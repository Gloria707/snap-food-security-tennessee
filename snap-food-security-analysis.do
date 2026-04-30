*===========================================================================*
*  SNAP & FOOD SECURITY ANALYSIS - TENNESSEE METRO AREAS (2020–2023)
* Current Population Survey - Food Security Supplement
  * Models:
  *  1. Binary Logit  – food_secure (1=secure, 0=insecure)
  *  2. Ordered Logit – food_sec_cat (1=High, 2=Marginal, 3=Low, 4=Very Low)
*===========================================================================*


clear all
set more off
* ---- Import each year ----
import delimited "dec19pub.csv", clear
rename gctcb cbsa
keep if inlist(cbsa,17300,17420,16860,27740,28700,28940,32820,34980)
gen year = 2019
tempfile y2019
save `y2019'

* For 2020
import delimited "C:\SNAP\dec20pub.csv", clear
rename gtcbsa cbsa
keep if gestfips==47
gen year = 2020
tempfile y2020
save `y2020'

* For 2021
import delimited "C:\SNAP\dec21pub.csv", clear
rename gtcbsa cbsa
keep if gestfips==47
gen year = 2021
tempfile y2021
save `y2021'

* For 2022
import delimited "C:\SNAP\dec22pub.csv", clear
rename gtcbsa cbsa
keep if gestfips==47
gen year = 2022
tempfile y2022
save `y2022'

* For 2023
import delimited "C:\SNAP\dec23pub.csv", clear
rename gtcbsa cbsa
keep if gestfips==47
gen year = 2023
tempfile y2023
save `y2023'

* ---- Stack all years ----
use `y2019', clear
append using `y2020' `y2021' `y2022' `y2023'

compress

* -----------------------------------------------------------------------
* AGGREGATE PERSON-LEVEL DATA TO HOUSEHOLD LEVEL
*
* The CPS FSS stores one record per PERSON. We use egen with by(hrhhid hryear4)
* to aggregate across all household members before collapsing to one row.

* Three types of variables:
*   (1) Aggregated across ALL members:  employment, disability, education,
*                                       children, elderly — using egen max/total
*   (2) Household-level (same for all members): SNAP, food security, income,
*                                       size, type — already consistent
*   (3) Householder only (pulineno==1): age, race, citizenship, homeownership
* -----------------------------------------------------------------------

* Drop empty placeholder rows (all key person-level fields = -1)
drop if prtage == -1 & pesex == -1 & peeduca == -1 & pemlr == -1
foreach v in hesp1 hrfs12md pemaritl hetenure cbsa pehspnon prdisflg hrnumhou peeduca ptdtrace pesex hefaminc prcitshp hrpoor {
    replace `v' = . if `v' < 0
}
* ── STEP 1: Create person-level indicators for aggregation ──

* Employment status (valid rows only: pemlr > 0)
gen _emp   = (inlist(pemlr, 1, 2)) if pemlr > 0 
gen _unemp = (inlist(pemlr, 3, 4)) if pemlr > 0   

* Disability (valid rows: prdisflg > 0)
gen _dis   = (prdisflg == 1)       if prdisflg > 0

* Age (valid rows: prtage >= 0)
gen _child = (prtage < 18)         if prtage >= 0  
gen _elder = (prtage >= 65)        if prtage >= 0  

* Education (valid rows: peeduca > 0; all members, not adults only)
gen _educ  = peeduca               if peeduca > 0

* STEP 2: Aggregate to household level using egen, by(hrhhid hryear4)
* max() captures "any member" for binary indicators
* total() counts members meeting criteria

egen any_employed   = max(_emp),   by(hrhhid hryear4)
egen any_unemployed = max(_unemp), by(hrhhid hryear4)
egen any_disabled   = max(_dis),   by(hrhhid hryear4)
egen any_elderly    = max(_elder), by(hrhhid hryear4)
egen n_children     = total(_child), by(hrhhid hryear4)
egen n_workers      = total(_emp),   by(hrhhid hryear4)
egen hh_maxeduc     = max(_educ),  by(hrhhid hryear4)

* All members NILF: no employed and no unemployed in household
gen all_nilf = (any_employed == 0 & any_unemployed == 0) if !missing(any_employed)

* Hispanic ethnicity
gen _hisp = (pehspnon == 1) if pehspnon > 0
egen hispanic = max(_hisp), by(hrhhid hryear4)
drop _hisp
label var hispanic "Any household member Hispanic"

* Presence of children indicator
gen has_children = (n_children > 0)

