clear

* MP shocks
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

tempfile mp_shocks
save `mp_shocks'

* Unemployed
import excel "${src_path}/Unemployed_Counties_1998_2024.xlsx", sheet("Auswertung") cellrange(A13:MN412) clear

gen name = substr(A, 7, .)
egen group = group(name)
tostring group, gen(groupstr)
encode groupstr, gen(county_id)
drop A-AB group groupstr

local i = 1
foreach v of varlist AC-MN {
    rename `v' unemployed`i'
    local ++i
}

reshape long unemployed, i(county_id name) j(t)
gen year_month = ym(1998, 1) + t - 1
format year_month %tm
drop t

order county_id name year_month unemployed
xtset county_id year_month
xtdescribe

tempfile unemployed
save `unemployed'


* Unemployment Rate
import excel "${src_path}/Unemployment_Rate_Counties_1998_2024.xlsx", sheet("Monatszahlen") cellrange(A13:LM412) clear

gen name = substr(A, 7, .)
gen land = substr(A, 1, 2)
egen group = group(name)
tostring group, gen(groupstr)
encode groupstr, gen(county_id)
drop A group groupstr

local i = 1
foreach v of varlist B-LM {
	destring `v', replace ignore("x")
    rename `v' unemp_rate`i'
    local ++i
}

reshape long unemp_rate, i(county_id name) j(t)
gen year_month = ym(1998, 1) + t - 1
format year_month %tm

drop t
order county_id name year_month unemp_rate
xtset county_id year_month
xtdescribe


* merge the two labor panels
merge 1:1 county_id year_month using `unemployed'
drop _merge

gen labor_force = round(unemployed/(unemp_rate/100))
gen employed = labor_force - unemployed

preserve
collapse (sum) unemployed employed labor_force, by(year_month)
gen county_id  = 0
gen land = "00"
gen name = "Deutschland"
tempfile germany
save `germany'
restore

append using `germany'
replace unemp_rate = round((unemployed/labor_force)*1000)/10 if county_id == 0

* merge shocks
merge m:1 year_month using `mp_shocks'
drop if _merge == 2
drop _merge

xtset county_id year_month

save "${out_path}/raw_panel.dta", replace
