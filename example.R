################################################################################
# --------------- Meteomatics Weather API Connector - Examples --------------- #
################################################################################
# Required packages: httr, data.table, lubridate, grid, stringr.
# use the command install.packages("") to install the missing R packages

# -> data.table might not work properly on Mac anymore
# ------------------------------------------------------------------------------
# Load the script containing the functions to connect to the API
source('R_query_api.R')

# ------------------------------------------------------------------------------
# -------------------------------- Account data --------------------------------
# ------------------------------------------------------------------------------
# Insert the meteomatics api username and password
username <- "r-community"   
password <- "Utotugode673"

# ------------------------------------------------------------------------------
# Find out what the current account can do -> in future versions no longer supported
features <- query_user_features(username, password)
features

# ------------------------------------------------------------------------------
# Find out what the current request limits are
limits <- query_user_limits(username, password)
limits

# ------------------------------------------------------------------------------
# ----------------------------- Query a Timeseries -----------------------------
# ------------------------------------------------------------------------------
# Define a time zone
#time_zone <- "Europe/Berlin"
#time_zone <- "Europe/Zurich"
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval
interval <- "PT1H"

# Specify the desired parameters (all following options are possible input formats)
# parameters <- "t_2m:C"
# parameters <- "t_2m:C,precip_1h:mm"
# parameters <- "gh_500hPa:m" #e.g. available for clusters
parameters <- c("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p", "precip_1h:mm")

# Specify the desired coordinate/station ids  (all following options are examples of possible input formats)
# coordinates <- "47.3,9.3"
# coordinates <- c("47.3,9.3", "47.43,9.4")
# coordinates <- "47.11,11.47+50,10"
# coordinates <- "postal_CH9000"
# coordinates <- c("postal_CH9000", "postal_CH9014")
# coordinates <- c("47.3,9.3", "postal_CH9000")
coordinates <- list(c(47.3,9.3), c(47.43,9.4))

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:1-50"; 
#                          "member:0"; "mean"; "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"
# ens_select <- "member:1-50"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1"; cluster:1-6; 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Call the timeseries function
ts_output <- query_time_series(coordinate_list = coordinates, startdate = startdate, 
                               enddate = enddate, interval = interval, parameters = parameters, 
                               username = username, password = password, model = model, 
                               ens_select = ens_select, interp_select = interp_select, 
                               on_invalid = "fill_with_invalid",request_type = "GET", 
                               cluster_select = cluster_select, calibrated = TRUE)

# Print the head of the data (first few rows)
head(ts_output)

# ------------------------------------------------------------------------------
# -------------------------------- Query a Grid --------------------------------
# ------------------------------------------------------------------------------
# Define a time zone
time_zone <- "UTC"

# Specify the exact time
datetime <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                        month = as.integer(strftime(today(), '%m')), 
                        day = as.integer(strftime(today(), '%d')) - 1, 
                        hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired parameter
# parameter <- "t_2m:C"
# parameter <- "gh_500hPa:m" #e.g. available for clusters
parameter <- "evapotranspiration_1h:mm"

# Specify the desired grid
lat_N <- 50
lon_W <- -15
lat_S <- 20
lon_E <- 10

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
# res_lat <- NULL
res_lat <- 3 #resolution
# res_lon <- NULL
res_lon <- 3 #resolution

num_lat <- NULL #number of lats
# num_lat <- 100
num_lon <- NULL #number of lons
# num_lon <- 100

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:1-50"; 
#                          "member:0"; "mean"; "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1"; cluster:1-6; 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Call the grid function
grid_output <- query_grid(datetime = datetime, parameter_grid = parameter, 
                          lat_N = lat_N, lon_W = lon_W, lat_S = lat_S, lon_E = lon_E,
                          res_lat = res_lat, res_lon = res_lon, num_lat = num_lat, 
                          num_lon = num_lon, username = username, password = password, 
                          model = model, ens_select = ens_select, interp_select = interp_select, 
                          cluster_select = cluster_select, on_invalid = "fill_with_invalid", 
                          request_type = "GET", calibrated = TRUE)

# Print the head of the data (first few rows)
head(grid_output)

