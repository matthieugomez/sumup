# fasttabstat

The command `fasttabstat` is an better version of `tabstat`. `fasttabstat` has exactly the same syntax than `tabstat`, with two advantages:
- `fasttabstat`  is 10x faster than `tabstat`. `fasttabstat` is faster than `tabulate, summarize()`.
- `fasttabstat` accepts more statistics than `tabstat` : 
	- any percentile 
	- `nmissing` : number of missing observations.


# stat
The command `stat` is a wrapper for `fastabstat`, with a syntax closer to `summarize`:
-  By default, the same statistics than `summarize` & the option `detail` is allowed.
- `stat` returns a list of scalar of the form `r(statname_byvalue)` instead of matrices
- `stat` works with groups defined by multiple variables


One can use `stat` as a better `sum`:
```
sysuse nlsw88.dta, clear
stat hours, by(race) 
```
![](img/sum.jpg)

```
stat hours, by(race married) detail
```
![](img/sum3.jpg)


One can also use `stat` as a way to `tabulate` groups defined by multiple variables

```
stat hours, by(race married) s(m)
```
![](img/sum4.jpg)


One can also use `stat` as faster way to `collapse` 

```
stat hours wage , by(race married) s(mean p50 p90) output(temp.dta)
use temp.dta, clear s(mean sum)
```
![](img/sum5.jpg)

# List of statistics

For both commands, the list of allowed statistics is:

Name | Definition
---|---
mean          | mean
count         | count of nonmissing observations
n             | same as count
sum           | sum
max           | maximum
min           | minimum
range         | range = max - min
sd            | standard deviation
variance      | variance
cv            | coefficient of variation (sd/mean)
semean        | standard error of mean (sd/sqrt(n))
skewness      | skewness
kurtosis      | kurtosis
median        | median (same as p50)
iqr           | interquartile range = p75 - p25
q             | equivalent to specifying p25 p50 p75
nmissing	|	Number of missing observations
p??			|	??th percentile

