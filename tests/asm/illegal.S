// illegal.S - an illegal instruction must stop the core without side effects
// run with +EXPECT_TRAP
  .section .text.init
  .globl _start
_start:
  li x5, 1
  .word 0x00001073          // csrrw x0, 0x000, x0 - Zicsr, not in RV32I base
  li x5, 2                  // must never execute
  ecall
