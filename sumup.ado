/***************************************************************************************************
The code for sumup is heavily inspired by tabstat.
***************************************************************************************************/

program define sumup, sortpreserve rclass
    version 12.1
    syntax [varlist(default=none)] [if] [in] [aweight fweight] [,  ///
    by(varlist) ///
    save(str) replace ///
    Detail Statistics(str) ///
    Missing noTotal ///
    seps(numlist) ///
    CASEwise Format(str) ///
    LAbelwidth(int -1) VArwidth(int -1) ///
    SAME noSEParator  septable(string)]



    if ("`weight'"!="") local wt [`weight'`exp']

    if "`varlist'" == ""{
        * tabulate function
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


    if "`total'" != "" & "`by'" == "" {
        di as txt "nothing to display"
        exit 0
    }


    if `"`format'"' != "" {
        capt local tmp : display `format' 1
        if _rc {
            di as err `"invalid %fmt in format(): `format'"'
            exit 120
        }
    }
    local incol "statistics"

    if `"`weight'"' != "" {
        local wght `"[`weight'`exp']"'
    }

    /* loop */

    tokenize "`varlist'"
    local nvars : word count `varlist'
    forvalues iv = 1/`nvars' {
        local var`iv' ``iv''
        if `"`format'"' != "" {
            local fmt`iv' `format'
        }
        else if inlist("`name`iv''", "N", "missing"){
            local fmt`iv' %9.0fc
        }
        else{
            local fmt`iv' : format ``iv''
        }
    }


    if "`by'" == "" | `varwidth' != -1 | `nvars' > 1 {
        local descr descr
    }

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


    





    if "`by'" ~= ""{
        local nby : word count `by'
        tokenize `by'
        local maxlength 0
        forval ib = 1/`nby'{
            local by`ib' ``ib'' 
            local byfullname`ib' `by`ib''
            local byvaluelabel`ib' `: value label `by`ib'''
            local bytype`ib': type `by`ib''
            local byformat`ib': format `by`ib''
            local bymaxlength`ib' 0
            local byistime`ib' = 0
            if "`byvaluelabel`ib''" == "" {
                if regexm("`bytype`ib''", "str") == 0 {
                    local byistime`ib' = regexm("`byformat`ib''", "%d|%t")
                }
            }
        }

    }
    else{
        local nby = 0
    }


    /*  sample selection  */

    marksample touse, novarlist
    if `nby' & "`missing'" == "" {
        markout `touse' `by' , strok
    }
    qui count if `touse'
    local samplesize=r(N)
    if `samplesize' == 0 {
        error 2000
    }
    local touse_first=_N-`samplesize'+1
    local touse_last=_N


    // varlist -> var1, var2, ... variables
    //            fmt1, fmt2, ... display formats





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
    forvalues is = 1/`nstats' {
        local expr`is' ``is''
    }
    tokenize `cmd'
    forvalues is = 1/`nstats' {
        local cmd`is' ``is''
    }
    tokenize `stats'
    forvalues is = 1/`nstats' {
        local name`is' ``is''
        local names "`names' ``is''"
        if `is' < `nstats' {
            local names "`names',"
        }
    }
    tokenize `titlestats'
    forvalues is = 1/`nstats' {
        local titlename`is' ``is''
        local titlenames "`titlenames' ``is''"
        if `is' < `nstats' {
            local titlenames "`titlenames',"
        }
    }


    if "`separator'" == "" & ( (`nstats' > 1 & "`incol'" == "variables") /*
    */         |(`nvars' > 1  & "`incol'" == "statistics")) {
        local sepline yes
    }



    if "`save'" != ""{
        cap confirm new file `"`save'"'
        if _rc ~= 0 & "`replace'" == ""{
            di as error  `"file `save' already exists. Specify option replace"'
            exit
        }

        tempfile postfile
        tempname postname
        forval ib = 1/`nby' {
            local postvars `postvars' `: type `by`ib''' `by`ib''
        }

        if `nvars' == 1{
            forvalues is = 1/`nstats'{
                local postvars `postvars' `name`is''
            }
        }
        else{
            forvalues iv = 1/`nvars' {
                forvalues is = 1/`nstats'{
                    local postvars `postvars' `var`iv''_`name`is''
                }
            }
        }
        qui postfile `postname' `postvars' using `postfile'
    }


    /* compute statistics  by group*/
    local matsize : set matsize
    local matreq = max(`nstats',`nvars')
    if `matsize' < `matreq' {
        di as err /*
        */ "set matsize to at least `matreq' (see help matsize for details)"
        exit 908
    }
    tempname Stat
    mat `Stat' = J(`nstats',`nvars',0)
    mat colnames `Stat' = `varlist'
    mat rownames `Stat' = `stats'

    if `nby'{
        tempvar bylength
        local tlength = cond(c(N)>c(maxlong), "double", "long")
        bys `touse' `by' : gen `tlength' `bylength' = _N 
        local ig = 0
        local start = `touse_first'
        while `start' < `touse_last'{
            local ++ig
            local end = `start' + `=`bylength'[`start']' - 1

            * loop over all variables
            forvalues iv = 1/`nvars' {
                if regexm("`cmd'", "sum") {
                    qui summ `var`iv'' in `start'/`end' `wght', `summopt'
                    forvalues is = 1/`nstats' {
                        if "`cmd`is''" == "sum"{
                            if "`name`is''"== "freq"{
                                mat `Stat'[`is',`iv'] = `end' - `start' + 1
                            }
                            else if  "`name`is''"== "missing"{
                                mat `Stat'[`is',`iv'] = `end' - `start' + 1 - `expr`is''
                            }
                            else{
                                mat `Stat'[`is',`iv'] = `expr`is''
                            }
                        }
                    }
                }
                if "`pctileopt'" ~= ""{
                    qui _pctile `var`iv'' in `start'/`end' `wght', p(`pctileopt')
                    forvalues is = 1/`nstats' {
                        if "`cmd`is''" == "_pctile"{
                            mat `Stat'[`is',`iv'] = `expr`is''
                        }
                    }
                }
            }   
            if "`save'"==""{
                tempname Stat`ig'
                mat `Stat`ig'' = `Stat'
                mat `Stat' = J(`nstats',`nvars', .)
            } 
            else{
                local bypost ""
                forval ib = 1/`nby'{
                    local bypost `bypost' (`by`ib''[`start'])
                }

                local statpost ""
                forvalues iv = 1/`nvars' {
                    forvalues is = 1/`nstats'{
                        local statpost `statpost' (`Stat'[`is',`iv'])
                    }
                }
                post `postname' `bypost' `statpost'
            }
            local start = `end' + 1

        }
        local ng `ig'
    }
    else {
        local ng 0
    }

    /* if save */
    if "`save'" ~= ""{
        postclose `postname'
        copy `postfile' `save', `replace'
        display "file `save' written"
    }
    else{
        if `nby'{
            * only do it if no collapse. This also means only a few groups
            local start = `touse_first'
            local ig = 0
            while `start' < `touse_last'{
                local ++ig
                local end = `start' + `=`bylength'[`start']' - 1
                forval ib = 1/`nby'{
                    * cap because string matrix does not exist
                    forval ib = 1/`nby'{
                        if "`byvaluelabel`ib''" ~= ""{
                            local byvaluelabel`ib'`ig' `"`: label `byvaluelabel`ib'' `=`by`ib''[`start']''"'
                        }
                        else{
                            local byvaluelabel`ib'`ig' `"`=`by`ib''[`start']'"'
                        }
                        local bymaxlength`ib' = max(strlen(`"`byvaluelabel`ib'`ig''"'),`bymaxlength`ib'')
                    }
                }
                local start = `end' + 1
            }
        }

        /* total */
        if "`total'" == "" {
            if `nby'{
                local condition in `touse_first'/`touse_last'
            }
            else{
                local condition if `touse'==1
            }
            forvalues iv = 1/`nvars' {
                if regexm("`cmd'", "sum") {
                    qui summ `var`iv''  `wght' `condition', `summopt'
                    forvalues is = 1/`nstats' {
                        if "`cmd`is''" == "sum"{
                            if "`name`is''"== "freq"{
                                mat `Stat'[`is',`iv'] = _N
                            }
                            else if  "`name`is''"== "missing"{
                                mat `Stat'[`is',`iv'] = _N - `expr`is''
                            }
                            else{
                                mat `Stat'[`is',`iv'] = `expr`is''
                            }
                        }
                    }
                }
                if "`pctileopt'" ~= ""{
                    qui _pctile `var`iv'' `wght' `condition', p(`pctileopt')
                    forvalues is = 1/`nstats' {
                        if "`cmd`is''" == "_pctile"{
                            mat `Stat'[`is',`iv'] = `expr`is''
                        }
                    }
                }
            }

            local ngt = `ng' + 1
            forval ib = 1/`nby'{
                local byvaluelabel`ib'`ngt' "Total"
            }
            tempvar Stat`ngt'
            mat `Stat`ngt'' = `Stat'
        }
        else{
            local ngt = `ng'
        }


        * constants for displaying results
        * --------------------------------
        local byw = 0
        if `nby' {
            forval ib = 1/`nby'{
                if substr("`bytype`ib''",1,3) != "str" {
                    local byw`ib' = min(floor((`labelwidth'+1)/`nby')-1,`bymaxlength`ib'')
                }
                else {
                    local byw`ib'=min(real(substr("`bytype`ib''",4,.)),floor((`labelwidth'+1)/`nby')-1)
                    local bytype`ib' str
                }
                if regexm("`byformat`ib''", "\%d") {
                    local has_M = index("`byformat`ib''", "M")
                    local has_L = index("`byformat`ib''", "L")
                    if `has_M' > 0 | `has_L' > 0 {
                        local byw`ib' = 18
                    }
                    else {
                        local byw`ib' = 11
                    }
                }
                else if regexm("`byformat`ib''", "\%t"){
                    local byw`ib' = 9
                }
                else {
                    local byw`ib' = max(length("`by`ib''"), `byw`ib'')
                }
                if "`total'" == "" {
                    local byw`ib' = max(`byw`ib'', 6)
                }
                local byw = `byw' + `byw`ib'' + 1
                local byshortname`ib' = abbrev("`byfullname`ib''",`byw`ib'')
            }
        }
        * number of chars in display format
        local ndigit  9
        local colwidth = `ndigit'+2

        local lleft = `byw' *("`by'"!="") + (`varwidth'+1)*("`descr'"!="")

        local cbar  = `lleft' + 1
        local lsize = c(linesize)
        * number of non-label elements in the row of a block
        local neblock = int((`lsize' - `cbar')/10)
        if "`seps'" == ""{
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
        }
        else{
            local seps `seps' `nstats'
            local nsblock : word count `seps'
            local is20  0 
            forvalues i = 1/`nsblock' {
                local is1`i' `=`is2`=`i'-1''+1'
                local is2`i' `: word `i' of `seps''
            }
            local nvblock : word count `seps'
            local i20  0 
            forvalues i = 1/`nsblock' {
                local i1`i' `=`i2`=`i'-1''+1'
                local i2`i' `: word `i' of `seps''
            }
        }


        /* display */
        di



        forvalues isblock = 1/`nsblock' {

            * is1..is2 are indices of statistics in a block
            local is1 = `is1`isblock''
            local is2 = `is2`isblock''
            * display header
            if `nby'{
                forval ib = 1/`nby'{
                    di as txt %~`byw`ib''s "`byshortname`ib''" _c
                    di as text " " _c 
                }
            }

            if "`descr'" ~= ""{
                local avn = abbrev("variable",`varwidth')
                di as txt "{ralign `varwidth':`avn'} " _c

            }
            di as txt  "{c |}" _c


            forvalues is = `is1'/`is2' {
                di as txt %`colwidth's "`titlename`is'' " _c 
            }
            local ndash = `colwidth'*(`is2'-`is1'+ 1)
            di as txt _n "{hline `lleft'}{c +}{hline `ndash'}"

            * loop over the categories of -by- (1..nby) and -total- (nby+1)
            forvalues ig = 1/`ngt'{
                if `nby' {
                    if `ig' <= `ng'{
                        forval ib = 1/`nby'{
                            local lab = substr(`"`byvaluelabel`ib'`ig''"', 1,`byw`ib'')
                            if `byistime`ib''{
                                di as txt %~`byw`ib''s  `"`: display `byformat`ib'' `lab'''"' _c

                            }
                            else {
                                di as txt %~`byw`ib''s  `"`lab'"' _c
                            }
                            di as text " " _c 
                        }
                    }
                    else{
                        forval ib = 1/`nby'{
                            if `ib' == 1{
                                di as txt %~`byw1's  `"Total"' _c   
                            }
                            else{
                                di as txt %~`byw`ib''s  `" "' _c   
                            }                    
                            di as text " " _c 
                        }
                    }
                }

                forvalues iv = 1/`nvars' {
                    if `iv' > 1 & `nby'{
                        di "{space `=`byw'-1'} {...}"
                    }
                    if "`descr'" != "" {
                        local avn = abbrev("`var`iv''",`varwidth')
                        di as txt "{ralign `varwidth':`avn'} " _c
                    }
                    di as txt  "{c |}" _c
                    forvalues is = `is1'/`is2' {
                        local s : display `fmt`iv'' `Stat`ig''[`is',`iv'] 
                        di as res %`colwidth's "`s'" _c
                    }
                    di
                }
                if (`ig' >= `ngt') {
                    di as txt "{hline `lleft'}{c BT}{hline `ndash'}"
                }
                else if ("`sepline'" != "") | ((`ig' == `ng') & (`ngt' == `ng' + 1)) {
                    di as txt "{hline `lleft'}{c +}{hline `ndash'}"
                }
            }

            if `isblock' < `nsblock' {
                display
            }
        }

        * save results 
        * ---------------------------------------

        if "`total'" == ""{
            return matrix StatTotal = `Stat`ngt''
        }
        if `nby'{
            foreach ig of numlist `ng'/1 {
                return matrix Stat`ig' = `Stat`ig''
            }
        }
    }
end

/***************************************************************************************************
Modified helper function 
***************************************************************************************************/


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
        if regexm("`st'", "^p[0-9]*$"){
            if !inlist("`st'", "p1", "p5", "p10", "p25", "p50", "p75", "p90", "p95", "p99"){
                local pctilecmd yes
            }
        }
        else if inlist("`st'", "sk", "skewness", "k", "kurtosis"){
            local sumdcmd yes
        }
    }



    foreach st of local opt {
        local st = lower(`"`st'"')

        if "`st'" == "me" {
            local st mean
        }
        else if "`st'" == "c" {
            local st count
        }
        else if "`st'" == "su" {
            local st sum
        }
        else if "`st'" == "ma" {
            local st max
        }
        else if "`st'" == "mi" {
            local st min
        }
        else if "`st'" == "r" {
            local st range
        }
        else if "`st'" == "v" {
            local st variance
        }
        else if "`st'" == "sem" {
            local st semean
        }
        else if "`st'" == "sk" {
            local st skewness
        }
        else if "`st'" == "k" {
            local st skurtosis
        }
        else if "`st'" == "me" {
            local st mean
        }
        else if inlist("`st'", "med", "median") {
            local st p50
        }

        * class 1 : available via -summarize, meanonly-
        * summarize.r(N) returns #obs (note capitalization)
        if inlist("`st'", "min", "mean", "max", "sum"){
            local titlename `=strproper("`st'")'
            local names "`names' `st'"
            local titlenames `"`titlenames' `titlename'"'
            local expr  "`expr' r(`st')"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }
        if inlist("`st'", "count", "n", "N"){
            local st N
            local titlename Obs
            local names "`names' `st'"
            local titlenames `"`titlenames' `titlename'"'
            local expr  "`expr' r(`st')"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }
        if "`st'" == "range"  {
            local names "`names' range"
            local titlenames `"`titlenames' `st'"'
            local expr  "`expr' r(max)-r(min)"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }
        if "`st'" == "freq" {
            local names "`names' freq"
            local titlenames `"`titlenames' `st'"'
            local expr  "`expr' r(N)"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }
        if "`st'" == "missing" {
            local names "`names' missing"
            local titlenames `"`titlenames' Missing"'
            local expr  "`expr' r(N)"
            local class = max(`class',1)
            local cmd "`cmd' sum"
            continue
        }


        * class 2 : available via -summarize-

        if "`st'" == "sd"{
            local names "`names' sd"
            local titlenames `"`titlenames' StdDev"'
            local expr  "`expr' r(sd)"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }
        if inlist("`st'", "sdmean", "semean") {
            local names "`names' se(mean)"
            local titlenames `"`titlenames' se(mean)"'
            local expr  "`expr' r(sd)/sqrt(r(N))"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }
        if inlist("`st'", "variance") {
            local names "`names' variance"
            local titlenames `"`titlenames' `st'"'
            local expr  "`expr' r(Var)"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }
        if inlist("`st'", "cv") {
            local names "`names' cv"
            local titlenames `"`titlenames' cv"'
            local expr  "`expr' (r(sd)/r(mean))"
            local class = max(`class',2)
            local cmd "`cmd' sum"
            continue
        }

        * class 3 : available via -detail-

        if  inlist("`st'", "skewness", "kurtosis") {
            local titlename `=strproper("`st'")'
            local names "`names' `st'"
            local titlenames `"`titlenames' `titlename'"'
            local expr  "`expr' r(`st')"
            local class = max(`class',3)
            local cmd "`cmd' sum"
            continue
        }

        if inlist("`st'", "iqr") {
            local names "`names' iqr"
            local titlenames `"`titlenames' iqr"'
            local expr  "`expr' r(p75)-r(p25)"
            local class = max(`class',3)
            local cmd "`cmd' sum"
            continue
        }


        if inlist("`st'", "q") {
            local names "`names' p25 p50 p75"
            local titlenames `"`titlenames' p25 p50 p75"'
            local expr  "`expr' r(p25) r(p50) r(p75)"
            local class = max(`class',3)
            local cmd "`cmd' `qcmd'"
            continue
        }   
        if regexm("`st'","^p[0-9]*$"){
            local names "`names' `st'"
            local titlenames `"`titlenames' `st'"'
            if inlist("`st'", "p1", "p5", "p10", "p25", "p50", "p75", "p90", "p95", "p99") & ("`pctilecmd'"  == "" |  "`sumdcmd'" == "yes"){
                local expr "`expr' r(`st')"
                local class = max(`class', 3)
                local cmd "`cmd' sum"
            }
            else{
                local nq = `nq' + 1             
                local quantile `=regexr("`st'", "p", "")'
                local expr "`expr' r(r`nq')"
                local pctileopt "`pctileopt' `quantile'"
                local cmd "`cmd' _pctile"
            }
            continue
        }
        di as error "`st' does not correspond to any stat"
        exit
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
