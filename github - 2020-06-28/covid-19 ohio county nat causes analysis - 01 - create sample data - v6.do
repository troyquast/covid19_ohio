clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;

log using "covid-19 ohio county nat causes analysis - 01 - create sample data - v6 .smcl", replace ;
* read in, revise, & save datasets ;
	* deaths data ;
		* read in data ;
			import excel 
				"ohio deaths by county, year, & mmwr week (2010-2020) - v3 .xlsx" , 
				sheet("dths- cty nat") firstrow allstring ;
		* drop total row ;
			drop if DeathCountyCountyName == "Total" ;
			drop if MMWRWeekMMWRWeek      == "Total" ;
			drop if DeathYearYear         == "Total" ;
		* drop data later than week 21 of 2020 ;
			foreach W of numlist 22/53
				{ ;
				drop if DeathYearYear == "2020 **" & MMWRWeekMMWRWeek == "`W'" ;
				} ;
		* drop unneeded vars ;
			drop SORT ;
		* rename vars ;
			rename 
				(DeathCountyCountyName DeathYearYear MMWRWeekMMWRWeek Deaths     )
				(county                year_cal          week_mmwr    num_deaths ) ;
		* revise 2019 & 2020 year var values ;
			replace year_cal = "2019" if year_cal == "2019 **" ;
			replace year_cal = "2020" if year_cal == "2020 **" ;
		* destring number of deaths var & mmwr week var (to allow sorting);
			destring num_deaths, replace ;
		* inspect var values ;
			* # deaths ;
				* total ;
					tabstat num_deaths, stat(sum) format(%9.0fc) ;
				* by week ;
					gsort week_mmwr ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(week_mmwr) ;
					* drop observations w/ unknown mmwr week & where mmwr week is 99 ;
						drop if week_mmwr == "99" | week_mmwr == "Unknown" ;
					* destring week var for later use ;
						destring week_mmwr,  replace ;
						tabstat num_deaths, stat(sum) format(%9.0fc) by(week_mmwr) ;
				* by calendar year ;
					gsort year_cal ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(year_cal) ;
				* by county ;
					gsort county ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(county) ;
					* drop observations w/ unknown county & where county is "NonOH" ;
						drop if county == "NonOH" | county == "Unknown" ;
					tabstat num_deaths, stat(sum) format(%9.0fc) by(county) ;
		* save data ;
			gsort county year_cal ;
			tempfile deaths ;
			save "`deaths'" ;
			clear ;
	* pop data ;
		* read in data ;
			import excel 
				"ohio deaths by county, year, & mmwr week (2010-2020) - v3 .xlsx" , 
				sheet("pop- cty") firstrow allstring ;
		* drop total row ;
			drop if CountyPopCountyName == "Total" ;
		* drop unneeded vars ;
			drop SORT ;
		* rename vars ;
			rename 
				(CountyPopCountyName PopulationYearYear Count     )
				(county              year_cal               pop_total ) ;
		* inspect var values ;
			foreach X in county year_cal 
				{ ;
				table `X', missing ;
				} ;
				sum pop_total if county == "NonOH" ;
				sum pop_total if county == "Unknown" ;
		* drop observations where county is Unknown or NonOH ;
			drop if county == "NonOH" | county == "Unknown" ;
		* destring pop var ;
			destring pop_total, replace ;
		* approximate 2019 & 2020 pop by using 2013-2018 compound annual growth rate ;
			replace pop_total = . if year_cal == "2019" | year_cal == "2020" ;
			gsort county year_cal ;
			* create vars that equal the 2015 & 2018 values ;
				foreach Y in 2013 2018
					{ ;
					gen pop_total_`Y'_temp = pop_total if year_cal == "`Y'" ;
					by county: egen pop_total_`Y' = mean(pop_total_`Y'_temp) ;
					} ;
			* calc compound annual growth rate 2015-2018 ;
				gen pop_cagr_2013_2018 = ( pop_total_2018 / pop_total_2013 ) ^ (1/5) - 1 ;
			* replace 2019 & 2020 values ;
				replace pop_total = ( 1 + pop_cagr_2013_2018 )   * pop_total_2018 if year == "2019" ;
				replace pop_total = ( 1 + pop_cagr_2013_2018 )^2 * pop_total_2018 if year == "2020" ;
			* drop unneeded vars ;
				drop pop_cagr_2013_2018 pop_total_* ;
		* save data ;
			gsort county year_cal ;
			tempfile pop ;
			save "`pop'" ;
			clear ;
* merge datasets ;
	* open deaths dataset ;
		use   "`deaths'", clear ;
	* merge pop dataset ;
		merge m:1 county year_cal using "`pop'" ;
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
	* revise Van Wert county name to facilitate bootstrapping ;
		replace county = "Van_Wert" if county == "Van Wert" ;
* save complete dataset ;
	gsort county year_cal week_mmwr ;
	save "covid-19 ohio county nat causes analysis - sample data - v6 .dta", replace ;
log close ;
end ;
