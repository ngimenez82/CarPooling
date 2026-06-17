 use "C:\data\CarPooling\Data\commuting_episodes.dta",clear 

 *** BUILD PORPORTION
 
 
* Duración en minutos por episodio (asegúrate de que duration está en minutos)
gen t_solo = m_driving_alone * duration
gen t_carp = m_carpooling    * duration
gen t_fam  = m_fampooling    * duration

* Total commuting en coche
gen t_carcomm = t_solo + t_carp + t_fam

* Shares dentro de commuting en coche
gen s_solo = t_solo / t_carcomm if t_carcomm>0
gen s_carp = t_carp / t_carcomm if t_carcomm>0
gen s_fam  = t_fam  / t_carcomm if t_carcomm>0

* Comprobación: debe sumar 1
gen s_sum = s_solo + s_carp + s_fam if t_carcomm>0
sum s_sum


collapse (sum) t_solo t_carp t_fam t_carcomm ///
         (first) native male incouple secondary universitary ///
                 nchild hh_numadults age age_sq occupation region year awbwt ///
         , by(caseid)


gen any_carp_nonhh = (t_carp>0) if t_carcomm>0
gen any_fampool    = (t_fam>0)  if t_carcomm>0

gen s_solo = t_solo / t_carcomm if t_carcomm>0
gen s_carp = t_carp / t_carcomm if t_carcomm>0
gen s_fam  = t_fam  / t_carcomm if t_carcomm>0

gen s_sum = s_solo + s_carp + s_fam if t_carcomm>0
sum s_sum


fracreg logit s_carp native male incouple secondary universitary ///
       nchild hh_numadults c.age c.age#c.age ///
       i.occupation i.region i.year [pw=awbwt] if t_carcomm>0, vce(robust)

margins, dydx(*)

* masa en 0 y en 1 (si existe)
sum s_carp if t_carcomm>0, detail
count if t_carcomm>0 & s_carp==0
count if t_carcomm>0 & s_carp>0
count if t_carcomm>0 & s_carp==1

fracreg logit s_fam native male incouple secondary universitary ///
       nchild hh_numadults c.age c.age#c.age ///
       i.occupation i.region i.year [pw=awbwt] if t_carcomm>0, vce(robust)

margins, dydx(*)



