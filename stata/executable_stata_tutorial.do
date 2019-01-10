/*********************
Stata Tutorial

This tutorial provides a overview of Stata's basic functionality
This is an executable Stata file; run it in Stata to better understand what it does
*/

/*********************
Use Stata for:
- data manipulation
- data analysis
- graphing
- tables out to excel or latex
*/

/*********************
In this tutorial:
- Basics: import data, browse dataset, create variables
- Dates: create date variables, create lead and lag variables
- Loops and ÒMacrosÓ: execute commands over a set of inputs, ÒbyÓ groups
- Merge/Append: merge and append data from multiple datasets
- regression: basic syntax, lead/lag variables, storing regression output
- Tables to Latex: 
- Graphing: 
*/

/*********************
Properties of Stata:
- only one dataset in memory at a time
- (almost) everything you do will be represented as a column "variable" in the dataset
- variables cannot be overwritten; you must "drop" them before re-creating them
- numeric missing values are denoted by . which is the largest number Stata can hold
- character missing values are denoted by ""
- "if" statements evaluate to 1 if true, and 0 if false
*/

/*********************
Basic Syntax:
[by varlist:] command [arguments] [if] [in] [, options]

- [brackets] indicate that the syntax is optional
*/

/*********************
Finding help:
- type "help [command name]" at the stata prompt
- alternatively, google "stata [command name]"
- Help file layout:
	syntax
	options
	option descriptions
	examples
	stored values
*/

/*********************
.ado files
- stata equivalent to packages
- to install, type "ssc install [.ado file name]" at the stata prompt
- ex: ssc install listtex
- once installed, these commands can be used like any other command
*/

/*********************
Miscellaneous
- to open GUI Stata from the command line, type "xstata" in the terminal
- to run a shell command from stata, type "! [command]"
- to continue a command on a second line, type "///" at the end of the first line
- to run a single command or group of commands from the do-file editor:
	highlight the commands
	Mac: command-shift-d; Windows/Linux: control-d
*/

/*********************
Editorializing
- give your saved datasets the same name as the do-file that created them
- if you are using lots of loops, you are doing something wrong
- keep variable names short and informative
- when creating new variables, indicate relationships to other variables with names
- ex: the varible "height_max" could store the maximum value of "height"
*/



/***************************/
/*  Basics                 */
/***************************/

//remove all datasets, matrices, etc. from memory
clear all
//do not wait for user input after printing the first page of output
set more off

/*********************/
//import files
//more examples in oecd.do
//import .dta file (Stata file type)
use oecd_panel.dta, clear

//additional examples 

//import .csv file
//insheet using oecd_panel.csv, comma names clear
//see more here: http://www.stata.com/help.cgi?insheet

//import .xlsx file
//import excel using oecd_panel.xlsx, sheet("Sheet1") firstrow clear
//see more here: http://www.stata.com/manuals13/dimportexcel.pdf


/*********************/
//view dataset
//observe changes to the dataset in the browse window after running each command 
browse  

//red columns are strings
//black columns are numbers (or dates!)
//blue columns are "encoded" variables; values in blue are not the actual values

tab country
browse if country == "Argentina"
//"if" statements evaluate to 1 if true, and 0 if false
gen argentina_dummy = (country == "Argentina")

//remove all observations from Belgium from the dataset
drop if country == "Belgium"
//remove argentina_dummy from the dataset
drop argentina_dummy

/*********************/
//counting and missing values
//count the number of observations in the dataset
count
//count the number of "country" observations with non-missing values
count if country != ""
//count the number of observations for Argentina
count if country == "Argentina"
//be careful - stata will count missing values as greater than 1000000
count if chg_invtr > 1000000
//exclude the missing values
count if chg_invtr > 1000000 & chg_invtr != .


/*********************/
//creating variables

//create a dummy variable for each country (c1, c2, etc.)
tabulate country, gen(c)

//create a new variable
gen double date = year + quarter/10
//the special variable "_n" takes a value of 1 in the first row, 2 in the 2nd row, etc.
gen counter = _n
//the special variable "_N" denotes the number of observations
gen num_obs = _N
//variables cannot be overwritten; use "replace"
replace counter = counter - 1
//replace the value of a variable in a specific row(s)
replace counter = -5 in 2
replace counter = -6 in 4/10


/*********************/
//panel data