drop _emp _unemp _dis _child _elder _educ

label var any_employed   "Any household member employed"
label var any_unemployed "Any household member unemployed"
label var all_nilf       "All household members not in labor force"
label var n_workers      "Number of workers in household"
label var any_disabled   "Any household member disabled"
label var any_elderly    "Any household member aged 65+"
label var n_children     "Number of children (<18) in household"
label var has_children   "Household has children (<18)"
label var hh_maxeduc     "Highest education level in household"

* STEP 3: Keep one row per household (pulineno == 1)
* pulineno identifies row order within the household.
* pulineno==1 is the householder — their age, race, and citizenship
* represent the household. For CSV years without pulineno, the data
* are already sorted so the first row per household is the householder.

capture confirm variable pulineno
if _rc == 0 {
    sort hrhhid hryear4 pulineno
}
else {
    sort hrhhid hryear4
}
by hrhhid hryear4: keep if _n == 1

di as result "Households after collapsing to PULINENO=1: `c(N)'"


* -----------------------------------------------------------------------
* 1A. SNAP PARTICIPATION  (hesp1: 1=Yes, 2=No; negatives = N/A or missing)
* -----------------------------------------------------------------------
gen snap = .
replace snap = 1 if hesp1 == 1
replace snap = 0 if hesp1 == 2
label var snap "SNAP participant (1=Yes, 0=No)"
label define yesno 0 "No" 1 "Yes"
label values snap yesno

* -----------------------------------------------------------------------
* 1B. FOOD SECURITY OUTCOMES
*   hrfs12m1/hrfs12md: Annual 12-month status  1=Food Secure, 2=Low Food Security,
*                                     3=Very Low Food Security
*   (Values -1 = inapplicable [30-day only or skip]; -9 = refused/DK)
* -----------------------------------------------------------------------

* Binary outcome: food_secure = 1 if food secure, 0 if any insecurity
gen food_secure = .
replace food_secure = 1 if hrfs12m1 == 1
replace food_secure = 0 if inlist(hrfs12m1, 2, 3)
label var food_secure "Food Secure (1=Secure, 0=Insecure)"
label values food_secure yesno

* Ordered outcome: 4-category USDA scale
gen food_sec_cat = .
replace food_sec_cat = 1 if hrfs12md == 1 
replace food_sec_cat = 2 if hrfs12md == 2 
replace food_sec_cat = 3 if hrfs12md == 3 
replace food_sec_cat = 4 if hrfs12md == 4
label var food_sec_cat "Food Security Category (1=High … 4=Very Low)"
label define fsc 1 "High" 2 "Marginal" 3 "Low" 4 "Very Low"
label values food_sec_cat fsc

* -----------------------------------------------------------------------
* 1C. DEMOGRAPHICS & SOCIOECONOMICS
* All household-level variables follow the same bysort/egen pattern.
* Variables already created in the aggregation step (before collapse):
*   hh_maxeduc, any_employed, any_unemployed, all_nilf,
*   any_disabled, any_elderly, n_children, n_workers, has_children
* -----------------------------------------------------------------------

* Household structure (hrhtype is already a household-level variable)
gen hh_married     = (inlist(hrhtype,1,2)) if hrhtype > 0
gen hh_male_head   = (inlist(hrhtype,3,6)) if hrhtype > 0
gen hh_female_head = (inlist(hrhtype,4,7)) if hrhtype > 0
label var hh_married     "HH type: Married couple [reference]"
label var hh_male_head   "HH type: Male-headed, no spouse"
label var hh_female_head "HH type: Female-headed, no spouse"

* Household size (hrnumhou is a household-level variable) 
gen hhsize = hrnumhou if hrnumhou > 0
label var hhsize "Household size (number of members)"

* Householder age (pulineno==1 row, retained after collapse)
gen hl_age    = prtage if prtage >= 0
gen hl_age_sq = hl_age^2
label var hl_age    "Householder age (years)"
label var hl_age_sq "Householder age squared"

* Householder race (pulineno==1 row)
* ptdtrace: 1=White, 2=Black, 3=Am.Indian, 4=Asian, 5=Hawaiian/PI, 6+=multiracial
gen race_white = (ptdtrace == 1) if ptdtrace > 0
gen race_black = (ptdtrace == 2) if ptdtrace > 0
gen race_other = (!inlist(ptdtrace,1,2) & ptdtrace > 0) if ptdtrace > 0
label var race_white "Householder: White [reference]"
label var race_black "Householder: Black"
label var race_other "Householder: Other/Multiracial"

