# ID/EX Pipeline Register Optimization

## Overview
The `id_ex_reg.v` module has been optimized based on the processor architecture diagram to reduce unnecessary signals and improve clarity while maintaining full functionality.

## Key Optimizations

### 1. **Removed Redundant Signals**
- **Removed `i_instruction` output**: The full 32-bit instruction doesn't need to propagate through EX stage
- **Removed instruction type flags** (`i_is_r`, `i_is_i`, `i_is_s`, `i_is_b`, `i_is_u`, `i_is_j`): These are only needed in decode stage, not execute

### 2. **Consolidated ALU Control Signals**
- **Combined into `i_alu_op [3:0]`**: Replaced separate signals:
  - `i_i_arith`
  - `i_i_unsigned`
  - `i_i_sub`
  - `i_i_opsel [2:0]`
- This 4-bit signal provides all necessary ALU operation encoding

### 3. **Consolidated Branch Control**
- **Replaced with `i_branch_type [3:0]`**: Replaced:
  - `i_check_lt_or_eq`
  - `i_branch_expect_n`
- Encodes branch comparison type: BEQ, BNE, BLT, BGE, BLTU, BGEU

### 4. **Improved Signal Organization**
Signals are now grouped by function:
- **Data path signals**: PC, PC+4, register data, immediate, addresses
- **Memory control**: Read/write enables, size, signedness
- **ALU control**: Operation code, special ops (AUIPC, LUI)
- **Branch/Jump control**: Branch/jump enables and types
- **Exception/Control**: Trap and halt flags

### 5. **Maintained Critical Features**
 Stall logic (holds values when `i_stall` asserted)
 Flush logic (clears pipeline bubble when `i_flush` asserted)
 Forwarding support (rs1/rs2/rd addresses available)
 All data path signals preserved
 Structural implementation with D flip-flops

## Signal Count Reduction
- **Before**: 47 input ports, 47 output ports
- **After**: 30 input ports, 30 output ports
- **Reduction**: ~36% fewer signals

## Benefits
1. **Simplified interface** - Easier to connect and maintain
2. **Reduced routing** - Fewer wires in FPGA implementation
3. **Better organization** - Logical grouping of related signals
4. **Same functionality** - No loss of features or capabilities
5. **Cleaner code** - Better documentation and readability

## Architecture Alignment
Based on the provided architecture diagram, the optimized register now contains exactly what the Execute stage needs:
- PC and PC+4 for address calculations
- Register data (Read Data 1 & 2) for ALU operations
- Immediate value for ALU operations
- Register addresses for forwarding unit
- Control signals for ALU, memory, and branching

## Migration Notes
When updating other modules that interface with `id_ex_reg`:
1. Update decode stage to generate `alu_op[3:0]` and `branch_type[2:0]`
2. Update execute stage to use consolidated control signals
3. Remove references to instruction type flags in execute stage
4. Update testbenches to match new port list
