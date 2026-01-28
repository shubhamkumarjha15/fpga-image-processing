`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 10:37:44
// Design Name: 
// Module Name: ov7670_capture
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


// ov7670_capture.v
`timescale 1ns/1ps
module ov7670_capture (
    input  pclk,         // pixel clock from camera
    input  resetn,
    input  vsync,        // frame sync (active high typically)
    input  href,         // line valid
    input  [7:0] d,      // data bus from camera
    // FIFO write interface (camera domain)
    output reg fifo_wr_en,
    output reg [15:0] fifo_wr_data,
    output reg frame_start,
    output reg frame_end
);

    reg [7:0] byte_latch;
    reg byte_toggle;

    always @(posedge pclk or negedge resetn) begin
        if(!resetn) begin
            byte_latch <= 0;
            byte_toggle <= 0;
            fifo_wr_en <= 0;
            fifo_wr_data <= 0;
            frame_start <= 0;
            frame_end <= 0;
        end else begin
            fifo_wr_en <= 0;
            frame_start <= 0;
            frame_end <= 0;

            if(vsync) begin
                // VSYNC active - new frame boundary
                // Depending on camera polarity you might need to adjust
            end

            if(vsync == 1'b1) begin
                // some cameras assert vsync during blanking
                // frame start detection: falling edge of vsync or rising per datasheet
            end

            if(href) begin
                // valid pixel data on D during href. The camera outputs pixels as two sequential bytes (MSB, LSB)
                if(!byte_toggle) begin
                    // latch first byte (MSB)
                    byte_latch <= d;
                    byte_toggle <= 1;
                end else begin
                    // second byte -> assemble 16-bit pixel and write to FIFO
                    fifo_wr_data <= {byte_latch, d}; // MSB:byte_latch, LSB:d
                    fifo_wr_en <= 1;
                    byte_toggle <= 0;
                end
            end else begin
                byte_toggle <= 0;
            end
        end
    end

endmodule
