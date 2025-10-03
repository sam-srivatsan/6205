module test_pattern_generator(
        input wire [1:0] pattern_select,
        input wire [10:0] h_count,
        input wire [9:0] v_count,
        output logic [7:0] pixel_red,
        output logic [7:0] pixel_green,
        output logic [7:0] pixel_blue
    );
    //your code here.
    //logic should be purely combinational
    logic [8:0] sum;
    assign sum = h_count + v_count; 

    always_comb begin
        case (pattern_select) 
            2'b00: begin // navy blur
                pixel_red = 102;
                pixel_green = 106;
                pixel_blue = 76;
            end 
            2'b01: begin
                if (v_count == 360 || h_count == 640) begin
                    pixel_red = 255;
                    pixel_green = 255;
                    pixel_blue = 255;
                end else begin
                    pixel_red = 0;
                    pixel_green = 0;
                    pixel_blue = 0;
                end 
            end 
            2'b10: begin
                pixel_red = h_count[7:0];
                pixel_green = h_count[7:0];
                pixel_blue = h_count[7:0];
            end
            2'b11: begin
                pixel_red = h_count[7:0];
                pixel_green = v_count[7:0];
                pixel_blue = sum[7:0];
            end 
        endcase
    end 

endmodule