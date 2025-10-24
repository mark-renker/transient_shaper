module tt_um_markr_transientshaper (
    input wire [7:0] ui_in,      // audio in [7:0], attack amount [7], sustain amount [6]
    output wire [7:0] uo_out,    // processed audio out
    input wire [7:0] uio_in,     // unused
    output wire [7:0] uio_out,   // unused
    output wire [7:0] uio_oe,    // unused
    input wire ena,              // design enable
    input wire clk,              // 24 MHz
    input wire rst_n             // active low reset
);

    wire [7:0] processed;

    transient_shaper_core #(
        .WIDTH(8)
    ) ts_inst (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .audio_in(ui_in[5:0]),      // lower 6 bits
        .attack_amt(ui_in[7]),
        .sustain_amt(ui_in[6]),
        .audio_out(processed)
    );

    assign uo_out = processed;
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

endmodule

