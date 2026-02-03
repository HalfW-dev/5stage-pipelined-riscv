////////
// Immediate Generator for RV32I
///////

module immgen #(
    parameter INST_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  logic [INST_WIDTH-1:0] i_instruction,
    output logic [DATA_WIDTH-1:0] o_imm
);

    // Extract opcode
    logic [6:0] opcode;
    assign opcode = i_instruction[6:0];

    always_comb begin
        // Default immediate = 0
        o_imm = '0;

        unique case (opcode)
            7'b0010011,
            7'b0000011,
            7'b1100111,
            7'b0001111,
            7'b1110011: begin
                o_imm = {{20{i_instruction[31]}}, i_instruction[31:20]};
            end

            // -------------------------------------------------
            // S-type: stores (SB, SH, SW)
            // -------------------------------------------------
            7'b0100011: begin
                o_imm = {{20{i_instruction[31]}},
                          i_instruction[31:25],
                          i_instruction[11:7]};
            end

            // -------------------------------------------------
            // B-type: branches (BEQ, BNE, BLT, BGE, BLTU, BGEU)
            // 1100011
            // -------------------------------------------------
            7'b1100011: begin
                o_imm = {{19{i_instruction[31]}},
                          i_instruction[31],
                          i_instruction[7],
                          i_instruction[30:25],
                          i_instruction[11:8],
                          1'b0};
            end

            // -------------------------------------------------
            // U-type: LUI / AUIPC
            // -------------------------------------------------
            7'b0110111,
            7'b0010111: begin
                // imm[31:12] = inst[31:12], lower 12 bits are zero
                o_imm = {i_instruction[31:12], 12'b0};
            end

            // -------------------------------------------------
            // J-type: JAL
            // -------------------------------------------------
            7'b1101111: begin
                o_imm = {{11{i_instruction[31]}},
                          i_instruction[31],
                          i_instruction[19:12],
                          i_instruction[20],
                          i_instruction[30:21],
                          1'b0};
            end

            default: begin
                o_imm = '0;
            end
        endcase
    end

endmodule
