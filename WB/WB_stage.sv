module WB_stage #(
    parameter DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] i_rd_data,
    input  logic [DATA_WIDTH-1:0] i_dmem_data,
    input  logic [4:0]            i_rd,
    
    input  logic                  i_MemToReg,
    input  logic                  i_RegWrite,

    output logic                  o_RegWrite,
    output logic [4:0]            o_rd,
    output logic [DATA_WIDTH-1:0] o_rf_write_data
);

    assign o_RegWrite = i_RegWrite;
    assign o_rd   = i_rd;

    assign o_rf_write_data = (i_MemToReg) ? i_dmem_data : i_rd_data;

endmodule