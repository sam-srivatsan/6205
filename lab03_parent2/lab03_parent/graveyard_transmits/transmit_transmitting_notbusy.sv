`default_nettype none

module evt_counter
    (   input wire          clk,
        input wire          rst,
        input wire          evt,
        output logic[15:0]  count
    );
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= 0;
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
)(
    input wire clk,
    input wire rst,
    input wire [7:0] din,
    input wire trigger,
    output logic busy,
    output logic dout
);

    localparam BAUD_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;

    logic [8:0] buffer_din;
    logic transmitting;

    logic baud_evt;       // enable baud counter up til next transmission 
    logic width_evt;      // enable bit counter of how many bits we sent
    logic [15:0] baud_count;
    logic [15:0] bit_count;

    // inst evt_counter for baud rate timing
    evt_counter baud_counter (
        .clk(clk),
        .rst(rst || !transmitting),  // reset when not transmitting
        .evt(baud_evt),
        .count(baud_count)
    );

    // inst evt_counter for bit count (width)
    evt_counter bit_counter (
        .clk(clk),
        .rst(rst || !transmitting),
        .evt(width_evt),
        .count(bit_count)
    );

    // Control logic
    always_ff @(posedge clk) begin
        if (rst) begin
            transmitting <= 0;
            dout <= 1;
            buffer_din <= 0;
            busy <= 0;
            baud_evt <= 0;
            width_evt <= 0;
        end
        else if (transmitting) begin
            baud_evt <= 1;
            if (baud_count == (BAUD_PERIOD - 1)) begin
                if (bit_count == 8) begin
                    transmitting <= 0;
                    dout <= 1;
                    busy <= 0;
                end 
                else begin
                    dout <= buffer_din[0];
                    buffer_din <= buffer_din >> 1;
                    baud_evt <= 0;   // pulse evt signal (1 cycle)
                    width_evt <= 1;  // count number of bits sent
                end 
            end else begin
                width_evt <= 0;  // only increment bit count once per bit
            end
        end
        else if (trigger && !transmitting) begin
            transmitting <= 1;
            dout <= 0; // start bit
            buffer_din <= {1'b1, din}; // add stop bit at the end
            busy <= 1;
        end
    end

endmodule
`default_nettype wire
