`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: RaySkechers
// Engineer: ChatGPT (for Zeb)
// 
// 256 × 256 dual-port framebuffer with centred 640 × 480 VGA output
// • Port-A  = read  (25 MHz pixel domain)
// • Port-B  = write (100 MHz system domain, single-cycle strobe wr_we)
// Colours   = 8-bit RRRGGGBB → 4-bit nibble per VGA channel
//////////////////////////////////////////////////////////////////////////////////

module framebuffer_vga_dual
(
    //---------------------------------------------------------------------------
    // Clocks / reset
    //---------------------------------------------------------------------------
    input  wire        clk,       // 100 MHz (Basys-3)
    input  wire        rst_btn,   // active-high reset (btnC)

    //---------------------------------------------------------------------------
    // WRITE SIDE  (Port-B)  --- clk domain
    //---------------------------------------------------------------------------
    input  wire [7:0]  wr_x,
    input  wire [7:0]  wr_y,
    input  wire [7:0]  wr_pix,
    input  wire        wr_we,     // 1-cycle strobe

    //---------------------------------------------------------------------------
    // VGA output pins  --- 25 MHz pixel domain (derived on-chip)
    //---------------------------------------------------------------------------
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b,
    output reg         vga_hs,
    output reg         vga_vs
);

    ////////////////////////////////////////////////////////////////////////////
    // 25 MHz pixel-tick generator  (÷4 from 100 MHz)
    ////////////////////////////////////////////////////////////////////////////
    reg [1:0] pix_div = 2'd0;
    wire      pix_tick = (pix_div == 2'd3);

    always @(posedge clk) begin
        if (rst_btn)
            pix_div <= 2'd0;
        else
            pix_div <= pix_div + 2'd1;
    end

    ////////////////////////////////////////////////////////////////////////////
    // 640 × 480 @ 60 Hz VGA timing  (800 × 525 total)
    ////////////////////////////////////////////////////////////////////////////
    localparam H_VISIBLE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48, H_TOTAL = 800;
    localparam V_VISIBLE = 480, V_FRONT = 10, V_SYNC =  2, V_BACK = 33, V_TOTAL = 525;

    reg [9:0] h_cnt = 10'd0;
    reg [9:0] v_cnt = 10'd0;

    always @(posedge clk) begin
        if (rst_btn) begin
            h_cnt <= 10'd0;
            v_cnt <= 10'd0;
        end
        else if (pix_tick) begin
            if (h_cnt == H_TOTAL-1) begin
                h_cnt <= 10'd0;
                v_cnt <= (v_cnt == V_TOTAL-1) ? 10'd0 : v_cnt + 10'd1;
            end else
                h_cnt <= h_cnt + 10'd1;
        end
    end

    // Sync pulses (active-low)
    always @(posedge clk) begin
        vga_hs <= ~(h_cnt >= H_VISIBLE+H_FRONT && h_cnt < H_VISIBLE+H_FRONT+H_SYNC);
        vga_vs <= ~(v_cnt >= V_VISIBLE+V_FRONT && v_cnt < V_VISIBLE+V_FRONT+V_SYNC);
    end

    ////////////////////////////////////////////////////////////////////////////
    // 256 × 256 framebuffer  (Port-A read, Port-B write)
    ////////////////////////////////////////////////////////////////////////////
    // Synthesises to a single 64 KiB true dual-port BRAM on 7-series parts.
    (* ram_style="block" *) reg [7:0] fb_mem [0:65535];

    // --- write port (Port-B) ---
    wire [15:0] wr_addr = {wr_y, wr_x};  // Y‖X
    always @(posedge clk)
        if (wr_we)
            fb_mem[wr_addr] <= wr_pix;

    // --- read port (Port-A) ---
    // Centre the 256×256 window inside the 640×480 active area
    localparam X_OFFSET = (H_VISIBLE - 256)/2;  // 192
    localparam Y_OFFSET = (V_VISIBLE - 256)/2;  // 112

    wire display_en = (h_cnt >= X_OFFSET                && h_cnt < X_OFFSET + 256) &&
                      (v_cnt >= Y_OFFSET                && v_cnt < Y_OFFSET + 256);

    wire [7:0] rd_x = h_cnt - X_OFFSET;
    wire [7:0] rd_y = v_cnt - Y_OFFSET;
    wire [15:0] rd_addr = {rd_y, rd_x};

    reg [7:0] rd_pix = 8'h00;
    always @(posedge clk)
        if (pix_tick)
            rd_pix <= fb_mem[rd_addr];

    ////////////////////////////////////////////////////////////////////////////
    // Output-stage: 8-bit RRRGGGBB → 4-bit per channel (nibble fan-out)
    ////////////////////////////////////////////////////////////////////////////
    always @(posedge clk) begin
        if (pix_tick) begin
            if (display_en) begin
                // Expand 3-3-2 into 4-4-4 by repeating MSBs
                vga_r <= {rd_pix[7:5], rd_pix[7]};          // RRR0 → RRRR
                vga_g <= {rd_pix[4:2], rd_pix[4]};          // GGG0 → GGGG
                vga_b <= {rd_pix[1:0], rd_pix[1:0]};        // BB00 → BBBB
            end else begin
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
        end
    end

endmodule
