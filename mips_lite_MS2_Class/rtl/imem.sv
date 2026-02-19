// =============================================================================
// imem.sv — Instruction Memory (ROM)
// Extended with diverse instructions to improve coverage
// =============================================================================
module imem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

logic [31:0] mem [0:255];
integer i;

initial begin
    // Default all to NOP
    for (i = 0; i < 256; i++)
        mem[i] = 32'h00000013;

    //  #  Address  | Hex Encoding | Assembly           | Effect
    mem[0]  = 32'h00000013;  // addi x0,  x0,  0   → NOP
    mem[1]  = 32'h00100093;  // addi x1,  x0,  1   → x1 = 1
    mem[2]  = 32'h00200113;  // addi x2,  x0,  2   → x2 = 2
    mem[3]  = 32'h00300193;  // addi x3,  x0,  3   → x3 = 3
    mem[4]  = 32'h00400213;  // addi x4,  x0,  4   → x4 = 4
    mem[5]  = 32'h00500293;  // addi x5,  x0,  5   → x5 = 5
    mem[6]  = 32'h00A00313;  // addi x6,  x0,  10  → x6 = 10
    mem[7]  = 32'h01400393;  // addi x7,  x0,  20  → x7 = 20
    mem[8]  = 32'h06400413;  // addi x8,  x0,  100 → x8 = 100
    mem[9]  = 32'h002081B3;  // add  x3,  x1,  x2  → ALU: x1+imm[2]=1+2=3
    mem[10] = 32'h00408493;  // addi x9,  x1,  4   → x9 = 1+4 = 5
    mem[11] = 32'h00810513;  // addi x10, x2,  8   → x10= 2+8 = 10
    mem[12] = 32'hFFF00593;  // addi x11, x0, -1   → x11= -1
    mem[13] = 32'hFFE00613;  // addi x12, x0, -2   → x12= -2
    mem[14] = 32'hFF808693;  // addi x13, x1, -8   → x13= 1-8 = -7
    mem[15] = 32'h00302023;  // sw   x3,  0(x0)    → store
    mem[16] = 32'h00108713;  // addi x14, x1,  1   → x14= 1+1=2
    mem[17] = 32'h00210793;  // addi x15, x2,  2   → x15= 2+2=4
    mem[18] = 32'h7FF00813;  // addi x16, x0, 2047 → x16= 2047 (max pos imm)
    mem[19] = 32'h80000893;  // addi x17, x0,-2048 → x17=-2048 (min neg imm)
end

assign instr = mem[addr[9:2]];

endmodule