#!/usr/bin/env python3
"""
bin2hex.py <in.bin> <out.hex> 
raw little-endian binary to $readmemh words.
"""

import sys

data = open(sys.argv[1], "rb").read()
data += b"\x00" * (-len(data) % 4)

with open(sys.argv[2], "w") as f:
  for i in range(0, len(data), 4):
    f.write(f"{int.from_bytes(data[i:i+4], 'little'):08x}\n")
