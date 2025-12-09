# FPGA Testing Guide for Pipelined RISC-V Processor

## Overview
This guide explains how to test your pipelined RISC-V processor on the DE1-SoC FPGA board using the factorial calculation program.

## Hardware Setup

### Board Inputs
- **CLOCK_50**: 50 MHz system clock (automatically connected)
- **KEY[0]**: Reset button (active low) - Press to reset processor
- **SW[9:8]**: Display mode selection switches
- **SW[7:0]**: Unused (available for future expansion)

### Board Outputs
- **LEDR[9:0]**: 10 red LEDs for displaying results

## LED Display Modes

Control what's displayed on the LEDs using switches SW[9:8]:

### Mode 00 (SW[9]=0, SW[8]=0): **Factorial Result Display**
- Shows the lower 10 bits of register x11 (a1) when it's written
- For factorial of 5: Result = 120 = 0x078
- LEDs will show: 0001111000 (binary) = 120 (decimal)

### Mode 01 (SW[9]=0, SW[8]=1): **Status Display**
- LED[0]: retire_valid (1 = instruction retired this cycle)
- LED[1]: retire_trap (1 = trap occurred)
- LED[2]: retire_halt (1 = processor halted)
- LED[9:3]: Unused (0)

### Mode 10 (SW[9]=1, SW[8]=0): **Program Counter Display**
- Shows lower 10 bits of current PC
- Useful for debugging program execution

### Mode 11 (SW[9]=1, SW[8]=1): **Register Write Display**
- LED[9]: retire_valid
- LED[8:4]: rd_waddr (destination register being written)
- LED[3:0]: Unused (0)

## Testing the Factorial Program

### Expected Behavior

1. **Compile and Load**:
   ```bash
   # Assemble the program
   riscv32-unknown-elf-as -march=rv32i -mabi=ilp32 -o factorial.o tests/factorial.S
   riscv32-unknown-elf-ld -T linker.ld -o factorial.elf factorial.o
   riscv32-unknown-elf-objcopy -O binary factorial.elf factorial.bin
   
   # Convert to hex format for FPGA
   od -An -tx1 -w1 -v factorial.bin | awk '{print $1}' > tb/program.mem
   ```

2. **Set Display Mode**:
   - Set SW[9:8] = 00 to view factorial result

3. **Reset and Run**:
   - Press KEY[0] to reset the processor
   - Release KEY[0] to start execution
   - Program will calculate 5! = 120
   - Result appears on LEDs when x11 is written

4. **Verify Results**:
   - **5! = 120 = 0x78 = 0b0001111000**
   - LEDs should light up as: `0001111000`
   - From right to left: OFF OFF OFF ON ON ON ON ON OFF OFF

### Testing Other Display Modes

1. **Mode 01 (Status)**:
   - While program runs, LED[0] should blink (retire_valid)
   - When done, LED[2] should stay lit (halt)
   - LED[1] should stay off (no traps)

2. **Mode 10 (PC)**:
   - LEDs will show changing PC values as program executes
   - Eventually stabilizes at "done" loop address

3. **Mode 11 (Register Writes)**:
   - Shows which registers are being written
   - LED[9] blinks when instructions retire
   - LED[8:4] shows register numbers (watch for x11 = 01011)

## Pin Assignments for DE1-SoC

You'll need to add these to your `.qsf` file:

```tcl
# Clock
set_location_assignment PIN_AF14 -to CLOCK_50

# Keys (Reset)
set_location_assignment PIN_AA14 -to KEY[0]
set_location_assignment PIN_AA15 -to KEY[1]
set_location_assignment PIN_W15 -to KEY[2]
set_location_assignment PIN_Y16 -to KEY[3]

# Switches
set_location_assignment PIN_AB12 -to SW[0]
set_location_assignment PIN_AC12 -to SW[1]
set_location_assignment PIN_AF9 -to SW[2]
set_location_assignment PIN_AF10 -to SW[3]
set_location_assignment PIN_AD11 -to SW[4]
set_location_assignment PIN_AD12 -to SW[5]
set_location_assignment PIN_AE11 -to SW[6]
set_location_assignment PIN_AC9 -to SW[7]
set_location_assignment PIN_AD10 -to SW[8]
set_location_assignment PIN_AE12 -to SW[9]

# LEDs
set_location_assignment PIN_V16 -to LEDR[0]
set_location_assignment PIN_W16 -to LEDR[1]
set_location_assignment PIN_V17 -to LEDR[2]
set_location_assignment PIN_V18 -to LEDR[3]
set_location_assignment PIN_W17 -to LEDR[4]
set_location_assignment PIN_W19 -to LEDR[5]
set_location_assignment PIN_Y19 -to LEDR[6]
set_location_assignment PIN_W20 -to LEDR[7]
set_location_assignment PIN_W21 -to LEDR[8]
set_location_assignment PIN_Y21 -to LEDR[9]
```

## Troubleshooting

### LEDs show all zeros
- Check reset: Press and release KEY[0]
- Verify program.mem is loaded correctly
- Check display mode switches (should be 00 for result)

### LEDs show unexpected pattern
- Verify factorial calculation in simulation first
- Check if processor trapped (Mode 01, LED[1])
- Monitor PC to see if program is executing (Mode 10)

### Program doesn't start
- Hold KEY[0] for reset, then release
- Check CLOCK_50 connection
- Verify synthesis completed without errors

## Memory Layout

- **Instruction Memory (IMEM)**: 0x0000_0000 - 0x0000_0FFF (4KB)
- **Data Memory (DMEM)**: 0x0000_0000 - 0x0000_0FFF (4KB)
- Both memories are 1024 words (32-bit)

## Program Execution Flow

1. Initialize: a0=5, a1=1
2. Loop 5 times:
   - Multiply a1 by a0 (shift-and-add algorithm)
   - Decrement a0
3. Final result in a1 = 120
4. Infinite loop at "done" to maintain display

## Expected LED Patterns

When calculating 5! with SW[9:8]=00:

| Step | a0 | a1 | LED Pattern (binary) | LED (decimal) |
|------|----|----|---------------------|---------------|
| Init | 5  | 1  | 0000000001         | 1             |
| 1st  | 4  | 5  | 0000000101         | 5             |
| 2nd  | 3  | 20 | 0000010100         | 20            |
| 3rd  | 2  | 60 | 0000111100         | 60            |
| 4th  | 1  | 120| 0001111000         | 120           |
| Done | 0  | 120| 0001111000         | 120           |
