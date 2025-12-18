module CSR (
    input logic clk,
    input logic rst_n,
    
    // Instruction Retirement (from WB stage)
    input logic inst_retire, 

    // CSR Access Interface (from EX or ID stage)
    input logic [11:0] csr_addr,
    input logic csr_write,      // Write enable
    input logic [2:0] funct3,   // CSR operation type (RW, RS, RC)
    input logic [31:0] wdata,   // Data from RS1 or Imm
    output logic [31:0] rdata   // Data to RD
);

    // 64-bit Counters
    logic [63:0] cycle_counter;
    logic [63:0] instret_counter;

    // Address Mapping (Based on RISC-V Standard)
    localparam ADDR_CYCLE    = 12'hC00;
    localparam ADDR_CYCLEH   = 12'hC80;
    localparam ADDR_INSTRET  = 12'hC02;
    localparam ADDR_INSTRETH = 12'hC82;

    // Cycle Counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 64'b0;
        end else begin
            cycle_counter <= cycle_counter + 64'b1;
        end
    end

    // Instruction Retire Counter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instret_counter <= 64'b0;
        end else if (inst_retire) begin
            instret_counter <= instret_counter + 64'b1;
        end
    end

    // Read Logic
    always_comb begin
        case (csr_addr)
            ADDR_CYCLE:    rdata = cycle_counter[31:0];
            ADDR_CYCLEH:   rdata = cycle_counter[63:32];
            ADDR_INSTRET:  rdata = instret_counter[31:0];
            ADDR_INSTRETH: rdata = instret_counter[63:32];
            default:       rdata = 32'b0;
        endcase
    end

    // Note: HW1 spec mainly requires reading these counters. 
    // Explicit writing to these counters via CSR instructions is usually restricted or ignored in simple labs,
    // but full CSR logic (RW, RS, RC) is implemented below for completeness if expanding to other registers.
    
    // Write Logic (Optional for counters in this specific lab, but good for completeness)
    // In this lab, we assume counters are read-only via instructions, hardware updates them.
    // So no explicit write logic to cycle/instret is added here to avoid conflict.

endmodule