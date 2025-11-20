@echo off
echo ========================================
echo    HART Processor ModelSim Launcher
echo ========================================
echo.

REM Set ModelSim path
set MODELSIM_PATH=C:\intelFPGA\18.1\modelsim_ase\win32aloem
set PATH=%MODELSIM_PATH%;%PATH%

REM Change to project directory
cd /d "d:\CS552"

REM Copy program memory file if needed
if exist "tb\program.mem" (
    copy "tb\program.mem" "program.mem" >nul 2>&1
    echo Program memory copied successfully
)

echo Starting ModelSim compilation and simulation...
echo.

REM Run ModelSim with clean simulation script
vsim -do clean_simulation.do

echo.
echo ModelSim session ended.
pause