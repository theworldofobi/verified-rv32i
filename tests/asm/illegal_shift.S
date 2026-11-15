// illegal_shift.S - SRAI/SRLI encoding with funct7 = 0110000 (reserved).
// rv32ui only uses legal encodings, so a decoder that ignores the extra
// funct7 bits passes all of rv32ui (found by seeded mutant m8).
// Run with +EXPECT_TRAP.
  .section .text.init
  .globl _start
_start:
  li x5, -8
  .word 0x6012d293          // "srai x5, x5, 1" with funct7 = 0110000: illegal
  li x5, 2                  // must never execute
  ecall
