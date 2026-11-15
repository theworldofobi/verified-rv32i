// branch_far.S - branch offsets beyond +/-2 KiB
// B-immediate bit 11 lives in insn[7] and the sign bit (imm[12]) in insn[31];
// they only differ when |offset| >= 2048, so short-branch tests cannot tell a
// swapped/misplaced bit 11 from a correct one (found by seeded mutant m2)
#include "test_macros.h"
TEST_START
  li gp, 1
  beq x0, x0, 1f            // forward ~+2.4 KiB: imm[12]=0, imm[11]=1
  j fail
back:
  li gp, 3
  j done
  .fill 600, 4, 0x00000013  // 600 NOPs (2400 bytes) of padding
1:
  li gp, 2
  beq x0, x0, back          // backward ~-2.4 KiB: imm[12]=1, imm[11]=0
  j fail
done:
TEST_END
