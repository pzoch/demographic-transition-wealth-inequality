# Frozen Fortran inputs

These three text files are Fortran inputs that no script in the repository
regenerates. They originate from external sources and are shipped as-is.

| File | Rows | Content | Source |
|---|---|---|---|
| `_data_Nn_US_1935_2100.txt` | 34 (5-yr periods 1935–2100) | Newborn population per period | U.N. Population Prospects birth rates + CDC |
| `_data_Nn_US_1935_init_old.txt` | 19 (age groups 25–100 in 5-yr bins at t=0) | Initial 1935 age distribution | CDC historical population tables |
| `_data_rho_1935.txt` | 18 (age groups 25–100 after jbar) | Pension replacement rates by age at retirement | Social Security Administration benefit formula |

See paper §3 and Online Appendix C for details.

`inputs_stata_code/__main_data_prepare.do` copies these three files into
`fortran_code/Data/` before the calibration scripts run, so they are available
to the Fortran binary alongside the pipeline-generated inputs.

If you need to update any of them, edit the file here and re-run
`__main_data_prepare.do`.
