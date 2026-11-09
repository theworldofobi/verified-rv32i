#!/usr/bin/env python3
import pathlib, subprocess, argparse, sys, shutil

PWD = pathlib.Path(__file__).resolve().parent
TARGETS = {
  "sim" : 0x0000_0000,
  "spike" : 0x8000_0000
}
LD = """OUTPUT_ARCH("riscv")
ENTRY(_start)
MEMORY {{ RAM (rwx) : ORIGIN = {base:#x}, LENGTH = {size:#x} }}
SECTIONS {{
  .text : {{ *(.text.init) *(.text .text.*) }} > RAM
  .rodata : {{ *(.rodata .rodatargs.* .srodata .srodatargs.*) }} > RAM
  .data : {{ . = ALIGN(4); *(.data .datargs.* .sdata .sdatargs.*) }} > RAM
  .tohost : {{ . = ALIGN(64); *(.tohost) }} > RAM
  .bss : {{ . = ALIGN(4); __bss_start = .; *(.bss .bss.* .sbss .sbss.* COMMON);
            . = ALIGN(4); __bss_end = .; }} > RAM
  __stack_top = ORIGIN(RAM) + LENGTH(RAM);
}}
"""

def run(cmd):
  print("+", " ".join(map(str, cmd)))
  subprocess.run(cmd, check=True)

ap = argparse.ArgumentParser()
ap.add_argument("source", type=pathlib.Path)
ap.add_argument("--target", choices=TARGETS, default="sim")
ap.add_argument("--mem-size", type=lambda s: int(s, 0), default=0x10000)
ap.add_argument("-o", "--outdir", type=pathlib.Path, default=pathlib.Path("build"))
ap.add_argument("--prefix", default="riscv64-unknown-elf-")

args = ap.parse_args()

if args.source.suffix not in (".c", ".s", ".S"):
  sys.exit("mkimage.py: ap.parse_args expected a .c or .S file")

if not shutil.which(args.prefix + "gcc"):
  sys.exit(f"mkimage.py: ap.parse_args: {args.prefix}gcc not found")

args.outdir.mkdir(parents=True, exist_ok=True)
stem = args.outdir / args.source.stem
ld = args.outdir / f"link_{args.target}.ld"
ld.write_text(LD.format(base=TARGETS[args.target], size=args.mem_size))

flags = ["-march=rv32i", "-mabi=ilp32", "-O2", "-g", "-ffreestanding", "-fno-builtin",
         "-nostdlib", "-nostartfiles", "-mno-relax", "-Wall", "-Wl,--no-warn-rwx-segments"]
if args.target == "spike":
  flags.append("-DSPIKE")
run([args.prefix + "gcc", *flags, "-T", ld, PWD / "crt0.S", args.source, "-lgcc", "-o", stem.with_suffix(".elf")])
run([args.prefix + "objcopy", "-O", "binary", "--remove-section=.bss", stem.with_suffix(".elf"), stem.with_suffix(".bin")])

data = stem.with_suffix(".bin").read_bytes()
data += b"\0" * (-len(data) % 4)

with open(stem.with_suffix(".hex"), "w") as f:
  for i in range(0, len(data), 4):
    f.write(f"{int.from_bytes(data[i:i+4], 'little'):08x}\n")

with open(stem.with_suffix(".dis"), "w") as f:
  subprocess.run([args.prefix + "objdump", "-d", "-S", stem.with_suffix(".elf")], stdout=f, check=True)

print(f"{stem}.hex: {len(data)//4} words at {TARGETS[args.target]:#010x}")