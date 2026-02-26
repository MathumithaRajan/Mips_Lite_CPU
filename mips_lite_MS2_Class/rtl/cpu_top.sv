// cpu_top.sv — Top-level CPU wrapper

module cpu_top (
    input  logic clk,
    input  logic reset
);

    logic [31:0] pc;
    logic [31:0] instr;
    logic [4:0]  rs1, rs2, rd;
    logic [31:0] imm;
    logic [31:0] rd1, rd2;
    logic [31:0] alu_result;
    logic        reg_write_en;
    logic [3:0]  alu_op;

    assign rs1 = instr[19:15];
    assign rs2 = instr[24:20];
    assign rd  = instr[11:7];
    assign imm = {{20{instr[31]}}, instr[31:20]};

    always_comb begin
        case (instr[6:0])
            7'b0100011: reg_write_en = 1'b0;
            7'b1100011: reg_write_en = 1'b0;
            default:    reg_write_en = 1'b1;
        endcase
    end

    always_comb begin
        case (instr[6:0])
            7'b0110011: begin
                if (instr[14:12] == 3'b000 && instr[31:25] == 7'b0100000)
                    alu_op = 4'b0001;
                else if (instr[14:12] == 3'b111)
                    alu_op = 4'b0010;
                else if (instr[14:12] == 3'b110)
                    alu_op = 4'b0011;
                else
                    alu_op = 4'b0000;
            end
            default: alu_op = 4'b0000;
        endcase
    end

    regfile u_regfile (
        .clk   (clk),  .reset (reset),
        .we    (reg_write_en),
        .rs1   (rs1),  .rs2   (rs2),
        .rd    (rd),   .wd    (alu_result),
        .rd1   (rd1),  .rd2   (rd2)
    );

    alu u_alu (
        .a      (rd1),
        .b      (imm),
        .alu_op (alu_op),
        .result (alu_result)
    );

    pc u_pc (
        .clk   (clk),
        .reset (reset),
        .pc    (pc)
    );

    imem u_imem (
        .addr  (pc),
        .instr (instr)
    );

endmodule