### `sumup`  = `summarize` by group

`sumup` allows to `summarize` your data by groups defined by one or more variable

```
sysuse nlsw88.dta, clear
sumup hours, by(union) 
*  union   |       Obs    Missing       Mean     StdDev        Min        Max 
* ---------+------------------------------------------------------------------
* Nonunion |      1,416          1     37.262    10.2272          1         80
*  Union   |        461          0    38.6594    9.11014          2         70
* ---------+------------------------------------------------------------------
*  Total   |      1,877          1    37.6052    9.98027          1         80
* ----------------------------------------------------------------------------

```
- Use multiple group variables

```
sumup hours, by(union married) 
*  union  married |       Obs    Missing       Mean     StdDev        Min        Max 
* ----------------+------------------------------------------------------------------
* Nonunio Single  |        474          1    39.7911    8.19843          5         80
* Nonunio Married |        942          0    35.9894    10.8929          1         80
*  Union  Single  |        181          0    39.8729    7.83088         10         70
*  Union  Married |        280          0     37.875     9.7827          2         67
* ----------------+------------------------------------------------------------------
*  Total          |      1,877          1    37.6052    9.98027          1         80
* -----------------------------------------------------------------------------------

```

- Use the detailed option to return detailed statistics

```
sumup hours, by(union) detail
*  union   |       Obs    Missing       Mean     StdDev   Skewness   Kurtosis 
* ---------+------------------------------------------------------------------
* Nonunion |      1,416          1     37.262    10.2272   -.835957    5.22066
*  Union   |        461          0    38.6594    9.11014    -.75361    6.01313
* ---------+------------------------------------------------------------------
*  Total   |      1,877          1    37.6052    9.98027   -.835598     5.4168
* ----------------------------------------------------------------------------
* 
*  union   |       Min         p1         p5        p10        p25        p50 
* ---------+------------------------------------------------------------------
* Nonunion |          1          5         16         20         35         40
*  Union   |          2         10         20         28         38         40
* ---------+------------------------------------------------------------------
*  Total   |          1          5         16         22         35         40
* ----------------------------------------------------------------------------
* 
*  union   |       p50        p75        p90        p95        p99        Max 
* ---------+------------------------------------------------------------------
* Nonunion |         40         40         48         50         60         80
*  Union   |         40         40         48         50         60         70
* ---------+------------------------------------------------------------------
*  Total   |         40         40         48         50         60         80
* ----------------------------------------------------------------------------
```

- Use the `statistics` option to return a specific set of statistics (including any percentile)

```
sumup hours, by(union) statistics(p80)
*  union   |       p80 
* ---------+-----------
* Nonunion |         40
*  Union   |         40
* ---------+-----------
*  Total   |         40
* ---------------------
```

- Use the `replace` or `save(...)` options to save the output table as a dataset



`sumup` is ten times faster than other programs with similar functionalities (e.g. `table, contents()` or `tabstat`).
 


# Installation
`sumup` is now available on SSC. 

```
ssc install sumup
```

To install the latest version from Github 
```
net install sumup, from("https://raw.githubusercontent.com/matthieugomez/sumup/master/")
```
