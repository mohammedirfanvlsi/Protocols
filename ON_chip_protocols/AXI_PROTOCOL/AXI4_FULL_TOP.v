// ============================================================================
    // Module Name: axi_top
    // Description: Top-level integration module for the AXI4-Full System.
    //              Instantiates 'axi_master' and 'axi_slave'.
    //              Wires all 5 AXI channels (AW, W, B, AR, R) directly together.
    //              Exposes User Control ports for the Testbench / Application layer.
    // ============================================================================

    module axi_top #(
        parameter DATA_WIDTH = 32,          // 32-bit data bus (4 bytes per word)
        parameter ADDR_WIDTH = 32,          // 32-bit address bus
        parameter ID_WIDTH   = 4,           // 4-bit Transaction ID tags
        parameter MEM_DEPTH  = 256          // Internal RAM size in the slave (256 words)
    )(
        // ========================================================================
        // 1. GLOBAL SIGNALS
        // ========================================================================
        input  wire                   aclk,          // Global Clock signal
        input  wire                   aresetn,       // Global Reset signal (Active-LOW)

        // ========================================================================
        // 2. USER WRITE INTERFACE (Commands sent from Testbench into Master)
        // ========================================================================
        input  wire                   init_write,    // Pulse HIGH for 1 cycle to launch Write burst
        input  wire [ADDR_WIDTH-1:0]  wr_addr,       // Target memory start address
        input  wire [7:0]             wr_len,        // Burst length (e.g., 3 means 4 beats)
        input  wire [DATA_WIDTH-1:0]  wr_data_in,    // Real 32-bit data word provided by User
        output wire                   wr_data_req,   // Pulses HIGH to ask User: "Give me next word!"
        output wire                   wr_done,       // Pulses HIGH when write burst successfully finishes

        // ========================================================================
        // 3. USER READ INTERFACE (Commands and data returning from Master to User)
        // ========================================================================
        input  wire                   init_read,     // Pulse HIGH for 1 cycle to launch Read burst
        input  wire [ADDR_WIDTH-1:0]  rd_addr,       // Target memory start address
        input  wire [7:0]             rd_len,        // Burst length of read request
        output wire [DATA_WIDTH-1:0]  rd_data_out,   // Real 32-bit data word read from memory
        output wire                   rd_data_valid, // Pulses HIGH whenever a read word is valid
        output wire                   rd_done        // Pulses HIGH when read burst successfully finishes
    );

        // ========================================================================
        // INTERNAL AXI WIRES (The copper traces connecting Master to Slave)
        // ========================================================================

        // --- Channel 1: Write Address Channel (AW) Wires ---
        wire [ID_WIDTH-1:0]   axi_awid;     // Carries Write ID tag from Master to Slave
        wire [ADDR_WIDTH-1:0] axi_awaddr;   // Carries Write Address from Master to Slave
        wire [7:0]            axi_awlen;    // Carries Burst Length from Master to Slave
        wire [2:0]            axi_awsize;   // Carries Burst Size (4 bytes) from Master to Slave
        wire [1:0]            axi_awburst;  // Carries Burst Type (INCR) from Master to Slave
        wire                  axi_awvalid;  // Master asserts HIGH when address is valid
        wire                  axi_awready;  // Slave asserts HIGH when address is captured

        // --- Channel 2: Write Data Channel (W) Wires ---
        wire [DATA_WIDTH-1:0] axi_wdata;    // Carries 32-bit Write Data from Master to Slave
        wire [(DATA_WIDTH/8)-1:0] axi_wstrb;// Carries Byte Enables (4'b1111) from Master to Slave
        wire                  axi_wlast;    // Master asserts HIGH on the final beat of burst
        wire                  axi_wvalid;   // Master asserts HIGH when write data is valid
        wire                  axi_wready;   // Slave asserts HIGH when write data is captured

        // --- Channel 3: Write Response Channel (B) Wires ---
        wire [ID_WIDTH-1:0]   axi_bid;      // Carries Response ID from Slave back to Master
        wire [1:0]            axi_bresp;    // Carries Write Status (2'b00 = OKAY) to Master
        wire                  axi_bvalid;   // Slave asserts HIGH when receipt is ready
        wire                  axi_bready;   // Master asserts HIGH to acknowledge receipt

        // --- Channel 4: Read Address Channel (AR) Wires ---
        wire [ID_WIDTH-1:0]   axi_arid;     // Carries Read ID tag from Master to Slave
        wire [ADDR_WIDTH-1:0] axi_araddr;   // Carries Read Address from Master to Slave
        wire [7:0]            axi_arlen;    // Carries Read Burst Length from Master to Slave
        wire [2:0]            axi_arsize;   // Carries Read Burst Size (4 bytes) from Master to Slave
        wire [1:0]            axi_arburst;  // Carries Read Burst Type (INCR) from Master to Slave
        wire                  axi_arvalid;  // Master asserts HIGH when read address is valid
        wire                  axi_arready;  // Slave asserts HIGH when read address is captured

        // --- Channel 5: Read Data Channel (R) Wires ---
        wire [ID_WIDTH-1:0]   axi_rid;      // Carries Read Data ID tag from Slave back to Master
        wire [DATA_WIDTH-1:0] axi_rdata;    // Carries 32-bit Read Data from Slave back to Master
        wire [1:0]            axi_rresp;    // Carries Read Status (2'b00 = OKAY) to Master
        wire                  axi_rlast;    // Slave asserts HIGH on the final beat of read burst
        wire                  axi_rvalid;   // Slave asserts HIGH when read data is valid
        wire                  axi_rready;   // Master asserts HIGH to acknowledge read data


        // ========================================================================
        // 4. INSTANTIATION 1: AXI4-FULL MASTER
        // ========================================================================
        axi_master #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .ID_WIDTH(ID_WIDTH)
        ) u_axi_master (
            // Global Connections
            .aclk          (aclk),
            .aresetn       (aresetn),

            // User Interface Connections
            .init_write    (init_write),
            .wr_addr       (wr_addr),
            .wr_len        (wr_len),
            .wr_data_in    (wr_data_in),
            .wr_data_req   (wr_data_req),
            .wr_done       (wr_done),

            .init_read     (init_read),
            .rd_addr       (rd_addr),
            .rd_len        (rd_len),
            .rd_data_out   (rd_data_out),
            .rd_data_valid (rd_data_valid),
            .rd_done       (rd_done),

            // AXI4 Write Address Channel (AW) -> Connected to internal wires
            .m_axi_awid    (axi_awid),
            .m_axi_awaddr  (axi_awaddr),
            .m_axi_awlen   (axi_awlen),
            .m_axi_awsize  (axi_awsize),
            .m_axi_awburst (axi_awburst),
            .m_axi_awvalid (axi_awvalid),
            .m_axi_awready (axi_awready),

            // AXI4 Write Data Channel (W) -> Connected to internal wires
            .m_axi_wdata   (axi_wdata),
            .m_axi_wstrb   (axi_wstrb),
            .m_axi_wlast   (axi_wlast),
            .m_axi_wvalid  (axi_wvalid),
            .m_axi_wready  (axi_wready),

            // AXI4 Write Response Channel (B) -> Connected to internal wires
            .m_axi_bid     (axi_bid),
            .m_axi_bresp   (axi_bresp),
            .m_axi_bvalid  (axi_bvalid),
            .m_axi_bready  (axi_bready),

            // AXI4 Read Address Channel (AR) -> Connected to internal wires
            .m_axi_arid    (axi_arid),
            .m_axi_araddr  (axi_araddr),
            .m_axi_arlen   (axi_arlen),
            .m_axi_arsize  (axi_arsize),
            .m_axi_arburst (axi_arburst),
            .m_axi_arvalid (axi_arvalid),
            .m_axi_arready (axi_arready),

            // AXI4 Read Data Channel (R) -> Connected to internal wires
            .m_axi_rid     (axi_rid),
            .m_axi_rdata   (axi_rdata),
            .m_axi_rresp   (axi_rresp),
            .m_axi_rlast   (axi_rlast),
            .m_axi_rvalid  (axi_rvalid),
            .m_axi_rready  (axi_rready)
        );


        // ========================================================================
        // 5. INSTANTIATION 2: AXI4-FULL SLAVE (Memory Model)
        // ========================================================================
        axi_slave #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .ID_WIDTH(ID_WIDTH),
            .MEM_DEPTH(MEM_DEPTH)
        ) u_axi_slave (
            // Global Connections
            .aclk          (aclk),
            .aresetn       (aresetn),

            // AXI4 Write Address Channel (AW) -> Connected to the EXACT SAME wires!
            .s_axi_awid    (axi_awid),
            .s_axi_awaddr  (axi_awaddr),
            .s_axi_awlen   (axi_awlen),
            .s_axi_awsize  (axi_awsize),
            .s_axi_awburst (axi_awburst),
            .s_axi_awvalid (axi_awvalid),
            .s_axi_awready (axi_awready),

            // AXI4 Write Data Channel (W) -> Connected to the EXACT SAME wires!
            .s_axi_wdata   (axi_wdata),
            .s_axi_wstrb   (axi_wstrb),
            .s_axi_wlast   (axi_wlast),
            .s_axi_wvalid  (axi_wvalid),
            .s_axi_wready  (axi_wready),

            // AXI4 Write Response Channel (B) -> Connected to the EXACT SAME wires!
            .s_axi_bid     (axi_bid),
            .s_axi_bresp   (axi_bresp),
            .s_axi_bvalid  (axi_bvalid),
            .s_axi_bready  (axi_bready),

            // AXI4 Read Address Channel (AR) -> Connected to the EXACT SAME wires!
            .s_axi_arid    (axi_arid),
            .s_axi_araddr  (axi_araddr),
            .s_axi_arlen   (axi_arlen),
            .s_axi_arsize  (axi_arsize),
            .s_axi_arburst (axi_arburst),
            .s_axi_arvalid (axi_arvalid),
            .s_axi_arready (axi_arready),

            // AXI4 Read Data Channel (R) -> Connected to the EXACT SAME wires!
            .s_axi_rid     (axi_rid),
            .s_axi_rdata   (axi_rdata),
            .s_axi_rresp   (axi_rresp),
            .s_axi_rlast   (axi_rlast),
            .s_axi_rvalid  (axi_rvalid),
            .s_axi_rready  (axi_rready)
        );

    endmodule