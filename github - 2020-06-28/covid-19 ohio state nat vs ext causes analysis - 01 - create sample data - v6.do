clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;

log using "covid-19 ohio state nat vs ext causes analysis - 01 - create sample data - v6 .smcl", replace ;
* read in, revise, & save datasets ;
	* deaths data ;
		* read in data ;
			import excel 
				"ohio deaths by county, year, & mmwr week (2010-2020) - v3 .xlsx" , 
				sheet("dths- st 39causes") firstrow allstring ;
		* drop total row ;
			drop if DeathYearYear           == "Total" ;
			drop if DeathCOD39ICDCode39Desc == "Total" ;
		* drop data later than week 21 of 2020 ;
			foreach W of numlist 22/53
				{ ;
				drop if DeathYearYear == "2020 **" & MMWRWeekMMWRWeek == "`W'" ;
				} ;
		* drop unneeded vars ;
			drop SORT ;
		* rename vars ;
			rename 
				(DeathCOD39ICDCode39Desc DeathYearYear MMWRWeekMMWRWeek Deaths     )
				(cause_39                year_cal      week_mmwr        num_deaths ) ;
		* revise 2019 & 2020 year var values ;
			replace year_cal = "2019" if year_cal == "2019 **" ;
			replace year_cal = "2020" if year_cal == "2020 **" ;
		* destring number of deaths var & mmwr week var (to allow sorting);
			destring num_deaths, replace ;
			format num_deaths %9.0fc ;
		* inspect var values ;
			* # deaths ;
				* total ;
					tabstat num_deaths, stat(sum) format(%9.0fc) ;
				* by week ;
					gsort week_mmwr ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(week_mmwr) ;
					* drop observations w/ unknown mmwr week & where mmwr week is 99 ;
						drop if week_mmwr == "99" ;
						drop if week_mmwr == "Unknown" ;
					* destring week var for later use ;
						destring week_mmwr,  replace ;
						tabstat num_deaths, stat(sum) format(%9.0fc) by(week_mmwr) ;
				* by calendar year ;
					gsort year_cal ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(year_cal) ;
				* by cause of death ;
					gsort cause_39 ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(cause_39) ;
		* create natural vs ext cause counts ;
			* first categorize causes of death ;
				gen cause_nat_ext = "natural" ;
				replace cause_nat_ext = "external" if 
					cause_39 == "Motor vehicle accidents (V02-V04V09.0V09.2V12-V14V19.0-V19.2V19.4-V19.6V20-V79V80.3-V80.5V81.0-V81.1V82.0-V82.1V83-V86V87.0-V87.8V88.0-V88.8V89.0V89.2)" | 
					cause_39 == "All other and unspecified accidents and adverse effects (V01V05-V06V09.1V09.3-V09.9V10-V11V15-V18V19.3V19.8-V19.9V80.0-V80.2V80.6-V80.9V81.2-V81.9V82.2-V82.9V87.9V88.9V89.1V89.3V89.9V90-X59Y40-Y86Y88)" | 
					cause_39 == "Intentional self-harm (suicide) (*U03X60-X84Y87.0)" | 
					cause_39 == "Assault (homicide) (*U01-*U02X85-Y09Y87.1)" | 
					cause_39 == "All other external causes (Y10-Y36Y87.2Y89)" ; 
			* next collapse counts ;
				drop cause_39 ;
				collapse (sum) num_deaths, by(year_cal week_mmwr cause_nat_ext) ;
		* save data ;
			gsort year_cal week_mmwr cause_nat_ext ;
			tempfile deaths ;
			save "`deaths'" ;
			clear ;
	* pop data ;
		* read in data ;
			import excel 
				"ohio deaths by county, year, & mmwr week (2010-2020) - v3 .xlsx" , 
				sheet("pop- st") firstrow allstring ;
		* drop total row ;
			drop if PopulationYearYear == "Total" ;
		* drop unneeded vars ;
			drop SORT ;
		* rename vars ;
			rename 
				(PopulationYearYear Count     )
				(year_cal           pop_total ) ;
		* destring pop var ;
			destring pop_total, replace ;
			format pop_total %9.0fc ;
		* approximate 2019 & 2020 pop by using 2013-2018 compound annual growth rate ;
			replace pop_total = . if year_cal == "2019" | year_cal == "2020" ;
			gsort year_cal ;
			* create vars that equal the 2015 & 2018 values ;
				foreach Y in 2013 2018
					{ ;
					gen pop_total_`Y'_temp = pop_total if year_cal == "`Y'" ;
					egen pop_total_`Y' = mean(pop_total_`Y'_temp) ;
					} ;
			* calc compound annual growth rate 2015-2018 ;
				gen pop_cagr_2013_2018 = ( pop_total_2018 / pop_total_2013 ) ^ (1/5) - 1 ;
			* replace 2019 & 2020 values ;
				replace pop_total = ( 1 + pop_cagr_2013_2018 )   * pop_total_2018 if year == "2019" ;
				replace pop_total = ( 1 + pop_cagr_2013_2018 )^2 * pop_total_2018 if year == "2020" ;
			* drop unneeded vars ;
				drop pop_cagr_2013_2018 pop_total_* ;
		* inspect var values ;
			* pop ;
				* total ;
					tabstat pop_total, stat(sum) format(%12.0fc) ;
				* by calendar year ;
					gsort year_cal ;
					tabstat pop_total, stat(sum) format(%12.0fc) by(year_cal) ;
		* save data ;
			gsort year_cal ;
			tempfile pop ;
			save "`pop'" ;
			clear ;
