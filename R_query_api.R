#Program for Meteomatics_Weather_API
#Packages
# install.packages("")
library(httr)
library(data.table)
library(lubridate)
library(ggplot2)

#def Variabeln
startdate_query = strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
enddate_query = strftime(enddate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
model = {}
ensSelect = {}

#Def Multi Plot Function for using
multiplot = function(..., plotlist=NULL, file, cols=1, layout=NULL)
{
  library(grid)
  #Make a list from the ... arguments and plotlist
  plots = c(list(...), plotlist)
  numPlots = length(plots)
  #If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout))
  {
    #Make the panel; ncol: Number of columns of plots; nrow: Number of rows needed, calculated from # of cols
    layout = matrix(seq(1, cols * ceiling(numPlots/cols)),
                    ncol = cols, nrow = ceiling(numPlots/cols))
  }
  if (numPlots==1)
  {
    print(plots[[1]])
  } else
  {
    #Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    #Make each plot, in the correct location
    for (ii in 1:numPlots)
    {
      #Get the i,j matrix positions of the regions that contain this subplot
      matchidx = as.data.frame(which(layout == ii, arr.ind = TRUE))
      print(plots[[ii]], vp = viewport(layout.pos.row = matchidx$row,
                                       layout.pos.col = matchidx$col))
    }
  }
}

#URL
query = if(request_type == "timeseries")
{
  sprintf("https://%s:%s@api.meteomatics.com/%s--%s:%s/%s/%s/csv", username, password, startdate_query, enddate_query, interval, parameters, coordinate)
} else {
  sprintf("https://%s:%s@api.meteomatics.com/%s/%s/%s/csv", username, password, startdate_query, parameters, coordinate)
}

#Wanted Data
if (request_type == "timeseries"){
  #Timeseries
  #Data from the API
  api_timeseries = function(path)
  {
    resp1 = GET(query, timeout(310))
    con = textConnection(content(resp1,"text"))
    parsed1 = read.csv(con, sep = ";")
    structure(
      list(content = parsed1)
    )
  }

  result = api_timeseries("/(startdate_query)---(enddate_query):(interval)/(parameters)/(coordinate)/csv?")

  #Data
  query_api = function(username, password, startdate, enddate, interval, parameters, coordinate)
  {
    #Data in new Dataframe
    df_timeseries = as.data.frame(result$content)
    #Dates in right shape
    df_timeseries$validdate = as.POSIXct(df_timeseries$validdate,format='%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
    df_timeseries$validdate = with_tz(df_timeseries$validdate, tzone = time_zone)
    #Plot
    plots = NULL
    for (i in names(df_timeseries[2:ncol(df_timeseries)]))
    {
      plots[[i]] = ggplot(data=df_timeseries, aes_string(x = df_timeseries$validdate, y = i)) +
        geom_line(aes_string(y = i)) + geom_point(aes_string(y = i)) +
        labs(x = "Time")
    }
    #Show graph
    multiplot(plotlist=plots)
    return(df_timeseries)
  }


}else{

  #Domain (Rectangle)
  #Data from the API
  api_domain = function(path)
  {
    resp1 = fread(query, skip=2, fill = TRUE)
    structure(
      list(content = resp1)
    )
  }

  result = api_domain("/(startdate_query)/(parameters)/(coordinate)/csv?")

  #Data
  query_api = function(username, password, startdate, enddate, interval, parameters, coordinate)
  {
    #New Dataframe
    df = as.data.frame(result$content)
    #Numbers of columns and rows
    r = nrow(df)
    c = ncol(df)
    Longs = as.numeric(colnames(df[2:c]))
    #Longitude
    Lon = rep(c(t(Longs)),r)
    df_domain = data.frame(Lon)
    #Latitude
    Lat = rep(df[1:r,1], each = c-1)
    df_domain["Lat"] = data.frame(as.numeric(Lat))
    #Values
    df_domain["Values"] = data.frame(Values = c(t(df[1:r,2:c])))
    return(df_domain)
  }
}
