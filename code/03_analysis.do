clear

shp2dta using "${src_path}/shapefiles/VG250_KRS.shp", ///
    database("${src_path}/shapefiles/krs_db") ///
    coordinates("${src_path}/shapefiles/krs_coord") ///
    genid(_ID) ///
    replace
	
use "${src_path}/shapefiles/krs_db.dta", clear
rename AGS ags
duplicates drop ags, force
tempfile krs_db_clean
save `krs_db_clean'


use "${out_path}/${ind}/${sign}/collected_results.dta", replace

merge 1:1 name using "${out_path}/ags_dict.dta"
drop _merge

merge 1:1 ags using `krs_db_clean'
keep if _merge == 3
drop _merge

foreach i in 6 12 18 24 30 36 {

    gen value = exakt_pc_`i'
	
    spmap value using "${src_path}/shapefiles/krs_coord", ///
        id(_ID) ///
        fcolor(BuRd) ///
        clmethod(custom) ///
        clbreaks(-30 -20 -10 -5 0 5 10 20 30) ///
        legend(size(small)) ///
        title("rel. transm. to agg. (horizon: `i' months)")
	
	graph export "${out_path}/${ind}/${sign}/h`i'.png", replace width(600)
		
    drop value
}

erase "${src_path}/shapefiles/krs_db.dta"
erase "${src_path}/shapefiles/krs_coord.dta"
