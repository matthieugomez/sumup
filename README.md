



### `sumup` prints summary statistics by group

```
sysuse nlsw88.dta, clear
sumup hours, by(race)  statistics(mean p80)
```
![](img/sum6.jpg)


### `sumup` extends `summarize`:

By default, `sumup` returns the same set of statistics than `summarize` 

```
sumup hours, by(race) 
```
![](img/sum.jpg)

With the option `detail`, `sumup` returns detailed statistics:
```
sumup hours, by(race) detail
```
![](img/sum3.jpg)


### `sumup` is flexible
The list of allowed statistics is:

Name | Definition
---|---
mean          | mean
count         | count of nonmissing observations
n             | same as count
missing	|	Number of missing observations
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
p??			|	any ??th percentile




### `sumup` accepts groups defined by several variables:

`sumup` can compute summary statistics for groups defined by multiple variables:

```
sumup hours, by(race married) 
```
![](img/sum7.jpg)


This makes `sumup` a useful extension of `tabulate`:

```
sumup, by(race married) 
```
![](img/sum4.jpg)




### `sumup` can `collapse` to an external dataset
Just use the `output` option:
```
sumup hours wage , by(race married) s(mean p50 p90) output(temp.dta)
describe using temp.dta
```
![](img/sum5.jpg)
Contrary to the `collapse` command, labels are lost in the process

### `sumup` is fast
`sumup` is ten times faster than `table, contents()`; `tabstat` or `collapse`. `sumup` is as fast, but more powerful, than `tabulate, summarize()`.

# fasttabstat
`sumup` borrows heavily from `tabstat`. The command `fasttabstat` is a drop-in version of `tabstat`, with two advantages:
- `fasttabstat`  is 10x faster than `tabstat`.
- `fasttabstat` accepts more statistics than `tabstat` : 
	- any percentile 
	- `missing` : number of missing observations.

