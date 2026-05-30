`timescale 1ns / 1ps

module lfsr(
    input clk,          // 100MHz clock (runs super fast to ensure randomness)
    input rst,          // Reset
    output reg [7:0] rnd_out // 8-bit random output (0 to 255)
);

    // Initial seed value (LFSRs cannot start at 0!)
    reg [7:0] lfsr_reg = 8'hA5; 
    wire feedback;

    // The feedback taps for an 8-bit LFSR (Polynomial: x^8 + x^6 + x^5 + x^4 + 1)
    assign feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_reg <= 8'hA5; // Reset to seed
        end else begin
            // Shift left by 1, and put the feedback bit at the very end
            lfsr_reg <= {lfsr_reg[6:0], feedback};
        end
    end

    // Continuously assign the internal register to the output
    always @(*) begin
        rnd_out = lfsr_reg;
    end

endmodule