// alu.S - every RV32I register/immediate ALU op, including edge cases
#include "test_macros.h"
TEST_START
  TEST_RR(1,  add,  0x00000000, 0x00000000, 0x00000000)
  TEST_RR(2,  add,  0x80000000, 0x7fffffff, 0x00000001)   // signed overflow wraps
  TEST_RR(3,  add,  0x00000000, 0xffffffff, 0x00000001)
  TEST_RR(4,  sub,  0xffffffff, 0x00000000, 0x00000001)
  TEST_RR(5,  sub,  0x7fffffff, 0x80000000, 0x00000001)
  TEST_RR(6,  sll,  0x80000000, 0x00000001, 31)
  TEST_RR(7,  sll,  0x00000002, 0x00000001, 0xffffffe1)   // only rs2[4:0] used
  TEST_RR(8,  srl,  0x00000001, 0x80000000, 31)
  TEST_RR(9,  srl,  0x7fffffff, 0xffffffff, 0xffffffe1)
  TEST_RR(10, sra,  0xffffffff, 0x80000000, 31)
  TEST_RR(11, sra,  0xc0000000, 0x80000000, 1)
  TEST_RR(12, sra,  0x3fffffff, 0x7fffffff, 1)
  TEST_RR(13, slt,  1,          0x80000000, 0x00000000)   // -2^31 < 0
  TEST_RR(14, slt,  0,          0x00000000, 0x80000000)
  TEST_RR(15, slt,  0,          0x00000005, 0x00000005)
  TEST_RR(16, sltu, 0,          0x80000000, 0x00000000)
  TEST_RR(17, sltu, 1,          0x00000000, 0xffffffff)
  TEST_RR(18, xor,  0xf00ff00f, 0xff00ff00, 0x0f0f0f0f)
  TEST_RR(19, or,   0xff0fff0f, 0xff00ff00, 0x0f0f0f0f)
  TEST_RR(20, and,  0x0f000f00, 0xff00ff00, 0x0f0f0f0f)

  TEST_IMM(30, addi,  0x00000000, 0x00000001, -1)
  TEST_IMM(31, addi,  0x800007fe, 0x7fffffff, 0x7ff)
  TEST_IMM(32, addi,  0x7ffff7ff, 0x7fffffff, -0x800)
  TEST_IMM(33, slti,  1,          0xffffffff, 0)
  TEST_IMM(34, slti,  0,          0x00000000, -1)
  TEST_IMM(35, sltiu, 1,          0x00000000, -1)         // imm sign-extends, then unsigned compare
  TEST_IMM(36, sltiu, 0,          0xffffffff, -1)
  TEST_IMM(37, xori,  0xffffff0f, 0x000000f0, -1)         // xori -1 == not
  TEST_IMM(38, ori,   0xfffff80f, 0x0000000f, -0x800)
  TEST_IMM(39, andi,  0x000007f0, 0xff00fff0, 0x7ff)
  TEST_IMM(40, slli,  0x80000000, 0x00000001, 31)
  TEST_IMM(41, srli,  0x00000001, 0x80000000, 31)
  TEST_IMM(42, srai,  0xffffffff, 0x80000000, 31)
  TEST_IMM(43, srai,  0x00000000, 0x7fffffff, 31)

  // writes to x0 are discarded
  li gp, 50
  li x1, 123
  add x0, x1, x1
  bne x0, zero, fail
  addi x0, x0, 5
  bne x0, zero, fail
TEST_END
