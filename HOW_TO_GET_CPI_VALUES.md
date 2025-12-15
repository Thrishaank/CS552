# 🎯 HOW TO GET YOUR CPI TABLE VALUES

## The Table You Need to Fill:

| CPI table                           | Image_filter | hash_lookup | bubblesort_large | matmul_4x4 |
|-------------------------------------|--------------|-------------|------------------|------------|
| Baseline without cache (phase 5)    |              |             |                  |            |
| Baseline with cache (phase 6)       |              |             |                  |            |

---

## 🚀 **THREE WAYS TO GET THESE VALUES:**

### **METHOD 1: Use Autograder** ⭐ EASIEST
If you submit to Gradescope/Canvas autograder:

1. **Submit your Phase 6 files** to autograder
2. **Autograder output** will show something like:
   ```
   Test: image_filter
   Cycles: 12450
   Instructions: 10234
   CPI: 1.22
   ✓ PASS
   ```
3. **Copy the CPI values** directly from autograder output
4. **Fill your table!**

**That's it!** Autograder has the benchmarks built-in.

---

### **METHOD 2: Get Benchmark Files from Course**
If you need to run locally:

#### Step 1: Find the Benchmark Files
Check these locations for `.hex` files:

**Canvas/Course Website:**
- Files → "Phase 6" or "Cache Project"
- Assignments → Phase 6 → Download materials
- Modules → Week X → Benchmark files

**GitLab/GitHub:**
- Course repository → `benchmarks/` folder
- Look for: `phase6_benchmarks.zip`

**Piazza/Ed Discussion:**
- Search for "benchmark" or "CPI testing"
- TAs often pin these resources

**Ask Your Group:**
- David, Blake, or Matthew might have them!

#### Step 2: Place Files Here
```
D:\CS552\benchmarks\
  - image_filter.hex
  - hash_lookup.hex
  - bubblesort_large.hex
  - matmul_4x4.hex
```

#### Step 3: Run My Script
```powershell
cd D:\CS552
.\run_all_cpi_tests.ps1
```

This will automatically fill your table!

---

### **METHOD 3: Use Existing Test Files**
If you can't find benchmarks, test with what you have:

```powershell
cd D:\CS552
.\quick_cpi_test.ps1
```

This uses `tests/prog.hex` to verify your processor calculates CPI correctly.

---

## 📊 **Understanding the Values**

### Phase 5 vs Phase 6

**Phase 5 (no cache):**
- Direct memory access
- Ideal pipeline: CPI ≈ 1.0
- With hazards: CPI ≈ 1.0-1.3

**Phase 6 (with cache):**
- Cache hits: Fast (like Phase 5)
- Cache misses: Slow (multiple cycles to fetch from memory)
- Expected CPI: 1.0-2.0 depending on program locality

### What Makes Good Results?

✅ **GOOD:**
- Phase 5: CPI = 1.05
- Phase 6: CPI = 1.12
- Cache working well, few misses!

✅ **ACCEPTABLE:**
- Phase 5: CPI = 1.20
- Phase 6: CPI = 1.50
- Cache has some misses, but functioning

❌ **BAD:**
- Phase 5: CPI = 1.05
- Phase 6: CPI = 5.20
- Cache is broken! (probably deadlock/stall issues)

---

## 🎓 **For Your Report**

After filling the table, add 2-3 sentences per benchmark:

### Example:
> **Image_filter:** Achieved CPI of 1.08 without cache and 1.15 with cache. 
> The slight increase is due to initial cold misses when loading image data. 
> Once cached, the program benefits from good spatial locality in the image array.

> **Hash_lookup:** CPI of 1.12 without cache and 1.35 with cache. 
> Hash lookups have poor spatial locality as they access random memory locations,
> leading to more cache misses than sequential access patterns.

---

## 🆘 **QUICKEST PATH TO COMPLETION:**

1. **Try autograder first** - Submit and get CPI values directly
2. **If no autograder** - Ask TA for benchmark files
3. **If stuck** - Use sample values and explain you couldn't access benchmarks

**Most important:** Your processor working > Exact benchmark numbers

---

## 📞 **Need Help?**

Run this to verify your processor works:
```powershell
cd D:\CS552
.\quick_cpi_test.ps1
```

If it shows "PROCESSOR WORKING", you're ready for benchmarks!

