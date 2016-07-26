



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


```
sumup hours, by(union married) 
```
![](img/sumgroups.jpg)






Sumup can also returns any percentile p??
```sumup hours, by(industry) statistics(p80)```


Save the results in a dataset, rather than in locals.

```
sumup hours wage, by(union married) statistics(mean p50 p90) save(temp.dta) replace
```
![](img/sumcollapse2.jpg)
collapse


`sumup` is ten times faster than `table, contents()`, `tabstat` or `collapse`. `sumup` is as fast, but more flexible, than `tabulate, summarize()`.
`sumup` borrows heavily  from `tabstat`.  The package also includes the command `fasttabstat` which is a drop in faster version of `tabstat`.


# Installation
`sumup` is now available on SSC. 

```
ssc install sumup
```

To install the latest version  on Github 
- with Stata13+
	```
	net install sumup, from(https://github.com/matthieugomez/stata-sumup/raw/master/)
	```

- with Stata 12 or older, download the zipfiles of the repositories and run in Stata the following commands:
	```
	net install sumup, from("SomeFolder")
	```
