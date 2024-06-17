Query a Grid with geoTIFF as Output Format
================

Description Retrieve a grid from the Meteomatics Weather API and save it
as geoTIFF file

First you have to import the meteomatics module and the lubridate
library, the ggplot2 library is not necessary for the Query, but for the
example plot

``` r
suppressMessages(library(lubridate))
suppressMessages(library(MeteomaticsRConnector))
```

Input here your username and password from your meteomatics profile

``` r
username <- "r-community"
password <- "Utotugode673"
```

Create a directory and specify the filename for saving the .tiff file

``` r
dir <- tempdir()
filename <- paste(dir, "grid.tiff", sep = "/")
```

Insert here the date as class POSIXct

``` r
datetime <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                        month = as.integer(strftime(lubridate::today(), '%m')),
                        day = as.integer(strftime(lubridate::today(), '%d')) - 1,
                        hour = 00, min = 00, sec = 00, tz = "UTC")
```

Choose the parameters you want to get and put them into a list. Check
here which parameters are available:
<https://www.meteomatics.com/en/api/available-parameters/>

``` r
parameter <- "t_2m:C"
```

Input here the limiting coordinates of the extract you want to look at.
You can also change the resolution.

``` r
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180
resolution <- "400x600"
```

Choose the model you want to query

``` r
model <- "mix"
```

In the following, the request will start. If there is an error in the
request as for example a wrong parameter or a date that doesn’t exist,
you get a message. With the additional argument
cbar=“geotiff_magenta_blue” you can specify your desired colorbar

``` r
query_geotiff(filename, datetime, parameter, lat_N, lon_W, lat_S, lon_E,
              resolution, username, password, model, cbar = "geotiff_magenta_blue")
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-16T00:00:00Z/t_2m:C/90,-180_-90,180:400x600/geotiff_magenta_blue?model=mix

    ## [1] "Saved queried geoTIFF image as /tmp/RtmpIIY7rd/grid.tiff"

To view the geoTIFF file in R you can use different packages such as
terra, raster or stars. In the following the raster package is used to
read the file from the tempdir

``` r
library(raster)
```

    ## Loading required package: sp

``` r
raster_data <- raster(filename)
plot(raster_data)
```

![](13_Query_geotiff_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->
