module apb_top (
    input        clk,
    input        rst_n,
    input        transfer,
    input        read_write,
    input  [7:0] apb_write_data,
    input  [8:0] apb_write_addr,
    input  [8:0] apb_read_addr,
    output [7:0] apb_read_data_out
);

    /* Internal wires */
    wire        penable;
    wire        pwrite;
    wire        psel1, psel2;
    wire [8:0]  paddr;
    wire [7:0]  pwdata;

    wire [7:0]  prdata;
    wire [7:0]  prdata1, prdata2;
    wire        pready;
    wire        pready1, pready2;

    /* ---------------------------
       Slave response MUX
       --------------------------- */

    // Select PREADY based on address
    assign pready = (paddr[8] == 1'b0) ? pready1 : pready2;

    // Select PRDATA only during READ
    assign prdata = read_write ?
                    ((paddr[8] == 1'b0) ? prdata1 : prdata2)
                    : 8'b0;

    /* ---------------------------
       APB MASTER
       --------------------------- */
    apb_protocol u_master (
        .clk(clk),
        .rst_n(rst_n),
        .pready(pready),
        .transfer(transfer),
        .read_write(read_write),
        .apb_write_data(apb_write_data),
        .prdata(prdata),
        .apb_read_addr(apb_read_addr),
        .apb_write_addr(apb_write_addr),
        .sel1(psel1),
        .sel2(psel2),
        .pwrite(pwrite),
        .penable(penable),
        .pwdata(pwdata),
        .apb_read_data_out(apb_read_data_out),
        .paddr(paddr)
    );

    /* ---------------------------
       APB SLAVE 1
       --------------------------- */
    apb_slave_1 u_slave1 (
        .clk(clk),
        .rst_n(rst_n),
        .penable(penable),
        .psel(psel1),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata1(prdata1),
        .pready1(pready1)
    );

    /* ---------------------------
       APB SLAVE 2
       --------------------------- */
    apb_slave_2 u_slave2 (
        .clk(clk),
        .rst_n(rst_n),
        .penable(penable),
        .psel(psel2),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),
        .prdata2(prdata2),
        .pready2(pready2)
    );

endmodule
