module tm_choice (
        input wire [7:0] d, //data byte in
        output logic [8:0] q_m //transition minimized output
    );

    logic [3:0] count_ones; // count to 8
    logic [7:0] dcopy;
    logic [7:0] q_temp;
    int i,j;

    always_comb begin 
        count_ones = 0;
        dcopy = d;

        for (i = 0; i < 8; i = i+1) begin
            count_ones = count_ones + dcopy[i];  
        end 

        // assigning q_temp
        q_temp[0] = d[0];

        if (count_ones > 4 || (count_ones == 4 && d[0] == 0)) begin // option 2, xnor
            for (j = 1; j < 8; j = j+1) begin
                q_temp[j] = ~(q_temp[j-1] ^ d[j]);
            end 
            q_m = {1'b0, q_temp};
        end

        else begin // xor
            for (j = 1; j < 8; j = j+1) begin
                q_temp[j] = q_temp[j-1] ^ d[j];
            end 
            q_m = {1'b1, q_temp};
        end 

    end 

endmodule