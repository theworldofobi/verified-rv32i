// upper.S - LUI / AUIPC
#include "test_macros.h"
TEST_START
  li gp, 1
  lui x14, 0xfffff
  li x7, 0xfffff000
  bne x14, x7, fail

  li gp, 2
  lui x14, 0
  bne x14, zero, fail

  li gp, 3
1:  auipc x14, 0              // x14 = address of label 1
  la x7, 1b
  bne x14, x7, fail

  li gp, 4
2:  auipc x14, 0x1
  la x7, 2b
  li x8, 0x1000
  add x7, x7, x8
  bne x14, x7, fail
TEST_END
