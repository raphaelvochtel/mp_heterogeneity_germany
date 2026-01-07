clear

****

global ind unemployed 	// unemp_rate unemployed
global sign expan 		// all expan contr

****

use "${out_path}/raw_panel.dta", clear

sort county_id year_month
tsset county_id year_month

/////

foreach i in 1 2 4 7 10 13 25 {
	gen log_${ind}_L`i' = log(L`i'.${ind})
}

foreach i in 2 4 7 10 13 25 {
	gen Delta_log_${ind}_L`i' = log_${ind}_L1 - log_${ind}_L`i' // only 1, 3, 6, 9, 12, 24 months-pre-trend
}

forvalues i = 1/36 {
	gen log_${ind}_F`i' = log(F`i'.${ind})
}

forvalues i = 1/36 {
	gen Delta_log_${ind}_F`i' = log_${ind}_F`i' - log_${ind}_L1
}

drop log_*

/////

preserve
duplicates drop county_id, force
sort county_id

keep county_id name
drop if county_id == 0
gen panelidnr = _n

save "${out_path}/dict.dta", replace
restore

/////

foreach i in 6 12 18 24 30 36 {
	sort county_id year_month
		
	qui reghdfe Delta_log_${ind}_F`i' c.mp_25bp_${sign}##i.county_id Delta_log_${ind}_L*, absorb(county_id year_month) vce(cluster land)
	
	eststo coeff
	esttab coeff using "${out_path}/${ind}/${sign}/hm`i'.csv", replace

	preserve
	
	// clean
	import delimited "${out_path}/${ind}/${sign}/hm`i'.csv", clear

	replace v1 = substr(v1, 3, length(v1) - 3)
	replace v2 = substr(v2, 3, length(v2) - 3)

	gen ind = 0
	replace ind = 1 if !missing(v1)
	replace v1 = v1[_n-1] if missing(v1)

	keep if regexm(v1, "county_id#c.mp_25bp_${sign}")
	destring v2, replace ignore(* ( ) )
	gen t_stat_`i' = v2[_n+1]
	
	drop if ind == 0
	drop ind
			
	gen panelidnr = real(substr(v1, 1, strpos(v1, ".") - 1))
	drop v1
	drop if missing(t_stat_`i')

	merge 1:1 panelidnr using "${out_path}/dict.dta"
	drop panelidnr _merge

	gen exakt_pc_`i' = (exp(v2) - 1) * 100
	drop v2
	order county_id name exakt_pc_`i' t_stat_`i'

    save "${out_path}/${ind}/${sign}/hm`i'.dta", replace
	erase "${out_path}/${ind}/${sign}/hm`i'.csv"
	
	restore
}
erase "${out_path}/dict.dta"


/////

use "${out_path}/${ind}/${sign}/hm6.dta", clear
erase "${out_path}/${ind}/${sign}/hm6.dta"

foreach i in 12 18 24 30 36 {
	merge 1:1 county_id using "${out_path}/${ind}/${sign}/hm`i'.dta"
	erase "${out_path}/${ind}/${sign}/hm`i'.dta"
	drop _merge
}

save "${out_path}/${ind}/${sign}/collected_results.dta", replace
