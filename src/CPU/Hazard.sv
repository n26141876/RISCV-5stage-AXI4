module Hazard (
    input logic [4:0] rs1_if_id,
    input logic [4:0] rs2_if_id,
    input logic [4:0] rd_id_ex,
    input logic mem_read_id_ex,
    
    // Control Hazard Signals
    input logic mispredict, // From EX stage (Prediction Wrong)
    
    output logic stall_if_id,
    output logic stall_pc,
    output logic flush_if_id,
    output logic flush_id_ex
);

    logic load_use_hazard;

    always_comb begin
        // Load-Use Hazard Detection
        load_use_hazard = mem_read_id_ex && ((rd_id_ex == rs1_if_id) || (rd_id_ex == rs2_if_id));
        
        stall_if_id = load_use_hazard;
        stall_pc    = load_use_hazard;
        
        // Flush on Misprediction or Load-Use
        // If mispredict, we need to flush instruction in IF/ID and ID/EX to restart
        flush_if_id = mispredict; 
        flush_id_ex = load_use_hazard || mispredict;
    end

endmodule