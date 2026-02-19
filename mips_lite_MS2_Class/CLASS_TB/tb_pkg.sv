// =============================================================================
// tb_pkg.sv  —  CPU Testbench Package
// =============================================================================
// ARCHITECTURE:
//   Generator → gen2scb mailbox → Scoreboard (expected side)
//   Generator → gen2drv mailbox → Driver (just for pacing/display)
//   oMon      → omon2scb mailbox → Scoreboard (observed side)
//   iMon      → display only (no scoreboard connection needed)
//
// KEY INSIGHT: Generator knows exactly what ALU result to expect for each PC.
// oMon observes the DUT output at each PC. SCB matches them by burst_id,
// with oMon skipping the reset cycles until the DUT starts real execution.
// =============================================================================

package tb_pkg;

// =============================================================================
// TRANSACTION
// =============================================================================
class transaction;

    bit [6:0]  opcode;
    bit [4:0]  rd;
    bit [4:0]  rs1;
    bit [11:0] imm12;
    bit [31:0] instr;
    bit [31:0] observed_pc;

    int burst_id;

    bit [31:0] expected_alu_result;
    bit [31:0] observed_alu_result;

    function void decode(bit [31:0] i);
        instr  = i;
        opcode = i[6:0];
        rd     = i[11:7];
        rs1    = i[19:15];
        imm12  = i[31:20];
    endfunction

    function void display(string tag);
        $display("[%s] BurstID=%0d | PC=%h | INSTR=%h | rs1=x%0d rd=x%0d imm=%0d | ExpALU=%0d ObsALU=%0d",
                 tag, burst_id, observed_pc, instr, rs1, rd,
                 $signed({{20{imm12[11]}}, imm12}),
                 $signed(expected_alu_result),
                 $signed(observed_alu_result));
    endfunction

endclass

// =============================================================================
// GENERATOR
// Predicts expected ALU output for each instruction in imem.
// Sends to BOTH gen2drv (for pacing) and gen2scb (for scoreboard).
// =============================================================================
class generator;

    mailbox #(transaction) gen2drv;
    mailbox #(transaction) gen2scb;   // direct to scoreboard
    int num_cycles;

    bit [31:0] imem_mirror [256];

    function new(mailbox #(transaction) gen2drv,
                 mailbox #(transaction) gen2scb,
                 int cycles = 20);
        this.gen2drv    = gen2drv;
        this.gen2scb    = gen2scb;
        this.num_cycles = cycles;

        foreach (imem_mirror[i]) imem_mirror[i] = 32'h00000013;
        imem_mirror[ 0] = 32'h00000013;  // NOP
        imem_mirror[ 1] = 32'h00100093;  // addi x1,x0,1
        imem_mirror[ 2] = 32'h00200113;  // addi x2,x0,2
        imem_mirror[ 3] = 32'h00300193;  // addi x3,x0,3
        imem_mirror[ 4] = 32'h00400213;  // addi x4,x0,4
        imem_mirror[ 5] = 32'h00500293;  // addi x5,x0,5
        imem_mirror[ 6] = 32'h00A00313;  // addi x6,x0,10
        imem_mirror[ 7] = 32'h01400393;  // addi x7,x0,20
        imem_mirror[ 8] = 32'h06400413;  // addi x8,x0,100
        imem_mirror[ 9] = 32'h002081B3;  // add  x3,x1,x2
        imem_mirror[10] = 32'h00408493;  // addi x9,x1,4
        imem_mirror[11] = 32'h00810513;  // addi x10,x2,8
        imem_mirror[12] = 32'hFFF00593;  // addi x11,x0,-1
        imem_mirror[13] = 32'hFFE00613;  // addi x12,x0,-2
        imem_mirror[14] = 32'hFF808693;  // addi x13,x1,-8
        imem_mirror[15] = 32'h00302023;  // sw   x3,0(x0)
        imem_mirror[16] = 32'h00108713;  // addi x14,x1,1
        imem_mirror[17] = 32'h00210793;  // addi x15,x2,2
        imem_mirror[18] = 32'h7FF00813;  // addi x16,x0,2047
        imem_mirror[19] = 32'h80000893;  // addi x17,x0,-2048
    endfunction

    task run();
        transaction tr;
        bit [31:0] regs [32];
        foreach (regs[i]) regs[i] = 0;

        for (int cycle = 1; cycle <= num_cycles; cycle++) begin
            bit [31:0] instr_word;
            bit [4:0]  rs1, rd;
            bit [11:0] imm12;
            bit signed [31:0] imm_sext, rd1, result;

            instr_word = imem_mirror[cycle - 1];
            rs1        = instr_word[19:15];
            rd         = instr_word[11:7];
            imm12      = instr_word[31:20];
            imm_sext   = {{20{imm12[11]}}, imm12};
            rd1        = (rs1 != 0) ? regs[rs1] : 32'b0;
            result     = rd1 + imm_sext;

            if (rd != 0) regs[rd] = result;

            tr                     = new();
            tr.burst_id            = cycle;
            tr.observed_pc         = (cycle - 1) * 4;
            tr.expected_alu_result = result;
            tr.decode(instr_word);

            $display("[GENERATOR] BurstID=%0d | PC=%08h | INSTR=%h | rs1=x%0d rd=x%0d imm=%0d | ExpALU=%0d",
                     cycle, tr.observed_pc, instr_word, rs1, rd,
                     $signed(imm_sext), $signed(result));

            gen2drv.put(tr);
            gen2scb.put(tr);  // send expected directly to scoreboard
            #10;
        end
        $display("[GENERATOR] Done - %0d transactions queued.\n", num_cycles);
    endtask

