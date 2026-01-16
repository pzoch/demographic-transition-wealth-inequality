@echo off
REM ===============================================================================
REM Script to run scenarios from scenarios.txt list
REM Usage: run_scenarios_from_list.bat
REM
REM This script reads scenarios.txt and runs each scenario listed.
REM Each line should have format: version experiment closure
REM Lines starting with # are treated as comments
REM ===============================================================================

setlocal enabledelayedexpansion

if not exist "scenarios.txt" (
    echo ERROR: scenarios.txt not found
    pause
    exit /b 1
)

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

echo Starting scenario runs from scenarios.txt...
echo.

set count=0
set failed=0

for /f "usebackq tokens=1,2,3" %%a in ("scenarios.txt") do (
    REM Skip comment lines
    set "line=%%a"
    if not "!line:~0,1!"=="#" (
        set /a count+=1
        echo [!count!] Running %%a%%b%%c...
        "%EXE_PATH%" %%a %%b %%c
        if errorlevel 1 (
            echo ERROR: %%a%%b%%c failed
            set /a failed+=1
        ) else (
            echo Completed %%a%%b%%c
        )
        echo.
    )
)

echo.
echo ===============================================================================
echo Run summary:
echo   Total scenarios: !count!
echo   Failed: !failed!
echo   Succeeded: !count! - !failed!
echo ===============================================================================

if !failed! gtr 0 (
    echo WARNING: Some scenarios failed. Check output above for details.
)

pause
