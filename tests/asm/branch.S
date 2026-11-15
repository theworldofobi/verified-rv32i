// branch.S - conditional branches (taken / not taken, signed / unsigned), JAL, JALR
#include "test_macros.h"

// branch must be taken
#define T_TAKEN(n, inst, a, b) \
  li gp, n; li x1, a; li x2, b; inst x1, x2, 1f; j fail; 1:
// branch must fall through
#define T_NOT(n, inst, a, b) \
  li gp, n; li x1, a; li x2, b; inst x1, x2, fail;

TEST_START
  T_TAKEN(1,  beq,  5, 5)
  T_NOT  (2,  beq,  5, 6)
  T_TAKEN(3,  bne,  5, 6)
  T_NOT  (4,  bne,  5, 5)
  T_TAKEN(5,  blt,  -1, 0)
  T_NOT  (6,  blt,  0, -1)
  T_NOT  (7,  blt,  3, 3)
  T_TAKEN(8,  bge,  0, -1)
  T_TAKEN(9,  bge,  3, 3)
  T_NOT  (10, bge,  -1, 0)
  T_TAKEN(11, bltu, 0, -1)
  T_NOT  (12, bltu, -1, 0)
  T_TAKEN(13, bgeu, -1, 0)
  T_TAKEN(14, bgeu, 7, 7)
  T_NOT  (15, bgeu, 0, -1)

  // backward branch: loop 10 times
  li gp, 20
  li x1, 0
  li x2, 10
3:  addi x1, x1, 1
  bne x1, x2, 3b
  TEST_EQ(21, x1, 10)

  // JAL writes the link register and jumps
  li gp, 30
  jal x5, 4f
5:  j fail
4:  la x7, 5b
  bne x5, x7, fail

  // JALR: target = (rs1 + imm) & ~1, link = pc + 4
  li gp, 31
  la x6, 6f
  addi x6, x6, -3           // misaligned by 1 after +4 below; LSB is cleared
  jalr x5, 4(x6)
7:  j fail
6:  la x7, 7b
  bne x5, x7, fail

  // JALR with rd == rs1 must use the OLD rs1
  li gp, 32
  la x6, 8f
  jalr x6, 0(x6)
9:  j fail
8:  la x7, 9b
  bne x6, x7, fail

  // JAL with rd = x0 does not write
  li gp, 33
  jal x0, 10f
  j fail
10: bne x0, zero, fail
TEST_END
