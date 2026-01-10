clear all


*** set your own base-path ***
local user = c(username)

if "`user'" == "raphaelvochtel"{
	global orig /Users/raphaelvochtel/Documents/mp_heterogeneity_germany // CHANGE HERE
}


*** which analysis to conduct ***
global level county			// options: 	county		state
global ind unemp_rate		// options:		- county: 	unemployed		unemp_rate
							//				- state: 	CPI
global sign all 			// options: 	all			expan 			contr


////////////////////////////////////////////////////////////////////////////////

set graph off
set seed 123456789


*** paths ***
global dofiles $orig/code
global src_path $orig/input_data
global out_path $orig/outputs
global sub_out_path ${out_path}/results_${level}_level

cd ${orig}

*** packages ***
// ssc install reghdfe
// ssc install ftools
// ssc install shp2dta
// ssc install spmap

*** do-files ***
include ${dofiles}/01_clean_data.do
include ${dofiles}/02_regression.do
// include ${dofiles}/03_analysis.do
