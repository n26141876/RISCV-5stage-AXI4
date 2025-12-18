module ALU (
    input logic [31:0] src1,
    input logic [31:0] src2,
    input logic [3:0] ctrl,
    output logic [31:0] result
);

    logic signed [63:0] mul_res_signed;
    logic signed [63:0] mul_res_hsu;
    logic [63:0] mul_res_unsigned;

    // Multiplication logic for M-Extension
    assign mul_res_signed = $signed(src1) * $signed(src2);
    assign mul_res_hsu = $signed(src1) * $signed({1'b0, src2});
    assign mul_res_unsigned = src1 * src2;

    always_comb begin
        case (ctrl)
            // --- RV32I Base Integer Instructions ---
            4'b0000: result = src1 + src2;                                          // ADD
            4'b0001: result = src1 - src2;                                          // SUB
            4'b0010: result = src1 << src2[4:0];                                    // SLL
            4'b0011: result = ($signed(src1) < $signed(src2)) ? 32'b1 : 32'b0;      // SLT
            4'b0100: result = (src1 < src2) ? 32'b1 : 32'b0;                        // SLTU
            4'b0101: result = src1 ^ src2;                                          // XOR
            4'b0110: result = src1 >> src2[4:0];                                    // SRL
            4'b0111: result = $signed(src1) >>> src2[4:0];                          // SRA
            4'b1000: result = src1 | src2;                                          // OR
            4'b1001: result = src1 & src2;                                          // AND

            // --- RV32M Multiplication Extension ---
            4'b1010: result = mul_res_signed[31:0];                                 // MUL (Lower 32 bits)
            4'b1011: result = mul_res_signed[63:32];                                // MULH (Upper 32 bits Signed x Signed)
            4'b1100: result = mul_res_hsu[63:32];                                   // MULHSU (Upper 32 bits Signed x Unsigned)
            4'b1101: result = mul_res_unsigned[63:32];                              // MULHU (Upper 32 bits Unsigned x Unsigned)

            // --- Special Operations ---
            4'b1110: result = src2;                                                 // LUI COPY
            
            default: result = 32'b0;
        endcase
    end

endmodule