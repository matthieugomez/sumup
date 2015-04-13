program sumup, rclass 
version 12.1
syntax [varlist(default=none)] [if] [in] [aweight fweight pweight] [, Detail by(varlist) Output(str) replace Statistics(str)  seps(numlist) /*
*/     CASEwise Format Format2(str) /*
*/      LAbelwidth(int -1) VArwidth(int -1)  Missing /*
*/      SAME SAVE noSEParator noTotal septable(string)]


if ("`weight'"!="") local wt [`weight'`exp']

if "`varlist'" == ""{
    local varlist `: word 1 of `by''
    local statistics n
}

if "`statistics'" == ""{		
    if "`detail'" == ""{
        local statistics  n missing  mean sd min max 
    }
    else{
        local statistics n missing  mean sd skewness kurtosis  min p1 p5 p10 p25 p50 p50 p75 p90 p95 p99 max
        local seps 6 12
        local columns statistics
    }
}    

if "`casewise'" != "" {
    local same same
}

if `"`stats'"' != "" {
    if `"`statistics'"' != "" {
        di as err /*
        */ "may not specify both statistics() and stats() options"
        exit 198
    }
    local statistics `"`stats'"'
    local stats
}

if "`total'" != "" & "`by'" == "" {
    di as txt "nothing to display"
    exit 0
}

if "`format'" != "" & `"`format2'"' != "" {
    di as err "may not specify both format and format()"
    exit 198
}
if `"`format2'"' != "" {
    capt local tmp : display `format2' 1
    if _rc {
        di as err `"invalid %fmt in format(): `format2'"'
        exit 120
    }
}

local incol "statistics"


if `varwidth' == -1 {
    local varwidth 12
}
else if !inrange(`varwidth',8,16) {
    local varwidth = clip(`varwidth',8,16)
    dis as txt ///
    "(option varwidth() outside valid range 8..16; `varwidth' assumed)"
}

if `labelwidth' == -1 {
    local labelwidth 16
}
else if !inrange(`labelwidth',8,32) {
    local labelwidth = clip(`labelwidth',8,32)
    dis as txt ///
    "(option labelwidth() outside valid range 8..32; `labelwidth' assumed)"
}

* sample selection

marksample touse, novar
if "`same'" != "" {
    markout `touse' `varlist'
}
if "`by'" != "" & "`missing'" == "" {
    markout `touse' `by' , strok
}
qui count if `touse'
local samplesize=r(N)
if `samplesize' == 0 {
    error 2000
}
if `"`weight'"' != "" {
    local wght `"[`weight'`exp']"'
}

// varlist -> var1, var2, ... variables
//            fmt1, fmt2, ... display formats

tokenize "`varlist'"
local nvars : word count `varlist'
forvalues i = 1/`nvars' {
    local var`i' ``i''
    if "`format'" != "" {
        local fmt`i' : format ``i''
    }
    else if `"`format2'"' != "" {
        local fmt`i' `format2'
    }
    else if "`name`i''" == "missing"{
        local fmt`i' %4.0g
    }
    else{
        local fmt`i' %9.0g
    }
}



if `nvars' == 1 & `"`columns'"' == "" {
    local incol statistics
}

* Statistics

Stats2 `statistics'
local stats   `r(names)'
local titlestats   `r(titlenames)'
local expr    `r(expr)'
local cmd    `r(cmd)'
local summopt `r(summopt)'
local pctileopt `r(pctileopt)'
local nstats : word count `stats'

tokenize `expr'
forvalues i = 1/`nstats' {
    local expr`i' ``i''
}
tokenize `cmd'
forvalues i = 1/`nstats' {
    local cmd`i' ``i''
}
tokenize `stats'
forvalues i = 1/`nstats' {
    local name`i' ``i''
    local names "`names' ``i''"
    if `i' < `nstats' {
        local names "`names',"
    }
}
tokenize `titlestats'
forvalues i = 1/`nstats' {
    local titlename`i' ``i''
    local titlenames "`titlenames' ``i''"
    if `i' < `nstats' {
        local titlenames "`titlenames',"
    }
}


