 /*
Title: ECB "Whatever It Takes" Speech — Sovereign Spread Event Study DiD
Author: Vatsala Dagar
Affiliation: MSc Economics & Policy, King's College London
Date: June 2026
Description: Replication code for continuous-treatment event study DiD
             estimating causal effect of Draghi's July 2012 speech on
             sovereign bond spreads across 11 eurozone countries.
Data: panel_stata.csv (included in repository)
Software: Stata 17+; requires reghdfe, coefplot, esttab packages
Sample: 11 eurozone countries (AT, BE, FI, FR, IE, IT, MT, NL, PT, SI, ES)
*/
 
* IMPORT DATA
 
clear all
set more off

* Working directory
* Set to the folder containing panel_stata.csv
cd "/path/to/your/data"

* Importing cleaned panel
import delimited "panel_stata.csv", delimiter(",") clear varnames(1)

* Date convert
gen date2 = date(date, "YMD")
format date2 %td
drop date
rename date2 date

* Declaring Panel
xtset country_id date

* Reconstructing event time in trading days relative to speech
sort country_id date
by country_id: gen tday = _n
gen speech_tday = tday if date == date("2012-07-26", "YMD")
by country_id: egen speech_tday2 = max(speech_tday)
drop speech_tday
rename speech_tday2 speech_tday
gen event_time = tday - speech_tday

* Main variables
gen post               = (date >= date("2012-07-26", "YMD"))
gen debt_x_post        = debt_gdp_2011 * post
gen programme          = (country == "Ireland" | country == "Portugal")
gen debt_x_post_prog   = debt_x_post * programme
gen debt_x_post_noprog = debt_x_post * (1 - programme)
gen debt_gdp_sq        = debt_gdp_2011^2
gen debt_sq_x_post     = debt_gdp_sq * post
gen debt_x_post_2012   = debt_gdp_2012 * post

* Saving full dataset
save "panel_wide.dta", replace

* Restrict to main estimation window [-10, +30]
keep if event_time >= -10 & event_time <= 30

* Save main estimation dataset
save "panel_main.dta", replace

di "Setup complete. Observations in main window: " _N
 
* TESTS 1 & 2: EVENT STUDY REGRESSION + PARALLEL TRENDS F-TEST
* Test 1: Pre-period parallel trends — graphical (via full event study plot)
* Test 2: Pre-period parallel trends — joint F-test
* Pass criterion: F-test p > 0.05

use "panel_main.dta", clear

* Generating event-time dummies and debt/GDP interactions
* Pre-period: k = -10 to -2 (k = -1 is omitted reference period)
forvalues k = 2/10 {
    gen pre`k'   = (event_time == -`k')
    gen i_pre`k' = debt_gdp_2011 * pre`k'
}

* Post-period: k = 0 to +30
forvalues k = 0/30 {
    gen post`k'   = (event_time == `k')
    gen i_post`k' = debt_gdp_2011 * post`k'
}

* Build variable lists
local pre_vars ""
forvalues k = 10(-1)2 {
    local pre_vars "`pre_vars' i_pre`k'"
}

local post_vars ""
forvalues k = 0/30 {
    local post_vars "`post_vars' i_post`k'"
}

* Full event study regression
reghdfe spread `pre_vars' `post_vars', absorb(country_id date) vce(robust)
estimates store eventstudy

* TEST 2: Joint F-test on pre-period coefficients
local pre_test ""
forvalues k = 10(-1)2 {
    local pre_test "`pre_test' i_pre`k'"
}

