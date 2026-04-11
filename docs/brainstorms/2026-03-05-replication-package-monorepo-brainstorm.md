# Brainstorm: Unified Replication Package Monorepo

**Date**: 2026-03-05
**Status**: Ready for planning

## What We're Building

A single git repo at `D:\Emeryt_local\` that contains the complete replication package for the Economic Journal paper. When ready to submit, clone/copy the whole thing to `N:\PROJECTS\EMERYT\_Paper_16_EJ_replication\`.

The repo unifies three currently separate pieces:
1. **Fortran model** (currently `D:\Emeryt_local\emeryt\` — separate git repo)
2. **Calibration** (currently `D:\Emeryt_local\calibration\` — separate git repo for income_process, plus inputs_stata_code on N: drive)
3. **Output/graphing** (currently `outputs_stata_code/` on N: drive, reads from NAS/Dropbox)

## Why This Approach

- **One repo** = one `git clone` to replicate everything
- **Self-contained** = no NAS, Dropbox, or external path dependencies
- **Matches EJ replication requirements** = reviewers run scripts in sequence, get all results
- **Simple** = no submodules, no multi-repo coordination

## Key Decisions

1. **Single git repo** at `D:\Emeryt_local\` (or a new subdirectory like `D:\Emeryt_local\replication\`)
2. **Gitignore large data** — .dta >10MB, large .csv, Results/ output. Copy these separately to N: drive.
3. **Self-contained paths** — all Stata scripts use relative paths within the repo. No external NAS/Dropbox/drive letter dependencies.
4. **Delete obsolete Fortran on N:** — replace with current code from `D:\Emeryt_local\emeryt\`
5. **Income process calibration included** — the consolidated Stata+MATLAB pipeline is part of the repo

## Proposed Directory Structure

```
D:\Emeryt_local\emeryt\                # Monorepo root (existing git repo)
├── README.md                          # Top-level replication guide
├── CLAUDE.md                          # AI assistance docs (existing, updated)
│
├── data/                              # Shared data (small tracked, large gitignored)
│   ├── PSID/
│   │   └── psid_ready.dta            # (gitignored, 54MB)
│   ├── SCF/
│   │   └── SCF_plus.dta              # (gitignored, 104MB)
│   └── model_psid_all_govt__.dta     # (gitignored, 200MB)
│
├── fortran_code/                      # Fortran model (moved from root)
│   ├── *.f90
│   ├── Instructions/
│   ├── Parameters/
│   ├── Data/                          # Small txt inputs (tracked)
│   ├── Results/                       # (gitignored — large output)
│   ├── 5Gtrans.sln
│   ├── run_scenarios.bat
│   └── scenarios.txt
│
├── inputs_stata_code/                 # Data preparation (from N: drive)
│   ├── __main_data_prepare.do
│   ├── _prepare_programs.do
│   ├── demography/
│   ├── tax_rate/
│   ├── skill_premium/
│   ├── social_security/
│   ├── depreciation/
│   ├── tfp/
│   ├── labor_share/
│   └── income_process/               # Our consolidated PSID pipeline
│       ├── estimate_income_process.do
│       ├── estimate_parameters.m
│       ├── matlab/
│       └── psid/psid.dta             # (gitignored, 94MB)
│
├── outputs_stata_code/                # Results & graphing (from N: drive)
│   ├── __main.do
│   ├── MvD_*.do
│   ├── R_Figure*.do
│   └── ...
│
├── sensitivity_stata_code/            # Robustness checks (from N: drive)
│   └── exog_rate/
│
└── graphs/                            # Output graphics (tracked — small)
    ├── inputs/
    └── outputs/
```

## Resolved Decisions

1. **Repo root**: `D:\Emeryt_local\emeryt\` — the existing emeryt repo becomes the monorepo
2. **Directory naming**: Match N: drive names exactly (`fortran_code/`, `inputs_stata_code/`, `outputs_stata_code/`, `sensitivity_stata_code/`) — coauthor works on Stata part and expects these names
3. **Fortran location**: Move from root into `fortran_code/` subdirectory to match N: structure
4. **Large data**: Gitignored. Copy separately to N: drive for submission.
5. **Self-contained paths**: All Stata scripts updated to use relative paths within the repo

## Open Questions (to resolve during planning)

1. **Git history**: Preserve emeryt/ history (move files within repo) or start fresh?
2. **inputs_stata_code data dependencies**: ACS .dta (~2GB) — gitignore + document provisioning?
3. **Model Results**: ~20GB per scenario. "Run model first" or provide pre-computed?
4. **Income process calibration**: Where does it go? Separate `calibration/` dir at root, or inside `inputs_stata_code/`?

## Next Steps

Run `/workflows:plan` to design the migration.