*** ADD COVID CASE DATA ;
* merge datasets ;
	* open deaths dataset ;
		use   "`deaths'", clear ;
	* merge pop dataset ;
		merge m:1 year_cal using "`pop'" ;
		drop _merge ;
* revise & create vars ;
	* epi year var & corresponding dummy vars (will use 2010 as reference year) ;
		* dummy vars ;
			gen     dum_year_epi_2009 = 0 ;
			replace dum_year_epi_2009 = 1 if year_cal == "2010" & week_mmwr <= 26 ;
			gen     dum_year_epi_2011 = 0 ;
			replace dum_year_epi_2011 = 1 if year_cal == "2011" & week_mmwr >= 27 ;
			replace dum_year_epi_2011 = 1 if year_cal == "2012" & week_mmwr <= 26 ;
			gen     dum_year_epi_2012 = 0 ;
			replace dum_year_epi_2012 = 1 if year_cal == "2012" & week_mmwr >= 27 ;
			replace dum_year_epi_2012 = 1 if year_cal == "2013" & week_mmwr <= 26 ;
			gen     dum_year_epi_2013 = 0 ;
			replace dum_year_epi_2013 = 1 if year_cal == "2013" & week_mmwr >= 27 ;
			replace dum_year_epi_2013 = 1 if year_cal == "2014" & week_mmwr <= 26 ;
			gen     dum_year_epi_2014 = 0 ;
			replace dum_year_epi_2014 = 1 if year_cal == "2014" & week_mmwr >= 27 ;
			replace dum_year_epi_2014 = 1 if year_cal == "2015" & week_mmwr <= 26 ;
			gen     dum_year_epi_2015 = 0 ;
			replace dum_year_epi_2015 = 1 if year_cal == "2015" & week_mmwr >= 27 ;
			replace dum_year_epi_2015 = 1 if year_cal == "2016" & week_mmwr <= 26 ;
			gen     dum_year_epi_2016 = 0 ;
			replace dum_year_epi_2016 = 1 if year_cal == "2016" & week_mmwr >= 27 ;
			replace dum_year_epi_2016 = 1 if year_cal == "2017" & week_mmwr <= 26 ;
			gen     dum_year_epi_2017 = 0 ;
			replace dum_year_epi_2017 = 1 if year_cal == "2017" & week_mmwr >= 27 ;
			replace dum_year_epi_2017 = 1 if year_cal == "2018" & week_mmwr <= 26 ;
			gen     dum_year_epi_2018 = 0 ;
			replace dum_year_epi_2018 = 1 if year_cal == "2018" & week_mmwr >= 27 ;
			replace dum_year_epi_2018 = 1 if year_cal == "2019" & week_mmwr <= 26 ;
			gen     dum_year_epi_2019 = 0 ;
			replace dum_year_epi_2019 = 1 if year_cal == "2019" & week_mmwr >= 27 ;
			replace dum_year_epi_2019 = 1 if year_cal == "2020" & week_mmwr <= 26 ;
		* var ;
			gen year_epi = "" ;
			replace year_epi = "2009" if dum_year_epi_2009 == 1 ; 
			replace year_epi = "2010" if year_cal == "2010" & week_mmwr >= 27 ;
			replace year_epi = "2010" if year_cal == "2011" & week_mmwr <= 26 ;
			foreach Y of numlist 11/19
				{ ;
				replace year_epi = "20`Y'" if dum_year_epi_20`Y' == 1 ; 
				} ;
	* mmwr week dummy vars (week 1 is reference week) ;
		foreach W of numlist 2(1)53 
			{ ;
			gen     dum_week_mmwr_`W' = 0 ;
			replace dum_week_mmwr_`W' = 1 if week_mmwr == `W' ;
			} ;
	* fourier terms ;
		gen fourier_theta = 2 * c(pi) * week_mmwr / 52.1775 ;
		gen fourier_sin_theta  = sin(fourier_theta) ;
		gen fourier_cos_theta  = cos(fourier_theta) ;		
		gen fourier_sin_2theta = sin(2 * fourier_theta) ;
		gen fourier_cos_2theta = cos(2 * fourier_theta) ;		
		drop fourier_theta ;
* save complete dataset ;
	gsort year_cal week_mmwr cause_nat_ext;
	save "covid-19 ohio state nat vs ext causes analysis - sample data - v6 .dta", replace ;
log close ;
end ;
