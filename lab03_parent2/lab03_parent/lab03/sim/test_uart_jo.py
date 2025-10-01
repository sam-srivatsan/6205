import cocotb
import os
import random
import sys
from math import log
import logging
from pathlib import Path
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,with_timeout
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
test_file = os.path.basename(__file__).replace(".py","")

# utility function to reverse bits:
def reverse_bits(n,size):
    reversed_n = 0
    for i in range(size):
        reversed_n = (reversed_n << 1) | (n & 1)
        n >>= 1
    return reversed_n

# test message:
SPI_RESP_MSG = 0x2345
#flip them:
SPI_RESP_MSG = reverse_bits(SPI_RESP_MSG,16)

SPI_RESP_MSG2 = 0xe3cb
SPI_RESP_MSG2 = reverse_bits(SPI_RESP_MSG2,16)
# this module below is a simple "fake" spi module written in Python that we can...
# test our design against.
async def test_spi_device(dut):
  count = 0
  count_max = 16 #change for different sizes
  while True:
    await FallingEdge(dut.cs) #listen for falling CS
    dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
    count+=1
    count%=16
    while dut.cs.value.integer ==0:
      await RisingEdge(dut.dclk)
      bit = dut.copi.value.integer #grab value:
      dut._log.info(f"SPI peripheral Device Receiving: {bit}")
      await FallingEdge(dut.dclk)
      dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
      dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
      count+=1
      count%=16
async def test_spi_device_again(dut):
    count = 0
    count_max = 16 #change for different sizes
    while True:
        await FallingEdge(dut.cs) #listen for falling CS
        dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
        dut._log.info(f"SPI peripheral Device Sending: {dut.cipo.value}")
        count+=1
        count%=16
        while count != 0:
            await RisingEdge(dut.dclk)
            bit = dut.copi.value.integer #grab value:
            dut._log.info(f"SPI peripheral Device Receiving (1st): {bit}")
            print(f"Bef Value: {dut.cs.value}")
            await FallingEdge(dut.dclk)
            print(f"AFt Value: {dut.cs.value}")
            dut.cipo.value = (SPI_RESP_MSG>>count)&0x1 #feed in lowest bit
            dut._log.info(f"SPI peripheral Device Sending (1st): {dut.cipo.value}")
            count+=1
            count%=16
        await FallingEdge(dut.cs) #listen for falling CS
        dut._log.info(f"Test num 2")
        dut.cipo.value = (SPI_RESP_MSG2>>count)&0x1 #feed in lowest bit
        dut._log.info(f"SPI peripheral Device Sending (2nd): {dut.cipo.value}")
        count+=1
        count%=16
        while dut.cs.value.integer ==0:
            await RisingEdge(dut.dclk)
            bit = dut.copi.value.integer #grab value:
            dut._log.info(f"SPI peripheral Device Receiving: (2nd) {bit}")
            await FallingEdge(dut.dclk)
            dut.cipo.value = (SPI_RESP_MSG2>>count)&0x1 #feed in lowest bit
            dut._log.info(f"SPI peripheral Device Sending (2nd): {dut.cipo.value}")
            count+=1
            count%=16
@cocotb.test()
async def test_a(dut):
   """cocotb test for the SPI module"""
   dut._log.info("Starting...")
   cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
#  cocotb.start_soon(test_spi_device_again(dut))
   dut._log.info("Holding reset...")
   dut.rst.value = 1
   dut.trigger.value = 0
   dut.din.value = 0x69
   await ClockCycles(dut.clk, 3) #wait three clock cycles
   assert dut.busy.value.integer==0, "busy is not 1 on reset!"
   await  FallingEdge(dut.clk)
   dut.rst.value = 0 #un reset device
   await ClockCycles(dut.clk, 3) #wait a few clock cycles
   await  FallingEdge(dut.clk)
   dut._log.info("Setting Trigger")
   dut.trigger.value = 1
   await ClockCycles(dut.clk, 1,rising=False)
   dut.din.value = 0xFF  # once trigger in is off, don't expect data_in to stay the same!!
   dut.trigger.value = 0
   assert dut.busy == 1,  "Should be busy after trigger!"
   assert dut.dout == 0, "Start bit should be 0!"
   
   expected = [1,0,0,1,0,1,1,0]
   for n, bit in enumerate(expected):
      await ClockCycles(dut.clk, 10417,rising=False)
      assert dut.dout == bit, f"{dut.dout} doesn't match expected value of {bit} for bit {n}"
      assert dut.busy == 1,  f"Should be busy while transmitting bit {n}! "
   await ClockCycles(dut.clk, 10417,rising=False)
   assert dut.busy == 1,  "Should be busy while transmitting!"
   assert dut.dout == 1, "End bit should be 1!"
   await ClockCycles(dut.clk, 10417,rising=False)
   assert dut.busy == 0, "Should no longer be busy!"

   dut._log.info("Starting 2nd data transmission")
   await ClockCycles(dut.clk, 9999, rising=False) #arbitrary
   assert dut.dout == 1, "Stop bit should still be on!"
   assert dut.busy == 0, "Should still not be busy!"
   dut.trigger.value = 1
   dut.din.value = 0x62
   await ClockCycles(dut.clk, 1, rising=False)
   dut.trigger.value = 0
   dut.din.value = 0x00
   assert dut.busy == 1,  "Should be busy after trigger!"
   assert dut.dout == 0, "Start bit should be 0!"

   expected = [0,1,1,0,0,0,1,0][::-1]
   for n, bit in enumerate(expected):
      await ClockCycles(dut.clk, 10417,rising=False)
      assert dut.dout == bit, f"{dut.dout} doesn't match expected value of {bit} for bit {n}"
      assert dut.busy == 1,  f"Should be busy while transmitting bit {n}! "
   await ClockCycles(dut.clk, 10417,rising=False)
   assert dut.busy == 1,  "Should be busy while transmitting!"
   assert dut.dout == 1, "End bit should be 1!"
   await ClockCycles(dut.clk, 10417,rising=False)
   assert dut.busy == 0, "Should no longer be busy!"

def spi_con_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_transmit.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 100_000_000, 'BAUD_RATE':9600} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "uart_transmit"
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel=hdl_toplevel,
        always=True,
        build_args=build_test_args,
        parameters=parameters,
        timescale = ('1ns','1ps'),
        waves=True
    )
    run_test_args = []
    runner.test(
        hdl_toplevel=hdl_toplevel,
        test_module=test_file,
        test_args=run_test_args,
        waves=True
    )

if __name__ == "__main__":
    spi_con_runner()
 