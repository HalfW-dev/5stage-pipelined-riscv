////////
// Forward unit to solve data hazard
///////

module forward (
    input  logic [4:0] i_rs1_ex,
    input  logic [4:0] i_rs2_ex,

    input  logic [4:0] i_rd_mem,
    input  logic       i_regwrite_mem,

    input  logic [4:0] i_rd_wb,
    input  logic       i_regwrite_wb,

    // 00 = Original (Regfile value)
    // 10 = Forward from MEM (Most recent)
    // 01 = Forward from WB (2nd most recent)
    output logic [1:0] o_forward_rs1,
    output logic [1:0] o_forward_rs2
);

    always_comb begin
        //rs1
        if (i_regwrite_mem && (i_rd_mem != 5'd0) && (i_rd_mem == i_rs1_ex)) begin
            o_forward_rs1 = 2'b10;
        
        end else if (i_regwrite_wb && (i_rd_wb != 5'd0) && (i_rd_wb == i_rs1_ex)) begin
            o_forward_rs1 = 2'b01;
            
        end else begin
            o_forward_rs1 = 2'b00;
        end
        
        //rs2
        if (i_regwrite_mem && (i_rd_mem != 5'd0) && (i_rd_mem == i_rs2_ex)) begin
            o_forward_rs2 = 2'b10;
            
        end else if (i_regwrite_wb && (i_rd_wb != 5'd0) && (i_rd_wb == i_rs2_ex)) begin
            o_forward_rs2 = 2'b01;
            
        end else begin
            o_forward_rs2 = 2'b00;
        end
    end

endmodule