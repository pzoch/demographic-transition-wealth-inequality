@echo off
REM ===============================================================================
REM Script to run multiple scenarios of the OLG model
REM Usage: run_scenarios.bat
REM
REM This script runs the compiled 5Gtrans.exe for multiple scenario combinations.
REM Each scenario is defined by three parameters:
REM   - version: Model variant (base, psid, busn, etc.)
REM   - experiment: What varies (all, ndm, ndo, etc.)
REM   - closure: Closure rule (govt__)
REM
REM Results are saved to: Results\{version}{experiment}{closure}\
REM ===============================================================================

REM Check for executable in multiple locations
set EXE_PATH=
if exist "5Gtrans.exe" set EXE_PATH=5Gtrans.exe
if exist "x64\Release\5Gtrans.exe" set EXE_PATH=x64\Release\5Gtrans.exe
if exist "x64\Debug\5Gtrans.exe" set EXE_PATH=x64\Debug\5Gtrans.exe
if exist "Release\5Gtrans.exe" set EXE_PATH=Release\5Gtrans.exe
if exist "Debug\5Gtrans.exe" set EXE_PATH=Debug\5Gtrans.exe

if "%EXE_PATH%"=="" (
    echo ERROR: 5Gtrans.exe not found. Please compile the project first.
    echo Searched in: current directory, x64\Release, x64\Debug, Release, Debug
    pause
    exit /b 1
)

echo Using executable: %EXE_PATH%
echo.

echo Starting scenario runs...
echo.

REM PSID scenarios (baseline model)
echo Running psid_all_govt__ (baseline with full CSV output)...
"%EXE_PATH%" psid_ all_ govt__
if errorlevel 1 (
    echo ERROR: psid_all_govt__ failed
    pause
    exit /b 1
)
echo Completed psid_all_govt__
echo.

echo Running psid_ndm_govt__ (no demographics)...
"%EXE_PATH%" psid_ ndm_ govt__
if errorlevel 1 (
    echo ERROR: psid_ndm_govt__ failed
    pause
    exit /b 1
)
echo Completed psid_ndm_govt__
echo.

REM Base scenarios (alternative calibration) - commented out by default
REM echo Running base_all_govt__...
REM 5Gtrans.exe base_ all_ govt__
REM if errorlevel 1 (
REM     echo ERROR: base_all_govt__ failed
REM     pause
REM     exit /b 1
REM )
REM echo Completed base_all_govt__
REM echo.

REM echo Running base_ndm_govt__...
REM 5Gtrans.exe base_ ndm_ govt__
REM if errorlevel 1 (
REM     echo ERROR: base_ndm_govt__ failed
REM     pause
REM     exit /b 1
REM )
REM echo Completed base_ndm_govt__
REM echo.

REM Add more scenarios as needed
REM Uncomment the following blocks to run additional scenarios:

REM echo Running busn_all_govt__...
REM 5Gtrans.exe busn_ all_ govt__
REM if errorlevel 1 (
REM     echo ERROR: busn_all_govt__ failed
REM     pause
REM     exit /b 1
REM )
REM echo Completed busn_all_govt__
REM echo.

REM echo Running busn_ndm_govt__...
REM 5Gtrans.exe busn_ ndm_ govt__
REM if errorlevel 1 (
REM     echo ERROR: busn_ndm_govt__ failed
REM     pause
REM     exit /b 1
REM )
REM echo Completed busn_ndm_govt__
REM echo.

echo.
echo All scenario runs completed successfully!
pause
