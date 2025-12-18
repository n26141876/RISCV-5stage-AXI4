module Forwarding (
    input logic [4:0] rs1_id_ex,
    input logic [4:0] rs2_id_ex,
    input logic [4:0] rd_ex_mem,
    input logic reg_write_ex_mem,
    input logic [4:0] rd_mem_wb,
    input logic reg_write_mem_wb,
    
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);

    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (reg_write_ex_mem && (rd_ex_mem != 5'b0) && (rd_ex_mem == rs1_id_ex)) begin
            forward_a = 2'b10;
        end else if (reg_write_mem_wb && (rd_mem_wb != 5'b0) && (rd_mem_wb == rs1_id_ex)) begin
            forward_a = 2'b01;
        end

        if (reg_write_ex_mem && (rd_ex_mem != 5'b0) && (rd_ex_mem == rs2_id_ex)) begin
            forward_b = 2'b10;
        end else if (reg_write_mem_wb && (rd_mem_wb != 5'b0) && (rd_mem_wb == rs2_id_ex)) begin
            forward_b = 2'b01;
        end
    end

endmodule