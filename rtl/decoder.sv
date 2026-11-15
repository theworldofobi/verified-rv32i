module decoder
  import rv32i_pkg::*;
(
  input  logic [31:0] insn,
  output ctrl_t       ctrl
);
  logic [6:0] opcode, funct7;
  logic [2:0] funct3;

  assign opcode = insn[6:0];
  assign funct3 = insn[14:12];
  assign funct7 = insn[31:25];

  always_comb begin
    ctrl = CTRL_NOP;

    case (opcode)
      OP_LUI: begin
        ctrl.reg_write = 1'b1;
        ctrl.src_a     = SRCA_ZERO;
        ctrl.src_b     = SRCB_IMM;
        ctrl.imm_sel   = IMM_U;
      end

      OP_AUIPC: begin
        ctrl.reg_write = 1'b1;
        ctrl.src_a     = SRCA_PC;
        ctrl.src_b     = SRCB_IMM;
        ctrl.imm_sel   = IMM_U;
      end

      OP_JAL: begin
        ctrl.reg_write = 1'b1;
        ctrl.jal       = 1'b1;
        ctrl.imm_sel   = IMM_J;
        ctrl.wb_sel    = WB_PC4;
      end

      OP_JALR: begin
        ctrl.reg_write = 1'b1;
        ctrl.jalr      = 1'b1;
        ctrl.uses_rs1  = 1'b1;
        ctrl.src_b     = SRCB_IMM;     // ALU computes rs1 + imm
        ctrl.imm_sel   = IMM_I;
        ctrl.wb_sel    = WB_PC4;
        ctrl.illegal   = (funct3 != 3'b000);
      end

      OP_BRANCH: begin
        ctrl.branch    = 1'b1;
        ctrl.uses_rs1  = 1'b1;
        ctrl.uses_rs2  = 1'b1;
        ctrl.imm_sel   = IMM_B;
        ctrl.illegal   = (funct3 == 3'b010) || (funct3 == 3'b011);
      end

      OP_LOAD: begin
        ctrl.reg_write = 1'b1;
        ctrl.mem_read  = 1'b1;
        ctrl.uses_rs1  = 1'b1;
        ctrl.src_b     = SRCB_IMM;
        ctrl.imm_sel   = IMM_I;
        ctrl.wb_sel    = WB_MEM;
        ctrl.illegal   = !(funct3 inside {F3_B, F3_H, F3_W, F3_BU, F3_HU});
      end

      OP_STORE: begin
        ctrl.mem_write = 1'b1;
        ctrl.uses_rs1  = 1'b1;
        ctrl.uses_rs2  = 1'b1;
        ctrl.src_b     = SRCB_IMM;
        ctrl.imm_sel   = IMM_S;
        ctrl.illegal   = !(funct3 inside {F3_B, F3_H, F3_W});
      end

      OP_IMM: begin
        ctrl.reg_write = 1'b1;
        ctrl.uses_rs1  = 1'b1;
        ctrl.src_b     = SRCB_IMM;
        ctrl.imm_sel   = IMM_I;
        unique case (funct3)
          3'b000: ctrl.alu_op = ALU_ADD;
          3'b010: ctrl.alu_op = ALU_SLT;
          3'b011: ctrl.alu_op = ALU_SLTU;
          3'b100: ctrl.alu_op = ALU_XOR;
          3'b110: ctrl.alu_op = ALU_OR;
          3'b111: ctrl.alu_op = ALU_AND;
          3'b001: begin
            ctrl.alu_op  = ALU_SLL;
            ctrl.illegal = (funct7 != 7'b0000000);
          end
          3'b101: begin
            ctrl.alu_op  = funct7[5] ? ALU_SRA : ALU_SRL;
            ctrl.illegal = (funct7 != 7'b0000000) && (funct7 != 7'b0100000);
          end
        endcase
      end

      OP_REG: begin
        ctrl.reg_write = 1'b1;
        ctrl.uses_rs1  = 1'b1;
        ctrl.uses_rs2  = 1'b1;
        ctrl.src_b     = SRCB_RS2;
        unique case (funct3)
          3'b000: ctrl.alu_op = funct7[5] ? ALU_SUB : ALU_ADD;
          3'b001: ctrl.alu_op = ALU_SLL;
          3'b010: ctrl.alu_op = ALU_SLT;
          3'b011: ctrl.alu_op = ALU_SLTU;
          3'b100: ctrl.alu_op = ALU_XOR;
          3'b101: ctrl.alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
          3'b110: ctrl.alu_op = ALU_OR;
          3'b111: ctrl.alu_op = ALU_AND;
        endcase
        // only SUB and SRA may use funct7 = 0100000
        if (funct7 == 7'b0100000)
          ctrl.illegal = !(funct3 == 3'b000 || funct3 == 3'b101);
        else
          ctrl.illegal = (funct7 != 7'b0000000);
      end

      OP_FENCE: begin
        ctrl.illegal = (funct3 != 3'b000);   // FENCE = NOP; FENCE.I not supported
      end

      OP_SYSTEM: begin
        if (insn == 32'h0000_0073 || insn == 32'h0010_0073)
          ctrl.halt = 1'b1;                  // ECALL / EBREAK
        else
          ctrl.illegal = 1'b1;               // CSRs (Zicsr) not implemented
      end

      default: ctrl.illegal = 1'b1;
    endcase

    // 16-bit (compressed) encodings are not supported
    if (insn[1:0] != 2'b11) ctrl.illegal = 1'b1;

    // never letting an illegal instruction change architectural state
    if (ctrl.illegal) begin
      ctrl.reg_write = 1'b0;
      ctrl.mem_read  = 1'b0;
      ctrl.mem_write = 1'b0;
      ctrl.branch    = 1'b0;
      ctrl.jal       = 1'b0;
      ctrl.jalr      = 1'b0;
      ctrl.halt      = 1'b0;
    end
  end
endmodule
