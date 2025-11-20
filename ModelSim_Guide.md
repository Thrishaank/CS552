# ModelSim Simulation Guide for HART Processor

This guide explains how to run your HART processor design in ModelSim with comprehensive waveform monitoring.

## Quick Start

### Option 1: Automated Script (Recommended)
1. Open Command Prompt/PowerShell
2. Navigate to your project directory: `cd d:\CS552`
3. Run: `run_modelsim.bat`

### Option 2: ModelSim GUI
1. Open ModelSim
2. Navigate to File -> Change Directory -> d:\CS552
3. In ModelSim console, type: `do modelsim_script.do`

### Option 3: Manual Setup
1. Open ModelSim  
2. Navigate to File -> Change Directory -> d:\CS552
3. In ModelSim console, type: `do simple_setup.do`
4. Add additional waves as needed
5. Type: `run -all`

## What the Script Does

1. **Compiles all RTL files** in proper dependency order:
   - Basic components (d_ff.v, rf.v, imm.v, alu.v)
   - Pipeline registers (if_id_reg.v, id_ex_reg.v, ex_mem_reg.v, mem_wb_reg.v)
   - Pipeline stages (fetch.v, decode.v, execute.v, memory.v, writeback.v)
   - Top module (hart.v)
   - Testbench (tb.v)

2. **Sets up comprehensive waveforms** organized in groups:
   - **Clock & Reset**: Basic timing signals
   - **Instruction Memory**: PC and instruction fetch
   - **Data Memory**: Load/store operations  
   - **Retire**: Instruction completion and PC tracking
   - **Register Access**: Register file reads/writes
   - **Pipeline Stages**: IF/ID, ID/EX, EX/MEM, MEM/WB signals
   - **Control**: Decode unit control signals
   - **ALU**: Arithmetic logic unit inputs/outputs
   - **Registers x0-x15**: First 16 register values

3. **Runs the simulation** until the program halts

## Monitoring Your Design

### Key Signals to Watch:
- **pc**: Current program counter
- **inst**: Current instruction being retired
- **valid**: Instruction retirement valid signal
- **halt**: Program completion signal
- **Register values**: Monitor x0-x15 for data flow
- **Pipeline stages**: Track instruction flow through pipeline

### Adding Custom Waves:
```tcl
# Add specific register
add wave -hex sim:/hart_tb/dut/rf/mem(10)  # Register x10 (a0)

# Add internal signals
add wave sim:/hart_tb/dut/some_internal_signal

# Add entire bus
add wave -hex sim:/hart_tb/dut/pipeline_signal[31:0]
```

### Useful ModelSim Commands:
```tcl
run -all                    # Run until $finish
run 1000ns                  # Run for specific time
wave zoom full              # Zoom to see all simulation time
wave zoom range 0ns 500ns   # Zoom to specific time range
restart -force              # Restart simulation
```

## Troubleshooting

### Common Issues:

1. **"vsim command not found"**
   - Add ModelSim to your PATH
   - Typical location: `C:\intelFPGA\20.1\modelsim_ase\win32aloem`

2. **Compilation errors**
   - Check that all .v files are present in rtl/ directory
   - Verify no syntax errors in your Verilog code

3. **"program.mem not found"** 
   - Ensure program.mem is in the tb/ folder
   - The script automatically copies it to the working directory

4. **Simulation doesn't start**
   - Check that hart_tb module is properly compiled
   - Verify testbench instantiation matches hart module ports

### Debugging Your Processor:
- Watch the **pc** signal to track instruction execution
- Monitor **Register Access** group to see data flow
- Check **Pipeline Stages** for proper instruction flow  
- Use **Control** signals to verify decode logic
- Watch **ALU** group for arithmetic operations

## Program Loading
The testbench loads `program.mem` from the tb/ directory. This should contain your RISC-V program in hexadecimal format, with each line containing 4 bytes of instruction data.

## Expected Output
The simulation will display cycle-by-cycle execution information and halt when the program completes. Final register values will be displayed, particularly the result in register a0 (x10).