if "`separator'" == "" & ( (`nstats' > 1 & "`incol'" == "variables") /*
    */         |(`nvars' > 1  & "`incol'" == "statistics")) {
    local sepline yes
}

local matsize : set matsize
local matreq = max(`nstats',`nvars')
if `matsize' < `matreq' {
    di as err /*
    */ "set matsize to at least `matreq' (see help matsize for details)"
    exit 908
}

if "`output'" ~= ""{
    if !regexm("`output'", "dta"){
        local output `output'.dta
    }

    cap confirm new file `"`output'"'
    if _rc ~= 0 & "`replace'" == ""{
        di as error  `"file `output' already exists. Specify option replace"'
        exit
    }
    else{
        tempfile outputname
        tempname postname
        foreach b in `by' {
            local postvars `postvars' `b'
        }

        if `nvars' == 1{
            forvalues is = 1/`nstats'{
                local postvars `postvars' `name`is''
            }
        }
        else{
            forvalues i = 1/`nvars' {
                forvalues is = 1/`nstats'{
                    local postvars `postvars' `var`i''_`name`is''
                }
            }
        }
        qui postfile `postname' `postvars' using `outputname'
    }
}
* compute the statistics
* ----------------------

if "`by'" != "" {

    local touse_first=_N-`samplesize'+1
    local touse_last=_N

    tempvar bylength
    bys `touse' `by' : gen `bylength' = _N 



    local byn : word count `by'

    local ib 0
    local maxlength 0
    foreach b in `by'{
        local ++ib
        local bytype`ib': type `b'
        local for`ib': format `b'
        local maxlength`ib' 0
    }


    tempname M
    /* get back to original */
    local iby = 0
    local start = `touse_first'
    while `start' < `touse_last'{
        local end = `start' + `=`bylength'[`start']' - 1
        local iby = `iby' + 1
        tempname Stat`iby'
        mat `Stat`iby'' = J(`nstats',`nvars',0)
        mat colnames `Stat`iby'' = `varlist'
        mat rownames `Stat`iby'' = `stats'


        * save label for groups in lab1, lab2 etc
        local ib 0
        tempname Mrow
        matrix `Mrow' = J(1, `byn', 0)
        foreach b in `by' {
            local ++ib
            cap matrix `Mrow'[1, `ib'] = `=`b'[`start']'
            local lab`iby'`ib' `: label (`b') `=`b'[`start']''
            local maxlength`ib' = max(strlen(`"`lab`iby'`ib''"'),`maxlength`ib'')
        }
        if `iby' == 1{
            cap matrix `M' = `Mrow'
        }
        else{
            cap matrix `M' = (`M' \ `Mrow')
        }
        * loop over all variables
        forvalues i = 1/`nvars' {
            if regexm("`cmd'", "sum") {
                qui summ `var`i'' in `start'/`end' `wght', `summopt'
                forvalues is = 1/`nstats' {
                    if "`cmd`is''" == "sum"{
                        if "`name`is''"== "freq"{
                            mat `Stat`iby''[`is',`i'] = `end' - `start' +1
                        }
                        else if  "`name`is''"== "missing"{
                            mat `Stat`iby''[`is',`i'] = `end' - `start' + 1 - `expr`is''
                        }
                        else{
                            mat `Stat`iby''[`is',`i'] = `expr`is''
                        }
                    }
                }
            }
            if "`pctileopt'" ~= ""{
                qui _pctile `var`i'' in `start'/`end' `wght', p(`pctileopt')
                forvalues is = 1/`nstats' {
                    if "`cmd`is''" == "pctile"{
                        mat `Stat`iby''[`is',`i'] = `expr`is''
                    }
                }
            }
        }   

        if "`output'"~=""{
            local bypost ""
            foreach b in `by'{
                local bypost `bypost' (`=`b'[`start']')
            }
            local statpost ""
            forvalues i = 1/`nvars' {
                forvalues is = 1/`nstats'{
                    local statpost `statpost' (`=`Stat`iby''[`is',`i']')
                }
            }
            post `postname' `bypost' `statpost'
        }
        local start = `end' + 1

    }
    local nby `iby'

}
else {
    local nby 0
}


if "`total'" == "" {
    * unconditional (Total) statistics are stored in Stat`nby+1'
    local iby = `nby'+1

    tempname Stat`iby'
    mat `Stat`iby'' = J(`nstats',`nvars',0)
    mat colnames `Stat`iby'' = `varlist'
    mat rownames `Stat`iby'' = `stats'

    if "`by'" ~= ""{
        local condition in `touse_first'/`touse_last'
    }
    else{
        local condition if `touse'==1
    }

    forvalues i = 1/`nvars' {
        if regexm("`cmd'", "sum") {
            qui summ `var`i''  `wght' `condition', `summopt'
            forvalues is = 1/`nstats' {
                if "`cmd`is''" == "sum"{
                    if "`name`is''"== "freq"{
                        mat `Stat`iby''[`is',`i'] = _N
                    }
                    else if  "`name`is''"== "missing"{
                        mat `Stat`iby''[`is',`i'] = _N - `expr`is''
                    }
                    else{
                        mat `Stat`iby''[`is',`i'] = `expr`is''
                    }
                }
            }
        }
        if "`pctileopt'" ~= ""{
            qui _pctile `var`i'' `wght' `condition', p(`pctileopt')
            forvalues is = 1/`nstats' {
                if "`cmd`is''" == "pctile"{
                    mat `Stat`iby''[`is',`i'] = `expr`is''
                }
            }
        }
    }
    local ib = 0
    foreach b in `by'{
        local lab`iby'`ib' "Total"
    }
}

