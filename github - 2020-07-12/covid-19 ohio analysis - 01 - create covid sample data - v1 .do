clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;

log using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio analysis - 01 - create covid sample data - v1 .smcl", replace ;
* read in dataset & prep to create vars ;
	* read in dataset ;
		import delimited 
			"C:\Users\Troy\Box Sync\_ troy's files\research\_data\ohio\ohio disease reporting system\ohio disease report sys - covid-19 summary data - downloaded 2020-06-15 .csv" , 
			varnames(1) stringcols(_all) ;
	* drop total row ;
		drop if sex == "Total" ;
	* limit to deaths ;
		table deathcount ;
		keep if deathcount == "1" | deathcount == "2" | deathcount == "3" | deathcount == "4" ;
	* rename county var ;
		rename ïcounty county ;
	* destring deathcount var ;
		destring deathcount, replace ;
	* drop deaths after 2020-05-23 to match mortality data date range ;
	* (eliminating deaths by individal date b/c issues re missing & unknown values addressed below) ;
		table dateofdeath, row ;
		drop if 
			dateofdeath == "5/24/2020" | dateofdeath == "5/25/2020" | dateofdeath == "5/26/2020" | dateofdeath == "5/27/2020" | dateofdeath == "5/28/2020" | dateofdeath == "5/29/2020" | dateofdeath == "5/30/2020" | 
			dateofdeath == "5/31/2020" | dateofdeath == "6/1/2020"  | dateofdeath == "6/2/2020"  | dateofdeath == "6/3/2020"  | dateofdeath == "6/4/2020"  | dateofdeath == "6/5/2020"  | dateofdeath == "6/6/2020"  | 
			dateofdeath == "6/7/2020"  | dateofdeath == "6/8/2020"  | dateofdeath == "6/9/2020"  | dateofdeath == "6/10/2020" | dateofdeath == "6/11/2020" | dateofdeath == "6/12/2020" | dateofdeath == "6/13/2020" ; 
	* address problematic date of death values, convert variable to stata date format, & drop original var ;
		* list date of death values ;
			table dateofdeath deathcount if dateofdeath ~= "Unknown", row ;
			table dateofdeath deathcount if dateofdeath == "Unknown", row ;
		* if date of death unknown & date of admission is known, replace w/ date of admission PLUS 7 DAYS;
			gsort admissiondate ;
			list admissiondate deathcount if ( dateofdeath == "Unknown" | dateofdeath == "" ) & admissiondate ~= "" & admissiondate ~= "Unknown" ;
			replace dateofdeath = "5/6/2020" if 
				( dateofdeath == "Unknown" | dateofdeath == "" ) & admissiondate == "4/29/2020" ;
			* drop this observation since the revised date of death would be after 5/23/20 ;
				drop if 
					( dateofdeath == "Unknown" | dateofdeath == "" ) & admissiondate == "5/19/2020" ;
		* if date of death & date of admission unknown, replace w/ onset date PLUS 14 DAYS ;
			gsort onsetdate ;
			list onsetdate deathcount if dateofdeath == "Unknown" | dateofdeath == "" ;
			replace dateofdeath = "3/19/2020" if
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "3/5/2020" ;
			replace dateofdeath = "5/6/2020" if
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "4/22/2020" ;
			replace dateofdeath = "5/17/2020" if
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/3/2020" ;
			replace dateofdeath = "5/19/2020" if
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/5/2020" ;
			replace dateofdeath = "5/22/2020" if
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/8/2020" ;
			* drop these observations since the revised date of death would be after 5/23/20 ;
				drop if 
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/11/2020" ;
				drop if 
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/15/2020" ;
				drop if 
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/16/2020" ;
				drop if 
				( dateofdeath == "Unknown" | dateofdeath == "" ) & onsetdate == "5/21/2020" ;
		* list date of death values ;
			table   dateofdeath, row ;
		* convert to stata date format ;
			gen    date_death = date(dateofdeath,"MDY") ;
			format date_death %tdCCYY-NN-DD ;
			drop dateofdeath ;
			gsort date_death ;
			list date_death if _n <= 10 ;
			list date_death if _n >= ( _N - 10) ;
	* drop unneedded variables ;
		drop casecount hospitalizedcount onsetdate admissiondate ;
	* create mmwr week var & drop date of death var ;
		gen     week_mmwr = . ;
		replace week_mmwr = 10 if date_death >= date("2020-03-01", "YMD") & date_death <= date("2020-03-07", "YMD") ;
		replace week_mmwr = 11 if date_death >= date("2020-03-08", "YMD") & date_death <= date("2020-03-14", "YMD") ;
		replace week_mmwr = 12 if date_death >= date("2020-03-15", "YMD") & date_death <= date("2020-03-21", "YMD") ;
		replace week_mmwr = 13 if date_death >= date("2020-03-22", "YMD") & date_death <= date("2020-03-28", "YMD") ;
		replace week_mmwr = 14 if date_death >= date("2020-03-29", "YMD") & date_death <= date("2020-04-04", "YMD") ;
		replace week_mmwr = 15 if date_death >= date("2020-04-05", "YMD") & date_death <= date("2020-04-11", "YMD") ;
		replace week_mmwr = 16 if date_death >= date("2020-04-12", "YMD") & date_death <= date("2020-04-18", "YMD") ;
		replace week_mmwr = 17 if date_death >= date("2020-04-19", "YMD") & date_death <= date("2020-04-25", "YMD") ;
		replace week_mmwr = 18 if date_death >= date("2020-04-26", "YMD") & date_death <= date("2020-05-02", "YMD") ;
		replace week_mmwr = 19 if date_death >= date("2020-05-03", "YMD") & date_death <= date("2020-05-09", "YMD") ;
		replace week_mmwr = 20 if date_death >= date("2020-05-10", "YMD") & date_death <= date("2020-05-16", "YMD") ;
		replace week_mmwr = 21 if date_death >= date("2020-05-17", "YMD") & date_death <= date("2020-05-23", "YMD") ;
		replace week_mmwr = 22 if date_death >= date("2020-05-24", "YMD") & date_death <= date("2020-05-30", "YMD") ;
		replace week_mmwr = 23 if date_death >= date("2020-05-31", "YMD") & date_death <= date("2020-06-06", "YMD") ;
		replace week_mmwr = 24 if date_death >= date("2020-06-07", "YMD") & date_death <= date("2020-06-13", "YMD") ;
		drop date_death ;
	* collapse data by mmwr week ;
		describe ;
		table deathcount ;
		collapse (sum) deathcount , by(county sex agerange week_mmwr) ;
	* save data ;
		tempfile base ;
		save "`base'" ;
		clear ;
