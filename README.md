
The command `stat` prints summary statistics by groups. 

### `stat` has the same defaults than `summarize` 

```
sysuse nlsw88.dta, clear
stat hours, by(race) 
```
![](img/sum.jpg)

You can compute more statistics with the option `detail`:
```
stat hours, by(race) detail
```
![](img/sum3.jpg)


### `stat` accepts groups defined by  multiple variables

```
stat hours, by(race married) s(m)
```
![](img/sum4.jpg)





### `stat` is fast
`stat` is faster than `tabulate`, `table, contents`, `tabstat`, or `collapse`


### `stat` accepts many statistics

```
stat hours, by(race)  s(mean p80)
```
![](img/sum6.jpg)

The list of allowed statistics is:

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
p??			|	any ??th percentile


### `stat`can `collapse` to an external dataset

```
stat hours wage , by(race married) s(mean p50 p90) output(temp.dta)
describe using temp.dta
```
![](img/sum5.jpg)


# fasttabstat

The command `fasttabstat` is a drop-in version of `tabstat`, with two advantages:
- `fasttabstat`  is 10x faster than `tabstat`.
- `fasttabstat` accepts more statistics than `tabstat` : 
	- any percentile 
	- `nmissing` : number of missing observations.

