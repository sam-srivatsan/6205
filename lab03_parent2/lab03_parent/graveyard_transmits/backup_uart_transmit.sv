`default_nettype none 
module uart_transmit#(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  din,
    input  wire        trigger,
    output logic       busy,
    output logic       dout
);

localparam BAUD_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

logic [8:0] buffer_din;
logic       transmitting;
logic [$clog2(BAUD_PERIOD-1):0] transmit_counter;
logic [8:0] bit_count;

always_ff @(posedge clk) begin
    if (rst) begin
        transmitting      <= 0;
        dout              <= 1; // idle state
        transmit_counter  <= 0;
        bit_count         <= 0;
        buffer_din        <= 0;
        busy              <= 0;
    end
    else if (trigger && !transmitting) begin
        transmitting      <= 1;
        dout              <= 0; // start bit
        buffer_din        <= {1'b1, din}; // stop bit + 8 data bits
        busy              <= 1;
        transmit_counter  <= 0;
        bit_count         <= 0;
    end
    else if (transmitting) begin
        if (transmit_counter == (BAUD_PERIOD - 1)) begin
            dout              <= buffer_din[0];
            buffer_din        <= buffer_din >> 1;
            transmit_counter  <= 0;
            bit_count         <= bit_count + 1;

            if (bit_count == 9) begin // start + 8 data + stop
                busy          <= 0;
                dout          <= 1; // idle line
                transmitting  <= 0;
            end
        end 
        else begin 
            transmit_counter <= transmit_counter + 1;
        end
    end
end

endmodule
`default_nettype wire