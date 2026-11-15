module branch_unit
  import rv32i_pkg::*;
(
  input  logic [2:0]  funct3,
  input  logic [31:0] rs1,
  input  logic [31:0] rs2,
  output logic        take
);
  always_comb begin
    case (funct3)
      F3_BEQ:  take = (rs1 == rs2);
      F3_BNE:  take = (rs1 != rs2);
      F3_BLT:  take = ($signed(rs1) <  $signed(rs2));
      F3_BGE:  take = ($signed(rs1) >= $signed(rs2));
      F3_BLTU: take = (rs1 <  rs2);
      F3_BGEU: take = (rs1 >= rs2);
      default: take = 1'b0;   // 010/011 are illegal
    endcase
  end
endmodule
