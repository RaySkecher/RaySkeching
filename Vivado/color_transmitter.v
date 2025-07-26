module color_transmitter #(
    parameter CLK_FREQ  = 100_000_000,
    parameter BAUD_RATE = 115200
)(
    input         clk,
    input         reset,
    input         start,
    input  [23:0] rgb,
    output        busy, // high until all 3 bytes sent
    output        TxD
);
    wire tx_idle;
    reg  tx_strobe;
    reg  [7:0] tx_data;

    transmitter #(
        .CLK_FREQ (CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) UART (
        .clk      (clk),
        .reset    (reset),
        .transmit (tx_strobe),
        .data     (tx_data),
        .TxD      (TxD),
        .idle     (tx_idle)
    );

    reg tx_idle_d;
    always @(posedge clk) tx_idle_d <= tx_idle;
    reg idle_rise;
    
    always @(posedge clk) idle_rise <= tx_idle & ~tx_idle_d;

    localparam IDLE  = 2'd0,
               LOAD0 = 2'd1,   // send B
               LOAD1 = 2'd2,   // send G
               LOAD2 = 2'd3;   // send R (then done)

    reg [1:0]  state;
    reg [23:0] rgb_latch;

    assign busy = tx_strobe | (state != IDLE) | ~tx_idle | start;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state     <= IDLE;
            tx_strobe <= 1'b0;
            tx_data   <= 8'hFF;
        end
        else begin
            tx_strobe <= 1'b0;
            case (state)
                IDLE: if (start) begin
                    rgb_latch <= rgb;               // capture colour
                    tx_data   <= rgb[7:0];          // B
                    tx_strobe <= 1'b1;              // kick first byte
                    state     <= LOAD1;
                end

                LOAD1: if (idle_rise) begin
                    tx_data   <= rgb_latch[15:8];   // G
                    tx_strobe <= 1'b1;
                    state     <= LOAD2;
                end

                LOAD2: if (idle_rise) begin
                    tx_data   <= rgb_latch[23:16];  // R
                    tx_strobe <= 1'b1;
                    state     <= IDLE;              // finished, back to idle
                end
            endcase
        end
    end
endmodule
