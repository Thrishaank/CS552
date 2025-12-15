# PowerShell script to measure branch prediction accuracy
param(
    [Parameter(Mandatory=$true)]
    [string]$BenchmarkHex,
    
    [int]$MaxCycles = 100000
)

Write-Host "=== Measuring Branch Prediction Accuracy ===" -ForegroundColor Cyan
Write-Host "Benchmark: $BenchmarkHex" -ForegroundColor White
Write-Host ""

# Check file exists
if (!(Test-Path $BenchmarkHex)) {
    Write-Host "ERROR: Benchmark not found: $BenchmarkHex" -ForegroundColor Red
    exit 1
}

# Copy benchmark
Copy-Item $BenchmarkHex -Destination "program.mem" -Force

# Compile
Write-Host "Compiling..." -NoNewline
Remove-Item -Recurse -Force work -ErrorAction SilentlyContinue
vlib work 2>&1 | Out-Null
vlog rtl/*.v 2>&1 | Out-Null
vlog tb/tb.v 2>&1 | Out-Null
Write-Host " Done" -ForegroundColor Green

# Run simulation with branch tracking
Write-Host "Running simulation..." -ForegroundColor Yellow

$simCmd = @"
vsim -c hart_tb -do "
    run ${MaxCycles}ns
    quit -f
" 2>&1
"@

$output = Invoke-Expression $simCmd

# Parse output for branch information
# Look for branch-related messages in your testbench
# You'll need to add display statements in your RTL/testbench

Write-Host ""
Write-Host "=== Parsing Branch Statistics ===" -ForegroundColor Cyan

# Example patterns to search for (you'll need to add these to your testbench):
# - "[BRANCH] Taken" or "[BRANCH] Not Taken"
# - "[PREDICT] Correct" or "[PREDICT] Wrong"

$branchTaken = ($output | Select-String -Pattern "BRANCH.*Taken" -AllMatches).Matches.Count
$branchNotTaken = ($output | Select-String -Pattern "BRANCH.*Not" -AllMatches).Matches.Count
$totalBranches = $branchTaken + $branchNotTaken

$correctPredictions = ($output | Select-String -Pattern "PREDICT.*Correct" -AllMatches).Matches.Count
$wrongPredictions = ($output | Select-String -Pattern "PREDICT.*Wrong" -AllMatches).Matches.Count

if ($totalBranches -gt 0) {
    $accuracy = [math]::Round(($correctPredictions * 100.0) / $totalBranches, 2)
    
    Write-Host "Total Branches:        $totalBranches" -ForegroundColor White
    Write-Host "  - Taken:             $branchTaken" -ForegroundColor Gray
    Write-Host "  - Not Taken:         $branchNotTaken" -ForegroundColor Gray
    Write-Host "Correct Predictions:   $correctPredictions" -ForegroundColor Green
    Write-Host "Wrong Predictions:     $wrongPredictions" -ForegroundColor Red
    Write-Host "Accuracy:              $accuracy%" -ForegroundColor Cyan
    
    return @{
        TotalBranches = $totalBranches
        Correct = $correctPredictions
        Wrong = $wrongPredictions
        Accuracy = $accuracy
    }
} else {
    Write-Host "WARNING: No branch information found!" -ForegroundColor Yellow
    Write-Host "You need to add branch tracking to your testbench or hart.v" -ForegroundColor Yellow
    return $null
}

