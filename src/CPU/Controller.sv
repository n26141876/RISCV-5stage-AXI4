module Controller (
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    
    output logic reg_write,
    output logic [3:0] alu_ctrl,
    output logic alu_src_a,
    output logic alu_src_b,
    output logic [1:0] wb_src,  // 0:ALU, 1:Mem, 2:PC+4, 3:CSR
    output logic data_read,
    output logic data_write,
    output logic [3:0] data_strb,
    output logic branch_taken,
    
    // CSR Control Signals
    output logic csr_write,
    output logic [2:0] csr_op
);

    localparam R_TYPE = 7'b0110011;
    localparam I_TYPE = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;
    localparam JAL    = 7'b1101111;
    localparam JALR   = 7'b1100111;
    localparam LUI    = 7'b0110111;
    localparam AUIPC  = 7'b0010111;
    localparam SYSTEM = 7'b1110011; // CSR Instructions

    logic [2:0] alu_op;

    always_comb begin
        // Default values
        reg_write = 0;
        alu_src_a = 0;
        alu_src_b = 0;
        wb_src = 0;
        data_read = 0;
        data_write = 0;
        branch_taken = 0;
        alu_op = 3'b000;
        data_strb = 4'b1111;
        
        csr_write = 0;
        csr_op = 3'b000;

        case (opcode)
            R_TYPE: begin
                reg_write = 1;
                alu_src_a = 0;
                alu_src_b = 0;
                wb_src = 0;
                alu_op = 3'b010;
                if (funct7[0]) alu_op = 3'b011; // For MUL extension distinction
            end
            I_TYPE: begin
                reg_write = 1;
                alu_src_a = 0;
                alu_src_b = 1;
                wb_src = 0;
                alu_op = 3'b010;
            end
            LOAD: begin
                reg_write = 1;
                alu_src_a = 0;
                alu_src_b = 1;
                wb_src = 1;
                data_read = 1;
                alu_op = 3'b000; // ADD
            end
            STORE: begin
                reg_write = 0;
                alu_src_a = 0;
                alu_src_b = 1;
                data_write = 1;
                alu_op = 3'b000; // ADD
                case (funct3)
                    3'b000: data_strb = 4'b0001; // SB
                    3'b001: data_strb = 4'b0011; // SH
                    default: data_strb = 4'b1111; // SW
                endcase
            end
            BRANCH: begin
                branch_taken = 1;
                alu_src_a = 0;
                alu_src_b = 0;
                alu_op = 3'b001;
            end
            JAL: begin
                reg_write = 1;
                wb_src = 2;
                branch_taken = 1;
            end
            JALR: begin
                reg_write = 1;
                alu_src_a = 0;
                alu_src_b = 1;
                wb_src = 2;
                alu_op = 3'b000;
                branch_taken = 1;
            end
            LUI: begin
                reg_write = 1;
                alu_src_a = 0; // Don't care
                alu_src_b = 1; // Imm
                wb_src = 0;
                alu_op = 3'b100; // Copy src2
            end
            AUIPC: begin
                reg_write = 1;
                alu_src_a = 1; // PC
                alu_src_b = 1; // Imm
                wb_src = 0;
                alu_op = 3'b000; // ADD
            end
            SYSTEM: begin // CSR Instructions
                reg_write = 1; // Write to RD (Old value of CSR)
                wb_src = 3;    // Data from CSR
                csr_write = 1; // Enable CSR write (controlled by funct3 inside CSR usually, or filtered here)
                csr_op = funct3;
                // Note: Actual CSR write also depends on rs1 != x0 for CSRRS/CSRRC
            end
            default: ;
        endcase
    end

    // ALU Control Decoder
    always_comb begin
        alu_ctrl = 4'b0000;
        
        case (alu_op)
            3'b000: alu_ctrl = 4'b0000; // ADD
            3'b001: alu_ctrl = 4'b0001; // SUB (Branch comparison)
            3'b010: begin // R-type / I-type
                case (funct3)
                    3'b000: begin 
                        if (opcode == R_TYPE && funct7[5]) 
                            alu_ctrl = 4'b0001; // SUB
                        else 
                            alu_ctrl = 4'b0000; // ADD
                    end
                    3'b001: alu_ctrl = 4'b0010; // SLL
                    3'b010: alu_ctrl = 4'b0011; // SLT
                    3'b011: alu_ctrl = 4'b0100; // SLTU
                    3'b100: alu_ctrl = 4'b0101; // XOR
                    3'b101: begin
                        if (funct7[5]) 
                            alu_ctrl = 4'b0111; // SRA
                        else 
                            alu_ctrl = 4'b0110; // SRL
                    end
                    3'b110: alu_ctrl = 4'b1000; // OR
                    3'b111: alu_ctrl = 4'b1001; // AND
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            3'b011: begin // M-Extension (MUL)
                case (funct3)
                    3'b000: alu_ctrl = 4'b1010; // MUL
                    3'b001: alu_ctrl = 4'b1011; // MULH
                    3'b010: alu_ctrl = 4'b1100; // MULHSU
                    3'b011: alu_ctrl = 4'b1101; // MULHU
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            3'b100: alu_ctrl = 4'b1110; // LUI Copy
            default: alu_ctrl = 4'b0000;
        endcase
    end

endmodule