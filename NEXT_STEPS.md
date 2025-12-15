# 🎯 NEXT STEPS TO COMPLETE CPI TABLE

## Current Status ✅
- ✅ Processor compiles successfully
- ✅ Cache integration complete
- ✅ Pipeline working
- ✅ Automation scripts created
- ⏳ **NEED: Benchmark .hex files**

---

## 🚀 TO COMPLETE YOUR CPI TABLE:

### Option A: You Have Benchmark Files (5 minutes)
1. Copy your 4 benchmark .hex files to `D:\CS552\benchmarks\`:
   - `image_filter.hex`
   - `hash_lookup.hex`
   - `bubblesort_large.hex`
   - `matmul_4x4.hex`

2. Run the automated script:
   ```powershell
   cd D:\CS552
   .\run_cpi_benchmarks.ps1
   ```

3. Copy the CPI values into your table!

---

### Option B: Use Autograder (2 minutes)
1. Submit your RTL files to the autograder (Gradescope/Canvas)
2. Autograder runs the benchmarks and reports CPI
3. Copy the CPI values from autograder output
4. Fill your table manually

---

### Option C: Get Benchmarks from Course Resources
**Where to look:**
1. **Canvas** → Files → "Phase 6" or "Cache Project" → Look for .hex or .zip files
2. **Course GitHub/GitLab** → benchmarks/ folder
3. **Piazza/Discord** → Search for "benchmarks" or "CPI testing"
4. **Ask teammates** → David, Blake, Matthew might have them
5. **Email TA** → Ask for "Phase 6 CPI benchmark programs"

---

## 📊 What Your Table Should Look Like

```
+------------------------+---------------+---------------+------------------+--------------+
| CPI table              | Image_filter  | hash_lookup   | bubblesort_large | matmul_4x4   |
+------------------------+---------------+---------------+------------------+--------------+
| Baseline without       |               |               |                  |              |
| cache (phase 5)        | 1.05          | 1.12          | 1.08             | 1.15         |
+------------------------+---------------+---------------+------------------+--------------+
| Baseline with          |               |               |                  |              |
| cache (phase 6)        | 1.12          | 1.18          | 1.25             | 1.20         |
+------------------------+---------------+---------------+------------------+--------------+
```
*(Example values - yours will differ)*

---

## 🛠️ Scripts I Created For You

### 1. `run_cpi_benchmarks.ps1` - Full Automation
Runs all 4 benchmarks and generates table automatically.

### 2. `run_single_benchmark.ps1` - Test One Benchmark
```powershell
.\run_single_benchmark.ps1 -BenchmarkHex "benchmarks\image_filter.hex"
```

### 3. `README_CPI.md` - Detailed Instructions
Complete guide for CPI testing and troubleshooting.

### 4. `get_benchmarks.md` - Where to Find Benchmarks
All the places to look for benchmark files.

---

## ⚡ Quick Test (Once You Have Benchmarks)

```powershell
# Test with one benchmark
cd D:\CS552
.\run_single_benchmark.ps1 -BenchmarkHex "benchmarks\image_filter.hex"

# Should output:
# Total Cycles:       XXXX
# Instructions Retired: YYYY
# CPI:                Z.ZZ
```

---

## 🎓 For Your Report

Include in `baseline_report.pdf`:

1. **The CPI Table** (filled in with your values)

2. **Brief Analysis** (2-3 sentences per benchmark):
   ```
   Example:
   "Image_filter achieved CPI of 1.05 without cache and 1.12 with cache. 
   The slight increase is due to initial cold misses. The cache provides 
   good hit rates for the image processing loops due to spatial locality."
   ```

3. **Optional**: Waveform screenshots showing cache hits/misses

---

## 📞 Need Help?

1. **Can't find benchmarks?** 
   - Ask your group: David, Blake, Matthew
   - Check Canvas/Gradescope assignment files
   - Email TA

2. **Processor not working?**
   - Run: `.\run_single_benchmark.ps1 -BenchmarkHex "tests\prog.hex"`
   - Check output for errors

3. **CPI values seem wrong?**
   - Read `README_CPI.md` troubleshooting section
   - Check cache busy signals

---

## ✨ You're Almost Done!

Your processor is working! You just need:
1. Get the 4 benchmark .hex files
2. Run the automation script
3. Fill in the table
4. Submit!

**Good luck!** 🚀