* create statewide counts ;
	use "`base'", replace ;
	* add observation for week 11 ;
		set obs `=_N + 1' ;
		replace week_mmwr = 11      if week_mmwr == . ;
		replace county = "Franklin" if week_mmwr == 11 ;
	* rename death count var then collapse & reshape dataset ;
		rename deathcount st_covid_actual ;
		collapse (sum) st_covid_actual , by(week_mmwr) ;
	* save data ;
		gsort week_mmwr ;
		tempfile state ;
		save "`state'" ;
		clear ;
* create counts by county ;
	use "`base'", replace ;
	* add observation for week 11 ;
		set obs `=_N + 1' ;
		replace week_mmwr = 11      if week_mmwr == . ;
		replace county = "Franklin" if week_mmwr == 11 ;
	* rename death count var then collapse & reshape dataset ;
		rename deathcount cty_covid_ ;
		collapse (sum) cty_covid_ , by(county week_mmwr) ;
		reshape wide 
			cty_covid_ , 
			i(week_mmwr) j(county) string ;
	* rename vars & replace missing values w/ zeroes ;
		foreach X of varlist cty_covid_*
			{ ;
			replace `X' = 0 if `X' == . ;
			rename `X' `X'_actual ;
			} ;
	* save data ;
		gsort week_mmwr ;
		tempfile county ;
		save "`county'" ;
		clear ;
* create counts by age group ;
	use "`base'", replace ;
	* add observation for week 11 ;
		set obs `=_N + 1' ;
		replace week_mmwr = 11      if week_mmwr == . ;
		replace agerange  = "00_19"   if week_mmwr == 11 ;
	* rename age groups ;
		replace agerange = "20_29" if agerange == "20-29" ;
		replace agerange = "30_39" if agerange == "30-39" ;
		replace agerange = "40_49" if agerange == "40-49" ;
		replace agerange = "50_59" if agerange == "50-59" ;
		replace agerange = "60_69" if agerange == "60-69" ;
		replace agerange = "70_79" if agerange == "70-79" ;
		replace agerange = "80_99" if agerange == "80+" ;
	* rename death count var then collapse & reshape dataset ;
		rename deathcount st_covid_ ;
		collapse (sum) st_covid_ , by(agerange week_mmwr) ;
		reshape wide 
			st_covid_ , 
			i(week_mmwr) j(agerange) string ;
	* rename vars & replace missing values w/ zeroes ;
		foreach X of varlist st_covid_*
			{ ;
			replace `X' = 0 if `X' == . ;
			rename `X' `X'_actual ;
			} ;
	* save data ;
		gsort week_mmwr ;
		tempfile age ;
		save "`age'" ;
		clear ;
* create counts by gender ;
	use "`base'", replace ;
	* add observation for week 11 ;
		set obs `=_N + 1' ;
		replace week_mmwr = 11     if week_mmwr == . ;
		replace sex       = "male" if week_mmwr == 11 ;
	* rename sex values ;
		replace sex = "female" if sex == "Female" ;
		replace sex = "male"   if sex == "Male" ;
	* rename death count var then collapse & reshape dataset ;
		rename deathcount st_covid_ ;
		collapse (sum) st_covid_ , by(sex week_mmwr) ;
		reshape wide 
			st_covid_ , 
			i(week_mmwr) j(sex) string ;
	* rename vars & replace missing values w/ zeroes ;
		foreach X of varlist st_covid_*
			{ ;
			replace `X' = 0 if `X' == . ;
			rename `X' `X'_actual ;
			} ;
	* save data ;
		gsort week_mmwr ;
		tempfile sex ;
		save "`sex'" ;
		clear ;
* merge datasets ;
	use "`state'" , replace ;
	merge 1:1 week_mmwr using "`county'" ;
	drop _merge ;
	merge 1:1 week_mmwr using "`age'" ;
	drop _merge ;
	merge 1:1 week_mmwr using "`sex'" ;
	drop _merge ;
* add calendar year var ;
	gen year_cal = "2020" ;
* save final dataset ;
	gsort year_cal week_mmwr ;
	save "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio analysis - covid sample data - v1 .dta", replace ;
log close ;
end ;
