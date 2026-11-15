// test_macros.h - tiny self-checking test framework for directed asm tests.
//   gp (x3) holds the current test number.
//   On failure: a0 = failing test number, then ecall.
//   On success: a0 = 0, then ecall.
// The testbench runs with +SELFCHECK so a0 != 0 fails the run.
#define TEST_START            \
  .section .text.init;      \
  .globl _start;            \
_start:                       \
  li gp, 0;

// TEST_RR(n, inst, expected, a, b): inst rd, rs1, rs2
#define TEST_RR(n, inst, exp, a, b) \
  li gp, n;  li x1, a;  li x2, b;  inst x14, x1, x2; \
  li x7, exp;  bne x14, x7, fail;

// TEST_IMM(n, inst, expected, a, imm): inst rd, rs1, imm
#define TEST_IMM(n, inst, exp, a, imm) \
  li gp, n;  li x1, a;  inst x14, x1, imm; \
  li x7, exp;  bne x14, x7, fail;

// TEST_EQ(n, reg, expected): compare any register with a constant
#define TEST_EQ(n, reg, exp) \
  li gp, n;  li x7, exp;  bne reg, x7, fail;

#define TEST_END              \
  li a0, 0;                 \
  ecall;                    \
fail:                         \
  mv a0, gp;                \
  ecall;
