
*------------------------------------------------------
* Descriptive ANALYSIS
*------------------------------------------------------
// setting directory for results

*global results "C:\Users\34645\OneDrive - unizar.es\Carpooling\Results"
global results "C:\Users\usuario\Desktop\projects\Carpooling\Results"
use "C:\Users\usuario\Desktop\projects\Carpooling\Data\commuting_episodes.dta", clear 
*	Summary statistics for the time use variables
gen primary = 1 
replace primary = primary - universitary - secondary

bysort caseid: egen commute_time_mean = mean(duration)

	*** EPISODE INFORMATION - we do not difference between carpoolers or non carpoolers since there is a possibility to not go by car ***
outreg2 using "$results\01_SumStats.xls" [aw=awbwt], ///
    sum(log) eqkeep(mean sd) ///
    keep(m_* timetravel) ///
    excel bdec(3) label replace ///
    ctitle("Total")

	*** INDIVIDUAL INFORMATION ***
preserve
bys person: keep if _n==1
outreg2 using "$results\02_SumStats.xls" [aw=awbwt], ///
    sum(log) eqkeep(mean sd) ///
    keep(age native male incouple primary secondary universitary hhldsize nchild hh_numadults) ///
    excel bdec(3) label replace ///
    ctitle("Total")
	
outreg2 using "$results\03_SumStats.xls" [aw=awbwt], ///
	sum(log) eqkeep(mean sd) ///
 keep(dayhs_work occup_1 occup_2 occup_3 occup_4 occup_5 occup_6 occup_7 occup_8 occup_9 occup_10 dayhs_work) ///
 excel bdec(3) label replace ///
    ctitle("Total")
restore


	*** GENERATE CARPOOLER IDENTIFIFIER ***
gen carpool_total_ep = (m_carpooling==1 | m_fampooling==1)


* 2) Pasa a nivel persona (si en algún episodio hizo eso)
bys caseid: egen carpool_total = max(carpool_total_ep)
bys caseid: egen carpool_nonhh = max(m_carpooling)
bys caseid: egen carpool_fam   = max(m_fampooling)

label variable carpool_total  "Any carpooling (incl. household)"
label variable carpool_nonhh  "Carpooling (non-household)"
label variable carpool_fam    "Carpooling (household)"

preserve
bys person: keep if _n==1
outreg2 using "$results\04_SumStats.xls" [aw=awbwt], ///
    sum(log) eqkeep(mean sd) ///
    keep(carpool_total carpool_nonhh carpool_fam) ///
    excel bdec(3) label replace ///
    ctitle("Total")
restore


	*** EPISODE WELL-BEING INFORMATION ***

* Outcomes
global wb "scpain schappy scsad sctired scstress"

* Output file
local out "$results\05_SumStats.xls"

* Ensure no missing in group indicators
foreach v in m_driving_alone m_carpooling{
    replace `v' = 0 if missing(`v')
}

tempvar tag

*------------------------------*
* Column 1: Driving alone
*------------------------------*
count if m_driving_alone==1 | m_fampooling ==1 
local N_ep = r(N)

