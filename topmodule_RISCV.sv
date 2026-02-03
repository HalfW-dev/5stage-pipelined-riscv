////////
// Topmodule of the RISCV architecture
///////

module topmodule_RISCV #(
    parameter ADDR_WIDTH = 32,
    parameter INST_WIDTH = 32, // for RV32I
    parameter DATA_WIDTH = 32,
    parameter INST_COUNT = 37  // for RV32I without ecall and ebreak
)(
    input  logic clk,
    input  logic resetn,

    // RISC-V FORMAL INTERFACE (RVFI) OUTPUTS

    output logic        rvfi_valid,
    output logic [63:0] rvfi_order,
    output logic [31:0] rvfi_insn,
    output logic        rvfi_trap,
    output logic        rvfi_halt,
    output logic        rvfi_intr,
    output logic [ 1:0] rvfi_mode,
    output logic [ 1:0] rvfi_ixl,
    
    output logic [ 4:0] rvfi_rs1_addr,
    output logic [ 4:0] rvfi_rs2_addr,
    output logic [31:0] rvfi_rs1_rdata,
    output logic [31:0] rvfi_rs2_rdata,
    
    output logic [ 4:0] rvfi_rd_addr,
    output logic [31:0] rvfi_rd_wdata,
    
    output logic [31:0] rvfi_pc_rdata,
    output logic [31:0] rvfi_pc_wdata,
    
    output logic [31:0] rvfi_mem_addr,
    output logic [ 3:0] rvfi_mem_rmask,
    output logic [ 3:0] rvfi_mem_wmask,
    output logic [31:0] rvfi_mem_rdata,
    output logic [31:0] rvfi_mem_wdata,
    
    output [INST_WIDTH-1:0] o_reg_ID_instruction
);

    localparam W = $clog2(INST_COUNT);

    // PIPELINE WIRES FOR RVFI
    // EX stage
    logic [ADDR_WIDTH-1:0] reg_EX_pc;
    logic [INST_WIDTH-1:0] reg_EX_insn;
    logic [DATA_WIDTH-1:0] reg_EX_rs1_data_rvfi;
    logic [DATA_WIDTH-1:0] reg_EX_rs2_data_rvfi; 

    // MEM stage
    logic [ADDR_WIDTH-1:0] reg_MEM_pc;
    logic [INST_WIDTH-1:0] reg_MEM_insn;
    logic [ADDR_WIDTH-1:0] reg_MEM_next_pc;
    logic [DATA_WIDTH-1:0] reg_MEM_rs1_data_rvfi;
    logic [DATA_WIDTH-1:0] reg_MEM_rs2_data_rvfi;
    logic [DATA_WIDTH-1:0] reg_MEM_mem_wdata;

    //WB stage
    logic [ADDR_WIDTH-1:0] reg_WB_pc;
    logic [INST_WIDTH-1:0] reg_WB_insn;
    logic [ADDR_WIDTH-1:0] reg_WB_next_pc;
    logic [DATA_WIDTH-1:0] reg_WB_rs1_data_rvfi;
    logic [DATA_WIDTH-1:0] reg_WB_rs2_data_rvfi;
    logic [DATA_WIDTH-1:0] reg_WB_mem_addr;
    logic [DATA_WIDTH-1:0] reg_WB_mem_wdata;
    logic [3:0]            reg_WB_mem_wmask;
    logic [3:0]            reg_WB_mem_rmask;

    // RVFI order counter
    logic [63:0] insn_order;
    
    // Control signals from CU
    logic        CU_ID_ALUSrc;
    logic [W-1:0] CU_ID_ALUOp;
    logic        CU_ID_MemRead;
    logic        CU_ID_MemWrite;
    logic        CU_ID_RegWrite;
    logic        CU_ID_MemToReg;

    logic        CU_EX_reg_ALUSrc;
    logic [W-1:0] CU_EX_reg_ALUOp;
    logic        CU_EX_reg_MemRead;
    logic        CU_EX_reg_MemWrite;
    logic        CU_EX_reg_RegWrite;
    logic        CU_EX_reg_MemToReg;

    logic [1:0]  FW_EX_forward_rs1;
    logic [1:0]  FW_EX_forward_rs2;

    // Intermediate signals for forwarding MUX outputs
    logic [DATA_WIDTH-1:0] EX_rs1_data_fwd; 
    logic [DATA_WIDTH-1:0] EX_rs2_data_fwd; 

    logic stall_pipeline;

    // IF stage outputs
    logic [ADDR_WIDTH-1:0] IF_reg_address;      
    logic [INST_WIDTH-1:0] IF_reg_instruction;  

    // IF/ID register outputs
    logic [ADDR_WIDTH-1:0] reg_ID_address;         
    logic [INST_WIDTH-1:0] reg_ID_instruction;     

    assign o_reg_ID_instruction = reg_ID_instruction;

    // ID stage output
    logic [DATA_WIDTH-1:0] ID_reg_rs1_data;
    logic [DATA_WIDTH-1:0] ID_reg_rs2_data;
    logic [DATA_WIDTH-1:0] ID_reg_imm;
    logic [6:0] ID_reg_opcode;
    logic [2:0] ID_reg_funct3;
    logic [6:0] ID_reg_funct7;
    logic [4:0] ID_reg_rs1;
    logic [4:0] ID_reg_rs2;
    logic [4:0] ID_reg_rd;

    // Intermediate signals for ID stage forwarding
    logic [DATA_WIDTH-1:0] ID_final_rs1_data;
    logic [DATA_WIDTH-1:0] ID_final_rs2_data;

    // ID/EX register outputs
    logic [DATA_WIDTH-1:0] reg_EX_rs1_data;
    logic [DATA_WIDTH-1:0] reg_EX_rs2_data;
    logic [DATA_WIDTH-1:0] reg_EX_imm;
    logic [ADDR_WIDTH-1:0] reg_EX_address;
    logic [6:0] reg_EX_opcode;
    logic [2:0] reg_EX_funct3;
    logic [6:0] reg_EX_funct7;
    logic [4:0] reg_EX_reg_rs1;
    logic [4:0] reg_EX_reg_rs2;
    logic [4:0] reg_EX_reg_rd; 

    // Branch signals
    logic [ADDR_WIDTH-1:0] branch_address;
    logic                  branch_taken;

    // EX stage output
    logic [DATA_WIDTH-1:0] EX_reg_rs1_data;
    logic [DATA_WIDTH-1:0] EX_reg_rs2_data;
    logic [DATA_WIDTH-1:0] EX_reg_rd_data;
    logic [ADDR_WIDTH-1:0] EX_next_pc_calc;

    // EX/MEM register outputs
    logic [DATA_WIDTH-1:0] reg_MEM_rs1_data;
    logic [DATA_WIDTH-1:0] reg_MEM_rs2_data;
    logic [DATA_WIDTH-1:0] reg_MEM_rd_data;
    logic [W-1:0] reg_MEM_ALUOp;
    logic reg_MEM_MemRead;
    logic reg_MEM_MemWrite;
    logic reg_MEM_RegWrite;
    logic reg_MEM_MemToReg;
    logic [4:0] reg_MEM_reg_rd; 
    logic [4:0] reg_MEM_reg_rs1;
    logic [4:0] reg_MEM_reg_rs2;

    // MEM stage output
    logic [DATA_WIDTH-1:0] MEM_reg_dmem_data;
    logic [DATA_WIDTH-1:0] MEM_reg_rd_data;
    logic MEM_reg_RegWrite;
    logic MEM_reg_MemToReg;

    // MEM/WB register outputs
    logic [DATA_WIDTH-1:0] reg_WB_dmem_data;
    logic [DATA_WIDTH-1:0] reg_WB_rd_data;
    logic [4:0] reg_WB_rd;
    logic [4:0] reg_WB_rs1;
    logic [4:0] reg_WB_rs2;
    logic reg_WB_RegWrite;
    logic reg_WB_MemToReg;

    // WB/ID signals
    logic WB_ID_RegWrite;
    logic [4:0] WB_ID_rd;
    logic [DATA_WIDTH-1:0] WB_ID_rd_data;

    // SUBMODULE INSTANTIATIONS
    cu cu (
        .clk(clk),
        .resetn(resetn),
        .i_opcode(ID_reg_opcode),  
        .i_funct3(ID_reg_funct3),  
        .i_funct7(ID_reg_funct7),  
        .o_ALUSrc(CU_ID_ALUSrc),     
        .o_ALUOp(CU_ID_ALUOp),       
        .o_MemRead(CU_ID_MemRead),   
        .o_MemWrite(CU_ID_MemWrite), 
        .o_RegWrite(CU_ID_RegWrite), 
        .o_MemToReg(CU_ID_MemToReg), 
        .o_invalid_instruction()
    );

    forward forward(
        .i_rs1_ex(reg_EX_reg_rs1),
        .i_rs2_ex(reg_EX_reg_rs2),
        .i_rd_mem(reg_MEM_reg_rd),
        .i_regwrite_mem(reg_MEM_RegWrite),
        .i_rd_wb(reg_WB_rd),
        .i_regwrite_wb(reg_WB_RegWrite),
        .o_forward_rs1(FW_EX_forward_rs1),
        .o_forward_rs2(FW_EX_forward_rs2)
    );

    hazard_unit hazard_unit (
        .i_rs1_id      (ID_reg_rs1),
        .i_rs2_id      (ID_reg_rs2),
        .i_rd_ex       (reg_EX_reg_rd),
        .i_mem_read_ex (CU_EX_reg_MemRead),
        .o_stall       (stall_pipeline)
    );

    IF_stage IF_stage (
        .clk(clk),
        .resetn(resetn),
        .i_branch_addr(branch_address), 
        .i_branch_inst(branch_taken), 
        .i_pipeline_stall(stall_pipeline), 
        .o_address(IF_reg_address), 
        .o_instruction(IF_reg_instruction)
    );

    IFID_reg IFID_reg (
        .clk(clk),
        .resetn(resetn),
        .i_branch_taken(branch_taken && !stall_pipeline),
        .i_stall(stall_pipeline), 
        .i_address(IF_reg_address), 
        .i_instruction(IF_reg_instruction), 
        .o_address(reg_ID_address), 
        .o_instruction(reg_ID_instruction) 
    );

    ID_stage ID_stage (
        .clk(clk),
        .resetn(resetn),
        .i_branch_taken(branch_taken),
        .i_instruction(reg_ID_instruction),
        .i_write_data(WB_ID_rd_data),
        .i_write_ena(WB_ID_RegWrite),
        .i_write_address(WB_ID_rd),
        .o_rs1_data(ID_reg_rs1_data),
        .o_rs2_data(ID_reg_rs2_data),
        .o_opcode(ID_reg_opcode), 
        .o_funct3(ID_reg_funct3), 
        .o_funct7(ID_reg_funct7), 
        .o_rs1(ID_reg_rs1),
        .o_rs2(ID_reg_rs2),
        .o_rd(ID_reg_rd),
        .o_imm(ID_reg_imm)
    );

    // ID Forwarding Logic
    always_comb begin
        if (WB_ID_RegWrite && (WB_ID_rd == ID_reg_rs1) && (WB_ID_rd != 5'd0)) begin
            ID_final_rs1_data = WB_ID_rd_data; 
        end else begin
            ID_final_rs1_data = ID_reg_rs1_data; 
        end
    end
    always_comb begin
        if (WB_ID_RegWrite && (WB_ID_rd == ID_reg_rs2) && (WB_ID_rd != 5'd0)) begin
            ID_final_rs2_data = WB_ID_rd_data;
        end else begin
            ID_final_rs2_data = ID_reg_rs2_data;
        end
    end

    IDEX_reg IDEX_reg( 
        .clk(clk),
        .resetn(resetn),
        .i_branch_taken(branch_taken),
        .i_rs1_data(ID_final_rs1_data), 
        .i_rs2_data(ID_final_rs2_data),
        .i_imm(ID_reg_imm),
        .i_address(reg_ID_address),
        
        .i_instruction(reg_ID_instruction),
        
        .i_opcode ( (stall_pipeline) ? 7'b0 : ID_reg_opcode ), 
        .i_funct3 ( (stall_pipeline) ? 3'b0 : ID_reg_funct3 ),
        .i_funct7 ( (stall_pipeline) ? 7'b0 : ID_reg_funct7 ),
        .i_rd(ID_reg_rd),
        .i_rs1(ID_reg_rs1),
        .i_rs2(ID_reg_rs2),
        .i_ALUSrc   ( (stall_pipeline) ? 1'b0 : CU_ID_ALUSrc   ),
        .i_ALUOp    ( (stall_pipeline) ? 1'b0 : CU_ID_ALUOp    ),
        .i_RegWrite ( (stall_pipeline) ? 1'b0 : CU_ID_RegWrite ),
        .i_MemRead  ( (stall_pipeline) ? 1'b0 : CU_ID_MemRead  ),
        .i_MemWrite ( (stall_pipeline) ? 1'b0 : CU_ID_MemWrite ),
        .i_MemToReg(CU_ID_MemToReg),

        .o_instruction(reg_EX_insn),
        .o_address(reg_EX_pc),
        
        .o_ALUSrc(CU_EX_reg_ALUSrc),
        .o_ALUOp(CU_EX_reg_ALUOp),
        .o_MemRead(CU_EX_reg_MemRead),
        .o_MemWrite(CU_EX_reg_MemWrite),
        .o_RegWrite(CU_EX_reg_RegWrite),
        .o_MemToReg(CU_EX_reg_MemToReg),
        .o_rs1_data(reg_EX_rs1_data),
        .o_rs2_data(reg_EX_rs2_data),
        .o_imm(reg_EX_imm),
        .o_opcode(reg_EX_opcode),
        .o_funct3(reg_EX_funct3),
        .o_funct7(reg_EX_funct7),
        .o_rd(reg_EX_reg_rd),
        .o_rs1(reg_EX_reg_rs1),
        .o_rs2(reg_EX_reg_rs2)
    );

    // Forwarding MUXes
    always_comb begin : MUX_FORWARD_A
        case (FW_EX_forward_rs1)
            2'b00: EX_rs1_data_fwd = reg_EX_rs1_data;  
            2'b10: EX_rs1_data_fwd = reg_MEM_rd_data;  
            2'b01: EX_rs1_data_fwd = WB_ID_rd_data;    
            default: EX_rs1_data_fwd = reg_EX_rs1_data;
        endcase
    end

    always_comb begin : MUX_FORWARD_B
        case (FW_EX_forward_rs2)
            2'b00: EX_rs2_data_fwd = reg_EX_rs2_data;  
            2'b10: EX_rs2_data_fwd = reg_MEM_rd_data;  
            2'b01: EX_rs2_data_fwd = WB_ID_rd_data;    
            default: EX_rs2_data_fwd = reg_EX_rs2_data;
        endcase
    end

    assign EX_next_pc_calc = branch_taken ? branch_address : (reg_EX_pc + 4);

    EX_stage EX_stage (
        .clk(clk),
        .resetn(resetn),
        .i_rs1_data(EX_rs1_data_fwd),
        .i_rs2_data(EX_rs2_data_fwd),
        .i_imm(reg_EX_imm),
        .i_address(reg_EX_pc),
        .i_ALUSrc(CU_EX_reg_ALUSrc),
        .i_ALUOp(CU_EX_reg_ALUOp),
        .o_branch_address(branch_address),
        .o_branch_taken(branch_taken),
        .o_alu_result(EX_reg_rd_data),
        .o_rs1_data(EX_reg_rs1_data),
        .o_rs2_data(EX_reg_rs2_data)
    );

    EXMEM_reg EXMEM_reg (
        .clk(clk),
        .resetn(resetn),

        .i_pc(reg_EX_pc),
        .i_instruction(reg_EX_insn),
        .i_next_pc(EX_next_pc_calc),
        
        .i_rs1_data_rvfi(reg_EX_rs1_data), 
        .i_rs2_data_rvfi(reg_EX_rs2_data), 

        .i_rs1_data(EX_reg_rs1_data),
        .i_rs2_data(EX_reg_rs2_data),
        .i_rd_data(EX_reg_rd_data),
        .i_ALUOp(CU_EX_reg_ALUOp),
        .i_MemRead(CU_EX_reg_MemRead),
        .i_MemWrite(CU_EX_reg_MemWrite),
        .i_RegWrite(CU_EX_reg_RegWrite),
        .i_MemToReg(CU_EX_reg_MemToReg),
        .i_rd(reg_EX_reg_rd),
        .i_rs1(reg_EX_reg_rs1),
        .i_rs2(reg_EX_reg_rs2),
        
        .o_pc(reg_MEM_pc),
        .o_instruction(reg_MEM_insn),
        .o_next_pc(reg_MEM_next_pc),
        .o_rs1_data_rvfi(reg_MEM_rs1_data_rvfi),
        .o_rs2_data_rvfi(reg_MEM_rs2_data_rvfi),

        .o_rs1_data(reg_MEM_rs1_data),
        .o_rs2_data(reg_MEM_rs2_data),
        .o_rd_data(reg_MEM_rd_data),
        .o_ALUOp(reg_MEM_ALUOp),
        .o_MemRead(reg_MEM_MemRead),
        .o_MemWrite(reg_MEM_MemWrite),
        .o_RegWrite(reg_MEM_RegWrite),
        .o_MemToReg(reg_MEM_MemToReg),
        .o_rd(reg_MEM_reg_rd),
        .o_rs1(reg_MEM_reg_rs1),
        .o_rs2(reg_MEM_reg_rs2)
    );

    MEM_stage MEM_stage (
        .clk(clk),
        .resetn(resetn),
        .i_rs1_data(reg_MEM_rs1_data),
        .i_rs2_data(reg_MEM_rs2_data),
        .i_EX_rd_data(reg_MEM_rd_data),
        .i_ALUOp(reg_MEM_ALUOp),
        .i_MemRead(reg_MEM_MemRead),
        .i_MemWrite(reg_MEM_MemWrite),
        .i_RegWrite(reg_MEM_RegWrite),
        .i_MemToReg(reg_MEM_MemToReg),
        .o_EX_rd_data(MEM_reg_rd_data),
        .o_dmem_data(MEM_reg_dmem_data),
        .o_RegWrite(MEM_reg_RegWrite),
        .o_MemToReg(MEM_reg_MemToReg)
    );

    MEMWB_reg MEMWB_reg (
        .clk(clk),
        .resetn(resetn),
        
        .i_pc(reg_MEM_pc),
        .i_instruction(reg_MEM_insn),
        .i_next_pc(reg_MEM_next_pc),
        .i_rs1_data_rvfi(reg_MEM_rs1_data_rvfi),
        .i_rs2_data_rvfi(reg_MEM_rs2_data_rvfi),
        .i_mem_addr(reg_MEM_rd_data),
        .i_mem_wdata(reg_MEM_rs2_data),
        
        .i_dmem_data(MEM_reg_dmem_data),
        .i_rd_data(MEM_reg_rd_data),
        .i_rd(reg_MEM_reg_rd),
        .i_rs1(reg_MEM_reg_rs1),
        .i_rs2(reg_MEM_reg_rs2),
        .i_RegWrite(MEM_reg_RegWrite),
        .i_MemToReg(MEM_reg_MemToReg),
        
        .o_pc(reg_WB_pc),
        .o_instruction(reg_WB_insn),
        .o_next_pc(reg_WB_next_pc),
        .o_rs1_data_rvfi(reg_WB_rs1_data_rvfi),
        .o_rs2_data_rvfi(reg_WB_rs2_data_rvfi),
        .o_mem_addr(reg_WB_mem_addr),
        
        .o_dmem_data(reg_WB_dmem_data),
        .o_rd_data(reg_WB_rd_data),
        .o_rd(reg_WB_rd),
        .o_rs1(reg_WB_rs1),
        .o_rs2(reg_WB_rs2),
        .o_RegWrite(reg_WB_RegWrite),
        .o_MemToReg(reg_WB_MemToReg)
    );

    WB_stage WB_stage (
        .i_rd_data(reg_WB_rd_data),
        .i_dmem_data(reg_WB_dmem_data),
        .i_rd(reg_WB_rd),
        .i_MemToReg(reg_WB_MemToReg),
        .i_RegWrite(reg_WB_RegWrite),
        .o_RegWrite(WB_ID_RegWrite),
        .o_rd(WB_ID_rd),
        .o_rf_write_data(WB_ID_rd_data)
    );

    
    // Maintain order counter
    always_ff @(posedge clk or negedge resetn) begin
        if (!resetn) insn_order <= '0;
        else if (rvfi_valid) insn_order <= insn_order + 1;
    end

    // Assignments
    assign rvfi_valid     = (reg_WB_insn != 32'h00000013) && resetn;
    assign rvfi_order     = insn_order;
    assign rvfi_insn      = reg_WB_insn;
    assign rvfi_trap      = 1'b0;
    assign rvfi_halt      = 1'b0;
    assign rvfi_intr      = 1'b0;
    assign rvfi_mode      = 2'b11;
    assign rvfi_ixl       = 2'b01;
    
    assign rvfi_rs1_addr  = reg_WB_rs1;
    assign rvfi_rs2_addr  = reg_WB_rs2;
    assign rvfi_rs1_rdata = reg_WB_rs1_data_rvfi;
    assign rvfi_rs2_rdata = reg_WB_rs2_data_rvfi;
    
    assign rvfi_rd_addr   = (WB_ID_RegWrite) ? WB_ID_rd : 5'd0;
    assign rvfi_rd_wdata  = (WB_ID_RegWrite && WB_ID_rd != 0) ? WB_ID_rd_data : 32'd0;
    
    assign rvfi_pc_rdata  = reg_WB_pc;
    assign rvfi_pc_wdata  = reg_WB_next_pc;
    
    assign rvfi_mem_addr  = reg_WB_mem_addr;
    
    assign rvfi_mem_rmask = (reg_WB_MemToReg) ? 4'b1111 : 4'b0000; 
    assign rvfi_mem_wmask = (reg_WB_RegWrite == 0 && reg_WB_MemToReg == 0 && reg_WB_insn[6:0] == 7'b0100011) ? 4'b1111 : 4'b0000; 
    
    assign rvfi_mem_rdata = reg_WB_dmem_data;
    assign rvfi_mem_wdata = 32'b0;

endmodule