clear
capture log close
display "This program was last run on $S_DATE at $S_TIME"
#delimit ;
log using "covid-19 ohio analyses - 03 - results - v9 .smcl", replace ;

* prep data ;
	* merge state-level data sets & save ;
		use "covid-19 ohio state all-cause analysis - actual & counter counts - v6 .dta", clear ;
		foreach X in "nat vs ext causes" "nat causes by gender" "nat causes by age (dash)" "nat causes by race"  
			{ ;
			gsort year_cal week_mmwr ;
			merge 1:1 year_cal week_mmwr using "xovid-19 ohio state `X' analysis - actual & counter counts - v7 .dta" ;
			drop _merge ;
			} ;
		* sort & save ;
			gsort year_cal week_mmwr ;
			tempfile state_level  ;
			save "`state_level'" ;
			clear ;
	* read in county-level data & limit to 10 largest ;
		use "covid-19 ohio county nat causes analysis - actual & counter counts - v7 .dta", clear ;
		keep if county == "Franklin" | county == "Cuyahoga" | county == "Hamilton" | county == "Summit" | county == "Montgomery" | county == "Lucas" | county == "Butler" | county == "Stark" | county == "Lorain" | county == "Mahoning" | county == "Marion" ;
		reshape wide cty_natc_actual cty_natc_p005 cty_natc_p025 cty_natc_p050 cty_natc_p500 cty_natc_p950 cty_natc_p975 cty_natc_p995 ,
			i(year_cal week_mmwr year_epi) j(county) string ;
		* revise var names ;
			foreach C in Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning Marion
				{ ;
				foreach T in actual p005 p025 p050 p500 p950 p975 p995 
					{ ;
					rename cty_natc_`T'`C' cty_natc_`C'_`T' ;
					} ;
				} ;
		* correct data download error ;
		* (for some reason, value for stark 2020 week 1 was not included in the initial download. i later obtained the value & added to the spreadsheet) ;
			replace cty_natc_Stark_actual = 44 if year_cal == "2020" & week_mmwr == 1 ;
		* sort & save ;
			gsort year_cal week_mmwr ;
			tempfile county_level  ;
			save "`county_level'" ;
			clear ;
	* merge state- & county-level data ;
		use "`state_level'" , replace ;
		merge 1:1 year_cal week_mmwr using "`county_level'" ;
		drop _merge ;
	* merge counts from ohio covid dashboard ;
		gsort year_cal week_mmwr ;
		merge 1:1 year_cal week_mmwr using "covid-19 ohio analysis - covid sample data - v1 .dta" ;
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
				natc extc 
				natc_female natc_male 
				natc_00_19 natc_20_29 natc_30_39 natc_40_49 natc_50_59 natc_60_69 natc_70_79 natc_80_99 
				natc_black natc_white
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
				egen cty_natc_`C'_cm12_actual = sum(cty_natc_`C'_actual) if week_mmwr >= 12 ;
				foreach X in 025 500 975
					{ ;
					egen cty_natc_`C'_cm12_p`X'    = sum(cty_natc_`C'_p`X')   if week_mmwr >= 12 ;
					gen  cty_natc_`C'_dif_p`X'     = cty_natc_`C'_actual - cty_natc_`C'_p`X' ;
					egen cty_natc_`C'_cdif12_p`X'  = sum(cty_natc_`C'_dif_p`X') if week_mmwr >= 12 ;
					} ;
				} ;
	* weekly differences btwn actual & covid counts ;
		* state level ;
			gen st_allc_dif_covid = st_allc_actual - st_covid_actual ;
			foreach Y in 
				"" 
				_female _male 
				_00_19 _20_29 _30_39 _40_49 _50_59 _60_69 _70_79 _80_99
				{ ;
				gen st_natc`Y'_dif_covid = st_natc`Y'_actual - st_covid`Y'_actual ;
				} ;
		* county level ;
			foreach C in Franklin Cuyahoga Hamilton Summit Montgomery Lucas Butler Stark Lorain Mahoning Marion
				{ ;
				gen cty_natc_`C'_dif_covid = cty_natc_`C'_actual - cty_covid_`C'_actual ;
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
				st_natc_cm12_actual 
				st_natc_cm12_p500 st_natc_cm12_p975 st_natc_cm12_p025 
				st_natc_cdif12_p500 st_natc_cdif12_p975 st_natc_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			tabstat 
				st_covid_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			foreach Y in 
				female male 
				00_19 20_29 30_39 40_49 50_59 60_69 70_79 80_99 
				{ ;
				display _newline(3) ;
				display as error "group: `Y'" ;
				tabstat 
					st_natc_`Y'_cm12_actual 
					st_natc_`Y'_cm12_p500 st_natc_`Y'_cm12_p975 st_natc_`Y'_cm12_p025 
					st_natc_`Y'_cdif12_p500 st_natc_`Y'_cdif12_p975 st_natc_`Y'_cdif12_p025 , stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				tabstat 
					st_covid_`Y'_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				} ;
		* actual vs counterfactual only (ie, no covid dashboard data available) ;
			foreach Y in 
				extc 
				natc_black natc_white 
				natc_doa natc_ed_out natc_home natc_hospice natc_inpatient natc_nhome_ltc
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
			tabstat 
				cty_natc_`C'_cm12_actual 
				cty_natc_`C'_cm12_p500 cty_natc_`C'_cm12_p975 cty_natc_`C'_cm12_p025 
				cty_natc_`C'_cdif12_p500 cty_natc_`C'_cdif12_p975 cty_natc_`C'_cdif12_p025 
				, stat(mean) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
				tabstat 
					cty_covid_`C'_actual if week_mmwr >= 12 , stat(sum) longstub format(%9.0fc) columns(statistics) varwidth(20) ;
			} ;
* graph results ;
	* graphing set-up ;
		pause off ;
		graph set window fontface "Times New Roman" ;
		set scheme s1color ;
	* actual w/ counterfactual 95% CI & (actual - # covid deaths) ;
		* prep individual graphs ;
			twoway
				rarea st_allc_p975 st_allc_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_allc_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_allc_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("All causes")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) ) 
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-2) )
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				/* legend(off) ; */
				legend(
					label(1 "Expected 95% CI")
					label(2 "Observed 2020 deaths")
					label(3 "Observed 2020 deaths less reported COVID-19 deaths")
					order(2 1 3) 
					cols(3)
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
				graph save   "graph - st allc - 95ci - covid diff "    , replace ;
				graph export "graph - st allc - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_p975 st_natc_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Natural causes")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) ) 
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0) )
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				/* legend(off) ; */
				plotregion(margin(tiny))
				legend(off) 
				;
				graph save   "graph - st natc - 95ci - covid diff "    , replace ;
				graph export "graph - st natc - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_extc_p975 st_extc_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_extc_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(orange_red) ,
				t1title("External causes")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) ) 
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-1.5) )
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				legend(off)
				plotregion(margin(tiny))
				graphregion(margin(l+2 /* r+10 */))
				; 
				graph save   "graph - st extc - 95ci "    , replace ;
				graph export "graph - st extc - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_female_p975 st_natc_female_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_female_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_female_dif_covid date_week_end             
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
				graph save   "graph - st natc female - 95ci - covid diff "    , replace ;
				graph export "graph - st natc female - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_male_p975 st_natc_male_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_male_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_male_dif_covid date_week_end             
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
				graph save   "graph - st natc male - 95ci - covid diff "    , replace ;
				graph export "graph - st natc male - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_00_19_p975 st_natc_00_19_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_00_19_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(red) ||
				line st_natc_00_19_dif_covid date_week_end             
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
				graph save   "graph - st natc 00_19 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 00_19 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_20_29_p975 st_natc_20_29_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_20_29_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_20_29_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("20-29 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st natc 20_29 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 20_29 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_30_39_p975 st_natc_30_39_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_30_39_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_30_39_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("30-39 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st natc 30_39 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 30_39 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_40_49_p975 st_natc_40_49_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_40_49_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_40_49_dif_covid date_week_end             
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
				graph save   "graph - st natc 40_49 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 40_49 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_50_59_p975 st_natc_50_59_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_50_59_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_50_59_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("50-59 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st natc 50_59 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 50_59 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_60_69_p975 st_natc_60_69_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_60_69_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_60_69_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("60-69 years old")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st natc 60_69 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 60_69 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_70_79_p975 st_natc_70_79_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_70_79_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_70_79_dif_covid date_week_end             
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
				graph save   "graph - st natc 70_79 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 70_79 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_80_99_p975 st_natc_80_99_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_80_99_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line st_natc_80_99_dif_covid date_week_end             
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
				graph save   "graph - st natc 80_99 - 95ci - covid diff "    , replace ;
				graph export "graph - st natc 80_99 - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_black_p975 st_natc_black_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_black_actual date_week_end             
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
				graph save   "graph - st natc black - 95ci "    , replace ;
				graph export "graph - st natc black - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea st_natc_white_p975 st_natc_white_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line st_natc_white_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ,
				t1title("Whites")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - st natc white - 95ci  "    , replace ;
				graph export "graph - st natc white - 95ci .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Franklin_p975 cty_natc_Franklin_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Franklin_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick)||
				line cty_natc_Franklin_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Franklin county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Franklin - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Franklin - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Cuyahoga_p975 cty_natc_Cuyahoga_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Cuyahoga_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Cuyahoga_dif_covid date_week_end             
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
				graph save   "graph - cty natc Cuyahoga - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Cuyahoga - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Hamilton_p975 cty_natc_Hamilton_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Hamilton_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Hamilton_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Hamilton county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Hamilton - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Hamilton - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Summit_p975 cty_natc_Summit_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Summit_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Summit_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Summit county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Summit - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Summit - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Montgomery_p975 cty_natc_Montgomery_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Montgomery_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Montgomery_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Montgomery county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Montgomery - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Montgomery - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Lucas_p975 cty_natc_Lucas_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Lucas_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Lucas_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Lucas county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Lucas - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Lucas - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Butler_p975 cty_natc_Butler_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Butler_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Butler_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Butler county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Butler - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Butler - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Stark_p975 cty_natc_Stark_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Stark_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Stark_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Stark county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Stark - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Stark - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Lorain_p975 cty_natc_Lorain_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Lorain_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick)||
				line cty_natc_Lorain_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Lorain county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #4 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Lorain - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Lorain - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Mahoning_p975 cty_natc_Mahoning_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Mahoning_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Mahoning_dif_covid date_week_end             
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
				graph save   "graph - cty natc Mahoning - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Mahoning - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
			pause ;
			twoway
				rarea cty_natc_Marion_p975 cty_natc_Marion_p025 date_week_end 			
					if week_mmwr > 1 , color(gs11) ||
				line cty_natc_Marion_actual date_week_end             
					if week_mmwr > 1 , lwidth(thick) ||
				line cty_natc_Marion_dif_covid date_week_end             
					if week_mmwr > 1 , lwidth(thick) lcolor(blue) ,
				t1title("Marion county")
				xtitle("")
				xlabel( 21939(35)22044 , axis(1) angle(horizontal) format(%tdMon_DD) labsize(small) )
				ytitle( "Number of deaths" , /*size(small)*/  axis(1) orientation(vertical) xoffset(-0))
				yscale(r(0))
				ylabel( #5 , axis(1) angle(horizontal) format(%9.0fc) labsize(small) ) 
				plotregion(margin(tiny))
				legend(off) ;
				graph save   "graph - cty natc Marion - 95ci - covid diff "    , replace ;
				graph export "graph - cty natc Marion - 95ci - covid diff .eps"  , replace preview(on) fontface("Times New Roman") ;
	* combine graphs ;
		* state all & nat causes ;
			grc1leg 
				"graph - st allc - 95ci - covid diff"
				"graph - st natc - 95ci - covid diff" 
				"graph - st extc - 95ci" ,
				/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
				/* subtitle("Deviations from State and Year Means", size(small)) */
				rows(1)
				/* imargin(0 0 0 0 0) */
				fysize(50) 
				/* xcommon */ 
				legendfrom("graph - st allc - 95ci - covid diff") 
				position(6)
				ring(-1)
				span ;
				graph save   "grph - comb - st all, nat, & ext causes - 95ci"    , replace ;
				graph export "grph - comb - st all, nat, & ext causes - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
				graph export "grph - comb - st all, nat, & ext causes - 95ci.emf", replace ;
			pause ;
		* state nat causes by gender ;
			grc1leg 
				"graph - st natc female - 95ci - covid diff"
				"graph - st natc male - 95ci - covid diff" ,
				/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
				/* subtitle("Deviations from State and Year Means", size(small)) */
				rows(1)
				/* imargin(0 0 0 0 0) */
				fxsize(95) 
				fysize(50) 
				/* xcommon */ 
				legendfrom("graph - st natc female - 95ci - covid diff") 
				position(6)
				ring(-1)
				span ;
				graph save   "grph - comb - st nat causes by gend - 95ci "    , replace ;
				graph export "grph - comb - st nat causes by gend - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
				graph export "grph - comb - st nat causes by gend - 95ci.emf", replace ;
			pause ;
		* state nat causes by age ;
			grc1leg 
				"graph - st natc 00_19 - 95ci - covid diff"
				"graph - st natc 20_29 - 95ci - covid diff"
				"graph - st natc 30_39 - 95ci - covid diff"
				"graph - st natc 40_49 - 95ci - covid diff"
				"graph - st natc 50_59 - 95ci - covid diff"
				"graph - st natc 60_69 - 95ci - covid diff"
				"graph - st natc 70_79 - 95ci - covid diff"
				"graph - st natc 80_99 - 95ci - covid diff" ,
				/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
				/* subtitle("Deviations from State and Year Means", size(small)) */
				rows(3)
				/* imargin(0 0 0 0 0) */
				/* fxsize(95) */
				fysize(100) 
				/* xcommon */ 
				legendfrom("graph - st natc 00_19 - 95ci - covid diff") 
				position(6)
				ring(-1)
				span ;
				graph save   "grph - comb - st nat causes by age - 95ci "    , replace ;
				graph export "grph - comb - st nat causes by age - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
				graph export "grph - comb - st nat causes by age - 95ci.emf"  , replace ;
			pause ;
		* state nat causes by race ;
			grc1leg 
				"graph - st natc black - 95ci"
				"graph - st natc white - 95ci" ,
				/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
				/* subtitle("Deviations from State and Year Means", size(small)) */
				rows(1)
				/* imargin(0 0 0 0 0) */
				fxsize(95) 
				fysize(50) 
				/* xcommon */ 
				legendfrom("graph - st natc black - 95ci") 
				position(6)
				ring(-1)
				span ;
				graph save   "grph - comb - st nat causes by race - 95ci "    , replace ;
				graph export "grph - comb - st nat causes by race - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
				graph export "grph - comb - st nat causes by race - 95ci.emf"  , replace ;
			pause ;
		* county nat causes by county ;
			grc1leg 
				"graph - cty natc Franklin - 95ci - covid diff"
				"graph - cty natc Cuyahoga - 95ci - covid diff"
				"graph - cty natc Hamilton - 95ci - covid diff"
				"graph - cty natc Summit - 95ci - covid diff"
				"graph - cty natc Montgomery - 95ci - covid diff"
				"graph - cty natc Lucas - 95ci - covid diff"
				"graph - cty natc Butler - 95ci - covid diff"
				"graph - cty natc Stark - 95ci - covid diff"
				"graph - cty natc Lorain - 95ci - covid diff"
				"graph - cty natc Mahoning - 95ci - covid diff" ,
				/* title("Incidence Rates (Ages 65+) and GDP Per Capita", size(small) ) */
				/* subtitle("Deviations from State and Year Means", size(small)) */
				rows(4)
				/* imargin(0 0 0 0 0) */
				/* fxsize(95) */
				fysize(100) 
				/* xcommon */ 
				legendfrom("graph - cty natc Cuyahoga - 95ci - covid diff") 
				position(6)
				ring(-1)
				span ;
				graph save   "grph - comb - cty nat causes - 95ci "    , replace ;
				graph export "grph - comb - cty nat causes - 95ci.eps"  , replace preview(on) fontface("Times New Roman") ;
				graph export "grph - comb - cty nat causes - 95ci.emf"  , replace ;
log close ;
end ;



 