* Education: from hh_maxeduc (highest attainment across all members)
* hh_maxeduc built with: egen hh_maxeduc = max(_educ), by(hrhhid hryear4)
* peeduca codes: 31-38=less than HS, 39=HS/GED, 40-41=some college,
*                43=bachelor's, 44-46=graduate
gen educ_lths    = (inrange(hh_maxeduc,31,38)) if hh_maxeduc > 0
gen educ_hs      = (hh_maxeduc == 39) if hh_maxeduc > 0
gen educ_somecol = (inrange(hh_maxeduc,40,42)) if hh_maxeduc > 0
gen educ_bach    = (hh_maxeduc == 43) if hh_maxeduc > 0
gen educ_grad    = (inrange(hh_maxeduc,44,46)) if hh_maxeduc > 0
label var educ_lths    "HH max educ: Less than HS [reference]"
label var educ_hs      "HH max educ: HS diploma/GED"
label var educ_somecol "HH max educ: Some college/Associate"
label var educ_bach    "HH max educ: Bachelor's degree"
label var educ_grad    "HH max educ: Graduate degree"
  
* Homeownership (pulineno==1) 
* hetenure: 1=owned/buying, 2=rented, 3=no cash rent
gen homeowner = .
replace homeowner = 1 if hetenure == 1
replace homeowner = 0 if inlist(hetenure, 2, 3)
label var homeowner "Homeowner"
label values homeowner yesno

* Citizenship (pulineno==1) 
* prcitshp: 1=native born, 2-4=naturalized, 5=non-citizen
gen citizen = .
replace citizen = 1 if inrange(prcitshp, 1, 4)
replace citizen = 0 if prcitshp == 5
label var citizen "U.S. citizen"
label values citizen yesno

*-----------------------------------------------------------------------
* CREATE CATEGORICAL VARIABLES FOR FACTOR NOTATION IN REGRESSIONS
* We add this block RIGHT AFTER the individual dummies are created (after 1C)
* and BEFORE the keep if !missing() sample restriction
*-----------------------------------------------------------------------

* race_cat: 1=White (ref), 2=Black, 3=Other ──
* Built from ptdtrace (householder race, pulineno==1 row)
gen race_cat = .
replace race_cat = 1 if ptdtrace == 1                       
replace race_cat = 2 if ptdtrace == 2                       
replace race_cat = 3 if !inlist(ptdtrace,1,2) & !missing(ptdtrace) 
label define race_lbl 1 "White" 2 "Black" 3 "Other/Multiracial"
label values race_cat race_lbl
label var race_cat "Householder race (1=White ref)"


* educ_cat: 1=<HS (ref), 2=HS/GED, 3=Some college, 4=Bach, 5=Grad
* Built from hh_maxeduc (already created in aggregation step)
gen educ_cat = .
replace educ_cat = 1 if inrange(hh_maxeduc, 31, 38)   
replace educ_cat = 2 if hh_maxeduc == 39               
replace educ_cat = 3 if inrange(hh_maxeduc, 40, 42)   
replace educ_cat = 4 if hh_maxeduc == 43              
replace educ_cat = 5 if inrange(hh_maxeduc, 44, 46)   
label define educ_lbl 1 "<HS" 2 "HS/GED" 3 "Some College" 4 "Bachelor's" 5 "Graduate"
label values educ_cat educ_lbl
label var educ_cat "HH max education category (1=<HS ref)"

* emp_cat: 1=Employed (ref), 2=Unemployed, 3=All NILF
* Built from any_employed / any_unemployed / all_nilf (already created)
gen emp_cat = .
replace emp_cat = 1 if any_employed   == 1            
replace emp_cat = 2 if any_unemployed == 1 & any_employed == 0 
replace emp_cat = 3 if all_nilf       == 1             
label define emp_lbl 1 "Employed" 2 "Unemployed" 3 "All NILF"
label values emp_cat emp_lbl
label var emp_cat "HH employment status (1=Employed ref)"


* indicator dummies from emp_cat for summary stats table
gen emp_cat_employed   = (emp_cat == 1) if !missing(emp_cat)
gen emp_cat_unemployed = (emp_cat == 2) if !missing(emp_cat)
gen emp_cat_nilf       = (emp_cat == 3) if !missing(emp_cat)

label var emp_cat_employed   "Household employment: Any member employed"
label var emp_cat_unemployed "Household employment: Unemployed (no employed member)"
label var emp_cat_nilf       "Household employment: All members NILF"


