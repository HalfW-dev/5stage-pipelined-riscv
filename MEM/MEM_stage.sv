module MEM_stage #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter INST_COUNT = 37
)(
    input  logic                   clk,
    input  logic                   resetn,

    input  logic [DATA_WIDTH-1:0]  i_rs1_data,
    input  logic [DATA_WIDTH-1:0]  i_rs2_data,
    input  logic [DATA_WIDTH-1:0]  i_EX_rd_data,

    input  logic [$clog2(INST_COUNT)-1:0] i_ALUOp,
    input  logic                   i_MemRead,
    input  logic                   i_MemWrite,
    input  logic                   i_RegWrite,
    input  logic                   i_MemToReg,

    output logic [DATA_WIDTH-1:0]  o_EX_rd_data,
    output logic [DATA_WIDTH-1:0]  o_dmem_data,
    output logic                   o_RegWrite,
    output logic                   o_MemToReg
);

    logic dmem_ena;
    logic dmem_write;
    logic [3:0] dmem_byte_sel;
    logic [ADDR_WIDTH-1:0] dmem_address;
    logic [DATA_WIDTH-1:0] dmem_wdata;
    logic [DATA_WIDTH-1:0] dmem_rdata;

    logic [1:0] byte_offset;
    logic [7:0] extracted_byte;
    logic [15:0] extracted_half;

    assign o_MemToReg = i_MemToReg;
    assign o_RegWrite = i_RegWrite;
    assign o_EX_rd_data = i_EX_rd_data; 

    always_comb begin
        if (i_ALUOp >= 19 && i_ALUOp <= 26) begin
            dmem_address = i_EX_rd_data;
        end else begin
            dmem_address = '0;
        end
    end

    assign byte_offset = dmem_address[1:0];

    always_comb begin : LSU
        dmem_ena      = 1'b0;
        dmem_write    = 1'b0;
        dmem_byte_sel = 4'b0000;
        dmem_wdata    = 32'b0;
        o_dmem_data   = 32'b0;

        extracted_byte = dmem_rdata[(byte_offset*8) +: 8]; 
        extracted_half = dmem_rdata[(byte_offset*8) +: 16];

        if (i_ALUOp >= 19 && i_ALUOp <= 26) begin
            dmem_ena = 1'b1; 

            if (i_ALUOp <= 23) begin
                dmem_write = 1'b0;
                case (i_ALUOp)
                    19: o_dmem_data = {{24{extracted_byte[7]}}, extracted_byte}; // LB
                    20: o_dmem_data = {{16{extracted_half[15]}}, extracted_half}; // LH
                    21: o_dmem_data = dmem_rdata; // LW
                    22: o_dmem_data = {24'b0, extracted_byte}; // LBU
                    23: o_dmem_data = {16'b0, extracted_half}; // LHU
                    default: o_dmem_data = 32'b0;
                endcase

            end else begin
                dmem_write = 1'b1;
                case (i_ALUOp)
                    24: begin // SB
                        dmem_wdata    = i_rs2_data << (byte_offset * 8);
                        dmem_byte_sel = 4'b0001 << byte_offset;
                    end
                    25: begin // SH
                        dmem_wdata    = i_rs2_data << (byte_offset * 8);
                        dmem_byte_sel = 4'b0011 << byte_offset;
                    end
                    26: begin // SW
                        dmem_wdata    = i_rs2_data;
                        dmem_byte_sel = 4'b1111;
                    end
                    default: dmem_byte_sel = 4'b0000;
                endcase
            end
        end
    end

    `ifdef RISCV_FORMAL

    `else
        dmem dmem_inst (
            .clk(clk),
            .i_mem_ena(dmem_ena),
            .i_mem_write(dmem_write),
            .i_byte_sel(dmem_byte_sel),
            .i_addr(dmem_address),
            .i_wdata(dmem_wdata), 
            .o_rdata(dmem_rdata)
        );
    `endif


endmodule