egen `tag' = tag(caseid) if m_driving_alone==1 | m_fampooling ==1
count if `tag'==1
local N_id = r(N)
drop `tag'

outreg2 using "`out'" [aw=awbwt] if m_driving_alone==1 | m_fampooling ==1, ///
    sum(log) eqkeep(mean sd) keep($wb) ///
    excel bdec(3) label replace ///
    ctitle("No carpool") ///
    addstat("Episodes", `N_ep', "Individuals", `N_id')

*------------------------------*
* Column 2: Carpool (non-household)
*------------------------------*
count if m_carpooling==1
local N_ep = r(N)

egen `tag' = tag(caseid) if m_carpooling==1
count if `tag'==1
local N_id = r(N)
drop `tag'

outreg2 using "`out'" [aw=awbwt] if m_carpooling==1, ///
    sum(log) eqkeep(mean sd) keep($wb) ///
    excel bdec(3) label append ///
    ctitle("Carpool (non-hh)") ///
    addstat("Episodes", `N_ep', "Individuals", `N_id')
	
	
* Asegura wb y grupo
global wb "scpain schappy scsad sctired scstress"
replace m_carpooling = 0 if missing(m_carpooling)

* Archivo temporal correcto (NO uses `T' si no lo definiste como tempfile)
tempfile T
tempname post

postfile `post' str20 var ///
    double m0 m1 diff lb ub p ///
    using `T', replace

foreach y of global wb {

    * Regresión de diferencia de medias: beta = mean(1) - mean(0)
    quietly regress `y' i.m_carpooling [pw=awbwt], vce(cluster caseid)

    * Media grupo 0 = constante
    local mean0 = _b[_cons]

    * Diferencia carpool - no carpool = coef de 1.m_carpooling
    local d     = _b[1.m_carpooling]
    local lb    = _b[1.m_carpooling] - invttail(e(df_r),0.025)*_se[1.m_carpooling]
    local ub    = _b[1.m_carpooling] + invttail(e(df_r),0.025)*_se[1.m_carpooling]

    * p-valor del coeficiente
    test 1.m_carpooling
    local pv = r(p)

    * Media grupo 1 = mean0 + diff
    local mean1 = `mean0' + `d'

    post `post' ("`y'") (`mean0') (`mean1') (`d') (`lb') (`ub') (`pv')
}

postclose `post'
use `T', clear

format m0 m1 diff lb ub %9.3f
format p %6.4f
list, noobs abbrev(20)


	
*******************************************
*******************************************
* OBJ. 1: WHO DOES CARPOOLING?
*******************************************
*******************************************

/*
bys person: keep if _n==1

 *** WE GENERATE DUMMY INCOME VARIABLES ***
* Crear income en 3 grupos
gen byte inc_group = .

* Bajo: < $40,000  (1–10)
replace inc_group = 1 if inrange(famincome, 1, 10)

* Medio: $40,000–$74,999 (11–13)
replace inc_group = 2 if inrange(famincome, 11, 13)

* Alto: $75,000+ (14–16)
replace inc_group = 3 if inrange(famincome, 14, 16)

label define inc_group_lbl ///
    1 "Low income (<$40k)" ///
    2 "Middle income ($40k–$74k)" ///
    3 "High income ($75k+)"
label values inc_group inc_group_lbl

* Dummy para income no reportado
gen byte inc_noreport = inlist(famincome, 996, 997, 998)
label var inc_noreport "Income not reported"
*/

*** MODELO PRINCIPAL 
bys person: keep if _n==1
*============================*
* Table 3: Logit (AMEs)
*============================*
gen commute10 = commute_time_mean/10
local out "$results\Table3_Logit_AME.xls"

* ---------- Column (1): Main ----------
logit carpool_nonhh native male incouple secondary universitary ///
     nchild hh_numadults c.age c.age_sq ///
     i.occupation i.region i.year ///
     [pw=awbwt], vce(robust)

margins, dydx(*) post

outreg2 using "`out'", excel replace bdec(3) se dec(3) ///
    keep(native male incouple secondary universitary nchild hh_numadults age age_sq) ///
    ctitle("Sociodemographic") ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Metro controls", "No", "MSA size", "No" ,"SE","Robust") ///
    label
	
	* ---------- Column (2): Metro vs non metro ----------
logit carpool_nonhh native male incouple secondary universitary ///
     nchild hh_numadults c.age c.age_sq ///
     i.occupation i.region i.year i.metro ///
     [pw=awbwt] if metro!=3 & metro!=5, vce(robust)


margins, dydx(*) post

outreg2 using "`out'", excel append bdec(3) se dec(3) ///
    keep(native male incouple secondary universitary nchild hh_numadults age age_sq i.metro) ///
    ctitle("Metro status") ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Metro controls", "Yes", "MSA size", "No" ,"SE","Robust") ///
    label
	
		* ---------- Column (3): MSA Size ----------
logit carpool_nonhh native male incouple secondary universitary ///
     nchild hh_numadults c.age c.age_sq ///
     i.occupation i.region i.year i.msasize ///
     [pw=awbwt] if msasize!=0, vce(robust)


margins, dydx(*) post

outreg2 using "`out'", excel append bdec(3) se dec(3) ///
    keep(native male incouple secondary universitary nchild hh_numadults age age_sq i.msasize) ///
    ctitle("MSA size") ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Metro controls", "No", "MSA size", "Yes" ,"SE","Robust") ///
    label

			* ---------- Column (4): MSA Size + time----------
logit carpool_nonhh native male incouple secondary universitary commute10 ///
     nchild hh_numadults c.age c.age_sq ///
     i.occupation i.region i.year i.msasize ///
     [pw=awbwt] if msasize!=0, vce(robust)


margins, dydx(*) post

outreg2 using "`out'", excel append bdec(3) se dec(3) ///
    keep(native male incouple secondary universitary nchild hh_numadults age age_sq i.msasize commute10) ///
    ctitle("MSA size") ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Metro controls", "No", "MSA size", "Yes" ,"SE","Robust") ///
    label

	
	
*============================*
* Table 4: Logit (AMEs) mechanisms 
*============================*
local out1 "$results\Table4_Logit_AME_interactions.xls"

*** Check channels of education, metropolitan status x education (Column 1)
logit carpool_nonhh native male incouple secondary ///
     i.metro##i.universitary ///
     nchild hh_numadults c.age c.age_sq ///
     i.occupation i.region i.year ///
     [pw=awbwt] if metro!=3 & metro!=5, vce(robust)

margins metro, dydx(universitary)
margins r.metro, dydx(universitary) 

outreg2 using "`out1'", excel replace bdec(3) se dec(3) ///
    keep(native male incouple secondary universitary nchild hh_numadults age age_sq i.metro##i.universitary) ///
    ctitle("MSA size") ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Metro controls", "Yes", "MSA size", "No" ,"SE","Robust") ///
    label

*** Check channels of education, msa size x education

logit carpool_nonhh native male incouple secondary ///
     i.msasize##i.universitary ///
     nchild hh_numadults c.age c.age_sq ///
     i.occupation i.region i.year ///
     [pw=awbwt] if msasize!=0, vce(robust)
margins msasize, dydx(universitary) post

margins msasize, dydx(universitary)
margins r.msasize, dydx(universitary) 

outreg2 using "`out1'", excel append bdec(3) se dec(3) ///
    keep(native male incouple secondary universitary nchild hh_numadults age age_sq i.msasize##i.universitary) ///
    ctitle("MSA size") ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Metro controls", "No", "MSA size", "Yes" ,"SE","Robust") ///
    label
	
	

*********************************************************************************

logit carpool_nonhh native male incouple secondary ///
     i.msasize##i.universitary ///
     nchild hh_numadults c.age c.age_sq commute_time_mean ///
     i.occupation i.region i.year ///
     [pw=awbwt] if msasize!=0, vce(robust)
margins msasize, dydx(universitary) post

margins msasize, dydx(universitary)
margins r.msasize, dydx(universitary) 

***ROBUSTNESS 

logit carpool_nonhh native male incouple secondary universitary ///
     nchild hh_numadults c.age c.age#c.age ///
     i.occupation i.region i.year ///
     i.inc_group ///
     [pw=awbwt], vce(robust)

	 *** Interaction 
logit carpool_nonhh native male incouple secondary universitary ///
     nchild hh_numadults c.age c.age#c.age ///
     i.occupation i.region##i.year ///
     [pw=awbwt], vce(robust)


reg prop_carpooling age age_sq male native ///
								secondary universitary  ///
								incouple hhldsize nchild ///
								dayhs_work i.occupation weekday ///
								state_* year_* month_* [pw=awbwt] if tagp==1, robust cluster(person)
outreg2 using "$results\who_US_commuting.xls", replace bdec(3)	


*******************************************
*******************************************
* OBJ. 2: WELL-BEING AND CARPOOLING
*******************************************
*******************************************

clear all 
global results "C:\Users\usuario\Desktop\projects\Carpooling\Results"
use "C:\Users\usuario\Desktop\projects\Carpooling\Data\commuting_episodes.dta", clear 
local wb "scpain schappy scsad sctired scstress"

foreach v in `wb'{
    sum `v'
    gen double `v'_z = (`v' - r(mean)) / r(sd)
    summ `v'_z
    count if `v'_z == .
}


* 1) calcular medias
sum ln_time_noncommuting
gen ln_time_noncommuting_c = ln_time_noncommuting - r(mean)

sum avenjoy_noncommuting_stress
gen avenjoy_noncommuting_stress_c = avenjoy_noncommuting_stress - r(mean)

sum avenjoy_noncommuting_hap
gen avenjoy_noncommuting_hap_c = avenjoy_noncommuting_hap - r(mean)



label variable ln_eptime "Log commuting duration"
label variable ln_eptime_sq "Log commuting duration (Squared)"
label variable ln_time_noncommuting_c "Log non-commuting time spent"
label variable avenjoy_noncommuting_stress_c "Avg stress non-commuting"
label variable avenjoy_noncommuting_hap_c "Avg hapiness non-commuting"



*========================
* Model 1
*========================
reg schappy_z m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)

outreg2 using "$results\well-being_schappy_z_US_commuting.xls", replace ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons


*========================
* Model 2 (add avg non-commuting happiness)
*========================
reg schappy_z m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild avenjoy_noncommuting_hap_c ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)

