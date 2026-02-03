////////
// The IF stage of the architecture
///////
module IF_stage #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,              // for RV32I
    parameter INST_NOP   = 32'h00000013     // NOP
)(
    input  logic                  clk,
    input  logic                  resetn,

    input  logic [ADDR_WIDTH-1:0] i_branch_addr,   // branch target
    input  logic                  i_branch_inst,   // branch/jump taken (1-cycle pulse)

    input  logic                  i_pipeline_stall,

    output logic [ADDR_WIDTH-1:0] o_address,       // PC associated with o_instruction
    output logic [INST_WIDTH-1:0] o_instruction    // instruction at o_address
);
    logic [ADDR_WIDTH-1:0] pc_reg;
    logic [ADDR_WIDTH-1:0] pc_id_pc;
    logic [INST_WIDTH-1:0] inst_mem_dout;

    logic [INST_WIDTH-1:0] stall_inst_buffer;
    logic                  stall_active_prev;

    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            stall_inst_buffer <= INST_NOP;
            stall_active_prev <= 1'b0;
        end else begin
            if (i_pipeline_stall && !stall_active_prev) begin
                stall_inst_buffer <= inst_mem_dout;
            end
            
            stall_active_prev <= i_pipeline_stall;
        end
    end

    `ifdef RISCV_FORMAL
    `else
        imem imem (
            .clka  (clk),
            .reseta(resetn),
            .addra (pc_reg),
            .douta (inst_mem_dout)
        );
    `endif

    always_comb begin
        if (i_branch_inst) begin
            // On the cycle a branch is taken in EX, kill the IF output immediately
            o_address     = '0;
            o_instruction = INST_NOP;
        end else begin
            if (stall_active_prev) begin 
                o_instruction = stall_inst_buffer;
                o_address     = pc_id_pc; 
            end else begin
                o_instruction = inst_mem_dout;
                o_address     = pc_id_pc;
            end
        end
    end

    // PC update Logic
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            pc_reg   <= '0;
            pc_id_pc <= '0;
        end else begin
            if (i_pipeline_stall) begin
                pc_reg   <= pc_reg;
                pc_id_pc <= pc_id_pc;
            end else begin
                pc_id_pc <= pc_reg;

                if (i_branch_inst) begin
                    pc_reg <= i_branch_addr;
                end else begin
                    pc_reg <= pc_reg + 32'd4;
                end
            end
        end
    end

endmodule