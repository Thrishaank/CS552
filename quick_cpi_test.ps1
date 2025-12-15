# Quick CPI test with existing program
Write-Host "=== Quick CPI Test ===" -ForegroundColor Cyan
Write-Host "This tests CPI calculation with your existing test program" -ForegroundColor White
Write-Host ""

# Use existing test file
if (Test-Path "tests\prog.hex") {
    Copy-Item "tests\prog.hex" -Destination "program.mem" -Force
    Write-Host "Using: tests\prog.hex" -ForegroundColor Green
} elseif (Test-Path "program.mem") {
    Write-Host "Using: existing program.mem" -ForegroundColor Green
} else {
    Write-Host "ERROR: No test program found!" -ForegroundColor Red
    exit 1
}

# Compile
Write-Host ""
Write-Host "Compiling..." -NoNewline
Remove-Item -Recurse -Force work -ErrorAction SilentlyContinue
vlib work 2>&1 | Out-Null
vlog rtl/*.v 2>&1 | Out-Null
vlog tb/tb.v 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host " FAILED!" -ForegroundColor Red
    exit 1
}
Write-Host " SUCCESS!" -ForegroundColor Green

# Run simulation
Write-Host "Running simulation..." -ForegroundColor Yellow
$output = vsim -c hart_tb -do "run 10000ns; quit -f" 2>&1

# Count retirements - look for pattern like: [cycle] PC=... INST=...
$pattern = '\[(\d+)\]\s+PC'
$matches = [regex]::Matches($output -join "`n", $pattern)

Write-Host ""
if ($matches.Count -gt 0) {
    $lastCycle = [int]$matches[$matches.Count - 1].Groups[1].Value
    $instructions = $matches.Count
    $cpi = [math]::Round($lastCycle / $instructions, 2)
    
    Write-Host "=== RESULTS ===" -ForegroundColor Cyan
    Write-Host "✅ Processor is working!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Total Cycles:         $lastCycle" -ForegroundColor White
    Write-Host "Instructions Retired: $instructions" -ForegroundColor White
    Write-Host "CPI:                  $cpi" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This means your processor can calculate CPI!" -ForegroundColor Green
    Write-Host "Now you need the 4 benchmark .hex files to fill your table." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "📋 Next steps:" -ForegroundColor Cyan
    Write-Host "1. Get benchmarks from course website/autograder" -ForegroundColor White
    Write-Host "2. Put them in:  D:\CS552\benchmarks\" -ForegroundColor White
    Write-Host "3. Run:          .\run_all_cpi_tests.ps1" -ForegroundColor White
    
} else {
    Write-Host "❌ No instruction retirements detected" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "- Processor stuck in stall" -ForegroundColor White
    Write-Host "- Cache busy signal stuck high" -ForegroundColor White
    Write-Host "- Pipeline not advancing" -ForegroundColor White
}

Write-Host ""

