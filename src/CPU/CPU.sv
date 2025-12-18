module CPU (
    input logic clk,
    input logic rst_n,

    output logic [31:0] pc_out,
    input logic [31:0] instr_in,
    input logic wait_imem,

    output logic [31:0] data_addr,
    output logic [31:0] data_in,
    input logic [31:0] data_out,
    output logic [3:0] data_strb,
    output logic data_read,
    output logic data_write,
    input logic wait_dmem
);
    logic stall_pipeline;
    assign stall_pipeline = wait_imem | wait_dmem;

    logic [31:0] pc_curr, pc_next;
    logic [31:0] pc_if_id;
    logic [31:0] instr_if_id;
    logic stall_if_id, stall_pc;
    logic flush_if_id, flush_id_ex;
    
    // Branch Prediction Signals
    logic mispredict;
    logic [31:0] pc_correct_ex; 
    logic pred_taken_id;
    logic [31:0] pred_target_id;
    logic id_redirect; 

    logic pc_write_enable;
    assign pc_write_enable = !stall_pipeline && !stall_pc;

    // --- PC Logic ---
    always_comb begin
        if (mispredict) 
            pc_next = pc_correct_ex;
        else if (id_redirect)
            pc_next = pred_target_id;
        else
            pc_next = pc_curr + 4;
    end

    PC i_PC (
        .clk(clk),
        .rst_n(rst_n),
        .pc_write(pc_write_enable),
        .pc_next(pc_next),
        .pc_curr(pc_curr)
    );
    assign pc_out = pc_curr;

    // --- IF/ID Register ---
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_if_id <= 32'b0;
            instr_if_id <= 32'b0;
        end else if (!stall_pipeline) begin
            if (flush_if_id || id_redirect) begin
                pc_if_id <= 32'b0;
                instr_if_id <= 32'b0; 
            end else if (!stall_if_id) begin
                pc_if_id <= pc_curr;
                instr_if_id <= instr_in;
            end
        end
    end

    // --- ID Stage ---
    logic [31:0] rs1_data_id, rs2_data_id;
    logic [31:0] imm_id;
    logic [4:0]  rs1_addr_id, rs2_addr_id, rd_addr_id;
    logic [6:0]  opcode_id; 
    logic [6:0]  funct7_id;
    logic [2:0]  funct3_id;
    logic       reg_write_id, mem_read_id, mem_write_id;
    logic       alu_src_a_id, alu_src_b_id;
    logic [4:0] alu_ctrl_id; 
    logic       branch_id;
    logic       jump_id;
    logic [1:0] wb_src_id;
    logic       csr_write_id;
    logic [2:0] csr_op_id;
    logic [3:0] data_strb_id;

    logic [31:0] wb_data_wb;
    logic [4:0]  rd_addr_wb;
    logic        reg_write_wb;

    assign opcode_id   = instr_if_id[6:0];
    assign rd_addr_id  = instr_if_id[11:7];
    assign funct3_id   = instr_if_id[14:12];
    assign rs1_addr_id = instr_if_id[19:15];
    assign rs2_addr_id = instr_if_id[24:20];
    assign funct7_id   = instr_if_id[31:25];

    ID_Register i_ID_Register (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write_wb && !stall_pipeline),
        .rs1_addr(rs1_addr_id),
        .rs2_addr(rs2_addr_id),
        .rd_addr(rd_addr_wb),
        .rd_data(wb_data_wb),
        .rs1_data(rs1_data_id),
        .rs2_data(rs2_data_id)
    );

    ImmGen i_ImmGen (
        .instr(instr_if_id),
        .imm(imm_id)
    );

    Instruction_Decoder i_Instruction_Decoder (
        .opcode(opcode_id),
        .funct3(funct3_id),
        .funct7_5(instr_if_id[30]), 
        .reg_write(reg_write_id),
        .mem_write(mem_write_id),
        .mem_read(mem_read_id),
        .alu_src(alu_src_b_id), 
        .result_src(wb_src_id),
        .imm_src(),             
        .alu_control(alu_ctrl_id),
        .branch(branch_id),
        .jump(jump_id),
        .csr_write(csr_write_id),
        .csr_op(csr_op_id),
        .mem_strb(data_strb_id)
    );

    // Logic for ALU Src A (PC vs RS1)
    // AUIPC (0010111) and JAL (1101111) need PC at ALU Src A
    assign alu_src_a_id = (opcode_id == 7'b0010111) || (opcode_id == 7'b1101111);

    logic is_jal_id, is_jalr_id;
    assign is_jal_id  = (opcode_id == 7'b1101111);
    assign is_jalr_id = (opcode_id == 7'b1100111);

    // Branch Prediction (ID Stage)
    logic actual_taken_ex;
    logic [31:0] pc_ex;
    logic branch_ex_valid;

    BranchPredictor i_BP (
        .clk(clk),
        .rst_n(rst_n),
        .pc_id(pc_if_id),
        .pred_taken(pred_taken_id),
        .update_en(branch_ex_valid), 
        .pc_ex(pc_ex),
        .actual_taken(actual_taken_ex)
    );
    assign pred_target_id = pc_if_id + imm_id;
    
    always_comb begin
        id_redirect = 1'b0;
        if (is_jal_id) begin
            id_redirect = 1'b1;
        end else if (branch_id && pred_taken_id) begin
            id_redirect = 1'b1;
        end
    end

    // --- ID/EX Register ---
    logic [31:0] rs1_data_ex, rs2_data_ex;
    logic [31:0] imm_ex;
    logic [4:0]  rs1_addr_ex, rs2_addr_ex, rd_addr_ex;
    logic [4:0]  alu_ctrl_ex;
    logic        reg_write_ex, mem_read_ex, mem_write_ex;
    logic        alu_src_a_ex, alu_src_b_ex;
    logic        branch_ex, jal_ex, jalr_ex;
    logic [1:0]  wb_src_ex;
    logic [2:0]  funct3_ex;
    logic        csr_write_ex;
    logic [2:0]  csr_op_ex;
    logic [3:0]  data_strb_ex;
    logic        pred_taken_ex; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_ex <= 0;
            mem_read_ex <= 0; mem_write_ex <= 0;
            branch_ex <= 0; jal_ex <= 0; jalr_ex <= 0;
            pc_ex <= 0;
            imm_ex <= 0;
            rs1_data_ex <= 0; rs2_data_ex <= 0;
            rs1_addr_ex <= 0; rs2_addr_ex <= 0; rd_addr_ex <= 0;
            alu_ctrl_ex <= 0; alu_src_a_ex <= 0; alu_src_b_ex <= 0; wb_src_ex <= 0;
            funct3_ex <= 0;
            csr_write_ex <= 0;
            csr_op_ex <= 0;
            data_strb_ex <= 0;
            pred_taken_ex <= 0;
        end else if (!stall_pipeline) begin
            if (flush_id_ex) begin
                reg_write_ex <= 0;
                mem_read_ex <= 0; mem_write_ex <= 0;
                branch_ex <= 0; jal_ex <= 0; jalr_ex <= 0;
                pc_ex <= 0;
                imm_ex <= 0;
                rs1_data_ex <= 0; rs2_data_ex <= 0;
                rs1_addr_ex <= 0; rs2_addr_ex <= 0; rd_addr_ex <= 0;
                alu_ctrl_ex <= 0; alu_src_a_ex <= 0; alu_src_b_ex <= 0; wb_src_ex <= 0;
                funct3_ex <= 0;
                csr_write_ex <= 0;
                csr_op_ex <= 0;
                data_strb_ex <= 0;
                pred_taken_ex <= 0;
            end else begin
                reg_write_ex <= reg_write_id;
                mem_read_ex  <= mem_read_id;
                mem_write_ex <= mem_write_id;
                branch_ex    <= branch_id;
                jal_ex       <= is_jal_id;
                jalr_ex      <= is_jalr_id;
                wb_src_ex    <= wb_src_id;
                alu_src_a_ex <= alu_src_a_id;
                alu_src_b_ex <= alu_src_b_id;
                alu_ctrl_ex  <= alu_ctrl_id;
                csr_write_ex <= csr_write_id;
                csr_op_ex    <= csr_op_id;
                data_strb_ex <= data_strb_id;
                
                pc_ex        <= pc_if_id;
                imm_ex       <= imm_id;
                rs1_data_ex  <= rs1_data_id;
                rs2_data_ex  <= rs2_data_id;
                rs1_addr_ex  <= rs1_addr_id;
                rs2_addr_ex  <= rs2_addr_id;
                rd_addr_ex   <= rd_addr_id;
                funct3_ex    <= funct3_id;
                pred_taken_ex <= (branch_id && pred_taken_id); 
            end
        end
    end

    // --- EX Stage ---
    logic [1:0] forward_a, forward_b;
    logic [31:0] alu_in_a_temp, alu_in_a;
    logic [31:0] alu_in_b_temp, alu_in_b;
    logic [31:0] alu_result_ex;
    logic [31:0] alu_result_mem;
    logic [31:0] csr_rdata_ex;

    always_comb begin
        case (forward_a)
            2'b00: alu_in_a_temp = rs1_data_ex;
            2'b10: alu_in_a_temp = alu_result_mem; 
            2'b01: alu_in_a_temp = wb_data_wb;    
            default: alu_in_a_temp = rs1_data_ex;
        endcase

        case (forward_b)
            2'b00: alu_in_b_temp = rs2_data_ex;
            2'b10: alu_in_b_temp = alu_result_mem;
            2'b01: alu_in_b_temp = wb_data_wb;
            default: alu_in_b_temp = rs2_data_ex;
        endcase
        
        alu_in_a = (alu_src_a_ex) ? pc_ex : alu_in_a_temp;
        alu_in_b = (alu_src_b_ex) ? imm_ex : alu_in_b_temp;
    end

    ALU i_ALU (
        .src1(alu_in_a),
        .src2(alu_in_b),
        .ctrl(alu_ctrl_ex), 
        .result(alu_result_ex) 
    );

    logic [31:0] store_data_aligned;
    logic [3:0]  data_strb_aligned;

    always_comb begin
        store_data_aligned = alu_in_b_temp; 
        data_strb_aligned  = data_strb_ex;
        case (alu_result_ex[1:0])
            2'b00: begin 
                store_data_aligned = alu_in_b_temp;
                data_strb_aligned  = data_strb_ex;
            end
            2'b01: begin 
                store_data_aligned = alu_in_b_temp << 8;
                data_strb_aligned  = data_strb_ex << 1;
            end
            2'b10: begin 
                store_data_aligned = alu_in_b_temp << 16;
                data_strb_aligned  = data_strb_ex << 2;
            end
            2'b11: begin 
                store_data_aligned = alu_in_b_temp << 24;
                data_strb_aligned  = data_strb_ex << 3;
            end
        endcase
    end

    logic inst_retire_wb;
    
    CSR i_CSR (
        .clk(clk),
        .rst_n(rst_n),
        .inst_retire(inst_retire_wb),
        .csr_addr(imm_ex[11:0]), 
        .csr_write(csr_write_ex),
        .funct3(csr_op_ex),
        .wdata(alu_in_a_temp), 
        .rdata(csr_rdata_ex)
    );

    // Branch Resolution & Misprediction Logic
    always_comb begin
        actual_taken_ex = 1'b0;
        mispredict = 1'b0;
        pc_correct_ex = pc_ex + 4;
        branch_ex_valid = branch_ex;

        if (jalr_ex) begin
            actual_taken_ex = 1'b1;
            pc_correct_ex = alu_result_ex;
            mispredict = 1'b1; 
        end else if (branch_ex) begin
            case (funct3_ex)
                3'b000: actual_taken_ex = (alu_in_a_temp == alu_in_b_temp); // BEQ
                3'b001: actual_taken_ex = (alu_in_a_temp != alu_in_b_temp); // BNE
                3'b100: actual_taken_ex = ($signed(alu_in_a_temp) < $signed(alu_in_b_temp)); // BLT
                3'b101: actual_taken_ex = ($signed(alu_in_a_temp) >= $signed(alu_in_b_temp)); // BGE
                3'b110: actual_taken_ex = (alu_in_a_temp < alu_in_b_temp); // BLTU
                3'b111: actual_taken_ex = (alu_in_a_temp >= alu_in_b_temp); // BGEU
                default: actual_taken_ex = 1'b0;
            endcase
            
            if (actual_taken_ex != pred_taken_ex) begin
                mispredict = 1'b1;
                if (actual_taken_ex) 
                    pc_correct_ex = pc_ex + imm_ex;
                else 
                    pc_correct_ex = pc_ex + 4;
            end
        end
    end

    // --- EX/MEM Register ---
    logic reg_write_mem, mem_read_mem, mem_write_mem;
    logic [1:0] wb_src_mem;
    logic [31:0] store_data_mem;
    logic [4:0] rd_addr_mem;
    logic [31:0] pc_plus_4_mem;
    logic [31:0] csr_rdata_mem;
    logic [3:0] data_strb_mem;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_mem <= 0;
            mem_read_mem <= 0; mem_write_mem <= 0;
            wb_src_mem <= 0;
            alu_result_mem <= 0; store_data_mem <= 0;
            rd_addr_mem <= 0;
            pc_plus_4_mem <= 0;
            csr_rdata_mem <= 0;
            data_strb_mem <= 0;
        end else if (!stall_pipeline) begin
            reg_write_mem <= reg_write_ex;
            mem_read_mem  <= mem_read_ex;
            mem_write_mem <= mem_write_ex;
            wb_src_mem    <= wb_src_ex;
            
            alu_result_mem <= alu_result_ex;
            store_data_mem <= store_data_aligned; 
            rd_addr_mem    <= rd_addr_ex;
            pc_plus_4_mem  <= pc_ex + 4;
            csr_rdata_mem  <= csr_rdata_ex;
            data_strb_mem  <= data_strb_aligned;
        end
    end

    assign data_addr  = alu_result_mem;
    assign data_in    = store_data_mem;
    assign data_read  = mem_read_mem;
    assign data_write = mem_write_mem;
    assign data_strb  = data_strb_mem;

    // --- MEM/WB Register ---
    logic [1:0] wb_src_wb;
    logic [31:0] alu_result_wb;
    logic [31:0] read_data_wb;
    logic [31:0] pc_plus_4_wb;
    logic [31:0] csr_rdata_wb;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_wb <= 0;
            wb_src_wb <= 0;
            alu_result_wb <= 0;
            read_data_wb <= 0;
            rd_addr_wb <= 0;
            pc_plus_4_wb <= 0;
            csr_rdata_wb <= 0;
            inst_retire_wb <= 0;
        end else if (!stall_pipeline) begin
            reg_write_wb <= reg_write_mem;
            wb_src_wb    <= wb_src_mem;
            rd_addr_wb   <= rd_addr_mem;
            
            alu_result_wb <= alu_result_mem;
            read_data_wb  <= data_out;
            pc_plus_4_wb  <= pc_plus_4_mem;
            csr_rdata_wb  <= csr_rdata_mem;
            inst_retire_wb <= (pc_plus_4_mem != 0);
        end
    end

    always_comb begin
        case (wb_src_wb)
            2'b00: wb_data_wb = alu_result_wb;
            2'b01: wb_data_wb = read_data_wb;
            2'b10: wb_data_wb = pc_plus_4_wb;
            2'b11: wb_data_wb = csr_rdata_wb; 
            default: wb_data_wb = 32'b0;
        endcase
    end

    Forwarding i_Forwarding (
        .rs1_id_ex(rs1_addr_ex),
        .rs2_id_ex(rs2_addr_ex),
        .rd_ex_mem(rd_addr_mem),
        .reg_write_ex_mem(reg_write_mem),
        .rd_mem_wb(rd_addr_wb),
        .reg_write_mem_wb(reg_write_wb),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    Hazard i_Hazard (
        .rs1_if_id(rs1_addr_id),
        .rs2_if_id(rs2_addr_id),
        .rd_id_ex(rd_addr_ex),
        .mem_read_id_ex(mem_read_ex),
        .mispredict(mispredict), 
        .stall_if_id(stall_if_id),
        .stall_pc(stall_pc),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex)
    );
endmodule