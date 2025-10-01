module cocotb_iverilog_dump();
initial begin
    $dumpfile("/home/samhita/6205_labs/lab03/sim/sim_build/uart_receive.fst");
    $dumpvars(0, uart_receive);
end
endmodule
