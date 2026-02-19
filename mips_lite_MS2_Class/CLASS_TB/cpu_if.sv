// =============================================================================
// cpu_if.sv
// CPU Interface — connects DUT signals to testbench
// =============================================================================

interface cpu_if (input logic clk);

    logic        reset;
    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] alu_result;
    logic        reg_write_en;

endinterface