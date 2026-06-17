/*-----------------------------------------------------
  07_MODE_CHOICE.DO
  Multinomial logit for commute mode choice
  Outcome: primary commute mode (dominant by time)
  Base category: driving alone (1)
-----------------------------------------------------*/

global results "C:\data\CarPooling\Results"

use "C:\data\CarPooling\Data\commuting_episodes.dta", clear

*------------------------------------------------------
* 1. Build episode-level mode category
*------------------------------------------------------
gen mode_cat = .
replace mode_cat = 1 if m_driving_alone == 1
replace mode_cat = 2 if m_carpooling   == 1   // non-HH carpool
replace mode_cat = 3 if m_fampooling   == 1   // household carpool
replace mode_cat = 4 if m_public       == 1   // public transit
replace mode_cat = 5 if m_physical     == 1   // walk / bicycle

label define mode_lbl 1 "Driving alone" 2 "Carpool (non-HH)" 3 "Fampooling" 4 "Public transit" 5 "Active"
label values mode_cat mode_lbl

*------------------------------------------------------
* 2. Person-level primary mode (dominant by commute time)
*------------------------------------------------------
foreach m of numlist 1/5 {
    bys caseid: egen total_mode`m' = total(duration * (mode_cat == `m'))
}

* Identify dominant mode
gen dominant_time = max(total_mode1, total_mode2, total_mode3, total_mode4, total_mode5)
gen primary_mode = .
replace primary_mode = 1 if total_mode1 == dominant_time & primary_mode == .
replace primary_mode = 2 if total_mode2 == dominant_time & primary_mode == .
replace primary_mode = 3 if total_mode3 == dominant_time & primary_mode == .
replace primary_mode = 4 if total_mode4 == dominant_time & primary_mode == .
replace primary_mode = 5 if total_mode5 == dominant_time & primary_mode == .
label values primary_mode mode_lbl

* Commute time at person level
bys caseid: egen commute_time_mean = mean(duration)

* One observation per person
bys caseid: keep if _n == 1

* Drop persons with no identifiable primary mode
drop if primary_mode == .

*------------------------------------------------------
* 3. Controls (consistent with Table 3 logit)
*------------------------------------------------------
global dem "native male incouple secondary universitary nchild hh_numadults c.age c.age_sq dayhs_work"

*------------------------------------------------------
* 4. Multinomial logit — base = driving alone (1)
*------------------------------------------------------
mlogit primary_mode $dem i.occupation i.msasize i.region i.year ///
    [pw=awbwt] if msasize != 0, base(1) vce(cluster caseid)

estimates store mlogit_base

*------------------------------------------------------
* 5. Average Marginal Effects
*------------------------------------------------------
* AMEs on education and key sociodemographics for each outcome
* First outcome: replace (creates file)
estimates restore mlogit_base
margins, dydx(secondary universitary male nchild hh_numadults) predict(outcome(2)) post
outreg2 using "$results\Table_ModeChoice_AME.xls", excel replace bdec(3) se dec(3) label ///
    ctitle("Carpool (non-HH)") ///
    addtext("Occupation FE","Yes","MSA size FE","Yes","Region FE","Yes","Year FE","Yes","SE","Clustered (caseid)")

estimates restore mlogit_base
margins, dydx(secondary universitary male nchild hh_numadults) predict(outcome(3)) post
outreg2 using "$results\Table_ModeChoice_AME.xls", excel append bdec(3) se dec(3) label ///
    ctitle("Fampooling") ///
    addtext("Occupation FE","Yes","MSA size FE","Yes","Region FE","Yes","Year FE","Yes","SE","Clustered (caseid)")

estimates restore mlogit_base
margins, dydx(secondary universitary male nchild hh_numadults) predict(outcome(4)) post
outreg2 using "$results\Table_ModeChoice_AME.xls", excel append bdec(3) se dec(3) label ///
    ctitle("Public transit") ///
    addtext("Occupation FE","Yes","MSA size FE","Yes","Region FE","Yes","Year FE","Yes","SE","Clustered (caseid)")

estimates restore mlogit_base
margins, dydx(secondary universitary male nchild hh_numadults) predict(outcome(5)) post
outreg2 using "$results\Table_ModeChoice_AME.xls", excel append bdec(3) se dec(3) label ///
    ctitle("Active modes") ///
    addtext("Occupation FE","Yes","MSA size FE","Yes","Region FE","Yes","Year FE","Yes","SE","Clustered (caseid)")

*------------------------------------------------------
* 6. AMEs by MSA size for carpooling outcome (non-HH)
*------------------------------------------------------
estimates restore mlogit_base
margins i.msasize, dydx(universitary) predict(outcome(2)) post
outreg2 using "$results\Table_ModeChoice_MSA.xls", excel replace bdec(3) se dec(3) label ///
    ctitle("Carpool (non-HH): univ. gradient by MSA") ///
    addtext("Occupation FE","Yes","MSA size FE","Yes","Region FE","Yes","Year FE","Yes","SE","Clustered (caseid)")

*------------------------------------------------------
* 7. Predicted probabilities for descriptive Table A.5
*------------------------------------------------------
estimates restore mlogit_base
margins, predict(outcome(1)) predict(outcome(2)) predict(outcome(3)) predict(outcome(4)) predict(outcome(5))
