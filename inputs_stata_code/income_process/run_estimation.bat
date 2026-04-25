@echo off
REM Full income-process pipeline compatibility driver.
REM Stata side lives in inputs_stata_code/income_process.
REM MATLAB estimation lives in inputs_matlab_code/income_process.
REM MATLAB plotting lives in outputs_matlab_code/income_process.

setlocal
set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..") do set "REPO_ROOT=%%~fI"

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

echo === Step 1: Stata PSID income-process inputs ===
pushd "%REPO_ROOT%\inputs_stata_code"
"%STATA_EXE%" /e do income_process\__run_psid_income_inputs.do
if errorlevel 1 (
    echo ERROR: Stata failed. Check inputs_stata_code\__run_psid_income_inputs.log or Stata output.
    popd
    pause
    exit /b 1
)
popd

echo === Step 2: MATLAB income-process estimation and plots ===
call "%REPO_ROOT%\inputs_matlab_code\income_process\run_income_process_matlab.bat"
if errorlevel 1 (
    echo ERROR: MATLAB stage failed.
    pause
    exit /b 1
)

echo.
echo === Income-process pipeline complete ===
echo Fortran inputs copied to fortran_code\Data\.
echo Plots saved to graphs\inputs\.
pause
endlocal
