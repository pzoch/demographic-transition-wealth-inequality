* Build the two PSID income-process samples and optional bootstrap resamples.

capture confirm file "income_process/I01_00_config.do"
if !_rc {
    do "income_process/I01_00_config.do"
}
else {
    capture confirm file "I01_00_config.do"
    if !_rc {
        do "I01_00_config.do"
    }
    else {
        do "inputs_stata_code/income_process/I01_00_config.do"
    }
}
local variants "$IP_VARIANTS"
local measure "$IP_MEASURE"
local n_reps $IP_N_REPS

foreach variant of local variants {
    local output_dir "$IP_OUTPUT_DIR/`variant'"
    display as text ""
    display as text "###############################################################"
    display as text "# Building sample: `variant'"
    display as text "###############################################################"

    use "$IP_COMMON_SAMPLE", clear
* --- Variant-specific sample selection ---
if "`variant'" == "mostdrop_hhslabinc" {
    * Drop households where >25% of 5-year income comes from business
    gen year_g = floor(year / 5) * 5
    bys year: egen p25 = pctile(hhslabinc), p(25)

    preserve
    tempfile superstars
    collapse (sum) hhsinc_bus hhslabinc p25 weight, by(year_g person)
    gen share = hhsinc_bus / hhslabinc
    gen most = 0
    replace most = 1 if share >= 0.25 & !mi(share) & hhslabinc > p25
    tsset person year_g
    gen entry = ((l5.most == 0) & (most == 1))
    gen exit  = ((most == 1) & (f5.most == 0))
    save `superstars', replace
    restore

    merge m:1 person year_g using `superstars', nogen
    sort person year
    drop if most == 1
    gen pure_labinc = hhslabinc - hhsinc_bus
    save "`output_dir'/psid_ready", replace
    display as text "   Saved: `output_dir'/psid_ready.dta"
    capture mkdir "$IP_REPO_ROOT/data"
    capture mkdir "$IP_REPO_ROOT/data/PSID"
    copy "`output_dir'/psid_ready.dta" "$IP_REPO_ROOT/data/PSID/psid_ready.dta", replace
    display as text "   Copied: $IP_REPO_ROOT/data/PSID/psid_ready.dta"
    drop year_g p25 pure_labinc
    display as text "   mostdrop: dropped business-income superstars"
}
else if "`variant'" == "busno_drop_hhslabinc" {
    * Keep all households (no filtering)
    display as text "   busno_drop: keeping all households"
}

* Save cleaned sample
save "`output_dir'/psid_`variant'_`measure'", replace
display as text "   Saved: `output_dir'/psid_`variant'_`measure'.dta"

* --- Generate bootstrap samples ---
if `n_reps' > 0 {
    set seed 20240101
    display as text "   Generating `n_reps' bootstrap samples..."
    forvalues ag = 1/`n_reps' {
        rename person person_old
        bsample, cluster(person_old) idcluster(person) strata(cohort)
        save "`output_dir'/psid_`variant'_`measure'_rep`ag'", replace
        use "`output_dir'/psid_`variant'_`measure'", clear
    }
    display as text "   Bootstrap samples saved to `output_dir'/"
}
}
