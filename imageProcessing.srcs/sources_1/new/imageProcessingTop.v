`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2025 16:21:26
// Design Name: 
// Module Name: imageProcessingTop
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

module imageProcessTop(
    input         axi_clk,
    input         axi_reset_n,
    
    // AXI Slave Interface
    input         i_data_valid,
    input  [7:0]  i_data,
    output        o_data_ready,
    
    // AXI Master Interface
    output        o_data_valid,
    output [7:0]  o_data,
    input         i_data_ready,
    
    // Control
    input  [3:0]  opcode,      // <--- new opcode input for operation selection
    
    // Interrupt output
    output        o_intr
);

    // Internal signals
    wire [71:0] pixel_data;
    wire        pixel_data_valid;
    wire [3:0]  opcode_sync;       // synchronized opcode from imageControl
    wire        axis_prog_full;
    wire [7:0]  convolved_data;
    wire        convolved_data_valid;

    // Backpressure: allow new input only if output buffer not full
    assign o_data_ready = !axis_prog_full;

    // ------------------------------------------------------------
    // Image Control Block
    // ------------------------------------------------------------
    imageControl IC (
        .i_clk(axi_clk),
        .i_rst(!axi_reset_n),
        .i_pixel_data(i_data),
        .i_pixel_data_valid(i_data_valid),
        .i_opcode(opcode),              // <--- new input
        .o_pixel_data(pixel_data),
        .o_pixel_data_valid(pixel_data_valid),
        .o_opcode(opcode_sync),         // <--- synchronized opcode output
        .o_intr(o_intr)
    );

    // ------------------------------------------------------------
    // Convolution Block (Filter Processor)
    // ------------------------------------------------------------
    conv CONV (
        .i_clk(axi_clk),
        .i_pixel_data(pixel_data),
        .i_pixel_data_valid(pixel_data_valid),
        .opcode(opcode_sync),           // use synced opcode for stability
        .o_convolved_data(convolved_data),
        .o_convolved_data_valid(convolved_data_valid)
    );

    // ------------------------------------------------------------
    // Output Buffer (AXI Stream FIFO)
    // ------------------------------------------------------------
    outputBuffer OB (
        .wr_rst_busy(),       
        .rd_rst_busy(),       
        .s_aclk(axi_clk),
        .s_aresetn(axi_reset_n),
        .s_axis_tvalid(convolved_data_valid),
        .s_axis_tready(),              
        .s_axis_tdata(convolved_data),
        .m_axis_tvalid(o_data_valid),
        .m_axis_tready(i_data_ready),
        .m_axis_tdata(o_data),
        .axis_prog_full(axis_prog_full)
    );

endmodule
