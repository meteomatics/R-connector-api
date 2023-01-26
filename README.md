
<!-- README.md is generated from README.Rmd. Please edit that file -->

[![logo](https://static.meteomatics.com/meteomatics-logo.png)](https://www.meteomatics.com)

# R connector to the [Meteomatics API](https://api.meteomatics.com/Overview.html "Documentation Overwiev")

<!-- badges: start -->
<!-- badges: end -->

===================================================================================

Meteomatics provides a REST-style API to retrieve historic, current, and
forecast data globally. This includes model data and observational data
in time series and areal formats. Areal formats are also offered through
a WMS/WFS-compatible interface. Geographic and time series data can be
combined in certain file formats, such as NetCDF.

## Installation

You can install the development version of MeteomaticsRConnector from
[GitHub](https://github.com/meteomatics/R-connector-api) directly within
your R session with:

``` r
# install.packages("devtools")
devtools::install_github("meteomatics/R-connector-api")
```

Alternatively, you can clone the git repository to a local directory of
your choice, open the installed R project by clicking on
MeteomaticsRConnector.Rproj and install the package by clicking on
“Build” and then “Install Package”.

## Requirements

The following external R functions are required and need to be
installed:
`httr, data.table, lubridate, stringr, jsonlite, sets, tidyr, utils, rlist`.

## Examples

This is a basic example on how to use the
`MeteomaticsRConnector::query_api()` function:

``` r
library(MeteomaticsRConnector)

## Insert the Meteomatics API username and password
username <- 'r-community'
password <- 'Utotugode673'

## Specify the date and time
datetime <- strftime(ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                                 month = as.integer(strftime(lubridate::today(), '%m')),
                                 day = as.integer(strftime(lubridate::today(), '%d')),
                                 hour = 00, min = 00, sec = 00, tz = 'UTC'),
                     format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')

## Create your final URL to query the 2m temperature in Berlin from the Meteomatics API
url <- paste0(sprintf('https://%s:%s@api.meteomatics.com/', username, password),
                      datetime, '/t_2m:C/52.520551,13.461804/csv')

## Call the MeteomaticsRConnector::query_api() function
query_api(url, username, password)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2023-01-25T00:00:00Z/t_2m:C/52.520551,13.461804/csv

    ## Response [https://r-community:Utotugode673@api.meteomatics.com/2023-01-25T00:00:00Z/t_2m:C/52.520551,13.461804/csv]
    ##   Date: 2023-01-25 15:35
    ##   Status: 200
    ##   Content-Type: text/csv; charset=utf-8
    ##   Size: 43 B
    ## validdate;t_2m:C
    ## 2023-01-25T00:00:00Z;-0.2

This is a basic example on how to use the
`MeteomaticsRConnector::query_time_series()` function:

``` r
library(MeteomaticsRConnector)

## Insert the Meteomatics API username and password
username <- 'r-community'
password <- 'Utotugode673'

## Specify the coordinates of interest
coordinates <- list(c(47.3,9.3), c(47.43,9.4))

## Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                         month = as.integer(strftime(lubridate::today(), '%m')),
                         day = as.integer(strftime(lubridate::today(), '%d')),
                         hour = 00, min = 00, sec = 00, tz = 'UTC')
enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                       month = as.integer(strftime(lubridate::today(), '%m')),
                       day = as.integer(strftime(lubridate::today(), '%d')) + 1,
                       hour = 00, min = 00, sec = 00, tz = 'UTC')

## Specify a time interval
interval <- "PT1H"

## Specify the parameter(s) of interest
parameters <- list("t_2m:C", "precip_1h:mm")

## Call the MeteomaticsRConnector::query_time_series() function
query_time_series(coordinates, startdate, enddate, interval, parameters,
                  username, password)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2023-01-25T00:00:00Z--2023-01-26T00:00:00Z:PT1H/t_2m:C,precip_1h:mm/47.3,9.3+47.43,9.4/csv?

    ##      lat lon           validdate t_2m:C precip_1h:mm
    ## 1  47.30 9.3 2023-01-25 00:00:00   -4.2            0
    ## 2  47.30 9.3 2023-01-25 01:00:00   -4.5            0
    ## 3  47.30 9.3 2023-01-25 02:00:00   -4.5            0
    ## 4  47.30 9.3 2023-01-25 03:00:00   -4.2            0
    ## 5  47.30 9.3 2023-01-25 04:00:00   -4.7            0
    ## 6  47.30 9.3 2023-01-25 05:00:00   -4.6            0
    ## 7  47.30 9.3 2023-01-25 06:00:00   -3.6            0
    ## 8  47.30 9.3 2023-01-25 07:00:00   -4.1            0
    ## 9  47.30 9.3 2023-01-25 08:00:00   -3.5            0
    ## 10 47.30 9.3 2023-01-25 09:00:00   -3.4            0
    ## 11 47.30 9.3 2023-01-25 10:00:00   -2.0            0
    ## 12 47.30 9.3 2023-01-25 11:00:00   -2.8            0
    ## 13 47.30 9.3 2023-01-25 12:00:00   -2.4            0
    ## 14 47.30 9.3 2023-01-25 13:00:00   -2.1            0
    ## 15 47.30 9.3 2023-01-25 14:00:00   -1.8            0
    ## 16 47.30 9.3 2023-01-25 15:00:00   -2.1            0
    ## 17 47.30 9.3 2023-01-25 16:00:00   -2.6            0
    ## 18 47.30 9.3 2023-01-25 17:00:00   -3.5            0
    ## 19 47.30 9.3 2023-01-25 18:00:00   -3.9            0
    ## 20 47.30 9.3 2023-01-25 19:00:00   -4.1            0
    ## 21 47.30 9.3 2023-01-25 20:00:00   -4.2            0
    ## 22 47.30 9.3 2023-01-25 21:00:00   -4.4            0
    ## 23 47.30 9.3 2023-01-25 22:00:00   -5.0            0
    ## 24 47.30 9.3 2023-01-25 23:00:00   -5.2            0
    ## 25 47.30 9.3 2023-01-26 00:00:00   -5.5            0
    ## 26 47.43 9.4 2023-01-25 00:00:00   -2.3            0
    ## 27 47.43 9.4 2023-01-25 01:00:00   -2.8            0
    ## 28 47.43 9.4 2023-01-25 02:00:00   -2.7            0
    ## 29 47.43 9.4 2023-01-25 03:00:00   -2.2            0
    ## 30 47.43 9.4 2023-01-25 04:00:00   -2.0            0
    ## 31 47.43 9.4 2023-01-25 05:00:00   -2.1            0
    ## 32 47.43 9.4 2023-01-25 06:00:00   -2.4            0
    ## 33 47.43 9.4 2023-01-25 07:00:00   -2.6            0
    ## 34 47.43 9.4 2023-01-25 08:00:00   -3.6            0
    ## 35 47.43 9.4 2023-01-25 09:00:00   -1.8            0
    ## 36 47.43 9.4 2023-01-25 10:00:00   -0.8            0
    ## 37 47.43 9.4 2023-01-25 11:00:00   -0.2            0
    ## 38 47.43 9.4 2023-01-25 12:00:00    0.1            0
    ## 39 47.43 9.4 2023-01-25 13:00:00    0.7            0
    ## 40 47.43 9.4 2023-01-25 14:00:00    1.0            0
    ## 41 47.43 9.4 2023-01-25 15:00:00    0.9            0
    ## 42 47.43 9.4 2023-01-25 16:00:00    0.4            0
    ## 43 47.43 9.4 2023-01-25 17:00:00    0.3            0
    ## 44 47.43 9.4 2023-01-25 18:00:00    0.2            0
    ## 45 47.43 9.4 2023-01-25 19:00:00    0.1            0
    ## 46 47.43 9.4 2023-01-25 20:00:00   -0.2            0
    ## 47 47.43 9.4 2023-01-25 21:00:00   -0.5            0
    ## 48 47.43 9.4 2023-01-25 22:00:00   -0.8            0
    ## 49 47.43 9.4 2023-01-25 23:00:00   -1.1            0
    ## 50 47.43 9.4 2023-01-26 00:00:00   -1.5            0

For a start, we recommend to read the documentation of each function,
where additional examples on how to use the R connector are provided. To
read the documentation e.g. for the
`MeteomaticsRConnector::query_time_series()` function write:

``` r
library(MeteomaticsRConnector)
?MeteomaticsRConnector::query_time_series
```
