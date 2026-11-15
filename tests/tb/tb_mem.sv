module tb_mem #(
  parameter int MEM_WORDS = 16384
) (
  input  logic        clk,
  input  logic [31:0] i_addr,
  output logic [31:0] i_rdata,
  input  logic [31:0] d_addr,
  input  logic        d_re,
  input  logic        d_we,
  input  logic [3:0]  d_wstrb,
  input  logic [31:0] d_wdata,
  output logic [31:0] d_rdata
);
  localparam int AW = $clog2(MEM_WORDS);

  logic [31:0] mem [MEM_WORDS];

  assign i_rdata = mem[i_addr[AW+1:2]];
  // X unless a load is actually requested: a DUT that consumes load data
  // without asserting dmem_re will propagate X and mismatch the ISS
  assign d_rdata = d_re ? mem[d_addr[AW+1:2]] : 'x;

  always_ff @(posedge clk) begin
    if (d_we)
      for (int b = 0; b < 4; b++) begin
        if (d_wstrb[b]) mem[d_addr[AW+1:2]][8*b +: 8] <= d_wdata[8*b +: 8];
      end
    end
endmodule
