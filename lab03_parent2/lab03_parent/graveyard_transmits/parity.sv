module parity_checker#(parameter WIDTH = 8)(
  input wire[WIDTH-1:0] data,
    output logic parity
    );

    assign parity = ^{1'b1,data};

endmodule