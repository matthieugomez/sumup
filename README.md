



### `sumup`  = `summarize` by group

`sumup` returns the same set of statistics than `summarize`, but computes them by group

```
sysuse nlsw88.dta, clear
sumup hours, by(race) 
```
![](img/sum.jpg)

With the option `detail`, `sumup` returns detailed statistics:
```
sumup hours, by(industry) detail
```
![](img/sumdetail.jpg)



### `sumup` accepts groups defined by several variables:

Compute summary statistics for groups defined by multiple variables:

```
sumup hours, by(union married) 
```
![](img/sumgroups.jpg)


Count the number of observations by groups defined by multiple variables:

```
sumup, by(union married) 
```
![](img/sumtab.jpg)



### `sumup` is flexible

Specify any set of statistics using the option `statistics`
```
sumup hours, by(industry) statistics(mean p80)
```
![](img/sumstat.jpg)


The list of allowed statistics is the following:

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


Instead of returning a set of scalars, sumup returns matrices.





### `sumup` can `collapse` to an external dataset

Save the summary statistics  dataset through the `save` option:

```
sumup hours wage, by(union married) statistics(mean p50 p90) save(temp.dta) replace
```
![](img/sumcollapse2.jpg)





### `sumup` is fast
`sumup` is ten times faster than `table, contents()`, `tabstat` or `collapse`. `sumup` is as fast, but more flexible, than `tabulate, summarize()`.


# Installation
```
net install sumup, from(https://github.com/matthieugomez/stata-sumup/raw/master/)
```

If you have a version of Stata < 13, you need to install it manually

1. Click the "Download ZIP" button in the right column to download a zipfile. 
2. Extract it into a folder (e.g. ~/SOMEFOLDER)
3. Run

	```
	cap ado uninstall sumup
	net install sumup, from("~/SOMEFOLDER")
	```

# Reference
`sumup` borrows heavily  from `tabstat`.  The package also includes the command `fasttabstat` which is a drop in faster version of `tabstat`.