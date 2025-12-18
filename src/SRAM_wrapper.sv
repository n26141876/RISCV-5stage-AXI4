module SRAM_wrapper (
    input logic ACLK,
    input logic ARESETn,

    // --- AXI Slave Interface ---
    // Read Address Channel
    input logic [3:0] ARID,
    input logic [31:0] ARADDR,
    input logic [3:0] ARLEN,
    input logic [2:0] ARSIZE,
    input logic [1:0] ARBURST,
    input logic ARVALID,
    output logic ARREADY,

    // Read Data Channel
    output logic [3:0] RID,
    output logic [31:0] RDATA,
    output logic [1:0] RRESP,
    output logic RLAST,
    output logic RVALID,
    input logic RREADY,

    // Write Address Channel
    input logic [3:0] AWID,
    input logic [31:0] AWADDR,
    input logic [3:0] AWLEN,
    input logic [2:0] AWSIZE,
    input logic [1:0] AWBURST,
    input logic AWVALID,
    output logic AWREADY,

    // Write Data Channel
    input logic [31:0] WDATA,
    input logic [3:0] WSTRB,
    input logic WLAST,
    input logic WVALID,
    output logic WREADY,

    // Write Response Channel
    output logic [3:0] BID,
    output logic [1:0] BRESP,
    output logic BVALID,
    input logic BREADY
);
    // --- SRAM Interface Logic ---
    logic CEB, WEB;
    logic [31:0] BWEB;
    logic [13:0] A;
    logic [31:0] DI;
    logic [31:0] DO;

    // Internal Registers for Burst Handling
    logic [3:0]  reg_bid, reg_rid;
    logic [31:0] reg_addr;
    logic [3:0]  reg_len;
    logic [3:0]  beat_cnt;

    // FSM States
    typedef enum logic [1:0] {
        IDLE,
        READ_BURST,
        WRITE_BURST,
        WRITE_RESP
    } state_t;
    state_t state, next_state;

    // --- State Machine ---
    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
            reg_len <= 0;
            reg_addr <= 0;
            reg_bid <= 0;
            reg_rid <= 0;
            beat_cnt <= 0;
        end else begin
            state <= next_state;
            
            // Latch control info on Handshake
            if (state == IDLE) begin
                if (AWVALID) begin // Priority to Write
                    reg_addr <= AWADDR;
                    reg_len  <= AWLEN;
                    reg_bid  <= AWID;
                    beat_cnt <= 0;
                end else if (ARVALID) begin
                    reg_addr <= ARADDR;
                    reg_len  <= ARLEN;
                    reg_rid  <= ARID;
                    beat_cnt <= 0;
                end
            end else if (state == READ_BURST) begin
                // Update Address only when Handshake occurs (RREADY is high)
                if (RVALID && RREADY) begin
                    reg_addr <= reg_addr + 4; // INCR
                    beat_cnt <= beat_cnt + 1;
                end
            end else if (state == WRITE_BURST) begin
                if (WVALID && WREADY) begin
                    reg_addr <= reg_addr + 4;
                    beat_cnt <= beat_cnt + 1;
                end
            end
        end
    end

    // --- Next State Logic ---
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (AWVALID) next_state = WRITE_BURST;
                else if (ARVALID) next_state = READ_BURST;
            end
            READ_BURST: begin
                if (RVALID && RREADY && (beat_cnt == reg_len)) 
                    next_state = IDLE;
            end
            WRITE_BURST: begin
                if (WVALID && WREADY && WLAST) 
                    next_state = WRITE_RESP;
            end
            WRITE_RESP: begin
                if (BVALID && BREADY) 
                    next_state = IDLE;
            end
        endcase
    end

    // --- AXI Output Logic ---
    assign AWREADY = (state == IDLE);
    assign ARREADY = (state == IDLE) && !AWVALID;

    assign WREADY = (state == WRITE_BURST);
    
    assign BID = reg_bid;
    assign BRESP = 2'b00; // OKAY
    assign BVALID = (state == WRITE_RESP);

    // Read Channel
    assign RID = reg_rid;
    assign RRESP = 2'b00; // OKAY
    assign RDATA = DO;
    assign RLAST = (state == READ_BURST) && (beat_cnt == reg_len);
    assign RVALID = (state == READ_BURST);

    // --- SRAM Control Logic (Critical Fix) ---
    assign CEB = !((state == IDLE && (ARVALID || AWVALID)) || 
                   (state == READ_BURST) ||  // Modified: removed "&& RREADY"
                   (state == WRITE_BURST));

    // Write Enable: Active Low. Only Low during Write Phase.
    assign WEB = !((state == IDLE && AWVALID) || (state == WRITE_BURST));

    // Address Mapping
    logic [31:0] current_addr;
    always_comb begin
        if (state == IDLE) begin
            if (AWVALID) current_addr = AWADDR;
            else if (ARVALID) current_addr = ARADDR;
            else current_addr = 32'b0;
        end else begin
            current_addr = reg_addr;
        end
    end
    assign A = current_addr[15:2];

    assign DI = WDATA;

    // Bit Write Enable
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : bweb_gen
            assign BWEB[8*i +: 8] = (WSTRB[i]) ? 8'h00 : 8'hFF;
        end
    endgenerate

    // --- SRAM Instance ---
    TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM (
        .CLK(ACLK),
        .CEB(CEB),
        .WEB(WEB),
        .A(A),
        .D(DI),
        .BWEB(BWEB),
        .Q(DO)
    );
endmodule