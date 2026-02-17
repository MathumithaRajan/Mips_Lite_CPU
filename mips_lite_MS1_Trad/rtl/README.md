# RTL Sources

# RTL – MIPS-Lite 5-Stage In-Order CPU (Milestone 1)

This directory contains the initial RTL implementation for the MIPS-Lite
5-stage in-order CPU developed as part of ECE-593 (Fundamentals of
Pre-Silicon Validation).

The RTL at this milestone focuses on structural correctness, modularity,
and successful compilation, rather than full architectural completeness.

------------------------------

## Implemented Modules

### 1. cpu_top.sv
- Top-level module that instantiates and connects major datapath components.
- Acts as the DUT for simulation.
- Integrates PC, instruction memory, register file, ALU, and pipeline
  registers.
- Control logic is minimal and intended to support basic data flow only
  for Milestone 1.

### 2. pc.sv
- Implements the Program Counter register.
- Supports sequential PC update (PC + 4).
- No branch or jump redirection implemented at this stage.

### 3. imem.sv
- Simple instruction memory model.
- Provides instruction fetch based on PC value.
- Modeled as a ROM-like structure for simulation purposes.

### 4. regfile.sv
- 32-register file with:
  - Two read ports
  - One write port
- Supports synchronous write and combinational read.
- Register x0 is hardwired to zero (if applicable).

### 5. alu.sv
- Arithmetic Logic Unit supporting basic operations:
  - ADD
  - SUB
  - AND
  - OR
- Operation selection controlled via simple ALU control signals.

### 6. pipeline_regs.sv
- Defines pipeline registers between stages (IF/ID, ID/EX, EX/MEM, MEM/WB).
- Enables clean separation between pipeline stages.
- No stall or flush logic implemented at this milestone.

------------------------------

## Design Scope (Milestone 1)

### Included
- Modular RTL structure
- Basic datapath connectivity
- Clean compilation in QuestaSim
- Synthesizable SystemVerilog constructs

### Not Included (Planned for later milestones)
- Hazard detection and forwarding
- Branch decision logic
- Load/store memory functionality
- Full instruction decode and control FSM
- Performance optimizations

------------------------------

## Notes
- This RTL serves as a foundation for future milestones.
- Functional correctness beyond basic data flow is not guaranteed at this stage.
- Additional logic will be incrementally added and verified in later milestones.
