parameter Datawidth = 8;
parameter Addresswidth = 4;

module fifo_read_domain(
                            input [Addresswidth:0] write_ptr_grey_sync,
                            input read_clk,
                            input read_reset,
                            input read_enable,
                            output [Addresswidth-1:0] read_address,
                            output [Addresswidth:0]   read_ptr_grey,
                            output empty
)

wire [Addresswidth:0]read_ptr;
reg [Addresswidth:0]read_address_reg;
wire [Addresswidth:0]read_ptr_next;
wire [Addresswidth:0]read_ptr_grey_next;

always@(posedge read_clk,posedge read_reset)
begin
    if(read_reset)
    begin
        read_ptr <= 0;
        read_address_reg <= 0;
    end
    else if (read_enable && !empty)
    begin
        read_ptr <= read_ptr + 1;
        read_address_reg <= read_ptr[Addresswidth-1:0];
    end
end

assign read_address = read_address_reg;
assign read_ptr_next = read_ptr + 1;

B_G  R1(read_ptr,read_ptr_grey);
B_G  R1(read_ptr_next,read_ptr_grey_next);


assign empty = (read_ptr_grey_next  == write_ptr_grey_sync);

endmodule




module B_G(input [Addresswidth:0]binary,output [ Addresswidth:0]grey);
assign grey = binary ^ (binary >> 1); 
endmodule 