# ------------------------------------------------------------------------------
# ------------------------ Query a png Image of a Grid -------------------------
# ------------------------------------------------------------------------------
# Specify the directory and filename of the output file
filename <- paste("/your/desired/directory", "grid.png", sep = "/")

# Define a time zone
time_zone <- "UTC"

# Specify the exact time
datetime <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                        month = as.integer(strftime(today(), '%m')), 
                        day = as.integer(strftime(today(), '%d')) - 1, 
                        hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired parameter
parameter <- "t_2m:C"
# parameter <- "gh_500hPa:m" #e.g. available for clusters
# parameter <- "evapotranspiration_1h:mm"

# Specify the desired grid
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
res_lat <- NULL #resolution
# res_lat <- 3 
res_lon <- NULL #resolution
# res_lon <- 3 

# num_lat <- NULL 
num_lat <- 400 #number of lats
# num_lon <- NULL 
num_lon <- 600 #number of lons

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:0"; "mean"; 
#                                       "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1" 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Call the grid function
query_grid_png(filename, datetime, parameter, lat_N, lon_W, 
               lat_S, lon_E, res_lat, res_lon, num_lat, num_lon, username,
               password, model = model, ens_select = ens_select, 
               cluster_select = cluster_select, interp_select = interp_select,
               calibrated = TRUE)

# ------------------------------------------------------------------------------
# ------------------------ Query a Timeseries on a Grid ------------------------
# ------------------------------------------------------------------------------
# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired parameter
# parameters <- "t_2m:C"
parameters <- "evapotranspiration_1h:mm"
# parameters <- c("t_2m:C", "evapotranspiration_1h:mm")
# parameters <- "gh_500hPa:m" #e.g. available for clusters

# Specify the desired interval
interval <- "PT1H"

# Specify the desired grid
lat_N <- 50
lon_W <- -15
lat_S <- 20
lon_E <- 10

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
# res_lat <- NULL
res_lat <- 3 #resolution
# res_lon <- NULL
res_lon <- 3 #resolution

num_lat <- NULL #number of lats
# num_lat <- 100
num_lon <- NULL #number of lons
# num_lon <- 100

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:1-50"; 
#                          "member:0"; "mean"; "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1"; cluster:1-6; 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Call the grid function
timeseries_grid_output <- query_grid_timeseries(startdate = startdate, enddate = enddate,
                                                interval = interval, parameters = parameters,
                                                lat_N = lat_N, lon_W = lon_W, 
                                                lat_S = lat_S, lon_E = lon_E, 
                                                res_lat = res_lat, res_lon = res_lon,
                                                num_lat = num_lat, num_lon = num_lon, 
                                                username = username, password = password, 
                                                model = model, ens_select = ens_select, 
                                                interp_select = interp_select, 
                                                cluster_select = cluster_select,
                                                on_invalid = "fill_with_invalid", 
                                                request_type = "GET", calibrated = TRUE)

# Print the head of the data (first few rows)
head(timeseries_grid_output)

# ------------------------------------------------------------------------------
# ----------------- Query png Images of a Timeseries on a Grid -----------------
# ------------------------------------------------------------------------------
# Specify the directory and filename of the output file
filepath <- "/your/desired/directory"

# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval (needs to be e.g. hours(1); days(1); minutes(60),...)
interval <- hours(1)

# Specify the desired parameter (only 1 parameter per query)
parameter <- "t_2m:C"
# parameter <- "gh_500hPa:m" #e.g. available for clusters
# parameter <- "evapotranspiration_1h:mm"

# Specify the desired grid
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
res_lat <- NULL #resolution
# res_lat <- 3 
res_lon <- NULL #resolution
# res_lon <- 3 

# num_lat <- NULL 
num_lat <- 400 #number of lats
# num_lon <- NULL 
num_lon <- 600 #number of lons

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:0"; "mean"; 
#                                       "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1" 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Call the grid function
query_png_timeseries(filepath, startdate, enddate, interval, parameter, lat_N, 
                     lon_W, lat_S, lon_E, res_lat, res_lon, num_lat, num_lon, 
                     username, password, model, ens_select, interp_select,
                     cluster_select, calibrated = TRUE)

