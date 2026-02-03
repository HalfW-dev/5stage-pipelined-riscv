////////
// IF/ID register
///////

module IFID_reg #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32, 
    parameter INST_NOP   = 32'h00000013
)(
    input  logic                   clk,
    input  logic                   resetn,
    
    input  logic                   i_branch_taken,
    input  logic                   i_stall,

    input  logic [ADDR_WIDTH-1:0]  i_address,
    input  logic [INST_WIDTH-1:0]  i_instruction,

    output logic [ADDR_WIDTH-1:0]  o_address,
    output logic [INST_WIDTH-1:0]  o_instruction
);

    logic [ADDR_WIDTH-1:0] address;
    logic [INST_WIDTH-1:0] instruction;
    logic [1:0] ins_kill_count; 

    assign o_address = address;
    assign o_instruction = instruction;

    always_ff @(posedge clk or negedge resetn) begin : propagate
        if(!resetn) begin
            address        <= '0;
            instruction    <= '0;
            ins_kill_count <= 2'b10;
        end 
        else if(i_branch_taken) begin
            address        <= '0;
            instruction    <= INST_NOP;
            ins_kill_count <= ins_kill_count - 2'b01;
        end 
        else if(ins_kill_count != 2'b10) begin
            if(ins_kill_count == 2'b00) begin
                address        <= i_address;
                instruction    <= i_instruction;
                ins_kill_count <= 2'b10;
            end else begin
                address        <= '0;
                instruction    <= '0;
                ins_kill_count <= ins_kill_count - 2'b01;
            end
        end 

        else if (i_stall) begin
            // If stalled, freeze everything.
        end 
        else begin
            address     <= i_address;
            instruction <= i_instruction;
        end
    end

endmodule