/**********************************************************************
 *  UART transmitter 8-N-1
 *  - one byte per 'transmit' pulse, line-idle indicator
 *********************************************************************/
module transmitter #(
    parameter CLK_FREQ  = 100_000_000,  // system clock in Hz
    parameter BAUD_RATE = 115200
)(
    input        clk,
    input        reset,          // async, active-high
    input        transmit,       // one-cycle "send" strobe
    input  [7:0] data,
    output reg   TxD,
    output       idle
);

    /* ------------------------------------------------------------ */
    localparam integer DIV = CLK_FREQ / BAUD_RATE;   // clocks / bit
    localparam IDLE = 1'b0, SEND = 1'b1;

    reg        state;
    reg [13:0] baud_cnt;         // enough bits for DIV-1 (≤16383)
    reg [3:0]  bit_cnt;          // counts 0-10
    reg [9:0]  shift_reg;

    assign idle = (state == IDLE);

    /* ------------------------ single FSM ------------------------ */
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state      <= IDLE;
            baud_cnt   <= 0;
            bit_cnt    <= 0;
            shift_reg  <= 10'h3FF;   // line is high during reset
            TxD        <= 1'b1;
        end
        else case (state)

            /* -------------- idle, wait for request -------------- */
            IDLE: begin
                if (transmit) begin           // rising-edge-detected pulse
                    shift_reg <= {1'b1, data, 1'b0}; // stop, data, start
                    bit_cnt   <= 0;
                    baud_cnt  <= 0;
                    TxD       <= 1'b0;        // start bit immediately
                    state     <= SEND;
                end
            end

            /* -------------- actively sending a byte ------------- */
            SEND: begin
                if (baud_cnt == DIV-1) begin  // one full bit elapsed
                    baud_cnt  <= 0;
                    /* first shift, then drive the line */
                    shift_reg <= {1'b1, shift_reg[9:1]};   // logical right-shift
                    TxD       <= shift_reg[1];             // ← new LSB *after* shift
                    bit_cnt   <= bit_cnt + 1;
                    if (bit_cnt == 4'd9)      // after 9 bits (first bit was sent in idle)
                        state <= IDLE;        // done
                end
                else
                    baud_cnt <= baud_cnt + 1;
            end
        endcase
    end
endmodule