//create a variable containing an id number for each 
sort country date
//"id" has value 1 in the first observation for every country and zero otherwise
by country: gen id = (_n == 1)
//sum the current observation of "id" with the previous observation
//this yields a unique "id" value for each country
//this is an example of looping functionality without explicitly writing a loop
replace id = id + id[_n-1] if _n != 1

//"cross-tabulate" country names and id numbers
//ex: this shows 12 observations for Australia, all with id 2
tab country id if inlist(country, "Argentina", "Australia", "Austria")


//sort the data by country (ascending), and within country sort by date (ascending)
sort country date
//sort the data by country (ascending), and within country sort by date (descending)
gsort country -date
//"by [varlist]" can only be used when the data is sorted by [varlist]
//find the number of observations for each country
by country: gen country_obs = _N
tab country_obs

/*********************/
//lead and lag variables

//create gdp lagged one time period
//this command does not account for the panel structure of the dataset
//the first value of gdp_1 for Austria is the last value of gdp for Australia
sort country date
gen gdp_1 = gdp[_n-1]
//browse the dataset to see the problem
browse country gdp gdp_1
drop gdp_1

//to fix this problem, re-generate the variable by country
by country: gen gdp_1 = gdp[_n-1]
//browse the dataset to be sure the problem no longer exists
browse country gdp gdp_1
//this is still not perfect - missing values will cause problems
//ex: suppose Argentina is missing its 2012 Q2 value for gdp
//a one-observation lag will record the value from 2012 Q1 as the lagged value for 2012 Q3.  
//create correct lagged values by using dates
drop gdp_1

//miscellaneous panel data examples

//egen commands are user generated commands
//in practice they work just like the "gen" command
//list of egen commands (including mean, min, max, sum, sd, rowtotal, etc.)
//http://econweb.tamu.edu/jnighohossian/tools/stata/egen.htm

//note: there is a difference between "gen var_sum = sum()" and "egen var_sum = sum()"
//create a variable that is the running sum of the "id" variable
by country: gen id_gen_sum = sum(id)
//create a variable that sums the id variable by country
by country: egen id_egen_sum = sum(id)
//sum all rows with names beginning in "id_"
egen id_rowtotal = rowtotal(id_*)



/***************************/
/*  Dates                  */
/***************************/

drop time
//the number of months since Q1, 1960
gen time = yq(year, quarter)
//MMDDYYYY dates are expressed as the number of days since 1960.

//to let Stata treat observations as temporally related, use "tsset"
sort id time
tsset id time
//the command "tsset clear" will remove the current tsset settings

//with tsset, we can construct correct leads and lags
//create gdp correctly lagged one time period
gen gdp_1 = L.gdp
//create gdp from two quarters in the future
gen gdp_f2 = F2.gdp

//create changes in gdp
gen dgdp = gdp - L.gdp
gen Dgdp = D.gdp



/***************************/
/*  Loops and "Macros"     */
/***************************/

local i = 0
while `i' < 5 {
	local i = `i' + 1
	display `i'
}

forvalues i =0(2)10 {
	display `i'
}

foreach num of numlist 1 8 7 6 {
	display `num'
}	
	
foreach var of varlist chg_invtr exp_gds exp_gds_svc exp_svc cons_expnd ///
                       gross_cap_fmtn gdp imp_gds imp_gds_svc imp_svc {
    //displays the variable name (string)
    display "`var'"
    //creates one and two period lags for each variable
	gen `var'_l1 = L.`var'
	gen `var'_l2 = L2.`var'
}



/***************************/
/*  Merge/Append/Joinby    */
/***************************/

//the current dataset is called "master"
//the dataset to be merged in is called "using"

//m:1 is "many to one" 
//each date exists for many countries in "master"; dates in "using" are unique
merge m:1 year quarter using ten_year_treasury.dta
//each merge command creates a "_merge" variable that :
//_merge == 1: master only
//_merge == 2: using only
//_merge == 3: merged
keep if _merge == 3

