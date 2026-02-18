# ================================
# MS1d run.do
# Simple simulation script for MIPS-Lite CPU
# ================================


# =========================
# Clean & create library
# =========================
if {[file exists work]} {
    vdel -lib work -all
}
vlib work

# =========================
# Compile RTL
# =========================
vlog -sv ../rtl/*.sv

# =========================
# Compile Testbench
# =========================
vlog -sv tb_cpu_top.sv

# =========================
# Simulate
# =========================
vsim -voptargs=+acc work.tb_cpu_top

# =========================
# Add waves 
# =========================
add wave -r sim:/tb_cpu_top/*

# =========================
# Run
# =========================
run -all


