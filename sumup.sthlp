{smcl}
{* *! version 0.2 08jul2015}{...}
{vieweralsosee "tabstat" "help tabstat"}{...}
{vieweralsosee "tabulate" "help tabulate"}{...}
{vieweralsosee "table" "help table"}{...}
{vieweralsosee "collapse" "help collapse"}{...}
{viewerjumpto "Syntax" "sumup##syntax"}{...}
{viewerjumpto "Description" "sumup##description"}{...}
{viewerjumpto "Weights" "sumup##weights"}{...}
{viewerjumpto "Options" "sumup##options"}{...}
{viewerjumpto "Statistics" "sumup##statnames"}{...}
{viewerjumpto "Examples" "sumup##examples"}{...}
{viewerjumpto "Author" "sumup##contact"}{...}

{title:Title}

{p2colset 5 18 20 2}{...}
{p2col :{cmd:sumup} {hline 2}}Summary statistics by group{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}
{p 8 15 2} {cmd:sumup}
[{varlist}] 
{ifin} {it:{weight}}
{cmd:,} 
[{help sumup##options:options}] {p_end}


{marker description}{...}
{title:Description}

{pstd}
{cmd:sumup} returns the same set of statistics than {cmd:summarize}, computed by groups.

{marker weights}{...}
{title:Weights}
{pstd}
{cmd:fweight}s, {cmd:aweight}s and {cmd:pweight}s are allowed; see {help weight}.



{marker options}{...}
{title:Options}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt :{opt by(byvars)}} variable(s) defining groups {p_end}
{synopt :{opt d:etail}} detailed statistics.{p_end}
{synopt:{opt s:tatistics(statnames)}} specified list of statistics (see {help sumup##statnames:statnames}) {p_end}
{synopt:{opt save(filename)}} save statistics as a collapsed dataset {p_end}
{synopt:{opt replace}}  overwrite existing dataset{p_end}


{marker statnames}{...}
{title:Statnames}
{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt me:an}} mean{p_end}
{synopt:{opt co:unt}} count of nonmissing observations{p_end}
{synopt:{opt n}} same as {cmd:count}{p_end}
{synopt:{opt su:m}} sum{p_end}
{synopt:{opt ma:x}} maximum{p_end}
{synopt:{opt mi:n}} minimum{p_end}
{synopt:{opt r:ange}} range = {opt max} - {opt min}{p_end}
{synopt:{opt sd}} standard deviation{p_end}
{synopt:{opt v:ariance}} variance{p_end}
{synopt:{opt cv}} coefficient of variation ({cmd:sd/mean}){p_end}
{synopt:{opt sem:ean}} standard error of mean ({cmd:sd/sqrt(n)}){p_end}
{synopt:{opt sk:ewness}} skewness{p_end}
{synopt:{opt k:urtosis}} kurtosis{p_end}
{synopt:{opt med:ian}} median (same as {opt p50}){p_end}
{synopt:{opt p??}} ??th percentile {p_end}
{synopt:{opt iqr}} interquartile range = {opt p75} - {opt p25}{p_end}
{synopt:{opt q}} equivalent to specifying {cmd:p25 p50 p75}{p_end}




{marker examples}{...}
{title:Examples}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse nlsw88.dta}{p_end}
{phang2}{cmd:. sumup wage, by(race) }{p_end}
{phang2}{cmd:. sumup wage [w = hours], by(race) }{p_end}
{phang2}{cmd:. sumup wage, by(industry) detail}{p_end}
{phang2}{cmd:. sumup wage, by(union married)}{p_end}
{phang2}{cmd:. sumup, by(union married)}{p_end}
{phang2}{cmd:. sumup wage, by(industry) statistics(mean p80)}{p_end}
{phang2}{cmd:. sumup  wage hours, by(union married) save(temp.dta) replace}{p_end}



{marker references}{...}
{title:References}

{cmd:sumup}, {cmd:table}, {cmd:tabstat}, {cmd:collapse} have similar functionalities, but {cmd:sumup} is ten times faster.
Code for {cmd:sumup} borrows heavily from {cmd:tabstat}.


{marker contact}{...}
{title:Author}

{phang}
Matthieu Gomez

{phang}
Department of Economics, Princeton University

{phang}
Please report issues on Github
{browse "https://github.com/matthieugomez/stata-sumup":https://github.com/matthieugomez/stata-sumup}
{p_end}


