import tb_pkg::*;

module tb_top;

    logic clk = 0;
    always #5 clk = ~clk;

    cpu_if intf(clk);

    cpu_top dut (
        .clk   (clk),
        .reset (intf.reset)
    );

    // Connect internal DUT signals to interface for monitoring
    assign intf.pc           = dut.pc;
    assign intf.instr        = dut.instr;
    assign intf.alu_result   = dut.alu_result;
    assign intf.reg_write_en = dut.reg_write_en;

    // Mailboxes
    mailbox #(transaction) g2d    = new();  // Generator -> Driver
    mailbox #(transaction) g2s    = new();  // Generator -> Scoreboard (expected)
    mailbox #(transaction) om2scb = new();  // oMon      -> Scoreboard (observed)

    // Components
    generator      gen;
    driver         drv;
    input_monitor  imon;
    output_monitor omon;
    scoreboard     scb;
    coverage       cov;

    initial begin
        $display("\n========================================");
        $display("  CPU TESTBENCH START");
        $display("========================================\n");

        intf.reset = 1;
        repeat(4) @(posedge clk);
        intf.reset = 0;
        $display("[TB_TOP] Reset deasserted\n");

        gen  = new(g2d, g2s, 20);
        drv  = new(g2d, intf);
        imon = new(intf);
        omon = new(om2scb, intf);
        scb  = new(g2s, om2scb);
        cov  = new(intf);

        fork
            gen.run();
            drv.run();
            imon.run();
            omon.run();
            scb.run();
        join_any

        repeat(5) @(posedge clk);

        scb.report();
        cov.report();

        $display("========================================");
        $display("  CPU TESTBENCH END");
        $display("========================================\n");
        $finish;
    end

    initial begin
        #50000;
        $display("[TIMEOUT] Simulation limit reached.");
        $finish;
    end

endmodule