`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.11.2025 11:47:52
// Design Name: 
// Module Name: rgb565_to_gray
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

module rgb565_to_gray(
    input  [15:0] rgb565,
    output [7:0] gray
);

    wire [4:0] r5 = rgb565[15:11];
    wire [5:0] g6 = rgb565[10:5];
    wire [4:0] b5 = rgb565[4:0];

    wire [7:0] r8 = {r5, r5[2:0]};
    wire [7:0] g8 = {g6, g6[1:0]};
    wire [7:0] b8 = {b5, b5[2:0]};

    assign gray = (r8>>2) + (g8>>1) + (b8>>2);

endmodule

