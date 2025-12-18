//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2025 Advanced VLSI System Design, advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Autor: 			TZUNG-JIN, TSAI (Leo)				  	   		//
//	Filename:		 AXI.sv			                            	//
//	Description:	Top module of AXI	 							//
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
`include "AXI_define.svh"

module AXI(
    input ACLK,
    input ARESETn,

    // ==========================================================
    // Master Interface (Inputs from Masters, Outputs to Masters)
    // ==========================================================
    
    // --- Master 1 (Data Master) ---
    // Write Address (AW)
    input [`AXI_ID_BITS-1:0] AWID_M1,
    input [`AXI_ADDR_BITS-1:0] AWADDR_M1,
    input [`AXI_LEN_BITS-1:0] AWLEN_M1,
    input [`AXI_SIZE_BITS-1:0] AWSIZE_M1,
    input [1:0] AWBURST_M1,
    input AWVALID_M1,
    output logic AWREADY_M1,
    
    // Write Data (W)
    input [`AXI_DATA_BITS-1:0] WDATA_M1,
    input [`AXI_STRB_BITS-1:0] WSTRB_M1,
    input WLAST_M1,
    input WVALID_M1,
    output logic WREADY_M1,
    
    // Write Response (B)
    output logic [`AXI_ID_BITS-1:0] BID_M1,
    output logic [1:0] BRESP_M1,
    output logic BVALID_M1,
    input BREADY_M1,

    // --- Master 0 (Instruction Master) ---
    // Read Address (AR)
    input [`AXI_ID_BITS-1:0] ARID_M0,
    input [`AXI_ADDR_BITS-1:0] ARADDR_M0,
    input [`AXI_LEN_BITS-1:0] ARLEN_M0,
    input [`AXI_SIZE_BITS-1:0] ARSIZE_M0,
    input [1:0] ARBURST_M0,
    input ARVALID_M0,
    output logic ARREADY_M0,
    
    // Read Data (R)
    output logic [`AXI_ID_BITS-1:0] RID_M0,
    output logic [`AXI_DATA_BITS-1:0] RDATA_M0,
    output logic [1:0] RRESP_M0,
    output logic RLAST_M0,
    output logic RVALID_M0,
    input RREADY_M0,
    
    // --- Master 1 (Data Master - Read Side) ---
    input [`AXI_ID_BITS-1:0] ARID_M1,
    input [`AXI_ADDR_BITS-1:0] ARADDR_M1,
    input [`AXI_LEN_BITS-1:0] ARLEN_M1,
    input [`AXI_SIZE_BITS-1:0] ARSIZE_M1,
    input [1:0] ARBURST_M1,
    input ARVALID_M1,
    output logic ARREADY_M1,
    
    output logic [`AXI_ID_BITS-1:0] RID_M1,
    output logic [`AXI_DATA_BITS-1:0] RDATA_M1,
    output logic [1:0] RRESP_M1,
    output logic RLAST_M1,
    output logic RVALID_M1,
    input RREADY_M1,

    // ==========================================================
    // Slave Interface (Outputs to Slaves, Inputs from Slaves)
    // ==========================================================

    // --- Slave 0 (Instruction Memory) ---
    // Write Address
    output logic [`AXI_IDS_BITS-1:0] AWID_S0,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_S0,
    output logic [`AXI_LEN_BITS-1:0] AWLEN_S0,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S0,
    output logic [1:0] AWBURST_S0,
    output logic AWVALID_S0,
    input AWREADY_S0,
    
    // Write Data
    output logic [`AXI_DATA_BITS-1:0] WDATA_S0,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_S0,
    output logic WLAST_S0,
    output logic WVALID_S0,
    input WREADY_S0,
    
    // Write Response
    input [`AXI_IDS_BITS-1:0] BID_S0,
    input [1:0] BRESP_S0,
    input BVALID_S0,
    output logic BREADY_S0,
    
    // Read Address
    output logic [`AXI_IDS_BITS-1:0] ARID_S0,
    output logic [`AXI_ADDR_BITS-1:0] ARADDR_S0,
    output logic [`AXI_LEN_BITS-1:0] ARLEN_S0,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S0,
    output logic [1:0] ARBURST_S0,
    output logic ARVALID_S0,
    input ARREADY_S0,
    
    // Read Data
    input [`AXI_IDS_BITS-1:0] RID_S0,
    input [`AXI_DATA_BITS-1:0] RDATA_S0,
    input [1:0] RRESP_S0,
    input RLAST_S0,
    input RVALID_S0,
    output logic RREADY_S0,
    
    // --- Slave 1 (Data Memory) ---
    // (Signals identical to Slave 0 structure)
    output logic [`AXI_IDS_BITS-1:0] AWID_S1,
    output logic [`AXI_ADDR_BITS-1:0] AWADDR_S1,
    output logic [`AXI_LEN_BITS-1:0] AWLEN_S1,
    output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S1,
    output logic [1:0] AWBURST_S1,
    output logic AWVALID_S1,
    input AWREADY_S1,
    
    output logic [`AXI_DATA_BITS-1:0] WDATA_S1,
    output logic [`AXI_STRB_BITS-1:0] WSTRB_S1,
    output logic WLAST_S1,
    output logic WVALID_S1,
    input WREADY_S1,
    
    input [`AXI_IDS_BITS-1:0] BID_S1,
    input [1:0] BRESP_S1,
    input BVALID_S1,
    output logic BREADY_S1,
    
    output logic [`AXI_IDS_BITS-1:0] ARID_S1,
    output logic [`AXI_ADDR_BITS-1:0] ARADDR_S1,
    output logic [`AXI_LEN_BITS-1:0] ARLEN_S1,
    output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S1,
    output logic [1:0] ARBURST_S1,
    output logic ARVALID_S1,
    input ARREADY_S1,
    
    input [`AXI_IDS_BITS-1:0] RID_S1,
    input [`AXI_DATA_BITS-1:0] RDATA_S1,
    input [1:0] RRESP_S1,
    input RLAST_S1,
    input RVALID_S1,
    output logic RREADY_S1
    
);

    // =========================================================================
    // Internal Signals & Definitions
    // =========================================================================

    // --- Default Slave Signals (For handling invalid addresses) ---
    logic [`AXI_IDS_BITS-1:0] AWID_SD, ARID_SD, BID_SD, RID_SD;
    logic [`AXI_ADDR_BITS-1:0] AWADDR_SD, ARADDR_SD;
    logic [`AXI_LEN_BITS-1:0] AWLEN_SD, ARLEN_SD;
    logic [`AXI_SIZE_BITS-1:0] AWSIZE_SD, ARSIZE_SD;
    logic [1:0] AWBURST_SD, ARBURST_SD;
    logic [`AXI_DATA_BITS-1:0] WDATA_SD, RDATA_SD;
    logic [`AXI_STRB_BITS-1:0] WSTRB_SD;
    logic [1:0] BRESP_SD, RRESP_SD;
    logic AWVALID_SD, WLAST_SD, WVALID_SD, BREADY_SD, ARVALID_SD, RREADY_SD;
    logic AWREADY_SD, WREADY_SD, BVALID_SD, ARREADY_SD, RLAST_SD, RVALID_SD;

    // --- Dummy Signals for Master 0 Write (Read-Only Master) ---
    logic [`AXI_ID_BITS-1:0] AWID_M0_dummy;
    assign AWID_M0_dummy = 4'b0;
    logic AWVALID_M0_dummy;
    assign AWVALID_M0_dummy = 1'b0;

    // =========================================================================
    // 1. Read Address Channel (AR)
    // =========================================================================
    
    // --- Arbitration ---
    logic ar_grant_m0, ar_grant_m1;
    logic ar_handshake;
    
    // Arbiter decides which master (M0 or M1) controls the AR bus
    Arbiter i_AR_Arbiter (
        .clk(ACLK),
        .rst_n(ARESETn),
        .req_m0(ARVALID_M0),
        .req_m1(ARVALID_M1),
        .handshake(ar_handshake),
        .grant_m0(ar_grant_m0),
        .grant_m1(ar_grant_m1)
    );

    // --- Multiplexer (Masters -> Interconnect) ---
    logic [`AXI_ADDR_BITS-1:0] ar_addr_mux;
    logic [`AXI_ID_BITS-1:0] ar_id_mux;
    logic [`AXI_LEN_BITS-1:0] ar_len_mux;
    logic [`AXI_SIZE_BITS-1:0] ar_size_mux;
    logic [1:0] ar_burst_mux;
    logic ar_valid_mux;

    always_comb begin
        if (ar_grant_m0) begin
            // Grant to M0 (Instruction Fetch)
            ar_id_mux    = ARID_M0;
            ar_addr_mux  = ARADDR_M0;
            ar_len_mux   = ARLEN_M0;
            ar_size_mux  = ARSIZE_M0;
            ar_burst_mux = ARBURST_M0;
            ar_valid_mux = ARVALID_M0;
        end else if (ar_grant_m1) begin
            // Grant to M1 (Data Read)
            ar_id_mux    = ARID_M1;
            ar_addr_mux  = ARADDR_M1;
            ar_len_mux   = ARLEN_M1;
            ar_size_mux  = ARSIZE_M1;
            ar_burst_mux = ARBURST_M1;
            ar_valid_mux = ARVALID_M1;
        end else begin
            // No Request
            ar_id_mux    = {`AXI_ID_BITS{1'b0}};
            ar_addr_mux  = {`AXI_ADDR_BITS{1'b0}};
            ar_len_mux   = {`AXI_LEN_BITS{1'b0}};
            ar_size_mux  = {`AXI_SIZE_BITS{1'b0}};
            ar_burst_mux = 2'b0;
            ar_valid_mux = 1'b0;
        end
    end

    // --- Address Decoding ---
    logic ar_valid_s0, ar_valid_s1, ar_valid_sd;
    
    // Decodes the winner's address to find which slave is targeted
    AXI_Address_Decoder i_AR_Decoder (
        .addr(ar_addr_mux),
        .valid_s1(ar_valid_s0), // Slave 1 (IM)
        .valid_s2(ar_valid_s1), // Slave 2 (DM)
        .valid_sd(ar_valid_sd)  // Default Slave
    );

    // --- De-Multiplexer (Interconnect -> Slaves) ---
    // Broadcast Address/Control signals to all slaves
    assign ARID_S0 = ar_id_mux;
    assign ARADDR_S0 = ar_addr_mux;
    assign ARLEN_S0 = ar_len_mux;
    assign ARSIZE_S0 = ar_size_mux;
    assign ARBURST_S0 = ar_burst_mux;
    // Only enable VALID for the selected slave
    assign ARVALID_S0 = ar_valid_mux & ar_valid_s0;

    assign ARID_S1 = ar_id_mux;
    assign ARADDR_S1 = ar_addr_mux;
    assign ARLEN_S1 = ar_len_mux;
    assign ARSIZE_S1 = ar_size_mux;
    assign ARBURST_S1 = ar_burst_mux;
    assign ARVALID_S1 = ar_valid_mux & ar_valid_s1;

    assign ARID_SD = ar_id_mux;
    assign ARADDR_SD = ar_addr_mux;
    assign ARLEN_SD = ar_len_mux;
    assign ARSIZE_SD = ar_size_mux;
    assign ARBURST_SD = ar_burst_mux;
    assign ARVALID_SD = ar_valid_mux & ar_valid_sd;

    // --- Ready Signal Return ---
    // Route the READY signal from the selected slave back to the granted master
    logic ar_ready_mux;
    assign ar_ready_mux = (ar_valid_s0 & ARREADY_S0) | 
                          (ar_valid_s1 & ARREADY_S1) | 
                          (ar_valid_sd & ARREADY_SD);
                          
    assign ARREADY_M0 = ar_grant_m0 & ar_ready_mux;
    assign ARREADY_M1 = ar_grant_m1 & ar_ready_mux;
    
    // Handshake occurs when both VALID and READY are high
    assign ar_handshake = ar_valid_mux & ar_ready_mux;


    // =========================================================================
    // 2. Read Data Channel (R)
    // =========================================================================
    logic [`AXI_IDS_BITS-1:0] r_id_sel;
    logic [`AXI_DATA_BITS-1:0] r_data_sel;
    logic [1:0] r_resp_sel;
    logic r_last_sel;
    logic r_valid_sel;

    // --- Multiplexer (Slaves -> Interconnect) ---
    // Select data from the slave asserting RVALID
    always_comb begin
        if (RVALID_S0) begin
            r_id_sel    = RID_S0;
            r_data_sel  = RDATA_S0;
            r_resp_sel  = RRESP_S0;
            r_last_sel  = RLAST_S0;
            r_valid_sel = RVALID_S0;
        end else if (RVALID_S1) begin
            r_id_sel    = RID_S1;
            r_data_sel  = RDATA_S1;
            r_resp_sel  = RRESP_S1;
            r_last_sel  = RLAST_S1;
            r_valid_sel = RVALID_S1;
        end else if (RVALID_SD) begin
            r_id_sel    = RID_SD;
            r_data_sel  = RDATA_SD;
            r_resp_sel  = RRESP_SD;
            r_last_sel  = RLAST_SD;
            r_valid_sel = RVALID_SD;
        end else begin
            r_id_sel    = {`AXI_IDS_BITS{1'b0}};
            r_data_sel  = {`AXI_DATA_BITS{1'b0}};
            r_resp_sel  = 2'b0;
            r_last_sel  = 1'b0;
            r_valid_sel = 1'b0;
        end
    end

    // --- De-Multiplexer (Interconnect -> Masters) ---
    // Route data based on Transaction ID (RID)
    // ID 0 -> Master 0, ID 1 -> Master 1
    assign RID_M0 = r_id_sel[`AXI_ID_BITS-1:0];
    assign RDATA_M0 = r_data_sel;
    assign RRESP_M0 = r_resp_sel;
    assign RLAST_M0 = r_last_sel;
    assign RVALID_M0 = r_valid_sel && (r_id_sel[`AXI_ID_BITS-1:0] == 4'd0);

    assign RID_M1 = r_id_sel[`AXI_ID_BITS-1:0];
    assign RDATA_M1 = r_data_sel;
    assign RRESP_M1 = r_resp_sel;
    assign RLAST_M1 = r_last_sel;
    assign RVALID_M1 = r_valid_sel && (r_id_sel[`AXI_ID_BITS-1:0] == 4'd1);

    // --- Ready Signal Routing ---
    // Route RREADY from the correct Master to all Slaves
    assign RREADY_S0 = (r_id_sel[`AXI_ID_BITS-1:0] == 4'd0) ? RREADY_M0 : 
                       (r_id_sel[`AXI_ID_BITS-1:0] == 4'd1) ? RREADY_M1 : 1'b1;
    assign RREADY_S1 = RREADY_S0;
    assign RREADY_SD = RREADY_S0;


    // =========================================================================
    // 3. Write Address Channel (AW)
    // =========================================================================
    logic aw_grant_m0, aw_grant_m1;
    logic aw_handshake;
    logic [`AXI_ADDR_BITS-1:0] aw_addr_mux;
    logic [`AXI_ID_BITS-1:0] aw_id_mux;
    logic [`AXI_LEN_BITS-1:0] aw_len_mux;
    logic [`AXI_SIZE_BITS-1:0] aw_size_mux;
    logic [1:0] aw_burst_mux;
    logic aw_valid_mux;
    
    // --- Arbitration ---
    Arbiter i_AW_Arbiter (
        .clk(ACLK),
        .rst_n(ARESETn),
        .req_m0(AWVALID_M0_dummy), // M0 is dummy (Read-Only)
        .req_m1(AWVALID_M1),
        .handshake(aw_handshake),
        .grant_m0(aw_grant_m0),
        .grant_m1(aw_grant_m1)
    );

    // --- Multiplexer (Masters -> Interconnect) ---
    always_comb begin
        if (aw_grant_m0) begin
            aw_id_mux    = AWID_M0_dummy;
            aw_addr_mux  = 32'b0; 
            aw_len_mux   = 4'b0;
            aw_size_mux  = 3'b0;
            aw_burst_mux = 2'b0;
            aw_valid_mux = 1'b0;
        end else if (aw_grant_m1) begin
            aw_id_mux    = AWID_M1;
            aw_addr_mux  = AWADDR_M1;
            aw_len_mux   = AWLEN_M1;
            aw_size_mux  = AWSIZE_M1;
            aw_burst_mux = AWBURST_M1;
            aw_valid_mux = AWVALID_M1;
        end else begin
            aw_id_mux    = {`AXI_ID_BITS{1'b0}};
            aw_addr_mux  = {`AXI_ADDR_BITS{1'b0}};
            aw_len_mux   = {`AXI_LEN_BITS{1'b0}};
            aw_size_mux  = {`AXI_SIZE_BITS{1'b0}};
            aw_burst_mux = 2'b0;
            aw_valid_mux = 1'b0;
        end
    end

    // --- Address Decoding ---
    logic aw_valid_s0, aw_valid_s1, aw_valid_sd;
    
    AXI_Address_Decoder i_AW_Decoder (
        .addr(aw_addr_mux),
        .valid_s1(aw_valid_s0), 
        .valid_s2(aw_valid_s1), 
        .valid_sd(aw_valid_sd)
    );

    // --- De-Multiplexer (Interconnect -> Slaves) ---
    assign AWID_S0 = aw_id_mux;
    assign AWADDR_S0 = aw_addr_mux;
    assign AWLEN_S0 = aw_len_mux;
    assign AWSIZE_S0 = aw_size_mux;
    assign AWBURST_S0 = aw_burst_mux;
    assign AWVALID_S0 = aw_valid_mux & aw_valid_s0;

    assign AWID_S1 = aw_id_mux;
    assign AWADDR_S1 = aw_addr_mux;
    assign AWLEN_S1 = aw_len_mux;
    assign AWSIZE_S1 = aw_size_mux;
    assign AWBURST_S1 = aw_burst_mux;
    assign AWVALID_S1 = aw_valid_mux & aw_valid_s1;

    assign AWID_SD = aw_id_mux;
    assign AWADDR_SD = aw_addr_mux;
    assign AWLEN_SD = aw_len_mux;
    assign AWSIZE_SD = aw_size_mux;
    assign AWBURST_SD = aw_burst_mux;
    assign AWVALID_SD = aw_valid_mux & aw_valid_sd;

    // --- Ready Signal Return ---
    logic aw_ready_mux;
    assign aw_ready_mux = (aw_valid_s0 & AWREADY_S0) | 
                          (aw_valid_s1 & AWREADY_S1) | 
                          (aw_valid_sd & AWREADY_SD);

    assign AWREADY_M1 = aw_grant_m1 & aw_ready_mux;
    assign aw_handshake = aw_valid_mux & aw_ready_mux;


    // =========================================================================
    // 4. Write Data Channel (W)
    // =========================================================================
    // This channel must "remember" which slave was selected in the AW phase.
    
    logic [1:0] reg_w_slave; // 1:S0, 2:S1, 3:Default

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            reg_w_slave <= 2'b0;
        end else if (aw_handshake) begin
            // Lock the slave selection when Address Handshake occurs
            if (aw_valid_s0) reg_w_slave <= 2'b01;
            else if (aw_valid_s1) reg_w_slave <= 2'b10;
            else if (aw_valid_sd) reg_w_slave <= 2'b11;
        end else if (WVALID_M1 && WREADY_M1 && WLAST_M1) begin
            // Unlock after the last data beat
            reg_w_slave <= 2'b0; 
        end
    end

    // --- Data Routing ---
    // Broadcast data, but valid is gated by reg_w_slave
    assign WDATA_S0 = WDATA_M1;
    assign WSTRB_S0 = WSTRB_M1;
    assign WLAST_S0 = WLAST_M1;
    assign WVALID_S0 = WVALID_M1 & (reg_w_slave == 2'b01);

    assign WDATA_S1 = WDATA_M1;
    assign WSTRB_S1 = WSTRB_M1;
    assign WLAST_S1 = WLAST_M1;
    assign WVALID_S1 = WVALID_M1 & (reg_w_slave == 2'b10);

    assign WDATA_SD = WDATA_M1;
    assign WSTRB_SD = WSTRB_M1;
    assign WLAST_SD = WLAST_M1;
    assign WVALID_SD = WVALID_M1 & (reg_w_slave == 2'b11);

    // --- Ready Signal Return ---
    logic w_ready_mux;
    assign w_ready_mux = (reg_w_slave == 2'b01) ? WREADY_S0 :
                         (reg_w_slave == 2'b10) ? WREADY_S1 :
                         (reg_w_slave == 2'b11) ? WREADY_SD : 1'b0;
    
    assign WREADY_M1 = w_ready_mux;


    // =========================================================================
    // 5. Write Response Channel (B)
    // =========================================================================
    logic [`AXI_IDS_BITS-1:0] b_id_sel;
    logic [1:0] b_resp_sel;
    logic b_valid_sel;

    // --- Multiplexer (Slaves -> Interconnect) ---
    always_comb begin
        if (BVALID_S0) begin
            b_id_sel    = BID_S0;
            b_resp_sel  = BRESP_S0;
            b_valid_sel = BVALID_S0;
        end else if (BVALID_S1) begin
            b_id_sel    = BID_S1;
            b_resp_sel  = BRESP_S1;
            b_valid_sel = BVALID_S1;
        end else if (BVALID_SD) begin
            b_id_sel    = BID_SD;
            b_resp_sel  = BRESP_SD;
            b_valid_sel = BVALID_SD;
        end else begin
            b_id_sel    = {`AXI_IDS_BITS{1'b0}};
            b_resp_sel  = 2'b0;
            b_valid_sel = 1'b0;
        end
    end

    // --- De-Multiplexer (Interconnect -> Masters) ---
    // Only M1 performs writes, so we route directly to M1
    assign BID_M1 = b_id_sel[`AXI_ID_BITS-1:0];
    assign BRESP_M1 = b_resp_sel;
    assign BVALID_M1 = b_valid_sel;
    
    // Broadcast M1's BREADY to all slaves (simple implementation)
    assign BREADY_S0 = BREADY_M1;
    assign BREADY_S1 = BREADY_M1;
    assign BREADY_SD = BREADY_M1;


    // =========================================================================
    // Sub-Module Instantiation
    // =========================================================================
    
    // Default Slave: Handles accesses to unmapped memory regions
    Default_Slave i_Default_Slave (
        .clk(ACLK),
        .rst_n(ARESETn),
        .ARID(ARID_SD), .ARADDR(ARADDR_SD), .ARLEN(ARLEN_SD), .ARSIZE(ARSIZE_SD), .ARBURST(ARBURST_SD),
        .ARVALID(ARVALID_SD), .ARREADY(ARREADY_SD),
        .RID(RID_SD), .RDATA(RDATA_SD), .RRESP(RRESP_SD), .RLAST(RLAST_SD), .RVALID(RVALID_SD), .RREADY(RREADY_SD),
        .AWID(AWID_SD), .AWADDR(AWADDR_SD), .AWLEN(AWLEN_SD), .AWSIZE(AWSIZE_SD), .AWBURST(AWBURST_SD),
        .AWVALID(AWVALID_SD), .AWREADY(AWREADY_SD),
        .WDATA(WDATA_SD), .WSTRB(WSTRB_SD), .WLAST(WLAST_SD), .WVALID(WVALID_SD), .WREADY(WREADY_SD),
        .BID(BID_SD), .BRESP(BRESP_SD), .BVALID(BVALID_SD), .BREADY(BREADY_SD)
    );

endmodule