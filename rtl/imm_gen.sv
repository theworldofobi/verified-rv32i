module imm_gen
  import rv32i_pkg::*;
(
  input  logic [31:0] insn,
  input  imm_sel_e    sel,
  output logic [31:0] imm
);
  always_comb begin
    case (sel)
      IMM_I:   imm = {{21{insn[31]}}, insn[30:20]};
      IMM_S:   imm = {{21{insn[31]}}, insn[30:25], insn[11:7]};
      IMM_B:   imm = {{20{insn[31]}}, insn[7], insn[30:25], insn[11:8], 1'b0};
      IMM_U:   imm = {insn[31:12], 12'b0};
      IMM_J:   imm = {{12{insn[31]}}, insn[19:12], insn[20], insn[30:21], 1'b0};
      default: imm = '0;
    endcase
  end
endmodule
