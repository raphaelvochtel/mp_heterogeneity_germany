clear all

set graph off

local user = c(username)

if "`user'" == "raphaelvochtel"{
	global orig /Users/raphaelvochtel/Documents/mp_heterogeneity_germany
	
	global dofiles $orig/code
	global src_path $orig/input_data
	global out_path $orig/outputs
}

cd ${orig}

// packages
// ssc install reghdfe
// ssc install ftools

set seed 123456789

// *** do-files ***