# ------------------------------------------------------------------------------
# ---------------------- Query a geoTIFF Image of a Grid -----------------------
# ------------------------------------------------------------------------------
# Specify the directory and filename of the output file
filename <- paste("/your/desired/directory", "grid.tiff", sep = "/")

# Define a time zone
time_zone <- "UTC"

# Specify the exact time
datetime <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                        month = as.integer(strftime(today(), '%m')), 
                        day = as.integer(strftime(today(), '%d')) - 1, 
                        hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired parameter
parameter <- "t_2m:C"
# parameter <- "gh_500hPa:m" #e.g. available for clusters
# parameter <- "evapotranspiration_1h:mm"

# Specify the desired grid
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
res_lat <- NULL #resolution
# res_lat <- 3 
res_lon <- NULL #resolution
# res_lon <- 3 

# num_lat <- NULL 
num_lat <- 400 #number of lats
# num_lon <- NULL 
num_lon <- 600 #number of lons

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:0"; "mean"; 
#                                       "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1" 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Define a specific colorbar
cbar <- NULL
# cbar <- "geotiff_magenta_blue"

# Call the grid function
query_geotiff(filename, datetime, parameter, lat_N, lon_W, lat_S, lon_E, res_lat, 
              res_lon, num_lat, num_lon, username, password, model = model, 
              ens_select = ens_select, cluster_select = cluster_select, 
              interp_select = interp_select, cbar = cbar, calibrated = TRUE)

# ------------------------------------------------------------------------------
# --------------- Query geoTIFF Images of a Timeseries on a Grid ---------------
# ------------------------------------------------------------------------------
# Specify the directory and filename of the output file
filepath <- "/your/desired/directory"

# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval (needs to be e.g. hours(1); days(1); minutes(60),...)
interval <- hours(1)

# Specify the desired parameter (only 1 parameter per query)
parameter <- "t_2m:C"
# parameter <- "gh_500hPa:m" #e.g. available for clusters
# parameter <- "evapotranspiration_1h:mm"

# Specify the desired grid
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
res_lat <- NULL #resolution
# res_lat <- 3 
res_lon <- NULL #resolution
# res_lon <- 3 

# num_lat <- NULL 
num_lat <- 400 #number of lats
# num_lon <- NULL 
num_lon <- 600 #number of lons

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:0"; "mean"; 
#                                       "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1" 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Define a specific colorbar
cbar <- NULL
# cbar <- "geotiff_magenta_blue"

# Call the grid function
query_geotiff_timeseries(filepath, startdate, enddate, interval, parameter, lat_N, 
                         lon_W, lat_S, lon_E, res_lat, res_lon, num_lat, num_lon, 
                         username, password, model, ens_select, interp_select,
                         cluster_select, cbar, calibrated = TRUE)

# ------------------------------------------------------------------------------
# ---------- Query a Timeseries on a Grid and save it as netcdf File -----------
# ------------------------------------------------------------------------------
# Specify the directory and filename of the output file
filename <- paste("/your/desired/directory", "timeseries_grid.nc", sep = "/")

# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired parameter
parameter_netcdf <- "t_2m:C"
# parameter_netcdf <- "evapotranspiration_1h:mm"
# parameter_netcdf <- "gh_500hPa:m" #e.g. available for clusters

# Specify the desired interval
interval <- "PT1H"

# Specify the desired grid
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180

# Specify the desired resolution or number of lats/lons -> either res or num is 
# required and the other one has to be NULL!
res_lat <- NULL #resolution
# res_lat <- 3 
res_lon <- NULL #resolution
# res_lon <- 3 

# num_lat <- NULL 
num_lat <- 200 #number of lats
# num_lon <- NULL 
num_lon <- 300 #number of lons

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:0"; "mean"; 
#                                       "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1"; 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"


query_netcdf(filename, startdate, enddate, interval, parameter_netcdf,
             lat_N, lon_W, lat_S, lon_E, res_lat, res_lon, num_lat,
             num_lon, username, password, model = model, ens_select = ens_select,
             interp_select = interp_select, cluster_select = cluster_select, 
             calibrated = TRUE)

