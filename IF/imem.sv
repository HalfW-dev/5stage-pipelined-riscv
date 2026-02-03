// -------------------------------------------------------------
// Instruction Memory (IMEM) for RV32I
// -------------------------------------------------------------
module imem #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,   // 32-bit RV32I instructions

    parameter MEM_DEPTH = 256
)(
    input  logic                   clka,
    input  logic                   reseta,
    input  logic [ADDR_WIDTH-1:0]  addra,   // byte address from IF_stage
    output logic [INST_WIDTH-1:0]  douta
);

    logic [INST_WIDTH-1:0] mem [0:MEM_DEPTH-1];
    logic just_reset;

    // ---------------------------------------------------------
    // Initialize memory from a hex file
    // ---------------------------------------------------------
    initial begin
        $readmemh("B:/dev/project/riscv/IF/inst_mem.hex", mem);
    end

    always_ff @(posedge clka or negedge reseta) begin
        if(!reseta) douta <= '0;
        else        douta <= mem[addra[ADDR_WIDTH-1:2]];
    end

endmodule