/*
notes on m:1, 1:m, m:m and joinby

merge m:1 id using using.dta
master		using		merge
id	data1	id	data2	id	data1	data2
1	A		1	Z		1	A		Z
1	B		2	Y		1	B		Z
1	B		3	X		1	B		Z
2	B					2	B		Y
2	C					2	C		Y
						3			X

merge 1:m id using using.dta
master		using		merge
id	data1	id	data2	id	data1	data2
1	Z		1	A		1	Z		A		
2	Y		1	B		1	Z		B		
3	X		1	B		1	Z		B		
			2	B		2	Y		B		
			2	C		2	Y		C		
						3	X

merge m:m id using using.dta
master       using       merge
id data1     id data2    id data1 data2
1  3         1  7        1  3     7 
1  4         1  8        1  4     8
1  5         2 10        1  5     .
2  2         2  6        2  2     10
2  1                     2  1     6

joinby id using using.dta
master       using       merge
id data1     id data2    id data1 data2
1  3         1  7        1  3     7 
1  4         1  8        1  3     8
1  5         2 10        1  4     7
2  2         2  6        1  4     8
2  1                     1  5     7
						 1  5     8
						 2  2     10
						 2  2     6
						 2  1     10
						 2  1     6
*/ 



/***************************/
/*  Regression             */
/***************************/

//before regressing on tsset lagged variables, the dataset must be sorted
sort id time

//regress dependent_var indep_var_1 indep_var_2 indep_var_3
regress gdp L.gross_cap_fmtn L.imp_gds_svc L.exp_gds_svc

//automatically create dummies for each country id
areg gdp L.gross_cap_fmtn L.imp_gds_svc L.exp_gds_svc, absorb(id)

//create quarter and year dummies from the quarter and year variables
xi: areg gdp L.gross_cap_fmtn L.imp_gds_svc L.exp_gds_svc i.quarter i.year, absorb(id)

//this is the same as the previous regression, but storing regressors in a local variable
local controls = "L.imp_gds_svc L.exp_gds_svc i.quarter i.year"
areg gdp L.gross_cap_fmtn `controls', absorb(id)

//look at the bottom of "help regress" to see stored values
//retrieve coefficents and variance/covariance matrix:
matrix b = e(b)
matrix v = e(V)

//display a matrix
mat list b
//display an element of a matrix
di v[2,1]


//store outreg options related to regression table formatting
//
local outreg_options = "nor2 coefast se nolabel bracket"

//Regression for all countries
areg gdp L.gross_cap_fmtn `controls', absorb(id)
outreg2 using table1.xls, `outreg_options' addstat("R-squared", e(r2)) replace

//Regression for Argentina
areg gdp L.gross_cap_fmtn `controls' if id == 1, absorb(id)
outreg2 using table1.xls, `outreg_options' addstat("R-squared", e(r2)) append



/***************************/
/*  Graphing               */
/***************************/

//store the first coefficient from the last regression
local coefficient = b[1,1]
//set the width and height of the saved graph
//notice that the width() and height() commands come after the comma
//this indicates that they are optional commands.  
//without them, Stata would create a graph using a default width and height
local pngwidth = 800
local pngheight = 600

//the line beginning with "graphregion..." makes the graph background white and removes the border from the legend
twoway 	(line gdp time, lcolor(red) lpattern(dash)) ///
		(line gdp_1 time, lcolor(blue) lpattern(dotdash)) if country == "Argentina", ///
		title("This is a graph, and this is a Coefficient: `coefficient'") ///
		xtitle("Date") ytitle("GDP") ///
		graphregion(fcolor(white) lcolor(white) color(white)) legend(region(lcolor(white)))

