`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Mayank Garg
// Project: FPGA-Based VGA Image Processing
// Description: VGA simulation testbench + PPM capture
//////////////////////////////////////////////////////////////////////////////////

module tb;

    // -------------------
    // Clock + Reset
    // -------------------
    reg clk;
    reg reset_n;

    initial begin
        clk = 0;
        forever #20 clk = ~clk;   // 25 MHz clock (VGA clock)
    end

    initial begin
        reset_n = 0;
        #200;
        reset_n = 1;
    end

    // -------------------
    // Input pixel interface (to imageProcessTop)
    // -------------------
    reg [7:0] pixel_in;
    reg pixel_valid;
    reg [3:0] opcode;

    initial begin
        opcode = 4'b1001;    // Example: Sobel Edge Detection
    end

    // -------------------
    // VGA Output wires
    // -------------------
    wire hsync, vsync;
    wire [7:0] vga_r, vga_g, vga_b;
    wire vga_valid;
    wire intr;

    // -------------------
    // DUT instance
    // -------------------
    vgaDisplayTop dut (
        .axi_clk(clk),
        .axi_reset_n(reset_n),
        .i_data_valid(pixel_valid),
        .i_data(pixel_in),
        .opcode(opcode),
        .vga_hsync(hsync),
        .vga_vsync(vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_valid(vga_valid),
        .o_intr(intr)
    );


    // -------------------
    // Send 512×512 synthetic test image
    // -------------------
    integer x, y;

    initial begin
        pixel_valid = 0;
        pixel_in = 0;

        // wait for reset release
        @(posedge reset_n);
        #200;

        $display("STARTING 512x512 IMAGE FEED...");

        for (y = 0; y < 512; y = y + 1) begin
            for (x = 0; x < 512; x = x + 1) begin
                @(posedge clk);
                pixel_in   <= (x + y) % 256;  // synthetic pattern
                pixel_valid <= 1;
            end
        end

        @(posedge clk);
        pixel_valid <= 0;

        $display("IMAGE FEED DONE.");
    end


    // -------------------
    // VGA FRAME CAPTURE (PPM format)
    // -------------------
    integer file_ppm;
    integer pixel_count;

    localparam H_VISIBLE = 640;
    localparam V_VISIBLE = 480;

    initial begin
        pixel_count = 0;

        file_ppm = $fopen("vga_output.ppm", "w");
        if (file_ppm == 0) begin
            $display("ERROR: Cannot open PPM output file!");
            $stop;
        end

        // PPM header (ASCII Format)
        $fwrite(file_ppm, "P3\n%d %d\n255\n", H_VISIBLE, V_VISIBLE);

        @(posedge reset_n);
        $display("RESET DONE - Starting VGA capture");

        // Capture exactly 640×480 valid pixels
        while (pixel_count < (H_VISIBLE * V_VISIBLE)) begin
            @(posedge clk);

            if (vga_valid) begin
                $fwrite(file_ppm, "%0d %0d %0d\n", vga_r, vga_g, vga_b);
                pixel_count = pixel_count + 1;
            end
        end

        $display("PPM FILE GENERATED SUCCESSFULLY!");
        $fclose(file_ppm);
        $stop;
    end


endmodule
