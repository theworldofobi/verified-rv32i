  .section .text.init
  .globl _start
_start:
  la    sp, __stack_top
  la    t0, __bss_start
  la    t1, __bss_end
1:  bgeu  t0, t1, 2f
  sw    zero, 0(t0)
  addi  t0, t0, 4
  j     1b
2:  call  main
  la    t0, tohost
  slli  t1, a0, 1
  ori   t1, t1, 1
  sw    t1, 0(t0)
#ifdef SPIKE
3:  j     3b
#else
  ecall
#endif

  .section .tohost, "aw", @progbits
  .balign 64
  .globl tohost
tohost:   .dword 0
  .balign 64
  .globl fromhost
fromhost: .dword 0