`default_nettype none 
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
    logic [$clog2(BAUD_PERIOD):0] transmit_counter;  // keep track of how many cycles since last transmission 
    // ********************* 
    logic [3:0] bit_counter; // how many bits i have transmitted so far, represent up to 8
    logic [7:0] buffer_input; // 8 bit

    always_ff @(posedge clk) begin

        if (rst) begin 
            // dout <= 1; 
            transmit_counter <= 0;
            busy <= 0;
            bit_counter <= 0;
        end 

        else if (!busy && trigger) begin // not transmitting but read a trigger
            busy <= 1;
            buffer_input <= din; 

            dout <= 0; // start bit 
            bit_counter <= 0; // we start counting the 8 + stop bits after this 
            // transmit_counter <= 1; 

        end

        else if (busy) begin
            if (transmit_counter == (BAUD_PERIOD - 1)) begin
                buffer_input <= buffer_input >> 1; // happens in next cycle
                if (bit_counter == 8) begin
                    dout <= 1;
                    bit_counter <= bit_counter + 1;
                    transmit_counter <= 0;
                end 
                else if (bit_counter == 9) begin
                    dout <= 1;
                    bit_counter <= bit_counter + 1;
                    transmit_counter <= 0;
                    busy <= 0;
                end 
                else begin // have transmitted 0-7 bits 
                    dout <= buffer_input[0];
                    bit_counter <= bit_counter + 1;
                    transmit_counter <= 0; // have just transmitted a bit
                end 
            end 
            // could be busy and not ready to transmit! 
            else transmit_counter <= transmit_counter + 1;
        end 
    end

endmodule
`default_nettype wire