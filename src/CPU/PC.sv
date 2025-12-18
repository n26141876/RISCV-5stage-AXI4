module PC (
    input logic clk,
    input logic rst_n,
    input logic pc_write,
    input logic [31:0] pc_next,
    output logic [31:0] pc_curr
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_curr <= 32'b0;
        end else if (pc_write) begin
            pc_curr <= pc_next;
        end
    end

endmodule