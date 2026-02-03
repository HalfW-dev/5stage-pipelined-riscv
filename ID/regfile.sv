// -------------------------------------------------------------
// RV32I Register File
// -------------------------------------------------------------
module regfile #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 32,
    parameter ADDR_WIDTH = $clog2(NUM_REGS)
)(
    input  logic                   clk,
    input  logic                   resetn,

    // Read port 1
    input  logic [ADDR_WIDTH-1:0]  i_rs1,
    output logic [DATA_WIDTH-1:0]  o_rs1_data,

    // Read port 2
    input  logic [ADDR_WIDTH-1:0]  i_rs2,
    output logic [DATA_WIDTH-1:0]  o_rs2_data,

    // Write port
    input  logic                   i_write_ena,
    input  logic [ADDR_WIDTH-1:0]  i_rd,
    input  logic [DATA_WIDTH-1:0]  i_rd_data
);

    logic [31:0] regs [0:31];

    initial begin
        $readmemh("B:/dev/project/riscv/ID/regfile_init.hex", regs);
        regs[0] = 32'b0;   // enforce x0 = 0 (RV32I rule)
    end


    // ---------------------------------------------------------
    // Synchronous write
    // ---------------------------------------------------------
    integer i;
    always_ff @(posedge clk) begin
            // Write-back stage: ignore writes to x0 (register 0)
            if (i_write_ena && (i_rd != '0)) begin
                regs[i_rd] <= i_rd_data;
            end else begin
                regs[0] <= '0;
            end
        end
    // end

    // ---------------------------------------------------------
    // Combinational reads with simple bypass for same-cycle W/R
    // ---------------------------------------------------------
    always_comb begin
        if (i_rs1 == '0) begin
            o_rs1_data = '0;
        end else if (i_write_ena && (i_rd == i_rs1)) begin
            o_rs1_data = i_rd_data;
        end else begin
            o_rs1_data = regs[i_rs1];
        end

        if (i_rs2 == '0) begin
            o_rs2_data = '0;
        end else if (i_write_ena && (i_rd == i_rs2)) begin
            o_rs2_data = i_rd_data;
        end else begin
            o_rs2_data = regs[i_rs2];
        end
    end

endmodule
