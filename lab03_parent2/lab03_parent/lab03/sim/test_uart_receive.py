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

INPUT_CLOCK_FREQ = 100_000_000
BAUD_RATE = 9600
BAUD_PERIOD = INPUT_CLOCK_FREQ // BAUD_RATE

@cocotb.test()
async def test_receive(dut):
   """cocotb test for the SPI module"""
   dut._log.info("Starting...")
   cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
   dut._log.info("Holding reset...")
   dut.rst.value = 1
   await ClockCycles(dut.clk, 2) # wait 2 clock cycles
   assert dut.state.value == 0, "state is not IDLE on reset!" # IDLE is assigned to 0 in the enum 

   dut.rst.value = 0
   await ClockCycles(dut.clk, 1) # now i am not in reset, i am in IDLE 

   dut.din.value = 0 # assign the first input bit to a valid start state
   # we should now go to start state after 1 clock cycle
   await ClockCycles(dut.clk, 4)
   assert dut.state.value == 1 # at START now

   await ClockCycles(dut.clk, BAUD_PERIOD)
   assert dut.state.value == 2 # at DATA now

   await ClockCycles(dut.clk, 8*BAUD_PERIOD + BAUD_PERIOD //2)
   assert dut.state.value == 3 # at DATA now

   await ClockCycles(dut.clk, BAUD_PERIOD)
   await ClockCycles(dut.clk, BAUD_PERIOD)
   await ClockCycles(dut.clk, BAUD_PERIOD)

   dut.rst.value = 1
   await ClockCycles(dut.clk, BAUD_PERIOD)
   await ClockCycles(dut.clk, BAUD_PERIOD)



#    await ClockCycles(dut.clk, BAUD_PERIOD/2) # wait a half period 
#    assert dut.state.value == 1 # still at IDLE




#    await  FallingEdge(dut.clk)
#    dut.rst.value = 0 #un reset device
#    await ClockCycles(dut.clk, 3) #wait a few clock cycles
#    await  FallingEdge(dut.clk)
#    dut._log.info("Setting Trigger")
#    dut.trigger.value = 1
#    await ClockCycles(dut.clk, 1,rising=False)
#    dut.din.value = 0xFF  # once trigger in is off, don't expect data_in to stay the same!!
#    dut.trigger.value = 0
#    assert dut.busy == 1,  "Should be busy after trigger!"
#    assert dut.dout == 0, "Start bit should be 0!"
   
#    expected = [1,0,0,1,0,1,1,0]
#    for n, bit in enumerate(expected):
#       await ClockCycles(dut.clk, 10417,rising=False)
#       assert dut.dout == bit, f"{dut.dout} doesn't match expected value of {bit} for bit {n}"
#       assert dut.busy == 1,  f"Should be busy while transmitting bit {n}! "
#    await ClockCycles(dut.clk, 10417,rising=False)
#    assert dut.busy == 1,  "Should be busy while transmitting!"
#    assert dut.dout == 1, "End bit should be 1!"
#    await ClockCycles(dut.clk, 10417,rising=False)
#    assert dut.busy == 0, "Should no longer be busy!"

#    dut._log.info("Starting 2nd data transmission")
#    await ClockCycles(dut.clk, 9999, rising=False) #arbitrary
#    assert dut.dout == 1, "Stop bit should still be on!"
#    assert dut.busy == 0, "Should still not be busy!"
#    dut.trigger.value = 1
#    dut.din.value = 0x62
#    await ClockCycles(dut.clk, 1, rising=False)
#    dut.trigger.value = 0
#    dut.din.value = 0x00
#    assert dut.busy == 1,  "Should be busy after trigger!"
#    assert dut.dout == 0, "Start bit should be 0!"

#    expected = [0,1,1,0,0,0,1,0][::-1]
#    for n, bit in enumerate(expected):
#       await ClockCycles(dut.clk, 10417,rising=False)
#       assert dut.dout == bit, f"{dut.dout} doesn't match expected value of {bit} for bit {n}"
#       assert dut.busy == 1,  f"Should be busy while transmitting bit {n}! "
#    await ClockCycles(dut.clk, 10417,rising=False)
#    assert dut.busy == 1,  "Should be busy while transmitting!"
#    assert dut.dout == 1, "End bit should be 1!"
#    await ClockCycles(dut.clk, 10417,rising=False)
#    assert dut.busy == 0, "Should no longer be busy!"

def receive_runner():
    """Simulate the counter using the Python runner."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "uart_receive.sv"]
    build_test_args = ["-Wall"]
    parameters = {'INPUT_CLOCK_FREQ': 100_000_000, 'BAUD_RATE':9600} #!!!change these to do different versions
    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "uart_receive"
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
    receive_runner()
 