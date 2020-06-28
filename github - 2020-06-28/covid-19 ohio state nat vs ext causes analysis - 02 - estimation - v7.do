clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;
log using "covid-19 ohio state nat vs ext causes analysis - 02 - estimation - v7 .smcl", replace ;

* open sample data ;
	use "covid-19 ohio state nat vs ext causes analysis - sample data - v6 .dta", clear ;
	tempfile sample_data ;
	save   "`sample_data'" ;
	clear ;
* estimate counterfactual mortality ;
	* using fourier terms ;
		foreach C in natural external
			{ ;
			foreach W of numlist 1/21
				{ ;
				* open sample data (have to estimate model for each week since lose results below) ;
					use "`sample_data'", clear ;
				* create scalar that is the pop in 2020 (to be used in prediction calculation below) ;
					sum pop_total if year_cal == "2020" ;
					scalar pop_total_2020 = r(mean) ;
				* estimate model ;
					glm
						num_deaths  
							dum_year_epi_* 
							fourier_* 
							if 
								( dum_year_epi_2019 == 0 | (dum_year_epi_2019 == 1 & week_mmwr >= 27 ) /* | (dum_year_epi_2019 == 1 & week_mmwr <= 6 ) */ )
								& cause_nat_ext == "`C'" , 
							family(poisson) link(log) exposure(pop_total) /* vce(robust) */ ;
				* get parametric bootstrap estimates ;
					* obtain coef & cov matrices ;
						matrix b = e(b) ;
						matrix V = e(V) ;
					* set seed ;
						set seed 29374065 ;
					* draw samples based on multivariate normal distribution specified in regression estimates ;
						drawnorm v1-v15, n(100) cov(V) means(b) ;
				* estimate counterfactual for each week of interest ;
						* calculate pred count ;
							* calc predicted count for each of the bootstrap draws ;
								gen fourier_theta = 2 * c(pi) * `W' / 52.1775 ;
								gen pred_count_strap = exp( v10 + v11 * sin(fourier_theta) + v12 * cos(fourier_theta) + v13 * sin(2*fourier_theta) + v14 * cos(2*fourier_theta) + v15 + ln(pop_total_2020) ) ;
							* obtain poisson draws from each bootstrap draw using the predicted count from that draw as the mean ;
								foreach Y of numlist 1(1)100
									{ ;
									* set seed ;
										set seed 29374065 ;
									gen pred_count_draw_`Y' = rpoisson(pred_count_strap) ;
									} ;
								* keep predicted counts from poisson draws ;
									keep pred_count_draw_* ;
								* save complete dataset ;
									tempfile complete ;
									save "`complete'" ;
									clear ;
								* save each var as own temp datasets ;
									foreach X of numlist 1/100
										{ ;
										use "`complete'" ;
										keep pred_count_draw_`X' ;
										rename pred_count_draw_`X' pred_count_all ;
										tempfile var`X' ;
										save "`var`X''" ;
										clear ;
										} ;
								* create appended dataset ;
									use    "`var1'" ;
									foreach X of numlist 2/100
										{ ;
										append using "`var`X''" ;
										} ;
								* get percentiles ;
									sum pred_count_all ;
									_pctile pred_count_all, p(.05, 2.5, 5, 50, 95, 97.5, 99.5 ) ;
									gen pctile_005 = r(r1) ;
									gen pctile_025 = r(r2) ;
									gen pctile_050 = r(r3) ;
									gen pctile_500 = r(r4) ;
									gen pctile_950 = r(r5) ;
									gen pctile_975 = r(r6) ;
									gen pctile_995 = r(r7) ;
								* prep single observation ;
									keep if _n == 1 ;
									drop pred_count_all ;
									gen cause_nat_ext = "`C'" ;
									gen week_mmwr   = `W' ;
									order cause_nat_ext week_mmwr ;
							* save data ;
								tempfile `C'_`W'  ;
								save "``C'_`W''" ;
								clear ;
						} ;
				} ;
		* append nat vs ext causes - week files ;
			* start w/ natural ;
				use "`natural_1'" ;
				foreach W of numlist 2/21
					{ ;
					append using "`natural_`W''" ;
					} ;
			* append white observations ;
				foreach W of numlist 1/21
					{ ;
					append using "`external_`W''" ;
					} ;
		* add year vars ;
			gen year_cal     = "2020" ;
			gen year_epi = "2019" ;
		* sort data ;
			gsort year_cal week_mmwr cause_nat_ext ;
* merge w/ full dataset ;
	merge 1:1 year_cal week_mmwr cause_nat_ext using "covid-19 ohio state nat vs ext causes analysis - sample data - v6 .dta" ;
* prep & save data ;
	* limit to necessary vars ;
		keep cause_nat_ext year_cal year_epi week_mmwr num_deaths pctile_005 pctile_025 pctile_050 pctile_500 pctile_950 pctile_975 pctile_995 ;
	* limit to calendar year 2020 data ;
		keep if year_cal == "2020" ;
	* reshape to wide format ;
		reshape wide 
			num_deaths pctile_005 pctile_025 pctile_050 pctile_500 pctile_950 pctile_975 pctile_995 , 
			i(year_cal week_mmwr year_epi) j(cause_nat_ext) string ;
	* rename vars ;
		rename num_deathsnatural  st_natc_actual ;
		rename num_deathsexternal st_extc_actual ;
		foreach P in 005 025 050 500 950 975 995 
			{ ;
			rename pctile_`P'natural  st_natc_p`P' ;
			rename pctile_`P'external st_extc_p`P' ;
			} ;
	* order & sort data ;
		gsort year_cal week_mmwr ;
		order year_cal week_mmwr year_epi st_natc_actual st_natc_p* st_extc_actual st_extc_p* ;
	* save data ;
		save "covid-19 ohio state nat vs ext causes analysis - actual & counter counts - v7 .dta", replace ;
log close ;
end ;