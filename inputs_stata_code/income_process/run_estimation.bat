@echo off
REM Full income process estimation pipeline
REM Processes all variants automatically (no arguments needed)
REM Pipeline: Stata (PSID -> omega + covariances) -> MATLAB (covariances -> sigma2eps) -> Plot
REM Final outputs copied to fortran_code/Data/ for Fortran, figures to graphs/inputs/

cd /d "%~dp0"

echo === Step 1: Stata pipeline (all variants) ===
"C:\Program Files\Stata16\StataSE-64.exe" /e do estimate_income_process.do
if errorlevel 1 (
    echo ERROR: Stata failed. Check estimate_income_process.log
    pause
    exit /b 1
)
echo Stata complete.

echo === Step 2: MATLAB estimation (all variants) ===
"C:\Program Files\MATLAB\R2018b\bin\matlab.exe" -batch "estimate_parameters"
if errorlevel 1 (
    echo ERROR: MATLAB failed.
    pause
    exit /b 1
)
echo MATLAB complete.

echo === Step 3: Plot sigma2_epsilon estimates ===
"C:\Program Files\MATLAB\R2018b\bin\matlab.exe" -batch "addpath('matlab'); plot_estimates"
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