outreg2 using "$results\well-being_schappy_z_US_commuting.xls", append ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         avenjoy_noncommuting_hap_c) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons


*========================
* Model 3 (interaction: ln time noncommuting × avg noncommuting happiness)
*========================
reg schappy_z m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    dayhs_work c.ln_time_noncommuting_c##c.avenjoy_noncommuting_hap_c ///
    i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)

outreg2 using "$results\well-being_schappy_z_US_commuting.xls", append ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         ln_time_noncommuting_c  avenjoy_noncommuting_hap_c ///
         c.ln_time_noncommuting_c#c.avenjoy_noncommuting_hap_c) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons


*========================
* STRESS - Model 1
*========================
reg scstress_z m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)

outreg2 using "$results\well-being_scstress_z_US_commuting.xls", replace ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons


*========================
* STRESS - Model 2 (add avg non-commuting stress)
*========================
reg scstress_z m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild avenjoy_noncommuting_stress_c ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)

outreg2 using "$results\well-being_scstress_z_US_commuting.xls", append ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         avenjoy_noncommuting_stress_c) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons


*========================
* STRESS - Model 3 (interaction: ln time noncommuting × avg noncommuting stress)
*========================
reg scstress_z m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    dayhs_work c.ln_time_noncommuting_c##c.avenjoy_noncommuting_stress_c ///
    i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)

