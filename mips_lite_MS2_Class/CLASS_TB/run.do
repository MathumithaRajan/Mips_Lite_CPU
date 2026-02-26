vdel -all
vlib work
vmap work work

# Compile RTL
vlog -sv -cover bcst ../rtl/alu.sv
vlog -sv -cover bcst ../rtl/pc.sv
vlog -sv -cover bcst ../rtl/regfile.sv
vlog -sv -cover bcst ../rtl/imem.sv
vlog -sv -cover bcst ../rtl/cpu_top.sv

# Compile TB
vlog -sv tb_pkg.sv
vlog -sv cpu_if.sv
vlog -sv tb_top.sv

# Simulate — hands off to sim.do for everything post-load
vsim -voptargs="+acc" -coverage -do sim.do work.tb_top