test `pre_test'

di "TEST 2: Joint F-test on pre-period coefficients"
di "F(" r(df) ", " r(df_r) ") = " r(F)
di "p-value = " r(p)
di cond(r(p) > 0.05, "RESULT: PASS", "RESULT: CONCERN")

 
* TEST 3: FULL EVENT STUDY COEFFICIENT PLOT (MAIN FIGURE)
* Shows pre- and post-period coefficients together
* Pass criterion: Near-zero pre-period, negative and growing post-period
* Output: fig_eventstudy_main.png
   
coefplot eventstudy, keep(i_pre* i_post*) vertical yline(0, lcolor(black) lpattern(solid)) xline(10.5, lcolor(red) lpattern(dash)) title("Event Study: WIT Speech Effect on Sovereign Spreads", size(medium)) xtitle("Trading days relative to July 26 2012", size(small)) ytitle("Coefficient bps per 1pp Debt/GDP", size(small)) ciopts(recast(rcap) lwidth(thin)) msize(small) xlabel(1 "-10" 3 "-8" 5 "-6" 7 "-4" 9 "-2" 11 "0" 16 "+5" 21 "+10" 26 "+15" 31 "+20" 36 "+25" 41 "+30", angle(0) labsize(small) nogrid) ylabel(, labsize(small) nogrid) scheme(s1mono)
graph export "fig_eventstudy_main.png", width(2400) height(1600) replace

di "Test 3 complete. fig_eventstudy_main.png saved."
 
* TEST 4: PARSIMONIOUS TWO-PERIOD DiD (HEADLINE TABLE)
* Average treatment effect -  additional bps compression per 1pp debt/GDP
* Pass criterion: Negative beta, significant at 5% level
* Output: table_main_DiD.rtf
 
use "panel_main.dta", clear

* Baseline specification
reghdfe spread debt_x_post, absorb(country_id date) vce(robust)
estimates store did_baseline

* VIX controlled
reghdfe spread debt_x_post vix, absorb(country_id date) vce(robust)
estimates store did_vix

* Table exporting
esttab did_baseline did_vix using "table_main_DiD.rtf", keep(debt_x_post vix) label se star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) title("Table 2: Parsimonious Two-Period DiD") mtitles("Baseline" "VIX Control") scalars("N Observations" "r2 R-squared") addnotes("Robust SEs. Country and date FEs absorbed. Outcome: 10-year spread vs Germany (bps). Window: [-10, +30] trading days. 11 eurozone countries.") replace

* Economic magnitude
scalar beta = _b[debt_x_post]
di "TEST 4: Economic Magnitude"
di "Beta: " beta " bps per 1pp Debt/GDP"
di "Italy (119.1%) vs Finland (52.0%): " (119.1-52.0)*beta " bps"
di "Portugal (114.0%) vs Finland (52.0%): " (114.0-52.0)*beta " bps"
di "Spain (69.5%) vs Finland (52.0%): " (69.5-52.0)*beta " bps"
 
* TEST 5: WINDOW SENSITIVITY
* Tests on whether results are stable across different post-period windows
* Output: table_window_sensitivity.rtf
   
use "panel_wide.dta", clear

* Window 1: [-10, +20]
preserve
    keep if event_time >= -10 & event_time <= 20
    reghdfe spread debt_x_post, absorb(country_id date) vce(robust)
    estimates store window_20
    di "Window [-10,+20]: beta = " _b[debt_x_post]
restore

* Window 2: [-10, +30] baseline
preserve
    keep if event_time >= -10 & event_time <= 30
    reghdfe spread debt_x_post, absorb(country_id date) vce(robust)
    estimates store window_30
    di "Window [-10,+30]: beta = " _b[debt_x_post]
restore

* Window 3: [-10, +45] OMT enters after day +37
preserve
    keep if event_time >= -10 & event_time <= 45
    reghdfe spread debt_x_post, absorb(country_id date) vce(robust)
    estimates store window_45
    di "Window [-10,+45]: beta = " _b[debt_x_post]
    di "(OMT enters here — coefficient shift indicates OMT additional effect)"
restore

esttab window_20 window_30 window_45 using "table_window_sensitivity.rtf", keep(debt_x_post) label se star(* 0.10 ** 0.05 *** 0.01) title("Window Sensitivity Analysis") mtitles("-10 to +20" "-10 to +30" "-10 to +45") addnotes("OMT Sept 6 2012 enters the -10 to +45 window. Robust SEs. Country and date FEs absorbed.") replace

di "Test 5 complete. table_window_sensitivity.rtf saved."
 
* TEST 6: VIX-CONTROLLED SPECIFICATION
* Tests on whether results are driven by global risk appetite
* Pass criterion: Beta stable after VIX control
 
use "panel_main.dta", clear

reghdfe spread debt_x_post vix, absorb(country_id date) vce(robust)

di "TEST 6: VIX-Controlled Specification"
di "Beta on Debt x Post: " _b[debt_x_post]
di "Beta on VIX:         " _b[vix]
di "Baseline beta:        " beta
 
* TEST 7: PROGRAMME VS NON-PROGRAMME HETEROGENEITY
* Mechanism test — troika countries should show a weaker dose-response
* Pass criterion: Non-programme slope significantly steeper (p < 0.05)
* Output: table_heterogeneity.rtf
 
use "panel_main.dta", clear

reghdfe spread debt_x_post if programme == 0, absorb(country_id date) vce(robust)
estimates store het_noprog
di "Non-programme beta = " _b[debt_x_post]

reghdfe spread debt_x_post if programme == 1, absorb(country_id date) vce(robust)
estimates store het_prog
di "Programme beta = " _b[debt_x_post]

reghdfe spread debt_x_post_noprog debt_x_post_prog, absorb(country_id date) vce(robust)
estimates store het_interact

test debt_x_post_noprog = debt_x_post_prog

di "Non-programme beta = " _b[debt_x_post_noprog]
di "Programme beta = " _b[debt_x_post_prog]
di "Test equal slopes: F = " r(F) ", p = " r(p)

esttab het_noprog het_prog het_interact using "table_heterogeneity.rtf", keep(debt_x_post debt_x_post_noprog debt_x_post_prog) label se star(* 0.10 ** 0.05 *** 0.01) title("Heterogeneity: Programme vs Non-Programme") mtitles("Non-Programme" "Programme" "Interaction") addnotes("Programme: Ireland Portugal. Non-programme: remaining 9 countries. Robust SEs. Country and date FEs absorbed.") replace
 
* TEST 8: ALTERNATIVE DEBT/GDP VINTAGE
* Tests sensitivity to the year chosen for treatment intensity
* Output: table_vintage.rtf
 
* Note: requires did_baseline estimates from Test 4 - run file top to bottom

use "panel_main.dta", clear

reghdfe spread debt_x_post_2012, absorb(country_id date) vce(robust)
estimates store vintage_2012

di "TEST 8: Alternative Debt/GDP Vintage"
di "2011 vintage beta (baseline): " beta
di "2012 vintage beta:            " _b[debt_x_post_2012]

esttab did_baseline vintage_2012 using "table_vintage.rtf", keep(debt_x_post debt_x_post_2012) label se star(* 0.10 ** 0.05 *** 0.01) title("Robustness: Alternative Debt/GDP Vintage") mtitles("2011 Vintage Baseline" "2012 Vintage") addnotes("Robust SEs. Country and date FEs absorbed.") replace

 
* TEST 9: OUTLIER EXCLUSION
* Tests whether results driven by extreme debt/GDP observations
 
* Note: requires did_baseline estimates from Test 4 - run file top to bottom

use "panel_main.dta", clear

reghdfe spread debt_x_post if country != "Italy" & country != "Slovenia", absorb(country_id date) vce(robust)
estimates store outlier_excl

di "TEST 9: Outlier Exclusion"
di "Full sample beta: -.683"
di "Excl. Italy and Slovenia beta: " _b[debt_x_post]

esttab did_baseline outlier_excl using "table_outlier.rtf", keep(debt_x_post) label se star(* 0.10 ** 0.05 *** 0.01) title("Robustness: Outlier Exclusion") mtitles("Full Sample" "Excl. Italy and Slovenia") addnotes("Italy: highest debt/GDP 119.1%. Slovenia: lowest 46.8%. Robust SEs. Country and date FEs absorbed.") replace

di "Test 9 complete. table_outlier.rtf saved."
 
* TEST 10: QUADRATIC DEBT/GDP SPECIFICATION
* Tests on whether the dose-response is linear or convex
 
* Note: requires did_baseline estimates from Test 4 - run file top to bottom

use "panel_main.dta", clear

reghdfe spread debt_x_post debt_sq_x_post, absorb(country_id date) vce(robust)
estimates store quadratic

scalar p_quad = 2*ttail(e(df_r), abs(_b[debt_sq_x_post]/_se[debt_sq_x_post]))

di "TEST 10: Quadratic Debt/GDP Specification"
di "Linear term:    " _b[debt_x_post]
di "Quadratic term: " _b[debt_sq_x_post]
di "Quadratic p:    " p_quad
di cond(p_quad < 0.05, "RESULT: Significant nonlinearity", "RESULT: Linear specification adequate")

esttab did_baseline quadratic using "table_quadratic.rtf", keep(debt_x_post debt_sq_x_post) label se star(* 0.10 ** 0.05 *** 0.01) title("Robustness: Quadratic Debt/GDP Specification") mtitles("Linear Baseline" "Quadratic") addnotes("Robust SEs. Country and date FEs absorbed.") replace

di "Test 10 complete. table_quadratic.rtf saved."
