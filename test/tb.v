module tb_tt_um_markr_transientshaper();

    reg clk = 0, rst_n = 0, ena = 1;
    reg [7:0] ui_in = 0;
    wire [7:0] uo_out;

    tt_um_markr_transientshaper uut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(8'b0), .uio_out(), .uio_oe(),
        .ena(ena), .clk(clk), .rst_n(rst_n)
    );

    initial begin
        rst_n = 0; #20; rst_n = 1;
        // Simulate an impulse with attack boost active
        ui_in = 8'b10111111; #20 clk = ~clk; #20 clk = ~clk;
        for (integer i = 0; i < 20; i = i + 1) begin
            ui_in = 8'b00011111; #10 clk = ~clk; #10 clk = ~clk;
        end
        #100 $finish;
    end

endmodule

