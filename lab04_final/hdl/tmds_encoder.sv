`timescale 1ns / 1ps
`default_nettype none
 
module tmds_encoder(
        input wire clk,
        input wire rst,
        input wire [7:0] video_data,  // video data (red, green or blue)
        input wire [1:0] control,   //for blue set to {vs,hs}, else will be 0
        input wire video_enable,    //choose between control (0) or video (1)
        output logic [9:0] tmds
    );

    logic [8:0] q_m;
    logic [4:0] tally;
    logic [4:0] count_ones;
    logic [4:0] count_zeros;
    int i;
 
    tm_choice mtm(
        .d(video_data),
        .q_m(q_m)
    );

    always_comb begin
        count_ones = 0;

        for (i = 0; i < 8; i = i+1) begin
            count_ones = count_ones + q_m[i];  
        end 

        count_zeros = 8 - count_ones;
    end 
 
    always_ff @(posedge clk) begin
        if (rst) begin
            tally <= 0;
            tmds <= 0;
        end 

        if (!video_enable) begin
            case (control)
                2'b00: tmds <= 10'b1101010100;
                2'b01: tmds <= 10'b0010101011;
                2'b10: tmds <= 10'b0101010100;
                2'b11: tmds <= 10'b1010101011;
            endcase 
            tally <= 0;
        end 

        else begin // have enabled video
            if (tally == 0 || (count_ones == count_zeros)) begin
                tmds[9] <= ~q_m[8];
                tmds[8] <= q_m[8];
                tmds[7:0] <= (q_m[8]) ? q_m[7:0] : ~q_m[7:0];
                
                if (q_m[8] == 0) begin
                    tally <= tally + (count_zeros - count_ones); // does this make sense when the counting is in comb? 
                    // yes bc we only need to count once from the input, not on Every clock cycle like spi/uart
                end else begin
                    tally <= tally + (count_ones - count_zeros);
                end 
            end 

            else begin
                if ((tally[4] == 0 && (count_ones > count_zeros)) || (tally[4] == 1 && (count_zeros > count_ones)) ) begin
                    tmds[9] <= 1;
                    tmds[8] <= q_m[8];
                    tmds[7:0] <= ~q_m[7:0];
                    tally <= tally + 5'h2*q_m[8] + (count_zeros - count_ones);
                end else begin
                    tmds[9] <= 0;
                    tmds[8] = q_m[8];
                    tmds[7:0] <= q_m[7:0];
                    tally <= tally - 5'h2*(!q_m[8]) + (count_ones - count_zeros);
                end 
            end 

        end


  end 
 
endmodule
 
`default_nettype wire