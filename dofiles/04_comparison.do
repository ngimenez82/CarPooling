 use "C:\Users\usuario\OneDrive - unizar.es\Carpooling\Data\atus_sample_f.dta",clear

* 0) Ordena por id persona y por orden temporal del episodio
sort caseid actline  

gen carpool_total_ep = (m_carpooling==1 | m_fampooling==1)


* 2) Pasa a nivel persona (si en algún episodio hizo eso)
bys caseid: egen carpool_total = max(carpool_total_ep)
bys caseid: egen carpool_nonhh = max(m_carpooling)
bys caseid: egen carpool_fam   = max(m_fampooling)

* 3) 1 fila por persona
bys caseid: keep if _n==1

* 4) Tasas ponderadas por año
mean carpool_total carpool_nonhh carpool_fam [pw=awbwt]


* número de episodios por persona
bysort caseid: gen n_episodios = _N

bysort caseid: keep if _n == 1
tab n_episodios
sum n_episodios, detail
