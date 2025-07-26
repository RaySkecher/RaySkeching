`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/26/2025 08:18:56 AM
// Design Name: 
// Module Name: image_pulse
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


module image_pulse(
    input clk,
    input tgts_busy,
    input start,
    output reg signal,
    output[7:0] x,
    output[7:0] y,
    output busy
);
    reg[15:0] idx;
    assign { y, x } = idx;
    
    assign busy = idx != 0;
    
    always @(posedge clk) begin
        if (start & ~busy) begin
            idx <= 1;
            signal <= 1;
        end else if (busy & ~tgts_busy & ~signal) begin
            idx <= idx + 1;
            signal <= 1;
        end else begin
            signal <= 0;
        end
    end
endmodule
