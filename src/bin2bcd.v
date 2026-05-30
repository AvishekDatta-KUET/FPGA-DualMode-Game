`timescale 1ns / 1ps

module bin2bcd(
    input [13:0] bin,
    output reg [3:0] thos,
    output reg [3:0] huns,
    output reg [3:0] tens,
    output reg [3:0] ones
);

    integer i;
    reg [29:0] shift;

    always @(bin) begin
        // Initialize shift register to zero
        shift = 30'd0;
        shift[13:0] = bin;
        
        // Loop 14 times for the 14-bit binary number
        for (i = 0; i < 14; i = i + 1) begin
            if (shift[17:14] >= 5) shift[17:14] = shift[17:14] + 3; // Ones
            if (shift[21:18] >= 5) shift[21:18] = shift[21:18] + 3; // Tens
            if (shift[25:22] >= 5) shift[25:22] = shift[25:22] + 3; // Hundreds
            if (shift[29:26] >= 5) shift[29:26] = shift[29:26] + 3; // Thousands
            
            // Shift left by 1
            shift = shift << 1;
        end
        
        // Extract BCD digits
        ones = shift[17:14];
        tens = shift[21:18];
        huns = shift[25:22];
        thos = shift[29:26];
    end
endmodule