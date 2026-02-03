////////
// ID_EX register
///////

module IDEX_reg #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter INST_COUNT = 37 //for RV32I
)(
    input  logic                   clk,
    input  logic                   resetn,
    input  logic                   i_branch_taken,

    input  logic [INST_WIDTH-1:0]  i_instruction,

    input  logic [DATA_WIDTH-1:0]  i_rs1_data,
    input  logic [DATA_WIDTH-1:0]  i_rs2_data,
    input  logic [DATA_WIDTH-1:0]  i_imm,
    input  logic [ADDR_WIDTH-1:0]  i_address,
    input  logic [6:0]             i_opcode,
    input  logic [2:0]             i_funct3,
    input  logic [6:0]             i_funct7,
    input  logic [4:0]             i_rd,
    input  logic [4:0]             i_rs1,
    input  logic [4:0]             i_rs2,

    input  logic                   i_ALUSrc,
    input  logic [$clog2(INST_COUNT)-1:0] i_ALUOp,
    input  logic                   i_MemRead,
    input  logic                   i_MemWrite,
    input  logic                   i_RegWrite,
    input  logic                   i_MemToReg,

    output logic [INST_WIDTH-1:0]  o_instruction,

    output logic [DATA_WIDTH-1:0]  o_rs1_data,
    output logic [DATA_WIDTH-1:0]  o_rs2_data,
    output logic [DATA_WIDTH-1:0]  o_imm,
    output logic [ADDR_WIDTH-1:0]  o_address,
    output logic [6:0]             o_opcode,
    output logic [2:0]             o_funct3,
    output logic [6:0]             o_funct7,
    output logic [4:0]             o_rd,
    output logic [4:0]             o_rs1,
    output logic [4:0]             o_rs2,

    output logic                   o_ALUSrc,
    output logic [$clog2(INST_COUNT)-1:0] o_ALUOp,
    output logic                   o_MemRead,
    output logic                   o_MemWrite,
    output logic                   o_RegWrite,
    output logic                   o_MemToReg
);

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            o_instruction <= 32'h00000013; // NOP
            o_rs1_data <= '0; o_rs2_data <= '0; o_imm <= '0; o_address <= '0;
            o_opcode <= '0; o_funct3 <= '0; o_funct7 <= '0;
            o_rd <= '0; o_rs1 <= '0; o_rs2 <= '0;
            
            o_ALUSrc <= '0; o_ALUOp <= '0;
            o_MemRead <= '0; o_MemWrite <= '0;
            o_RegWrite <= '0; o_MemToReg <= '0;
            
        end else if (i_branch_taken) begin
            o_instruction <= 32'h00000013; // NOP
            o_rs1_data <= '0; o_rs2_data <= '0; o_imm <= '0; o_address <= '0;
            o_opcode <= 7'b0010011; // NOP
            o_funct3 <= '0; o_funct7 <= '0;
            o_rd <= '0; o_rs1 <= '0; o_rs2 <= '0;
            
            o_ALUSrc <= '0; o_ALUOp <= '0;
            o_MemRead <= '0; o_MemWrite <= '0;
            o_RegWrite <= '0; o_MemToReg <= '0;
            
        end else begin
            o_instruction <= i_instruction;
            o_rs1_data <= i_rs1_data;
            o_rs2_data <= i_rs2_data;
            o_imm      <= i_imm;
            o_address  <= i_address;
            o_opcode   <= i_opcode;
            o_funct3   <= i_funct3;
            o_funct7   <= i_funct7;
            o_rd       <= i_rd;
            o_rs1      <= i_rs1;
            o_rs2      <= i_rs2;
            
            o_ALUSrc   <= i_ALUSrc;
            o_ALUOp    <= i_ALUOp;
            o_MemRead  <= i_MemRead;
            o_MemWrite <= i_MemWrite;
            o_RegWrite <= i_RegWrite;
            o_MemToReg <= i_MemToReg;
        end
    end

endmodule