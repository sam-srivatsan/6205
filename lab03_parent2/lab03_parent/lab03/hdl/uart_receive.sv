`timescale 1ns / 1ps
`default_nettype none

module uart_receive
  #(
    parameter INPUT_CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE = 9600
    )
   (
        input wire 	       clk,
        input wire 	       rst,
        input wire 	       din,
        output logic       dout_valid,
        output logic [7:0] dout
    );

    localparam integer UART_BIT_PERIOD = INPUT_CLOCK_FREQ / BAUD_RATE;
    localparam integer UART_HALF_PERIOD = UART_BIT_PERIOD / 2;
    // buffer the input! 
    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP,
        TRANSMIT
    } uart_state; // uart_state is a 3-bit logic that can be set to any of these values
    // it is 3-bits because there are 5 different states 

    // note: for the online checker, don't rename this variable
    uart_state state; 

    logic [$clog2(UART_BIT_PERIOD) - 1:0] cycle_count; // count how many clock cycles have passed since the current UART bit that is being received began
    // doing the log of this means we use the # of bits needed to represent up to the bit period 

    logic [3:0] data_width; // mcounts how many data bits have been received so far 
    // data is 8 bits, so indices 0-7 is for the data_width 
    // to store 8 values, we need a 3 bit logic 


   always_ff @(posedge clk) begin
    if (rst) begin
        state <= IDLE; 
        cycle_count <= 0; // reinitialize counter to 0 when restarting FSM
        data_width <= 0; // not received any bits yet
        dout <= 0;
        dout_valid <= 0;
    end 

    else if (state == IDLE && din == 0) begin
        dout <= 0;
        data_width <= 0;
        dout_valid <= 0;
        
        // only things to change - just check at the half period 
        cycle_count <= UART_HALF_PERIOD;
        state <= START;
    end

    else if (state == TRANSMIT) begin // just reset the validity and the IDLE cycle 
        dout_valid <= 0;
        state <= IDLE; 
    end 

    else if (state != IDLE) begin

        if (cycle_count == UART_BIT_PERIOD -1) begin 

            if (state == START) begin 
                // check for correct start bit 
                if (din == 0) state <= DATA;
                else state <= IDLE; 

                data_width <= data_width + 1;
                cycle_count <= 0;
            end 


            if (state == STOP) begin
                if (din == 1) begin // correct stop bit 
                    dout_valid <= 1;
                    state <= TRANSMIT;
                end else state <= IDLE;

                data_width <= data_width + 1;
                cycle_count <= 0;
            end 

            if (state == DATA) begin
                dout <= {din, dout[7:1]};
                if (data_width == 8) begin
                    state <= STOP;
                end 
                data_width <= data_width + 1;
                cycle_count <= 0;
            end 
        end
        else begin
            cycle_count <= cycle_count + 1;
        end 
    end 


    // else begin

    //     case (state)
    //         IDLE: begin // detect start bit (waveform line pulls low)
    //             if (din == 0) begin // detect falling edge
    //                 cycle_count <= 0;
    //                 data_width <= 0;
    //                 state <= START; // set state to start 
    //             end
    //         end

   
    //         START: begin
    //             cycle_count <= cycle_count + 1;
    //             if (cycle_count == UART_BIT_PERIOD - 1) begin
    //                 data_width <= data_width + 1;
    //                 cycle_count <= 0;
    //                 if (din == 0) begin 
    //                     state <= DATA;
    //                 end else state <= IDLE;
    //             end else cycle_count <= cycle_count + 1;
    //         end 
         

    //         DATA: begin
    //             if (cycle_count == UART_BIT_PERIOD - 1) begin
    //                 cycle_count <= 0;
    //                 data_width <= data_width + 1;

    //                 if (data_width == 8) state <= STOP;
    //                 dout <= {din, dout[7:1]};
    //                 data_width <= data_width + 1;
    //             end else cycle_count <= cycle_count + 1;
    //         end 

    //         STOP: begin
    //             if (cycle_count == UART_BIT_PERIOD - 1) begin // what if we pass the half period?
    //                 if (din == 1) begin
    //                     dout_valid <= 1;  
    //                     state <= TRANSMIT; // correct stop bit
    //                 end else state <= IDLE; // wrong start bit
    //             end else cycle_count <= cycle_count + 1;
    //         end 


    //         TRANSMIT: begin
    //             state <= IDLE;
    //             dout_valid <= 0;
    //         end 
                
    //     endcase  
    // end 
   end 

endmodule // uart_receive
`default_nettype wire