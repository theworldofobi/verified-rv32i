module lsu
  import rv32i_pkg::*;
(
  input  logic [2:0]  funct3,
  input  logic [1:0]  addr_lo,     // addr[1:0]
  // store path
  input  logic [31:0] store_data,  // rs2
  output logic [31:0] wdata,
  output logic [3:0]  wstrb,       // byte enables (only meaningful for stores)
  // load path
  input  logic [31:0] rdata,       // raw word from memory
  output logic [31:0] load_data,
  output logic        misaligned
);
  logic [7:0]  byte_sel;
  logic [15:0] half_sel;

  // store
  always_comb begin
    case (funct3[1:0])
      2'b00: begin // SB
        wdata = {4{store_data[7:0]}};
        wstrb = 4'b0001 << addr_lo;
      end
      2'b01: begin // SH
        wdata = {2{store_data[15:0]}};
        wstrb = addr_lo[1] ? 4'b1100 : 4'b0011;
      end
      default: begin // SW
        wdata = store_data;
        wstrb = 4'b1111;
      end
    endcase
  end

  // load
  assign byte_sel = rdata[{addr_lo, 3'b000} +: 8];
  assign half_sel = addr_lo[1] ? rdata[31:16] : rdata[15:0];

  always_comb begin
    case (funct3)
      F3_B:    load_data = {{24{byte_sel[7]}},  byte_sel};
      F3_H:    load_data = {{16{half_sel[15]}}, half_sel};
      F3_BU:   load_data = {24'b0, byte_sel};
      F3_HU:   load_data = {16'b0, half_sel};
      default: load_data = rdata;               // LW
    endcase
  end

  // alignment
  always_comb begin
    case (funct3[1:0])
      2'b01:   misaligned = addr_lo[0];
      2'b10:   misaligned = (addr_lo != 2'b00);
      default: misaligned = 1'b0;
    endcase
  end
endmodule
