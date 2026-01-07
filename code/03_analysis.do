clear

****

global ind unemployed 	// unemp_rate unemployed
global sign expan 		// all expan contr

****

// shp2dta using "${src_path}/VG250_KRS.shp", ///
//     database(krs_db) ///
//     coordinates(krs_coord) ///
//     genid(_ID) ///
//     replace
// rename AGS ags
// tempfile krs_db
// save `krs_db'
// und iwie auch krs_coord


use "${out_path}/${ind}/${sign}/collected_results.dta", replace

merge 1:1 name using "${out_path}/ags_dict.dta"
drop _merge

merge 1:1 ags using `krs_db'

foreach i in 6 12 18 24 30 36 {
	keep ags exakt_pc_`i'
	rename exakt_pc_`i' value
	spmap value using krs_coord.dta, ///
		id(_ID) ///
		fcolor(RdBu) ///
		clmethod(custom) ///
		clbreaks(-10 -5 -2 -1 0 1 2 5 10) ///
		legend(size(small))
}
