module BranchPredictor (
    input logic clk,
    input logic rst_n,

    // Read Port (ID Stage)
    input logic [31:0] pc_id,
    output logic pred_taken,

    // Write/Update Port (EX Stage)
    input logic update_en,               // Valid Branch in EX
    input logic [31:0] pc_ex,
    input logic actual_taken
);

    // 2-bit Saturating Counters
    // 00: Strongly Not Taken            // 01: Weakly Not Taken
    // 10: Weakly Taken                  // 11: Strongly Taken
    logic [1:0] counters [0:31]; 
    logic [4:0] read_index;
    logic [4:0] write_index;

    assign read_index = pc_id[6:2];      // Simple Hash: Use PC bits 6-2
    assign write_index = pc_ex[6:2];

    // Prediction Logic (Combinational)
    // Predict Taken if counter MSB is 1 (10 or 11)
    assign pred_taken = counters[read_index][1];

    // Update Logic (Sequential)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 32; i++) 
                counters[i] <= 2'b01; // Initialize to Weakly Not Taken
        end else if (update_en) begin
            case (counters[write_index])
                2'b00: counters[write_index] <= (actual_taken) ? 2'b01 : 2'b00;
                2'b01: counters[write_index] <= (actual_taken) ? 2'b10 : 2'b00;
                2'b10: counters[write_index] <= (actual_taken) ? 2'b11 : 2'b01;
                2'b11: counters[write_index] <= (actual_taken) ? 2'b11 : 2'b10;
            endcase
        end
    end

endmodule