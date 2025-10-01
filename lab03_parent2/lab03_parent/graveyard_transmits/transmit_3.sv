`default_nettype none 

module evt_counter
    (   input wire          clk,
        input wire          rst,
        input wire          evt,
        output logic[15:0]  count
    );
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 16'b0;
        end else begin
            if (evt) begin
                count <= count + 1;
            end
        end
    end
endmodule


module uart_transmit#(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
   )
    (
  input wire clk,
  input wire rst,
  input wire [7:0] din,
  input wire trigger,
  output logic busy,
  output logic dout
    );

localparam BAUD_PERIOD = INPUT_CLOCK_FREQ/BAUD_RATE;

logic [8:0] buffer_din;
logic transmitting;
logic [$clog2(BAUD_PERIOD-1):0] transmit_counter; // check how many cycles it has been since last transmission
logic [8:0] data_width;

always_ff @(posedge clk) begin
     if (rst) begin
        transmitting <= 0;
        dout <= 1; // clear whatever i was sending as dout
        transmit_counter <= 0;
        data_width <= 0;
        buffer_din <= 0;
        busy <= 0;
     end
     else if (transmitting) begin
        // one bit should take clock_freq/baud_rate number of cycle 
        if (transmit_counter == (BAUD_PERIOD) - 1) begin
            dout <= buffer_din[0];
            buffer_din <= buffer_din >> 1;
            transmit_counter <= 0;
            data_width <= data_width + 1;

            if (data_width == 8) begin
               busy <= 0;
               dout <= 1;
               transmitting <= 0;
               data_width <= 0;
            end
        end 
        else begin 
         transmit_counter <= transmit_counter + 1;
        end
        // if not transmitting in this clock cycle,, then increment the counter for how many cycles to wait till next transmission
     end
     else if (trigger && !transmitting) begin // not transmitting but about to because the trigger is high
        transmitting <= 1;
        dout <= 0; // set start bit
        buffer_din <= {1'b1,din}; // concatenate stop bit with din for a 9 bit input aside from start bit
        busy <= 1;
        transmit_counter <= 0;
        data_width <= 0;
     end
end
endmodule
`default_nettype wire
