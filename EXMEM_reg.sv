////////
// EX/MEM register
///////

module EXMEM_reg #(
    parameter ADDR_WIDTH = 32,
    parameter INST_COUNT = 37, //for RV32I
    parameter DATA_WIDTH = 32,
    parameter INST_WIDTH = 32
)(
    input  logic                   clk,
    input  logic                   resetn,

    input  logic [ADDR_WIDTH-1:0]  i_pc,
    input  logic [INST_WIDTH-1:0]  i_instruction,
    input  logic [ADDR_WIDTH-1:0]  i_next_pc,
    input  logic [DATA_WIDTH-1:0]  i_rs1_data_rvfi,
    input  logic [DATA_WIDTH-1:0]  i_rs2_data_rvfi,

    input  logic [DATA_WIDTH-1:0]  i_rs1_data,
    input  logic [DATA_WIDTH-1:0]  i_rs2_data,
    input  logic [DATA_WIDTH-1:0]  i_rd_data,
    input  logic [4:0]             i_rd,
    input  logic [4:0]             i_rs1,
    input  logic [4:0]             i_rs2,
    input  logic [$clog2(INST_COUNT)-1:0] i_ALUOp,
    input  logic                   i_MemRead,
    input  logic                   i_MemWrite,
    input  logic                   i_RegWrite,
    input  logic                   i_MemToReg,

    output logic [ADDR_WIDTH-1:0]  o_pc,
    output logic [INST_WIDTH-1:0]  o_instruction,
    output logic [ADDR_WIDTH-1:0]  o_next_pc,
    output logic [DATA_WIDTH-1:0]  o_rs1_data_rvfi,
    output logic [DATA_WIDTH-1:0]  o_rs2_data_rvfi,

    output logic [DATA_WIDTH-1:0]  o_rs1_data,
    output logic [DATA_WIDTH-1:0]  o_rs2_data,
    output logic [DATA_WIDTH-1:0]  o_rd_data,
    output logic [4:0]             o_rd,
    output logic [4:0]             o_rs1,
    output logic [4:0]             o_rs2,
    output logic [$clog2(INST_COUNT)-1:0] o_ALUOp,
    output logic                   o_MemRead,
    output logic                   o_MemWrite,
    output logic                   o_RegWrite,
    output logic                   o_MemToReg
);

    always_ff @(posedge clk or negedge resetn) begin
        if(!resetn) begin
            o_pc            <= '0;
            o_instruction   <= 32'h00000013;
            o_next_pc       <= '0;
            o_rs1_data_rvfi <= '0;
            o_rs2_data_rvfi <= '0;

            o_rs1_data      <= '0;
            o_rs2_data      <= '0;
            o_rd_data       <= '0;
            o_rd            <= '0;
            o_rs1           <= '0;
            o_rs2           <= '0;
            
            o_ALUOp         <= '0;
            o_MemRead       <= '0;
            o_MemWrite      <= '0;
            o_RegWrite      <= '0;
            o_MemToReg      <= '0;
        end else begin
            o_pc            <= i_pc;
            o_instruction   <= i_instruction;
            o_next_pc       <= i_next_pc;
            o_rs1_data_rvfi <= i_rs1_data_rvfi;
            o_rs2_data_rvfi <= i_rs2_data_rvfi;

            o_rs1_data      <= i_rs1_data;
            o_rs2_data      <= i_rs2_data;
            o_rd_data       <= i_rd_data;
            o_rd            <= i_rd;
            o_rs1           <= i_rs1;
            o_rs2           <= i_rs2;
            
            o_ALUOp         <= i_ALUOp;
            o_MemRead       <= i_MemRead;
            o_MemWrite      <= i_MemWrite;
            o_RegWrite      <= i_RegWrite;
            o_MemToReg      <= i_MemToReg;
        end
    end

endmodule