endclass

// =============================================================================
// DRIVER — pacing only, displays what's being "processed" each cycle
// =============================================================================
class driver;

    mailbox #(transaction) gen2drv;
    virtual cpu_if         vif;

    function new(mailbox #(transaction) gen2drv, virtual cpu_if vif);
        this.gen2drv = gen2drv;
        this.vif     = vif;
    endfunction

    task run();
        transaction tr;
        forever begin
            gen2drv.get(tr);
            @(posedge vif.clk); #1;
            $display("[DRIVER]    BurstID=%0d | PC=%h | rs1=x%0d rd=x%0d ExpALU=%0d",
                     tr.burst_id, tr.observed_pc, tr.rs1, tr.rd,
                     $signed(tr.expected_alu_result));
        end
    endtask

endclass

// =============================================================================
// INPUT MONITOR — observes DUT inputs, display only
// =============================================================================
class input_monitor;

    virtual cpu_if vif;

    function new(virtual cpu_if vif);
        this.vif = vif;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk); #1;
            $display("[iMon]      PC=%h | INSTR=%h | rs1=x%0d rd=x%0d",
                     vif.pc, vif.instr,
                     vif.instr[19:15], vif.instr[11:7]);
        end
    endtask

endclass

// =============================================================================
// OUTPUT MONITOR — observes DUT outputs, sends to scoreboard
// =============================================================================
class output_monitor;

    mailbox #(transaction) omon2scb;
    virtual cpu_if         vif;

    function new(mailbox #(transaction) omon2scb, virtual cpu_if vif);
        this.omon2scb = omon2scb;
        this.vif      = vif;
    endfunction

    task run();
        transaction tr;
        forever begin
            @(posedge vif.clk); #2;
            tr                     = new();
            tr.observed_pc         = vif.pc;
            tr.observed_alu_result = vif.alu_result;
            tr.decode(vif.instr);

            $display("[oMon]      PC=%h | INSTR=%h | ALU_RESULT=%0d",
                     tr.observed_pc, tr.instr,
                     $signed(tr.observed_alu_result));

            omon2scb.put(tr);
        end
    endtask

endclass

// =============================================================================
// SCOREBOARD
// Gets expected from generator (gen2scb) and observed from oMon (omon2scb).
// Waits until observed PC matches expected PC before comparing.
// =============================================================================
class scoreboard;

    mailbox #(transaction) gen2scb;
    mailbox #(transaction) omon2scb;

    int pass_count = 0;
    int fail_count = 0;
    int total_count = 0;

    function new(mailbox #(transaction) g2s,
                 mailbox #(transaction) o2s);
        gen2scb  = g2s;
        omon2scb = o2s;
    endfunction

    task run();
        transaction exp_tr, act_tr;

        forever begin
            gen2scb.get(exp_tr);
            omon2scb.get(act_tr);

            total_count++;

            if (exp_tr.expected_alu_result == act_tr.observed_alu_result) begin
                pass_count++;
                $display("[SCB PASS] Exp=%0d Act=%0d",
                         $signed(exp_tr.expected_alu_result),
                         $signed(act_tr.observed_alu_result));
            end
            else begin
                fail_count++;
                $display("[SCB FAIL] Exp=%0d Act=%0d",
                         $signed(exp_tr.expected_alu_result),
                         $signed(act_tr.observed_alu_result));
            end
        end
    endtask


    function void report();
        $display("\n========================================");
        $display("  SCOREBOARD SUMMARY");
        $display("  PASS  : %0d", pass_count);
        $display("  FAIL  : %0d", fail_count);
        $display("  TOTAL : %0d", total_count);

        if (fail_count == 0)
            $display("  ** ALL TESTS PASSED **");
        else
            $display("  ** SOME TESTS FAILED **");

        $display("========================================\n");
    endfunction

endclass

// =============================================================================
// COVERAGE
// =============================================================================
class coverage;

    virtual cpu_if vif;

    covergroup cpu_cg @(posedge vif.clk);

        cp_opcode: coverpoint vif.instr[6:0] {
            bins nop_addi = {7'b0010011};
            bins r_type   = {7'b0110011};
            bins load     = {7'b0000011};
            bins store    = {7'b0100011};
            bins branch   = {7'b1100011};
            bins other    = default;
        }

        cp_funct3: coverpoint vif.instr[14:12] {
            bins f3_000 = {3'b000};
            bins f3_001 = {3'b001};
            bins f3_010 = {3'b010};
            bins f3_011 = {3'b011};
            bins f3_100 = {3'b100};
            bins f3_101 = {3'b101};
            bins f3_110 = {3'b110};
            bins f3_111 = {3'b111};
        }

        cp_rd: coverpoint vif.instr[11:7] {
            bins x0      = {0};
            bins x1_x7   = {[1:7]};
            bins x8_x15  = {[8:15]};
            bins x16_x31 = {[16:31]};
        }

        cp_rs1: coverpoint vif.instr[19:15] {
            bins x0      = {0};
            bins x1_x7   = {[1:7]};
            bins x8_x15  = {[8:15]};
            bins x16_x31 = {[16:31]};
        }

        cp_alu_result: coverpoint vif.alu_result {
            bins zero      = {32'h0};
            bins small_pos = {[32'h1      : 32'hFF]};
            bins large_pos = {[32'h100    : 32'h7FFFFFFF]};
            bins negative  = {[32'h80000000 : 32'hFFFFFFFF]};
        }

        cx_op_result: cross cp_opcode, cp_alu_result;

    endgroup

    function new(virtual cpu_if vif);
        this.vif = vif;
        cpu_cg   = new();
    endfunction

    function void report();
        $display("\n========================================");
        $display("  FUNCTIONAL COVERAGE REPORT");
        $display("  Overall   : %.2f%%", cpu_cg.get_coverage());
        $display("  cp_opcode : %.2f%%", cpu_cg.cp_opcode.get_coverage());
        $display("  cp_funct3 : %.2f%%", cpu_cg.cp_funct3.get_coverage());
        $display("  cp_rd     : %.2f%%", cpu_cg.cp_rd.get_coverage());
        $display("  cp_rs1    : %.2f%%", cpu_cg.cp_rs1.get_coverage());
        $display("  cp_alu_res: %.2f%%", cpu_cg.cp_alu_result.get_coverage());
        $display("========================================\n");
    endfunction

endclass

endpackage