outreg2 using "$results\well-being_scstress_z_US_commuting.xls", append ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         ln_time_noncommuting avenjoy_noncommuting_stress_c ///
         c.ln_time_noncommuting_c#c.avenjoy_noncommuting_stress_c) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons




****  ALTERNATIVES  

	
**** JOB STRAIN 

egen z_dayhs_work = std(dayhs_work)
egen z_nchild     = std(nchild)
gen jobstrain = z_dayhs_work + z_nchild
label var jobstrain "Job strain (std hours + std children)"

reg scstress_z ///
    m_carpooling##c.jobstrain ///
    m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    i.occupation weekday i.msasize ///
    state_* year_* month_* ///
    [pw=awbwt], vce(cluster person)

margins, dydx(m_carpooling) at(jobstrain=(-2 -1 0 1 2))
		
*------------------------------------------------------
* ROBUSTNESS
*------------------------------------------------------		

*************************
* OBJ. 1: TOBIT MODEL
*************************	

tobit prop_carpooling age age_sq male native ///
								secondary universitary  ///
								incouple hhldsize nchild ///
								dayhs_work i.occupation weekday ///
								year_* month_* [pw=awbwt] if tagp==1, ll(0) vce(cluster person) 
margins, dydx(age age_sq male native secondary universitary incouple hhldsize nchild dayhs_work i.occupation weekday) predict(ystar(0,.))


*************************
* OBJ. 2: OLOGIT MODEL
*************************	

// HAPPINESS
ologit schappy  m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)
	
outreg2 using "$results\well-being_mnl.xls", replace ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons

						

// HAPPINESS average happines in non-commuting
ologit schappy m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild avenjoy_noncommuting_hap_c ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person) 

