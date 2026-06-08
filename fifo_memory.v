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
                        input empty,
                        output [Datawidth-1:0]read_data
                   );


localparam depth = 1 << Addresswidth;


reg [Datawidth-1:0] memory [0 : depth-1];

assign read_data = (empty) ? 0 : memory[read_address];

always@(posedge write_clk)
    begin
     if(write_enable && !full)
            memory[write_address] <= write_data;
    end



endmodule