* income categories
bysort hrhhid hryear4: egen hh_income_cat = max(hefaminc)

gen income_status = .
* --- Group 1: Low Income (Eligible for SNAP) --- *
* HH=1: $18,954 (Cat 6 is up to $20k)
replace income_status = 1 if hhsize == 1 & hh_income_cat <= 6
* HH=2: $25,636 (Cat 8 is up to $30k)
replace income_status = 1 if hhsize == 2 & hh_income_cat <= 8
* HH=3: $32,318 (Cat 9 is up to $35k)
replace income_status = 1 if hhsize == 3 & hh_income_cat <= 9
* HH=4: $39,000 (Cat 10 is up to $40k)
replace income_status = 1 if hhsize == 4 & hh_income_cat <= 10
* HH=5: $45,682 (Cat 12 is up to $50k)
replace income_status = 1 if hhsize == 5 & hh_income_cat <= 12
* HH=6: $52,364 (Cat 13 is up to $60k)
replace income_status = 1 if hhsize == 6 & hh_income_cat <= 13
* HH=7+: $59,046 (Cat 13 is up to $60k)
replace income_status = 1 if hhsize >= 7 & hh_income_cat <= 13

* --- Group 2: Middle Income ---
* Anyone above the SNAP limit but below $100k (Cat 15)
replace income_status = 2 if missing(income_status) & hh_income_cat <= 15

* --- Group 3: High Income ---
* Anyone earning $100k or more (Cat 16+)
replace income_status = 3 if missing(income_status) & hh_income_cat >= 16

label define inc_lbl 1 "Low (≤130% FPL)" 2 "Middle" 3 "High"
label values income_status inc_lbl
label var income_status "HH income status (130% FPL threshold, size-adjusted)"

* Eligibility criteria(low income)
gen eligible = 0
* Matches our size-adjusted "Low/Eligible" logic
replace eligible = 1 if hhsize == 1 & hh_income_cat <= 7
replace eligible = 1 if hhsize == 2 & hh_income_cat <= 9
replace eligible = 1 if hhsize == 3 & hh_income_cat <= 10
replace eligible = 1 if hhsize >= 4 & hh_income_cat <= 12

* -----------------------------------------------------------------------
* REGRESSION DUMMIES
* -----------------------------------------------------------------------
gen inc_low    = (income_status == 1) if !missing(income_status)
gen inc_medium = (income_status == 2) if !missing(income_status)
gen inc_high   = (income_status == 3) if !missing(income_status)

* -----------------------------------------------------------------------
* 1D. METRO AREA IDENTIFIERS & LABELS
* -----------------------------------------------------------------------
gen metro = cbsa
label var metro "CBSA Code"
label define metro_lbl 0 "Non-metro" 16860 "Chattanooga TN-GA" 17300 "Clarksville TN-KY" 17420 "Cleveland TN" 27740 "Johnsoncity TN" 28700 "Kingsport-Bristol TN-VA" 28940 "Knoxville" 32820 "Memphis TN-MS-AR" 34980 "Nashville-Davidson TN"
label values metro metro_lbl

* Indicator dummies for each of the 9 named metros (exclude non-metro as base)
gen metro_chattanooga = (cbsa == 16860)
gen metro_clarksville = (cbsa == 17300)
gen metro_cleveland   = (cbsa == 17420)
gen metro_johnsoncity = (cbsa == 27740)
gen metro_kingsport   = (cbsa == 28700)
gen metro_knoxville   = (cbsa == 28940)
gen metro_memphis     = (cbsa == 32820)
gen metro_nashville   = (cbsa == 34980)

* -----------------------------------------------------------------------
* 1E. YEAR & YEAR FIXED EFFECTS  (base year = 2019)
* -----------------------------------------------------------------------
gen year = hryear4
label var year "Survey year"
tab year, gen(yr_)
rename yr_1 yr_2019
rename yr_2 yr_2020
rename yr_3 yr_2021
rename yr_4 yr_2022
rename yr_5 yr_2023
label var yr_2019 "Year FE: 2019 (base)"
label var yr_2020 "Year FE: 2020"
label var yr_2021 "Year FE: 2021"
label var yr_2022 "Year FE: 2022"
label var yr_2023 "Year FE: 2023"

* -----------------------------------------------------------------------
* 1F. ANALYSIS SAMPLE: keep households with valid outcome & SNAP indicator
* -----------------------------------------------------------------------
keep if !missing(food_secure) & !missing(snap)
keep if !missing(food_sec_cat)

di as result "Analytical sample N = `c(N)'"