outreg2 using "$results\well-being_mnl.xls", append ///
    bdec(3) label ///
    keep (m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         ln_time_noncommuting_c  avenjoy_noncommuting_hap_c ///
         ) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons
					

ologit schappy m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild avenjoy_noncommuting_hap_c ///
    dayhs_work i.occupation weekday i.msasize ///
				    c.ln_time_noncommuting_c##c.avenjoy_noncommuting_hap_c ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)

outreg2 using "$results\well-being_mnl.xls", append ///
    bdec(3) label ///
    keep (m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         ln_time_noncommuting_c  avenjoy_noncommuting_hap_c ///
         c.ln_time_noncommuting_c#c.avenjoy_noncommuting_hap_c) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons	


// STRESS
ologit scstress  m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person)
	
outreg2 using "$results\well-being_mnl_stress.xls", replace ///
    bdec(3) label ///
    keep(m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons

						

// Stress average happines in non-commuting
ologit scstress m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild avenjoy_noncommuting_stress_c ///
    dayhs_work i.occupation weekday i.msasize ///
    state_* year_* month_* [pw=awbwt], vce(cluster person) 

outreg2 using "$results\well-being_mnl_stress.xls", append ///
    bdec(3) label ///
    keep (m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         ln_time_noncommuting_c  avenjoy_noncommuting_stress_c ///
         ) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons
					

ologit scstress m_carpooling m_public m_physical m_fampooling ///
    ln_eptime ln_eptime_sq ///
    age age_sq male native ///
    secondary universitary ///
    incouple hhldsize nchild avenjoy_noncommuting_stress_c ///
    dayhs_work i.occupation weekday i.msasize ///
	c.ln_time_noncommuting_c##c.avenjoy_noncommuting_stress_c ///
	state_* year_* month_*  [pw=awbwt], robust cluster(person)

outreg2 using "$results\well-being_mnl_stress.xls", append ///
    bdec(3) label ///
    keep (m_carpooling m_public m_physical m_fampooling ln_eptime ln_eptime_sq ///
         ln_time_noncommuting_c  avenjoy_noncommuting_stress_c ///
         c.ln_time_noncommuting_c#c.avenjoy_noncommuting_stress_c) ///
    addtext("Occupation FE","Yes","Region FE","Yes","Year FE","Yes","Month FE","Yes", ///
            "MSA size","Yes","SE","Clustered (person)") ///
    nonotes nocons	



*************************************************************************
***** ELIMINAMOS DEL OBJ 2. LOS DEMAS STATES DE WELL-BEING *****
*************************************************************************

*****************
/* LO SACAMOS DEL ANALISIS:

sum scsad 
generate double scsad_z=(scsad-r(mean))/r(sd) 
summ scsad_z 
count if scsad_z == .

sum scstress 
generate double scstress_z=(scstress-r(mean))/r(sd) 
summ scstress_z 
count if scstress_z ==.

sum sctired 
generate double sctired_z=(sctired-r(mean))/r(sd) 
summ sctired_z 
count if sctired_z ==.

sum scpain 
generate double scpain_z=(scpain-r(mean))/r(sd) 
summ scpain_z 
count if scpain_z ==.

// SADNESS
reg scsad_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scsad_z_US_commuting.xls", replace bdec(3)		
					
* with whom	
reg scsad_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scsad_z_US_commuting.xls", append bdec(3)	

// SADNESS average happines in non-commuting
reg scsad_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_sad ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scsad_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg scsad_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_sad ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scsad_z_US_commuting.xls", append bdec(3)	

// SADNESS average in non-commuting
reg scsad_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_sad ///
					ln_time_nontravelling int_nontravelling_sad ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scsad_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg scsad_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///				   
					avenjoy_nontravelling_sad ///
					ln_time_nontravelling int_nontravelling_sad ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scsad_z_US_commuting.xls", append bdec(3)	

*****************

// STRESS
reg scstress_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scstress_z_US_commuting.xls", replace bdec(3)		
					
* with whom	
reg scstress_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scstress_z_US_commuting.xls", append bdec(3)	

// STRESS average  in non-commuting
reg scstress_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_stress ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scstress_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg scstress_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_stress ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scstress_z_US_commuting.xls", append bdec(3)	

// STRESS with average in non-commuting
reg scstress_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_stress ///
					ln_time_nontravelling int_nontravelling_stress ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scstress_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg scstress_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_stress ///
					ln_time_nontravelling int_nontravelling_stress ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scstress_z_US_commuting.xls", append bdec(3)	


*****************

// TIRED
reg sctired_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_sctired_z_US_commuting.xls", replace bdec(3)		
					
* with whom	
reg sctired_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_sctired_z_US_commuting.xls", append bdec(3)	

// TIRED average  in non-commuting
reg sctired_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_tired ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_sctired_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg sctired_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_tired ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_sctired_z_US_commuting.xls", append bdec(3)	

// TIRED with average in non-commuting
reg sctired_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_tired ///
					ln_time_nontravelling int_nontravelling_tired ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_sctired_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg sctired_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_tired ///
					ln_time_nontravelling int_nontravelling_tired ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_sctired_z_US_commuting.xls", append bdec(3)	


*****************
// PAIN
reg scpain_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scpain_z_US_commuting.xls", replace bdec(3)		
					
* with whom	
reg scpain_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scpain_z_US_commuting.xls", append bdec(3)	

// TIRED average  in non-commuting
reg scpain_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_pain ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scpain_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg scpain_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_pain ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scpain_z_US_commuting.xls", append bdec(3)	

// TIRED with average in non-commuting
reg scpain_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					avenjoy_nontravelling_pain ///
					ln_time_nontravelling int_nontravelling_pain ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scpain_z_US_commuting.xls", append bdec(3)		
					
* with whom	
reg scpain_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
				    avenjoy_nontravelling_pain ///
					ln_time_nontravelling int_nontravelling_pain ///
					state_* year_* month_*  [pw=awbwt], robust cluster(person)
outreg2 using "$data\well-being_scpain_z_US_commuting.xls", append bdec(3)	
*/




**** robustness

*****************
/*
// SADNESS
ologit scsad_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scsad_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// SADNESS average happines in non-commuting
ologit scsad_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_sad ///
					year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scsad_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_sad ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// SADNESS average in non-commuting
ologit scsad_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_sad ///
					ln_time_nontravelling int_nontravelling_sad ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scsad_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///				   
					avenjoy_nontravelling_sad ///
					ln_time_nontravelling int_nontravelling_sad ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

*****************

// STRESS
ologit scstress_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scstress_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// STRESS average  in non-commuting
ologit scstress_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_stress ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scstress_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_stress ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// STRESS with average in non-commuting
ologit scstress_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_stress ///
					ln_time_nontravelling int_nontravelling_stress ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scstress_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_stress ///
					ln_time_nontravelling int_nontravelling_stress ///
					 year_* month_*  [pw=awbwt], robust cluster(person)


*****************

// TIRED
ologit sctired_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit sctired_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// TIRED average  in non-commuting
ologit sctired_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_tired ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit sctired_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_tired ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// TIRED with average in non-commuting
ologit sctired_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_tired ///
					ln_time_nontravelling int_nontravelling_tired ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit sctired_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_tired ///
					ln_time_nontravelling int_nontravelling_tired ///
					 year_* month_*  [pw=awbwt], robust cluster(person)


*****************
// PAIN
ologit scpain_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scpain_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// TIRED average  in non-commuting
ologit scpain_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_pain ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scpain_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_pain ///
					 year_* month_*  [pw=awbwt], robust cluster(person)

// TIRED with average in non-commuting
ologit scpain_z m_carpooling m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
					avenjoy_nontravelling_pain ///
					ln_time_nontravelling int_nontravelling_pain ///
					 year_* month_* [pw=awbwt], robust cluster(person)
					
* with whom	
ologit scpain_z m_carpooling_spouse m_carpooling_parents ///
					m_carpooling_child m_carpooling_otherhh ///
					m_carpooling_nonhh ///
					m_public m_physical /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					full_time i.occupation weekday ///
				    avenjoy_nontravelling_pain ///
					ln_time_nontravelling int_nontravelling_pain ///
				 year_* month_*  [pw=awbwt], robust cluster(person)
*/