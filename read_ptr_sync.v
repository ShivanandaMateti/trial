module read_ptr_sync #(
                         parameter Addresswidth = 3
                      )
                      (
                        input [Addresswidth:0]read_ptr_grey,
                        input write_clk,
                        input write_reset,
                        output [Addresswidth:0]read_ptr_grey_sync
                      );


wire [Addresswidth:0] t1;

D_ff  #(.Addresswidth(Addresswidth)) S1 (
                                           .clk(write_clk),
                                           .reset(write_reset),
                                           .d(read_ptr_grey),
                                           .q(t1)
                                        );

D_ff  #(.Addresswidth(Addresswidth)) S2 (
                                           .clk(write_clk),
                                           .reset(write_reset),
                                           .d(t1),
                                           .q(read_ptr_grey_sync)
                                        );

endmodule


module D_ff #(
                parameter Addresswidth = 3
            )
            (
                input clk,
                input reset,
                input [Addresswidth:0] d,
                output [Addresswidth:0] q
            );

reg [Addresswidth:0] q_reg;
always@(posedge clk,posedge reset)
begin
    if(reset)
        q_reg <= 0;
    else
        q_reg <= d;
end

assign q = q_reg;

endmodule


