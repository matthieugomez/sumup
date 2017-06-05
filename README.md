


### `sumup`  = `summarize` by group

`sumup` allows to `summarize` your data by group

```
sysuse nlsw88.dta, clear
sumup hours, by(race) 
```
![](img/sum.jpg)

- Use the detailed option to return detailed statistics

```
sumup hours, by(industry) detail
```
![](img/sumdetail.jpg)


- Define groups with respect to multiple variables
```
sumup hours, by(union married) 
```
![](img/sumgroups.jpg)



- Use the `statistics` option to return a specific set of statistics (including any percentile)

	```sumup hours, by(industry) statistics(p80)```


`sumup` is ten times faster than `table, contents()` or `tabstat`. `sumup` is as fast, but more flexible, than `tabulate, summarize()`. `sumup` borrows heavily  from `tabstat`.  The package also includes the command `fasttabstat` which is a drop in faster version of `tabstat`.



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
