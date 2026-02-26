# sim.do — executes after vsim loads
# All coverage exclude commands use -scope with full instance paths
# because -du alone does not match signals inside sub-instances.
#
# Instance hierarchy:
#   /tb_top/dut          = cpu_top
#   /tb_top/dut/u_pc     = pc
#   /tb_top/dut/u_regfile= regfile
#   /tb_top/dut/u_alu    = alu
#   /tb_top/dut/u_imem   = imem

# ============================================================
# W1: PC upper bits [31:7] — PC never exceeds 0x70
#     Also pc[1:0] — word-aligned, always 0
# ============================================================
foreach bit {31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 1 0} {
    coverage exclude -scope /tb_top/dut/u_pc      -togglenode "pc\[$bit\]"
    coverage exclude -scope /tb_top/dut           -togglenode "pc\[$bit\]"
}

# ============================================================
# W1: addr upper bits in imem — same as PC
# ============================================================
foreach bit {31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 1 0} {
    coverage exclude -scope /tb_top/dut/u_imem    -togglenode "addr\[$bit\]"
}

# ============================================================
# W3: rd2[31:3] — ALU uses imm not rd2, output unused
# ============================================================
foreach bit {31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3} {
    coverage exclude -scope /tb_top/dut/u_regfile -togglenode "rd2\[$bit\]"
    coverage exclude -scope /tb_top/dut           -togglenode "rd2\[$bit\]"
}

# ============================================================
# W4: a[31:12] — register values all fit in 12 bits (max 2047)
# ============================================================
foreach bit {31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12} {
    coverage exclude -scope /tb_top/dut/u_alu     -togglenode "a\[$bit\]"
}

# ============================================================
# W4: alu_op[3:2] — no ALU operation uses these bits
# ============================================================
coverage exclude -scope /tb_top/dut/u_alu  -togglenode {alu_op[3]}
coverage exclude -scope /tb_top/dut/u_alu  -togglenode {alu_op[2]}
coverage exclude -scope /tb_top/dut        -togglenode {alu_op[3]}
coverage exclude -scope /tb_top/dut        -togglenode {alu_op[2]}

# ============================================================
# W5: reset 0->1 — never re-asserted after startup
# ============================================================
coverage exclude -scope /tb_top/dut/u_pc      -togglenode {reset} -trans 01
coverage exclude -scope /tb_top/dut/u_regfile -togglenode {reset} -trans 01

# ============================================================
# W6: instr[3:0] — RISC-V ISA mandates opcode[1:0]=11
#     bits [3:0] are fixed by opcode and never toggle
# ============================================================
foreach bit {3 2 1 0} {
    coverage exclude -scope /tb_top/dut           -togglenode "instr\[$bit\]"
    coverage exclude -scope /tb_top/dut/u_imem    -togglenode "instr\[$bit\]"
}

# ============================================================
# W7: pc[14] 1->0 — PC is monotonically increasing, never decrements
# ============================================================
coverage exclude -scope /tb_top/dut           -togglenode {pc[14]} -trans 10
coverage exclude -scope /tb_top/dut/u_pc      -togglenode {pc[14]} -trans 10

# ============================================================
# W8: i[31:0] in regfile — loop counter for i=0..31
#     Only i[4:0] needed, all upper bits structurally 0
# ============================================================
foreach bit {31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0} {
    coverage exclude -scope /tb_top/dut/u_regfile -togglenode "i\[$bit\]"
}

# ============================================================
# W9: rd2[3] — no instruction uses rs2 in x8-x15 range
# ============================================================
coverage exclude -scope /tb_top/dut/u_regfile -togglenode {rd2[3]}
coverage exclude -scope /tb_top/dut           -togglenode {rd2[3]}

# ============================================================
# Run simulation and save reports
# ============================================================
add wave -r /*
run -all

coverage report -detail      -output code_coverage.txt
coverage report -detail -cvg -output functional_coverage.txt

echo "DONE. See code_coverage.txt and functional_coverage.txt"
