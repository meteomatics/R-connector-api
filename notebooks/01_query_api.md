Query API
================

Query the Metematics API with an self-created URL and save the output
with different formats.

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

Specify the output directory for your query.

``` r
outputdir <- paste0(tempdir(), "/test_query.csv")
```

Input here the date and the time as class POSIXct.

``` r
datetime <- strftime(ISOdatetime(year=as.integer(strftime(lubridate::today(),'%Y')),
                                 month=as.integer(strftime(lubridate::today(),'%m')),
                                 day=as.integer(strftime(lubridate::today(),'%d')),
                                 hour = 00, min = 00, sec = 00, tz = 'UTC'),
                     format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
```

Meteomatics provides an easy access to weather data in all formats via
URL building. Explore our URL creator:
<https://www.meteomatics.com/en/api/url-creator/>

``` r
# In this example 2m temperature for today 00 UTC will be queried at location 52.520551,13.461804. The output file is set to csv.

url <- paste0(sprintf('https://%s:%s@api.meteomatics.com/', username, password),
                      datetime, '/t_2m:C/52.520551,13.461804/csv')
```

In the following, the request will start. If there is an error in the
request as for example a wrong parameter or a date that doesn’t exist,
you get a message.

``` r
data <- query_api(url, username, password, output_dir = outputdir)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T00:00:00Z/t_2m:C/52.520551,13.461804/csv

This is further example for fetching temperature date, but now for the
800hPa level and in Kelvin units. The output from the Meteomatics Mix
model is saved to a .json file.

``` r
outputdir <- paste0(tempdir(), "/test_query.json")

url <- paste0(sprintf('https://%s:%s@api.meteomatics.com/', username, password),
                      datetime, '/t_800hPa:K/51.5073219,-0.1276474+47.4236,9.3622/json?model=mix')

query_api(url, username, password, output_dir = outputdir)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T00:00:00Z/t_800hPa:K/51.5073219,-0.1276474+47.4236,9.3622/json?model=mix

    ## Response [https://r-community:Utotugode673@api.meteomatics.com/2024-06-17T00:00:00Z/t_800hPa:K/51.5073219,-0.1276474+47.4236,9.3622/json?model=mix]
    ##   Date: 2024-06-17 09:28
    ##   Status: 200
    ##   Content-Type: application/json; charset=utf-8
    ##   Size: 319 B
    ## <ON DISK>  /tmp/Rtmpre7nMM/test_query.json
