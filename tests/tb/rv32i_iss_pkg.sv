package rv32i_iss_pkg;
  import rv32i_pkg::retire_t;

  class rv32i_iss #(int MEM_WORDS = 16384);
    logic [31:0] x   [32];
    logic [31:0] mem [MEM_WORDS];
    logic [31:0] pc;
    int unsigned instret;

    function new();
      foreach (x[i])   x[i]   = '0;
      foreach (mem[i]) mem[i] = '0;
      pc      = '0;
      instret = 0;
    endfunction

    function int unsigned widx(logic [31:0] addr);
      return int'(addr[$clog2(MEM_WORDS)+1:2]);
    endfunction

    function logic [31:0] ext(logic [31:0] v, int bits);
      logic [31:0] m;
      m = 32'h1 << (bits - 1);
      return (v ^ m) - m;
    endfunction

    // Execute one instruction and return the trace record the DUT should produce.
    function retire_t step();
      retire_t     r;
      logic [31:0] insn, rs1v, rs2v, res, addr, word, imm_i, imm_s, imm_b, imm_u, imm_j;
      logic [6:0]  opc, f7;
      logic [2:0]  f3;
      logic [4:0]  rd, rs1, rs2;
      logic [1:0]  lo;
      logic [4:0]  sh;            // byte-lane shift = 8 * addr[1:0]
      logic        wr, illegal;

      insn = mem[widx(pc)];
      opc  = insn[6:0];  rd  = insn[11:7];  f3 = insn[14:12];
      rs1  = insn[19:15]; rs2 = insn[24:20]; f7 = insn[31:25];
      rs1v = x[rs1];      rs2v = x[rs2];

      imm_i = ext({20'b0, insn[31:20]}, 12);
      imm_s = ext({20'b0, insn[31:25], insn[11:7]}, 12);
      imm_b = ext({19'b0, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0}, 13);
      imm_u = {insn[31:12], 12'b0};
      imm_j = ext({11'b0, insn[31], insn[19:12], insn[20], insn[30:21], 1'b0}, 21);

      r         = '0;
      r.valid   = 1'b1;
      r.pc      = pc;
      r.insn    = insn;
      r.pc_next = pc + 4;
      res       = '0;
      wr        = 1'b0;
      illegal   = 1'b0;

      if (insn[1:0] != 2'b11) illegal = 1'b1;
      else case (opc)
        7'b0110111: begin res = imm_u;          wr = 1; end              // LUI
        7'b0010111: begin res = pc + imm_u;     wr = 1; end              // AUIPC
        7'b1101111: begin res = pc + 4; wr = 1; r.pc_next = pc + imm_j; end // JAL
        7'b1100111: begin                                                // JALR
          if (f3 != 0) illegal = 1;
          else begin res = pc + 4; wr = 1; r.pc_next = (rs1v + imm_i) & ~32'h1; end
        end
        7'b1100011: begin                                                // BRANCH
          logic t;
          case (f3)
            3'b000: t = (rs1v == rs2v);
            3'b001: t = (rs1v != rs2v);
            3'b100: t = ($signed(rs1v) <  $signed(rs2v));
            3'b101: t = ($signed(rs1v) >= $signed(rs2v));
            3'b110: t = (rs1v <  rs2v);
            3'b111: t = (rs1v >= rs2v);
            default: begin t = 0; illegal = 1; end
          endcase
          if (t) r.pc_next = pc + imm_b;
        end
        7'b0000011: begin                                                // LOAD
          addr = rs1v + imm_i;
          lo   = addr[1:0];
          sh   = {lo, 3'b000};
          word = mem[widx(addr)];
          wr   = 1;
          case (f3)
            3'b000: res = ext((word >> sh) & 32'hff, 8);
            3'b001: res = ext((word >> sh) & 32'hffff, 16);
            3'b010: res = word;
            3'b100: res = (word >> sh) & 32'hff;
            3'b101: res = (word >> sh) & 32'hffff;
            default: begin illegal = 1; wr = 0; end
          endcase
        end
        7'b0100011: begin                                                // STORE
          logic [31:0] m;
          addr = rs1v + imm_s;
          lo   = addr[1:0];
          sh   = {lo, 3'b000};
          case (f3)
            3'b000: begin m = 32'h0000_00ff << sh; r.mem_wstrb = 4'b0001 << lo; end
            3'b001: begin m = 32'h0000_ffff << sh; r.mem_wstrb = 4'b0011 << lo; end
            3'b010: begin m = 32'hffff_ffff;           r.mem_wstrb = 4'b1111;       end
            default: begin m = 0; illegal = 1; end
          endcase
          if (!illegal) begin
            r.mem_we    = 1;
            r.mem_addr  = {addr[31:2], 2'b00};
            r.mem_wdata = (rs2v << sh) & m;
            mem[widx(addr)] = (mem[widx(addr)] & ~m) | r.mem_wdata;
          end
        end
        7'b0010011: begin                                                // OP-IMM
          wr = 1;
          unique case (f3)
            3'b000: res = rs1v + imm_i;
            3'b010: res = {31'b0, $signed(rs1v) < $signed(imm_i)};
            3'b011: res = {31'b0, rs1v < imm_i};
            3'b100: res = rs1v ^ imm_i;
            3'b110: res = rs1v | imm_i;
            3'b111: res = rs1v & imm_i;
            3'b001: begin
              if (f7 != 0) illegal = 1;
              res = rs1v << rs2;
            end
            3'b101: begin
              if (f7 == 7'b0000000)      res = rs1v >> rs2;
              else if (f7 == 7'b0100000) res = $unsigned($signed(rs1v) >>> rs2);
              else illegal = 1;
            end
          endcase
        end
        7'b0110011: begin                                                // OP
          wr = 1;
          case ({f7, f3})
            {7'h00, 3'b000}: res = rs1v + rs2v;
            {7'h20, 3'b000}: res = rs1v - rs2v;
            {7'h00, 3'b001}: res = rs1v << rs2v[4:0];
            {7'h00, 3'b010}: res = {31'b0, $signed(rs1v) < $signed(rs2v)};
            {7'h00, 3'b011}: res = {31'b0, rs1v < rs2v};
            {7'h00, 3'b100}: res = rs1v ^ rs2v;
            {7'h00, 3'b101}: res = rs1v >> rs2v[4:0];
            {7'h20, 3'b101}: res = $unsigned($signed(rs1v) >>> rs2v[4:0]);
            {7'h00, 3'b110}: res = rs1v | rs2v;
            {7'h00, 3'b111}: res = rs1v & rs2v;
            default: illegal = 1;
          endcase
        end
        7'b0001111: if (f3 != 0) illegal = 1;                            // FENCE
        7'b1110011: begin                                                // SYSTEM
          if (insn == 32'h0000_0073 || insn == 32'h0010_0073) begin
            r.halt    = 1;
            r.pc_next = pc;
          end else illegal = 1;
        end
        default: illegal = 1;
      endcase

      if (illegal) begin
        r           = '0;
        r.valid     = 1;
        r.pc        = pc;
        r.insn      = insn;
        r.pc_next   = pc;
        r.trap      = 1;
        wr          = 0;
      end

      if (wr && rd != 0) begin
        x[rd]      = res;
        r.rd       = rd;
        r.rd_wdata = res;
      end

      pc = r.pc_next;
      instret++;
      return r;
    endfunction
  endclass
endpackage
