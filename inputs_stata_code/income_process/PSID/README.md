# PSID input for the income-process pipeline

`psid.dta` is the raw PSID extract used by `inputs_stata_code/income_process`.
It is restricted/source data and is intentionally not tracked in git.

The optional `psid_read.R` script records the extraction route used by the authors:
it uses `psidR` to build the PSID panel and writes `psid.dta`. The Stata pipeline
then creates both income-process variants, the `psid_ready.dta` file used by the
output income-distribution plots, omega profiles for Fortran, and covariance
matrices for MATLAB.
