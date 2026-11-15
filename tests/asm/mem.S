// mem.S - loads and stores of every width, sign/zero extension, all byte lanes
#include "test_macros.h"
TEST_START
  la x10, buf

  // LW / LH / LHU / LB / LBU
  lw  x14, 0(x10);  TEST_EQ(1,  x14, 0x80f17f01)
  lb  x14, 0(x10);  TEST_EQ(2,  x14, 0x00000001)
  lb  x14, 1(x10);  TEST_EQ(3,  x14, 0x0000007f)
  lb  x14, 2(x10);  TEST_EQ(4,  x14, 0xfffffff1)
  lb  x14, 3(x10);  TEST_EQ(5,  x14, 0xffffff80)
  lbu x14, 2(x10);  TEST_EQ(6,  x14, 0x000000f1)
  lbu x14, 3(x10);  TEST_EQ(7,  x14, 0x00000080)
  lh  x14, 0(x10);  TEST_EQ(8,  x14, 0x00007f01)
  lh  x14, 2(x10);  TEST_EQ(9,  x14, 0xffff80f1)
  lhu x14, 2(x10);  TEST_EQ(10, x14, 0x000080f1)

  // negative offsets
  addi x11, x10, 8
  lw  x14, -8(x11); TEST_EQ(11, x14, 0x80f17f01)
  lw  x14, -4(x11); TEST_EQ(12, x14, 0xdeadbeef)

  // SB to each lane must not disturb the others
  li x1, 0
  sw x1, 8(x10)
  li x2, 0x11; sb x2, 8(x10)
  li x2, 0x22; sb x2, 9(x10)
  li x2, 0x33; sb x2, 10(x10)
  li x2, 0xfffffe44; sb x2, 11(x10)     // only the low byte is stored
  lw x14, 8(x10);   TEST_EQ(20, x14, 0x44332211)

  // SH to both halves
  li x2, 0xabcd1234; sh x2, 12(x10)
  li x2, 0x5678;     sh x2, 14(x10)
  lw x14, 12(x10);  TEST_EQ(21, x14, 0x56781234)

  // SW then read back with every load type
  li x2, 0xfedcba98; sw x2, 16(x10)
  lw  x14, 16(x10); TEST_EQ(22, x14, 0xfedcba98)
  lbu x14, 19(x10); TEST_EQ(23, x14, 0xfe)
  lh  x14, 16(x10); TEST_EQ(24, x14, 0xffffba98)

  // address = rs1 + imm with large positive offset
  la x11, buf
  addi x11, x11, -0x400
  lw x14, 0x400(x11); TEST_EQ(25, x14, 0x80f17f01)
TEST_END

  .data
  .balign 4
buf:
  .word 0x80f17f01
  .word 0xdeadbeef
  .space 32
