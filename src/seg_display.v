`timescale 1ns / 1ps

module seg_display(
    input clk_1kHz,         // The slow clock from our clk_div
    input rst,              // Reset
    input [3:0] digit0,     // Right-most digit
    input [3:0] digit1,     // Middle-right digit
    input [3:0] digit2,     // Middle-left digit
    input [3:0] digit3,     // Left-most digit
    output reg [3:0] an,    // Anodes (Active-low, decides WHICH digit is on)
    output reg [6:0] seg    // Cathodes (Active-low, decides WHICH segments light up)
);

    reg [1:0] active_digit; // 2-bit counter to cycle through the 4 digits (00, 01, 10, 11)
    reg [3:0] current_val;  // The 4-bit number to be drawn on the active digit

    // Cycle through digits 0 to 3 continuously
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            active_digit <= 0;
        end else begin
            active_digit <= active_digit + 1;
        end
    end

    // Multiplexer to select which Anode to activate and which number to show
    always @(*) begin
        case(active_digit)
            2'b00: begin
                an = 4'b1110;       // Turn on right-most digit (active low)
                current_val = digit0; // Grab the number for this digit
            end
            2'b01: begin
                an = 4'b1101;       // Turn on middle-right digit
                current_val = digit1;
            end
            2'b10: begin
                an = 4'b1011;       // Turn on middle-left digit
                current_val = digit2;
            end
            2'b11: begin
                an = 4'b0111;       // Turn on left-most digit
                current_val = digit3;
            end
        endcase
    end

    // Hex to 7-Segment Decoder (Cathodes are Active-Low on Basys 3)
    always @(*) begin
        case(current_val)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            // Letters for winners like "P1" or "P2"
            4'hA: seg = 7'b0001000; // 'A'
            4'hB: seg = 7'b0000011; // 'b'
            4'hC: seg = 7'b1000110; // 'C'
            4'hD: seg = 7'b0100001; // 'd'
            4'hE: seg = 7'b0000110; // 'E'
            
            // CHANGED THIS LINE: 4'hF is now used to make a blank space
            4'hF: seg = 7'b1111111; // Blank space (All segments OFF)
            
            default: seg = 7'b1111111; // Blank / Off
        endcase
    end

endmodule