# ------------------------------------------------------------------------------
# --------------------------- Query Lightning Strikes --------------------------
# ------------------------------------------------------------------------------
# Define a time zone
#time_zone <- "Europe/Berlin" #The returned datetime will be in UTC
#time_zone <- "Europe/Zurich" #The returned datetime will be in UTC
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired grid
lat_N <- 50
lon_W <- -15
lat_S <- 20
lon_E <- 10

# Call the query_lightnings function
lightnings <- query_lightnings(startdate, enddate, lat_N, lon_W, lat_S, lon_E, 
                               username, password)

# Print the head of the data (first few rows)
head(lightnings)

# ------------------------------------------------------------------------------
# --------------------------- Find Weather Station -----------------------------
# ------------------------------------------------------------------------------
# Specify the desired location (all following options are possible input formats)
# location <- "47.3,9.3"
# location <- "germany"
location <- c("47.3", "9.3")

# Specify the desired parameters (all following options are possible input formats)
# parameters <- "t_2m:C"
# parameters <- "t_2m:C,precip_1h:mm"
parameters <- c("t_2m:C", "precip_1h:mm")

# Call the query_station_list function
stations <- query_station_list(username, password, parameters = parameters, 
                               location = location)

# Print the head of the data (first few rows)
head(stations)

# ------------------------------------------------------------------------------
# ------------------ Query a Timeseries for a Weather Station ------------------
# ------------------------------------------------------------------------------
# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                        month = as.integer(strftime(today(), '%m')), 
                        day = as.integer(strftime(today(), '%d')) - 1, 
                        hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                      month = as.integer(strftime(today(), '%m')), 
                      day = as.integer(strftime(today(), '%d')), 
                      hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval
interval <- "PT1H"

# Specify the desired parameters (all following options are possible input formats)
# parameters <- "t_2m:C"
# parameters <- "t_2m:C,precip_1h:mm"
parameters <- c("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")

# Specify the desired coordinate/station ids 
# (all following options are examples of possible input formats)
# coordinates <- "47.3,9.3"
# coordinates <- c("47.3,9.3", "47.43,9.4")
coordinates <- list(c(47.3,9.3), c(47.43,9.4))

# wmo_ids <- "066810" #St.Gallen; needs to be a string because of the leading zero
wmo_ids <- c("066600", "066810") #Zurich and St.Gallen; needs to be a string because of the leading zero

#mch_ids <- "LUG" #MeteoSchweiz station in Lugano
mch_ids <- c("LUG", "STG") #MeteoSchweiz station in Lugano and St.Gallen

#metar_ids <- "LSZH" #Zurich Airport
metar_ids <- c("LSZH", "LSGG") #Zurich and Geneva Airport

amda_ids <- "P100" #Kahl/Main
#AMDA ID	amda_<amda_id>	amda_P100 

cman_ids <- "mrka2" #Middle Rock Light (Alaska)
#C-MAN ID	cman_<cman_id>	cman_mrka2

hash_ids <- c("3817692398") #Zurich Airport

# Call the station_timeseries function
station_timeseries <- query_station_timeseries(startdate, enddate, interval, 
                                               parameters, username, password, 
                                               latlon_tuple_list = coordinates, 
                                               wmo_ids = wmo_ids, mch_ids = mch_ids, 
                                               metar_ids = metar_ids, amda_ids = amda_ids,
                                               cman_ids = cman_ids, hash_ids = hash_ids, 
                                               on_invalid = "fill_with_invalid")

# Print the head of the data (first few rows)
head(station_timeseries)

# ------------------------------------------------------------------------------
# -------------------- Query a Special Locations Timeseries --------------------
# ------------------------------------------------------------------------------
# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval
interval <- "PT1H"

# Specify the desired parameters (all following options are possible input formats)
# parameters <- "t_2m:C"
# parameters <- "t_2m:C,precip_1h:mm"
parameters <- c("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")

# Specify the desired postal code 
# Input as list, e.g.: postal_codes = list('DE'= c(71679, 70173) ...)
postal_code <- list('DE'= c(71679, 70173), 'CH' = c(9014, 9000))

# Call the station_timeseries function
special_timeseries <- query_special_locations_timeseries (startdate, enddate, interval, 
                                               parameters, username, password, 
                                               postal_code = postal_code, 
                                               on_invalid = "fill_with_invalid")

