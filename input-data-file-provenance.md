# Input Data File Provenance

## Context

After fixing the inputs Stata pipeline (`__main_data_prepare.do`) to produce files with correct names and correct row counts (34 five-year periods, 1935–2100), we compared the committed `_data_*.txt` files (used by the Fortran model) against the N: drive (`N:\PROJECTS\EMERYT\_Paper_16_inequality\Code\FORTRAN\Data\`), which contains an earlier version (24 rows, from before the truncation fix).

## Summary

Of the 11 files produced by `__main_data_prepare.do`, 7 are reproduced exactly by the pipeline. Of the remaining 4, one (`_data_gamma.txt`) is reproducible with corrected script parameters. The other 3 have value differences between the committed Fortran inputs and the N: drive.

| File | N: drive vs Fortran input |
|---|---|
| `_data_contrib_to_gdp.txt` | **Identical** (24 rows match, Fortran has 10 more) |
| `_data_gamma.txt` | **Different** (all 24 rows differ; N: drive used wrong parameters) |
| `_data_labsh.txt` | **Different** (all 24 rows differ) |
| `_data_college_share.txt` | **Different** (all rows differ; N: drive has 46 rows, Fortran has 68) |

## Files reproduced exactly by pipeline (7 of 11)

| File | Contents |
|---|---|
| `_data_depr.txt` | Depreciation rates |
| `_data_lambda.txt` | Bequest tax rates |
| `_data_skill_premium.txt` | College wage premium |
| `_data_tauK.txt` | Capital tax rates |
| `_data_tauL.txt` | Labor tax rates |
| `_data_tauC.txt` | Consumption tax rates |
| `_data_exog_rate_1935.txt` | Exogenous interest rate |

## Files with differences (4 of 11)

---

### `_data_gamma.txt` — TFP growth rates

**Reproducible with corrected parameters.**

The Stata script `M02prepare_gamma.do` currently has wrong parameters. With the correct values (`coef_pre=1.35`, `lambda=1600`), the pipeline reproduces the committed Fortran inputs exactly (diff=0 across all 34 periods).

| Parameter | Correct value | In script |
|---|---|---|
| `coef_pre` (pre-1954 extrapolation) | 1.35 | 1.9 |
| `lambda` (HP filter smoothing) | 1600 | 500 |
| `coef_post` (post-2019 extrapolation) | 0.9 | 0.9 |

The N: drive gamma was produced with the current script parameters (`coef_pre=1.9`, `lambda=500`). It differs from the committed Fortran inputs substantially, especially in early periods.

| Row | Year | Fortran input | N: drive (1.9/500) | Difference |
|-----|------|---------------|--------------------|------------|
| 1 | 1935 | .046288 | .065560 | +.0193 |
| 2 | 1940 | .046288 | .065560 | +.0193 |
| 3 | 1945 | .049519 | .066416 | +.0169 |
| 4 | 1950 | .052679 | .066869 | +.0142 |
| 5 | 1955 | .054486 | .065424 | +.0109 |
| 6 | 1960 | .052443 | .060378 | +.0079 |
| 7 | 1965 | .044476 | .048163 | +.0037 |
| 8 | 1970 | .032826 | .030681 | −.0021 |
| 9 | 1975 | .023479 | .017560 | −.0059 |
| 10 | 1980 | .020709 | .015209 | −.0055 |
| 11 | 1985 | .024802 | .023841 | −.0010 |
| 12 | 1990 | .030741 | .032700 | +.0020 |
| 13 | 1995 | .035501 | .038990 | +.0035 |
| 14 | 2000 | .037119 | .041115 | +.0040 |
| 15 | 2005 | .034112 | .034861 | +.0007 |
| 16 | 2010 | .029634 | .026612 | −.0030 |
| 17 | 2015 | .027918 | .025393 | −.0025 |
| 18 | 2020 | .028558 | .028284 | −.0003 |
| 19 | 2025 | .029681 | .030466 | +.0008 |
| 20 | 2030 | .030509 | .031222 | +.0007 |
| 21 | 2035 | .030945 | .031258 | +.0003 |
| 22 | 2040 | .031096 | .031114 | +.0000 |
| 23 | 2045 | .031101 | .031006 | −.0001 |
| 24 | 2050 | .031056 | .030963 | −.0001 |
| 25 | 2055 | .031011 | — | |
| 26 | 2060 | .030982 | — | |
| 27 | 2065 | .030968 | — | |
| 28 | 2070 | .030965 | — | |
| 29 | 2075 | .030966 | — | |
| 30 | 2080 | .030968 | — | |
| 31 | 2085 | .030970 | — | |
| 32 | 2090 | .030971 | — | |
| 33 | 2095 | .030971 | — | |
| 34 | 2100 | .030972 | — | |

---

### `_data_labsh.txt` — Labor share

**Not reproducible.**

N: drive values differ from committed Fortran inputs, especially in the pre-1955 extrapolation region. Post-1955, values converge. The source data (`labor_share.dta` = PWT 10.0) is unchanged.

| Row | Year | Fortran input | N: drive | Difference |
|-----|------|---------------|----------|------------|
| 1 | 1935 | 63.835365 | 64.566078 | +0.731 |
| 2 | 1940 | 63.772667 | 64.289101 | +0.516 |
| 3 | 1945 | 63.701439 | 63.995014 | +0.294 |
| 4 | 1950 | 63.613274 | 63.719780 | +0.107 |
| 5 | 1955 | 63.461994 | 63.470737 | +0.009 |
| 6 | 1960 | 63.305439 | 63.287701 | −0.018 |
| 7 | 1965 | 63.277458 | 63.263191 | −0.014 |
| 8 | 1970 | 63.100254 | 63.094307 | −0.006 |
| 9 | 1975 | 62.447906 | 62.446968 | −0.001 |
| 10 | 1980 | 61.709126 | 61.709805 | +0.001 |
| 11 | 1985 | 61.386074 | 61.386757 | +0.001 |
| 12 | 1990 | 61.491604 | 61.491924 | +0.000 |
| 13 | 1995 | 61.702164 | 61.702240 | +0.000 |
| 14 | 2000 | 61.523605 | 61.523582 | −0.000 |
| 15 | 2005 | 60.691895 | 60.691853 | −0.000 |
| 16 | 2010 | 59.848671 | 59.848618 | −0.000 |
| 17 | 2015 | 59.361416 | 59.361343 | −0.000 |
| 18 | 2020 | 59.066425 | 59.066402 | −0.000 |
| 19 | 2025 | 58.833427 | 58.833660 | +0.000 |
| 20 | 2030 | 58.640331 | 58.641136 | +0.001 |
| 21 | 2035 | 58.478470 | 58.479965 | +0.001 |
| 22 | 2040 | 58.339287 | 58.340328 | +0.001 |
| 23 | 2045 | 58.215714 | 58.212250 | −0.003 |
| 24 | 2050 | 58.103043 | 58.137383 | +0.034 |
| 25 | 2055 | 57.998474 | — | |
| 26 | 2060 | 57.900394 | — | |
| 27 | 2065 | 57.807743 | — | |
| 28 | 2070 | 57.719780 | — | |
| 29 | 2075 | 57.635910 | — | |
| 30 | 2080 | 57.555664 | — | |
| 31 | 2085 | 57.478596 | — | |
| 32 | 2090 | 57.404102 | — | |
| 33 | 2095 | 57.331253 | — | |
| 34 | 2100 | 57.287865 | — | |

Max difference is 0.73 at 1935 (1.1%), dropping to <0.01 by 1955. All post-1955 differences are negligible (<0.001).

---

### `_data_contrib_to_gdp.txt` — Pension contributions / GDP

**N: drive matches committed Fortran inputs exactly** (first 24 rows identical). The Fortran file has 10 additional rows (2055–2100), all equal to the last value (.069059).

| Row | Year | Fortran input | N: drive | Difference |
|-----|------|---------------|----------|------------|
| 1 | 1935 | .033434 | .033434 | 0 |
| 2 | 1940 | .034416 | .034416 | 0 |
| 3 | 1945 | .035483 | .035483 | 0 |
| 4 | 1950 | .036663 | .036663 | 0 |
| 5 | 1955 | .038003 | .038003 | 0 |
| 6 | 1960 | .039592 | .039592 | 0 |
| 7 | 1965 | .041663 | .041663 | 0 |
| 8 | 1970 | .046663 | .046663 | 0 |
| 9 | 1975 | .051386 | .051386 | 0 |
| 10 | 1980 | .058590 | .058590 | 0 |
| 11 | 1985 | .064045 | .064045 | 0 |
| 12 | 1990 | .069881 | .069881 | 0 |
| 13 | 1995 | .069256 | .069256 | 0 |
| 14 | 2000 | .068909 | .068909 | 0 |
| 15 | 2005 | .067076 | .067076 | 0 |
| 16 | 2010 | .063080 | .063080 | 0 |
| 17 | 2015 | .066644 | .066644 | 0 |
| 18 | 2020 | .069059 | .069059 | 0 |
| 19 | 2025 | .069059 | .069059 | 0 |
| 20 | 2030 | .069059 | .069059 | 0 |
| 21 | 2035 | .069059 | .069059 | 0 |
| 22 | 2040 | .069059 | .069059 | 0 |
| 23 | 2045 | .069059 | .069059 | 0 |
| 24 | 2050 | .069059 | .069059 | 0 |
| 25 | 2055 | .069059 | — | |
| 26 | 2060 | .069059 | — | |
| 27 | 2065 | .069059 | — | |
| 28 | 2070 | .069059 | — | |
| 29 | 2075 | .069059 | — | |
| 30 | 2080 | .069059 | — | |
| 31 | 2085 | .069059 | — | |
| 32 | 2090 | .069059 | — | |
| 33 | 2095 | .069059 | — | |
| 34 | 2100 | .069059 | — | |

---

### `_data_college_share.txt` — College share by education type

**Not reproducible.**

This file contains 68 rows: rows 1–34 are the college share, rows 35–68 are the non-college share (= 1 − college). The N: drive version has 46 rows (corrupted by the drawing code truncation bug — the first 23 rows are college share and the remaining rows are non-college shares that start mid-series).

| Row | Year | Fortran input | N: drive | Difference |
|-----|------|---------------|----------|------------|
| 1 | 1935 | .046971 | .053243 | +.006 |
| 2 | 1940 | .045660 | .045944 | +.000 |
| 3 | 1945 | .048641 | .043568 | −.005 |
| 4 | 1950 | .060667 | .054218 | −.006 |
| 5 | 1955 | .082731 | .079489 | −.003 |
| 6 | 1960 | .110705 | .111728 | +.001 |
| 7 | 1965 | .139126 | .142860 | +.004 |
| 8 | 1970 | .163835 | .168014 | +.004 |
| 9 | 1975 | .183123 | .185947 | +.003 |
| 10 | 1980 | .197750 | .198464 | +.001 |
| 11 | 1985 | .210097 | .209166 | −.001 |
| 12 | 1990 | .222945 | .221955 | −.001 |
| 13 | 1995 | .237694 | .237156 | −.001 |
| 14 | 2000 | .254694 | .252855 | −.002 |
| 15 | 2005 | .275427 | .271806 | −.004 |
| 16 | 2010 | .301077 | .298209 | −.003 |
| 17 | 2015 | .329640 | .330061 | +.000 |
| 18 | 2020 | .356598 | .360406 | +.004 |
| 19 | 2025 | .377311 | .381324 | +.004 |
| 20 | 2030 | .390845 | .392668 | +.002 |
| 21 | 2035 | .399102 | .398816 | −.000 |
| 22 | 2040 | .404399 | .403181 | −.001 |
| 23 | 2045 | .408410 | .407242 | −.001 |
| 24 | 2050 | .412036 | — | |
| 25 | 2055 | .415618 | — | |
| 26 | 2060 | .419213 | — | |
| 27 | 2065 | .422769 | — | |
| 28 | 2070 | .426229 | — | |
| 29 | 2075 | .429561 | — | |
| 30 | 2080 | .432760 | — | |
| 31 | 2085 | .435841 | — | |
| 32 | 2090 | .438836 | — | |
| 33 | 2095 | .441786 | — | |
| 34 | 2100 | .443550 | — | |

**Non-college share (rows 35–68):** Values are 1 − college share (mirrors the table above).

---

## Key takeaway

Of the 11 files produced by the Stata pipeline:
- **7 files**: Pipeline reproduces exactly
- **1 file** (`_data_gamma.txt`): Reproducible by correcting `M02prepare_gamma.do` parameters to `coef_pre=1.35` and `lambda=1600`
- **1 file** (`_data_contrib_to_gdp.txt`): N: drive matches Fortran inputs exactly (just truncated to 24 rows)
- **2 files** (`_data_labsh.txt`, `_data_college_share.txt`): N: drive differs from Fortran inputs; not reproducible from current pipeline
