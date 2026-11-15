module rv32i_single
  import rv32i_pkg::*;
#(
  parameter logic [31:0] RESET_PC = 32'h0000_0000
) (
  input  logic        clk,
  input  logic        rst_n,
  // instruction memory
  output logic [31:0] imem_addr,
  input  logic [31:0] imem_rdata,
  // data memory
  output logic [31:0] dmem_addr,     // word aligned
  output logic        dmem_re,
  output logic        dmem_we,
  output logic [3:0]  dmem_wstrb,
  output logic [31:0] dmem_wdata,
  input  logic [31:0] dmem_rdata,
  // status
  output logic        halted,        // ecall/ebreak or illegal instruction retired
  output logic        trap,          // stopped because of an illegal instruction
  // retirement trace
  output retire_t     retire
);
  logic [31:0] pc, pc_plus4, pc_next, insn;
  ctrl_t       ctrl;
  logic [31:0] imm, rs1_val, rs2_val, alu_a, alu_b, alu_y;
  logic [31:0] load_data, wb_data, branch_target, store_wdata;
  logic [3:0]  store_wstrb;
  logic        take_branch, redirect, misaligned, active;

  assign active = rst_n && !halted;

  // FETCH
  assign imem_addr = pc;
  assign insn      = imem_rdata;
  assign pc_plus4  = pc + 32'd4;

  // DECODE
  decoder u_dec (.insn(insn), .ctrl(ctrl));
  imm_gen u_imm (.insn(insn), .sel(ctrl.imm_sel), .imm(imm));

  regfile #(.BYPASS(1'b0)) u_rf (
    .clk    (clk),
    .raddr1 (insn[19:15]), .rdata1 (rs1_val),
    .raddr2 (insn[24:20]), .rdata2 (rs2_val),
    .we     (active && ctrl.reg_write),
    .waddr  (insn[11:7]),
    .wdata  (wb_data)
  );

  // EXECUTE
  always_comb begin
    case (ctrl.src_a)
      SRCA_PC:   alu_a = pc;
      SRCA_ZERO: alu_a = '0;
      SRCA_RS1:  alu_a = rs1_val;
      default:   alu_a = rs1_val;
    endcase
  end
  assign alu_b = (ctrl.src_b == SRCB_IMM) ? imm : rs2_val;

  alu u_alu (.op(ctrl.alu_op), .a(alu_a), .b(alu_b), .y(alu_y));

  branch_unit u_br (.funct3(insn[14:12]), .rs1(rs1_val), .rs2(rs2_val), .take(take_branch));

  assign branch_target = pc + imm;      // branches and JAL
  assign redirect      = ctrl.jal || ctrl.jalr || (ctrl.branch && take_branch);

  always_comb begin
    if (ctrl.jalr)          pc_next = {alu_y[31:1], 1'b0};
    else if (redirect)      pc_next = branch_target;
    else                    pc_next = pc_plus4;
  end

  // MEMORY
  lsu u_lsu (
    .funct3     (insn[14:12]),
    .addr_lo    (alu_y[1:0]),
    .store_data (rs2_val),
    .wdata      (store_wdata),
    .wstrb      (store_wstrb),
    .rdata      (dmem_rdata),
    .load_data  (load_data),
    .misaligned (misaligned)
  );

  assign dmem_addr  = {alu_y[31:2], 2'b00};
  assign dmem_re    = active && ctrl.mem_read;
  assign dmem_we    = active && ctrl.mem_write;
  assign dmem_wstrb = store_wstrb;
  assign dmem_wdata = store_wdata;

  // WRITEBACK
  always_comb begin
    case (ctrl.wb_sel)
      WB_MEM:  wb_data = load_data;
      WB_PC4:  wb_data = pc_plus4;
      WB_ALU:  wb_data = alu_y;
      default: wb_data = alu_y;
    endcase
  end

  // STATES
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc     <= RESET_PC;
      halted <= 1'b0;
      trap   <= 1'b0;
    end else if (!halted) begin
      if (ctrl.halt || ctrl.illegal) begin
        halted <= 1'b1;
        trap   <= ctrl.illegal;
      end else begin
        pc <= pc_next;
      end
    end
  end

  // TRACE
  logic [31:0] lane_mask;
  assign lane_mask = {{8{store_wstrb[3]}}, {8{store_wstrb[2]}},
                      {8{store_wstrb[1]}}, {8{store_wstrb[0]}}};

  always_comb begin
    retire           = '0;
    retire.valid     = active;
    retire.pc        = pc;
    retire.insn      = insn;
    retire.pc_next   = (ctrl.halt || ctrl.illegal) ? pc : pc_next;
    retire.rd        = (ctrl.reg_write) ? insn[11:7] : 5'd0;
    retire.rd_wdata  = (retire.rd != 5'd0) ? wb_data : 32'd0;
    retire.mem_we    = ctrl.mem_write;
    retire.mem_addr  = ctrl.mem_write ? dmem_addr : 32'd0;
    retire.mem_wstrb = ctrl.mem_write ? store_wstrb : 4'd0;
    retire.mem_wdata = ctrl.mem_write ? (store_wdata & lane_mask) : 32'd0;
    retire.halt      = ctrl.halt;
    retire.trap      = ctrl.illegal;
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (active && (ctrl.mem_read || ctrl.mem_write))
      assert (!misaligned)
        else $error("misaligned access at pc=%08h addr=%08h", pc, alu_y);
  end
`endif

endmodule
