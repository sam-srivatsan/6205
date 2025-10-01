`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module counter(     input wire clk,
                    input wire rst,
                    input wire [31:0] period,
                    output logic [31:0] count
              );
   always_ff @(posedge clk)begin
     if (rst) begin
       count <= 32'd0; // if we trigger reset, then set the count back to 0
     end
     else if (count >= period - 1) begin
       count <= 32'd0; // if we need to manually wrap/reset after 203 cycles
       // no modulus or division
     end 
     else begin // increment count
       count <= count + 1;
     end
     
	end
endmodule
`default_nettype wire