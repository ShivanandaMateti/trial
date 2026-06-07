parameter Datawidth = 8;
parameter Addresswidth = 3;

module fifo_memory(
                        input write_clk,
                        input write_reset,
                        input [Datawidth-1:0]write_data,
                        input [Addresswidth-1:0]write_address,
                        input [Addresswidth-1:0]read_address,
                        input full,
                        output [Datawidth-1:0]read_data
                   );


localparam depth;
assign depth = 1 << Addresswidth;
reg [Datawidth-1:0] memory [depth-1:0];

assign read_data = memory[read_address];

always@(posedge write_clk )
    begin
        if(!full)
            memory[write_address] <= write_data;
    end
endmodule