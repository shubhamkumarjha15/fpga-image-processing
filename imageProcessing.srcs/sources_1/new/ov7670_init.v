`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.11.2025 10:54:22
// Design Name: 
// Module Name: ov7670_init
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

// ov7670_init.v
`timescale 1ns / 1ps
module ov7670_init(
    input  wire clk,         // system clock (e.g. 50 MHz or 25 MHz)
    input  wire rstn,        // active low reset
    output reg  done,        // goes high when init completed
    // SCCB/I2C low-level interface (simple handshake)
    output reg  sccb_start,  // pulse to start one write
    input  wire sccb_busy,   // SCCB busy high while transfer
    output reg  [7:0] sccb_addr, // 7-bit device register address (8-bit bus)
    output reg  [7:0] sccb_data  // data to write
);

    // OV7670 I2C address is 0x42/0x43 for write/read, but here we only send register/address pairs
    // Register list for RGB565 VGA mode (common subset). Add/modify as needed.
    localparam N = 28; // number of reg/value pairs

    reg [15:0] rom [0:N-1];
    initial begin
        // {reg_addr, reg_val}
        // Typical registers to set RGB565, VGA, PLL, enable output
        // These values are standard common starting points; adjust for your sensor variant.
        rom[0]  = {8'h12, 8'h80}; // COM7: reset
        rom[1]  = {8'h12, 8'h04}; // COM7: RGB format (COM7[2]=1 -> RGB)
        rom[2]  = {8'h11, 8'h01}; // CLKRC: internal clock prescaler
        rom[3]  = {8'h0C, 8'h04}; // COM3: enable scaling?
        rom[4]  = {8'h3E, 8'h19}; // COM14 set PCLK divider / scale
        rom[5]  = {8'h8C, 8'h00}; // RGB444 off
        rom[6]  = {8'h40, 8'hD0}; // COM15 set RGB565 (COM15[1]=1)
        rom[7]  = {8'h3A, 8'h04}; // TSLB maybe
        rom[8]  = {8'h15, 8'h00}; // COM10: vsync settings
        rom[9]  = {8'h17, 8'h11}; // HSTART
        rom[10] = {8'h18, 8'h75}; // HSTOP
        rom[11] = {8'h32, 8'h36}; // HREF
        rom[12] = {8'h19, 8'h02}; // VSTART
        rom[13] = {8'h1A, 8'h7a}; // VSTOP
        rom[14] = {8'h03, 8'h0a}; // VREF
        rom[15] = {8'h0e, 8'h61}; // COM5/others
        rom[16] = {8'h0f, 8'h4b}; 
        rom[17] = {8'h16, 8'h02}; 
        // More registers often required to get stable VGA + lighting etc.
        // Add extra entries if needed to tune exposure/AGC/white balance.
        rom[18] = {8'ha2, 8'h02};
        rom[19] = {8'h29, 8'h00};
        rom[20] = {8'h2b, 8'h00};
        rom[21] = {8'h6b, 8'h0a};
        rom[22] = {8'h3b, 8'h0a};
        rom[23] = {8'h4f, 8'h80};
        rom[24] = {8'h50, 8'h80};
        rom[25] = {8'h11, 8'h00}; // set clock maybe final
        rom[26] = {8'h12, 8'h04}; // ensure RGB mode
        rom[27] = {8'h00, 8'h00}; // (optional) NOP/terminator
    end

    reg [7:0] idx;
    reg state;
    localparam S_IDLE = 1'b0, S_SEND = 1'b1;

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            idx <= 0;
            sccb_start <= 1'b0;
            sccb_addr <= 8'd0;
            sccb_data <= 8'd0;
            done <= 1'b0;
            state <= S_IDLE;
        end else begin
            sccb_start <= 1'b0; // pulse only
            if (done) begin
                // keep done high once finished
            end else begin
                case (state)
                    S_IDLE: begin
                        if (idx < N) begin
                            // load next pair
                            sccb_addr <= rom[idx][15:8];
                            sccb_data <= rom[idx][7:0];
                            // start write
                            sccb_start <= 1'b1;
                            state <= S_SEND;
                        end else begin
                            done <= 1'b1;
                        end
                    end
                    S_SEND: begin
                        // wait for sccb_busy to finish (assuming busy goes high when transfer in progress)
                        if (!sccb_busy) begin
                            // transfer finished -> move to next
                            idx <= idx + 1;
                            state <= S_IDLE;
                        end
                    end
                endcase
            end
        end
    end

endmodule
