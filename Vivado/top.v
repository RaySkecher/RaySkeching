`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: RaySkechers
// Engineer: Zeb
// 
// Create Date: 07/22/2025 11:22:17 AM
// Design Name: RTX ON
// Module Name: top
// Project Name: RaySkecherV1
// Target Devices: Basys 3
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

module top(
    input[15:0] sw,
    output[15:0] led,
    input clk,
    input btnU,
    input btnC,
    input btnL,
    input btnR,
    input btnD,
    output[3:0] vgaRed,
    output[3:0] vgaGreen,
    output[3:0] vgaBlue,
    output Hsync,
    output Vsync,
    output TxD
);

    reg  btnD_r1, btnD_r2;
    wire ap_done, ap_idle, ap_ready, ap_start;
    wire[23:0] ap_return;
    
    always @(posedge clk) begin
        btnD_r1 <= btnD;
        btnD_r2 <= btnD_r1;
    end
    wire btnD_rise = btnD_r1 & ~btnD_r2;
    
    
    wire ap_rst;
    assign ap_rst = btnC;

    reg ap_start_r;
    wire pix_busy;
    always @(posedge clk) begin
        if (ap_rst)                ap_start_r <= 1'b0;
        else if (pix_busy)         ap_start_r <= 1'b0;
        else if (btnD_rise)        ap_start_r <= 1'b1;
    end
    assign ap_start = ap_start_r;
    
    wire[15:0] x, y;
    assign {x[15:8], y[15:8]} = 0;

    reg[23:0] last_val;
    

    assign led[3:0] = last_val[7:4];
    assign led[7:4] = last_val[15:12];
    assign led[11:8] = last_val[23:20];
    
    wire busy;
    wire start;
    reg prev_done;
    reg start_delayed;
    initial prev_done = 0;
    
    always @(posedge clk)
        prev_done <= ap_done;
    always @(posedge clk)
        start_delayed <= start;
    
    reg[7:0] prev_x, prev_y;
    always @(posedge clk) begin
        if (start) begin
            prev_x <= x;
            prev_y <= y;
            last_val <= ap_return;
        end
    end
    
    assign start = ap_done & (~prev_done);
    
    assign led[15] = ap_done;
    assign led[14] = ap_idle;
    assign led[13] = btnD;
    assign led[12] = pix_busy;
    
    wire tp_start;
    
    
    image_pulse ctrl (
        .clk(clk),
        .tgts_busy(busy | ~ap_idle | start | tp_start),
        .start(ap_start),
        .signal(tp_start),
        .x(x[7:0]),
        .y(y[7:0]),
        .busy(pix_busy)
    );
    
    color_transmitter out (
        .clk(clk),
        .reset(ap_rst),
        .start(start),
        .rgb(ap_return),
        .busy(busy),
        .TxD(TxD)
    );
    
    framebuffer_vga_dual vga (
        .clk (clk),
        .rst_btn (ap_rst),
        .wr_x    (prev_x),
        .wr_y    (prev_y),
        .wr_pix  ({last_val[7:5], last_val[15:13], last_val[23:22]}),
        .wr_we   (start_delayed),
        .vga_r   (vgaRed),
        .vga_g   (vgaGreen),
        .vga_b   (vgaBlue),
        .vga_hs  (Hsync),
        .vga_vs  (Vsync)
    );


    trace_path_0 main_fn (
      .ap_clk(clk),        // input wire ap_clk
      .ap_rst(ap_rst),        // input wire ap_rst
      .ap_done(ap_done),      // output wire ap_done
      .ap_idle(ap_idle),      // output wire ap_idle
      .ap_ready(ap_ready),    // output wire ap_ready
      .ap_start(tp_start),    // input wire ap_start
      .ap_return(ap_return),  // output wire [23 : 0] ap_return
      .x(x),                  // input wire [15 : 0] x
      .y(y)                  // input wire [15 : 0] y
    );
endmodule