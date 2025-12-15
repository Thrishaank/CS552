# CS552 Phase 6 CPI Benchmarks Setup

## Required Benchmark Files

You need these 4 benchmark programs in `.hex` format:

1. **image_filter.hex** - Image filtering algorithm
2. **hash_lookup.hex** - Hash table lookup operations
3. **bubblesort_large.hex** - Bubble sort on large array
4. **matmul_4x4.hex** - 4x4 matrix multiplication

## Where to Get Benchmarks

### Option 1: Course Resources
Check your course website/Canvas for "Phase 6 Benchmarks" or "Cache Testing Benchmarks"

### Option 2: Autograder
If you use an autograder (like Gradescope), the benchmarks might be built-in.
You just submit your RTL files and it runs them.

### Option 3: Create Benchmarks Directory
Once you have the .hex files, place them in:
```
D:\CS552\benchmarks\
  - image_filter.hex
  - hash_lookup.hex
  - bubblesort_large.hex
  - matmul_4x4.hex
```

## Next Steps

1. **If you have benchmark .hex files**:
   - Create `D:\CS552\benchmarks\` folder
   - Copy the 4 .hex files there
   - Run: `.\run_cpi_benchmarks.ps1`

2. **If you use autograder**:
   - Submit your RTL files to the autograder
   - Copy the CPI values from autograder output
   - Fill the table manually

3. **If you need to create benchmarks**:
   - You'll need the .S (assembly) or .c (C) source files
   - Compile them with RISC-V toolchain
   - Convert to .hex format

## Automated CPI Testing

I've created scripts for you:

### PowerShell Script (Recommended for Windows)
```powershell
.\run_cpi_benchmarks.ps1
```

This will:
- Compile your processor
- Run all 4 benchmarks
- Extract cycle counts and instruction counts
- Generate CPI table automatically

### Manual Testing
For each benchmark:
```powershell
# Copy benchmark to program.mem
Copy-Item benchmarks\image_filter.hex -Destination program.mem

# Compile and run
vlib work
vlog rtl/*.v
vlog tb/tb.v
vsim -c hart_tb -do "run 100000ns; quit -f"

# Count cycles and instructions from output
# CPI = Total_Cycles / Instructions_Retired
```

## Expected CPI Values

Typical ranges (for reference):
- **Without cache (Phase 5)**: CPI ≈ 1.0 - 1.3 (ideal pipeline)
- **With cache (Phase 6)**: 
  - Good locality: CPI ≈ 1.0 - 1.5
  - Poor locality: CPI ≈ 2.0 - 5.0+

Your goal: Show that cache improves (or maintains) CPI for programs with good locality!

