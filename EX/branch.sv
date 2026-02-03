////////
// Branch / jump decision unit
///////

module branch #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32, //for RV32I
    parameter DATA_WIDTH = 32,
    parameter INST_COUNT = 37  //for RV32I without ecall and ebreak
)(
    input  logic [ADDR_WIDTH-1:0]         i_address,   // usually PC

    input  logic [DATA_WIDTH-1:0]         i_rs1_data,
    input  logic [DATA_WIDTH-1:0]         i_rs2_data,
    input  logic [DATA_WIDTH-1:0]         i_imm,
    
    input  logic [$clog2(INST_COUNT)-1:0] i_ALUOp,
    input  logic                          i_invalid_instruction,

    output logic [ADDR_WIDTH-1:0]         o_branch_address,
    output logic                          o_branch_taken
);
    
    localparam W = $clog2(INST_COUNT);
    typedef logic [W-1:0] aluop_t;

    logic [ADDR_WIDTH-1:0] branch_address;
    logic                  branch_taken;

    logic [DATA_WIDTH-1:0] jalr_sum_full;

    assign o_branch_address = branch_address;
    assign o_branch_taken   = branch_taken;

    always_comb begin
        branch_address = i_address + $signed(i_imm[ADDR_WIDTH-1:0]);
        branch_taken   = 1'b0;
        jalr_sum_full  = '0;

        unique case (i_ALUOp)

            // ----------------------------------------
            // BEQ / BNE / BLT / BGE / BLTU / BGEU
            // ----------------------------------------
            aluop_t'(27): branch_taken = (i_rs1_data == i_rs2_data);                   // BEQ
            aluop_t'(28): branch_taken = (i_rs1_data != i_rs2_data);                   // BNE
            aluop_t'(29): branch_taken = ($signed(i_rs1_data) <  $signed(i_rs2_data)); // BLT
            aluop_t'(30): branch_taken = ($signed(i_rs1_data) >= $signed(i_rs2_data)); // BGE
            aluop_t'(31): branch_taken = (i_rs1_data <  i_rs2_data);                   // BLTU
            aluop_t'(32): branch_taken = (i_rs1_data >= i_rs2_data);                   // BGEU

            // JAL
            aluop_t'(33): begin
                branch_taken = 1'b1;
            end

            // JALR
            aluop_t'(34): begin
                jalr_sum_full = i_rs1_data + i_imm;
                branch_address = { jalr_sum_full[ADDR_WIDTH-1:1], 1'b0 };
                branch_taken   = 1'b1;
            end

            default: begin

            end

        endcase
    end

endmodule
