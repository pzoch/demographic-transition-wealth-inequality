@echo off
REM ===============================================================================
REM Script to run heterogeneous rate-of-return scenarios (Appendix F.2)
REM Usage: run_scenarios_het.bat
REM
REM Requires: 5Gtrans_het.exe (compiled with Release_HetRate^|x64 configuration)
REM ===============================================================================

REM Check for het executable in multiple locations (bin\ is the shipped fallback)
set EXE_PATH=
if exist "5Gtrans_het.exe" set EXE_PATH=5Gtrans_het.exe
if exist "x64\Release_HetRate\5Gtrans_het.exe" set EXE_PATH=x64\Release_HetRate\5Gtrans_het.exe
if exist "bin\5Gtrans_het.exe" set EXE_PATH=bin\5Gtrans_het.exe

if "%EXE_PATH%"=="" (
    echo ERROR: 5Gtrans_het.exe not found.
    echo Please compile the project using Release_HetRate^|x64 configuration.
    echo Searched in: current directory, x64\Release_HetRate, bin
    pause
    exit /b 1
)

echo Using executable: %EXE_PATH%
echo.

echo Running hrat_all_govt__...
"%EXE_PATH%" hrat_ all_ govt__
if errorlevel 1 (
    echo ERROR: hrat_all_govt__ failed
    pause
    exit /b 1
)
echo Completed hrat_all_govt__
echo.

echo Running hrat_ndm_govt__...
"%EXE_PATH%" hrat_ ndm_ govt__
if errorlevel 1 (
    echo ERROR: hrat_ndm_govt__ failed
    pause
    exit /b 1
)
echo Completed hrat_ndm_govt__
echo.

echo.
echo All het-rate scenario runs completed successfully!
pause
