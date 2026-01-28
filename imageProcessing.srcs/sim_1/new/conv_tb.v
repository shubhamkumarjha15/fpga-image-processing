`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 16:03:38
// Design Name: 
// Module Name: conv_tb
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


`timescale 1ns / 1ps

module conv_tb;

    // Inputs
    reg clk;
    reg [71:0] pixel_data;
    reg pixel_valid;
    reg [3:0] opcode;

    // Outputs
    wire [7:0] out_pixel;
    wire out_valid;

    // Instantiate DUT (Device Under Test)
    conv uut (
        .i_clk(clk),
        .i_pixel_data(pixel_data),
        .i_pixel_data_valid(pixel_valid),
        .opcode(opcode),
        .o_convolved_data(out_pixel),
        .o_convolved_data_valid(out_valid)
    );

    // Clock generation (10 ns period)
    always #5 clk = ~clk;

    // Initialize signals
    initial begin
        clk = 0;
        pixel_valid = 0;
        opcode = 4'b0000;
        pixel_data = 72'd0;

        // Dumpfile for GTKWave
        $dumpfile("conv_all_wave.vcd");
        $dumpvars(0, conv_tb);

        $display("----- FPGA Image Processing Test Start -----");

        // ---------------------------------------------
        // TEST 1: BLUR FILTER (opcode = 1000)
        // ---------------------------------------------
        #20;
        opcode = 4'b1000;
        pixel_data = {9{8'd50}}; // uniform pixels
        pixel_valid = 1;
        #10 pixel_valid = 0;
        #50;
        if (out_valid)
            $display("Time=%0t | BLUR | Output Pixel = %0d", $time, out_pixel);

        // ---------------------------------------------
        // TEST 2: EDGE DETECTION (opcode = 1001)
        // ---------------------------------------------
        #50;
        opcode = 4'b1001;
        pixel_data = {8'd10, 8'd20, 8'd30, 8'd40, 8'd50, 8'd60, 8'd70, 8'd80, 8'd90};
        pixel_valid = 1;
        #10 pixel_valid = 0;
        #100;
        if (out_valid)
            $display("Time=%0t | EDGE DETECTION | Output Pixel = %0d", $time, out_pixel);

        // ---------------------------------------------
        // TEST 3: COLOR INVERSION (opcode = 0011)
        // ---------------------------------------------
        #50;
        opcode = 4'b0011;
        pixel_data = {9{8'd100}}; // All pixels = 100
        pixel_valid = 1;
        #10 pixel_valid = 0;
        #50;
        if (out_valid)
            $display("Time=%0t | COLOR INVERSION | Output Pixel = %0d", $time, out_pixel);
        // Expected = 155 (255 - 100)

        // ---------------------------------------------
        // TEST 4: SHARPEN FILTER (opcode = 1101)
        // ---------------------------------------------
        #50;
        opcode = 4'b1101;
        // Slightly higher center value to observe sharpening
        pixel_data = {8'd30, 8'd40, 8'd30, 8'd40, 8'd60, 8'd40, 8'd30, 8'd40, 8'd30};
        pixel_valid = 1;
        #10 pixel_valid = 0;
        #100;
        if (out_valid)
            $display("Time=%0t | SHARPEN | Output Pixel = %0d", $time, out_pixel);

        // ---------------------------------------------
        // END SIMULATION
        // ---------------------------------------------
        #50;
        $display("----- Simulation completed successfully at time %0t -----", $time);
        $stop;
    end

endmodule

