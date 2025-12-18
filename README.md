# RISCV-5Stage-AXI4

## 📖 Overview
This repository contains the SystemVerilog RTL implementation of a **32-bit RISC-V processor** with a classical **5-stage pipeline architecture**, integrated with a custom **AXI4 (Advanced eXtensible Interface) bus system**.

The design supports **RV32IM** instruction sets (Integer + Multiplication) and features dynamic branch prediction, hazard handling, and a robust memory interface compliant with AMBA AXI4 protocols.

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
    * **SRAM Slaves & Bridge support INCR Burst transactions**.
    * Supports `WSTRB` (Write Strobe) for Byte/Half-word stores (`SB`, `SH`).

## 🏗️ System Architecture

```mermaid
graph TD
    subgraph "CPU Wrapper (Master)"
        CPU[RISC-V 5-Stage Core]
        M0[Master 0: Instruction]
        M1[Master 1: Data Load/Store]
        CPU --> M0
        CPU --> M1
    end

    subgraph "AXI Interconnect (Bus Matrix)"
        Arbiter[Round-Robin Arbiter]
        Decoder[Address Decoder]
        Crossbar[Read/Write Channels Crossbar]
        
        M0 ==> Crossbar
        M1 ==> Crossbar
        Crossbar -.-> Arbiter
        Crossbar -.-> Decoder
    end

    subgraph "Slaves (Memory Map)"
        S0[Slave 0: IM SRAM]
        S1[Slave 1: DM SRAM]
        SD[Default Slave]
        
        subgraph "Address: 0x0000_0000"
            S0
        end
        subgraph "Address: 0x0001_0000"
            S1
        end
        subgraph "Unmapped Address"
            SD
        end
    end

    Crossbar ==> S0
    Crossbar ==> S1
    Crossbar ==> SD

    style CPU fill:#f9f,stroke:#333,stroke-width:2px
    style Crossbar fill:#bbf,stroke:#333,stroke-width:2px
    style S0 fill:#dfd,stroke:#333,stroke-width:2px
    style S1 fill:#dfd,stroke:#333,stroke-width:2px
