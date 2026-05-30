`timescale 1ns / 1ps

module debouncer(
    input clk,         // 100MHz clock
    input btn_in,      // The raw, bouncy signal from the physical button
    output reg btn_out // The clean, single-press signal 
);

    reg [19:0] counter; // 20-bit counter to reach 1,000,000 (10ms delay)
    reg sync_0, sync_1; // Used to prevent metastability (signal weirdness)

    // First, safely synchronize the physical button to our board's clock
    always @(posedge clk) begin
        sync_0 <= btn_in;
        sync_1 <= sync_0;
    end

    // Only register the press if the button has remained stable for 10ms
    always @(posedge clk) begin
        if (sync_1 == btn_out) begin
            counter <= 0; // If nothing changed, keep counter at 0
        end else begin
            counter <= counter + 1;
            if (counter == 1_000_000) begin
                btn_out <= sync_1; // Button has been stable for 10ms, register the change!
                counter <= 0;
            end
        end
    end

endmodule