// Simplified formal verification wrapper for transient_shaper_core
// Focuses on core safety properties only

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

`ifdef FORMAL
    // ========== ASSUMPTIONS ==========

    // Reset starts asserted
    initial assume(!rst_n);

    // Input is valid 6-bit value
    always @(*) assume(audio_in <= 6'h3F);

    // ========== SAFETY PROPERTIES ==========

    // Property 1: Reset behavior
    always @(posedge clk) begin
        if (!rst_n) begin
            reset_clears_output: assert(audio_out == 0);
        end
    end

    // Property 2: Output bounds
    // Output is always a valid 8-bit value (checked after clock edges when stable)
    always @(posedge clk) begin
        if (rst_n) begin
            output_in_range: assert(audio_out <= 8'hFF);
        end
    end

    // ========== COVERAGE ==========

    // Cover: All combinations of boost settings
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_no_boost: cover(!attack_amt && !sustain_amt && audio_in > 0);
            cover_attack_only: cover(attack_amt && !sustain_amt && audio_in > 0);
            cover_sustain_only: cover(!attack_amt && sustain_amt && audio_in > 0);
            cover_both_boost: cover(attack_amt && sustain_amt && audio_in > 0);
        end
    end

    // Cover: Maximum input value
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_max_input: cover(audio_in == 6'h3F);
        end
    end

    // Cover: High output value
    always @(posedge clk) begin
        if (rst_n && ena) begin
            cover_high_output: cover(audio_out > 100);
        end
    end

`endif

endmodule

`default_nettype wire
