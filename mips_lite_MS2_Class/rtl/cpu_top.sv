// cpu_top.sv 
// Top-level wrapper

module cpu_top (
    input  logic clk,
    input  logic reset
);

    // Internal signals
    logic [31:0] pc;
    logic [31:0] instr;
    logic [4:0] rs1, rs2, rd;
    logic [31:0] imm;
    logic [31:0] rd1, rd2;
    logic [31:0] alu_result;
    logic reg_write_en;
    
    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];
    assign imm = {{20{instr[31]}}, instr[31:20]};  // I-type immediate
    assign reg_write_en = 1'b1;

    // reg file 
    regfile u_regfile (
    .clk (clk),
    .reset(reset),
    .we  (reg_write_en),
    .rs1 (rs1),
    .rs2 (rs2),
    .rd  (rd),
    .wd  (alu_result),
    .rd1 (rd1),
    .rd2 (rd2)
);

    // alu 
    alu u_alu (
    .a (rd1),
    .b (imm),
    .alu_op (4'b0000),  // ADD operation
    .result (alu_result)
);

    // Program Counter
    pc u_pc (
        .clk   (clk),
        .reset (reset),
        .pc    (pc)
    );

    // Instruction Memory
    imem u_imem (
        .addr  (pc),
        .instr (instr)
    );

endmodule
