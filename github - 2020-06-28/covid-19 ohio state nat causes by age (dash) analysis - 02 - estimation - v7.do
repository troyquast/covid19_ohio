clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;
log using "covid-19 ohio state nat causes by age (dash) analysis - 02 - estimation - v7 .smcl", replace ;

* open sample data ;
	use "covid-19 ohio state nat causes by age (dash) analysis - sample data - v6 .dta", clear ;
	tempfile sample_data ;
	save   "`sample_data'" ;
	clear ;
* estimate counterfactual mortality ;
	* using fourier terms ;
		foreach A in 00_19 20_29 30_39 40_49 50_59 60_69 70_79 80_99 
			{ ;
			foreach W of numlist 1/21
				{ ;
				* open sample data (have to estimate model for each week since lose results below) ;
					use "`sample_data'", clear ;
				* create scalar that is the pop in 2020 for that age group (to be used in prediction calculation below) ;
					sum pop_total if age_group_dash == "`A'" & year_cal == "2020" ;
					scalar pop_total_2020 = r(mean) ;
				* estimate model ;
					glm
						num_deaths  
							dum_year_epi_* 
							fourier_* 
							if 
								( dum_year_epi_2019 == 0 | (dum_year_epi_2019 == 1 & week_mmwr >= 27 ) /* | (dum_year_epi_2019 == 1 & week_mmwr <= 6 ) */ )
								& age_group_dash == "`A'" , 
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
									gen age_group_dash = "`A'" ;
									gen week_mmwr   = `W' ;
									order age_group_dash week_mmwr ;
							* save data ;
								tempfile `A'_`W'  ;
								save "``A'_`W''" ;
								clear ;
						} ;
				} ;
		* append age_group-week files ;
			* start w/ 00_00 age group ;
				use "`00_19_1'" ;
				foreach W of numlist 2/21
					{ ;
					append using "`00_19_`W''" ;
					} ;
			* append observations for other age groups ;
				foreach A in 20_29 30_39 40_49 50_59 60_69 70_79 80_99
				{ ;
					foreach W of numlist 1/21
					{ ;
					append using "``A'_`W''" ;
					} ;
				} ;
		* add year vars ;
			gen year_cal = "2020" ;
			gen year_epi = "2019" ;
		* sort data ;
			gsort year_cal week_mmwr age_group_dash ;
* merge w/ full dataset ;
	merge 1:1 year_cal week_mmwr age_group_dash using "covid-19 ohio state nat causes by age (dash) analysis - sample data - v6 .dta" ;
* prep & save data ;
	* limit to necessary vars ;
		keep age_group_dash year_cal year_epi week_mmwr num_deaths pctile_005 pctile_025 pctile_050 pctile_500 pctile_950 pctile_975 pctile_995 ;
	* limit to calendar year 2020 data ;
		keep if year_cal == "2020" ;
	* reshape to wide format ;
		reshape wide 
			num_deaths pctile_005 pctile_025 pctile_050 pctile_500 pctile_950 pctile_975 pctile_995 , 
			i(year_cal week_mmwr year_epi) j(age_group) string ;
	* rename vars ;
		foreach A in 00_19 20_29 30_39 40_49 50_59 60_69 70_79 80_99
			{ ;
			rename num_deaths`A' st_natc_`A'_actual ;
			foreach P in 005 025 050 500 950 975 995 
				{ ;
				rename pctile_`P'`A' st_natc_`A'_p`P' ;
				} ;
			} ;
	* order & sort data ;
		gsort year_cal week_mmwr ;
		order year_cal week_mmwr year_epi st_natc_* ;
	* save data ;
		save "covid-19 ohio state nat causes by age (dash) analysis - actual & counter counts - v7 .dta", replace ;
log close ;
end ;