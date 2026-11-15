module regfile #(
  parameter bit BYPASS = 1'b0
) (
  input  logic        clk,
  input  logic [4:0]  raddr1,
  output logic [31:0] rdata1,
  input  logic [4:0]  raddr2,
  output logic [31:0] rdata2,
  input  logic        we,
  input  logic [4:0]  waddr,
  input  logic [31:0] wdata
);
  /* verilator lint_off PROCASSINIT */
  logic [31:0] regs [32] = '{default: '0};
  /* verilator lint_on PROCASSINIT */

  always_ff @(posedge clk) begin
    if (we && waddr != 5'd0) regs[waddr] <= wdata;
  end

  always_comb begin
    if (raddr1 == 5'd0)                         rdata1 = '0;
    else if (BYPASS && we && waddr == raddr1)   rdata1 = wdata;
    else                                        rdata1 = regs[raddr1];

    if (raddr2 == 5'd0)                         rdata2 = '0;
    else if (BYPASS && we && waddr == raddr2)   rdata2 = wdata;
    else                                        rdata2 = regs[raddr2];
  end
endmodule