* -----------------------------------------------------------------------
* ADDITIONAL VARIABLES NEEDED FOR TABLE 1
* (not yet created in Section 1C — all from pulineno==1 row)
* -----------------------------------------------------------------------

* Female householder (pesex: 1=Male, 2=Female)
gen female = (pesex == 2) if pesex > 0
label var female "Female householder"
label values female yesno

* Householder age — rename hl_age to age for cleaner table labels
* (hl_age already created in 1C; just alias for display)
gen age = hl_age
label var age "Householder age (years)"

* Food security detail dummies (from food_sec_cat = hrfs12md)
gen fs_high = (food_sec_cat == 1) if !missing(food_sec_cat)
gen fs_marg = (food_sec_cat == 2) if !missing(food_sec_cat)
gen fs_low  = (food_sec_cat == 3) if !missing(food_sec_cat)
gen fs_vlow = (food_sec_cat == 4) if !missing(food_sec_cat)
label var fs_high "High food security"
label var fs_marg "Marginal food security"
label var fs_low  "Low food security"
label var fs_vlow "Very low food security"

* Individual marital status dummies (from pulineno==1 pemaritl)
* pemaritl: 1=married spouse present, 2=married spouse absent,
*           3=widowed, 4=divorced, 5=separated, 6=never married
gen married      = (pemaritl == 1)        if pemaritl > 0
gen divorced_sep = (inlist(pemaritl,4,5)) if pemaritl > 0
gen widowed      = (pemaritl == 3)        if pemaritl > 0
gen never_marr   = (pemaritl == 6)        if pemaritl > 0
label var married      "Married"
label var divorced_sep "Divorced/Separated"
label var widowed      "Widowed"
label var never_marr   "Never married"

* Single-parent household (hrhtype: female or male headed, no spouse)
gen single_hh = (inlist(hrhtype,3,4,6,7)) if hrhtype > 0
label var single_hh "Single-parent household"

* Has disability — use household aggregate any_disabled (already created)
* Rename for cleaner table label
gen has_disability = any_disabled
label var has_disability "Has disability (any member)"


* -----------------------------------------------------------------------
* 2A. TABLE 1: FULL SAMPLE | SNAP PARTICIPANTS | NON-PARTICIPANTS
* Replicates the three-column layout in the image exactly
* -----------------------------------------------------------------------
di as text _newline(2) "======== TABLE 1: SUMMARY STATISTICS ========"

* --- Panel A: Outcomes ---
eststo full:     estpost summarize snap food_secure food_sec_cat fs_high fs_marg fs_low fs_vlow if !missing(snap) & eligible == 1 & !missing(food_secure), quietly
eststo snap_yes: estpost summarize snap food_secure food_sec_cat fs_high fs_marg fs_low fs_vlow if snap == 1 & eligible == 1 & !missing(food_secure), quietly
eststo snap_no:  estpost summarize snap food_secure food_sec_cat fs_high fs_marg fs_low fs_vlow if snap == 0 & eligible == 1 & !missing(food_secure), quietly

esttab full snap_yes snap_no, cells("mean(fmt(3)) sd(fmt(3))") label nostar nonumber noobs mtitles("Full Sample" "SNAP Participants" "Non-Participants") title("Panel A: Outcomes")

* --- Panel B: Demographics ---
eststo full:     estpost summarize female age race_white race_black race_other hispanic married divorced_sep widowed never_marr single_hh hhsize has_disability homeowner citizen if !missing(snap) & eligible == 1 & !missing(food_secure), quietly
eststo snap_yes: estpost summarize female age race_white race_black race_other hispanic married divorced_sep widowed never_marr single_hh hhsize has_disability homeowner citizen if snap == 1 & eligible == 1 & !missing(food_secure), quietly
eststo snap_no:  estpost summarize female age race_white race_black race_other hispanic married divorced_sep widowed never_marr single_hh hhsize has_disability homeowner citizen if snap == 0 & eligible == 1 & !missing(food_secure), quietly

esttab full snap_yes snap_no, cells("mean(fmt(3)) sd(fmt(3))") label nostar nonumber noobs title("Panel B: Demographics")

* --- Panel C: Education ---
eststo full:     estpost summarize educ_lths educ_hs educ_somecol educ_bach educ_grad if !missing(snap) & eligible == 1 & !missing(food_secure), quietly
eststo snap_yes: estpost summarize educ_lths educ_hs educ_somecol educ_bach educ_grad if snap == 1 & eligible == 1 & !missing(food_secure), quietly
eststo snap_no:  estpost summarize educ_lths educ_hs educ_somecol educ_bach educ_grad if snap == 0 & eligible == 1 & !missing(food_secure), quietly

