Grid
================

Here you can get a grid of one parameter over a certain area at exaclty
one time step. As output you get a dataframe, that contains the
latitude, longitude and the selected parameters as columns

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

Input here the date and the time as class POSIXct.

``` r
startdate_grid <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
                         month = as.integer(strftime(lubridate::today(), '%m')),
                         day = as.integer(strftime(lubridate::today(), '%d')),
                         hour = 06, min = 00, sec = 00, tz = 'UTC')
```

Choose the parameter you want to get. You can only chose one parameter
at a time. Check here which parameters are available:
<https://www.meteomatics.com/en/api/available-parameters/>

``` r
parameter_grid = list('low_cloud_cover:p')
```

Input here the limiting coordinates of the extract you want to look at.
You can also change the resolution.

``` r
lat_N <- 50
lon_W <- -15
lat_S <- 20
lon_E <- 10
resolution <- "2,2" # or "2x2"
```

Choose the model you want to query. The default value is NULL, meaning
that the model mix is selected.

``` r
model = "mix"
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
df_grid <- query_grid(datetime = startdate_grid, parameters = parameter_grid, lat_N,  lon_W, lat_S,  lon_E, resolution, model=model, username, password)
```

    ## Calling URL:
    ##  https://api.meteomatics.com/2024-06-17T06:00:00Z/low_cloud_cover:p/50,-15_20,10:2,2/csv?model=mix

``` r
print(df_grid)
```

    ## [[1]]
    ##    lat/lon   -15   -13   -11    -9    -7    -5   -3    -1     1     3    5
    ## 1       50  31.2  25.8  24.2  21.9   1.6   2.3 11.7  10.9   8.6 100.0 99.2
    ## 2       48  14.8  16.4  81.2  84.4  49.2 100.0 65.6 100.0 100.0  44.5 32.0
    ## 3       46 100.0  22.7 100.0  13.3 100.0 100.0 93.0  98.4   4.7  32.8  0.0
    ## 4       44  31.2  42.2  10.2 100.0  85.9   1.6  0.0  15.6   2.3  14.1  0.0
    ## 5       42  32.8  28.9 100.0 100.0 100.0   7.0  0.0   0.0   0.0   4.7  0.0
    ## 6       40   4.7  96.1  11.7 100.0   5.5   0.0  0.0   0.0  11.7   0.0  0.0
    ## 7       38 100.0   0.0  28.1   3.9   0.0   0.0  0.0  93.8  19.5   0.0  0.0
    ## 8       36  53.9  31.2  28.1  25.8   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 9       34 100.0 100.0  78.9  25.0  89.8   0.0  0.0   0.0   0.0   0.0  0.0
    ## 10      32 100.0 100.0  64.8  81.2   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 11      30  47.7  67.2   7.0   0.0   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 12      28  89.8  48.4  95.3   0.0   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 13      26  85.2   9.4  51.6   0.0   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 14      24   0.0   0.0   0.0   0.0   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 15      22   0.0   0.0   0.0   0.0   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ## 16      20   0.0   0.0   0.0   0.0   0.0   0.0  0.0   0.0   0.0   0.0  0.0
    ##        7     9
    ## 1   43.8 100.0
    ## 2   36.0   0.0
    ## 3  100.0   0.0
    ## 4    0.8  37.5
    ## 5    0.0   0.0
    ## 6    0.0   0.0
    ## 7    0.0   0.0
    ## 8    0.0   0.0
    ## 9    0.0   0.0
    ## 10   0.0   0.0
    ## 11   0.0   0.0
    ## 12   0.0   0.0
    ## 13   0.0   0.0
    ## 14   0.0   0.0
    ## 15   0.0   0.0
    ## 16   0.0   0.0

``` r
# Convert list to a single data frame
df <- do.call(rbind, df_grid)
# Extract values into a matrix
mat <- as.matrix(df[, -1])  # Exclude the first column (lat/lon)
# Optionally, you can set row names and column names
row_names <- df$`lat/lon`
col_names <- as.numeric(colnames(df)[-1])  # Exclude the first column name
rownames(mat) <- row_names
colnames(mat) <- col_names

grid_df <- as.data.frame(mat)
```

Now you can work on the data by using R commands. Here are some examples
how you can access to the different datapoints.

``` r
maximum <- max(grid_df)
minimum <- min(grid_df)
mean <- sapply(grid_df, mean, na.rm = TRUE)


at_this_location = grid_df["46","-15"]
print(at_this_location)
```

    ## [1] 100

``` r
at_this_longitude = grid_df[,"-13"]
print(at_this_longitude)
```

    ##  [1]  25.8  16.4  22.7  42.2  28.9  96.1   0.0  31.2 100.0 100.0  67.2  48.4
    ## [13]   9.4   0.0   0.0   0.0

``` r
at_this_latitude = grid_df["46",]
print(at_this_latitude)
```

    ##    -15  -13 -11   -9  -7  -5 -3   -1   1    3 5   7 9
    ## 46 100 22.7 100 13.3 100 100 93 98.4 4.7 32.8 0 100 0
