// cpu_top.sv 
// Top-level wrapper

module cpu_top (
    input  logic clk,
    input  logic reset
);

    // Internal signals
    logic [31:0] pc;
    logic [31:0] instr;

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