esttab full snap_yes snap_no, cells("mean(fmt(3)) sd(fmt(3))") label nostar nonumber noobs title("Panel C: Education")

* --- Panel D: Employment & Income ---
eststo full:     estpost summarize emp_cat_employed emp_cat_unemployed emp_cat_nilf inc_low inc_medium inc_high if !missing(snap) & eligible == 1 & !missing(food_secure), quietly
eststo snap_yes: estpost summarize emp_cat_employed emp_cat_unemployed emp_cat_nilf inc_low inc_medium inc_high if snap == 1 & eligible == 1 & !missing(food_secure), quietly
eststo snap_no:  estpost summarize emp_cat_employed emp_cat_unemployed emp_cat_nilf inc_low inc_medium inc_high if snap == 0 & eligible == 1 & !missing(food_secure), quietly

esttab full snap_yes snap_no, cells("mean(fmt(3)) sd(fmt(3))") label nostar nonumber noobs title("Panel D: Employment & Income")

* --- Panel E: Survey Year ---
eststo full:     estpost summarize yr_2019 yr_2020 yr_2021 yr_2022 yr_2023 if !missing(snap) & eligible == 1 & !missing(food_secure), quietly
eststo snap_yes: estpost summarize yr_2019 yr_2020 yr_2021 yr_2022 yr_2023 if snap == 1 & eligible == 1 & !missing(food_secure), quietly
eststo snap_no:  estpost summarize yr_2019 yr_2020 yr_2021 yr_2022 yr_2023 if snap == 0 & eligible == 1 & !missing(food_secure), quietly

esttab full snap_yes snap_no, cells("mean(fmt(3)) sd(fmt(3))") label nostar nonumber noobs title("Panel E: Survey Year")

* -----------------------------------------------------------------------
* 2B. COMBINED EXPORT TO CSV (WEIGHTED)
* -----------------------------------------------------------------------
eststo clear

local vars snap food_secure food_sec_cat fs_high fs_marg fs_low fs_vlow female age race_white race_black race_other hispanic married divorced_sep widowed never_marr single_hh has_children hhsize has_disability homeowner citizen educ_lths educ_hs educ_somecol educ_bach educ_grad emp_cat_employed emp_cat_unemployed emp_cat_nilf inc_low inc_medium yr_2019 yr_2020 yr_2021 yr_2022 yr_2023

