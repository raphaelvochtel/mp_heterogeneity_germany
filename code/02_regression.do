clear

*** county monthly labor market reaction ***************************************
if "${level}" == "county" & ("${ind}" == "unemployed" | "${ind}" == "unemp_rate") {	
	use "${out_path}/county_labor_panel.dta", clear

	* merge shocks
	merge m:1 year_month using "${out_path}/mp_shocks.dta"
	drop if _merge == 2
	drop _merge

	xtset ags year_month

	sort ags year_month
	tsset ags year_month

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
	duplicates drop ags, force
	sort ags

	keep ags name
	drop if ags == 0
	gen panelidnr = _n

	save "${sub_out_path}/dict.dta", replace
	restore

	/////

	foreach i in 6 12 18 24 30 36 {
		sort ags year_month
			
		qui reghdfe Delta_log_${ind}_F`i' c.mp_25bp_${sign}##i.ags Delta_log_${ind}_L*, absorb(ags year_month) vce(cluster land)
		
		eststo coeff
		esttab coeff using "${sub_out_path}/${ind}/${sign}/hm`i'.csv", replace

		preserve
		
		// clean
		import delimited "${sub_out_path}/${ind}/${sign}/hm`i'.csv", clear

		replace v1 = substr(v1, 3, length(v1) - 3)
		replace v2 = substr(v2, 3, length(v2) - 3)

		gen ind = 0
		replace ind = 1 if !missing(v1)
		replace v1 = v1[_n-1] if missing(v1)

		keep if regexm(v1, "ags#c.mp_25bp_${sign}")
		destring v2, replace ignore(* ( ) )
		gen t_stat_`i' = v2[_n+1]
		
		drop if ind == 0
		drop ind
				
		gen panelidnr = real(substr(v1, 1, strpos(v1, ".") - 1))
		drop v1
		drop if missing(t_stat_`i')

		merge 1:1 panelidnr using "${sub_out_path}/dict.dta"
		drop panelidnr _merge

		gen exakt_pc_`i' = (exp(v2) - 1) * 100
		drop v2
		order ags name exakt_pc_`i' t_stat_`i'

		save "${sub_out_path}/${ind}/${sign}/hm`i'.dta", replace
		erase "${sub_out_path}/${ind}/${sign}/hm`i'.csv"
		
		restore
	}

	/////

	use "${sub_out_path}/${ind}/${sign}/hm6.dta", clear
	erase "${sub_out_path}/${ind}/${sign}/hm6.dta"

	foreach i in 12 18 24 30 36 {
		merge 1:1 ags using "${sub_out_path}/${ind}/${sign}/hm`i'.dta"
		erase "${sub_out_path}/${ind}/${sign}/hm`i'.dta"
		drop _merge
	}

	save "${sub_out_path}/${ind}/${sign}/collected_results.dta", replace

	erase "${out_path}/county_labor_panel.dta"
	erase "${sub_out_path}/dict.dta"

}
