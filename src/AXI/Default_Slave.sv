module Default_Slave (
    input logic clk,
    input logic rst_n,

    // AR Channel
    input logic [3:0] ARID,
    input logic [31:0] ARADDR,
    input logic [3:0] ARLEN,
    input logic [2:0] ARSIZE,
    input logic [1:0] ARBURST,
    input logic ARVALID,
    output logic ARREADY,

    // R Channel
    output logic [3:0] RID,
    output logic [31:0] RDATA,
    output logic [1:0] RRESP,
    output logic RLAST,
    output logic RVALID,
    input logic RREADY,

    // AW Channel
    input logic [3:0] AWID,
    input logic [31:0] AWADDR,
    input logic [3:0] AWLEN,
    input logic [2:0] AWSIZE,
    input logic [1:0] AWBURST,
    input logic AWVALID,
    output logic AWREADY,

    // W Channel
    input logic [31:0] WDATA,
    input logic [3:0] WSTRB,
    input logic WLAST,
    input logic WVALID,
    output logic WREADY,

    // B Channel
    output logic [3:0] BID,
    output logic [1:0] BRESP,
    output logic BVALID,
    input logic BREADY
);

    // --- State Machine to handle Responses ---
    // We need to handshake Address first, then Data/Response.
    
    // Read Logic
    logic ar_handshake;
    logic [3:0] saved_arid;
    logic [3:0] read_len;
    logic [3:0] read_cnt;
    logic reading;

    assign ar_handshake = ARVALID && ARREADY;
    assign ARREADY = !reading; // Accept address if not currently sending responses

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reading <= 1'b0;
            saved_arid <= 4'b0;
            read_len <= 4'b0;
            read_cnt <= 4'b0;
        end else if (ar_handshake) begin
            reading <= 1'b1;
            saved_arid <= ARID;
            read_len <= ARLEN;
            read_cnt <= 4'b0;
        end else if (reading && RREADY) begin
            if (read_cnt == read_len) reading <= 1'b0;
            else read_cnt <= read_cnt + 1;
        end
    end

    assign RID = saved_arid;
    assign RDATA = 32'b0;
    assign RRESP = 2'b11; // DECERR
    assign RLAST = (read_cnt == read_len);
    assign RVALID = reading;


    // Write Logic
    // Need to consume AW and W, then send B.
    logic aw_done, w_done;
    logic [3:0] saved_bid;
    logic b_valid_reg;

    assign AWREADY = !aw_done && !b_valid_reg;
    assign WREADY  = !w_done && !b_valid_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_done <= 1'b0;
            w_done <= 1'b0;
            b_valid_reg <= 1'b0;
            saved_bid <= 4'b0;
        end else begin
            // Address Handshake
            if (AWVALID && AWREADY) begin
                aw_done <= 1'b1;
                saved_bid <= AWID;
            end
            
            // Data Handshake (Wait for WLAST)
            if (WVALID && WREADY && WLAST) begin
                w_done <= 1'b1;
            end

            // Response Handshake
            if (aw_done && w_done) begin
                b_valid_reg <= 1'b1;
                aw_done <= 1'b0; // Reset for next
                w_done <= 1'b0;
            end else if (b_valid_reg && BREADY) begin
                b_valid_reg <= 1'b0;
            end
        end
    end

    assign BID = saved_bid;
    assign BRESP = 2'b11; // DECERR
    assign BVALID = b_valid_reg;

endmodule