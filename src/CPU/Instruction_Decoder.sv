module Instruction_Decoder (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    output reg        reg_write,
    output reg        mem_write,
    output reg        mem_read,
    output reg        alu_src,
    output reg  [1:0] result_src,
    output reg  [2:0] imm_src,
    output reg  [4:0] alu_control, 
    output reg        branch,
    output reg        jump,
    output reg        csr_write,
    output reg  [2:0] csr_op,
    output reg  [3:0] mem_strb
);

    always @(*) begin
        // Default Control Signals
        reg_write   = 0;
        mem_write   = 0;
        mem_read    = 0;
        alu_src     = 0;
        result_src  = 2'b00;
        imm_src     = 3'b000;
        alu_control = 5'b00000; 
        branch      = 0;
        jump        = 0;
        csr_write   = 0;
        csr_op      = 3'b000;
        mem_strb    = 4'b1111; // Default strobe

        case (opcode)
            7'b0110011: begin // R-type
                reg_write = 1;
                case (funct3)
                    3'b000: alu_control = (funct7_5) ? 5'b00001 : 5'b00000; // SUB : ADD
                    3'b001: alu_control = 5'b00100; // SLL
                    3'b010: alu_control = 5'b00101; // SLT
                    3'b011: alu_control = 5'b01001; // SLTU
                    3'b100: alu_control = 5'b00110; // XOR
                    3'b101: alu_control = (funct7_5) ? 5'b01000 : 5'b00111; // SRA : SRL
                    3'b110: alu_control = 5'b00011; // OR
                    3'b111: alu_control = 5'b00010; // AND
                    default: alu_control = 5'b00000;
                endcase
            end

            7'b0010011: begin // I-type ALU
                reg_write = 1;
                alu_src   = 1;
                imm_src   = 3'b000;
                case (funct3)
                    3'b000: alu_control = 5'b00000; // ADDI
                    3'b001: alu_control = 5'b00100; // SLLI
                    3'b010: alu_control = 5'b00101; // SLTI
                    3'b011: alu_control = 5'b01001; // SLTIU
                    3'b100: alu_control = 5'b00110; // XORI
                    3'b101: alu_control = (funct7_5) ? 5'b01000 : 5'b00111; // SRAI : SRLI
                    3'b110: alu_control = 5'b00011; // ORI
                    3'b111: alu_control = 5'b00010; // ANDI
                    default: alu_control = 5'b00000;
                endcase
            end

            7'b0000011: begin // Load
                reg_write   = 1;
                mem_read    = 1;
                alu_src     = 1;
                result_src  = 2'b01;
                imm_src     = 3'b000;
                alu_control = 5'b00000; // ADD (Base + Offset)
            end

            7'b0100011: begin // Store
                mem_write   = 1;
                alu_src     = 1;
                imm_src     = 3'b001;
                alu_control = 5'b00000; // ADD (Base + Offset)
                // Decode write strobe for SB, SH, SW
                case (funct3)
                    3'b000: mem_strb = 4'b0001; // SB
                    3'b001: mem_strb = 4'b0011; // SH
                    default: mem_strb = 4'b1111; // SW
                endcase
            end

            7'b1100011: begin // Branch
                branch      = 1;
                imm_src     = 3'b010;
                alu_control = 5'b00001; // SUB for comparison
                case (funct3)
                    3'b000: alu_control = 5'b01010; // BEQ
                    3'b001: alu_control = 5'b01011; // BNE
                    3'b100: alu_control = 5'b01100; // BLT
                    3'b101: alu_control = 5'b01101; // BGE
                    3'b110: alu_control = 5'b01110; // BLTU
                    3'b111: alu_control = 5'b01111; // BGEU
                    default: alu_control = 5'b00000;
                endcase
            end

            7'b1101111: begin // JAL
                reg_write   = 1;
                jump        = 1;
                imm_src     = 3'b011;
                result_src  = 2'b10;
            end

            7'b1100111: begin // JALR
                reg_write   = 1;
                jump        = 1;
                alu_src     = 1;
                imm_src     = 3'b000;
                result_src  = 2'b10;
                alu_control = 5'b00000;
            end

            7'b0110111: begin // LUI
                reg_write   = 1;
                imm_src     = 3'b100;
                alu_src     = 1;
                result_src  = 2'b00;
                alu_control = 5'b10000; 
            end

            7'b0010111: begin // AUIPC
                reg_write   = 1;
                imm_src     = 3'b100;
                result_src  = 2'b00;
                alu_control = 5'b10001;
            end

            7'b1110011: begin // SYSTEM (CSR Instructions)
                reg_write   = 1;     // Write CSR read data to RD
                result_src  = 2'b11; // Select CSR output in WB mux
                csr_write   = 1;     // Enable CSR write
                csr_op      = funct3;
                imm_src     = 3'b000; // Usually zimm or rs1
            end

            default: begin
                reg_write = 0;
            end
        endcase
    end
endmodule