`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 15:42:13
// Design Name: 
// Module Name: lineBuffer_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module lineBuffer_tb;

    // Inputs
    reg i_clk;
    reg i_rst;
    reg [7:0] i_data;
    reg i_data_valid;
    reg i_rd_data;

    // Output
    wire [23:0] o_data;

    // Instantiate the DUT
    lineBuffer uut (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_data(i_data),
        .i_data_valid(i_data_valid),
        .o_data(o_data),
        .i_rd_data(i_rd_data)
    );

    // Clock generation: 10ns period (100 MHz)
    always #5 i_clk = ~i_clk;

    integer i;

    initial begin
        $display("------ Simulation Started ------");
        $dumpfile("lineBuffer_tb.vcd");
        $dumpvars(0, lineBuffer_tb);

        // Initialize signals
        i_clk = 0;
        i_rst = 1;
        i_data = 8'd0;
        i_data_valid = 0;
        i_rd_data = 0;

        // Hold reset for a few cycles
        #20;
        i_rst = 0;

        // Write 16 sample data bytes into the buffer
        $display("Writing data into line buffer...");
        for (i = 0; i < 16; i = i + 1) begin
            @(posedge i_clk);
            i_data <= i;
            i_data_valid <= 1;
        end

        // Stop writing
        @(posedge i_clk);
        i_data_valid <= 0;
        i_data <= 8'd0;

        // Wait a few cycles before reading
        #20;

        // Read out concatenated pixel groups
        $display("Reading concatenated data...");
        for (i = 0; i < 14; i = i + 1) begin
            @(posedge i_clk);
            i_rd_data <= 1;
            $display("Time=%0t | rdPntr=%0d | o_data = {%0d,%0d,%0d}",
                     $time,
                     i,
                     uut.line[uut.rdPntr],
                     uut.line[uut.rdPntr+1],
                     uut.line[uut.rdPntr+2]);
        end

        // Stop reading
        @(posedge i_clk);
        i_rd_data <= 0;

        #50;
        $display("------ Simulation Finished ------");
        $finish;
    end

endmodule

