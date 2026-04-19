@echo off
REM Full income process estimation pipeline
REM Processes all variants automatically (no arguments needed)
REM Pipeline: Stata (PSID -> omega + covariances) -> MATLAB (covariances -> sigma2eps) -> Plot
REM Final outputs copied to fortran_code/Data/ for Fortran, figures to graphs/inputs/
REM
REM Override software paths via environment variables if your install locations differ:
REM   set STATA_EXE=D:\Stata17\StataSE-64.exe
REM   set MATLAB_EXE=D:\MATLAB\R2023a\bin\matlab.exe
REM Otherwise defaults below are used.
REM
REM Bootstrap: by default n_reps=0 (point estimates only, ~minutes).
REM For confidence bands set N_REPS=1000 before running (several hours):
REM   set N_REPS=1000
REM Both estimate_income_process.do and estimate_parameters.m honor this env var.

setlocal

cd /d "%~dp0"

if not defined STATA_EXE  set "STATA_EXE=C:\Program Files\Stata16\StataSE-64.exe"
if not defined MATLAB_EXE set "MATLAB_EXE=C:\Program Files\MATLAB\R2018b\bin\matlab.exe"

if not exist "%STATA_EXE%" (
    echo ERROR: Stata executable not found at: %STATA_EXE%
    echo Set STATA_EXE env var to your Stata path, e.g.:
    echo   set STATA_EXE=C:\Program Files\Stata17\StataSE-64.exe
    pause
    exit /b 1
)
if not exist "%MATLAB_EXE%" (
    echo ERROR: MATLAB executable not found at: %MATLAB_EXE%
    echo Set MATLAB_EXE env var to your MATLAB path, e.g.:
    echo   set MATLAB_EXE=C:\Program Files\MATLAB\R2023a\bin\matlab.exe
    pause
    exit /b 1
)

echo Using Stata:  %STATA_EXE%
echo Using MATLAB: %MATLAB_EXE%
echo.

echo === Step 1: Stata pipeline (all variants) ===
"%STATA_EXE%" /e do estimate_income_process.do
if errorlevel 1 (
    echo ERROR: Stata failed. Check estimate_income_process.log
    pause
    exit /b 1
)
echo Stata complete.

echo === Step 2: MATLAB estimation (all variants) ===
"%MATLAB_EXE%" -batch "estimate_parameters"
if errorlevel 1 (
    echo ERROR: MATLAB failed.
    pause
    exit /b 1
)
echo MATLAB complete.

echo === Step 3: Plot sigma2_epsilon estimates ===
"%MATLAB_EXE%" -batch "addpath('matlab'); plot_estimates"
if errorlevel 1 (
    echo WARNING: Plotting failed. Estimation outputs are still valid.
)
echo Plotting complete.

echo.
echo === Pipeline complete ===
echo Outputs copied to fortran_code/Data/:
for %%v in (mostdrop_hhslabinc busno_drop_hhslabinc) do (
    echo   _data_omega_%%v_avghourlyhh.txt
    echo   _data_sigma2eps_%%v_avghourlyhh.txt
)
echo Figures saved to graphs/inputs/
pause
endlocal
