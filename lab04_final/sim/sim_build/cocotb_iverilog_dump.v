module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/samhita/Downloads/lab04/sim/sim_build/tmds_encoder.fst");
    $dumpvars(0, tmds_encoder);
end
endmodule
