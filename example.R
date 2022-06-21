#Meteomatics Weather API Connector - Examples


#Required packages: httr, data.table, lubridate, ggplot2, stringr.
#install.packages("")

source('R_query_api.R')


#Account data
username <- "r-community"
password <- "Utotugode673"

#Find out what the current account can do
limits <- query_user_features(username, password)
limits

#Set initial time data####
time_zone <- "Europe/Berlin"
startdate <- ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                        month = as.integer(strftime(today(),'%m')),
                        day = as.integer(strftime(today(),'%d')),
                        hour = 00, min = 00, sec = 00, tz = "UTC")
enddate <- ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                      month = as.integer(strftime(today(),'%m')),
                      day = as.integer(strftime(today(),'%d'))+1,
                      hour = 00, min = 00, sec = 00, tz = "UTC")
interval <- "PT1H"


#Query a Timeseries####
parameters <- "t_2m:C,relative_humidity_1000hPa:p"
coordinate <- "47.11,11.47"
#coordinate <- "47.11,11.47+50,10"
ts_output <- timeseries(startdate, enddate, interval, parameters, coordinate)
head(ts_output)

#Query ensemble Timeseries (needs upgraded account)####
#parameters <- "t_2m:C"
#coordinate <- "47.11,11.47"
#ts_output <- timeseries(startdate, enddate, interval, parameters, coordinate, model="ecmwf-vareps", ens_select="member:1-2")
#head(ts_output)

#Query ensemble Timeseries multiple coordinates (needs upgraded account)####
#parameters <- "t_2m:C"
#coordinate <- "47.11,11.47+46.11,10.47"
#ts_output <- timeseries(startdate, enddate, interval, parameters, coordinate, model="ecmwf-vareps", ens_select="member:1-2")
#head(ts_output)

#Grid####
parameter <- "t_2m:C"
coordinate <- "48.5,5.5_45.5,11.5:800x600"
grid_output <- grid(startdate, parameter, coordinate)
head(grid_output)

#Grid with esemble members####
#parameter <- "t_2m:C"
#coordinate <- "48.5,5.5_45.5,11.5:80x60"
#grid_output <- grid(startdate, parameter, coordinate, model="ecmwf-vareps", ens_select="member:1-2")
#head(grid_output)

#Pivot Grid####
parameter <- "t_2m:C" #only one parameter
coordinate <- "48.5,5.5_45.5,11.5:5x5" #Rectangle
pivot_grid <- grid_pivot(startdate, parameter, coordinate)
head(pivot_grid)

#Timeseries grid####
parameter <- "t_2m:C"
coordinate <- "50,0_40,20:500x300"
interval <- "PT12H"
timeseries_grid_output <- timeseries_grid(startdate, enddate, interval, parameter, coordinate)
head(timeseries_grid_output)

#Get a list of lightning strikes####
time_range="2019-07-07T12:00:00ZPT2S"
bounding_box="50,10_40,20"
ls <- lightning_strikes(time_range, bounding_box)
head(ls)

#save timeseries grid as .netcdf####
parameters = "t_2m:C"
coordinate = "90,-180_-90,180:600x400"
startdate <- ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                         month = as.integer(strftime(today(),'%m')),
                         day = as.integer(strftime(today(),'%d')),
                         hour = 00, min = 00, sec = 00, tz = "UTC")
duration = "PT3H"
interval = "PT1H"
save_netcdf(startdate, duration, interval, parameters, coordinate)

#safe grads plot####
parameters <- "t_500hPa:C,gh_500hPa:m"
coordinate <- "70,-15_35,30:0.1,0.1"
save_grads_plot(startdate, parameters, coordinate)

#Find stations####
location <- "location=47.3,9.3"
parameters <- "parameters=t_2m:C" #parameters=<comma separated parameter list>
stations <- find_station(location, parameters)
head(stations)

#Query a timeseries for a weather station with certain coordinates if possible####
startdate <- ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                        month = as.integer(strftime(today(),'%m')),
                        day = as.integer(strftime(today(),'%d'))-1,
                        hour = 00, min = 00, sec = 00, tz = "UTC")
enddate <- ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                      month = as.integer(strftime(today(),'%m')),
                      day = as.integer(strftime(today(),'%d')),
                      hour = 00, min = 00, sec = 00, tz = "UTC")
interval <- "PT1H"
parameters <- "t_2m:C,relative_humidity_2m:p"
coordinate <- "47.43,9.4"
stations_timeseries <- station_timeseries(startdate, enddate, interval, parameters, coordinate)
head(stations_timeseries)


#Query a timeseries for a weather station with certain IDs####
startdate = ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                        month = as.integer(strftime(today(),'%m')),
                        day = as.integer(strftime(today(),'%d'))-1,
                        hour = 00, min = 00, sec = 00, tz = "UTC")
enddate = ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                      month = as.integer(strftime(today(),'%m')),
                      day = as.integer(strftime(today(),'%d')),
                      hour = 00, min = 00, sec = 00, tz = "UTC")
interval <- "PT3H"
parameters = "t_2m:C,relative_humidity_2m:p"
station <- "wmo_066810"
timeseries_station_id(startdate, enddate, interval, parameters, station)

#Get latest initial times####
parameters <- "t_2m:C,relative_humidity_2m:p"
model <- "ecmwf-ifs"
startdate = ISOdatetime(year = as.integer(strftime(today(),'%Y')),
                        month = as.integer(strftime(today(),'%m')),
                        day = as.integer(strftime(today(),'%d')),
                        hour = 00, min = 00, sec = 00, tz = "UTC")
date <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
init_dates(model, date, parameters)


#Get available time range####
model <- "ecmwf-ifs"
paramters <- "global_rad:W,t_2m:C"
available_time_range(model,parameters)
