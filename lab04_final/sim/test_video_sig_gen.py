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

ACTIVE_H_PIXELS = 10
H_FRONT_PORCH = 3
H_SYNC_WIDTH = 5
H_BACK_PORCH = 8
ACTIVE_LINES = 7
V_FRONT_PORCH = 2
V_SYNC_WIDTH = 1
V_BACK_PORCH = 5
FPS = 2

@cocotb.test()
async def test_a(dut):
   """cocotb test for the SPI module"""
   dut._log.info("Starting...")
   cocotb.start_soon(Clock(dut.pixel_clk, 10, units="ns").start())
   dut._log.info("Holding reset...")
   dut.rst.value = 1

   await ClockCycles(dut.pixel_clk, 3) #wait three clock cycles
   assert dut.h_count.value==0, "h_count is not 0 on reset!"
   assert dut.v_count.value==0, "v_count is not 0 on reset!"

   dut.rst.value = 0 #un reset device


   # now the actual testing begins

   await ClockCycles(dut.pixel_clk, ACTIVE_H_PIXELS//2) # in clock cycles, should be in active_h_pixels blue range 
   assert dut.active_draw.value == 1, "should be in active draw region!" 
   assert dut.h_sync.value == 0, "should NOT YET be in h_sync, still in active draw!" 

   await ClockCycles(dut.pixel_clk, ACTIVE_H_PIXELS//2)
   await ReadOnly()
   assert dut.active_draw.value == 0, "should NO LONGER be in active draw region!" 
   assert dut.h_sync.value == 0, "should NOT YET be in h_sync, in h_front_porch!" 

   await ClockCycles(dut.pixel_clk, H_FRONT_PORCH)
   await ReadOnly()
   assert dut.h_sync.value == 1, "should be in h_sync!"
   
   await ClockCycles(dut.pixel_clk, H_SYNC_WIDTH)
   await ReadOnly()
   assert dut.h_sync.value == 0, "should NO LONGER be in h_sync, in h_back_porch!" 

   # completed one full row 

   # run through until the end of active draw, which is at (9,6)


def vsg_runner():
    """VSG Tester."""
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")
    proj_path = Path(__file__).resolve().parent.parent
    sys.path.append(str(proj_path / "sim" / "model"))
    sources = [proj_path / "hdl" / "vsg.sv"]
    build_test_args = ["-Wall"]
    #values for parameters defined earlier in the code.
    parameters = {'ACTIVE_H_PIXELS': ACTIVE_H_PIXELS, 'ACTIVE_LINES':ACTIVE_LINES,
                  'H_BACK_PORCH':H_BACK_PORCH,'H_SYNC_WIDTH':H_SYNC_WIDTH, 'H_FRONT_PORCH':H_FRONT_PORCH,
                  'V_FRONT_PORCH':V_FRONT_PORCH,'V_BACK_PORCH':V_BACK_PORCH,'FPS':FPS, "V_SYNC_WIDTH":V_SYNC_WIDTH}
 
    sys.path.append(str(proj_path / "sim"))
    hdl_toplevel = "video_sig_gen"
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
    )

if __name__ == "__main__":
    vsg_runner()
 