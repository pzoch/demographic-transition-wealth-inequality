# ACS/IPUMS input for the college-share pipeline

`ACS_college.dta` is the IPUMS USA extract used by `inputs_stata_code/skill_premium/D02_prepare_college.do`.
It is large and subject to IPUMS terms of use, so it may be omitted from a public journal deposit
unless redistribution permission has been arranged. The processed files needed by the model are:

```
inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs.dta
inputs_stata_code/skill_premium/ACS_college/processed/col_share_acs_ext.dta
fortran_code/Data/_data_college_share.txt
```

## Rebuilding from IPUMS

To rebuild from scratch, create an IPUMS USA extract and save it as:

```
inputs_stata_code/skill_premium/ACS_college/ACS_college.dta
```

Use the following years/samples:

```
1940, 1950, 1960, 1970, 1980, 1990, 2000, 2006, 2011, 2016, 2021
```

Required variables:

- `YEAR`
- `AGE`
- `HIGRADE`
- `EDUCD`
- `PERWT`

`D02_prepare_college.do` keeps age-25 observations, defines BA-or-higher status using `HIGRADE`
before 1990 and `EDUCD` from 1990 onward, computes weighted college shares with `PERWT`, interpolates
the annual path onto the model's five-year grid, extrapolates early and post-2020 values as coded in
the script, writes `_data_college_share.txt`, and saves the processed cohort files used by
`demography/hetero_pi/D03_prepare_hetero_pi.do`.

## Citation and rights

IPUMS USA is provided by the University of Minnesota. The collection DOI is:

```
https://doi.org/10.18128/C010
```

At the time of the 2026 package revision, the current IPUMS USA version is Version 16.0:

```
https://doi.org/10.18128/D010.V16.0
```

If you rebuild with a different IPUMS version, cite the version DOI corresponding to your extract date.
The IPUMS version history and citation instructions are maintained at https://www.ipums.org/projects/ipums-usa
and https://usa.ipums.org/usa/cite.shtml.
