`timescale 1ns / 1ps
module voting_machine(
    input clk,                   // 100MHz clock
    input BTNU, BTNC, BTND,      // UP(Vote), CENTER(Finish), DOWN(Reset)
    input [3:0] rep_sel,         // Representative select (one-hot: bit 0 for rep 1, bit 1 for rep 2, etc.)
    input [3:0] voter_id,        // Voter ID (0000 to 1001 valid)
    output reg [6:0] seg,        // 7-segment segments
    output reg [3:0] an,         // 4-digit enable
    output LD0                   // Optional: Invalid voter or already voted indicator
);

    // Vote storage
    reg [3:0] votes[3:0];         // votes[0]=Rep1, votes[1]=Rep2, votes[2]=Rep3, votes[3]=Rep4
    reg [9:0] voted;              // Track voters who have voted (bit 0 for ID 0, up to bit 9 for ID 9)
    reg finish;
    integer i;

    // Button debounce
    reg [1:0] vote_btn_sync, finish_btn_sync, reset_btn_sync;

    // Authentication and selection validation
    wire valid_voter;
    wire [2:0] sel_count;
    assign valid_voter = (voter_id <= 4'b1001);
    assign sel_count = rep_sel[0] + rep_sel[1] + rep_sel[2] + rep_sel[3];

    // Optional invalid voter LED (also lights if already voted or invalid selection)
    assign LD0 = (vote_btn_sync == 2'b01) & (~valid_voter | voted[voter_id] | (sel_count != 1));

    // Debounce process
    always @(posedge clk) begin
        vote_btn_sync <= {vote_btn_sync[0], BTNU};
        finish_btn_sync <= {finish_btn_sync[0], BTNC};
        reset_btn_sync <= {reset_btn_sync[0], BTND};
    end

    // Reset and vote logic
    always @(posedge clk) begin
        if(reset_btn_sync == 2'b01) begin
            for(i=0; i<4; i=i+1) votes[i] <= 0;
            voted <= 0;
            finish <= 0;
        end
        else if(finish == 0) begin
            // Vote
            if(vote_btn_sync == 2'b01 && valid_voter && !voted[voter_id] && sel_count == 1) begin
                voted[voter_id] <= 1;
                for(i=0; i<4; i=i+1) begin
                    if(rep_sel[i]) votes[i] <= votes[i] + 1;
                end
            end
            // Finish vote
            if(finish_btn_sync == 2'b01) finish <= 1;
        end
    end

    // Winner & Runner-up calculation
    reg [3:0] win1, win2, max1, max2;
    always @(posedge clk) begin
        if(finish) begin
            max1 = 0; max2 = 0;
            win1 = 0; win2 = 0;
            for(i=0; i<4; i=i+1) begin
                if(votes[i] > max1) begin
                    max2 = max1; win2 = win1;
                    max1 = votes[i]; win1 = i + 1;  // Rep numbers 1-4
                end
                else if(votes[i] > max2) begin
                    max2 = votes[i]; win2 = i + 1;  // Rep numbers 1-4
                end
            end
        end
    end

    // 7-Segment Display
    reg [3:0] display_data[3:0];
    reg [1:0] display_index = 0;
    reg [15:0] refresh_count = 0;

    // Update display_data (left to right: digit3 digit2 digit1 digit0)
    always @(*) begin
        if(finish == 0) begin
            // During voting: show votes for Rep1 (left) to Rep4 (right)
            display_data[3] = votes[0];  // Rep1 votes (leftmost)
            display_data[2] = votes[1];  // Rep2 votes
            display_data[1] = votes[2];  // Rep3 votes
            display_data[0] = votes[3];  // Rep4 votes (rightmost)
        end else begin
            // After finish: Winner Rep, Winner votes, Runner-up Rep, Runner-up votes
            display_data[3] = win1;      // Winner Rep (1-4, leftmost)
            display_data[2] = max1;      // Winner votes
            display_data[1] = win2;      // Runner-up Rep (1-4)
            display_data[0] = max2;      // Runner-up votes (rightmost)
        end
    end

    // Multiplex display
    always @(posedge clk) begin
        refresh_count <= refresh_count + 1;
        if(refresh_count == 50000) begin
            refresh_count <= 0;
            display_index <= display_index + 1;
        end
    end

    // 7-segment decoder
    function [6:0] seg_decode(input [3:0] num);
        case(num)
            4'h0: seg_decode = 7'b1000000; 
            4'h1: seg_decode = 7'b1111001;
            4'h2: seg_decode = 7'b0100100;
            4'h3: seg_decode = 7'b0110000;
            4'h4: seg_decode = 7'b0011001;
            4'h5: seg_decode = 7'b0010010;
            4'h6: seg_decode = 7'b0000010;
            4'h7: seg_decode = 7'b1111000;
            4'h8: seg_decode = 7'b0000000;
            4'h9: seg_decode = 7'b0010000;
            default: seg_decode = 7'b1111111;
        endcase
    endfunction

    // Drive display
    always @(*) begin
        an = 4'b1111;
        an[display_index] = 0;
        seg = seg_decode(display_data[display_index]);
    end

endmodule
