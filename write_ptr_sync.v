module write_ptr_sync #(
                         parameter Addresswidth = 3
                      )
                      (
                        input [Addresswidth:0]write_ptr_grey,
                        input read_clk,
                        input read_reset,
                        output [Addresswidth:0]write_ptr_grey_sync
                      );


wire [Addresswidth:0] t1;

D_ff  #(.Addresswidth(Addresswidth)) S1 (
                                            .clk(read_clk),
                                            .reset(read_reset),
                                            .d(write_ptr_grey),
                                            .q(t1)
                                        );

D_ff  #(.Addresswidth(Addresswidth)) S2 (
                                            .clk(read_clk),
                                            .reset(read_reset),
                                            .d(t1),
                                            .q(write_ptr_grey_sync)
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


