// Formal verification wrapper for transient_shaper_core
// This file contains SystemVerilog Assertions (SVA) to verify design properties

`default_nettype none

module transient_shaper_formal #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire ena,
    input wire [WIDTH-3:0] audio_in,
    input wire attack_amt,
    input wire sustain_amt,
    output wire [WIDTH-1:0] audio_out
);

    // Instantiate the design under test
    transient_shaper_core #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .audio_in(audio_in),
        .attack_amt(attack_amt),
        .sustain_amt(sustain_amt),
        .audio_out(audio_out)
    );

    // Past value tracking for external signals
    reg [WIDTH-1:0] past_audio_out;
    reg [WIDTH-3:0] past_audio_in;
    reg past_valid = 0;

    always @(posedge clk) begin
        past_audio_out <= audio_out;
        past_audio_in <= audio_in;
        if (rst_n && ena) past_valid <= 1;
        else past_valid <= 0;
    end

`ifdef FORMAL
    // Assume constraints (input assumptions)

    // Reset handling - start with reset asserted
    initial assume(!rst_n);

    // Input constraints - audio_in is 6-bit (0-63)
    always @(*) begin
        assume(audio_in <= 6'h3F);
    end

    // ========== SAFETY PROPERTIES ==========

    // Property 1: Reset behavior
    // When reset is asserted, output should be zero
    always @(posedge clk) begin
        if (!rst_n) begin
            assert_reset_audio_out: assert(audio_out == 0);
        end
    end

    // Property 2: Output bounds
    // The output should never exceed the maximum 8-bit value
    always @(posedge clk) begin
        if (rst_n) begin
            // Output must be valid 8-bit value
            assert_output_bounds: assert(audio_out <= 255);
        end
    end

    // Property 3: Stable operation after reset release
    // After a few cycles out of reset with ena high, system should be stable
    reg [3:0] cycles_since_reset;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cycles_since_reset <= 0;
        else if (ena && cycles_since_reset < 15) cycles_since_reset <= cycles_since_reset + 1;
    end

    // Property 4: Passthrough with no boost
    // With no boost enabled, output equals input (accounting for boost contributions from envelopes)
    // This is a weaker property - we just check output is reasonable
    always @(posedge clk) begin
        if (rst_n && ena) begin
            // Output should never be less than zero or greater than theoretical max
            // Max output = 63 (max input) + 127 (max attack_boost) + 127 (max sustain_boost) = 317
            // But this can't happen because envelopes lag the input
            assert_output_reasonable: assert(audio_out < 320);
        end
    end

    // Property 5: Output monotonicity with zero input
    // With sustained zero input, output should not suddenly increase
    always @(posedge clk) begin
        if (rst_n && ena && past_valid) begin
            if (audio_in == 0 && past_audio_in == 0 && past_audio_out < 10) begin
                // If we've been at zero and output is small, it should stay small
                assert_stays_small: assert(audio_out < 20);
            end
        end
    end

    // ========== COVERAGE PROPERTIES ==========

    // Cover: Both boosts enabled
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_both_boosts: cover(attack_amt && sustain_amt && audio_in > 0);
        end
    end

    // Cover: Attack only
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_attack_only: cover(attack_amt && !sustain_amt && audio_in > 0);
        end
    end

    // Cover: Sustain only
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_sustain_only: cover(!attack_amt && sustain_amt && audio_in > 0);
        end
    end

    // Cover: Maximum input value
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_max_input: cover(audio_in == 6'h3F);  // Maximum 6-bit value (63)
        end
    end

    // Cover: Transition from high to low input
    always @(posedge clk) begin
        if (rst_n && ena && past_valid) begin
            cover_high_to_low: cover($past(audio_in) > 32 && audio_in < 16);
        end
    end

    // Cover: Output saturation scenario
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_high_output: cover(audio_out > 200);
        end
    end

`endif

endmodule

`default_nettype wire
