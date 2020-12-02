clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;
log using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio analyses - 03 - results - v13 .smcl", replace ;

* prep data ;
	* merge state-level data sets & save ;
		use "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio state all-cause analysis - actual & counter counts - v13 .dta", clear ;
		foreach X in "all causes by gender" "all causes by age2 (dash)" "all causes by race" "all causes by place" "all causes by ed" 
			{ ;
			gsort year_cal week_mmwr ;
			merge 1:1 year_cal week_mmwr using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio state `X' analysis - actual & counter counts - v13 .dta" ;
			drop _merge ;
			} ;
		* sort & save ;
			gsort year_cal week_mmwr ;
			tempfile state_level  ;
			save "`state_level'" ;
			clear ;
	* read in county-level data ;
		* all causes data ;
			use "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio county all causes analysis - actual & counter counts - v13 .dta", clear ;
*			keep if county == "Franklin" | county == "Cuyahoga" | county == "Hamilton" | county == "Summit" | county == "Montgomery" | county == "Lucas" | county == "Butler" | county == "Stark" | county == "Lorain" | county == "Mahoning" | county == "Marion" ;
			reshape wide cty_allc_actual cty_allc_p005 cty_allc_p025 cty_allc_p050 cty_allc_p500 cty_allc_p950 cty_allc_p975 cty_allc_p995 ,
				i(year_cal week_mmwr year_epi) j(county) string ;
			* revise var names ;
				foreach C in 
					/* Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning */
					Adams Allen Ashland Ashtabula Athens Auglaize Belmont Brown Butler Carroll Champaign Clark Clermont Clinton Columbiana Coshocton Crawford Cuyahoga Darke Defiance Delaware 
					Erie Fairfield Fayette Franklin Fulton Gallia Geauga Greene Guernsey Hamilton Hancock Hardin Harrison Henry Highland Hocking Holmes Huron Jackson Jefferson Knox Lake 
					Lawrence Licking Logan Lorain Lucas Madison Mahoning Marion Medina Meigs Mercer Miami Monroe Montgomery Morgan Morrow Muskingum Noble Ottawa Paulding Perry Pickaway Pike 
					Portage Preble Putnam Richland Ross Sandusky Scioto Seneca Shelby Stark Summit Trumbull Tuscarawas Union Van_Wert Vinton Warren Washington Wayne Williams Wood Wyandot 
					{ ;
					foreach T in actual p005 p025 p050 p500 p950 p975 p995 
						{ ;
						rename cty_allc_`T'`C' cty_allc_`C'_`T' ;
						} ;
					} ;
			* sort & save ;
				gsort year_cal week_mmwr ;
				tempfile county_level_all  ;
				save "`county_level_all'" ;
				clear ;
	* merge state- & county-level datasets ;
		use "`state_level'" , replace ;
		merge 1:1 year_cal week_mmwr using "`county_level_all'" ;
		drop _merge ;
	* merge counts from ohio covid dashboard ;
		gsort year_cal week_mmwr ;
		merge 1:1 year_cal week_mmwr using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio analysis - covid sample data - v13 .dta" ;
		list week_mmwr if _merge ~= 3 ;
		drop _merge ;
* revise & create vars ;
	* shorten select place of death abbreviations to allow for valid var names ;
		rename *emer_dept_out* *ed_out* ;
		rename *nurs_home_ltc* *nhome_ltc* ;
	* weekly & multi-weekly differencs between actual & counterfactual values ;
	* (will calc multi-weekly for week 12 forward) ;
		* state level ;
			foreach Y in 
				allc 
				allc_female allc_male 
				allc_white allc_black 
				allc_00_19 allc_20_49 /* allc_20_29 allc_30_39 allc_40_49 */ allc_50_59 allc_60_69 allc_70_79 allc_80_99 
				allc_nhome_ltc allc_home allc_inpatient allc_hospice allc_ed_out allc_doa 
				allc_no_hs_dipl allc_hs_dipl_ged allc_coll_wo_bach allc_coll_w_bach 
				{ ;
				egen st_`Y'_cm12_actual = sum(st_`Y'_actual) if week_mmwr >= 12 ;
				foreach X in 025 500 975
					{ ;
					egen st_`Y'_cm12_p`X'    = sum(st_`Y'_p`X')   if week_mmwr >= 12 ;
					gen  st_`Y'_dif_p`X'     = st_`Y'_actual - st_`Y'_p`X' ;
					egen st_`Y'_cdif12_p`X'  = sum(st_`Y'_dif_p`X') if week_mmwr >= 12 ;
					} ;
				gen st_`Y'_ciwdth_95 = st_`Y'_p975 - st_`Y'_p025 ;
				} ;
		* county level ;
			foreach C in 
				Adams Allen Ashland Ashtabula Athens Auglaize Belmont Brown Butler Carroll Champaign Clark Clermont Clinton Columbiana Coshocton Crawford Cuyahoga Darke Defiance Delaware 
				Erie Fairfield Fayette Franklin Fulton Gallia Geauga Greene Guernsey Hamilton Hancock Hardin Harrison Henry Highland Hocking Holmes Huron Jackson Jefferson Knox Lake 
				Lawrence Licking Logan Lorain Lucas Madison Mahoning Marion Medina Meigs Mercer Miami Monroe Montgomery Morgan Morrow Muskingum Noble Ottawa Paulding Perry Pickaway Pike 
				Portage Preble Putnam Richland Ross Sandusky Scioto Seneca Shelby Stark Summit Trumbull Tuscarawas Union Van_Wert Vinton Warren Washington Wayne Williams Wood Wyandot 
				{ ;
				egen cty_allc_`C'_cm12_actual = sum(cty_allc_`C'_actual) if week_mmwr >= 12 ;
				foreach Z in 025 500 975
					{ ;
					egen cty_allc_`C'_cm12_p`Z'    = sum(cty_allc_`C'_p`Z')   if week_mmwr >= 12 ;
					gen  cty_allc_`C'_dif_p`Z'     = cty_allc_`C'_actual - cty_allc_`C'_p`Z' ;
					egen cty_allc_`C'_cdif12_p`Z'  = sum(cty_allc_`C'_dif_p`Z') if week_mmwr >= 12 ;
					} ;
				} ;
	* weekly differences btwn actual & covid counts ;
		* state level ;
			gen st_allc_dif_covid = st_allc_actual - st_covid_actual ;
			foreach Y in 
				_female _male 
				_00_19 _20_49 /* _20_29 _30_39 _40_49 */ _50_59 _60_69 _70_79 _80_99
				{ ;
				gen st_allc`Y'_dif_covid = st_allc`Y'_actual - st_covid`Y'_actual ;
				} ;
		* county level ;
			* create vars for counties that had reported covid deaths during the sample period ;
				foreach C in 
					Adams Allen Ashland Ashtabula Athens Auglaize Belmont Brown Butler Carroll Champaign Clark Clermont Clinton Columbiana Coshocton Crawford Cuyahoga Darke Defiance Delaware 
					Erie Fairfield Fayette Franklin Fulton Gallia Geauga Greene Guernsey Hamilton Hancock Hardin Harrison Henry Highland Hocking Holmes Huron Jackson Jefferson Knox Lake 
					Lawrence Licking Logan Lorain Lucas Madison Mahoning Marion Medina Meigs Mercer Miami Monroe Montgomery /* Morgan */ Morrow Muskingum /* Noble */ Ottawa /* Paulding */ Perry Pickaway /* Pike */
					Portage Preble Putnam Richland Ross Sandusky Scioto Seneca Shelby Stark Summit Trumbull Tuscarawas Union Van_Wert Vinton Warren Washington Wayne Williams Wood Wyandot 
					{ ;
					gen cty_allc_`C'_dif_covid = cty_allc_`C'_actual - cty_covid_`C'_actual ;
					} ;
			* create vars for counties that had no reported covid deaths ;
				foreach C in 
					Morgan Noble Paulding Pike 
					{ ;
					gen cty_covid_`C'_actual = 0 ;
					gen cty_allc_`C'_dif_covid = cty_allc_`C'_actual - 0 ;
					} ;
	* calc ratio of multi-weekly observed to expected & excess to reported covid ;
		* county level ;
			foreach C in 
				Adams Allen Ashland Ashtabula Athens Auglaize Belmont Brown Butler Carroll Champaign Clark Clermont Clinton Columbiana Coshocton Crawford Cuyahoga Darke Defiance Delaware 
				Erie Fairfield Fayette Franklin Fulton Gallia Geauga Greene Guernsey Hamilton Hancock Hardin Harrison Henry Highland Hocking Holmes Huron Jackson Jefferson Knox Lake 
				Lawrence Licking Logan Lorain Lucas Madison Mahoning Marion Medina Meigs Mercer Miami Monroe Montgomery Morgan Morrow Muskingum Noble Ottawa Paulding Perry Pickaway Pike 
				Portage Preble Putnam Richland Ross Sandusky Scioto Seneca Shelby Stark Summit Trumbull Tuscarawas Union Van_Wert Vinton Warren Washington Wayne Williams Wood Wyandot 
				{ ;
				gen  cty_allc_`C'_obs_p500_r = cty_allc_`C'_cm12_actual / cty_allc_`C'_cm12_p500 ;
				egen cty_cov_`C'_cm12_actual = sum(cty_covid_`C'_actual) if week_mmwr >= 12 ;
				gen  cty_allc_`C'_exc_cov_r = cty_allc_`C'_cdif12_p500 / cty_cov_`C'_cm12_actual ;
				} ;
	* create date var ;
		gen date_week_end = . ;
		replace date_week_end = date("2020-01-11", "YMD") if week_mmwr == 2 ;
		replace date_week_end = date("2020-01-18", "YMD") if week_mmwr == 3 ;
		replace date_week_end = date("2020-01-25", "YMD") if week_mmwr == 4 ;
		replace date_week_end = date("2020-02-01", "YMD") if week_mmwr == 5 ;
		replace date_week_end = date("2020-02-08", "YMD") if week_mmwr == 6 ;
		replace date_week_end = date("2020-02-15", "YMD") if week_mmwr == 7 ;
		replace date_week_end = date("2020-02-22", "YMD") if week_mmwr == 8 ;
		replace date_week_end = date("2020-02-29", "YMD") if week_mmwr == 9 ;
		replace date_week_end = date("2020-03-07", "YMD") if week_mmwr == 10 ;
		replace date_week_end = date("2020-03-14", "YMD") if week_mmwr == 11 ;
		replace date_week_end = date("2020-03-21", "YMD") if week_mmwr == 12 ;
		replace date_week_end = date("2020-03-28", "YMD") if week_mmwr == 13 ;
		replace date_week_end = date("2020-04-04", "YMD") if week_mmwr == 14 ;
		replace date_week_end = date("2020-04-11", "YMD") if week_mmwr == 15 ;
		replace date_week_end = date("2020-04-18", "YMD") if week_mmwr == 16 ;
		replace date_week_end = date("2020-04-25", "YMD") if week_mmwr == 17 ;
		replace date_week_end = date("2020-05-02", "YMD") if week_mmwr == 18 ;
		replace date_week_end = date("2020-05-09", "YMD") if week_mmwr == 19 ;
		replace date_week_end = date("2020-05-16", "YMD") if week_mmwr == 20 ;
		replace date_week_end = date("2020-05-23", "YMD") if week_mmwr == 21 ;
		replace date_week_end = date("2020-05-30", "YMD") if week_mmwr == 22 ;
		replace date_week_end = date("2020-06-06", "YMD") if week_mmwr == 23 ;
		replace date_week_end = date("2020-06-13", "YMD") if week_mmwr == 24 ;
		replace date_week_end = date("2020-06-20", "YMD") if week_mmwr == 25 ;
		replace date_week_end = date("2020-06-27", "YMD") if week_mmwr == 26 ;
		replace date_week_end = date("2020-07-04", "YMD") if week_mmwr == 27 ;
		replace date_week_end = date("2020-07-11", "YMD") if week_mmwr == 28 ;
		replace date_week_end = date("2020-07-18", "YMD") if week_mmwr == 29 ;
		replace date_week_end = date("2020-07-25", "YMD") if week_mmwr == 30 ;
		replace date_week_end = date("2020-08-01", "YMD") if week_mmwr == 31 ;
		replace date_week_end = date("2020-08-08", "YMD") if week_mmwr == 32 ;
		replace date_week_end = date("2020-08-15", "YMD") if week_mmwr == 33 ;
		replace date_week_end = date("2020-08-22", "YMD") if week_mmwr == 34 ;
		replace date_week_end = date("2020-08-29", "YMD") if week_mmwr == 35 ;
		replace date_week_end = date("2020-09-05", "YMD") if week_mmwr == 36 ;
		replace date_week_end = date("2020-09-12", "YMD") if week_mmwr == 37 ;
		replace date_week_end = date("2020-09-19", "YMD") if week_mmwr == 38 ;
		replace date_week_end = date("2020-09-26", "YMD") if week_mmwr == 39 ;
		replace date_week_end = date("2020-10-03", "YMD") if week_mmwr == 40 ;
* numeric results ;
	* state level ;
		* actual, counterfactual, & covid dashboard ;
			tabstat 
				st_allc_cm12_actual 
				st_allc_cm12_p500 st_allc_cm12_p025 st_allc_cm12_p975 
				st_allc_cdif12_p500 st_allc_cdif12_p975 st_allc_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			tabstat 
				st_covid_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			foreach Y in 
				female male 
				00_19 20_49 /* 20_29 30_39 40_49 */ 50_59 60_69 70_79 80_99 
				{ ;
				display _newline(3) ;
				display as error "group: `Y'" ;
				tabstat 
					st_allc_`Y'_cm12_actual 
					st_allc_`Y'_cm12_p500 st_allc_`Y'_cm12_p025 st_allc_`Y'_cm12_p975 
					st_allc_`Y'_cdif12_p500 st_allc_`Y'_cdif12_p975 st_allc_`Y'_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				tabstat 
					st_covid_`Y'_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				} ;
		* actual vs counterfactual only (ie, no covid dashboard data available) ;
			foreach Y in 
				allc_white allc_black
				allc_doa allc_ed_out allc_home allc_hospice allc_inpatient allc_nhome_ltc 
				allc_no_hs_dipl allc_hs_dipl_ged allc_coll_wo_bach allc_coll_w_bach 
				{ ;
				display _newline(3) ;
				display as error "st_`Y'" ;
				tabstat 
					st_`Y'_cm12_actual 
					st_`Y'_cm12_p500 st_`Y'_cm12_p025 st_`Y'_cm12_p975 
					st_`Y'_cdif12_p500 st_`Y'_cdif12_p975 st_`Y'_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				} ;
/*
	* county level ;
		foreach C in
			Adams Allen Ashland Ashtabula Athens Auglaize Belmont Brown Butler Carroll Champaign Clark Clermont Clinton Columbiana Coshocton Crawford Cuyahoga Darke Defiance Delaware 
			Erie Fairfield Fayette Franklin Fulton Gallia Geauga Greene Guernsey Hamilton Hancock Hardin Harrison Henry Highland Hocking Holmes Huron Jackson Jefferson Knox Lake 
			Lawrence Licking Logan Lorain Lucas Madison Mahoning Marion Medina Meigs Mercer Miami Monroe Montgomery Morgan Morrow Muskingum Noble Ottawa Paulding Perry Pickaway Pike 
			Portage Preble Putnam Richland Ross Sandusky Scioto Seneca Shelby Stark Summit Trumbull Tuscarawas Union Van_Wert Vinton Warren Washington Wayne Williams Wood Wyandot 
			{ ;
			display _newline(3) ;
			display as error "`C'" ;
			display as error "`X'" ;
			tabstat 
				cty_allc_`C'_cm12_actual 
				cty_allc_`C'_cm12_p500 cty_allc_`C'_cm12_p975 cty_allc_`C'_cm12_p025 
				cty_allc_`C'_cdif12_p500 cty_allc_`C'_cdif12_p975 cty_allc_`C'_cdif12_p025 
				, stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			tabstat 
				cty_allc_`C'_obs_p500_r cty_allc_`C'_exc_cov_r if week_mmwr >= 12 , stat(mean) longstub format(%9.2fc) columns(statistics) varwidth(20) ;
			tabstat 
				cty_covid_`C'_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			} ;
*/
* graph results ;
	* graphing set-up ;
		pause off ;
		graph set window fontface "Times New Roman" ;
		cd "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs" ; 
		set scheme s1color ;
	* actual w/ counterfactual 95% PI & (actual - # covid deaths) ;
		* prep individual graphs ;
			* all causes ;
				twoway
					rarea st_allc_p975 st_allc_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) /* ||
					line st_allc_p500 date_week_end             
						if week_mmwr > 1 , /* lwidth(thick) */ lcolor(black) lpattern(dash) */ ,
					/* t1title("all causes") */
					/* ysize(4)
					xsize(4) */
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-2) )
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(5.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(medsmall) 
						region(margin(l=2 r=4 t=1))
						/* forcesize */
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc - 95ci - covid diff - v13 "     , replace ;
					graph export "graph - st allc - 95ci - covid diff - v13 .eps" , replace preview(on) fontface("Times New Roman") ;
					graph export "graph - st allc - 95ci - covid diff - v13 .emf" , replace ;
				pause ;
			* by gender ;
				twoway
					rarea st_allc_female_p975 st_allc_female_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_female_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_female_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("Females", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					yscale(r(0))
					ytitle( "Number of deaths" , size(large)  axis(1) orientation(vertical) xoffset(-2) )
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					;
					graph save   "graph - st allc female - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc female - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_male_p975 st_allc_male_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_male_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_male_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("Males", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					yscale(r(0))
					ytitle( "" , size(large) axis(1) orientation(vertical) xoffset(-0) )
					ylabel( #4, axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc male - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc male - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
			* by age ;
				twoway
					rarea st_allc_00_19_p975 st_allc_00_19_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_00_19_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(red) ||
					line st_allc_00_19_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("0-19 years old", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-2) )
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc 00_19 - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc 00_19 - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_20_49_p975 st_allc_20_49_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_20_49_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_20_49_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("20-49 years old", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-2) )
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc 20_49 - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc 20_49 - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_50_59_p975 st_allc_50_59_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_50_59_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_50_59_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("50-59 years old", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large)  axis(1) orientation(vertical) xoffset(-2) )
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc 50_59 - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc 50_59 - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_60_69_p975 st_allc_60_69_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_60_69_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_60_69_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("60-69 years old", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large)  axis(1) orientation(vertical) xoffset(-2) )
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc 60_69 - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc 60_69 - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_70_79_p975 st_allc_70_79_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_70_79_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_70_79_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("70-79 years old", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( 0(200)800 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					graphregion(margin(l-2 /* r+10 */))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc 70_79 - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc 70_79 - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_80_99_p975 st_allc_80_99_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_80_99_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ||
					line st_allc_80_99_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(medthick) lcolor(blue) ,
					t1title("80+ years old", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					graphregion(margin(l-2 /* r+10 */))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						label(3 "Observed deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						height(6.0)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(l=2 r=4 t=1))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc 80_99 - 95ci - covid diff - v13 "    , replace ;
					graph export "graph - st allc 80_99 - 95ci - covid diff - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
					pause ;
			* by place of death ;
				twoway
					rarea st_allc_doa_p975 st_allc_doa_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_doa_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Dead on arrival", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc doa - 95ci - v13 "    , replace ;
					graph export "graph - st allc doa - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_home_p975 st_allc_home_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_home_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Home", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc home - 95ci - v13 "    , replace ;
					graph export "graph - st allc home - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_ed_out_p975 st_allc_ed_out_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_ed_out_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Emergency department or outpatient", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc ed_out - 95ci - v13 "    , replace ;
					graph export "graph - st allc ed_out - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_hospice_p975 st_allc_hospice_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_hospice_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Hospice", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large)  axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc hospice - 95ci - v13 "    , replace ;
					graph export "graph - st allc hospice - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_inpatient_p975 st_allc_inpatient_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_inpatient_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Inpatient", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc inpatient - 95ci - v13 "    , replace ;
					graph export "graph - st allc inpatient - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_nhome_ltc_p975 st_allc_nhome_ltc_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_nhome_ltc_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Nursing home or long-term care", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc nhome_ltc - 95ci - v13 "    , replace ;
					graph export "graph - st allc nhome_ltc - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
			* by educational attainment ;
				twoway
					rarea st_allc_no_hs_dipl_p975 st_allc_no_hs_dipl_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_no_hs_dipl_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("No high school diploma", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc no_hs_dipl - 95ci - v13 "    , replace ;
					graph export "graph - st allc no_hs_dipl - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_hs_dipl_ged_p975 st_allc_hs_dipl_ged_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_hs_dipl_ged_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("High school diploma or GED", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc hs_dipl_ged - 95ci - v13 "    , replace ;
					graph export "graph - st allc hs_dipl_ged - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_coll_wo_bach_p975 st_allc_coll_wo_bach_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_coll_wo_bach_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("College without bachelor's degree", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc coll_wo_bach - 95ci - v13 "    , replace ;
					graph export "graph - st allc coll_wo_bach - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_coll_w_bach_p975 st_allc_coll_w_bach_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_coll_w_bach_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Bachelor's degree or higher", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(medium)
						keygap(tiny)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						forcesize
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc coll_w_bach - 95ci - v13  "    , replace ;
					graph export "graph - st allc coll_w_bach - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
			* by race ;
				twoway
					rarea st_allc_white_p975 st_allc_white_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_white_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Whites", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(medium)
						colgap(large)
						keygap(large)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						/* forcesize */
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc white - 95ci - v13 "    , replace ;
					graph export "graph - st allc white - 95ci - v13 .wmf"  , replace fontface("Times New Roman") ;
				pause ;
				twoway
					rarea st_allc_black_p975 st_allc_black_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line st_allc_black_actual date_week_end             
						if week_mmwr > 1 , lwidth(medthick) ,
					t1title("Blacks", size(vlarge))
					xtitle("")
					xlabel( 21932(42)22191 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(large) ) 
					ytitle( "Number of deaths" , size(large) axis(1) orientation(vertical) xoffset(-1))
					yscale(r(0))
					ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(large) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed deaths")
						order(2 1) 
						cols(2)
						/* width(100) */
						height(1.8)
						size(medium) 
						rowgap(large)
						colgap(large)
						keygap(large)
						symxsize(large) 
						symysize(large) 
						region(margin(medsmall))
						/* forcesize */
						/* rowgap(tiny) */
						) ;
					graph save   "graph - st allc black - 95ci - v13 "    , replace ;
					graph export "graph - st allc black - 95ci - v13 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
stop ;
/*
			* by county ;
				twoway
					rarea cty_allc_Franklin_p975 cty_allc_Franklin_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Franklin_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick)||
					line cty_allc_Franklin_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Franklin", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "Number of deaths" , size(small) axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Franklin - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Franklin - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Cuyahoga_p975 cty_allc_Cuyahoga_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Cuyahoga_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Cuyahoga_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Cuyahoga", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(
						label(1 "Expected 95% PI")
						label(2 "Observed 2020 deaths")
						label(3 "Observed 2020 deaths less reported COVID-19 deaths")
						order(2 1 3) 
						cols(2)
						/* width(100) */
						/* height(.8) */
						size(tiny) 
						rowgap(half_tiny)
						colgap(half_tiny)
						keygap(half_tiny)
						symxsize(half_tiny) 
						symysize(half_tiny) 
						/* forcesize */
						/* rowgap(tiny) */
						) ;
					graph save   "graph - cty allc Cuyahoga - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Cuyahoga - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Hamilton_p975 cty_allc_Hamilton_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Hamilton_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Hamilton_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Hamilton", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "Number of deaths" , size(small) axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Hamilton - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Hamilton - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Summit_p975 cty_allc_Summit_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Summit_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Summit_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Summit", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Summit - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Summit - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Montgomery_p975 cty_allc_Montgomery_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Montgomery_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Montgomery_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Montgomery", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "Number of deaths" , size(small) axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Montgomery - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Montgomery - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Lucas_p975 cty_allc_Lucas_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Lucas_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Lucas_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Lucas", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Lucas - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Lucas - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Butler_p975 cty_allc_Butler_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Butler_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Butler_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Butler", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "Number of deaths" , size(small) axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Butler - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Butler - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Stark_p975 cty_allc_Stark_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Stark_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Stark_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Stark", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Stark - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Stark - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Lorain_p975 cty_allc_Lorain_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Lorain_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick)||
					line cty_allc_Lorain_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Lorain", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "Number of deaths" , size(small) axis(1) orientation(vertical) xoffset(-0))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					legend(off) ;
					graph save   "graph - cty allc Lorain - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Lorain - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
				twoway
					rarea cty_allc_Mahoning_p975 cty_allc_Mahoning_p025 date_week_end 			
						if week_mmwr > 1 , color(gs11) ||
					line cty_allc_Mahoning_actual date_week_end             
						if week_mmwr > 1 , lwidth(thick) ||
					line cty_allc_Mahoning_dif_covid date_week_end             
						if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
					t1title("Mahoning", size(small))
					xtitle("")
					xlabel( 21932(35)22058 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(vsmall) )
					ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(+0.5))
					yscale(r(0))
					ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(vsmall) ) 
					plotregion(margin(tiny))
					graphregion(margin(l-2 /* r+10 */))
					legend(off) ;
					graph save   "graph - cty allc Mahoning - 95ci - covid diff - v12 "    , replace ;
					graph export "graph - cty allc Mahoning - 95ci - covid diff - v12 .eps"  , replace preview(on) fontface("Times New Roman") ;
				pause ;
		* combine graphs ;
			* state by gender ;
				grc1leg 
					"graph - st allc female - 95ci - covid diff - v12"
					"graph - st allc male - 95ci - covid diff - v12" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(1)
					/* imargin(0 0 0 0 0) */
					/* fxsize(100) */
					fysize(65) 
					/* xcommon */ 
					legendfrom("graph - st allc female - 95ci - covid diff - v12") 
					position(6)
					ring(-1)
					span ;
					graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs\grph - comb - st all causes by gend - 95ci - v12 "    , replace ;
					graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs\grph - comb - st all causes by gend - 95ci - v12.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs\grph - comb - st all causes by gend - 95ci - v12.emf", replace ;
				pause ;
			* state by age ;
				grc1leg 
					"graph - st allc 00_19 - 95ci - covid diff - v12"
					"graph - st allc 20_49 - 95ci - covid diff - v12"
					"graph - st allc 50_59 - 95ci - covid diff - v12"
					"graph - st allc 60_69 - 95ci - covid diff - v12"
					"graph - st allc 70_79 - 95ci - covid diff - v12"
					"graph - st allc 80_99 - 95ci - covid diff - v12" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(3)
					/* imargin(0 0 0 0 0) */
					fxsize(75)  
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - st allc 00_19 - 95ci - covid diff - v12") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - st all causes by age - 95ci - v12 "    , replace ;
					graph export "grph - comb - st all causes by age - 95ci - v12.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - st all causes by age - 95ci - v12.emf"  , replace ;
				pause ;
			* state by ed ;
				grc1leg 
					"graph - st allc no_hs_dipl - 95ci - v12"
					"graph - st allc hs_dipl_ged - 95ci - v12" 
					"graph - st allc coll_wo_bach - 95ci - v12" 
					"graph - st allc coll_w_bach - 95ci - v12" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(2)
					/* imargin(0 0 0 0 0) */
					fxsize(100) 
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - st allc no_hs_dipl - 95ci - v12") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - st all causes by ed - 95ci - v12"    , replace ;
					graph export "grph - comb - st all causes by ed - 95ci - v12.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - st all causes by ed - 95ci - v12.emf"  , replace ;
				pause ;
			* state by place of death ;
				grc1leg 
					"graph - st allc nhome_ltc - 95ci - v12" 
					"graph - st allc home - 95ci - v12"
					"graph - st allc inpatient - 95ci - v12"
					"graph - st allc hospice - 95ci - v12"
					"graph - st allc ed_out - 95ci - v12"
					"graph - st allc doa - 95ci - v12" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(3)
					/* imargin(0 0 0 0 0) */
					fxsize(75) 
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - st allc doa - 95ci - v12") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - st all causes by place - 95ci - v12"    , replace ;
					graph export "grph - comb - st all causes by place - 95ci - v12.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - st all causes by place - 95ci - v12.emf"  , replace ;
				pause ;
			* county by county ;
				grc1leg 
					"graph - cty allc Franklin - 95ci - covid diff - v12"
					"graph - cty allc Cuyahoga - 95ci - covid diff - v12"
					"graph - cty allc Hamilton - 95ci - covid diff - v12"
					"graph - cty allc Summit - 95ci - covid diff - v12"
					"graph - cty allc Montgomery - 95ci - covid diff - v12"
					"graph - cty allc Lucas - 95ci - covid diff - v12"
					"graph - cty allc Butler - 95ci - covid diff - v12"
					"graph - cty allc Stark - 95ci - covid diff - v12"
					"graph - cty allc Lorain - 95ci - covid diff - v12"
					"graph - cty allc Mahoning - 95ci - covid diff - v12" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(5)
					/* imargin(0 0 0 0 0) */
					fxsize(65) 
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - cty allc Cuyahoga - 95ci - covid diff - v12") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - cty all causes - 95ci - v12 "    , replace ;
					graph export "grph - comb - cty all causes - 95ci - v12.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - cty all causes - 95ci - v12.emf"  , replace ;
* export datasets to excel for health affairs graphs ;
	* overall & by gender ;
		export excel 
			date_week_end
			st_allc_actual        st_allc_dif_covid        st_allc_p025        st_allc_ciwdth_95
			st_allc_female_actual st_allc_female_dif_covid st_allc_female_p025 st_allc_female_ciwdth_95
			st_allc_male_actual   st_allc_male_dif_covid   st_allc_male_p025   st_allc_male_ciwdth_95
			using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\2020-07 - health affairs\excel files\overall & gender.xlsx" 
			if week_mmwr > 1 , 
			firstrow(variables) replace ; 
	* by gender ;
		export excel 
			date_week_end
			st_allc_female_actual st_allc_female_dif_covid st_allc_female_p025 st_allc_female_ciwdth_95
			st_allc_male_actual   st_allc_male_dif_covid   st_allc_male_p025   st_allc_male_ciwdth_95
			using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\2020-07 - health affairs\excel files\gender.xlsx" 
			if week_mmwr > 1 , 
			firstrow(variables) replace ; 
	* by age group ;
		export excel 
			date_week_end
			st_allc_00_19_actual st_allc_00_19_dif_covid st_allc_00_19_p025 st_allc_00_19_ciwdth_95
			st_allc_20_49_actual st_allc_20_49_dif_covid st_allc_20_49_p025 st_allc_20_49_ciwdth_95
			st_allc_50_59_actual st_allc_50_59_dif_covid st_allc_50_59_p025 st_allc_50_59_ciwdth_95
			st_allc_60_69_actual st_allc_60_69_dif_covid st_allc_60_69_p025 st_allc_60_69_ciwdth_95
			st_allc_70_79_actual st_allc_70_79_dif_covid st_allc_70_79_p025 st_allc_70_79_ciwdth_95
			st_allc_80_99_actual st_allc_80_99_dif_covid st_allc_80_99_p025 st_allc_80_99_ciwdth_95
			using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\2020-07 - health affairs\excel files\age group .xlsx" 
			if week_mmwr > 1 , 
			firstrow(variables) replace ; 
	* by education ;
		export excel 
			date_week_end
			st_allc_no_hs_dipl_actual   st_allc_no_hs_dipl_p025   st_allc_no_hs_dipl_ciwdth_95
			st_allc_hs_dipl_ged_actual  st_allc_hs_dipl_ged_p025  st_allc_hs_dipl_ged_ciwdth_95
			st_allc_coll_wo_bach_actual st_allc_coll_wo_bach_p025 st_allc_coll_wo_bach_ciwdth_95
			st_allc_coll_w_bach_actual  st_allc_coll_w_bach_p025  st_allc_coll_w_bach_ciwdth_95
			using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\2020-07 - health affairs\excel files\ed attain .xlsx" 
			if week_mmwr > 1 , 
			firstrow(variables) replace ; 
	* by place of death ;
		export excel 
			date_week_end
			st_allc_nhome_ltc_actual st_allc_nhome_ltc_p025 st_allc_nhome_ltc_ciwdth_95
			st_allc_home_actual      st_allc_home_p025      st_allc_home_ciwdth_95
			st_allc_inpatient_actual st_allc_inpatient_p025 st_allc_inpatient_ciwdth_95
			st_allc_hospice_actual   st_allc_hospice_p025   st_allc_hospice_ciwdth_95
			st_allc_ed_out_actual    st_allc_ed_out_p025    st_allc_ed_out_ciwdth_95
			st_allc_doa_actual       st_allc_doa_p025       st_allc_doa_ciwdth_95
			using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\2020-07 - health affairs\excel files\place .xlsx" 
			if week_mmwr > 1 , 
			firstrow(variables) replace ; 
*/
*/
* county-level maps ;
	* prep analytic dataset ;
		* save analytic dataset for later use ;
			tempfile analytic_data  ;
			save "`analytic_data'" ;
		* limit to relevant vars & observations ;
			keep cty_allc_*_obs_p500_r ;
			keep if _n == _N ;
		* reshape data ;
			* first need to rename var ;
				rename cty_allc_*_obs_p500_r cty_allc_* ;
			gen one = 1 ;
			reshape long cty_allc_, i(one) j(county) string ;
			drop one ;
		* revise rate var name ;
			rename cty_allc_ obs_p500_r ;
		* revise Van Wert county name ;
			replace county = "Van Wert" if county == "Van_Wert" ; 
		* save dataset ;
			gsort county ;
			tempfile analytic_map_data  ;
			save "`analytic_map_data'" ;
			clear ;
	* open & save state boundaries data ;
		* spshapte2dta requires use of local path ;
			cd "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work" ;
		* create dta file; 
			spshape2dta "C:\Users\Troy\Box Sync\_ troy's files\research\_data\us\census bureau\geographic data\cb_2018_us_county_500k.shp",                                 
			saving(geodata_us_counties) replace ;
	* merge state boundaries data to analytic dataset ;
		use geodata_us_counties.dta, clear ;
		* limit to ohio counties ;
			keep if STATEFP == "39" ;
		* rename county var ;
			rename NAME county ;
		* sort data ;
			gsort county ;
		* merge w/ analytic map data ;
			merge 1:1 county using "`analytic_map_data'" ;
	* create graphs ;
		grmap obs_p500_r , 
			clnumber(8) clmethod(custom) clbreaks(.8 .9 1 1.1 1.2 1.3 1.4)
			fcolor(Heat) ndfcolor(black)
			title("", size(huge)) 
			legend(size(medium)) ;
		


		
	

stop ;

			* save revised dataset ;
				save geodata_us_counties.dta, replace ;

stop ;
			

stop ;
			rename NAME state ;
			gsort state ;
			merge 1:m state using "`analytic_data'"	 ;
		

cty_allc_`C'_obs_p500_r




log close ;
end ;



 