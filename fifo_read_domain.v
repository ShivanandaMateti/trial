parameter Datawidth = 8;
parameter Addresswidth = 3;

module fifo_read_domain(
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




module B_G#(parameter Addresswidth = 3)
           (input [Addresswidth:0]binary,
            output [ Addresswidth:0]grey);
assign grey = binary ^ (binary >> 1); 
endmodule 

