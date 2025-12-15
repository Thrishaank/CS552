# Script to run a single benchmark and extract CPI
param(
    [Parameter(Mandatory=$true)]
    [string]$BenchmarkHex,
    
    [int]$MaxCycles = 100000
)

Write-Host "=== Running Benchmark: $BenchmarkHex ===" -ForegroundColor Cyan

# Check if file exists
if (!(Test-Path $BenchmarkHex)) {
    Write-Host "ERROR: Benchmark file not found: $BenchmarkHex" -ForegroundColor Red
    exit 1
}

# Copy to program.mem
Write-Host "Copying benchmark to program.mem..." -NoNewline
Copy-Item $BenchmarkHex -Destination "program.mem" -Force
Write-Host " Done" -ForegroundColor Green

# Clean and compile
Write-Host "Compiling processor..." -NoNewline
Remove-Item -Recurse -Force work -ErrorAction SilentlyContinue
vlib work 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host " Failed!" -ForegroundColor Red
    exit 1
}

vlog rtl/*.v 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host " Failed!" -ForegroundColor Red
    exit 1
}

vlog tb/tb.v 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host " Failed!" -ForegroundColor Red
    exit 1
}

Write-Host " Done" -ForegroundColor Green

# Run simulation
Write-Host "Running simulation (max ${MaxCycles}ns)..." -ForegroundColor Yellow
$simOutput = vsim -c hart_tb -do "run ${MaxCycles}ns; quit -f" 2>&1

# Save output to log
$logFile = "simulation_log.txt"
$simOutput | Out-File $logFile

Write-Host "Simulation complete!" -ForegroundColor Green
Write-Host ""

# Parse results
Write-Host "=== RESULTS ===" -ForegroundColor Cyan

# Count instruction retirements (valid signals)
$retirementPattern = '\[(\d+)\]'
$retirements = [regex]::Matches($simOutput, $retirementPattern)

if ($retirements.Count -gt 0) {
    $lastRetirement = $retirements[$retirements.Count - 1]
    $totalCycles = [int]$lastRetirement.Groups[1].Value
    $totalInstructions = $retirements.Count
    
    $cpi = [math]::Round($totalCycles / $totalInstructions, 3)
    
    Write-Host "Total Cycles:       $totalCycles" -ForegroundColor White
    Write-Host "Instructions Retired: $totalInstructions" -ForegroundColor White
    Write-Host "CPI:                $cpi" -ForegroundColor Green
    
    return @{
        Cycles = $totalCycles
        Instructions = $totalInstructions
        CPI = $cpi
    }
} else {
    Write-Host "ERROR: No instruction retirements detected!" -ForegroundColor Red
    Write-Host "Check $logFile for details" -ForegroundColor Yellow
    
    # Show last 20 lines of output
    Write-Host "`nLast 20 lines of simulation output:" -ForegroundColor Yellow
    $simOutput | Select-Object -Last 20 | ForEach-Object { Write-Host $_ }
    
    return $null
}

