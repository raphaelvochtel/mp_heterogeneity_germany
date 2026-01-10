clear

*** MP shocks ******************************************************************
// from Jarocinski, M. and Karadi, P. (2020) Deconstructing  Monetary Policy Surprises - The Role of Information Shocks, AEJ:Macro, DOI: 10.1257/mac.20180090
import delimited "${src_path}/ecb_shocks_1999_2025.csv", clear

gen year_month = ym(year, month)
format year_month %tm
gen mp_25bp_all = mp_median/0.25
gen cbi_25bp_all = cbi_median/0.25
keep year_month mp_25bp_all cbi_25bp_all

gen D_mp_contr = 0
replace D_mp_contr = 1 if mp_25bp_all > 0
gen mp_25bp_contr = mp_25bp_all * D_mp_contr

gen D_mp_expan = 0
replace D_mp_expan = 1 if mp_25bp_all < 0
gen mp_25bp_expan = mp_25bp_all * D_mp_expan * (-1)

gen D_cbi_contr = 0
replace D_cbi_contr = 1 if cbi_25bp_all > 0
gen cbi_25bp_contr = cbi_25bp_all * D_cbi_contr

gen D_cbi_expan = 0
replace D_cbi_expan = 1 if cbi_25bp_all < 0
gen cbi_25bp_expan = cbi_25bp_all * D_cbi_expan * (-1)

drop D_*

save "${out_path}/mp_shocks.dta", replace

*** county labor panel 1998:01-2024:12 *****************************************
if "${level}" == "county" & ("${ind}" == "unemployed" | "${ind}" == "unemp_rate") {
	* Unemployed
	import excel "${src_path}/counties_unemployed_1998_2024_m.xlsx", sheet("Auswertung") cellrange(A13:MN412) clear

	gen name = substr(A, 7, .)
	gen agsstr = substr(A, 1, 5)
	gen land = substr(agsstr, 1, 2)

	encode agsstr, gen(ags)
	drop A-AB agsstr

	local i = 1
	foreach v of varlist AC-MN {
		rename `v' unemployed`i'
		local ++i
	}

	reshape long unemployed, i(ags name) j(t)
	gen year_month = ym(1998, 1) + t - 1
	format year_month %tm
	drop t

	order ags name year_month unemployed

	tempfile unemployed
	save `unemployed'


	* Unemployment Rate
	import excel "${src_path}/counties_unemployment_rate_1998_2024_m.xlsx", sheet("Monatszahlen") cellrange(A13:LM412) clear

	gen name = substr(A, 7, .)
	drop A

	local i = 1
	foreach v of varlist B-LM {
		destring `v', replace ignore("x")
		rename `v' unemp_rate`i'
		local ++i
	}

	reshape long unemp_rate, i(name) j(t)
	gen year_month = ym(1998, 1) + t - 1
	format year_month %tm

	drop t
	order name year_month unemp_rate

	* merge the two labor panels
	merge 1:1 name year_month using `unemployed'
	drop _merge

	gen labor_force = round(unemployed/(unemp_rate/100))
	gen employed = labor_force - unemployed

	preserve
	collapse (sum) unemployed employed labor_force, by(year_month)
	gen agsstr  = "00000"
	encode agsstr, gen(ags)
	drop agsstr
	gen land = "00"
	gen name = "Deutschland"
	tempfile germany
	save `germany'
	restore

	append using `germany'
	replace unemp_rate = round((unemployed/labor_force)*1000)/10 if land == "00"

	order land ags name year_month
	
	xtset ags year_month
	xtdescribe

	save "${out_path}/county_labor_panel.dta", replace
}

*** county labor panel 1998:01-2025:12 *****************************************
if "${level}" == "state" & "${ind}" == "CPI" {
	* federal as benchmark
	import delimited "${src_path}/federal_VPI_1995_2025_m.csv", clear
	
	rename time year
	gen month_str = substr(_variable_attribute_code, 6, 2)
	destring month_str, gen(month)
	gen year_month = ym(year, month)
	format year_month %tm
	
	gen land_str = "00"
	gen name = "Deutschland"
	
	keep if value_unit == "2020=100"
	rename value CPI
	replace CPI = subinstr(CPI, ",", ".", .)
	replace CPI = "-" if CPI == "..."
	destring CPI, replace ignore("-")
	
	keep land_str name year_month CPI
	
	tempfile germany
	save `germany'

	
	* states
	import delimited "${src_path}/states_VPI_1995_2025_m.csv", clear
	
	rename time year
	gen month_str = substr(_variable_attribute_code, 6, 2)
	destring month_str, gen(month)
	gen year_month = ym(year, month)
	format year_month %tm
	
	rename v12 land_int
	gen str2 land_str = string(land_int,"%02.0f")
	rename v13 name
	label variable name ""
	
	rename value CPI
	replace CPI = subinstr(CPI, ",", ".", .)
	replace CPI = "-" if CPI == "..."
	destring CPI, replace ignore("-")

	
	keep land_str name year_month CPI
	
	append using `germany'
	encode land_str, gen(land)
	drop land_str
	order land name year_month CPI

	xtset land year_month
	xtdescribe

	save "${out_path}/state_CPI_panel.dta", replace
}
