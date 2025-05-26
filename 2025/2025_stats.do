/*==============================================================================
IBES Data Analysis: Count Observations by Year and Currency Code
==============================================================================*/

* Clear memory and set options
clear all
set more off

global mypath "/Users/kawabatahatsu/ibes-japan/ibes-japan/IBES/Both"
global mypath "/Users/tsenga/ibes-japan/ibes-japan/IBES/Both"
use $mypath/merged_data.dta, clear


* Check the data structure first
describe sym eym ACTUAL TICKER, fullnames
summarize sym eym in 1/10
list sym eym ACTUAL TICKER in 1/5

* --- Data Preparation ---

* Ensure CURCODE is string if it's not already (IBES sometimes has it as numeric)
* If CURCODE is numeric, you might need to convert it or use labels.
* For this example, we assume CURCODE is a string variable.
* If it's numeric with labels, you might want to decode it first:
* decode CURCODE, gen(CURCODE_str) // Example if CURCODE is numeric with labels

* Extract Year from 'sym' variable
* 'sym' is stored as float (e.g., 201404 for YYYYMM)
* Based on describe output, 'sym' is float %tm, which is a Stata monthly date.
* We can directly use date functions.
gen year = yofd(dofm(sym)) // Extracts year from Stata monthly date
label var year "Observation Year (from sym)"

* --- Counting Observations ---

* Create indicator variables for non-missing values
* Based on `describe` output:
* STDEV is double (numeric) - missing is .
* ACTUAL is double (numeric) - missing is .
* TICKER is str6 (string) - missing is ""
gen has_stdev = (STDEV != .)     // Check for non-missing numeric for STDEV
gen has_actual = (ACTUAL != .)   // Check for non-missing numeric for ACTUAL
gen has_ticker = (TICKER != "")  // Check for non-empty string for TICKER

* Collapse the data to get counts by year and CURCODE
preserve
collapse (sum) STDEV_Count=has_stdev ACTUAL_Count=has_actual TICKER_Count=has_ticker, by(year CURCODE)

* --- Displaying the Results ---

* List the results in a clean table format
display ""
display "Summary Table: Observation Counts by Year and Currency Code"
display "------------------------------------------------------------------"
list year CURCODE STDEV_Count ACTUAL_Count TICKER_Count, separator(0) abbreviate(20)

* You can also export this table to a file (e.g., CSV, Excel)
* Example for CSV:
* export delimited year CURCODE STDEV_Count ACTUAL_Count TICKER_Count using "ibes_summary_counts.csv", replace

* Example for Excel (requires user-written command `export excel` or similar):
* export excel year CURCODE STDEV_Count ACTUAL_Count TICKER_Count using "ibes_summary_counts.xlsx", sheet("Summary") firstrow(variables) replace

restore

* End of do-file
display ""
display "Do-file execution completed."
