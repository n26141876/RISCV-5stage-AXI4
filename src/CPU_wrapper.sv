module CPU_wrapper (
    input logic ACLK,
    input logic ARESETn,

    output logic [3:0] AWID_M0,
    output logic [31:0] AWADDR_M0,
    output logic [3:0] AWLEN_M0,
    output logic [2:0] AWSIZE_M0,
    output logic [1:0] AWBURST_M0,
    output logic AWVALID_M0,
    input logic AWREADY_M0,
    output logic [31:0] WDATA_M0,
    output logic [3:0] WSTRB_M0,
    output logic WLAST_M0,
    output logic WVALID_M0,
    input logic WREADY_M0,
    input logic [3:0] BID_M0,
    input logic [1:0] BRESP_M0,
    input logic BVALID_M0,
    output logic BREADY_M0,
    output logic [3:0] ARID_M0,
    output logic [31:0] ARADDR_M0,
    output logic [3:0] ARLEN_M0,
    output logic [2:0] ARSIZE_M0,
    output logic [1:0] ARBURST_M0,
    output logic ARVALID_M0,
    input logic ARREADY_M0,
    input logic [3:0] RID_M0,
    input logic [31:0] RDATA_M0,
    input logic [1:0] RRESP_M0,
    input logic RLAST_M0,
    input logic RVALID_M0,
    output logic RREADY_M0,

    output logic [3:0] AWID_M1,
    output logic [31:0] AWADDR_M1,
    output logic [3:0] AWLEN_M1,
    output logic [2:0] AWSIZE_M1,
    output logic [1:0] AWBURST_M1,
    output logic AWVALID_M1,
    input logic AWREADY_M1,
    output logic [31:0] WDATA_M1,
    output logic [3:0] WSTRB_M1,
    output logic WLAST_M1,
    output logic WVALID_M1,
    input logic WREADY_M1,
    input logic [3:0] BID_M1,
    input logic [1:0] BRESP_M1,
    input logic BVALID_M1,
    output logic BREADY_M1,
    output logic [3:0] ARID_M1,
    output logic [31:0] ARADDR_M1,
    output logic [3:0] ARLEN_M1,
    output logic [2:0] ARSIZE_M1,
    output logic [1:0] ARBURST_M1,
    output logic ARVALID_M1,
    input logic ARREADY_M1,
    input logic [3:0] RID_M1,
    input logic [31:0] RDATA_M1,
    input logic [1:0] RRESP_M1,
    input logic RLAST_M1,
    input logic RVALID_M1,
    output logic RREADY_M1
);

    logic [31:0] pc_out;
    logic [31:0] instr_in;
    logic wait_imem;

    logic [31:0] data_addr;
    logic [31:0] data_in;
    logic [31:0] data_out;
    logic [3:0] data_strb;
    logic data_read;
    logic data_write;
    logic wait_dmem;
    logic [2:0] data_type;

    assign AWID_M0 = 4'b0;
    assign AWADDR_M0 = 32'b0;
    assign AWLEN_M0 = 4'b0;
    assign AWSIZE_M0 = 3'b010;
    assign AWBURST_M0 = 2'b01;
    assign AWVALID_M0 = 1'b0;
    assign WDATA_M0 = 32'b0;
    assign WSTRB_M0 = 4'b0;
    assign WLAST_M0 = 1'b0;
    assign WVALID_M0 = 1'b0;
    assign BREADY_M0 = 1'b0;

    assign ARID_M0 = 4'b0;
    assign ARADDR_M0 = pc_out;
    assign ARLEN_M0 = 4'b0;
    assign ARSIZE_M0 = 3'b010;
    assign ARBURST_M0 = 2'b01;
    assign ARVALID_M0 = ARESETn;
    assign RREADY_M0 = 1'b1;

    assign instr_in = RDATA_M0;
    
    always_comb begin
        if (!ARESETn) begin
            wait_imem = 1'b0;
        end else begin
            wait_imem = !(RVALID_M0 && RREADY_M0);
        end
    end

    assign AWID_M1 = 4'b0001;
    assign AWADDR_M1 = data_addr;
    assign AWLEN_M1 = 4'b0;
    assign AWSIZE_M1 = 3'b010;
    assign AWBURST_M1 = 2'b01;
    assign AWVALID_M1 = data_write;
    
    assign WDATA_M1 = data_out;
    assign WSTRB_M1 = data_strb;
    assign WLAST_M1 = 1'b1;
    assign WVALID_M1 = data_write;
    
    assign BREADY_M1 = 1'b1;

    assign ARID_M1 = 4'b0001;
    assign ARADDR_M1 = data_addr;
    assign ARLEN_M1 = 4'b0;
    assign ARSIZE_M1 = 3'b010;
    assign ARBURST_M1 = 2'b01;
    assign ARVALID_M1 = data_read;
    
    assign RREADY_M1 = 1'b1;

    assign data_in = RDATA_M1;

    logic r_wait, w_wait;
    
    always_comb begin
        r_wait = data_read & (~(RVALID_M1 & RREADY_M1));
        w_wait = data_write & (~(BVALID_M1 & BREADY_M1));
        wait_dmem = r_wait | w_wait;
    end

    CPU i_CPU (
        .clk(ACLK),
        .rst_n(ARESETn),
        
        .pc_out(pc_out),
        .instr_in(instr_in),
        .wait_imem(wait_imem),
        
        .data_addr(data_addr),
        .data_in(data_in),
        .data_out(data_out),
        .data_strb(data_strb),
        .data_read(data_read),
        .data_write(data_write),
        .wait_dmem(wait_dmem)
    );

endmodule