***/*-----------------------------------------------------
--------------------------------------------------------
CARPOOLING IN COMMUTING - US
--------------------------------------------------------
-----------------------------------------------------*/


*------------------------------------------------------
* DIRECTORY
*------------------------------------------------------
clear all
use "$data\atus_f.dta", clear

* Para armar el promedio de non-commuting necesito que sean .
replace schappy=.  if schappy > 6
replace scpain=.   if scpain > 6
replace scsad=.   if scsad > 6
replace sctired=.   if sctired > 6
replace scstress=.   if scstress > 6	

*-------------------------------------------------------
* AV. WELL-BEING IN NON-COMMUTING
*-------------------------------------------------------
* se debe armar antes de seleccionar los commuting episodes, sino luego no se tendría esa data

// non-commuting activities
gen a_nontravelling = 0 
gen commuting = 0 // Variable for commuting episode 
gen personal_care = 0 
gen housework_childcare = 0 
gen leisure = 0 

label variable commuting "Commuting episode"
label variable personal_care "Travelling for personal care episode"
label variable housework_childcare "Travelling for househork & childcare episode"
label variable leisure "Travelling for leisure episode"

replace commuting = 1 if inlist(activity, 180501, 180502, 180503, 180504, 180599)


replace personal_care = 1 if inlist(activity, ///
    180101, 180199, ///
    180804, 180805, 180899)


replace housework_childcare = 1 if inlist(activity, ///
    180201, 180202, 180203, 180204, 180205, 180206, ///
    180207, 180208, 180209, 180299, 180301, ///
    180302, 180303, 180304, ///
    180305, 180306, 180307, 180399, 180801, 180401,  ///
    180402, 180403, 180404, 180405, 180406, 180407, 180901, 180902, 180903, 180904,180905, 180999, 180807)
	
replace leisure = 1 if inlist(activity, ///
    181101, 181199, ///
    181201, 181202, 181203, 181204, 181205, 181206, 181299, ///
    181302, ///
    181401, 181499, ///
    181501, 181599)


	
replace a_nontravelling = 1 if (commuting!=1 & personal_care!=1 & housework_childcare!=1 & leisure!=1)



// control: all remaining activities must be commuting-related
tab a_nontravelling
tab activity if a_nontravelling==0

// mean happiness level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_nontravelling_hap = mean(schappy) if a_nontravelling==1 
bysort caseid: egen avenjoy_nontravelling_hap = min(aux_avenjoy_nontravelling_hap) 
label var avenjoy_nontravelling_hap "average happiness in all non-travelling activities"

count if avenjoy_nontravelling_hap==.						// individuals with only travelling activities
drop if avenjoy_nontravelling_hap==.	

// mean pain level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_nontravelling_pain = mean(scpain) if a_nontravelling==1
bysort caseid: egen avenjoy_nontravelling_pain = min(aux_avenjoy_nontravelling_pain) 
label var avenjoy_nontravelling_pain "average pain in all non-travelling activities"

count if avenjoy_nontravelling_pain==.						// individuals with only travelling activities
drop if avenjoy_nontravelling_pain==.		

// mean sadness level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_nontravelling_sad = mean(scsad) if a_nontravelling==1
bysort caseid: egen avenjoy_nontravelling_sad = min(aux_avenjoy_nontravelling_sad) 
label var avenjoy_nontravelling_sad "average sadness in all non-travelling activities"

count if avenjoy_nontravelling_sad==.						// individuals with only travelling activities
drop if avenjoy_nontravelling_sad==.		

// mean fatigue level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_nontravelling_tired = mean(sctired) if a_nontravelling==1 
bysort caseid: egen avenjoy_nontravelling_tired = min(aux_avenjoy_nontravelling_tired) 
label var avenjoy_nontravelling_tired "average tired in all non-travelling activities"

count if avenjoy_nontravelling_tired==.						// individuals with only travelling activities
drop if avenjoy_nontravelling_tired==.	

// mean fatigue level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_nontravelling_stress = mean(scstress) if a_nontravelling==1
bysort caseid: egen avenjoy_nontravelling_stress = min(aux_avenjoy_nontravelling_stress) 
label var avenjoy_nontravelling_stress "average stress in all non-travelling activities"

count if avenjoy_nontravelling_stress==.						// individuals with only travelling activities
drop if avenjoy_nontravelling_stress==.	

* total time devoted to non-travelling activities (at the diary-level)
bysort caseid: egen aux_time_nontravelling = sum(duration) if a_nontravelling==1
bysort caseid: egen time_nontravelling = min(aux_time_nontravelling) 
label var time_nontravelling "total time (min) in non-travelling act."




