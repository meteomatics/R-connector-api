Query Timeseries
================

Description Retrieve a time series from the Meteomatics Weather API

First you have to import the meteomatics module and the lubridate
library, the ggplot2 library is not necessary for the Query, but for the
example plot

``` r
suppressMessages(library(lubridate))
suppressMessages(library(MeteomaticsRConnector))
suppressMessages(library(ggplot2))
```

Input here your username and password from your meteomatics profile

``` r
username <- "r-community"
password <- "Utotugode673"
```

Input here a startdate, an enddate and the time interval, all as class
POSIXct. The interval tells you, if you get the data in hourly steps,
daily steps or every five minutes in between the startdate and the
enddate.

``` r
time_zone <- "UTC"
startdate <- as.POSIXct(format(Sys.time(), format="%Y-%m-%d %H:00:00"), tz=time_zone)
enddate <- as.POSIXct(format(Sys.time()+hours(24), format="%Y-%m-%d %H:00:00"), tz=time_zone)

interval <- "PT1H"
```

Specify the locations for your query

``` r
coordinates <- list(c(47.3,9.3))
```

Choose the parameters you want to get and put them into a list. Check
here which parameters are available:
<https://www.meteomatics.com/en/api/available-parameters/>

``` r
parameters <- list("t_2m:C", "precip_1h:mm", "dew_point_2m:C")
```

Choose the model you want to query

``` r
model <- "mix"
```

In the following, the request will start. If there is an error in the
request as for example a wrong parameter or a date that doesn’t exist,
you get a message. If the argument calibrated=TRUE is inserted,
observations are used to calibrate the model forecast.

``` r
data <- query_time_series(coordinates, startdate, enddate, interval, parameters,
                  username, password, model = model, calibrated = TRUE)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T16:00:00Z--2024-06-18T16:00:00Z:PT1H/t_2m:C,precip_1h:mm,dew_point_2m:C/47.3,9.3/csv?model=mix&calibrated=TRUE

You can now print the queried dataframe.

``` r
print(head(data))
```

    ##    lat lon           validdate t_2m.C precip_1h.mm dew_point_2m.C
    ## 1 47.3 9.3 2024-06-17 16:00:00   18.8         0.00           13.9
    ## 2 47.3 9.3 2024-06-17 17:00:00   16.9         0.18           13.8
    ## 3 47.3 9.3 2024-06-17 18:00:00   15.9         0.06           13.8
    ## 4 47.3 9.3 2024-06-17 19:00:00   17.0         2.22           10.7
    ## 5 47.3 9.3 2024-06-17 20:00:00   14.0         0.00           11.6
    ## 6 47.3 9.3 2024-06-17 21:00:00   15.2         0.00            8.6

You can use follwing code to plot the data in a simple meteogram

``` r
ylim.prim <- c(0, 30)   # in this example, precipitation
ylim.sec <- c(0,40)    # in this example, temperature
b <- diff(ylim.prim)/diff(ylim.sec)
a <- ylim.prim[1] - b*ylim.sec[1]

plot <- ggplot(data, aes(x= validdate)) +
  geom_col(aes(y= precip_1h.mm), fill="lightblue") +
  geom_line(aes(y = a + t_2m.C *b), color = "red") +
  geom_line(aes(y = a + dew_point_2m.C *b), color = "darkgreen") +

  scale_y_continuous("Precipitation [mm]", sec.axis = sec_axis(~ (. - a)/b, name = "Temperature / Dewpoint [°C]")) +
  ggtitle(paste0("Meteogram for Location:  ", coordinates[[1]][1], ", ", coordinates[[1]][2])) +
  xlab("")+
  theme_minimal()
```

![](demo_images/02_meteogram.png)
