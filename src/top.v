`timescale 1ns / 1ps

module top(
    input clk,             // 100MHz board clock
    input [15:0] sw,       // 16 Switches
    input btnC,            // Start button
    input btnU,            // Stop button (Mode 2)
    input btnR,            // Reset button
    
    output [15:0] led,     // 16 LEDs
    output [3:0] an,       // 7-Segment Anodes
    output [6:0] seg       // 7-Segment Cathodes
);

    // --- Wires to connect modules together ---
    wire clk_1kHz, clk_1Hz;
    wire start_clean, stop_clean, reset_clean;
    wire [7:0] random_num;
    
    // Mode 1 Wires
    wire [14:0] m1_leds;
    wire [3:0] p1_score, p2_score, p_turn;
    wire m1_game_over;
    
    // Mode 2 Wires
    wire [13:0] m2_time_bin;
    wire m2_led;
    wire [3:0] bcd_thos, bcd_huns, bcd_tens, bcd_ones;

    // --- 1. Clocks and Random Number ---
    clk_div clock_gen (
        .clk_100MHz(clk), .rst(reset_clean), 
        .clk_1kHz(clk_1kHz), .clk_1Hz(clk_1Hz)
    );

    lfsr rng (
        .clk(clk), .rst(reset_clean), 
        .rnd_out(random_num)
    );

    // --- 2. Button Debouncers ---
    debouncer db_start(.clk(clk), .btn_in(btnC), .btn_out(start_clean));
    debouncer db_stop (.clk(clk), .btn_in(btnU), .btn_out(stop_clean));
    debouncer db_reset(.clk(clk), .btn_in(btnR), .btn_out(reset_clean));

    // --- 3. Mode 1 FSM (Memory Game) ---
    mode1_fsm memory_game (
        .clk_1kHz(clk_1kHz), .rst(reset_clean), .start_btn(start_clean),
        .sw(sw[14:0]), .rnd_in(random_num), .led_out(m1_leds),
        .p1_score(p1_score), .p2_score(p2_score), .p_turn(p_turn), .game_over(m1_game_over)
    );

    // --- 4. Mode 2 FSM (Reaction Timer) ---
    mode2_fsm reaction_timer (
        .clk_1kHz(clk_1kHz), .rst(reset_clean), .start_btn(start_clean), .stop_btn(stop_clean),
        .rnd_in(random_num), .bcd_time(m2_time_bin), .led_out(m2_led)
    );

    // --- 5. BCD Converter (For Mode 2 Timer) ---
    bin2bcd time_converter (
        .bin(m2_time_bin), 
        .thos(bcd_thos), .huns(bcd_huns), .tens(bcd_tens), .ones(bcd_ones)
    );

    // --- 6. Multiplexing the Outputs Based on Mode Switch (sw[15]) ---
    wire mode = sw[15]; // 0 = Mode 1, 1 = Mode 2
    
    // Route LEDs based on mode
    assign led[14:0] = (mode == 0) ? m1_leds : {14'b0, m2_led};
    assign led[15]   = mode; 

    // Route 7-Segment Display based on mode
    reg [3:0] d3, d2, d1, d0;
    
    always @(*) begin
        if (mode == 0) begin
            if (m1_game_over) begin
                // GAME OVER DISPLAY LOGIC
                if (p1_score > p2_score) begin 
                    d3 = 4'hA; d2 = 4'h1; d1 = 4'hF; d0 = p1_score; // P1 Wins! Shows "A1 [Score]"
                end 
                else if (p2_score > p1_score) begin 
                    d3 = 4'hb; d2 = 4'h2; d1 = 4'hF; d0 = p2_score; // P2 Wins! Shows "b2 [Score]"
                end 
                else begin 
                    d3 = p1_score; d2 = 4'hF; d1 = 4'hF; d0 = p2_score; // Tie! Shows "[P1]  [P2]"
                end
            end else begin
                // NORMAL GAMEPLAY DISPLAY LOGIC
                d3 = p1_score; 
                d2 = 4'hF;     // 4'hF is our new blank space in seg_display
                d1 = p2_score; 
                d0 = p_turn;   // Shows Turn: 1 or 2
            end
        end else begin
            // Mode 2 Display: Show Reaction Time in MS
            d3 = bcd_thos; d2 = bcd_huns; d1 = bcd_tens; d0 = bcd_ones;
        end
    end

    // --- 7. 7-Segment Controller ---
    seg_display display_ctrl (
        .clk_1kHz(clk_1kHz), .rst(reset_clean),
        .digit3(d3), .digit2(d2), .digit1(d1), .digit0(d0),
        .an(an), .seg(seg)
    );

endmodule