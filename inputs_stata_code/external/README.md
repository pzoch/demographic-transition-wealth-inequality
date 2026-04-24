# External Fortran inputs

These three text files are Fortran inputs sourced from external authorities
that no script in the repository regenerates — they are shipped as-is.

| File | Rows | Content | Source |
|---|---|---|---|
| `_data_Nn_US_1935_2100.txt` | 34 (5-yr periods 1935–2100) | Newborn population per period | U.N. Population Prospects birth rates + CDC |
| `_data_Nn_US_1935_init_old.txt` | 19 (age groups 25–100 in 5-yr bins at t=0) | Initial 1935 age distribution | CDC historical population tables |
| `_data_rho_1935.txt` | 18 (age groups 25–100 after jbar) | Pension replacement rates by age at retirement | Social Security Administration benefit formula |

See paper §3 and Online Appendix C for details.

`copy_to_fortran.do` (in this folder, called from `__main_data_prepare.do`)
copies these files into `fortran_code/Data/` so the Fortran binary reads them
alongside the pipeline-generated inputs. To update one, edit the copy here and
re-run `__main_data_prepare.do`.
