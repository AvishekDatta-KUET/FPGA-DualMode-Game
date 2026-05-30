`timescale 1ns / 1ps

module mode1_fsm(
    input clk_1kHz,        // 1ms clock for timing FSM delays
    input rst,             // Reset switch
    input start_btn,       // Start button
    input [14:0] sw,       // The 15 game switches
    input [7:0] rnd_in,    // 8-bit random number
    
    output reg [14:0] led_out, // The 15 LEDs
    output reg [3:0] p1_score, // Player 1 score
    output reg [3:0] p2_score, // Player 2 score
    output reg [3:0] p_turn,   // Current player turn (1 or 2)
    output reg game_over       // High when 5 rounds are done
);

    // --- Start Button Edge Detector ---
    reg prev_start;
    wire start_edge = (start_btn && !prev_start);

    // --- Random Number Synchronizer ---
    reg [7:0] sync_rnd1, sync_rnd2;
    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            sync_rnd1 <= 0;
            sync_rnd2 <= 0;
            prev_start <= 0;
        end else begin
            sync_rnd1 <= rnd_in;
            sync_rnd2 <= sync_rnd1;
            prev_start <= start_btn;
        end
    end
    wire [3:0] new_num = sync_rnd2 % 15; 

    // --- 9 Robust FSM States ---
    localparam IDLE            = 4'd0;
    localparam GEN_SEQ         = 4'd1;
    localparam SHOW_SEQ        = 4'd2;
    localparam WAIT_INPUT      = 4'd3;
    localparam CHECK_INPUT     = 4'd4;
    localparam WRONG_FLASH     = 4'd5;
    localparam EVALUATE        = 4'd6;
    localparam NEXT_TURN_DELAY = 4'd7;
    localparam END_GAME        = 4'd8;

    reg [3:0] state;
    
    // Arrays and Counters
    reg [3:0] sequence [0:4];  // 5 items in the sequence
    reg [2:0] seq_idx;        
    reg [15:0] timer;          // 16-bit timer for long delays safely
    reg [3:0] round_count;    
    
    // Lock baseline switch states to prevent bouncing issues
    reg [14:0] locked_sw;

    always @(posedge clk_1kHz or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            led_out <= 0;
            p1_score <= 0;
            p2_score <= 0;
            p_turn <= 1;
            round_count <= 0;
            game_over <= 0;
            timer <= 0;
            locked_sw <= 0;
        end else begin
            case (state)
                IDLE: begin
                    led_out <= 0;
                    if (start_edge) begin
                        seq_idx <= 0;
                        p1_score <= 0;
                        p2_score <= 0;
                        round_count <= 0;
                        p_turn <= 1;
                        game_over <= 0;
                        state <= GEN_SEQ;
                    end
                end

                GEN_SEQ: begin
                    // Ensure unique numbers in the sequence
                    if ( (seq_idx == 0) || 
                         (seq_idx == 1 && new_num != sequence[0]) ||
                         (seq_idx == 2 && new_num != sequence[0] && new_num != sequence[1]) ||
                         (seq_idx == 3 && new_num != sequence[0] && new_num != sequence[1] && new_num != sequence[2]) ||
                         (seq_idx == 4 && new_num != sequence[0] && new_num != sequence[1] && new_num != sequence[2] && new_num != sequence[3]) ) 
                    begin
                        sequence[seq_idx] <= new_num; 
                        
                        if (seq_idx == 4) begin 
                            seq_idx <= 0;
                            timer <= 0;
                            state <= SHOW_SEQ;
                        end else begin
                            seq_idx <= seq_idx + 1;
                        end
                    end
                end

                SHOW_SEQ: begin
                    timer <= timer + 1;
                    if (timer < 800) begin
                        led_out <= (15'b1 << sequence[seq_idx]); // Show LED
                    end else if (timer < 1000) begin
                        led_out <= 0; // Brief dark pause between LEDs
                    end else begin
                        timer <= 0;
                        if (seq_idx == 4) begin
                            seq_idx <= 0; 
                            led_out <= 0;
                            locked_sw <= sw; // Take snapshot of switches right now!
                            state <= WAIT_INPUT;
                        end else begin
                            seq_idx <= seq_idx + 1;
                        end
                    end
                end

                WAIT_INPUT: begin
                    // Wait until the user changes ANY switch from the snapshot
                    if (sw != locked_sw) begin 
                        timer <= 0;
                        state <= CHECK_INPUT;
                    end
                end

                CHECK_INPUT: begin
                    timer <= timer + 1;
                    if (timer > 20) begin // 20ms Debounce wait
                        if (sw != locked_sw) begin // Switch is still changed (stable)
                            // Did they change the CORRECT switch?
                            if ( (sw ^ locked_sw) == (15'b1 << sequence[seq_idx]) ) begin
                                locked_sw <= sw; // Update snapshot
                                led_out <= led_out | (15'b1 << sequence[seq_idx]); // Turn ON the guessed LED!
                                
                                if (seq_idx == 4) begin // Finished the sequence!
                                    if (p_turn == 1) p1_score <= p1_score + 1;
                                    else p2_score <= p2_score + 1;
                                    timer <= 0;
                                    state <= EVALUATE;
                                end else begin
                                    seq_idx <= seq_idx + 1;
                                    state <= WAIT_INPUT; // Wait for next guess
                                end
                            end else begin
                                // Changed WRONG switch!
                                timer <= 0;
                                state <= WRONG_FLASH;
                            end
                        end else begin
                            // It was just a bounce, ignore it
                            state <= WAIT_INPUT;
                        end
                    end
                end

                WRONG_FLASH: begin
                    timer <= timer + 1;
                    // Blink all LEDs every 200ms
                    if ((timer % 200) < 100) led_out <= 15'b111_1111_1111_1111;
                    else led_out <= 0;
                    
                    if (timer > 1500) begin // 1.5 seconds of shame
                        led_out <= 0;
                        timer <= 0;
                        state <= EVALUATE; // 0 points, move to next
                    end
                end

                EVALUATE: begin
                    led_out <= 0;
                    if (p_turn == 1) begin
                        p_turn <= 2;          
                        timer <= 0;
                        state <= NEXT_TURN_DELAY; 
                    end else begin
                        p_turn <= 1;          
                        if (round_count == 4) begin // 5 rounds total (0,1,2,3,4)
                            game_over <= 1;
                            state <= END_GAME;
                        end else begin
                            round_count <= round_count + 1;
                            timer <= 0;
                            state <= NEXT_TURN_DELAY; 
                        end
                    end
                end

                NEXT_TURN_DELAY: begin
                    timer <= timer + 1;
                    if (timer > 2000) begin // 2 second pause before next turn
                        seq_idx <= 0;
                        state <= GEN_SEQ; 
                    end
                end

                END_GAME: begin
                    // Final Visual Output!
                    if (p1_score > p2_score) begin
                        led_out <= 15'b000_0000_0000_1111; // P1 wins! (Right side LEDs)
                    end else if (p2_score > p1_score) begin
                        led_out <= 15'b111_1000_0000_0000; // P2 wins! (Left side LEDs)
                    end else begin
                        led_out <= 15'b110_0000_0000_0011; // Tie! (Edges)
                    end
                    
                    if (start_edge) begin // Press start to play again
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule