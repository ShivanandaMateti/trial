module fifo_top#(
                    parameter Datawidth = 8,
                    parameter Addresswidth = 3
                )
                (
                    input [Datawidth-1:0] write_data,
                    input write_enable,
                    input write_clk,
                    input write_reset,
                    input read_enable,
                    input read_clk,
                    input read_reset,
                    output [Datawidth-1:0] read_data,
                    output empty,
                    output full
                );


wire [Addresswidth:0] read_ptr_grey;
wire [Addresswidth:0] read_ptr_grey_sync;
wire [Addresswidth:0] write_ptr_grey;
wire [Addresswidth:0] write_ptr_grey_sync;
wire [Addresswidth-1:0] write_address;
wire [Addresswidth-1:0] read_address;

read_ptr_sync  #(.Addresswidth(Addresswidth)) I1(
                                                    .read_ptr_grey(read_ptr_grey),
                                                    .write_clk(write_clk),
                                                    .write_reset(write_reset),
                                                    .read_ptr_grey_sync(read_ptr_grey_sync)
                                                );

fifo_write_domain  #(   .Datawidth(Datawidth),
                        .Addresswidth(Addresswidth)
                    )
                    I2
                    (
                        .write_clk(write_clk),
                        .write_reset(write_reset),
                        .write_enable(write_enable),
                        .read_ptr_grey_sync(read_ptr_grey_sync),
                        .write_address(write_address),
                        .write_ptr_grey(write_ptr_grey),
                        .full(full)
                    );

write_ptr_sync  #(.Addresswidth(Addresswidth)) I3(
                                                    .write_ptr_grey(write_ptr_grey),
                                                    .read_clk(read_clk),
                                                    .read_reset(read_reset),
                                                    .write_ptr_grey_sync(write_ptr_grey_sync)
                                                 );

fifo_read_domain   #(   .Datawidth(Datawidth),
                        .Addresswidth(Addresswidth)
                    )
                    I4
                    (
                        .read_clk(read_clk),
                        .read_reset(read_reset),
                        .read_enable(read_enable),
                        .write_ptr_grey_sync(write_ptr_grey_sync),
                        .read_address(read_address),
                        .read_ptr_grey(read_ptr_grey),
                        .empty(empty)
                    ); 

fifo_memory   #(
                    .Addresswidth(Addresswidth),
                    .Datawidth(Datawidth)
               )
               I5
               (
                    .write_clk(write_clk),
                    .write_enable(write_enable),
                    .write_data(write_data),
                    .write_address(write_address),
                    .read_address(read_address),
                    .full(full),
                    .read_data(read_data)
               );

endmodule
