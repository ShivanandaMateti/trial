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


// Step 1 : read pointer synchronization

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

// Step 2 : Generating write pointer , write address , full


module fifo_write_domain#(
                            parameter Datawidth = 8,
                            parameter Addresswidth = 3
                         )
                         (
                            input write_clk,
                            input write_reset,
                            input [Addresswidth:0] read_ptr_grey_sync,
                            input write_enable,
                            output [Addresswidth-1:0] write_address,
                            output [Addresswidth:0]   write_ptr_grey,
                            output full

                         );

reg [Addresswidth:0] write_ptr;
wire [Addresswidth:0] write_ptr_next;
wire [Addresswidth:0] write_ptr_grey_next;


wire write_inc;
assign write_inc = write_enable & ~full;
assign write_ptr_next = write_ptr + write_inc;

always@(posedge write_clk,posedge write_reset)
begin
    if(write_reset)
        write_ptr <= 0;
    else
        write_ptr <= write_ptr_next;
end

assign write_address = write_ptr[Addresswidth-1:0];

B_G #(Addresswidth) W1 (write_ptr,write_ptr_grey);
B_G #(Addresswidth) W2 (write_ptr_next,write_ptr_grey_next);

reg full_reg;

always@(posedge write_clk,posedge write_reset)
begin
    if(write_reset)
        full_reg<=0;
    else
        full_reg <= ( write_ptr_grey_next == {~read_ptr_grey_sync[Addresswidth:Addresswidth-1],read_ptr_grey_sync[Addresswidth-2:0]});
end

assign full = full_reg;


endmodule




module B_G#(parameter Addresswidth = 3)
           (input [Addresswidth:0]binary,
            output [ Addresswidth:0]grey);
assign grey = binary ^ (binary >> 1); 
endmodule 


// Step 3 : Write pointer Synchronization

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


// Step 4 : generating read address , read pointer , empty


module fifo_read_domain #(
                            parameter Datawidth = 8,
                            parameter Addresswidth = 3
                        )
                        (
                            input [Addresswidth:0] write_ptr_grey_sync,
                            input read_clk,
                            input read_reset,
                            input read_enable,
                            output [Addresswidth-1:0] read_address,
                            output [Addresswidth:0]   read_ptr_grey,
                            output empty
                        );

reg [Addresswidth:0]read_ptr;
wire [Addresswidth:0]read_ptr_next;
wire [Addresswidth:0]read_ptr_grey_next;
wire read_inc;
assign read_inc = read_enable & ~empty;
assign read_ptr_next = read_ptr + read_inc;

always@(posedge read_clk,posedge read_reset)
begin
    if(read_reset)
        read_ptr <= 0;
    else 
        read_ptr <= read_ptr_next;
end

assign read_address = read_ptr[Addresswidth-1:0];

B_G  #(Addresswidth)R1(read_ptr,read_ptr_grey);
B_G  #(Addresswidth)R2(read_ptr_next,read_ptr_grey_next);


reg empty_reg;

always @(posedge read_clk or posedge read_reset)
begin
    if (read_reset)
        empty_reg <= 1'b1;
    else
        empty_reg <= (read_ptr_grey_next == write_ptr_grey_sync);
end

assign empty = empty_reg;

endmodule


// Step 5 and final step : write data in write address , read from read address 


module fifo_memory #(
                        parameter Datawidth = 8,
                        parameter Addresswidth = 3
                    )
                    (
                        input write_clk,
                        input write_enable,
                        input [Datawidth-1:0]write_data,
                        input [Addresswidth-1:0]write_address,
                        input [Addresswidth-1:0]read_address,
                        input full,
                        output [Datawidth-1:0]read_data
                   );


localparam depth = 1 << Addresswidth;


reg [Datawidth-1:0] memory [0 : depth-1];

assign read_data = memory[read_address];

always@(posedge write_clk)
    begin
     if(write_enable && !full)
            memory[write_address] <= write_data;
    end



endmodule
