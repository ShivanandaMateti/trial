module fifo_memory #(
                        parameter Datawidth = 8,
                        parameter Addresswidth = 3
                    )
                    (
                        input write_clk,
                        input read_clk,
                        input write_enable,
                        input read_enable,
                        input [Datawidth-1:0]write_data,
                        input [Addresswidth-1:0]write_address,
                        input [Addresswidth-1:0]read_address,
                        input full,
                        output [Datawidth-1:0]read_data
                   );


localparam depth = 1 << Addresswidth;


reg [Datawidth-1:0] memory [0 : depth-1];
reg [Datawidth-1:0] read_data_reg;
always@(posedge read_clk)
    begin
        if(read_enable)
            read_data_reg = memory[read_address];
    end

assign read_data = read_data_reg;

always@(posedge write_clk)
    begin
     if(write_enable && !full)
            memory[write_address] <= write_data;
    end



endmodule
