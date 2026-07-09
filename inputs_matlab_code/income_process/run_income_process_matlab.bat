@echo off
REM MATLAB stage of the income-process pipeline.
REM Reads Stata covariance outputs, estimates sigma2eps, copies Fortran inputs,
REM and refreshes the MATLAB income-process plot in graphs/inputs/.

setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "REPO_ROOT=%%~fI"
cd /d "%REPO_ROOT%"

if not defined MATLAB_EXE set "MATLAB_EXE=C:\Program Files\MATLAB\R2018b\bin\matlab.exe"

if not exist "%MATLAB_EXE%" (
    echo ERROR: MATLAB executable not found at: %MATLAB_EXE%
    echo Set MATLAB_EXE env var to your MATLAB path, e.g.:
    echo   set MATLAB_EXE=C:\Program Files\MATLAB\R2023a\bin\matlab.exe
    exit /b 1
)

echo Using MATLAB: %MATLAB_EXE%
if defined N_REPS (
    echo Using N_REPS from environment: %N_REPS%
) else (
    if exist "%REPO_ROOT%\inputs_stata_code\income_process\N_REPS.txt" (
        set /p CFG_N_REPS=<"%REPO_ROOT%\inputs_stata_code\income_process\N_REPS.txt"
        echo Using N_REPS from inputs_stata_code\income_process\N_REPS.txt: !CFG_N_REPS!
    ) else (
        echo Using default N_REPS: 0
    )
)
echo.

echo === MATLAB Step 1: Estimate income-process parameters ===
"%MATLAB_EXE%" -batch "run('inputs_matlab_code/income_process/estimate_parameters.m')"
if errorlevel 1 (
    echo ERROR: MATLAB estimation failed.
    exit /b 1
)

echo === MATLAB Step 2: Plot sigma2_epsilon estimates ===
"%MATLAB_EXE%" -batch "run('outputs_matlab_code/income_process/plot_estimates.m')"
if errorlevel 1 (
    echo WARNING: MATLAB plotting failed. Estimation outputs may still be valid.
)

echo.
echo MATLAB income-process stage complete.
endlocal