if "`output'"~= ""{
    postclose `postname'
    copy `outputname' `output', `replace'
    display "file `output' written"
}

* constants for displaying results
* --------------------------------

if "`by'" != "" {
    local ib = 0
    foreach b in `by'{
        local ++ib
        if substr("`bytype`ib''",1,3) != "str" {
            local byw`ib' = min(floor((`labelwidth'+1)/`byn')-1,`maxlength`ib'')
        }
        else {
            local byw`ib'=min(real(substr("`bytype`ib''",4,.)),floor((`labelwidth'+1)/`byn')-1)
            local bytype`ib' str
        }
        
        capture local if_date_for`ib' = substr("`for`ib''", index("`for`ib''", "%"), index("`for`ib''", "d"))
        capture local if_time_for`ib' = substr("`for`ib''", index("`for`ib''", "%"), index("`for`ib''", "t"))
        if "`if_date_for`ib''" == "%d" | "`if_time_for`ib''" == "%t" {
            if "`if_date_for`ib''" == "%d" {
                local has_M = index("`for`ib''", "M")
                local has_L = index("`for`ib''", "L")
                if `has_M' > 0 | `has_L' > 0 {
                    local byw`ib' = 18
                }
                else {
                    local byw`ib' = 11
                }
            }
            else {
                local byw`ib' = 9
            }
        }
        else {
            local byw`ib' = max(length("`b'"), `byw`ib'')
        }
        if "`total'" == "" {
            local byw`ib' = max(`byw`ib'', 6)
        }
    }
    local bw 0
    local ib 0
    foreach b in `by'{
        local ++ib
        local byw = `byw' + `byw`ib'' + 1
    }
}
else {
    local byw 9
}
* number of chars in display format
local ndigit  9
local colwidth = `ndigit'+2

if "`incol'" == "statistics" {
    local lleft = `byw' *("`by'"!="") + ///
    (`varwidth'+1)*("`descr'"!="")
}
else {
    local lleft = `byw'*("`by'"!="") + (8+1)*("`descr'"!="")
}

local cbar  = `lleft' + 1

local lsize = c(linesize)
* number of non-label elements in the row of a block
local neblock = int((`lsize' - `cbar')/10)
* number of blocks if stats horizontal
local nsblock  = 1 + int((`nstats'-1)/`neblock')
local is20  0 
forvalues i = 1/`nsblock' {
    local is1`i' `=`is2`=`i'-1''+1'
    local is2`i' `=min(`nstats', `is1`i'' + `neblock' - 1)'
}
* number of blocks if variables horizontal
local nvblock  = 1 + int((`nvars'-1)/`neblock')
local i20  0 
forvalues i = 1/`nvblock' {
    local i1`i' `=`i2`=`i'-1''+1'
    local i2`i' `=min(`nvars', `i1`i'' + `neblock' - 1)'
}




* display results
* ---------------

if "`incol'" == "statistics" {

    * display the results: horizontal = statistics (block wise)
    /*         
    if "`descr'" == "" {
        di as txt _n `"Summary for variables: `varlist'"'
        if "`byv'" != "" {
            local bylabel : var label `byv'
            if `"`bylabel'"' != "" {
                local bylabel `"(`bylabel')"'
            }
            di as txt _col(6) `"by categories of: `byv' `bylabel'"'
        }
    }
    */
    di

    * loop over all nsblock blocks of statistics

    forvalues isblock = 1/`nsblock' {

        * is1..is2 are indices of statistics in a block
        local is1 = `is1`isblock''
        local is2 = `is2`isblock''

        * display header
        if "`by'" != "" {
            local ib 0
            foreach b in `by'{
                local ++ib
                local byname`ib' = abbrev("`b'",`byw`ib'')
                di as txt %~`byw`ib''s "`byname`ib''" _c
                di as text " " _c 
            }
        }
        di as txt  "{c |}" _c
        forvalues is = `is1'/`is2' {
            di as txt %`colwidth's "`titlename`is'' " _c 
        }
        local ndash = `colwidth'*(`is2'-`is1'+ 1)
        di as txt _n "{hline `lleft'}{c +}{hline `ndash'}"

        * loop over the categories of -by- (1..nby) and -total- (nby+1)
        local nbyt = `nby' + ("`total'" == "")
        forvalues iby = 1/`nbyt'{
           forvalues i = 1/`nvars' {
            if "`by'" != "" {
                if `i' == 1 {
                    local ib = 0
                    foreach b in `by'{
                        loca ++ib
                        if `iby' <= `nby'{
                            local lab = substr(`"`lab`iby'`ib''"', 1,`byw`ib'')
                            local val_lab : value label `b'
                            if "`val_lab'" == "" {
                                local type `bytype`ib''
                                local yes_str = index("`type'", "str")
                                if `yes_str' == 0 {
                                    capture local if_date_for`ib' = index("`for`ib''", "%d")
                                    capture local if_time_for`ib' = index("`for`ib''", "%t")
                                    if `if_date_for`ib'' > 0 | `if_time_for`ib'' > 0 {
                                        local date_for`ib' : display `for`ib'' `lab'
                                        di as txt %~`byw`ib''s  `"`date_for`ib''"' _c

                                    }
                                    else {
                                        /* okay for strLs */
                                        di as txt %~`byw`ib''s  `"`lab'"' _c
                                    }

                                }
                                else {
                                    di as txt %~`byw`ib''s  `"`lab'"' _c
                                }
                            }
                            else {
                                di as txt %~`byw`ib''s  `"`lab'"' _c
                            }
                        }
                        else{
                            di as txt %~`=`byw`ib'''s  `"Total"' _c   
                        }
                        di as txt " " _c
                    }
                }
                else {
                    di "{space `=`byw'-1'} {...}"
                }
            }
            if "`descr'" != "" {
                local avn = abbrev("`var`i''",`varwidth')
                di as txt "{ralign `varwidth':`avn'} " _c
            }
            di as txt  "{c |}" _c
            forvalues is = `is1'/`is2' {
                if "`name`is''" == "N" | "`name`is''" == "missing"{
                    local s : display %9.0fc `Stat`iby''[`is',`i'] 
                    di as res %`colwidth's "`s'" _c
                }
                else{
                    local s : display `fmt`i'' `Stat`iby''[`is',`i'] 
                    di as res %`colwidth's "`s'" _c
                }
            }
            di
        }
        if (`iby' >= `nbyt') {
            di as txt "{hline `lleft'}{c BT}{hline `ndash'}"
        }
        else if ("`sepline'" != "") | ((`iby'+1 == `nbyt') & ("`total'" == "")) {
            di as txt "{hline `lleft'}{c +}{hline `ndash'}"
        }
    }

    if `isblock' < `nsblock' {
        display
    }
    } /* isblock */
}

