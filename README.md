
The command `sumup` prints summary statistics by groups. 




### `sumup` prints statistics by group

```
sysuse nlsw88.dta, clear
sumup hours, by(race)  statistics(mean p80)
```
![](img/sum6.jpg)


### `sumup` has smart defaults

By default, `sumup` returns the same set of statistics than `summarize` 

```
sumup hours, by(race) 
```
![](img/sum.jpg)

The option `detail` behaves similarly than in `summarize`:
```
sumup hours, by(race) detail
```
![](img/sum3.jpg)


### `sumup` accepts an arbitrary number of statistics

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




### `sumup` accepts groups defined by  multiple variables

```
sumup, by(race married) statistics(n)
```
![](img/sum4.jpg)




### `sumup` can `collapse` to an external dataset
Use the `output` option:
```
sumup hours wage , by(race married) s(mean p50 p90) output(temp.dta)
describe using temp.dta
```
![](img/sum5.jpg)

### `sumup` is fast
`sumup` is faster than `tabulate, sum()` ; `table, contents()`; `tabstat`; or `collapse`


# fasttabstat

The command `fasttabstat` is a drop-in version of `tabstat`, with two advantages:
- `fasttabstat`  is 10x faster than `tabstat`.
- `fasttabstat` accepts more statistics than `tabstat` : 
	- any percentile 
	- `nmissing` : number of missing observations.

