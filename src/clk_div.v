`timescale 1ns / 1ps

module clk_div(
    input clk_100MHz,    // The built-in 100MHz Basys 3 clock
    input rst,           // Reset signal to start over
    output reg clk_1kHz, // 1kHz clock (1ms tick) for 7-segment display and Mode 2 timer
    output reg clk_1Hz   // 1Hz clock (1 second tick) for Mode 1 LED delays
);

    // Counters to track the ticks
    reg [16:0] count_1kHz;
    reg [25:0] count_1Hz;

    // Generate 1kHz clock (Toggles every 50,000 ticks)
    always @(posedge clk_100MHz or posedge rst) begin
        if (rst) begin
            count_1kHz <= 0;
            clk_1kHz <= 0;
        end else if (count_1kHz == 49_999) begin
            count_1kHz <= 0;
            clk_1kHz <= ~clk_1kHz;
        end else begin
            count_1kHz <= count_1kHz + 1;
        end
    end

    // Generate 1Hz clock (Toggles every 50,000,000 ticks)
    always @(posedge clk_100MHz or posedge rst) begin
        if (rst) begin
            count_1Hz <= 0;
            clk_1Hz <= 0;
        end else if (count_1Hz ==49_999_999) begin
            count_1Hz <= 0;
            clk_1Hz <= ~clk_1Hz;
        end else begin
            count_1Hz <= count_1Hz + 1;
        end
    end

endmodule