* save results (mainly for certification)
* ---------------------------------------


if "`by'" == ""{
    return matrix StatTotal = `Stat`nbyt''
}
else{
    forvalues iby = 1/`nby' {
        return matrix Stat`iby' = `Stat`iby''
    }
    if "`total'" == ""{
        return matrix StatTotal = `Stat`nbyt''
    }
    matrix colnames `M' = `by'
    return matrix by = `M' 
}

end

/***************************************************************************************************
Modified helper function from tabstat

/* Stats str
processes the contents() option. It returns in
r(names)   -- names of statistics, separated by blanks
r(expr)    -- r() expressions for statistics, separated by blanks
r(summopt) -- option for summarize command (meanonly, detail)
***************************************************************************************************/


note: if you add statistics, ensure that the name of the statistic
is at most 8 chars long.
*/
cap program drop Stats2
program define Stats2, rclass
    if `"`0'"' == "" {
        local opt "mean"
    }
    else {
        local opt `"`0'"'
    }

    * ensure that order of requested statistics is preserved
    * invoke syntax for each word in input
    local class 0
    local nq 0
    foreach st of local opt {
        local 0 = lower(`", `st'"')

        capt syntax [, n freq missing MEan sd Variance SUm COunt MIn MAx Range SKewness Kurtosis /*
        */  SDMean SEMean p1 p5 p10 p25 p50 p75 p90 p95 p99 iqr q MEDian CV *]
        if _rc {
            di in err `"unknown statistic: `st'"'
            exit 198
        }
        if "`median'" != "" {
            local p50 p50
        }
        * class 1 : available via -summarize, meanonly-
        * summarize.r(N) returns #obs (note capitalization)
        local s "`n'`freq'`min'`mean'`max'`sum'"
        if "`s'" != "" {
            if "`n'" ~= ""{
                local titlename Obs
                local s N
            }
            else{
                local titlename `=strproper("`s'")'
            }
            local names "`names' `s'"
            local titlenames `"`titlenames' `titlename'"'
            local expr  "`expr' r(`s')"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }

        if "`range'" != "" {
            local names "`names' range"
            local titlenames `"`titlenames' `s'"'
            local expr  "`expr' r(max)-r(min)"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }

        if "`freq'" != "" {
            local names "`names' freq"
            local titlenames `"`titlenames' `s'"'
            local expr  "`expr' r(N)"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }

        if "`missing'" != "" {
            local names "`names' missing"
            local titlenames `"`titlenames' Missing"'
            local expr  "`expr' r(N)"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }


        * class 2 : available via -summarize-

        if "`sd'" != "" {
            local names "`names' sd"
            local titlenames `"`titlenames' "Std. Dev.""'
            local expr  "`expr' r(sd)"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }
        if "`sdmean'" != "" | "`semean'"!="" {
            local names "`names' se(mean)"
            local titlenames `"`titlenames' se(mean)"'
            local expr  "`expr' r(sd)/sqrt(r(N))"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }
        if "`variance'" != "" {
            local names "`names' variance"
            local titlenames `"`titlenames' `s'"'
            local expr  "`expr' r(Var)"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }
        if "`cv'" != "" {
            local names "`names' cv"
            local titlenames `"`titlenames' cv"'
            local expr  "`expr' (r(sd)/r(mean))"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }

        * class 3 : available via -detail-

        local s "`skewness'`kurtosis'`p1'`p5'`p10'`p25'`p50'`p75'`p90'`p95'`p99'"
        if "`s'" != "" {
            if inlist("`s'", "skewness", "kurtosis"){
                local titlename `=strproper("`s'")'
            }
            else{
                local titlename `s'
            }
            local names "`names' `s'"
            local titlenames `"`titlenames' `titlename'"'
            local expr  "`expr' r(`s')"
            local class = max(`class',3)
            local cmd "`cmd' sum"
            continue
        }
        if "`iqr'" != "" {
            local names "`names' iqr"
            local titlenames `"`titlenames' iqr"'
            local expr  "`expr' r(p75)-r(p25)"
            local class = max(`class',3)
            local cmd "`cmd' sum"
            continue
        }
        if "`q'" != "" {
            local names "`names' p25 p50 p75"
            local titlenames `"`titlenames' p25 p50 p75"'
            local expr  "`expr' r(p25) r(p50) r(p75)"
            local class = max(`class',3)
            local cmd "`cmd' sum"
            continue
        }

        if regexm("`options'","p[0-9]*"){
            local quantile `=regexr("`options'", "p", "")'
            local nq = `nq' + 1
            local names "`names' `options'"
            local titlenames `"`titlenames' `options'"'
            local expr "`expr' r(r`nq')"
            local pctileopt "`pctileopt' `quantile'"
            local cmd "`cmd' pctile"
        }
    }




    if `class' == 1 {
        local summopt "meanonly"
    }
    else if `class' == 3 {
        local summopt "detail"
    }
    return local names `names'
    return local titlenames `titlenames'

    return local expr  `expr'
    return local cmd  `cmd'
    return local summopt `summopt'
    return local pctileopt  `pctileopt'


end
