@echo off
echo Starting ModelSim simulation for HART processor...
echo.

REM Set ModelSim path
set MODELSIM_PATH=C:\intelFPGA\18.1\modelsim_ase\win32aloem
set PATH=%MODELSIM_PATH%;%PATH%

REM Check if ModelSim is available
where vsim >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: ModelSim (vsim) not found.
    echo Please verify ModelSim installation at: %MODELSIM_PATH%
    pause
    exit /b 1
)

REM Change to the project directory
cd /d "d:\CS552"

REM Copy program.mem to current directory if it exists in tb folder
if exist "tb\program.mem" (
    copy "tb\program.mem" "program.mem" >nul
    echo Copied program.mem to working directory
)

REM Run ModelSim with the script
echo Running ModelSim...
vsim -do modelsim_script.do

pause