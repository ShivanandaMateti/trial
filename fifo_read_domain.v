parameter Datawidth = 8;
parameter Addresswidth = 4;

module fifo_read_domain(
                            input [Addresswidth:0] write_ptr_grey_sync,
                            input read_clk,
                            input read_reset,
                            output [Addresswidth-1:0] read_address,
                            output [Addresswidth:0]   read_ptr_grey,
                            output empty,

)

wire read_ptr;
reg read_address_reg;

always@(posedge read_clk,posedge read_reset)
begin
    if(read_reset)
    begin
        read_ptr <= 0;
        read_address_reg <= 0;
    end
    else
    begin
        read_ptr = read_ptr + 1;
        read_address_reg = read_ptr[Addresswidth-1:0];
    end
end

assign read_address = read_address_reg;
assign read_ptr_next = read_ptr + 1;

B_G  R1(read_ptr,read_ptr_grey);

assign empty = (read_ptr_grey  == write_ptr_grey_sync);

endmodule




module B_G(input [Addresswidth:0]binary,output [ Addresswidth:0]grey);
genvar i;
generate for(i=0;i<Addresswidth+1;i=i+1)
        begin : B_G
        if(i==0)
        assign grey[Addresswidth] = binary [ Addresswidth];
        else
        assign grey[Addresswidth-i] = grey[Addresswidth-i-1] ^ binary[Addresswidth-i];
        end
endgenerate
endmodule 

