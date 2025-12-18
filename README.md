# RISC-V 32-bit 5-Stage Pipelined CPU with AXI4 Interconnect

## 📖 Overview
This project implements a **32-bit RISC-V processor** with a classical **5-stage pipeline architecture**, integrated with a custom **AXI4 (Advanced eXtensible Interface) bus system**. The design supports **RV32IM** instruction sets (Integer + Multiplication) and features dynamic branch prediction, hazard handling, and a robust memory interface compliant with AMBA AXI4 protocols.

The system is verified using both directed assembly tests (sorting, GCD, etc.) and **JasperGold Verification IP (VIP)** to ensure protocol compliance for the AXI Bridge, Master, and Slave interfaces.

## 🚀 Key Features

### Processor Core (CPU)
* **Architecture**: 5-Stage Pipeline (IF, ID, EX, MEM, WB).
* **ISA Support**: RV32I Base Integer Instruction Set + M-Extension (Multiplication).
* **Hazard Handling**:
    * **Forwarding Unit**: Solves data hazards (Read-After-Write) by forwarding data from EX/MEM and MEM/WB stages.
    * **Hazard Detection Unit**: Handles Load-Use hazards (Stall) and Control hazards (Flush).
* **Branch Prediction**:
    * **Dynamic Prediction**: Implemented a **2-bit Saturating Counter** Branch History Table (BHT).
    * Handles branch resolution in the EX stage with auto-flush on misprediction.
* **CSR Support**: Implemented `cycle`, `instret` hardware counters and related CSR instructions (`csrr`, `csrw`).

### AXI4 Interconnect & Memory Subsystem
* **Topology**: 
    * **2 Masters**: Instruction Fetch (Read-only), Load/Store Unit (Read/Write).
    * **2 Slaves**: Instruction Memory (IM), Data Memory (DM).
    * **Default Slave**: Handles address decoding errors (DECERR).
* **Protocol**: AMBA AXI4 (Simplified).
* **Arbitration**: **Round-Robin Arbiter** to manage bus contention between Instruction and Data masters.
* **Burst Mode**:
    * Masters initiate Single transfers.
    * **SRAM Slaves & Bridge support INCR Burst transactions** (Verified via VIP).
    * Supports `WSTRB` (Write Strobe) for Byte/Half-word stores (`SB`, `SH`).

## 📂 File Structure

```text
.
├── src/
│   ├── top.sv                 # Top-level module integrating CPU, AXI, and SRAMs
│   ├── CPU.sv                 # 5-stage pipeline integration
│   ├── Controller.sv          # Main control unit (Opcode decoder)
│   ├── Instruction_Decoder.sv # Decoder for ALU control, ImmGen, and CSRs
│   ├── ALU.sv                 # Arithmetic Logic Unit (includes M-extension)
│   ├── BranchPredictor.sv     # 2-bit saturating counter predictor
│   ├── Hazard.sv              # Hazard detection unit
│   ├── Forwarding.sv          # Data forwarding unit
│   ├── AXI.sv                 # AXI4 Interconnect (Bridge/Crossbar)
│   ├── Arbiter.sv             # Round-Robin Arbiter for AXI masters
│   ├── SRAM_wrapper.sv        # AXI-compliant SRAM controller (supports Burst)
│   └── ...
├── include/
│   └── AXI_define.svh         # AXI4 parameter definitions
├── sim/                       # Testbenches and test programs
└── script/                    # Synthesis scripts