# Class-based Testbench

Milestone 2

# Class-Based Verification Environment — Simple CPU Testbench

## Overview

This document describes the class-based SystemVerilog testbench developed to
verify a simple CPU RTL design. The CPU fetches instructions from an internal
instruction memory (imem), decodes them, and executes ALU operations using a
register file. The testbench follows a structured verification methodology
using Object-Oriented Programming (OOP) principles in SystemVerilog.

---

## DUT (Design Under Test) Summary

| Module       | Description                                      |
|--------------|--------------------------------------------------|
| `cpu_top`    | Top-level CPU wrapper                            |
| `pc`         | Program Counter — increments by 4 each cycle     |
| `imem`       | Instruction Memory — 256-entry ROM               |
| `regfile`    | 32-entry register file with write-back           |
| `alu`        | ALU — performs ADD (rd1 + sign_ext(imm))         |

**Key RTL behaviour:**
- The CPU self-fetches — PC drives imem, imem drives the instruction bus
- ALU is hardwired to ADD: `result = regs[rs1] + sign_extend(instr[31:20])`
- PC starts at 0 during reset; first observable PC post-reset is **4**

---

## Testbench Architecture

```
┌─────────────┐   gen2drv   ┌────────┐
│             │────────────►│ Driver │── display only
│  Generator  │             └────────┘
│             │   gen2scb   ┌─────────────┐
│  (expected) │────────────►│             │
└─────────────┘             │ Scoreboard  │──► PASS/FAIL
                            │             │
┌─────────────┐  omon2scb  │ (PC-matched)│
│Output Monitor│───────────►│             │
│   (oMon)    │             └─────────────┘
└─────────────┘
       ▲
       │ observes via hierarchical assigns
┌──────┴──────┐
│   cpu_top   │  (DUT)
│  (RTL)      │
└─────────────┘
       ▲
┌──────┴──────┐
│Input Monitor│── display only
│   (iMon)   │
└─────────────┘
```

---

## Testbench Components

### 1. Transaction (`transaction`)
The base data object passed between TB components.

| Field                  | Type        | Description                          |
|------------------------|-------------|--------------------------------------|
| `instr`                | bit [31:0]  | Full 32-bit instruction word         |
| `opcode`               | bit [6:0]   | Instruction opcode field             |
| `rs1`, `rd`            | bit [4:0]   | Source and destination registers     |
| `imm12`                | bit [11:0]  | 12-bit immediate field               |
| `observed_pc`          | bit [31:0]  | PC at which this transaction occurs  |
| `burst_id`             | int         | Transaction sequence number          |
| `expected_alu_result`  | bit [31:0]  | Reference model ALU output           |
| `observed_alu_result`  | bit [31:0]  | Actual DUT ALU output                |

---

### 2. Generator
- Mirrors the imem ROM contents internally
- Computes expected ALU results using a **reference register file model**
- Generates 19 transactions starting from **PC=4** (first observable post-reset PC)
- Sends each transaction to both `gen2drv` and `gen2scb` mailboxes

**Key design decision:** PC=0 (NOP during reset) is never observable by the
output monitor after reset deasserts, so generation starts from PC=4.

**Sample output:**
```
[GENERATOR] BurstID=1 | PC=00000004 | INSTR=00100093 | rs1=x0 rd=x1 imm=1 | ExpALU=1
```

---

### 3. Driver
- Receives transactions from the generator via `gen2drv`
- Waits for clock edge and displays transaction details
- **Does not drive DUT signals** — the CPU is self-fetching from internal imem

**Sample output:**
```
[DRIVER] BurstID=1 | PC=00000004 | rs1=x0 rd=x1 | ExpALU=1
```

---

### 4. Input Monitor (iMon)
- Samples `vif.pc` and `vif.instr` each clock cycle
- **Display only** — does not feed the scoreboard
- Provides visibility into what instructions the DUT is fetching

**Sample output:**
```
[iMon] PC=00000004 | INSTR=00100093 | rs1=x0 rd=x1
```

---

### 5. Output Monitor (oMon)
- Samples `vif.pc`, `vif.instr`, and `vif.alu_result` each clock cycle
- Sends observed transactions to scoreboard via `omon2scb` mailbox
- No reset gating — runs freely; stale entries handled by SCB PC-matching

**Sample output:**
```
[oMon] PC=00000004 | INSTR=00100093 | ALU_RESULT=1
```

---

### 6. Scoreboard
- Receives expected transactions from generator (`gen2scb`)
- Receives observed transactions from oMon (`omon2scb`)
- Uses PC-based matching: for each expected transaction, drains
  the oMon mailbox until `observed_pc === expected_pc`, then compares

```systemverilog
do begin
    omon2scb.get(obs_tr);
end while (obs_tr.observed_pc !== exp_tr.observed_pc);
```

