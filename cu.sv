////////
// Global control unit of the architecture
///////

module cu #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32, //for RV32I
    parameter DATA_WIDTH = 32,
    parameter INST_COUNT = 37  //for RV32I without ecall and ebreak
)(
    input  logic                         clk,
    input  logic                         resetn,

    // Decoded fields from ID
    input  logic [6:0]                   i_opcode,
    input  logic [2:0]                   i_funct3,
    input  logic [6:0]                   i_funct7,

    output logic                         o_ALUSrc,
    output logic [$clog2(INST_COUNT)-1:0] o_ALUOp,
    output logic                         o_MemWrite,
    output logic                         o_MemRead,
    output logic                         o_RegWrite,
    output logic                         o_MemToReg,
    output logic                         o_invalid_instruction
);

localparam W = $clog2(INST_COUNT);
typedef logic [W-1:0] aluop_t;

// decode outputs
aluop_t ALU_op;
logic   ALU_src;
logic   invalid_instruction;
logic   MemWrite;
logic   MemRead;
logic   RegWrite;
logic   MemToReg;

assign o_ALUOp               = ALU_op;
assign o_ALUSrc              = ALU_src;
assign o_invalid_instruction = invalid_instruction;
assign o_MemWrite            = MemWrite;
assign o_MemRead             = MemRead;
assign o_RegWrite            = RegWrite;
assign o_MemToReg            = MemToReg;


always_comb begin : decode_ctrl

    invalid_instruction = 1'b0;
    ALU_op              = aluop_t'(0);
    ALU_src             = 1'b0;
    MemWrite            = 1'b0;
    MemRead             = 1'b0;
    RegWrite            = 1'b1;
    MemToReg            = 1'b0;

    unique case (i_opcode)

        // ---------------- R-type (0110011) ----------------
        7'b0110011: begin
            ALU_src = 1'b0;  // rs2
            unique case (i_funct3)
                3'h0: begin
                    if      (i_funct7 == 7'h00) ALU_op = aluop_t'(0);  // ADD
                    else if (i_funct7 == 7'h20) ALU_op = aluop_t'(1);  // SUB
                    else                      invalid_instruction = 1'b1;
                end
                3'h4: if (i_funct7 == 7'h00) ALU_op = aluop_t'(2); else invalid_instruction = 1'b1; // XOR
                3'h6: if (i_funct7 == 7'h00) ALU_op = aluop_t'(3); else invalid_instruction = 1'b1; // OR
                3'h7: if (i_funct7 == 7'h00) ALU_op = aluop_t'(4); else invalid_instruction = 1'b1; // AND
                3'h1: if (i_funct7 == 7'h00) ALU_op = aluop_t'(5); else invalid_instruction = 1'b1; // SLL
                3'h5: begin
                    if      (i_funct7 == 7'h00) ALU_op = aluop_t'(6);  // SRL
                    else if (i_funct7 == 7'h20) ALU_op = aluop_t'(7);  // SRA
                    else                      invalid_instruction = 1'b1;
                end
                3'h2: if (i_funct7 == 7'h00) ALU_op = aluop_t'(8); else invalid_instruction = 1'b1; // SLT
                3'h3: if (i_funct7 == 7'h00) ALU_op = aluop_t'(9); else invalid_instruction = 1'b1; // SLTU
                default: invalid_instruction = 1'b1;
            endcase
        end

        // -------------- I-type arithmetic (0010011) --------------
        7'b0010011: begin
            ALU_src = 1'b1; // use immediate
            unique case (i_funct3)
                3'h0: ALU_op = aluop_t'(10); // ADDI
                3'h4: ALU_op = aluop_t'(11); // XORI
                3'h6: ALU_op = aluop_t'(12); // ORI
                3'h7: ALU_op = aluop_t'(13); // ANDI
                3'h1: begin
                    if (i_funct7 == 7'h00) ALU_op = aluop_t'(14); // SLLI
                    else                 invalid_instruction = 1'b1;
                end
                3'h5: begin
                    if      (i_funct7 == 7'h00) ALU_op = aluop_t'(15); // SRLI
                    else if (i_funct7 == 7'h20) ALU_op = aluop_t'(16); // SRAI
                    else                      invalid_instruction = 1'b1;
                end
                3'h2: ALU_op = aluop_t'(17); // SLTI
                3'h3: ALU_op = aluop_t'(18); // SLTIU
                default: invalid_instruction = 1'b1;
            endcase
        end

        // -------------- Loads (0000011) --------------
        7'b0000011: begin
            ALU_src = 1'b1;  // base + imm
            MemToReg = 1'b1;
            MemRead = 1'b1;
            unique case (i_funct3)
                3'h0: ALU_op = aluop_t'(19); // LB
                3'h1: ALU_op = aluop_t'(20); // LH
                3'h2: ALU_op = aluop_t'(21); // LW
                3'h4: ALU_op = aluop_t'(22); // LBU
                3'h5: ALU_op = aluop_t'(23); // LHU
                default: invalid_instruction = 1'b1;
            endcase
        end

        // -------------- Stores (0100011) --------------
        7'b0100011: begin
            ALU_src = 1'b1;  // base + imm
            MemWrite = 1'b1;
            RegWrite = 1'b0;
            unique case (i_funct3)
                3'h0: ALU_op = aluop_t'(24); // SB
                3'h1: ALU_op = aluop_t'(25); // SH
                3'h2: ALU_op = aluop_t'(26); // SW
                default: invalid_instruction = 1'b1;
            endcase
        end

        // -------------- Branches (1100011) --------------
        7'b1100011: begin
            ALU_src = 1'b0;  // rs2
            RegWrite = 1'b0;
            unique case (i_funct3)
                3'h0: ALU_op = aluop_t'(27); // BEQ
                3'h1: ALU_op = aluop_t'(28); // BNE
                3'h4: ALU_op = aluop_t'(29); // BLT
                3'h5: ALU_op = aluop_t'(30); // BGE
                3'h6: ALU_op = aluop_t'(31); // BLTU
                3'h7: ALU_op = aluop_t'(32); // BGEU
                default: invalid_instruction = 1'b1;
            endcase
        end

        // JAL (1101111)
        7'b1101111: begin
            ALU_src = 1'b1;
            ALU_op  = aluop_t'(33);
        end

        // JALR (1100111, i_funct3 = 000)
        7'b1100111: begin
            ALU_src = 1'b1;     // rs1 + I-immediate
            if (i_funct3 == 3'h0) ALU_op = aluop_t'(34);
            else                invalid_instruction = 1'b1;
        end

        // LUI (0110111)
        7'b0110111: begin
            ALU_src = 1'b1;
            ALU_op  = aluop_t'(35);
        end

        // AUIPC (0010111)
        7'b0010111: begin
            ALU_src = 1'b1;
            ALU_op  = aluop_t'(36);
        end

        default: begin
            invalid_instruction = 1'b1;
        end
    endcase
end

endmodule
