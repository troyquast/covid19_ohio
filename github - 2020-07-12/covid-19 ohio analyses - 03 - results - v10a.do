clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;
log using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio analyses - 03 - results - v10a .smcl", replace ;

* prep data ;
	* merge state-level data sets & save ;
		use "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio state all-cause analysis - actual & counter counts - v6 .dta", clear ;
		foreach X in "all causes by gender" "all causes by age (dash)" "all causes by race" "all causes by ed"  
			{ ;
			gsort year_cal week_mmwr ;
			merge 1:1 year_cal week_mmwr using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio state `X' analysis - actual & counter counts - v7 .dta" ;
			drop _merge ;
			} ;
		* sort & save ;
			gsort year_cal week_mmwr ;
			tempfile state_level  ;
			save "`state_level'" ;
			clear ;
	* read in county-level data & limit to 10 largest ;
		* all causes data ;
			use "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\counter mort datasets\covid-19 ohio county all causes analysis - actual & counter counts - v7 .dta", clear ;
			keep if county == "Franklin" | county == "Cuyahoga" | county == "Hamilton" | county == "Summit" | county == "Montgomery" | county == "Lucas" | county == "Butler" | county == "Stark" | county == "Lorain" | county == "Mahoning" | county == "Marion" ;
			reshape wide cty_allc_actual cty_allc_p005 cty_allc_p025 cty_allc_p050 cty_allc_p500 cty_allc_p950 cty_allc_p975 cty_allc_p995 ,
				i(year_cal week_mmwr year_epi) j(county) string ;
			* revise var names ;
				foreach C in Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning Marion
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
		merge 1:1 year_cal week_mmwr using "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\covid-19 ohio analysis - covid sample data - v1 .dta" ;
		list week_mmwr if _merge ~= 3 ;
		drop _merge ;
* revise & create vars ;
	* weekly & multi-weekly differencs between actual & counterfactual values ;
	* (will calc multi-weekly for week 12 forward) ;
		* state level ;
			foreach Y in 
				allc 
				allc_female allc_male 
				allc_00_19 allc_20_29 allc_30_39 allc_40_49 allc_50_59 allc_60_69 allc_70_79 allc_80_99 
				allc_black allc_white 
				allc_no_hs_dipl allc_hs_dipl_ged allc_coll_wo_bach allc_coll_w_bach 
				{ ;
				egen st_`Y'_cm12_actual = sum(st_`Y'_actual) if week_mmwr >= 12 ;
				foreach X in 025 500 975
					{ ;
					egen st_`Y'_cm12_p`X'    = sum(st_`Y'_p`X')   if week_mmwr >= 12 ;
					gen  st_`Y'_dif_p`X'     = st_`Y'_actual - st_`Y'_p`X' ;
					egen st_`Y'_cdif12_p`X'  = sum(st_`Y'_dif_p`X') if week_mmwr >= 12 ;
					} ;
				} ;
		* county level ;
			foreach C in Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning Marion
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
				_00_19 _20_29 _30_39 _40_49 _50_59 _60_69 _70_79 _80_99
				{ ;
				gen st_allc`Y'_dif_covid = st_allc`Y'_actual - st_covid`Y'_actual ;
				} ;
		* county level ;
			foreach C in Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning Marion
				{ ;
				gen cty_allc_`C'_dif_covid = cty_allc_`C'_actual - cty_covid_`C'_actual ;
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
* numeric results ;
	* state level ;
		* actual, counterfactual, & covid dashboard ;
			tabstat 
				st_allc_cm12_actual 
				st_allc_cm12_p500 st_allc_cm12_p975 st_allc_cm12_p025 
				st_allc_cdif12_p500 st_allc_cdif12_p975 st_allc_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			tabstat 
				st_covid_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			foreach Y in 
				female male 
				00_19 20_29 30_39 40_49 50_59 60_69 70_79 80_99 
				{ ;
				display _newline(3) ;
				display as error "group: `Y'" ;
				tabstat 
					st_allc_`Y'_cm12_actual 
					st_allc_`Y'_cm12_p500 st_allc_`Y'_cm12_p975 st_allc_`Y'_cm12_p025 
					st_allc_`Y'_cdif12_p500 st_allc_`Y'_cdif12_p975 st_allc_`Y'_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				tabstat 
					st_covid_`Y'_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				} ;
		* actual vs counterfactual only (ie, no covid dashboard data available) ;
			foreach Y in 
				allc_black allc_white 
				allc_no_hs_dipl allc_hs_dipl_ged allc_coll_wo_bach allc_coll_w_bach 
				{ ;
				display _newline(3) ;
				display as error "st_`Y'" ;
				tabstat 
					st_`Y'_cm12_actual 
					st_`Y'_cm12_p500 st_`Y'_cm12_p975 st_`Y'_cm12_p025 
					st_`Y'_cdif12_p500 st_`Y'_cdif12_p975 st_`Y'_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				} ;
	* county level ;
		foreach C in Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning Marion
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
					cty_covid_`C'_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			} ;
* graph results ;
	* graphing set-up ;
		pause off ;
		graph set window fontface "Times New Roman" ;
		cd "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs" ; 
		set scheme s1color ;
	* actual w/ counterfactual 95% CI & (actual - # covid deaths) ;
		* prep individual graphs ;
			twoway
				rarea st_allc_p975 st_allc_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) /* ||
				line st_allc_p500 date_week_end             
					if week_mmwr > 1 , /* lwidth(thick) */ lcolor(black) lpattern(dash) */ ,
				/* t1title("all causes") */
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) ) 
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-2) )
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				/* legend(off) ; */
				legend(
					label(1 "Expected deaths 95% CI")
					label(2 "Observed deaths")
					label(3 "Observed deaths less reported COVID-19 deaths")
					/* label(4 "Expected deaths") */
					order(2 /* 4 */ 3 1) 
					cols(2)
					/* height(.8) */
					size(small) 
					/* rowgap(tiny)
					colgap(tiny)
					keygap(tiny) */
					symxsize(small) /*
					symysize(tiny) */
					forcesize 
					/* rowgap(tiny) */
					)
				;
				graph save   "graph - st allc - 95ci - covid diff "     , replace ;
				graph export "graph - st allc - 95ci - covid diff .eps" , replace preview(on) fontface("Times New Roman") ;
				graph export "graph - st allc - 95ci - covid diff .emf" , replace ;
			pause ;
			twoway
				rarea st_allc_female_p975 st_allc_female_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_female_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_female_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Females")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) ) 
				yscale(r(0))
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-2) )
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(
					label(1 "Expected 95% CI")
					label(2 "Observed 2020 deaths")
					label(3 "Observed 2020 deaths less reported COVID-19 deaths")
					order(2 1 3) 
					cols(3)
					/* width(100) */
					height(.8)
					size(vsmall) 
					rowgap(tiny)
					colgap(tiny)
					keygap(tiny)
					symxsize(tiny) 
					symysize(tiny) 
					/* forcesize */
					/* rowgap(tiny) */
					)
				;
				graph save   "graph - st allc female - 95ci - covid diff "    , replace ;
				graph export "graph - st allc female - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_male_p975 st_allc_male_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_male_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_male_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Males")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				yscale(r(0))
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0) )
				ylabel( #4, axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) 
				; 
				graph save   "graph - st allc male - 95ci - covid diff "    , replace ;
				graph export "graph - st allc male - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_00_19_p975 st_allc_00_19_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_00_19_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(red) ||
				line st_allc_00_19_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("0-19 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-2) )
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(
					label(1 "Expected 95% CI")
					label(2 "Observed 2020 deaths")
					label(3 "Observed 2020 deaths less reported COVID-19 deaths")
					order(2 1 3) 
					cols(3)
					/* width(100) */
					height(.8)
					size(vsmall) 
					rowgap(tiny)
					colgap(tiny)
					keygap(tiny)
					symxsize(tiny) 
					symysize(tiny) 
					/* forcesize */
					/* rowgap(tiny) */
					) ;
				graph save   "graph - st allc 00_19 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 00_19 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_20_29_p975 st_allc_20_29_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_20_29_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_20_29_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("20-29 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc 20_29 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 20_29 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_30_39_p975 st_allc_30_39_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_30_39_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_30_39_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("30-39 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc 30_39 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 30_39 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_40_49_p975 st_allc_40_49_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_40_49_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_40_49_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("40-49 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				graphregion(margin(l-2 /* r+10 */))
				legend(off) ;
				graph save   "graph - st allc 40_49 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 40_49 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_50_59_p975 st_allc_50_59_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_50_59_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_50_59_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("50-59 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc 50_59 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 50_59 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_60_69_p975 st_allc_60_69_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_60_69_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_60_69_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("60-69 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc 60_69 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 60_69 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_70_79_p975 st_allc_70_79_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_70_79_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_70_79_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("70-79 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				graphregion(margin(l-2 /* r+10 */))
				legend(off) ;
				graph save   "graph - st allc 70_79 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 70_79 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_80_99_p975 st_allc_80_99_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_80_99_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_80_99_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("80+ years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				graphregion(margin(l-2 /* r+10 */))
				legend(off) ;
				graph save   "graph - st allc 80_99 - 95ci - covid diff "    , replace ;
				graph export "graph - st allc 80_99 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_black_p975 st_allc_black_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_black_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("Blacks")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(
					label(1 "Expected 95% CI")
					label(2 "Observed 2020 deaths")
					order(2 1) 
					cols(2)
					/* width(100) */
					height(.8)
					size(vsmall) 
					rowgap(tiny)
					colgap(tiny)
					keygap(tiny)
					symxsize(tiny) 
					symysize(tiny) 
					/* forcesize */
					/* rowgap(tiny) */
					) ;
				graph save   "graph - st allc black - 95ci "    , replace ;
				graph export "graph - st allc black - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_white_p975 st_allc_white_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_white_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("Whites")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc white - 95ci  "    , replace ;
				graph export "graph - st allc white - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_no_hs_dipl_p975 st_allc_no_hs_dipl_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_no_hs_dipl_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("No high school diploma")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(
					label(1 "Expected 95% CI")
					label(2 "Observed 2020 deaths")
					label(3 "Observed 2020 deaths less reported COVID-19 deaths")
					order(2 1 3) 
					cols(3)
					/* width(100) */
					height(.8)
					size(vsmall) 
					rowgap(tiny)
					colgap(tiny)
					keygap(tiny)
					symxsize(tiny) 
					symysize(tiny) 
					/* forcesize */
					/* rowgap(tiny) */
					) ;
				graph save   "graph - st allc no_hs_dipl - 95ci  "    , replace ;
				graph export "graph - st allc no_hs_dipl - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_hs_dipl_ged_p975 st_allc_hs_dipl_ged_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_hs_dipl_ged_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("High school diploma or GED")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc hs_dipl_ged - 95ci  "    , replace ;
				graph export "graph - st allc hs_dipl_ged - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_coll_wo_bach_p975 st_allc_coll_wo_bach_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_coll_wo_bach_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("College without bachelor's degree")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc coll_wo_bach - 95ci  "    , replace ;
				graph export "graph - st allc coll_wo_bach - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_allc_coll_w_bach_p975 st_allc_coll_w_bach_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_coll_w_bach_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("College with bachelor's degree or higher")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st allc coll_w_bach - 95ci  "    , replace ;
				graph export "graph - st allc coll_w_bach - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Franklin_p975 cty_allc_Franklin_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Franklin_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick)||
				line cty_allc_Franklin_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Franklin county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Franklin - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Franklin - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Cuyahoga_p975 cty_allc_Cuyahoga_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Cuyahoga_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Cuyahoga_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Cuyahoga county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(
					label(1 "Expected 95% CI")
					label(2 "Observed 2020 deaths")
					label(3 "Observed 2020 deaths less reported COVID-19 deaths")
					order(2 1 3) 
					cols(3)
					/* width(100) */
					height(.8)
					size(vsmall) 
					rowgap(tiny)
					colgap(tiny)
					keygap(tiny)
					symxsize(tiny) 
					symysize(tiny) 
					/* forcesize */
					/* rowgap(tiny) */
					) ;
				graph save   "graph - cty allc Cuyahoga - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Cuyahoga - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Hamilton_p975 cty_allc_Hamilton_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Hamilton_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Hamilton_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Hamilton county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Hamilton - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Hamilton - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Summit_p975 cty_allc_Summit_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Summit_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Summit_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Summit county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Summit - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Summit - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Montgomery_p975 cty_allc_Montgomery_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Montgomery_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Montgomery_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Montgomery county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Montgomery - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Montgomery - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Lucas_p975 cty_allc_Lucas_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Lucas_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Lucas_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Lucas county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Lucas - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Lucas - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Butler_p975 cty_allc_Butler_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Butler_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Butler_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Butler county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Butler - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Butler - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Stark_p975 cty_allc_Stark_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Stark_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Stark_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Stark county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Stark - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Stark - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Lorain_p975 cty_allc_Lorain_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Lorain_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick)||
				line cty_allc_Lorain_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Lorain county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Lorain - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Lorain - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Mahoning_p975 cty_allc_Mahoning_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Mahoning_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Mahoning_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Mahoning county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(+0.5))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				graphregion(margin(l-2 /* r+10 */))
				legend(off) ;
				graph save   "graph - cty allc Mahoning - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Mahoning - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_allc_Marion_p975 cty_allc_Marion_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_allc_Marion_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_allc_Marion_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Marion county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty allc Marion - 95ci - covid diff "    , replace ;
				graph export "graph - cty allc Marion - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
		* combine graphs ;
			* state by gender ;
				grc1leg 
					"graph - st allc female - 95ci - covid diff"
					"graph - st allc male - 95ci - covid diff" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(1)
					/* imargin(0 0 0 0 0) */
					fxsize(95) 
					fysize(50) 
					/* xcommon */ 
					legendfrom("graph - st allc female - 95ci - covid diff") 
					position(6)
					ring(-1)
					span ;
					graph save   "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs\grph - comb - st all causes by gend - 95ci "    , replace ;
					graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs\grph - comb - st all causes by gend - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "C:\Users\Troy\Box Sync\_ troy's files\research\covid-19\2020-05 - ohio analysis\stata work\graphs\grph - comb - st all causes by gend - 95ci.emf", replace ;
				pause ;
			* state by age ;
				grc1leg 
					"graph - st allc 00_19 - 95ci - covid diff"
					"graph - st allc 20_29 - 95ci - covid diff"
					"graph - st allc 30_39 - 95ci - covid diff"
					"graph - st allc 40_49 - 95ci - covid diff"
					"graph - st allc 50_59 - 95ci - covid diff"
					"graph - st allc 60_69 - 95ci - covid diff"
					"graph - st allc 70_79 - 95ci - covid diff"
					"graph - st allc 80_99 - 95ci - covid diff" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(3)
					/* imargin(0 0 0 0 0) */
					/* fxsize(95) */
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - st allc 00_19 - 95ci - covid diff") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - st all causes by age - 95ci "    , replace ;
					graph export "grph - comb - st all causes by age - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - st all causes by age - 95ci.emf"  , replace ;
				pause ;
			* state by race ;
				grc1leg 
					"graph - st allc black - 95ci"
					"graph - st allc white - 95ci" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(1)
					/* imargin(0 0 0 0 0) */
					fxsize(95) 
					fysize(50) 
					/* xcommon */ 
					legendfrom("graph - st allc black - 95ci") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - st all causes by race - 95ci "    , replace ;
					graph export "grph - comb - st all causes by race - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - st all causes by race - 95ci.emf"  , replace ;
				pause ;
			* state by ed ;
				grc1leg 
					"graph - st allc no_hs_dipl - 95ci"
					"graph - st allc hs_dipl_ged - 95ci" 
					"graph - st allc coll_wo_bach - 95ci" 
					"graph - st allc coll_w_bach - 95ci" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(2)
					/* imargin(0 0 0 0 0) */
					fxsize(95) 
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - st allc no_hs_dipl - 95ci") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - st all causes by ed - 95ci "    , replace ;
					graph export "grph - comb - st all causes by ed - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - st all causes by ed - 95ci.emf"  , replace ;
				pause ;
			* county by county ;
				grc1leg 
					"graph - cty allc Franklin - 95ci - covid diff"
					"graph - cty allc Cuyahoga - 95ci - covid diff"
					"graph - cty allc Hamilton - 95ci - covid diff"
					"graph - cty allc Summit - 95ci - covid diff"
					"graph - cty allc Montgomery - 95ci - covid diff"
					"graph - cty allc Lucas - 95ci - covid diff"
					"graph - cty allc Butler - 95ci - covid diff"
					"graph - cty allc Stark - 95ci - covid diff"
					"graph - cty allc Lorain - 95ci - covid diff"
					"graph - cty allc Mahoning - 95ci - covid diff" ,
					/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
					/* subtitle("Deviations from State and Year Means", size(small)) */
					rows(4)
					/* imargin(0 0 0 0 0) */
					/* fxsize(95) */
					fysize(100) 
					/* xcommon */ 
					legendfrom("graph - cty allc Cuyahoga - 95ci - covid diff") 
					position(6)
					ring(-1)
					span ;
					graph save   "grph - comb - cty all causes - 95ci "    , replace ;
					graph export "grph - comb - cty all causes - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
					graph export "grph - comb - cty all causes - 95ci.emf"  , replace ;
log close ;
end ;



 