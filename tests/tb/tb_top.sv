/* tb_top compilation guide

  +HEX=<file>      program image ($readmemh, one 32-bit word per line)
  +MAX_CYCLES=<n>  timeout (default 200000)
  +SELFCHECK       also require a0 (x10) == 0 at ecall (directed tests)
  +EXPECT_TRAP     the program is supposed to end on an illegal instruction
  +TRACE           print every retired instruction

  Compile with -DDUT_PIPELINE to test the 5-stage core, otherwise the
  single-cycle core is used.
*/

module tb_top;
  import rv32i_pkg::*;
  import rv32i_iss_pkg::*;

  localparam int MEM_WORDS = 16384;   // 64 KiB

  logic        clk = 1'b0;
  logic        rst_n;
  logic [31:0] imem_addr, imem_rdata, dmem_addr, dmem_wdata, dmem_rdata;
  logic [3:0]  dmem_wstrb;
  logic        dmem_re, dmem_we, halted, trap;
  retire_t     retire;

  always #5 clk = ~clk;

`ifdef DUT_PIPELINE
  rv32i_pipeline dut (
`else
  rv32i_single dut (
`endif
    .clk, .rst_n,
    .imem_addr, .imem_rdata,
    .dmem_addr, .dmem_re, .dmem_we, .dmem_wstrb, .dmem_wdata, .dmem_rdata,
    .halted, .trap, .retire
  );

  tb_mem #(.MEM_WORDS(MEM_WORDS)) u_mem (
    .clk,
    .i_addr (imem_addr), .i_rdata (imem_rdata),
    .d_addr (dmem_addr), .d_re (dmem_re), .d_we (dmem_we), .d_wstrb (dmem_wstrb),
    .d_wdata(dmem_wdata), .d_rdata (dmem_rdata)
  );

  rv32i_iss #(.MEM_WORDS(MEM_WORDS)) iss;

  string       hex;
  int unsigned max_cycles = 200000;
  int unsigned cycles     = 0;
  int unsigned retired    = 0;
  int unsigned errors     = 0;
  bit          selfcheck, expect_trap, trace;
  bit          done       = 1'b0;

  function automatic string fmt(retire_t r);
    return $sformatf("pc=%08h insn=%08h next=%08h rd=x%0d<-%08h mem_we=%0b @%08h strb=%b data=%08h halt=%0b trap=%0b",
                     r.pc, r.insn, r.pc_next, r.rd, r.rd_wdata, r.mem_we,
                     r.mem_addr, r.mem_wstrb, r.mem_wdata, r.halt, r.trap);
  endfunction

  initial begin
    if (!$value$plusargs("HEX=%s", hex)) $fatal(1, "missing +HEX=<file>");
    void'($value$plusargs("MAX_CYCLES=%d", max_cycles));
    selfcheck   = $test$plusargs("SELFCHECK");
    expect_trap = $test$plusargs("EXPECT_TRAP");
    trace       = $test$plusargs("TRACE");

    for (int i = 0; i < MEM_WORDS; i++) u_mem.mem[i] = 32'h0;
    $readmemh(hex, u_mem.mem);

    iss = new();
    for (int i = 0; i < MEM_WORDS; i++) iss.mem[i] = u_mem.mem[i];

    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    @(posedge clk) #1 rst_n = 1'b1;   // release away from the negedge sample point (no race)
  end

  // Compare on the falling edge: all retire outputs are settled by then.
  always @(negedge clk) begin
    if (rst_n && !done) begin
      cycles++;
      if (retire.valid) begin
        retire_t exp;
        exp = iss.step();
        retired++;
        if (trace) $display("[%0d] %s", cycles, fmt(retire));
        if (retire != exp) begin
          errors++;
          $display("MISMATCH after %0d instructions (cycle %0d)", retired, cycles);
          $display("  dut: %s", fmt(retire));
          $display("  ref: %s", fmt(exp));
          finish();
        end
        if (retire.halt || retire.trap) finish();
      end
      if (cycles >= max_cycles) begin
        $display("TIMEOUT after %0d cycles (%0d retired)", cycles, retired);
        errors++;
        finish();
      end
    end
  end

  task automatic finish();
    done = 1'b1;
    // the halt/trap status ports must latch on the edge that retires ecall/illegal
    @(posedge clk); #1;
    if (errors == 0 && (retire.halt || retire.trap)) begin
      if (!halted || trap != retire.trap) begin
        $display("status ports wrong: halted=%0b trap=%0b (retire.trap=%0b)", halted, trap, retire.trap);
        errors++;
      end
    end
    if (errors == 0) begin
      if (retire.trap != expect_trap) begin
        $display("unexpected %s at pc=%08h", retire.trap ? "illegal-instruction trap" : "normal halt", retire.pc);
        errors++;
      end
      if (selfcheck && iss.x[10] != 0) begin
        $display("self-check failed: a0 = %0d (failing test number)", iss.x[10]);
        errors++;
      end
    end
    $display("%s %s: %0d instructions, %0d cycles, CPI %0.3f",
             errors == 0 ? "PASS" : "FAIL", hex, retired, cycles,
             retired == 0 ? 0.0 : real'(cycles) / real'(retired));
    if (errors != 0) $fatal(1);
    $finish;
  endtask
endmodule