eststo full: estpost summarize `vars' if !missing(snap) & eligible == 1 & !missing(food_secure), quietly
eststo snap_yes: estpost summarize `vars' if snap == 1 & eligible == 1 & !missing(food_secure), quietly
eststo snap_no: estpost summarize `vars' if snap == 0 & eligible == 1 & !missing(food_secure), quietly

* Adding count(fmt(0)) to show the number of households (N) at the bottom
esttab full snap_yes snap_no using "summary_stats_final.csv", cells("mean(fmt(3)) sd(fmt(3))") label nostar nonumber mtitles("Full Sample" "SNAP Participants" "Non-Participants") title("Table 1: Weighted Summary Statistics — TN Metro Areas") replace


* -----------------------------------------------------------------------
* 2C. FOOD SECURITY STATUS BY SNAP PARTICIPATION (cross-tab)
* -----------------------------------------------------------------------
di _newline "======== TABLE 3: FOOD SECURITY × SNAP PARTICIPATION ========"

tab food_sec_cat snap, row col chi2
tab food_secure snap,  row col chi2

* -----------------------------------------------------------------------
* 2D. TRENDS OVER TIME
* -----------------------------------------------------------------------
di _newline "======== TABLE 5: ANNUAL TRENDS ========"

tabstat snap food_secure, by(year) stat(mean n) nototal

* Graphical check (optional - remove if running in batch)
graph bar (mean) snap food_secure, over(year) title("SNAP Participation and Food Security Rate by Year") ytitle("Share of Households") legend(label(1 "SNAP") label(2 "Food Secure"))


*---------------------------------------------------------------------------
*  SECTION 3: BASELINE BINARY LOGIT MODELS
*  Outcome: food_secure (1=secure, 0=insecure)
*  Key predictor: snap
*  Controls: gender, age, race, education, employment, income, disability,
*            household size, marital status, metro FE, year FE
*---------------------------------------------------------------------------*
di _newline(2) "======== SECTION 3: BINARY LOGIT MODELS ========"

* Reference categories: married-couple HH, White householder, <HS education, all members NILF, High income, 2019, Chattanooga
global controls hh_male_head hh_female_head hl_age hl_age_sq hl_black hl_asian hl_other hhsize n_children any_elderly any_disabled educ_hs educ_somecol educ_bach educ_grad any_employed any_unemployed inc_low inc_medium homeowner citizen     

eststo clear

eststo m1: logit food_secure snap hhsize has_children i.any_elderly homeowner i.race_cat hispanic i.educ_cat i.emp_cat citizen has_disability i.cbsa i.year if eligible==1 [pweight=hhsupwgt], vce(robust)
estadd scalar pseudo_r2 = e(r2_p)
esttab m1 using "OR_Logit2.csv", eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label scalars("pseudo_r2 Pseudo R-sq" "N Observations") mtitles("Bivariate" "+Controls" "+Year FE" "Full Model") title("Binary Logit — Odds Ratios") replace
esttab m1, eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label scalars("pseudo_r2 Pseudo R-sq" "N Observations") mtitles("Bivariate" "+Controls" "+Year FE" "Full Model") title("Binary Logit — Odds Ratios")

eststo clear
quietly logit food_secure snap hhsize has_children any_elderly homeowner i.race_cat hispanic i.educ_cat i.emp_cat citizen has_disability i.cbsa i.year if eligible==1 [pweight=hhsupwgt], vce(robust)
margins, dydx(*) post

eststo ame1
esttab ame1 using "logit_AME.csv", b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) label mtitles("Bivariate" "+Controls" "+Year FE" "Full Model") title("Binary Logit — Average Marginal Effects") replace
esttab ame1, b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) label mtitles("Bivariate" "+Controls" "+Year FE" "Full Model") title("Binary Logit — Average Marginal Effects")
*---------------------------------------------------------------------------
*  SECTION 4: ORDERED LOGIT MODELS
*  Outcome: food_sec_cat (1=High … 4=Very Low)
*  Note: Higher values = WORSE food security, so positive coeff = more insecurity
*---------------------------------------------------------------------------*
di _newline(2) "======== SECTION 4: ORDERED LOGIT MODELS ========"

eststo clear
eststo o1a: ologit food_sec_cat snap hhsize has_children any_elderly homeowner i.race_cat hispanic i.educ_cat i.emp_cat citizen has_disability i.cbsa i.year if eligible == 1 [pweight=hhsupwgt], vce(robust)
capture estadd scalar pseudo_r2 = e(r2_p)
esttab o1a using "ologit_OR_final.csv", eform b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label scalars("pseudo_r2 Pseudo R-sq" "N Observations") mtitles("Bivariate" "+Controls" "+Year FE" "Full Model") eqlabels("" "Cut 1: High→Marginal" "Cut 2: Marginal→Low" "Cut 3: Low→Very Low") title("Ordered Logit — Proportional Odds Ratios") replace

quietly ologit food_sec_cat snap hhsize has_children female homeowner hl_age i.race_cat hispanic i.educ_cat i.emp_cat citizen has_disability i.year i.cbsa if eligible==1 [pweight=hhsupwgt], vce(robust)
margins, dydx(snap) predict(outcome(1)) predict(outcome(2)) predict(outcome(3)) predict(outcome(4)) post
esttab . using "ologit_AME_final.csv", b(4) se(4) star(* 0.10 ** 0.05 *** 0.01) title("AME of SNAP — Probability of Each Food Security Level (Full Model)") replace

*---------------------------------------------------------------------------
*  SECTION 5A: DISAGGREGATED ANALYSIS BY METRO AREA
*---------------------------------------------------------------------------*
di _newline(2) "======== SECTION 5: DISAGGREGATED METRO ANALYSIS ========"

eststo clear
local metro_codes 16860 17300 17420 27740 28700 28940 32820 34980
local metro_names "Chattanooga Clarksville Cleveland JohnsonCity Kingsport Knoxville Memphis Nashville"
local i = 1
foreach code of local metro_codes {
    local mname : word `i' of `metro_names'
    di _newline "--- `mname' (CBSA `code') ---"

    capture reg food_secure snap if cbsa == `code' & eligible == 1 [pweight=hhsupwgt], vce(robust)

    if _rc == 0 {
        eststo me_`mname'
        di "  N = `e(N)'  SNAP coef = direct marginal effect"
    }
    else {
        di "  WARNING: Did not converge for `mname'"
    }
    local ++i
}
esttab me_* using "table_bivariate_metro.csv", b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label plain title("Table 5B – Bivariate Association: SNAP & Food Security") mtitles("Chattanooga" "Clarksville" "Cleveland" "Johnson City" "Kingsport" "Knoxville" "Memphis" "Nashville") replace


