# Traditional Testbench

# Traditional Testbench – Milestone 1

This directory contains a simple, traditional (non-UVM) SystemVerilog
testbench used to validate basic functionality of the MIPS-Lite CPU RTL
for Milestone 1.

The goal of this testbench is to ensure successful compilation,
simulation, and basic data flow through the design.

---

## Testbench Overview

### tb_cpu_top.sv
- Top-level testbench module for the DUT (`cpu_top`).
- Instantiates the CPU and provides:
  - Clock generation
  - Reset sequencing
- Does not use classes, interfaces, or constrained-random stimulus.

---------------

## What This Testbench Verifies (Milestone 1)

### ✔ Basic Checks
- DUT instantiation without errors
- Clock toggling and reset behavior
- Program Counter updates on clock edges
- Instruction fetch from instruction memory
- Basic ALU data propagation
- Register file read/write visibility

### ✔ Simulation Infrastructure
- RTL and TB compile successfully in QuestaSim
- Simulation can be run using an automated `run.do` script
- Waveforms can be observed for internal signals

---------------

## What This Testbench Does NOT Verify

- Pipeline hazards (data/control hazards)
- Load-use stalls or forwarding
- Branch correctness
- Instruction-level architectural correctness
- Randomized or stress testing

These features are intentionally deferred to later milestones.

---------------

## How to Run the Testbench

From the `TRAD_TB` directory in QuestaSim:

```tcl
do run.do

