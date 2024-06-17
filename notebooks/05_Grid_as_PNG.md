Grid as PNG
================

Retrieve a grid from the Meteomatics Weather API and save it as png file

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
file1 <- paste0(filepath, "/grid_temperature_switzerland.png")
```

Input here the date and the time.

``` r
datetime <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                        month = as.integer(strftime(lubridate::today(), '%m')),
                        day = as.integer(strftime(lubridate::today(), '%d')) - 1,
                        hour = 00, min = 00, sec = 00, tz = "UTC")
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
lat_N <- 48
lon_W <- 6
lat_S <- 45.5
lon_E <- 10.5

resolution <- "1200x800" 
# you can also use following resolution resolution <- "0.1,0.1"
```

Choose the model you want to query

``` r
model <- "mix"
```

In the following, the request will start. If there is an error in the
request as for example a wrong parameter or a date that doesn’t exist,
you get a message.

``` r
query_grid_png(file1, datetime, parameter, lat_N, lon_W, lat_S, lon_E,
               resolution, username, password,
               model = model)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-16T00:00:00Z/t_2m:C/48,6_45.5,10.5:1200x800/png?model=mix

    ## [1] "Saved queried png image as /tmp/Rtmpzp9jdQ/grid_temperature_switzerland.png"

Your png file is now saved with the assigned name. If the picture is too
small, make the resolution smaller. Hence, there are more points on the
same distance and the picture gets bigger, but it also takes more time
to generate the picture.

``` r
library(knitr)
include_graphics(file1)
```

<img src="../../../../../tmp/Rtmpzp9jdQ/grid_temperature_switzerland.png" width="1200" />

``` r
file2 <- paste0(filepath, "/relative_humidity.png")

model <- "mix"


parameter <- "relative_humidity_2m:p"
lat_N <- 73
lon_W <- 0
lat_S <- 55
lon_E <- 35

resolution <- "1200x800"

query_grid_png(file2, datetime, parameter, lat_N, lon_W, lat_S, lon_E,
               resolution, username, password,
               model = model)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-16T00:00:00Z/relative_humidity_2m:p/73,0_55,35:1200x800/png?model=mix

    ## [1] "Saved queried png image as /tmp/Rtmpzp9jdQ/relative_humidity.png"

``` r
include_graphics(file2)
```

<img src="../../../../../tmp/Rtmpzp9jdQ/relative_humidity.png" width="1200" />
