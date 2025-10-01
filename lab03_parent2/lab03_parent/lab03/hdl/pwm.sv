`default_nettype none

module pwm(   input wire clk,
              input wire rst,
              input wire [7:0] dc_in,
              output logic sig_out);

    logic [7:0] actual_dc;
    logic [31:0] count;
    counter mc (.clk(clk),
                .rst(rst),
                .period(255), // time on + time off or the maximum % 
                .count(count));

    always_comb begin
        if (count == 0) begin 
            actual_dc = dc_in;
        end
        // else begin
        //     actual_dc <= actual_dc;
        // end

        // does this count as accidental latching?
        // else preserve the value of actual_dc
    
    end
    
    assign sig_out = count<actual_dc;
endmodule
`default_nettype wire