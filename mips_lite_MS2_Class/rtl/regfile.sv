// register File

module regfile (
    input  logic clk,
    input  logic reset,
    input  logic we,
    input  logic [4:0] rs1,
    input  logic [4:0] rs2,
    input  logic [4:0] rd,
    input  logic [31:0] wd,
    output logic [31:0] rd1,
    output logic [31:0] rd2
);


    logic [31:0] regs [31:0];

    integer i;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i++)
                regs[i] <= 32'b0;
        end 
    else if (we && rd != 0)
        regs[rd] <= wd;
    end


    assign rd1 = (rs1 != 0) ? regs[rs1] : 32'b0;
    assign rd2 = (rs2 != 0) ? regs[rs2] : 32'b0;

endmodule
