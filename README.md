# Parametrized Asynchronous (Dual-Clock) FIFO

An efficient, robust Verilog implementation of an Asynchronous (Dual-Clock) FIFO designed to safely transfer data packets across completely independent, non-synchronized clock domains (e.g., between a slower write-side processing core and a high-speed read-side peripheral). 

The design addresses critical clock-domain crossing (CDC) issues by employing Gray code pointer translations combined with multi-stage (2-FF) synchronizer chains to minimize metastability risks.

---

## 🚀 Key Features
- **True Dual-Clock Separation:** Completely independent `write_clk` and `read_clk` domains running at different frequencies.
- **Parametrized Dimensions:** Easily reconfigurable Data Width (`DWIDTH`) and Address Width/Depth (`AWIDTH` / `DEPTH = 2^AWIDTH`) via top-level parameter mappings.
- **Robust CDC Logic:** Incorporates binary-to-Gray conversions for pointer crossings to limit multi-bit glitching.
- **Advanced Flow Control:** Generates safe, pessimistic `full` (synchronized to write clock) and `empty` (synchronized to read clock) status flags to prevent data overwrites and underflows.
- **Comprehensive Verification Suite:** Includes a complete testbench testing edge-cases such as simultaneous R/W operations, pointer wrap-around boundaries, and uneven clock rates.

---

## 📂 Architecture Overview

The system architecture cleanly decouples memory operations from control logic to optimize synthesis pathing and static timing analysis (STA):

1. **`fifo_top.v`**: The parent wrapper coordinating clock domain boundaries and submodule interfaces.
2. **Dual-Port Memory Buffer**: An internal RAM structure accepting dual clock inputs to handle concurrent R/W indexing safely.
3. **2-FF Synchronizers**: Multi-stage flip-flop chains crossing pointers safely across the asynchronous boundaries.
4. **Read Pointer & Empty Logic Handler**: Synchronized to `read_clk`, handles binary reading steps and instant `empty` flag calculations.
5. **Write Pointer & Full Logic Handler**: Synchronized to `write_clk`, manages binary writing updates and instant `full` flag calculations.

---

## 🔧 Signal Definitions

| Port Signal | I/O | Width | Clock Domain | Description |
| :--- | :---: | :---: | :---: | :--- |
| `write_data` | Input | `[DWIDTH-1:0]` | `write_clk` | Data payload to be queued. |
| `write_enable`| Input | `1 bit` | `write_clk` | Asserts a data write operation. |
| `write_clk` | Input | `1 bit` | Native | Main clock driving the producer side (100 MHz default). |
| `write_reset` | Input | `1 bit` | `write_clk` | Reset line for write-domain logic. |
| `read_enable` | Input | `1 bit` | `read_clk` | Asserts a data read operation. |
| `read_clk` | Input | `1 bit` | Native | Main clock driving the consumer side (~143 MHz default). |
| `read_reset` | Input | `1 bit` | `read_clk` | Reset line for read-domain logic. |
| `read_data` | Output| `[DWIDTH-1:0]` | `read_clk` | Dequeued output data payload. |
| `empty` | Output| `1 bit` | `read_clk` | Status flag indicating FIFO is completely vacant. |
| `full` | Output| `1 bit` | `write_clk` | Status flag indicating FIFO storage limits reached. |

---

## 🔬 Testbench & Verification Scenarios

The accompanying testbench (`fifo_tb.v`) exercises the design through 13 separate verification phases, structured to handle extreme and average operations:

- **Test 1:** Cold reset verification (assuring baseline `empty=1`, `full=0` flags).
- **Test 2:** Spurious read protection on a vacant buffer.
- **Test 3:** Cross-domain propagation tracking over a single read/write cycle.
- **Test 4 & 5:** Filling the FIFO to full limits and enforcing safety write-inhibition checks during overflows.
- **Test 6:** Comprehensive drainage while ensuring strict First-In, First-Out (FIFO) ordering.
- **Test 7:** Concurrent Write and Read operations executing through a parallel `fork ... join` framework.
- **Test 8:** Multi-batch pointer wrap-around tracking (forcing binary counters to wrap beyond $2^{\text{AWIDTH}}$).
- **Test 9:** Asynchronous mid-operation hardware reset stress.
- **Test 10:** Multi-iteration randomized back-to-back burst stresses.
- **Test 11:** Edge boundary analysis (`DEPTH-1` to `DEPTH` flags conversion).
- **Test 12 & 13:** Asymmetric throughput stress testing (Slow Writer/Fast Reader and Fast Writer/Slow Reader sequences).

---

## 🛠 Simulation Workflow

### Prerequisites
Ensure you have an HDL Simulator installed (e.g., **Icarus Verilog**, **ModelSim**, **Vivado**, or **Verilator**), along with a waveform viewer like **GTKWave**.

### Running Simulation (Via Icarus Verilog Example)
1. Compile the source design structures and testbench together:
   ```bash
   iverilog -o fifo_sim fifo_tb.v fifo_top.v
