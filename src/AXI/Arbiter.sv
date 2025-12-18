module Arbiter (
    input logic clk,
    input logic rst_n,
    
    // Request signals (VALID from Masters)
    input logic req_m0,
    input logic req_m1,
    
    // Handshake done (READY & VALID are both high)
    // Used to toggle priority
    input logic handshake, 

    // Grant signals
    output logic grant_m0,
    output logic grant_m1
);

    // 0: Priority to M0, 1: Priority to M1
    logic priority_bit;

    // Update Priority: Toggle only when the prioritized master finishes a handshake
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_bit <= 1'b0; // Default M0 priority
        end else if (handshake) begin
            // If M0 finished and M1 is waiting, give to M1. Or simple toggle.
            // Simple Round-Robin: Toggle every time a grant is used.
            priority_bit <= ~priority_bit;
        end
    end

    // Combinational Grant Logic
    always_comb begin
        grant_m0 = 1'b0;
        grant_m1 = 1'b0;

        case (priority_bit)
            1'b0: begin // Priority M0
                if (req_m0)      grant_m0 = 1'b1;
                else if (req_m1) grant_m1 = 1'b1;
            end
            1'b1: begin // Priority M1
                if (req_m1)      grant_m1 = 1'b1;
                else if (req_m0) grant_m0 = 1'b1;
            end
        endcase
    end

endmodule