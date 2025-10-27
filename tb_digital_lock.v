`timescale 1ns/1ps

module tb_digital_lock;

    // 100 MHz clock (10 ns period)
    reg clk = 0;
    always #5 clk = ~clk;

    reg rst = 1;
    reg [3:0] digit = 0;
    reg valid = 0;
    reg relock = 0;

    wire unlocked, lockout;
    wire wrong_try_pulse;

    // Shorten lockout for sim
    localparam integer LOCKOUT_T = 80;

    digital_lock #(
        .P0(4'd1), .P1(4'd2), .P2(4'd3), .P3(4'd4),
        .MAX_ATTEMPTS(3),
        .LOCKOUT_CYCLES(LOCKOUT_T)
    ) dut (
        .clk(clk), .rst(rst),
        .digit(digit), .valid(valid),
        .relock(relock),
        .unlocked(unlocked),
        .wrong_try_pulse(wrong_try_pulse),
        .lockout(lockout)
    );

    // helper: push a single digit with a 1-cycle valid pulse
    task push(input [3:0] d);
    begin
        @(negedge clk);
        digit <= d;
        valid <= 1'b1;
        @(negedge clk);
        valid <= 1'b0;
    end
    endtask

    initial begin
        $display("=== Digital Lock TB ===");
        // Reset
        repeat (4) @(negedge clk);
        rst <= 0;

        // 1) Correct code 1-2-3-4
        push(4'd1); push(4'd2); push(4'd3); push(4'd4);
        repeat (4) @(negedge clk);

        // 2) Relock and attempt wrong first digit
        relock <= 1; @(negedge clk); relock <= 0;
        push(4'd9); // wrong start
        repeat (4) @(negedge clk);

        // 3) Two more wrong attempts to trigger lockout
        push(4'd1); push(4'd9); // wrong at 2nd digit
        push(4'd0);             // wrong at start again

        // sit through lockout
        while (lockout == 1'b1) @(negedge clk);

        // 4) After lockout, enter correct code again
        push(4'd1); push(4'd2); push(4'd3); push(4'd4);
        repeat (10) @(negedge clk);

        $display("=== TB Done ===");
        $stop;
    end

endmodule