This approach is **immune to timing offsets** between components — no
clock-edge counting, no reset synchronisation tricks needed.

**Sample output:**
```
[SCB] BurstID=1 | PASS | PC=00000004 | ALU=1 == Exp=1 | rd=x1
[SCB] BurstID=8 | PASS | PC=00000020 | ALU=100 == Exp=100 | rd=x8
```

---

### 7. Coverage (`coverage`)
Implements a SystemVerilog covergroup sampled on every positive clock edge.

| Coverpoint        | Description                              | Bins                                    |
|-------------------|------------------------------------------|-----------------------------------------|
| `cp_opcode`       | Instruction opcode field                 | OP-IMM, R-type, Load, Store, Branch     |
| `cp_funct3`       | ALU operation subtype                    | 8 bins (3'b000 to 3'b111)               |
| `cp_rd`           | Destination register range               | x0, x1-x7, x8-x15, x16-x31             |
| `cp_rs1`          | Source register range                    | x0, x1-x7, x8-x15, x16-x31             |
| `cp_alu_result`   | ALU result value range                   | zero, small_pos, large_pos, negative    |
| `cx_op_result`    | Cross: opcode × ALU result               | Combination coverage                    |

---

## Mailbox Connections

| Mailbox     | From        | To          | Purpose                          |
|-------------|-------------|-------------|----------------------------------|
| `gen2drv`   | Generator   | Driver      | Pacing and display               |
| `gen2scb`   | Generator   | Scoreboard  | Expected (reference) transactions|
| `omon2scb`  | oMon        | Scoreboard  | Observed DUT output transactions |

---

## Test Plan

| BurstID | PC     | Instruction           | ExpALU | Tests                        |
|---------|--------|-----------------------|--------|------------------------------|
| 1       | 0x0004 | addi x1, x0, 1        | 1      | Basic immediate add          |
| 2       | 0x0008 | addi x2, x0, 2        | 2      | Basic immediate add          |
| 3–8     | 0x000c–0x0020 | addi x3–x8, x0, n | 3–100 | Varied immediates            |
| 9       | 0x0024 | add x3, x1, x2        | 3      | Register-sourced operand     |
| 10–11   | 0x0028–0x002c | addi x9–x10, x1/x2, n | 5,10 | rs1 != x0             |
| 12–14   | 0x0030–0x0038 | addi x11–x13, x0/x1, neg | -1,-2,-7 | Negative immediates  |
| 15      | 0x003c | sw x3, 0(x0)          | 3      | Store-type instruction       |
| 16–17   | 0x0040–0x0044 | addi x14–x15, x1/x2, n | 2,4 | Mixed operands             |
| 18      | 0x0048 | addi x16, x0, 2047    | 2047   | Maximum positive immediate   |
| 19      | 0x004c | addi x17, x0, -2048   | -2048  | Minimum negative immediate   |

---

## Simulation Results

```
========================================
  SCOREBOARD SUMMARY
  PASS : 20
  FAIL : 0
  TOTAL: 20
  ** ALL TESTS PASSED **
========================================

========================================
  FUNCTIONAL COVERAGE REPORT
  Overall   : ~61%
  cp_opcode : 60%
  cp_rd     : 100%
  cp_alu_res: 100%
========================================
```

---

## File Structure

```
rtl/
  cpu_top.sv        — Top-level CPU
  alu.sv            — ALU module
  pc.sv             — Program Counter
  imem.sv           — Instruction Memory (ROM)
  regfile.sv        — Register File
  pipeline_regs.sv  — Pipeline registers (placeholder)

tb/
  cpu_if.sv         — SystemVerilog interface
  tb_pkg.sv         — All TB classes (Transaction, Generator, Driver,
                       iMon, oMon, Scoreboard, Coverage)
  tb_top.sv         — Top-level testbench module
  run.do            — QuestaSim compile and simulation script
```

---

## How to Run

```tcl
# In QuestaSim, from the tb/ directory:
do run.do
```

Coverage reports are saved to:
- `code_coverage.txt` — statement, branch, condition, toggle
- `functional_coverage.txt` — covergroup/coverpoint percentages

---

## Known Limitations and Waivers

| Item | Description | Waiver Reason |
|------|-------------|---------------|
| ALU hardwired to ADD | `cpu_top` always passes `4'b0000` to ALU | RTL milestone limitation; full decode planned in later milestones |
| PC=0 not verified | NOP at PC=0 executes only during reset | Post-reset PC starts at 4; reset behaviour verified by waveform inspection |
| `pipeline_regs.sv` empty | Pipeline registers are a placeholder | Single-cycle implementation; pipelining planned for later milestone |
| funct3 coverage ~25% | Only `3'b000` (ADD/ADDI) exercised | ALU hardwired to ADD; other funct3 values require decode logic in future RTL |