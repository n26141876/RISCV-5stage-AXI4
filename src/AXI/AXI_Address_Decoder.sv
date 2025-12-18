module AXI_Address_Decoder (
    input logic [31:0] addr,
    
    output logic valid_s1, 
    output logic valid_s2, 
    output logic valid_sd  
);

    always_comb begin
        valid_s1 = 1'b0;
        valid_s2 = 1'b0;
        valid_sd = 1'b0;

        case (addr[31:16])
            16'h0000: valid_s1 = 1'b1;
            16'h0001: valid_s2 = 1'b1;
            default:  valid_sd = 1'b1;
        endcase
    end

endmodule