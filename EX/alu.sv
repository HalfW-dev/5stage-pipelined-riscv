////////
// Main execution unit - ALU
///////

module alu #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32, //for RV32I
    parameter DATA_WIDTH = 32,
    parameter INST_COUNT = 37  //for RV32I without ecall and ebreak
)(
    input  logic [DATA_WIDTH-1:0]         i_rs1_data,
    input  logic [DATA_WIDTH-1:0]         i_rs2_data,
    input  logic [ADDR_WIDTH-1:0]         i_address,

    input  logic [$clog2(INST_COUNT)-1:0] i_ALUOp,
    input  logic                          i_invalid_instruction, // unused for now

    output logic [DATA_WIDTH-1:0]         o_rd_data
);

localparam W = $clog2(INST_COUNT);
typedef logic [W-1:0] aluop_t;

logic [DATA_WIDTH-1:0] rd_data;
assign o_rd_data = rd_data;

always_comb begin
    unique case (i_ALUOp)

        // ADD / ADDI / address calc for loads & stores
        aluop_t'(0),
        aluop_t'(10),
        aluop_t'(19),
        aluop_t'(20),
        aluop_t'(21),
        aluop_t'(22),
        aluop_t'(23),
        aluop_t'(24),
        aluop_t'(25),
        aluop_t'(26): rd_data = i_rs1_data + i_rs2_data;

        // SUB
        aluop_t'(1): rd_data = i_rs1_data - i_rs2_data;

        // XOR / XORI
        aluop_t'(2),
        aluop_t'(11): rd_data = i_rs1_data ^ i_rs2_data;

        // OR / ORI
        aluop_t'(3),
        aluop_t'(12): rd_data = i_rs1_data | i_rs2_data;

        // AND / ANDI
        aluop_t'(4),
        aluop_t'(13): rd_data = i_rs1_data & i_rs2_data;

        // SLL / SLLI
        aluop_t'(5),
        aluop_t'(14): rd_data = i_rs1_data << i_rs2_data[4:0];

        // SRL / SRLI
        aluop_t'(6),
        aluop_t'(15): rd_data = i_rs1_data >> i_rs2_data[4:0];

        // SRA / SRAI
        aluop_t'(7),
        aluop_t'(16): rd_data = $signed(i_rs1_data) >>> i_rs2_data[4:0];

        // SLT / SLTI (signed)
        aluop_t'(8),
        aluop_t'(17): rd_data =
            ($signed(i_rs1_data) < $signed(i_rs2_data)) ? 32'd1 : 32'd0;

        // SLTU / SLTIU (unsigned)
        aluop_t'(9),
        aluop_t'(18): rd_data =
            (i_rs1_data < i_rs2_data) ? 32'd1 : 32'd0;

        // JAL / JALR
        aluop_t'(33),
        aluop_t'(34): rd_data = i_address + 32'd4;

        // LUI
        aluop_t'(35): rd_data = i_rs2_data;

        // AUIPC
        aluop_t'(36): rd_data = i_address + i_rs2_data;

        default: rd_data = 32'hDEAD_BEEF;
    endcase
end

endmodule
