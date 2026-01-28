`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 10:56:39
// Design Name: 
// Module Name: systemTop
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
//////////////////////////////////////////////////////////////////////////////////`timescale 1ns/1ps

module systemTop(

    input  wire        clk100,      // 100 MHz system clock
    input  wire        resetn,      // Active low reset

    // OV7670 Camera pins
    input  wire        ov_pclk,
    input  wire        ov_vsync,
    input  wire        ov_href,
    input  wire [7:0]  ov_data,
    inout  wire        ov_sio_c,
    inout  wire        ov_sio_d,

    // VGA output
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [7:0]  vga_r,
    output wire [7:0]  vga_g,
    output wire [7:0]  vga_b
);

    // -----------------------------------------
    // 1. Clocking - generate 25 MHz for VGA
    // -----------------------------------------

    wire clk25;
    wire locked;

    clk_wiz clk_gen (
        .clk_in1(clk100),
        .reset(~resetn),
        .locked(locked),
        .clk_out1(clk25)     // 25 MHz output
    );

    // -----------------------------------------
    // 2. SCCB (I2C) Camera Register Configuration
    // -----------------------------------------

    wire sccb_busy, sccb_done;

    ov7670_sccb sccb_inst (
        .clk(clk100),
        .resetn(resetn),
        .sccb_scl(ov_sio_c),
        .sccb_sda(ov_sio_d),
        .busy(sccb_busy),
        .done(sccb_done)
    );
    
    
    ov7670_init camera_init (
    .clk(sysclk),        // or your system clock
    .resetn(resetn),
    .ready(cam_init_done),  // output ready signal
    .scl(sccb_scl),
    .sda(sccb_sda)
);

    // -----------------------------------------
    // 3. OV7670 Capture (PCLK domain)
    // -----------------------------------------

    wire cam_wr_en;
    wire [15:0] cam_wr_data;
    wire frame_start, frame_end;

    ov7670_capture camera_cap (
        .pclk(ov_pclk),
        .resetn(resetn),
        .vsync(ov_vsync),
        .href(ov_href),
        .d(ov_data),

        .fifo_wr_en(cam_wr_en),
        .fifo_wr_data(cam_wr_data),
        .frame_start(frame_start),
        .frame_end(frame_end)
    );

    // -----------------------------------------
    // 4. FIFO: 16-bit camera pixel buffer
    // -----------------------------------------

    wire fifo_valid;
    wire [15:0] fifo_pixel_16;

    cam_to_proc_fifo fifo_inst (
        .wr_rst_busy(),
        .rd_rst_busy(),

        .s_aclk(ov_pclk),
        .s_aresetn(resetn),
        .s_axis_tvalid(cam_wr_en),
        .s_axis_tready(),
        .s_axis_tdata(cam_wr_data),

        .m_aclk(clk25),
        .m_axis_tvalid(fifo_valid),
        .m_axis_tready(1'b1),
        .m_axis_tdata(fifo_pixel_16)
    );

    // -----------------------------------------
    // 5. RGB565 ? Grayscale conversion
    // -----------------------------------------

    wire [7:0] gray_pixel;

    rgb565_to_gray gray_unit (
        .rgb565(fifo_pixel_16),
        .gray(gray_pixel)
    );

    // -----------------------------------------
    // 6. Image Processing Block
    // -----------------------------------------

    wire proc_valid;
    wire [7:0] proc_pixel;

   

    // -----------------------------------------
    // 7. VGA Display Output
    // -----------------------------------------

    vgaDisplayTop vgaTop (
        .axi_clk(clk25),
        .axi_reset_n(resetn),

        .i_data_valid(proc_valid),
        .i_data(proc_pixel),
        .opcode(4'b1001),

        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_valid()
    );

endmodule

