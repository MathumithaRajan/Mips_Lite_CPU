# =============================================================================
# run.do — QuestaSim 10.6c compile & simulate script
# =============================================================================

if {[file exists work]} {
    vdel -lib work -all
}
vlib work
vmap work work

# =============================================================================
# Step 1: Compile RTL with coverage instrumentation (+cover)
# =============================================================================
vlog -sv -work work +cover ../rtl/alu.sv
vlog -sv -work work +cover ../rtl/regfile.sv
vlog -sv -work work +cover ../rtl/pc.sv
vlog -sv -work work +cover ../rtl/pipeline_regs.sv
vlog -sv -work work +cover ../rtl/imem.sv
vlog -sv -work work +cover ../rtl/cpu_top.sv

# =============================================================================
# Step 2: Compile Interface
# =============================================================================
vlog -sv -work work cpu_if.sv

# =============================================================================
# Step 3: Compile TB Package
# =============================================================================
vlog -sv -work work tb_pkg.sv

# =============================================================================
# Step 4: Compile Top
# =============================================================================
vlog -sv -work work tb_top.sv

# =============================================================================
# Step 5: Simulate with coverage
# =============================================================================
vsim -voptargs="+acc" -coverage work.tb_top

# =============================================================================
# Step 6: Waveforms (simple labels — no special characters)
# =============================================================================
add wave -divider "CLOCK RESET"
add wave /tb_top/clk
add wave /tb_top/intf/reset

add wave -divider "CPU SIGNALS"
add wave -radix hex     /tb_top/intf/pc
add wave -radix hex     /tb_top/intf/instr
add wave -radix decimal /tb_top/intf/alu_result
add wave               /tb_top/intf/reg_write_en

# =============================================================================
# Step 7: Run simulation
# =============================================================================
run -all

# =============================================================================
# Step 8: Coverage reports
# =============================================================================
coverage save coverage.ucdb
coverage report -code sbct -details -output code_coverage.txt
coverage report -cvg  -details -output functional_coverage.txt

echo "DONE. See code_coverage.txt and functional_coverage.txt"
