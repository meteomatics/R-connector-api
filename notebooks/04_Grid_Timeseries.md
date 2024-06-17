Grid Timeseries
================

This query provides you a grid of selected parameters (timeseries) over
a certain area. As output you get a dataframe. The dataframe contains
the Lat/Lon corrdinates, the date and the selected parameters as
columns.

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

Here we need a startdate, an enddate and the time interval, all as
datetime-objects. The interval tells you, if you get the data in hourly
steps, daily steps or every five minutes in between the startdate and
the enddate.

``` r
startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                         month = as.integer(strftime(lubridate::today(), '%m')),
                         day = as.integer(strftime(lubridate::today(), '%d'))-1,
                         hour = 06, min = 00, sec = 00, tz = 'UTC')

enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                       month = as.integer(strftime(lubridate::today(), '%m')),
                       day = as.integer(strftime(lubridate::today(), '%d')),
                       hour = 06, min = 00, sec = 00, tz = 'UTC')

interval <- "PT1H"
```

Choose the parameters and model you want to get and write them in the
list. Check here which parameters are available:
<https://www.meteomatics.com/en/api/available-parameters/>

``` r
# A list of strings containing the parameters of interest list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p", "precip_1h:mm").
parameters <- list("t_2m:C", "precip_1h:mm")

    
# A character vector containing the model of interest. The default value is NULL, meaning that the model mix is selected.
model <- "mix"
```

Input here the limiting coordinates of the extract you want to look at.
You can also change the resolution.

``` r
lat_N <- 50
lon_W <- -5
lat_S <- 40
lon_E <- 5
resolution <- "3,4" # or "2x2"
```

There are additional arguments possible for the query:

``` r
# A character vector containing the ensembles of interest. The default value is NULL. Possible inputs are for example: "median"; "member:5"; "member:1-50"; "member:0"; "mean"; "quantile0.2".
ens_select <- NULL 

# A character vector specifying the interpolation: The default value is NULL. A possible input is: "gradient_interpolation"
interp_select <- NULL

#A character vector containing the cluster of interest. The default value is NULL. Possible inputs are for example: "cluster:1"; "cluster:1-6"
cluster_select <- NULL

#A character vector specifying the treatment of missing weather station values. The default value is NULL. If on_invalid = "fill_with_invalid", missing values are filled with Na.
on_invalid <- NULL
```

In the following, the request will start. If there is an error in the
request as for example a wrong parameter or a date that doesn’t exist,
you get a message.

``` r
df_grid <- query_grid_timeseries(startdate, enddate, interval, parameters, lat_N, lon_W, lat_S, lon_E, resolution, username, password, model)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-16T06:00:00Z--2024-06-17T06:00:00Z:PT1H/t_2m:C,precip_1h:mm/50,-5_40,5:3,4/csv?model=mix

``` r
print(head(df_grid))
```

    ##   lat lon           validdate t_2m:C precip_1h:mm
    ## 1  40  -5 2024-06-16 06:00:00   14.4            0
    ## 2  40  -5 2024-06-16 07:00:00   17.5            0
    ## 3  40  -5 2024-06-16 08:00:00   19.9            0
    ## 4  40  -5 2024-06-16 09:00:00   22.1            0
    ## 5  40  -5 2024-06-16 10:00:00   24.0            0
    ## 6  40  -5 2024-06-16 11:00:00   25.6            0

Now you can investigate the recieved data

``` r
# get the location and timestep of the highest temperature:

# Check for NA or NaN values in the t_2m:C column
df_grid <- df_grid[!is.na(df_grid$`t_2m:C`), ]

# Find the row with the maximum t_2m:C
max_row <- df_grid[which.max(df_grid$`t_2m:C`), ]

# Print the result
cat("Latitude:", max_row$lat, ", Longitude:", max_row$lon, ", Time:", format(max_row$validdate, format = "%Y-%m-%d %H:%M:%S"))
```

    ## Latitude: 40 , Longitude: -5 , Time: 2024-06-16 15:00:00

Or you can filter the data for specific hours

``` r
specific_hour <- df_grid[df_grid$validdate == enddate,]
print(specific_hour)
```

    ##     lat lon           validdate t_2m:C precip_1h:mm
    ## 25   40  -5 2024-06-17 06:00:00   15.8         0.00
    ## 50   40  -1 2024-06-17 06:00:00   17.4         0.00
    ## 75   40   3 2024-06-17 06:00:00   21.3         0.00
    ## 100  43  -5 2024-06-17 06:00:00   10.9         0.00
    ## 125  43  -1 2024-06-17 06:00:00   12.6         0.00
    ## 150  43   3 2024-06-17 06:00:00   18.9         0.00
    ## 175  46  -5 2024-06-17 06:00:00   16.6         4.19
    ## 200  46  -1 2024-06-17 06:00:00   17.2         0.00
    ## 225  46   3 2024-06-17 06:00:00   13.7         4.94
    ## 250  49  -5 2024-06-17 06:00:00   13.6         0.00
    ## 275  49  -1 2024-06-17 06:00:00   13.3         0.00
    ## 300  49   3 2024-06-17 06:00:00   15.2         0.00
