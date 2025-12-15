# Complete CPI benchmark runner for Phase 5/6 comparison
Write-Host "=======================================================

" -ForegroundColor Cyan
Write-Host "   CS552 CPI Benchmark Suite - Phase 5 & 6" -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

$benchmarks = @("image_filter", "hash_lookup", "bubblesort_large", "matmul_4x4")
$results = @{}

# Check if benchmarks exist
$missingBenchmarks = @()
foreach ($bench in $benchmarks) {
    $hexFile = "benchmarks\$bench.hex"
    if (!(Test-Path $hexFile)) {
        $missingBenchmarks += $bench
    }
}

if ($missingBenchmarks.Count -gt 0) {
    Write-Host "⚠️  WARNING: Missing benchmark files!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Cannot find these benchmarks in D:\CS552\benchmarks\:" -ForegroundColor White
    foreach ($missing in $missingBenchmarks) {
        Write-Host "  ❌ $missing.hex" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "📁 Where to get them:" -ForegroundColor Cyan
    Write-Host "  1. Canvas → Files → Phase 6 benchmarks" -ForegroundColor White
    Write-Host "  2. Course website → Downloads" -ForegroundColor White
    Write-Host "  3. Ask TA for benchmark .hex files" -ForegroundColor White
    Write-Host "  4. Use autograder (it has benchmarks built-in)" -ForegroundColor White
    Write-Host ""
    Write-Host "OR: Test your processor with existing files:" -ForegroundColor Yellow
    Write-Host "    .\quick_cpi_test.ps1" -ForegroundColor Gray
    Write-Host ""
    exit 1
}

# Compile once
Write-Host "🔨 Compiling processor..." -NoNewline
Remove-Item -Recurse -Force work -ErrorAction SilentlyContinue
vlib work 2>&1 | Out-Null
vlog rtl/*.v 2>&1 | Out-Null
vlog tb/tb.v 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host " FAILED!" -ForegroundColor Red
    Write-Host "Check for compilation errors in your RTL files" -ForegroundColor Yellow
    exit 1
}
Write-Host " SUCCESS!" -ForegroundColor Green
Write-Host ""

# Run each benchmark
foreach ($bench in $benchmarks) {
    Write-Host "───────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "📊 Running: $bench" -ForegroundColor Cyan
    Write-Host "───────────────────────────────────────────────────" -ForegroundColor Gray
    
    $hexFile = "benchmarks\$bench.hex"
    Copy-Item $hexFile -Destination "program.mem" -Force
    
    Write-Host "   Simulating..." -NoNewline
    $output = vsim -c hart_tb -do "run 100000ns; quit -f" 2>&1
    
    # Parse results
    $pattern = '\[(\d+)\]\s+PC'
    $matches = [regex]::Matches($output -join "`n", $pattern)
    
    if ($matches.Count -gt 0) {
        $cycles = [int]$matches[$matches.Count - 1].Groups[1].Value
        $insts = $matches.Count
        $cpi = [math]::Round($cycles / $insts, 3)
        
        $results[$bench] = @{
            Cycles = $cycles
            Instructions = $insts
            CPI = $cpi
        }
        
        Write-Host " DONE" -ForegroundColor Green
        Write-Host "   Cycles: $cycles | Instructions: $insts | CPI: $cpi" -ForegroundColor White
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $results[$bench] = @{
            CPI = "N/A"
        }
    }
    Write-Host ""
}

# Generate table
Write-Host ""
Write-Host "=======================================================

" -ForegroundColor Cyan
Write-Host "              📊 CPI RESULTS TABLE" -ForegroundColor White
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

$phase6Values = @()
foreach ($bench in $benchmarks) {
    if ($results[$bench].CPI -ne "N/A") {
        $phase6Values += $results[$bench].CPI.ToString().PadLeft(12)
    } else {
        $phase6Values += "N/A".PadLeft(12)
    }
}

Write-Host "┌─────────────────────────┬──────────────┬──────────────┬──────────────────┬──────────────┐" -ForegroundColor White
Write-Host "│ CPI table               │ Image_filter │ hash_lookup  │ bubblesort_large │ matmul_4x4   │" -ForegroundColor White
Write-Host "├─────────────────────────┼──────────────┼──────────────┼──────────────────┼──────────────┤" -ForegroundColor White
Write-Host "│ Baseline without cache  │              │              │                  │              │" -ForegroundColor White
Write-Host "│ (phase 5)               │              │              │                  │              │" -ForegroundColor Gray
Write-Host "├─────────────────────────┼──────────────┼──────────────┼──────────────────┼──────────────┤" -ForegroundColor White
Write-Host ("│ Baseline with cache     │" + $phase6Values[0] + "│" + $phase6Values[1] + "│" + $phase6Values[2] + "│" + $phase6Values[3] + "│") -ForegroundColor Green
Write-Host "│ (phase 6)               │              │              │                  │              │" -ForegroundColor Gray
Write-Host "└─────────────────────────┴──────────────┴──────────────┴──────────────────┴──────────────┘" -ForegroundColor White
Write-Host ""

Write-Host "✅ Phase 6 (with cache) CPI values calculated!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 For Phase 5 values (without cache):" -ForegroundColor Yellow
Write-Host "   - Run these same benchmarks on your Phase 5 processor" -ForegroundColor White
Write-Host "   - OR use autograder Phase 5 results" -ForegroundColor White
Write-Host "   - OR ask your group (David/Blake/Matthew) if they have Phase 5 data" -ForegroundColor White
Write-Host ""

# Save to file
$tableFile = "cpi_results_phase6.txt"
$tableContent = @"
CPI RESULTS - Phase 6 (With Cache)
Generated: $(Get-Date)

Benchmark         | Cycles  | Instructions | CPI
------------------|---------|--------------|-------
"@

foreach ($bench in $benchmarks) {
    $benchPadded = $bench.PadRight(17)
    if ($results[$bench].CPI -ne "N/A") {
        $tableContent += "`n$benchPadded | $($results[$bench].Cycles.ToString().PadLeft(7)) | $($results[$bench].Instructions.ToString().PadLeft(12)) | $($results[$bench].CPI)"
    } else {
        $tableContent += "`n$benchPadded | N/A     | N/A          | N/A"
    }
}

$tableContent | Out-File $tableFile
Write-Host "💾 Results saved to: $tableFile" -ForegroundColor Cyan
Write-Host ""