**** AVG non-commuting 
// mean happiness level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_noncommuting_hap = mean(schappy) if commuting==0 
bysort caseid: egen avenjoy_noncommuting_hap = min(aux_avenjoy_noncommuting_hap) 
label var avenjoy_noncommuting_hap "Avg. happiness in all non-commuting activities"

count if avenjoy_noncommuting_hap==.						// individuals with only travelling activities
drop if avenjoy_noncommuting_hap==.	

// mean pain level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_noncommuting_pain = mean(scpain) if commuting== 0
bysort caseid: egen avenjoy_noncommuting_pain = min(aux_avenjoy_noncommuting_pain) 
label var avenjoy_noncommuting_pain "Avg. pain in all non-commuting activities"

count if avenjoy_noncommuting_pain==.						// individuals with only travelling activities
drop if avenjoy_noncommuting_pain==.		

// mean sadness level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_noncommuting_sad = mean(scsad) if commuting==0
bysort caseid: egen avenjoy_noncommuting_sad = min(aux_avenjoy_noncommuting_sad) 
label var avenjoy_noncommuting_sad "Avg. sadness in all non-commuting activities"

count if avenjoy_noncommuting_sad==.						// individuals with only travelling activities
drop if avenjoy_noncommuting_sad==.		

// mean fatigue level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_noncomuting_tired = mean(sctired) if commuting==0 
bysort caseid: egen avenjoy_noncommuting_tired = min(aux_avenjoy_noncomuting_tired) 
label var avenjoy_noncommuting_tired "Avg. tired in all non-commuting activities"

count if avenjoy_noncommuting_tired==.						// individuals with only travelling activities
drop if avenjoy_noncommuting_tired==.	

// mean fatigue level in all non-travelling activities (at the diary-level)
bysort caseid: egen aux_avenjoy_noncommuting_stress = mean(scstress) if commuting==0
bysort caseid: egen avenjoy_noncommuting_stress = min(aux_avenjoy_noncommuting_stress) 
label var avenjoy_noncommuting_stress "Avg. stress in all non-travelling activities"

count if avenjoy_noncommuting_stress==.						// individuals with only travelling activities
drop if avenjoy_noncommuting_stress==.	

* total time devoted to non-travelling activities (at the diary-level)
*bysort caseid: egen aux_time_nontravelling = sum(duration) if a_nontravelling==1
*bysort caseid: egen time_nontravelling = min(aux_time_nontravelling) 
label var time_nontravelling "total time (min) in non-travelling act."

drop aux_* a_nontravelling

* summ
summ avenjoy_nontravelling_* time_nontravelling

// time in logs and the interaction
gen ln_time_nontravelling = ln(time_nontravelling)
gen int_nontravelling_hap = avenjoy_nontravelling_hap * ln_time_nontravelling
gen int_nontravelling_sad = avenjoy_nontravelling_sad * ln_time_nontravelling
gen int_nontravelling_pain = avenjoy_nontravelling_pain * ln_time_nontravelling
gen int_nontravelling_tired = avenjoy_nontravelling_tired * ln_time_nontravelling
gen int_nontravelling_stress = avenjoy_nontravelling_stress * ln_time_nontravelling


**** Time in non-commuting
gen double noncomm_min = duration
replace noncomm_min = 0 if commuting==1
bysort caseid: egen double time_noncommuting = total(noncomm_min)
gen double ln_time_noncommuting = ln(time_noncommuting) if time_noncommuting>0


*------------------------------------------------------
* CLEANING & SAMPLE (COMMUTING ACT)
*------------------------------------------------------

** COMMUTING CARPOOLING:

*market work
gen market_work_time=duration if activity==50101 | activity==50102 | activity==50103 | activity==50104 | activity==50199 | activity==50204 | activity==50205 | activity==50299 | activity==50301 | activity==50302 | activity==50303 | activity==50304 | activity==50399 | activity==59999 | activity==50305
replace market_work_time=0 if market_work_time==.

sort caseid
by caseid: egen total_market_work=sum(market_work_time)

// SAMPLE: travelling episodes (activity) with information on mode of transport (where)


keep if (commuting==1 | personal_care==1 | housework_childcare==1 | leisure==1) & where>=230
*keep if (activity==180501 | activity==180502 | activity==180503 | activity==180599) & where>=230 if we would only want commuting episodes

drop if activity >= 181601								 // unespecified activities
drop if where==239 | where==240				 // unespecified mode of transport
		
* keep diaries with at least 60 minutes of market work excluding commuting
keep if total_market_work>=60
		
* keep those who are working
keep if empstat==1

* exclude retired and student individuals
keep if schlcoll==1

* age
drop if age < 21
drop if age > 65	

// drop if non-respondent of well-being module
tab wb_resp, nol
drop if wb_resp==0
** Tambien lo hacemos antes

 // drop missings in well-being
