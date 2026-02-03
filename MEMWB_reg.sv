////////
// MEM/WB register
///////

module MEMWB_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32
)(
    input logic clk,
    input logic resetn,

    // NEW: RVFI Pipeline Inputs
    input logic [ADDR_WIDTH-1:0] i_pc,
    input logic [INST_WIDTH-1:0] i_instruction,
    input logic [ADDR_WIDTH-1:0] i_next_pc,
    input logic [DATA_WIDTH-1:0] i_rs1_data_rvfi,
    input logic [DATA_WIDTH-1:0] i_rs2_data_rvfi,
    input logic [DATA_WIDTH-1:0] i_mem_addr,
    input logic [DATA_WIDTH-1:0] i_mem_wdata,

    input logic [DATA_WIDTH-1:0] i_dmem_data,   
    input logic [DATA_WIDTH-1:0] i_rd_data,     
    input logic [4:0]            i_rd,          
    input logic [4:0]            i_rs1,
    input logic [4:0]            i_rs2,

    input logic                  i_RegWrite,    
    input logic                  i_MemToReg,    

    output logic [ADDR_WIDTH-1:0] o_pc,
    output logic [INST_WIDTH-1:0] o_instruction,
    output logic [ADDR_WIDTH-1:0] o_next_pc,
    output logic [DATA_WIDTH-1:0] o_rs1_data_rvfi,
    output logic [DATA_WIDTH-1:0] o_rs2_data_rvfi,
    output logic [DATA_WIDTH-1:0] o_mem_addr,
    
    output logic [DATA_WIDTH-1:0] o_dmem_data,
    output logic [DATA_WIDTH-1:0] o_rd_data,
    output logic [4:0]            o_rd,
    output logic [4:0]            o_rs1,
    output logic [4:0]            o_rs2,
    
    output logic                  o_RegWrite,
    output logic                  o_MemToReg
);

    always_ff @(posedge clk or negedge resetn) begin : propagate
        if (!resetn) begin
            o_pc            <= '0;
            o_instruction   <= 32'h00000013; // NOP
            o_next_pc       <= '0;
            o_rs1_data_rvfi <= '0;
            o_rs2_data_rvfi <= '0;
            o_mem_addr      <= '0;

            o_dmem_data     <= '0;
            o_rd_data       <= '0;
            o_rd            <= '0;
            o_rs1           <= '0;
            o_rs2           <= '0;
            o_RegWrite      <= '0;
            o_MemToReg      <= '0;
        end else begin
            o_pc            <= i_pc;
            o_instruction   <= i_instruction;
            o_next_pc       <= i_next_pc;
            o_rs1_data_rvfi <= i_rs1_data_rvfi;
            o_rs2_data_rvfi <= i_rs2_data_rvfi;
            o_mem_addr      <= i_mem_addr;

            o_dmem_data     <= i_dmem_data;
            o_rd_data       <= i_rd_data;
            o_rd            <= i_rd;
            o_rs1           <= i_rs1;
            o_rs2           <= i_rs2;
            o_RegWrite      <= i_RegWrite;
            o_MemToReg      <= i_MemToReg;
        end
    end

endmodule