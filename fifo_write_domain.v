module fifo_write_domain#(
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

assign full = full_reg;  // to generate full we use the greycode pointers only 


endmodule




module B_G#(parameter Addresswidth = 3)
           (input [Addresswidth:0]binary,
            output [ Addresswidth:0]grey);
assign grey = binary ^ (binary >> 1); 
endmodule 