drop if schappy == .
drop if scpain == .
drop if scsad == .
drop if sctired  == .
drop if scstress == .
		
// drop if no info of presence of others								
*drop if presence_missing==1 ya lo hacemos antes 


*** Rename to match previous do file 
rename withspouse_ep withspouse
rename withparents_ep withparents
rename withchild_ep withchild
rename withother_ep  withother
rename withnonfamily_ep withononfamily

drop if (alone==0 & withspouse==0  & withchild==0  & withparents==0 & withother==0  & withononfamily==0) 
// inspect
inspect


*------------------------------------------------------
* TRAVELLING INFORMATION
*------------------------------------------------------

// mode of transport
tab where

gen m_private = 0
replace m_private = 1 if where==230 | where==231

gen m_public = 0
replace m_public = 1 if where==233 | where==234  | where==236 |  where==237 |  where==238

gen m_physical = 0
replace m_physical = 1 if where==232 | where==235

gen green = 0
replace green = 1 if m_public==1 | m_physical==1

gen mode_transport = 0
replace mode_transport = 1 if m_private==1
replace mode_transport = 2 if m_public==1
replace mode_transport = 3 if m_physical==1
tab mode_transport

label variable m_private "Transport mode: Private vehicle"
label variable m_public "Transport mode: Public transport"
label variable m_physical  "Transport mode: Walking or bicycle"

/* Esta es la definición que hacen previamente de carpooling, aqui cambiamos 
// CARPOOLING
gen m_carpooling = 0
replace m_carpooling = 1 if m_private==1 & alone==0

gen m_driving_alone = 0
replace m_driving_alone = 1 if m_private==1 & alone==1

summ m_driving_alone m_carpooling m_public m_physical

// CARPOOLING WITH...
gen m_carpooling_spouse = 0
replace m_carpooling_spouse = 1 if m_carpooling==1 & withspouse==1

gen m_carpooling_parents = 0
replace m_carpooling_parents = 1 if m_carpooling==1 & (withparents==1)

gen m_carpooling_child = 0
replace m_carpooling_child = 1 if m_carpooling==1 & withchild==1

gen m_carpooling_otherhh = 0
replace m_carpooling_otherhh = 1 if m_carpooling==1 & withother==1

gen m_carpooling_nonhh = 0
replace m_carpooling_nonhh = 1 if m_carpooling==1 & withononfamily==1

gen aux = m_carpooling_spouse + m_carpooling_parents + m_carpooling_child + m_carpooling_otherhh + m_carpooling_nonhh
summ aux																// not mutually exclusive
drop aux
*/

// CARPOOLING
gen m_carpooling = 0
replace m_carpooling = 1 if m_private==1 & alone==0 & withononfamily==1
label variable m_carpooling "Carpooling for commuting (With non-household members)"

gen m_fampooling = 0 
replace m_fampooling = 1 if m_private==1 & alone==0 & withononfamily==0
label variable m_fampooling "Fampooling for commuting (Carpooling with household members)"

gen m_driving_alone = 0
replace m_driving_alone = 1 if m_private==1 & alone==1

label variable m_driving_alone "Driving alone for commuting"

// episode time
gen eptime = duration
label variable eptime "Duration in minutes"
gen ln_eptime = ln(duration)
gen eptime_sq = duration * duration
gen ln_eptime_sq = ln(eptime)*ln(eptime)


// Creating time use variables and proportion of carpooling
egen person = group(caseid), label

* total travelling
bysort person: egen timetravel = sum(eptime)
label var timetravel "Total time travelling by the individual"

* total travelling by each mode of transport
bysort person: egen aux_time_driving_alone = sum(eptime) if m_driving_alone==1
replace aux_time_driving_alone=0 if aux_time_driving_alone==.
bysort person: egen time_driving_alone = max(aux_time_driving_alone) 
label var time_driving_alone "Total time travelling driving alone by the individual"

bysort person: egen aux_time_carpooling = sum(eptime) if m_carpooling==1
replace aux_time_carpooling=0 if aux_time_carpooling==.
bysort person: egen time_carpooling = max(aux_time_carpooling) 
label var time_carpooling "Total time travelling carpooling by the individual"

bysort person: egen aux_time_fampooling = sum(eptime) if m_fampooling==1
replace aux_time_fampooling=0 if aux_time_fampooling==.
bysort person: egen time_fampooling = max(aux_time_fampooling) 
label var time_fampooling "Total time travelling  fampooling by the individual"

bysort person: egen aux_time_public = sum(eptime) if m_public==1
replace aux_time_public=0 if aux_time_public==.
bysort person: egen time_public = max(aux_time_public) 
label var time_public "Total time travelling by public transport by the individual"

