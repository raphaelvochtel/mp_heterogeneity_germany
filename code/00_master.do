clear all

set graph off
set seed 123456789


*** paths ***
local user = c(username)

if "`user'" == "raphaelvochtel"{
	global orig /Users/raphaelvochtel/Documents/mp_heterogeneity_germany // CHANGE HERE
	
	global dofiles $orig/code
	global src_path $orig/input_data
	global out_path $orig/outputs
}

cd ${orig}

*** packages ***
// ssc install reghdfe
// ssc install ftools
// ssc install shp2dta
// ssc install spmap

*** which analysis to conduct ***
global ind unemp_rate 	// options: 	unemp_rate 	unemployed		(later: prices)
global sign contr 		// options: 	all			expan 			contr

*** do-files ***
// include ${dofiles}/01_clean_data.do
// include ${dofiles}/02_regression.do
include ${dofiles}/03_analysis.do
