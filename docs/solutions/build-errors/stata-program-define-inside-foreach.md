---
status: solved
priority: p1
category: build-errors
tags: [stata, parser, foreach, program-define, batch-mode]
module: estimate_income_process.do
symptoms: ["--Break-- r(1) after program define end statement", "Stata batch mode fails silently at program define"]
date_solved: 2026-03-04
---

# Stata `program define ... end` Fails Inside `foreach` Block

## Problem Statement

When `program define doit ... end` is placed **inside** a `foreach` loop in Stata, the script crashes with `--Break-- r(1)` immediately after the `end` statement. This happens in both interactive and batch mode.

```
 52.     }
 53. end
--Break--
r(1);
```

The `end` keyword that closes `program define` conflicts with Stata's block parser, which also uses `end`-like tokens to close `foreach { }` blocks.

## Root Cause

Stata's parser has an ambiguity when `program define ... end` appears inside a compound expression (`foreach`, `forvalues`, `if/else`). The `end` token that terminates the program definition gets misinterpreted, causing the script to break.

## Working Solution

Move `program define` **before** the `foreach` loop. The program only needs to be defined once.

**Before (broken):**
```stata
foreach variant of local variants {
    ...
    capture program drop doit
    program define doit
        while $ic < 66 {
            ...
        }
    end          // ← crashes here
    ...
}
```

**After (working):**
```stata
capture program drop doit
program define doit
    while $ic < 66 {
        ...
    }
end

foreach variant of local variants {
    ...
    // just call `doit` — already defined
    ...
}
```

## Prevention

Always define Stata programs at the top level of a do-file, never inside `foreach`, `forvalues`, `if`, or other compound blocks.