bysort person: egen aux_time_physical = sum(eptime) if m_physical==1
replace aux_time_physical=0 if aux_time_physical==.
bysort person: egen time_physical = max(aux_time_physical) 
label var time_physical "Total time travelling by physical means by the individual"

gen aux = time_driving_alone + time_carpooling + time_public + time_physical + time_fampooling
compare aux timetravel
drop aux aux_*

* proportions
gen double prop_driving_alone = time_driving_alone/timetravel * 100
label var prop_driving_alone "Proportion by driving alone of total time travelling (%)"

gen double prop_carpooling = time_carpooling/timetravel * 100
label var prop_carpooling "Proportion by carpooling of total time travelling (%)"

gen double prop_fampooling = time_fampooling/timetravel * 100
label var prop_fampooling "Proportion by fampooling of total time travelling (%)"

gen double prop_public = time_public/timetravel * 100
label var prop_public "Proportion by public of total time travelling (%)"

gen double prop_physical = time_physical/timetravel * 100
label var prop_physical "Proportion by physical of total time travelling (%)"

gen aux = prop_driving_alone + prop_carpooling + prop_public + prop_physical
summ aux
drop aux


*------------------------------------------------------
* CREATING CONTROL VARIABLES
*------------------------------------------------------

// tagging individuals (for stats at the individual level)					// hacer luego de depurar base y sample
egen tagp = tag(person)														
order caseid person tagp
tab tagp

// individual level demographics 

* empleado
 tab empstat 
 tab empstat, nol
 
 gen emp = 0
 replace emp = 1 if empstat==1
 
 label variable emp "Working individual"
 
* native
gen native = 0
replace native = 1 if bpl==9900
tab native

label variable native "Native"

* region
tab region, gen(reg)

* male
gen male = 0
replace male = 1 if sex==1

label variable male "Male"

* weekend vs. weekday
gen weekend = 0
replace weekend = 1 if day==1 | day==7

label variable weekend "Weekend day"

gen weekday = 0
replace weekday = 1 if day==2 | day==3 | day==4 | day==5 | day==6

* age sq
gen age_sq = age * age

label variable age_sq "Age squared"

* living in couple
gen incouple =0
replace incouple = 1 if  marst==1 | marst==2

label variable incouple "Living with couple"


* educ
tab educ
tab educ, nol
gen secondary = 0
replace secondary=1 if educ==20 | educ==21 
tab secondary

label variable secondary "Educ. level: Secondary"

gen universitary = 0
replace universitary = 1 if educ==30 | educ==31 | educ==32 | ///
										   educ==40 | educ==41 | educ==42 | ///
										   educ==43 
label variable universitary "Educ. level: University"

* household composition
rename hh_size hhsize
rename hh_numkids nchild

label variable hhsize "Household size"
label variable nchild "Number of children"

* month
tab month, gen(month_)

* year
tab year, gen(year_)

* state
tab statefip, gen(state_)

* rename hhsize
rename hhsize hhldsize

* day
tab day, gen(day_)

/* weekly hs of work
tab hrsatrate, nol
drop if hrsatrate== 997 | hrsatrate== 998 | hrsatrate== 999 
rename hrsatrate hswork
*/

* occupational category 
tab occ2, nol
drop if occ2==9999

gen occupation = 0
replace occupation = 1 if occ2==110 | occ2==111
replace occupation = 2 if occ2==120 | occ2==121 | occ2==122 | occ2==123 | occ2==124 | occ2==125 | occ2==126 | occ2==127
replace occupation = 3 if occ2==130 | occ2==131 | occ2==132 | occ2==133 | occ2==134
replace occupation = 4 if occ2==140
replace occupation = 5 if occ2==150
replace occupation = 6 if occ2==160
replace occupation = 7 if occ2==170
replace occupation = 8 if occ2==180
replace occupation = 9 if occ2==190
replace occupation = 10 if occ2==200

tab occupation
tab occ2 

tab occupation, gen(occup_)


label variable occup_1  "Management, business and financial occup."
label variable occup_2  "Professional, scientific and technical occup."
label variable occup_3  "Service occupations"
label variable occup_4  "Sales occupations"
label variable occup_5  "Office and administrative support occup."
label variable occup_6  "Farming, fishing and forestry occup."
label variable occup_7  "Construction and extraction occup."
label variable occup_8  "Installation, maintenance and repair occup."
label variable occup_9  "Production occupations"
label variable occup_10 "Transportation and material moving occup."



* rename full-time
rename fullpart full_time



* daily market work
rename total_market_work dayhs_work

replace dayhs_work = dayhs_work / 60

label variable dayhs_work "Daily hours of work"

save "$data\travelling_episodes.dta", replace

keep if commuting == 1
save "$data\commuting_episodes.dta", replace