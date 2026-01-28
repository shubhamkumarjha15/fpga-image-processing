`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.11.2025 10:36:34
// Design Name: 
// Module Name: ov7670_sccb
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

// ov7670_sccb.v
`timescale 1ns/1ps
module ov7670_sccb(
    input clk,            // system clock (e.g., 50-100 MHz)
    input resetn,
    output reg sccb_scl,
    inout  sccb_sda,
    output reg busy,
    output reg done
);

    // Simple open-drain style SDA implementation
    reg sda_o;
    reg sda_oe;
    assign sccb_sda = sda_oe ? sda_o : 1'bz;

    localparam CLK_DIV = 500; // Adjust to get SCL ~100kHz; depends on system clk
    reg [15:0] clk_cnt;
    reg scl_tick;

    // generate slow tick for SCCB bit toggling
    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin clk_cnt <= 0; scl_tick <= 0; end
        else begin
            if(clk_cnt == CLK_DIV-1) begin clk_cnt <= 0; scl_tick <= ~scl_tick; end
            else clk_cnt <= clk_cnt + 1;
        end
    end

    // ROM of register-value pairs (addr[7:0], val[7:0]) packed into 16-bit words
    // TODO: replace with real OV7670 register values for RGB565 and desired resolution
    reg [15:0] sccb_rom [0:31];
    integer rom_len = 10; // actual used entries

    initial begin
        // Example sequence (replace these with actual values)
        // reset (COM7 = 0x12 -> 0x80), then later set RGB565 etc.
        sccb_rom[0] = {8'h12, 8'h80}; // COM7: reset
        sccb_rom[1] = {8'h11, 8'h01}; // CLKRC
        sccb_rom[2] = {8'h12, 8'h04}; // COM7: set output format (example)
        sccb_rom[3] = {8'h3A, 8'h04}; // TSLB (?)
        sccb_rom[4] = {8'h40, 8'h10}; // COM15 (RGB565)
        // ... add more settings ...
        rom_len = 5; // set to number of entries used
    end

    // Simple state machine to write each register via SCCB (write device address 0x42 as per OV7670)
    localparam DEV_ADDR = 8'h42; // SCCB write address (0x21<<1 = 0x42) check datasheet
    reg [7:0] state;
    localparam S_IDLE = 0, S_START=1, S_WRDEV=2, S_WRREG=3, S_WRVAL=4, S_STOP=5, S_NEXT=6, S_DONE=7;

    integer rom_idx;
    reg [7:0] byte_to_send;
    reg [3:0] bitcnt;
    reg [7:0] send_byte;
    reg sending;

    always @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            state <= S_IDLE;
            sda_o <= 1'b1; sda_oe <= 1'b1;
            sccb_scl <= 1'b1;
            busy <= 0;
            done <= 0;
            rom_idx <= 0;
            sending <= 0;
        end else begin
            case(state)
                S_IDLE: begin
                    busy <= 0; done <= 0;
                    if(1) begin // start immediately (or gate by external)
                        busy <= 1;
                        rom_idx <= 0;
                        state <= S_START;
                    end
                end
                S_START: begin
                    // start condition: SDA goes low while SCL high
                    sda_o <= 1'b1; sccb_scl <= 1'b1; sda_oe <= 1'b1;
                    // on next tick assert start
                    state <= S_WRDEV;
                    send_byte <= DEV_ADDR;
                    bitcnt <= 7;
                    sending <= 1;
                end
                S_WRDEV: begin
                    // write device addr byte, bit-bang on scl toggles
                    if(scl_tick) begin
                        // on rising edge: set SDA for next bit
                        sda_o <= send_byte[bitcnt];
                        sda_oe <= 1'b1;
                        sccb_scl <= 1'b0;
                    end else begin
                        sccb_scl <= 1'b1;
                        if(bitcnt == 0) state <= S_WRREG;
                        else bitcnt <= bitcnt - 1;
                    end
                end
                S_WRREG: begin
                    // send reg address
                    send_byte <= sccb_rom[rom_idx][15:8];
                    bitcnt <= 7;
                    state <= S_WRVAL;
                end
                S_WRVAL: begin
                    // send reg value
                    // Note: this is a simplified combined sequence: device->reg->value
                    if(scl_tick) begin
                        sda_o <= send_byte[bitcnt];
                        sccb_scl <= 1'b0;
                    end else begin
                        sccb_scl <= 1'b1;
                        if(bitcnt==0) begin
                            // move to send value
                            send_byte <= sccb_rom[rom_idx][7:0];
                            bitcnt <= 7;
                            state <= S_NEXT;
                        end else bitcnt <= bitcnt - 1;
                    end
                end
                S_NEXT: begin
                    // send value
                    if(scl_tick) begin
                        sda_o <= send_byte[bitcnt];
                        sccb_scl <= 1'b0;
                    end else begin
                        sccb_scl <= 1'b1;
                        if(bitcnt==0) begin
                            rom_idx <= rom_idx + 1;
                            if(rom_idx >= rom_len) state <= S_DONE;
                            else begin
                                // send next register: start again
                                send_byte <= DEV_ADDR;
                                bitcnt <= 7;
                                state <= S_WRDEV;
                            end
                        end else bitcnt <= bitcnt - 1;
                    end
                end
                S_DONE: begin
                    busy <= 0; done <= 1;
                    state <= S_DONE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
