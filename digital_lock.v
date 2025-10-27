// -----------------------------------------------------------------------------
// Digital Lock (FSM, 4-digit code, serial digit entry)
// Author: (you)
// Tool: Verilog-2001, synthesizable
//
// Interface:
//   - clk, rst       : clock and active-high synchronous reset
//   - digit[3:0]     : digit value 0..9 for each key press
//   - valid          : 1-cycle strobe when a digit is presented
//   - relock         : force the lock back to locked state after unlock
//   - unlocked       : high when the door is unlocked (latched until relock)
//   - wrong_try_pulse: 1-cycle pulse when a wrong code attempt occurs
//   - lockout        : high while in lockout (after MAX_ATTEMPTS wrong tries)
//
// Parameters:
//   P0..P3           : the passcode digits (default 1-2-3-4)
//   MAX_ATTEMPTS     : wrong tries allowed before lockout
//   LOCKOUT_CYCLES   : duration of lockout in clk cycles
// -----------------------------------------------------------------------------

`timescale 1ns/1ps

module digital_lock #(
    parameter [3:0] P0 = 4'd1,  // 1
    parameter [3:0] P1 = 4'd2,  // 2
    parameter [3:0] P2 = 4'd3,  // 3
    parameter [3:0] P3 = 4'd4,  // 4
    parameter integer MAX_ATTEMPTS   = 3,
    parameter integer LOCKOUT_CYCLES = 100_000  // adjust to clock rate
)(
    input  wire       clk,
    input  wire       rst,            // active-high sync reset
    input  wire [3:0] digit,          // 0..9
    input  wire       valid,          // 1-cycle strobe for each key press
    input  wire       relock,         // user/MCU signal to relock

    output reg        unlocked,
    output reg        wrong_try_pulse,
    output wire       lockout
);

    // ------------------------------
    // FSM state encoding
    // ------------------------------
    localparam [2:0]
        S_IDLE   = 3'd0,  // wait for first digit
        S_D1     = 3'd1,  // expecting P1
        S_D2     = 3'd2,  // expecting P2
        S_D3     = 3'd3,  // expecting P3
        S_UNLOCK = 3'd4,  // unlocked (latched)
        S_LOCKED = 3'd5;  // lockout state (timer)

    reg [2:0]  state, state_nxt;

    // attempts & lockout timer
    reg [$clog2(MAX_ATTEMPTS+1)-1:0] attempts, attempts_nxt;
    reg [31:0] lockout_cnt, lockout_cnt_nxt;

    // handy wires
    wire pass0 = (digit == P0);
    wire pass1 = (digit == P1);
    wire pass2 = (digit == P2);
    wire pass3 = (digit == P3);

    assign lockout = (state == S_LOCKED);

    // ------------------------------
    // Next-state logic
    // ------------------------------
    always @* begin
        // defaults
        state_nxt        = state;
        attempts_nxt     = attempts;
        lockout_cnt_nxt  = lockout_cnt;
        wrong_try_pulse  = 1'b0;

        case (state)
            S_IDLE: begin
                if (valid) begin
                    if (pass0) state_nxt = S_D1;
                    else begin
                        // wrong right away
                        wrong_try_pulse = 1'b1;
                        attempts_nxt    = attempts + 1'b1;
                        if (attempts + 1 >= MAX_ATTEMPTS) begin
                            state_nxt       = S_LOCKED;
                            lockout_cnt_nxt = 32'd0;
                        end
                    end
                end
            end

            S_D1: begin
                if (valid) begin
                    if (pass1) state_nxt = S_D2;
                    else begin
                        wrong_try_pulse = 1'b1;
                        attempts_nxt    = attempts + 1'b1;
                        state_nxt       = (attempts + 1 >= MAX_ATTEMPTS) ? S_LOCKED : S_IDLE;
                        lockout_cnt_nxt = (attempts + 1 >= MAX_ATTEMPTS) ? 32'd0 : lockout_cnt;
                    end
                end
            end

            S_D2: begin
                if (valid) begin
                    if (pass2) state_nxt = S_D3;
                    else begin
                        wrong_try_pulse = 1'b1;
                        attempts_nxt    = attempts + 1'b1;
                        state_nxt       = (attempts + 1 >= MAX_ATTEMPTS) ? S_LOCKED : S_IDLE;
                        lockout_cnt_nxt = (attempts + 1 >= MAX_ATTEMPTS) ? 32'd0 : lockout_cnt;
                    end
                end
            end

            S_D3: begin
                if (valid) begin
                    if (pass3) begin
                        state_nxt    = S_UNLOCK;
                        attempts_nxt = 'd0; // reset counter after success
                    end else begin
                        wrong_try_pulse = 1'b1;
                        attempts_nxt    = attempts + 1'b1;
                        state_nxt       = (attempts + 1 >= MAX_ATTEMPTS) ? S_LOCKED : S_IDLE;
                        lockout_cnt_nxt = (attempts + 1 >= MAX_ATTEMPTS) ? 32'd0 : lockout_cnt;
                    end
                end
            end

            S_UNLOCK: begin
                // stay unlocked until relock
                if (relock) state_nxt = S_IDLE;
            end

            S_LOCKED: begin
                // count a fixed lockout interval
                if (lockout_cnt >= LOCKOUT_CYCLES - 1) begin
                    state_nxt       = S_IDLE;
                    attempts_nxt    = 'd0;       // clear after lockout
                    lockout_cnt_nxt = 32'd0;
                end else begin
                    lockout_cnt_nxt = lockout_cnt + 1;
                end
            end

            default: state_nxt = S_IDLE;
        endcase
    end

    // ------------------------------
    // Registers
    // ------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state       <= S_IDLE;
            attempts    <= 'd0;
            lockout_cnt <= 32'd0;
            unlocked    <= 1'b0;
        end else begin
            state       <= state_nxt;
            attempts    <= attempts_nxt;
            lockout_cnt <= lockout_cnt_nxt;

            // unlocked output is latched in UNLOCK state, cleared on relock or reset
            if (state_nxt == S_UNLOCK)      unlocked <= 1'b1;
            else if (relock || (state == S_LOCKED)) unlocked <= 1'b0;
        end
    end

endmodule
