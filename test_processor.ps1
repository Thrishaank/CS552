# Quick processor test script
Write-Host "=== CS552 Processor Quick Test ===" -ForegroundColor Cyan
Write-Host ""

# Check if program.mem exists
if (!(Test-Path "program.mem")) {
    Write-Host "WARNING: program.mem not found. Using test program..." -ForegroundColor Yellow
    if (Test-Path "tests\prog.hex") {
        Copy-Item "tests\prog.hex" -Destination "program.mem"
    } else {
        Write-Host "ERROR: No test program available!" -ForegroundColor Red
        exit 1
    }
}

Write-Host "Compiling processor..." -NoNewline
Remove-Item -Recurse -Force work -ErrorAction SilentlyContinue
vlib work 2>&1 | Out-Null
vlog rtl/*.v 2>&1 | Out-Null
vlog tb/tb.v 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host " FAILED!" -ForegroundColor Red
    Write-Host "Check for syntax errors in RTL files" -ForegroundColor Yellow
    exit 1
}

Write-Host " SUCCESS!" -ForegroundColor Green

Write-Host "Running simulation..." -ForegroundColor Yellow
$output = vsim -c hart_tb -do "run 5000ns; quit -f" 2>&1

# Check for instruction retirements
$retirements = [regex]::Matches($output, '\[(\d+)\]')

if ($retirements.Count -gt 0) {
    Write-Host ""
    Write-Host "✅ PROCESSOR WORKING!" -ForegroundColor Green
    Write-Host "   Instructions retired: $($retirements.Count)" -ForegroundColor White
    Write-Host "   Last cycle: $($retirements[$retirements.Count-1].Groups[1].Value)" -ForegroundColor White
    
    # Calculate CPI
    $cycles = [int]$retirements[$retirements.Count-1].Groups[1].Value
    $insts = $retirements.Count
    $cpi = [math]::Round($cycles / $insts, 2)
    Write-Host "   CPI: $cpi" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "✨ Ready for CPI benchmarks!" -ForegroundColor Green
    Write-Host "   Next: Get benchmark .hex files and run .\run_cpi_benchmarks.ps1" -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "❌ PROCESSOR NOT RETIRING INSTRUCTIONS" -ForegroundColor Red
    Write-Host "   Check for stalls or deadlocks" -ForegroundColor Yellow
    
    # Show cache activity
    $icache = $output | Select-String -Pattern "ICACHE"
    $dcache = $output | Select-String -Pattern "DCACHE"
    
    if ($icache) {
        Write-Host ""
        Write-Host "ICACHE Activity:" -ForegroundColor Cyan
        $icache | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" }
    }
    
    if ($dcache) {
        Write-Host ""
        Write-Host "DCACHE Activity:" -ForegroundColor Cyan
        $dcache | Select-Object -First 5 | ForEach-Object { Write-Host "   $_" }
    }
}

Write-Host ""

