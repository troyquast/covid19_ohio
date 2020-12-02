clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;
log using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio state all causes by gender analysis - 02 - estimation - v13 .smcl", replace ;

* open sample data ;
	use "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio state all causes by gender analysis - sample data - v13 .dta", clear ;
	tempfile sample_data ;
	save   "`sample_data'" ;
	clear ;
* estimate counterfactual mortality ;
	* using fourier terms ;
		foreach G in female male
			{ ;
			foreach W of numlist 1/40
				{ ;
				* open sample data (have to estimate model for each week since lose results below) ;
					use "`sample_data'", clear ;
				* create scalar that is the pop in 2020 for that gender (to be used in prediction calculation below) ;
					sum pop_total if gender == "`G'" & year_cal == "2020" ;
					scalar pop_total_2020 = r(mean) ;
				* estimate model ;
					glm
						num_deaths  
							dum_year_epi_* 
							fourier_* 
							if 
								year_cal ~= "2020" 
								& gender == "`G'" , 
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
									gen gender = "`G'" ;
									gen week_mmwr   = `W' ;
									order gender week_mmwr ;
							* save data ;
								tempfile `G'_`W'  ;
								save "``G'_`W''" ;
								clear ;
						} ;
				} ;
		* append gender-week files ;
			* start w/ females ;
				use "`female_1'" ;
				foreach W of numlist 2/40
					{ ;
					append using "`female_`W''" ;
					} ;
			* append male observations ;
				foreach W of numlist 1/40
					{ ;
					append using "`male_`W''" ;
					} ;
		* add year vars ;
			gen year_cal = "2020" ;
			gen year_epi = "2019" ;
		* sort data ;
			gsort year_cal week_mmwr gender ;
* merge w/ full dataset ;
	merge 1:1 year_cal week_mmwr gender using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio state all causes by gender analysis - sample data - v13 .dta" ;
* prep & save data ;
	* limit to necessary vars ;
		keep gender year_cal year_epi week_mmwr num_deaths pctile_005 pctile_025 pctile_050 pctile_500 pctile_950 pctile_975 pctile_995 ;
	* limit to calendar year 2020 data ;
		keep if year_cal == "2020" ;
	* reshape to wide format ;
		reshape wide 
			num_deaths pctile_005 pctile_025 pctile_050 pctile_500 pctile_950 pctile_975 pctile_995 , 
			i(year_cal week_mmwr year_epi) j(gender) string ;
	* rename vars ;
		foreach G in female male
			{ ;
			rename num_deaths`G' st_allc_`G'_actual ;
			foreach P in 005 025 050 500 950 975 995 
				{ ;
				rename pctile_`P'`G' st_allc_`G'_p`P' ;
				} ;
			} ;
	* order & sort data ;
		gsort year_cal week_mmwr ;
		order year_cal week_mmwr year_epi st_allc_female_actual st_allc_female_p* st_allc_male_actual st_allc_male_p* ;
	* save data ;
		save "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio state all causes by gender analysis - actual & counter counts - v13 .dta", replace ;
log close ;
end ;