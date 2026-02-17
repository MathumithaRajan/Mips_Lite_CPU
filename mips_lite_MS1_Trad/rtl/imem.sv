// instruction memory stub

module imem (
    input  logic [31:0] addr,
    output logic [31:0] instr
);

    // Dummy instruction memory
    always_comb begin
        instr = 32'h00000013; // NOP-like instruction
    end

endmodule
