*** Preprocessing raw file de ATUS 
set more off



use "$data\atus_raw.dta", clear 


*** Cargamos solo aquellos actividades registradas
keep if rectype=="1"
drop pernum - sexw
drop if missing(strata)
sort caseid
save "$data\_atus_household", replace 

clear

use "$data\atus_raw.dta", clear
keep if rectype=="2"
drop strata - hh_numadults
drop actline - sexw
sort caseid lineno
save "$data\_atus_person", replace 


clear

use "$data\atus_raw.dta", clear
keep if rectype=="3"
drop strata - bls_work_workrel
sort caseid actline
save "$data\_atus_activity", replace 

clear

use "$data\atus_raw.dta", clear
keep if rectype=="4"
drop strata - rawbwt
sort caseid actlinew
save "$data\_atus_who", replace 

clear

*** Creamos WHO por episodio 

use "$data\_atus_who", clear  


* 1) Presencia missing (Refused / Don't know / Blank)
gen byte presence_missing = inlist(relatew, 9996, 9997, 9998)

* 2) Indicador de "acompañante válido" en esta fila WHO
*    (excluye Alone=100 y excluye missing de presencia)
gen byte comp_valid = (presence_missing==0 & relatew!=100)

* 3) Flags por tipo (por fila WHO)
gen byte withspouse    = comp_valid & inlist(relatew, 200, 201)
gen byte withparents   = comp_valid & inlist(relatew, 204, 400)
gen byte withchild     = comp_valid & inlist(relatew, 202, 203, 207, 300, 406)
gen byte withother     = comp_valid & inlist(relatew, 205, 206, 208, 209, 401, 402)
gen byte withnonfamily = comp_valid & inlist(relatew, 210, 403, 404, 405, 407, 408, 409, 410, 411)

* 4) Género de acompañantes (por fila WHO) - solo si comp_valid
gen byte comp_male   = comp_valid & (sexw==1)
gen byte comp_female = comp_valid & (sexw==2)

* 6) Agregar por episodio (caseid, actlinew): 1 fila por actividad
bys caseid serial actlinew: egen withspouse_ep        = max(withspouse)
bys caseid actlinew: egen withparents_ep       = max(withparents)
bys caseid serial actlinew: egen withchild_ep         = max(withchild)
bys caseid serial actlinew: egen withother_ep         = max(withother)
bys caseid serial actlinew: egen withnonfamily_ep     = max(withnonfamily)
bys caseid serial actlinew: egen presence_missing_ep  = max(presence_missing)

bys caseid serial actlinew: egen n_companions = total(comp_valid)
bys caseid serial actlinew: egen n_male       = total(comp_male)
bys caseid serial actlinew: egen n_female     = total(comp_female)

* 7) Dummy "viaja solo" a nivel episodio (más robusto que usar flags)
gen byte alone = .
replace alone = 1 if presence_missing_ep==0 & n_companions==0
replace alone = 0 if presence_missing_ep==0 & n_companions>0
label var alone "Alone during activity (episode-level)"


drop if presence_missing_ep == 1
* 8) Reducir a 1 fila por episodio y preparar merge con ACTIVITY
keep caseid actlinew serial ///
     withspouse_ep withparents_ep withchild_ep withother_ep withnonfamily_ep ///
      alone ///
     n_companions n_male n_female ///
 

duplicates drop
rename actlinew actline
isid caseid serial actline
save "$data\_atus_who_flags", replace


*=========================================================
* 1) ACTIVITY + WHO_FLAGS  -> 1 fila por actividad
*=========================================================
use "$data\_atus_activity", clear

* Merge WHO agregado por episodio
merge m:1 caseid serial actline using "$data\_atus_who_flags"
drop if _merge == 1
drop _merge

save "$data\_atus_activity_plus_who", replace


*=========================================================
* 2) Añadir PERSON (respondiente) por caseid
*=========================================================
use "$data\_atus_activity_plus_who", clear

merge m:1 caseid serial using "$data\_atus_person"
tab _merge
drop if _merge==2
drop _merge

save "$data\_atus_activity_plus_who_person", replace


*=========================================================
* 3) Añadir HOUSEHOLD por caseid
*=========================================================
use "$data\_atus_activity_plus_who_person", clear

merge m:1 caseid using "$data\_atus_household"
tab _merge
drop if _merge==2
drop _merge

* (Opcional) comprobar unicidad final
isid caseid serial actline

compress
save "$data\atus_sample_f.dta", replace





















