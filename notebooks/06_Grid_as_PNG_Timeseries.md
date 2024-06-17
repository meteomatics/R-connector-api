Grid as PNG Timeseries
================

Retrieve a time series on a grid from the Meteomatics Weather API

First you have to import the meteomatics module and the lubridate
library

``` r
suppressMessages(library(lubridate))
suppressMessages(library(MeteomaticsRConnector))
```

Input here your username and password from your meteomatics profile

``` r
username <- "r-community"
password <- "Utotugode673"
```

Input here the name that your png-file should get.

``` r
filepath <-  tempdir()
```

Input here the date and the time.

``` r
startdate <- as.POSIXct(format(Sys.time(),format="%Y-%m-%d %H:00:00"), tz="UTC")
enddate <- as.POSIXct(lubridate::today() + lubridate::hours(23), tz = "UTC")

interval <- lubridate::hours(3)
```

Choose the parameters and model you want to get and write them in the
list. Check here which parameters are available:
<https://www.meteomatics.com/en/api/available-parameters/>

``` r
parameter <- "t_2m:C"
```

Input here the limiting coordinates of the extract you want to look at.
You can also change the resolution.

``` r
lat_N = 35.5
lon_W = 68
lat_S = 7.9
lon_E = 97

resolution <- "400x600"
```

Choose the model you want to query

``` r
model <- "mix"
```

In the following, the request will start. If there is an error in the
request as for example a wrong parameter or a date that doesn’t exist,
you get a message.

``` r
query_png_timeseries(filepath, startdate, enddate, interval, parameter, lat_N,
                     lon_W, lat_S, lon_E, resolution, username, password, model)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T11:00:00Z/t_2m:C/35.5,68_7.9,97:400x600/png?model=mix 
    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T14:00:00Z/t_2m:C/35.5,68_7.9,97:400x600/png?model=mix 
    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T17:00:00Z/t_2m:C/35.5,68_7.9,97:400x600/png?model=mix 
    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T20:00:00Z/t_2m:C/35.5,68_7.9,97:400x600/png?model=mix 
    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T23:00:00Z/t_2m:C/35.5,68_7.9,97:400x600/png?model=mix

    ## [1] "Saved queried png images within /tmp/RtmpfGNYLb"

``` r
library(knitr)

filelist <- list.files(filepath,"*.png")

include_graphics(paste0(filepath, "/", filelist[1]))
```

<img src="../../../../../tmp/RtmpfGNYLb/t_2m_C_20240617_110000.png" width="400" />

``` r
include_graphics(paste0(filepath, "/", filelist[2]))
```

<img src="../../../../../tmp/RtmpfGNYLb/t_2m_C_20240617_140000.png" width="400" />

``` r
include_graphics(paste0(filepath, "/", filelist[3]))
```

<img src="../../../../../tmp/RtmpfGNYLb/t_2m_C_20240617_170000.png" width="400" />
