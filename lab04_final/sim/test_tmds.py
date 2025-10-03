import cocotb
from cocotb.triggers import Timer
import os
from pathlib import Path
import sys
from cocotb.clock import Clock
from cocotb.triggers import Timer, ClockCycles, RisingEdge, FallingEdge, ReadOnly,ReadWrite,with_timeout, First, Join
from cocotb.utils import get_sim_time as gst
from cocotb.runner import get_runner
from random import getrandbits
test_file = os.path.basename(__file__).replace(".py","")

async def reset(rst,clk):
    """ Helper function to issue a reset signal to our module """
    rst.value = 1
    await ClockCycles(clk,3)
    rst.value = 0
    await ClockCycles(clk,2)

async def drive_data(dut,data_byte,control_bits,ve_bit):
    """ submit a set of data values as input, then wait a clock cycle for them to stay there. """
    dut.video_data.value = data_byte
    dut.control.value = control_bits
    dut.video_enable.value = ve_bit
    await ClockCycles(dut.clk,1)

@cocotb.test()
async def test_tmds(dut):
    """ Your simulation test!
        TODO: Flesh this out with value sets and print statements. Maybe even some assertions, as a treat.
    """
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    # set all inputs to 0
    dut.video_data.value = 0
    dut.control.value = 0
    dut.video_enable.value = 0
    # use helper function to assert reset signal
    await reset(dut.rst,dut.clk)
    # example usage of the helper function to set all the input values you want to set
    # you probably want to make lots more of these.
    await drive_data(dut, 0x44, 0b00, 1)
    # a clock cycle has now passed: see the helper function. read your outputs here!
    await drive_data(dut, 0x55, 0b00, 1)
    await drive_data(dut, 0x00, 0b01, 0)
    await drive_data(dut, 0x00, 0b11, 0)
    for i in range(100):
        await drive_data(dut, getrandbits(8), getrandbits(2), getrandbits(1))



def test_tmds_runner():
    """Run the TMDS runner. Boilerplate code"""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "tmds_encoder.sv", proj_path / "hdl" / "tm_choice.sv"]
    build_test_args = ["-Wall"]
    parameters = {}
    sys.path.append(str(proj_path / "sim"))
    runner = get_runner(sim)
    hdl_toplevel = "tmds_encoder"
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
    test_tmds_runner()

