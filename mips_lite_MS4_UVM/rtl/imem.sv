module imem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);
    logic [31:0] mem [256];

    initial begin
        foreach (mem[i]) mem[i] = 32'h00000013;

        // Original instructions
        mem[ 0] = 32'h00000013;  // NOP
        mem[ 1] = 32'h00100093;  // addi x1,  x0,  1
        mem[ 2] = 32'h00200113;  // addi x2,  x0,  2
        mem[ 3] = 32'h00300193;  // addi x3,  x0,  3
        mem[ 4] = 32'h00400213;  // addi x4,  x0,  4
        mem[ 5] = 32'h00500293;  // addi x5,  x0,  5
        mem[ 6] = 32'h00A00313;  // addi x6,  x0,  10
        mem[ 7] = 32'h01400393;  // addi x7,  x0,  20
        mem[ 8] = 32'h06400413;  // addi x8,  x0,  100
        mem[ 9] = 32'h002081B3;  // add  x3,  x1,  x2
        mem[10] = 32'h00408493;  // addi x9,  x1,  4
        mem[11] = 32'h00810513;  // addi x10, x2,  8
        mem[12] = 32'hFFF00593;  // addi x11, x0,  -1
        mem[13] = 32'hFFE00613;  // addi x12, x0,  -2
        mem[14] = 32'hFF808693;  // addi x13, x1,  -8
        mem[15] = 32'h00302023;  // sw   x3,  0(x0)
        mem[16] = 32'h00108713;  // addi x14, x1,  1
        mem[17] = 32'h00210793;  // addi x15, x2,  2
        mem[18] = 32'h7FF00813;  // addi x16, x0,  2047
        mem[19] = 32'h80000893;  // addi x17, x0,  -2048
        // Coverage improvement
        mem[20] = 32'h00041103;  // lw   x2,  0(x8)   -> load opcode
        mem[21] = 32'h00049263;  // bne  x9,  x0, 4   -> branch opcode
        mem[22] = 32'h04800513;  // addi x10, x0, 72  -> large_pos
        mem[23] = 32'h00048593;  // addi x11, x9, 0   -> rs1=x9 (x8-x15)
        mem[24] = 32'h40208433;  // sub  x8,  x1, x2  -> R-type
        mem[25] = 32'h00080913;  // addi x18, x16, 0  -> rs1=x16 (x16-x31)
        // RTL fix: exercise SUB, AND, OR ALU branches
        mem[26] = 32'h401409B3;  // sub  x19, x8,  x1 -> alu_op=SUB
        mem[27] = 32'h00737A33;  // and  x20, x6,  x7 -> alu_op=AND
        mem[28] = 32'h00526AB3;  // or   x21, x4,  x5 -> alu_op=OR
    end

    assign instr = mem[addr >> 2];

endmodule