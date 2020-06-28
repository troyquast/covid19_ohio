clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;

log using "covid-19 ohio analysis - 01 - create cause-specific deaths data ages 20-49 - v1 .smcl", replace ;
* read in, revise, & save datasets ;
	* deaths data ;
		* read in data ;
			import excel 
				"ohio deaths by county, year, & mmwr week (2010-2020) - v3 .xlsx" , 
				sheet("dths - st nat by cause 20-49 yr") firstrow allstring ;
		* drop unneeded vars ;
			drop SORT ;
		* rename vars ;
			rename 
				(DeathAgeGroupNCIAgeNCI DeathCOD39ICDCode39Desc DeathYearYear MMWRWeekMMWRWeek Deaths     )
				(age_group_nci          icd_code_39_full        year_cal      week_mmwr    num_deaths ) ;
		* revise 2019 & 2020 year var values ;
			replace year_cal = "2019" if year_cal == "2019 **" ;
			replace year_cal = "2020" if year_cal == "2020 **" ;
		* destring number of deaths var & mmwr week var (to allow sorting);
			table num_deaths ;
			destring num_deaths, replace ;
			table week_mmwr ;
			destring week_mmwr, replace ;
		* limit to data weeks covering 2020-03-17 (date of first death in covid dashboard) to 2020-05-23 ;
			drop if week_mmwr < 12 | week_mmwr > 21 ;
		* inspect var values ;
			* # deaths ;
				* total ;
					tabstat num_deaths, stat(sum) format(%9.0fc) ;
				* by week ;
					gsort week_mmwr ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(week_mmwr) ;
					* drop observations w/ unknown mmwr week & where mmwr 
						tabstat num_deaths, stat(sum) format(%9.0fc) by(week_mmwr) ;
				* by calendar year ;
					gsort year_cal ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(year_cal) ;
		* create age group var ;
			gen     age_group_dash = "" ;
			replace age_group_dash = "20_29" if age_group_nci == "20 to 24" ;
			replace age_group_dash = "20_29" if age_group_nci == "25 to 29" ;
			replace age_group_dash = "30_39" if age_group_nci == "30 to 34" ;
			replace age_group_dash = "30_39" if age_group_nci == "35 to 39" ;
			replace age_group_dash = "40_49" if age_group_nci == "40 to 44" ;
			replace age_group_dash = "40_49" if age_group_nci == "45 to 49" ;
		* create var for cause of death groups ;
			gen icd_code_group = "" ;
			replace icd_code_group = "Diseases of heart" if 
				icd_code_39_full == "Other diseases of heart (I00-I09I26-I51)" | 
				icd_code_39_full == "Hypertensive heart disease with or without renal disease (I11I13)" |
				icd_code_39_full == "Ischemic heart diseases (I20-I25)" ;
			replace icd_code_group = "Malignant neoplasms" if 
				icd_code_39_full == "Malignant neoplasm of stomach (C16)" |
				icd_code_39_full == "Malignant neoplasms of colon rectum and anus (C18-C21)" |
				icd_code_39_full == "Malignant neoplasm of pancreas (C25)" |
				icd_code_39_full == "Malignant neoplasms of trachea bronchus and lung (C33-C34)" |
				icd_code_39_full == "Malignant neoplasm of breast (C50)" |
				icd_code_39_full == "Malignant neoplasms of cervix uteri corpus uteri and ovary (C53-C56)" |
				icd_code_39_full == "Malignant neoplasm of prostate (C61)" |
				icd_code_39_full == "Malignant neoplasms of urinary tract (C64-C68)" |
				icd_code_39_full == "Non-Hodgkinâ€™s lymphoma (C82-C85)" |
				icd_code_39_full == "Leukemia (C91-C95)" |
				icd_code_39_full == "Other malignant neoplasms (C00-C15C17C22-C24C26-C32C37-C49C51-C52C57-C60C62-C63C69-C81C88C90C96-C97)" ;
			replace icd_code_group = "Chronic lower respiratory diseases" if 
				icd_code_39_full == "Chronic lower respiratory diseases (J40-J47)" ;
			replace icd_code_group = "Cerobrovascular diseases" if 
				icd_code_39_full == "Cerebrovascular diseases (I60-I69)" ;
			replace icd_code_group = "Diabetes mellitus" if 
				icd_code_39_full == "Diabetes mellitus (E10-E14)" ;
			replace icd_code_group = "Influenza and pneumonia" if 
				icd_code_39_full == "Influenza and pneumonia (J10-J18)" ;
			replace icd_code_group = "Nephritis nephrotic syndrome and nephrosis" if 
				icd_code_39_full == "Nephritis nephrotic syndrome and nephrosis (N00-N07N17-N19N25-N27)" ;
			replace icd_code_group = "Symptoms, signs, and abnormal findings, not elsewhere classified" if 
				icd_code_39_full == "Symptoms signs and abnormal clinical and laboratory findings not elsewhere classified (excluding Sudden infant death syndrome) (R00-R94R96-R99)" ;
			replace icd_code_group = "All other diseases (Residual)" if 
				icd_code_39_full == "All other diseases (Residual) (A00-A09A20-A49A54-B19B25-B99D00-E07E15-G25G31-H93I80-J06J20-J39J60-K22K29-K66K71-K72K75-M99N10-N15N20-N23N28-N98U049U071)" ;
			replace icd_code_group = "Chronic liver disease and cirrhosis" if 
				icd_code_39_full == "Chronic liver disease and cirrhosis (K70K73-K74)" ;
			replace icd_code_group = "Other" if 
				icd_code_group == "" ;
		* create var for pre-2020 & 2020 ;
			gen     year_group = "" ;
			replace year_group = "2010_2019" if year_cal ~= "2020" ;
			replace year_group = "2020"      if year_cal == "2020" ;
		* collapse data ;
			rename num_deaths num_deaths_ ;
			collapse (sum) num_deaths_, by(year_group icd_code_group) ;
		* replace sum w/ mean for pre-2020 data ;
			replace num_deaths_ = round(num_deaths / 10) if year_group == "2010_2019" ;
		* reshape data ;
			reshape wide num_deaths_, i(icd_code_group) j(year_group) string ;
		* create sort var based on # 2020 deaths w/ other at end ;
			gsort -num_deaths_2020 ;
			gen     sort_num_deaths_2020 = _n ;
			replace sort_num_deaths_2020 = 99 if icd_code_group == "Other" ;
	* graphing set-up ;
		pause off ;
		graph set window fontface "Times New Roman" ;
		cd "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs" ; 
		set scheme s1color ;
		* graph data ;
			graph hbar 
				(asis) num_deaths_2010_2019 
				(asis) num_deaths_2020 
				if icd_code_group ~= "Total" ,
				over(icd_code_group, sort(sort_num_deaths_2020) label(labsize(small)) ) 
				bar(1, color(red))
				bar(2, color(blue))
				ylabel(#5, labsize(small)) 
				xsize(3)
				ysize(1.5)
				legend(
					label(1 "2010-2019 average")
					label(2 "2020")
					order(1 2) 
					cols(1)
					rows(2)
					height(6)
					position(3)
					ring(0)
 					size(small) 
					rowgap(tiny)
					colgap(tiny)
					keygap(tiny)
					symxsize(tiny) 
					symysize(tiny) 
					/* forcesize */
					/* rowgap(tiny) */
					);
				graph save   "graph - st natc - by cause - 20-49 yrs old "    , replace ;
				graph export "graph - st natc - by cause - 20-49 yrs old .eps" , replace preview(on) fontface("Times New Roman") ;
				graph export "graph - st natc - by cause - 20-49 yrs old .emf" , replace ;
log close ;
end ;