* -----------------------------------------------------------------------
* 5B. Disaggregated + all variables 
* -----------------------------------------------------------------------
eststo clear
local metro_codes 16860 17300 17420 27740 28700 28940 32820 34980
local metro_names "Chattanooga Clarksville Cleveland JohnsonCity Kingsport Knoxville Memphis Nashville"

local i = 1
foreach code of local metro_codes {
    local mname : word `i' of `metro_names'
    di _newline "--- lpm Analysis: `mname' (CBSA `code') ---"

    * Use a simpler model for small N: SNAP + Year fixed effects only
    capture reg food_secure snap homeowner i.race_cat has_children has_disability i.year if cbsa == `code' & eligible == 1 [pweight=hhsupwgt], vce(robust)

    if _rc == 0 {
        eststo biv_`mname'
        di "  N = `e(N)'"
    }
    else {
        di "  WARNING: Model failed for `mname'"
    }
    local ++i
}

* Exporting the results
esttab biv_* using "table_metro.csv", b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label plain title("Table 5B – SNAP & Food Security LPM") mtitles("Chattanooga" "Clarksville" "Cleveland" "Johnson City" "Kingsport" "Knoxville" "Memphis" "Nashville") replace


*---------------------------------------------------------------------------
* SECTION 6: ROBUSTNESS CHECKS
*---------------------------------------------------------------------------*

di _newline(2) "======== SECTION 6: ROBUSTNESS CHECKS ========"

* -----------------------------------------------------------------------
* 6A. Probit – binary outcome
* -----------------------------------------------------------------------
eststo clear
probit food_secure snap hhsize has_children any_elderly homeowner i.race_cat hispanic i.educ_cat i.emp_cat citizen has_disability i.cbsa i.year if eligible == 1 [pweight=hhsupwgt], vce(robust)
margins, dydx(*) post
eststo rob_probit
* -----------------------------------------------------------------------
* 6B. Linear Probability Model (LPM)
* -----------------------------------------------------------------------
regress food_secure snap hhsize has_children any_elderly homeowner i.race_cat hispanic i.educ_cat i.emp_cat citizen has_disability i.cbsa i.year if eligible == 1 [pweight=hhsupwgt], vce(robust)
eststo rob_lpm

esttab rob_probit rob_lpm using "table_robustness.csv", b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) label title("Table 7 – Robustness Checks") mtitles("Probit" "LPM") replace


*-----------------------------------------------------------------------
* Prevelance of Food_security/SNAP
*-----------------------------------------------------------------------
gen food_insecure = .

* 1 = Food Insecure (Low or Very Low Food Security)
replace food_insecure = 1 if inlist(hrfs12md, 3, 4)

* 0 = Food Secure (High or Marginal Food Security)
replace food_insecure = 0 if inlist(hrfs12md, 1, 2)

* --- Add Labels for clean tables ---
label define finsec_lbl 1 "Food Insecure" 0 "Food Secure"
label values food_insecure finsec_lbl
label var food_insecure "Household is Food Insecure (Low or Very Low)"

tabstat food_insecure if eligible == 1, by(year) statistics(mean n) save
tabstat food_insecure if eligible == 1 & snap == 1, by(year) statistics(mean n)
tabstat food_insecure if eligible == 1 & snap == 0, by(year) statistics(mean n)

*-----------------------------------------------------------------------
* SNAP Participation and food insecurity rates by metro area
*-----------------------------------------------------------------------
preserve
collapse (mean) snap_rate = snap (mean) insecurity_rate = food_insecure (count) n = food_secure [pweight = hhsupwgt] if !missing(snap) & !missing(food_secure), by(cbsa)

* Convert to percentages
replace snap_rate = round(snap_rate * 100, 0.1)
replace insecurity_rate = round(insecurity_rate * 100, 0.1)

label define cbsa_lbl 0 "Non-Metro" 16860 "Chattanooga" 17300 "Clarksville" 17420 "Cleveland" 27740 "Johnson City" 28700 "Kingsport" 28940 "Knoxville" 32820 "Memphis" 34980 "Nashville"
label values cbsa cbsa_lbl

list cbsa snap_rate insecurity_rate n, sep(0) noobs

export delimited using "figure_metro_rates.csv", replace
restore

























