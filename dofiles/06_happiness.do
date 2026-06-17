*******************************************
*******************************************
* OBJ. 2: WELL-BEING AND CARPOOLING
*******************************************
*******************************************
*use "C:\data\CarPooling\Data\commuting_episodes.dta",clear 
use "C:\data\CarPooling\Data\commuting_episodes.dta",clear
global results "C:\data\CarPooling\Results"

// creating well-being variables standarized: z-score
sum schappy 
generate double schappy_z=(schappy-r(mean))/r(sd) 
summ schappy_z 
count if schappy_z == .


sum scstress 
generate double scstress_z=(scstress-r(mean))/r(sd) 
summ scstress_z 
count if scstress_z == .

**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************

// HAPPINESS compared to non travelling  
reg schappy_z m_carpooling m_public m_physical m_fampooling /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					 state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$results\well-being_schappy_z_US_commuting.xls", replace bdec(3)	label	 


// HAPPINESS average happines in non-commuting
reg schappy_z m_carpooling m_public m_physical m_fampooling ///  
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild avenjoy_noncommuting_hap ///
					dayhs_work i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$results\well-being_schappy_z_US_commuting.xls", append bdec(3) label	

// HAPPINESS average happines in non-commuting and time non commuting
reg schappy_z m_carpooling m_public m_physical m_fampooling ///  
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work   c.ln_time_noncommuting##c.avenjoy_noncommuting_hap i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$results\well-being_schappy_z_US_commuting.xls", append bdec(3) label	

**************************************************************************************************************
**************************************************************************************************************
**************************************************************************************************************


// STRESS
reg scstress_z m_carpooling m_public m_physical m_fampooling /// 
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work i.occupation weekday ///
					 state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$results\well-being_scstress_z_US_commuting.xls", replace bdec(3)	label	 


// STRESS average happines in non-commuting
reg scstress_z m_carpooling m_public m_physical m_fampooling ///  
					ln_eptime ln_eptime_sq  ///
					age age_sq male native ///
					secondary universitary ///
					incouple hhldsize nchild ///
					dayhs_work avenjoy_nontravelling_hap i.occupation weekday ///
					state_* year_* month_* [pw=awbwt], robust cluster(person)
outreg2 using "$results\well-being_scstress_z_US_commuting.xls", append bdec(3) label						
