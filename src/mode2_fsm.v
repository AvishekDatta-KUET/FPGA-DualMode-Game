`timescale 1ns / 1ps

module mode2_fsm(
    input clk_1kHz,        // 1ms clock for our stopwatch timer
    input rst,             // Reset switch
    input start_btn,       // Clean start signal (from debouncer)
    input stop_btn,        // Clean stop signal (from debouncer)
    input [7:0] rnd_in,    // 8-bit random number from LFSR (0-255)
    
    output reg [13:0] bcd_time, // Time in milliseconds to send to 7-segment display
    output reg led_out     // The single light that turns on
);

    // FSM States
    localparam IDLE      = 2'b00;
    localparam DELAY     = 2'b01;
    localparam WAIT_STOP = 2'b10;
    localparam DONE      = 2'b11;

    reg [1:0] state;
    reg [13:0] ms_counter; // Max 9999 ms
    reg [13:0] delay_target;

    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            ms_counter <= 0;
            led_out <= 0;
            bcd_time <= 0;
        end else begin
            case (state)
                IDLE: begin
                    led_out <= 0;
                    ms_counter <= 0;
                    if (start_btn) begin
                        // Calculate a random delay: Base 2000ms (2s) + up to 2550ms (2.55s)
                        // This gives a random delay between 2 and 4.5 seconds.
                        delay_target <= 2000 + (rnd_in * 10); 
                        state <= DELAY;
                    end
                end

                DELAY: begin
                    ms_counter <= ms_counter + 1;
                    if (ms_counter >= delay_target) begin
                        ms_counter <= 0; // Reset counter to act as our stopwatch
                        led_out <= 1;    // Turn on the light!
                        state <= WAIT_STOP;
                    end
                end

                WAIT_STOP: begin
                    // Stop counting if we reach 9999 (max display limit)
                    if (ms_counter < 9999) begin
                        ms_counter <= ms_counter + 1;
                    end
                    
                    if (stop_btn) begin
                        bcd_time <= ms_counter; // Lock the time to display
                        led_out <= 0;           // Turn off the light
                        state <= DONE;
                    end
                end

                DONE: begin
                    // Keep displaying the time until start is pressed again
                    if (start_btn) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule