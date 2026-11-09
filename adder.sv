module adder(
  input  logic       clk,
  input  logic [7:0] a,
  input  logic [7:0] b,
  output logic [8:0] y
);
  always_ff @(posedge clk) begin
    y <= a + b;
  end
endmodule
