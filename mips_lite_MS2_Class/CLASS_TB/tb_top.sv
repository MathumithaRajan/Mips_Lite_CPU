import tb_pkg::*;

module tb_top;

    logic clk = 0;
    always #5 clk = ~clk;

    cpu_if intf(clk);
    cpu_top dut (.clk(clk), .reset(intf.reset));

    assign intf.pc           = dut.pc;
    assign intf.instr        = dut.instr;
    assign intf.alu_result   = dut.alu_result;
    assign intf.reg_write_en = dut.reg_write_en;

    mailbox #(transaction) g2d    = new();
    mailbox #(transaction) g2s    = new();
    mailbox #(transaction) om2scb = new();

    generator      gen;
    driver         drv;
    input_monitor  imon;
    output_monitor omon;
    scoreboard     scb;
    coverage       cov;

    // 25 transactions: PC=4 to PC=0x64 (imem[1..25])
    // PC=0 (NOP during reset) is never observed post-reset, so skipped
    localparam int NUM_TRANSACTIONS = 28;

    initial begin
        $display("\n========================================");
        $display("  CPU TESTBENCH START");
        $display("========================================\n");

        intf.reset = 1;
        repeat(4) @(posedge clk);
        intf.reset = 0;
        $display("[TB_TOP] Reset deasserted\n");

        gen  = new(g2d, g2s, NUM_TRANSACTIONS);
        drv  = new(g2d, intf);
        imon = new(intf);
        omon = new(om2scb, intf);
        scb  = new(g2s, om2scb, NUM_TRANSACTIONS);
        cov  = new(intf);

        fork
            gen.run();
            drv.run();
            imon.run();
            omon.run();
            scb.run();
        join_none

        // Wait for scoreboard to finish all checks
        wait (scb.done == 1);
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
        $display("[TIMEOUT] Simulation exceeded limit.");
        scb.report();
        $finish;
    end

endmodule