//the "replace" option will replace an existing "graph.png" file with the current file
graph export graph.png, replace width(`pngwidth') height(`pngheight')

//display the graph in a pdf created in latex
//to do this, create a text file in stata containing the lines needed in a latex file:
//the "_n" at the end of each line includes a "newline" character in the file

file open f1 using "graph.tex", write replace
file write f1 "\documentclass[10pt]{article}" _n
file write f1 "\usepackage{graphicx}" _n
file write f1 "\usepackage[margin=1in]{geometry}" _n
file write f1 "\usepackage[labelformat=empty]{caption}" _n
file write f1 "\newcommand{\fullscale}{.33}" _n
file write f1 "\begin{document}" _n
file write f1 "\clearpage" _n
file write f1 "\begin{figure}" _n
file write f1 "\begin{center}" _n
file write f1 "Figure 1: What a figure!\\" _n
file write f1 "\includegraphics[scale=\fullscale]{graph.png}" _n
file write f1 "\end{center}" _n
file write f1 "\caption{Notes: Write your notes here.}" _n
file write f1 "\end{figure}" _n
file write f1 "\end{document}" _n 
file close f1


//compile the graph file in latex
! pdflatex graph.tex
//remove the obnoxious auxiliary files created when compiling latex
! rm graph.aux graph.log


/***************************/
/*  Tables to Latex        */
/***************************/

//export stored regression results 

//labels on variables in the regression will be included in the table
label variable gdp "Gross Domestic Product"
label variable gross_cap_fmtn "Gross Capital Formation"
label variable imp_gds_svc "Imports of Goods and Services"
label variable exp_gds_svc "Exports of Goods and Services"

//run regressions, and store results using "eststo"
xi: areg gdp gross_cap_fmtn i.quarter i.year, absorb(id)
eststo table_column_1
xi: areg gdp gross_cap_fmtn imp_gds_svc exp_gds_svc i.quarter i.year, absorb(id)eststo table_column_2

//export the table of regressions to latex
local notes_1 = "Put some notes here."
local notes_2 = "Include more notes here if you would like."  
local significance = "  \\  Significance: * significant at 10\%; ** significant at 5\%; *** significant at 1\%."
//include all objects in "eststo" with names beginning in "table_column_"
esttab table_column_*  ///
using gdp_table.tex, replace  ///
star(* 0.10 ** 0.05 *** 0.01) /*plain*/ nogaps   ///
nodepvars b(%9.3f) legend noabbrev style(tex) constant   ///
title("Table 1: Two Nonsensical Regressions")   ///
label stats(N r2_a, fmt(%9.0g %9.3g) labels("Observations" "Adjusted R-Squared")) se  ///
order(gross_cap_fmtn imp_gds_svc exp_gds_svc /*_cons*/)    ///
keep( gross_cap_fmtn imp_gds_svc exp_gds_svc /*_cons*/)     ///
nomtitles  ///
posthead("Dependent Variable & GDP & GDP  \\"  ///
		"\hline")  ///
prefoot("\hline" ///
		"Country FEs  & Yes & Yes \\"  ///
		"\hline"  ///
		"Sample       & Full & Full \\"  /// 
		"\hline")  ///
nonotes ///
postfoot(	"\hline\hline" ///
			"\end{tabular}}"  ///
			"\captionsetup{justification=justified}"  ///
			"\caption{Notes: `notes_1' `notes_2' `significance' }"  ///
			"\end{table}")  ///
substitute(	\begin{table}[htbp]\centering \begin{table}[p]\centering\captionsetup{width=0.8\textwidth}\footnotesize{ )

//create latex file to "wrap" around the gdp table output
file open f1 using "gdp_table_wrapper.tex", write replace
file write f1 "\documentclass[10pt]{article}" _n
file write f1 "\usepackage[margin=1in]{geometry}" _n
file write f1 "\usepackage[labelformat=empty]{caption}" _n
file write f1 "\begin{document}" _n
file write f1 "\clearpage" _n
file write f1 "\input{gdp_table.tex}" _n 
file write f1 "\end{document}" _n 
file close f1

//compile the GDP table in latex
! pdflatex gdp_table_wrapper.tex
//remove the obnoxious auxiliary files created when compiling latex
! rm gdp_table_wrapper.aux gdp_table_wrapper.log



//export a (nicely formatted) table from the dataset
//to do this, create a latex (.tex) file within Stata by using the 
//to export a portion of the dataset as a nicely formatted table, we will create 

//install listtex if you haven't already
ssc install listtex

listtex country year quarter gdp if country == "Argentina" using argentina_table.tex, replace rstyle(tabular)  ///
		head(	"\documentclass[10pt]{article}"  ///
				"\usepackage[margin=1in]{geometry}"  ///
				"\usepackage[labelformat=empty]{caption}"  ///
				"\begin{document}"  ///
				"\begin{table}[htbp]\centering\captionsetup{width=0.8\textwidth}\footnotesize{"  ///
				"\caption{Table 2: Argentina}"  ///
				"\begin{tabular}{l l l  r }"  ///
				"\hline\hline"  ///
				"Country     & Year & Quarter & GDP \\"  ///
				"\hline")  ///
		foot(	"\hline"  ///
				"\end{tabular}}"  ///
				"\caption{Notes: Write your notes here.}"  ///
				"\end{table}"  ///
				"\end{document}")

//compile the latex file created by listtex
! pdflatex argentina_table.tex
//remove the obnoxious auxiliary files created when compiling latex
! rm argentina_table.log argentina_table.aux



