# Print the head of the data (first few rows)
head(special_timeseries)

# ------------------------------------------------------------------------------
# ------------------------ Get the Latest Initial Times ------------------------
# ------------------------------------------------------------------------------
# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval
interval <- "PT1H"

# Specify the desired parameters (all following options are possible input formats)
# parameter <- "t_2m:C"
# parameter <- "t_2m:C,precip_1h:mm"
parameter <- c("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")

# Specify the desired model
model <- "ecmwf-ens"
# model <- "ecmwf-ifs"

# Call the query_init_date function
init_dates <- query_init_date(startdate, enddate, interval, parameter, username, 
                              password, model)

# Print the head of the data (first few rows)
head(init_dates)

# ------------------------------------------------------------------------------
# ------------------------ Get the Available Time Range ------------------------
# ------------------------------------------------------------------------------
# Specify the desired parameters (all following options are possible input formats)
# parameters <- "t_2m:C"
# parameters <- "t_2m:C,precip_1h:mm"
parameters <- c("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm", 
                "global_rad:W", "evapotranspiration_1h:mm")

# Specify the desired model
model <- "ecmwf-ens"
# model <- "ecmwf-ifs"

# Call the query_init_date function
available_time_ranges <- query_available_time_ranges(parameters, username, password, model)

# Print the head of the data (first few rows)
head(available_time_ranges)

# ------------------------------------------------------------------------------
# ------------------------------- Query Polygons -------------------------------
# ------------------------------------------------------------------------------
# Define a time zone
time_zone <- "UTC"

# Specify the start and end date
startdate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                         month = as.integer(strftime(today(), '%m')), 
                         day = as.integer(strftime(today(), '%d')) - 1, 
                         hour = 00, min = 00, sec = 00, tz = time_zone)
enddate <- ISOdatetime(year = as.integer(strftime(today(), '%Y')), 
                       month = as.integer(strftime(today(), '%m')), 
                       day = as.integer(strftime(today(), '%d')), 
                       hour = 00, min = 00, sec = 00, tz = time_zone)

# Specify the desired interval
interval <- "PT1H"

# Specify the desired parameters (all following options are possible input formats)
# parameters <- "t_2m:C"
# parameters <- "gh_500hPa:m" #e.g. available for clusters
# parameters <- "t_2m:C,precip_1h:mm"
parameters <- c("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")

# Specify the coordinates of the desired polygon (e.g 2 polygons as input)
coordinates <- list(list(c(45.1, 8.2), c(45.2, 8.0), c(46.2, 7.5)), 
                    list(c(55.1, 8.2), c(55.2, 8.0), c(56.2, 7.5)))

# Select one of the following aggregates: min; max; mean; median; mode
# In case of multiple polygons with different aggregators the number of aggregators 
# and polygons must match and the operator has to be set to NULL!
aggregation <- "mean"
# aggregation <- c("min", "max")

# Specify an operator; Can be either "D" (difference) or "U" (union). If more 
# than 1 polygon is supplied, then the operator key has to be defined except 
# different aggregators for multiple polygons are selected
# operator <- NULL
operator <- "U"

# Specify the desired model
model <- "mix"
# model <- "ecmwf-ens" #for ensembles
# model <- "ecmwf-ens-cluster" #for clusters

# Select ensemble members (for example: "median"; "member:5"; "member:1-50"; 
#                          "member:0"; "mean"; "quantile0.2")
ens_select <- NULL
# ens_select <- "median"
# ens_select <- "member:5"

# Specify an interpolation
interp_select <- NULL
# interp_select <- "gradient_interpolation"

# Select a cluster (for example "cluster:1"; cluster:1-6; 
# see http://api.meteomatics.com/API-Request.html#cluster-selection)
cluster_select <- NULL
# cluster_select <- "cluster:1"

# Call the query_polygon function
polygon <- query_polygon(coordinates, startdate, enddate, interval, parameters, 
                         aggregation, username, password, operator, model, 
                         ens_select, interp_select, on_invalid = "fill_with_invalid", 
                         cluster_select = cluster_select, calibrated = TRUE)

# Print the head of the data (first few rows)
head(polygon)
