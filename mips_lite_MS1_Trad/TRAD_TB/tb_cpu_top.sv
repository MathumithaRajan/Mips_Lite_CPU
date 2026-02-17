
module tb_cpu_top;

    // Clock and reset
    logic clk;
    logic reset;

    // Instantiate DUT
    cpu_top dut (
        .clk   (clk),
        .reset (reset)
    );

    // Clock generation: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset sequence
    initial begin
        reset = 1;
        #20;
        reset = 0;
    end

    // Simulation control
    initial begin
        $display("Starting MS1d basic CPU test...");
        #200;
        $display("Ending simulation.");
        $finish;
    end

endmodule
