
module spi_con
     #(parameter DATA_WIDTH = 8,
       parameter DATA_CLK_PERIOD = 100
      )
    (   input wire   clk, //system clock (100 MHz)
        input wire   rst, //reset in signal
        input wire   [DATA_WIDTH-1:0] data_in, //data to send
        input wire   trigger, //start a transaction
        output logic [DATA_WIDTH-1:0] data_out, //data received!
        output logic data_valid, //high when output data is present.
 
        output logic copi, //(Controller-Out-Peripheral-In)
        input wire   cipo, //(Controller-In-Peripheral-Out)
        output logic dclk, //(Data Clock)
        output logic cs // (Chip Select)
 
      );

      logic [DATA_WIDTH-1:0] local_data;
      logic [31:0] cycle_count;
      logic [31:0] dclk_count;
      logic transmitting;

    always_ff @(posedge clk) begin
        if (rst) begin
            cs <= 1; 
            cycle_count <= 32'd0; // if we trigger reset, then set the count back to 0
            dclk_count <= 32'd0; // dclk counter // count for cycles
            transmitting <= 0;
            data_valid <= 0;
            dclk <= 0;
            data_out <= 0;
            local_data <= 0;
            copi <= 0;
        end
        
        else if (transmitting) begin // if currently transmitting state: if the number of dclk oscillations is within width
            cs <= 0;
            if (cycle_count == DATA_CLK_PERIOD-1) begin
                dclk <= 0; // falling edge
                
                cycle_count <= 32'd0; // if we need to manually wrap/reset after a full period

                copi <= local_data[DATA_WIDTH - 1];
                local_data <= local_data << 1; // every time just use msb 

                if (dclk_count == DATA_WIDTH) begin
                    transmitting <= 0;
                    cs <= 1;
                    data_valid <= 1;
                end
            end

            else if (cycle_count == DATA_CLK_PERIOD/2 - 1) begin // set dclk to 1 before the half period
                dclk <= 1; // rising edge at half a period 
                cycle_count <= cycle_count + 1;

                data_out <= {data_out[DATA_WIDTH-2:0], cipo}; // shift top bits to the left and tack on cipo to the end as LSB
                dclk_count <= dclk_count + 1; // you changed dclk

            end 

            else begin
                cycle_count <= cycle_count + 1;
            end

        end

        else if (trigger) begin 
            if (~transmitting) begin
                transmitting <= 1;
                local_data <= data_in;
                cycle_count <= DATA_CLK_PERIOD-1; // we need to actually start at the end of some "other cycle" to trigger
                dclk_count <= 0;
                data_out <= 0;
            end  
        end


        else begin // not in reset, not triggered, not transmitting
            data_valid <= 0;
            cs <= 1;
        end

    end 
endmodule