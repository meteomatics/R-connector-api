#Meteomatics Weather API Connector
#Connecting with the query_api_time.R
source('R_query_api_v2.R')

#Data
username = "r-community"
password = "Utotugode673"

time_zone = "Europe/Berlin"
startdate = ISOdatetime(year = strtoi(strftime(today(),'%Y')),
                        month = strtoi(strftime(today(),'%m')),
                        day = strtoi(strftime(today(),'%d')),
                        hour = 00, min = 00, sec = 00, tz = "UTC")
enddate = ISOdatetime(year = strtoi(strftime(today(),'%Y')),
                      month = strtoi(strftime(today(),'%m')),
                      day = strtoi(strftime(today(),'%d'))+1,
                      hour = 00, min = 00, sec = 00, tz = "UTC")
interval = "PT1H"

#Find out what the current account can do
limits = query_user_features(username, password)

#Query a timeseries in a single point for two parameters
cat("\nPerforming time series query.\n")
request_type= "timeseries"
parameters = "t_2m:C,relative_humidity_1000hPa:p" #different parameters
coordinate = "47.11,11.47" #Point or line
ts_output = query_api(username, password, startdate, enddate, interval, parameters, coordinate, request_type, time_zone=time_zone)
print(ts_output)

#Run a grid query if possible

if (limits['area request option'])
{
  cat("\nPerforming domain query.\n")
  parameters = "t_2m:C" #only one parameter
  coordinate = "48.5,5.5_45.5,11.5:800x600" #Rectangle
  request_type = "domain"
  grid_output = query_api(username, password, startdate, enddate, interval, parameters, coordinate, request_type, time_zone=time_zone)
  print(grid_output)
} else
{
  cat(sprintf("\nYour account '%s' does not include area requests.
With the corresponding upgrade you could query whole grids of data at once or even time series of grids.
Please check http://shop.meteomatics.com or contact us at shop@meteomatics.com for an individual offer.", username))
}
