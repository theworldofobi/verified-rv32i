/* flat 64 KiB memory image starting at address 0 */
OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY { RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 64K }

SECTIONS
{
  .text : { *(.text.init) *(.text .text.*) } > RAM
  .rodata : { *(.rodata .rodata.* .srodata .srodata.*) } > RAM
  .data : { . = ALIGN(4); *(.data .data.* .sdata .sdata.*) } > RAM
  .bss : { . = ALIGN(4); __bss_start = .; *(.bss .bss.* .sbss .sbss.* COMMON) . = ALIGN(4); } > RAM
  _end = .;
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}