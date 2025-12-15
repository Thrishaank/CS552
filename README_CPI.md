# CPI Testing Guide for Phase 6

## Quick Start

### Step 1: Get Benchmark Files
You need 4 benchmark .hex files. **Where to find them:**

1. **Check course website** - Usually in "Phase 6" or "Cache Project" materials
2. **Check Gradescope/Canvas** - May be in assignment files
3. **Ask TA/Professor** - They should provide these benchmarks

Expected files:
- `image_filter.hex`
- `hash_lookup.hex`
- `bubblesort_large.hex`
- `matmul_4x4.hex`

### Step 2: Create Benchmarks Directory
```powershell
mkdir benchmarks
# Copy your 4 .hex files into this folder
```

### Step 3: Run Automated Testing
```powershell
# Run all benchmarks at once
.\run_cpi_benchmarks.ps1

# OR run one at a time
.\run_single_benchmark.ps1 -BenchmarkHex "benchmarks\image_filter.hex"
.\run_single_benchmark.ps1 -BenchmarkHex "benchmarks\hash_lookup.hex"
.\run_single_benchmark.ps1 -BenchmarkHex "benchmarks\bubblesort_large.hex"
.\run_single_benchmark.ps1 -BenchmarkHex "benchmarks\matmul_4x4.hex"
```

### Step 4: Fill the Table

The table you need to fill:

| CPI table              | Image_filter | hash_lookup | bubblesort_large | matmul_4x4 |
|------------------------|--------------|-------------|------------------|------------|
| Baseline without cache | _______      | _______     | _______          | _______    |
| Baseline with cache    | _______      | _______     | _______          | _______    |

**Notes:**
- **"Baseline without cache"** = Your Phase 5 processor (no cache)
- **"Baseline with cache"** = Your Phase 6 processor (with cache)

## Manual CPI Calculation

If you need to calculate CPI manually from simulation output:

```
CPI = Total Cycles / Instructions Retired
```

### Example from Simulation Output

If your simulation shows:
```
[100] PC=0x00000080 INST=0x00100093
[102] PC=0x00000084 INST=0x00200113
[105] PC=0x00000088 INST=0x00300193
...
[5420] PC=0x000001fc INST=0x00000013
```

Then:
- **Total Instructions** = Number of lines with `[cycle]` = 50 (for example)
- **Total Cycles** = Last cycle number = 5420
- **CPI** = 5420 / 50 = 108.4

## Understanding Your Results

### Good Results
- **Phase 5 (no cache)**: CPI close to 1.0 means excellent pipelining
- **Phase 6 (with cache)**: 
  - CPI similar to Phase 5 = cache is working well!
  - CPI slightly higher = acceptable (cache misses are expected)

### Bad Results
- **CPI >> 2.0**: Check for:
  - Cache deadlocks (o_busy stuck high)
  - Incorrect stall logic
  - Memory arbiter issues

### Comparing Phase 5 vs Phase 6
- **Programs with good locality**: Phase 6 should be similar or slightly better
- **Programs with poor locality**: Phase 6 might be worse (cache thrashing)

## Troubleshooting

### "No instruction retirements detected"
- Processor is stalled indefinitely
- Check: `icache_busy`, `dcache_busy` signals
- Common cause: `o_busy` stuck high in cache.v

### "CPI value is invalid" (from autograder)
- Instructions not retiring properly
- Check: `valid` signal propagation through pipeline
- Check: Reset logic in all pipeline registers

### Simulation runs forever
- Infinite loop in program (expected for some benchmarks)
- Increase `-MaxCycles` parameter: `.\run_single_benchmark.ps1 -MaxCycles 500000`
- Or use `halt` instruction to stop properly

## What to Submit

Create `baseline_report.pdf` with:
1. **CPI Table** (filled in)
2. **Brief explanation** of results (2-3 sentences per benchmark)
3. **Optional**: Waveforms showing cache hits/misses

Example explanation:
> *Image_filter shows CPI of 1.05 without cache and 1.12 with cache. The slight increase is due to initial cold misses when loading the image data into cache. Once data is cached, the program benefits from spatial locality.*

Good luck! 🚀

