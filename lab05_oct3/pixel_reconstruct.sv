`timescale 1ns / 1ps
`default_nettype none

module pixel_reconstruct
    #(
        parameter HCOUNT_WIDTH = 11,
        parameter VCOUNT_WIDTH = 10
    )
    (
     input wire                         clk,
     input wire                         rst,
     input wire                         camera_pclk,
     input wire                         camera_h_sync,
     input wire                         camera_v_sync,
     input wire [7:0]                   camera_data,
     output logic                       pixel_valid,
     output logic [HCOUNT_WIDTH-1:0]    pixel_h_count,
     output logic [VCOUNT_WIDTH-1:0]    pixel_v_count,
     output logic [15:0]                pixel_data
     );
    // your code here! and here's a handful of logics that you may find helpful to utilize.

    // previous value of PCLK
    logic  pclk_prev;
    always_ff @(posedge clk) begin
        pclk_prev <= camera_pclk;
        // edge detector 
        //  true when pclk transitions from 0 to 1
    end 

    // another edge detector for falling edge of hsync --> this row is done, vsync ---> this frame is done 
    

    logic camera_sample_valid;
    assign camera_sample_valid = 0; // TODO: fix this assign
    // previous value of camera data, from last valid sample!
    // should NOT update on every cycle of clk, only
    // when samples are valid.
    logic last_sampled_hs;
    logic [7:0] last_sampled_data;
    // flag indicating whether the last byte has been transmitted or not.
    logic half_pixel_ready;

    always_ff@(posedge clk) begin
        if (rst) begin
        end else begin
            if(camera_sample_valid) begin

            end
        end
    end
endmodule

`default_nettype wire