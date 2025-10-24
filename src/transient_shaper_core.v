module transient_shaper_core #(
    parameter WIDTH = 8
) (
    input wire clk,
    input wire rst_n,
    input wire ena,
    input wire [WIDTH-3:0] audio_in,    // 6-bit input for demo
    input wire attack_amt,              // 1 bit: 0=normal, 1=boost attack
    input wire sustain_amt,             // 1 bit: 0=normal, 1=boost sustain
    output reg [WIDTH-1:0] audio_out
);

    reg [WIDTH-1:0] fast_env = 0, slow_env = 0;

    // Envelope followers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) fast_env <= 0;
        else if (ena) fast_env <= (fast_env * 3 + audio_in) >> 2;  // Fast (attack)
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) slow_env <= 0;
        else if (ena) slow_env <= (slow_env * 7 + audio_in) >> 3;  // Slow (sustain)
    end

    // Attack/Sustain mix mod
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) audio_out <= 0;
        else if (ena) begin
            reg signed [WIDTH:0] attack_boost, sustain_boost;
            attack_boost = attack_amt ? (fast_env >> 1) : 0;
            sustain_boost = sustain_amt ? (slow_env >> 1) : 0;
            audio_out <= audio_in + attack_boost + sustain_boost;
        end
    end

endmodule

