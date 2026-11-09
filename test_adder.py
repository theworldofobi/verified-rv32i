import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ReadOnly

@cocotb.test()
async def test_adder(dut):
  cocotb.start_soon(Clock(dut.clk, 10, "ns").start())

  for x in range(50):
    a = random.randrange(256)
    b = random.randrange(256)

    await FallingEdge(dut.clk)

    dut.a.value = a
    dut.b.value = b

    await RisingEdge(dut.clk)
    await ReadOnly()

    actual = dut.y.value.to_unsigned()
    assert actual == a + b, f"test_adder: received {actual}, expected {a + b}"


