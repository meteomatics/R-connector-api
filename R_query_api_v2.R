#Program for Meteomatics_Weather_API
#Packages
# install.packages("")
library(httr)
library(data.table)
library(lubridate)
library(ggplot2)
source('VERSION.R')

query_user_features = function(username, password)
{
  r=GET(sprintf('https://%s:%s@api.meteomatics.com/user_stats_json', username, password), timeout(310))
  j=jsonlite::fromJSON(content(r, 'text'))
  res <- logical(3)
  names(res) <- c('area request option', 'historic request option', 'model select option')
  res['area request option'] = j$`user statistics`$`area request option`
  res['historic request option'] = j$`user statistics`$`historic request option`
  res['model select option'] = j$`user statistics`$`model select option`
  return(res)
}

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

api_timeseries = function(query)
{
  resp1 = GET(query, timeout(310))
  con = textConnection(content(resp1,"text"))
  parsed1 = read.csv(con, sep = ";")
  structure(
    list(content = parsed1)
  )
}

api_domain = function(query)
{
  resp1 = fread(query, skip=2, fill = TRUE)
  structure(
    list(content = resp1)
  )
}


query_api = function(username, password, startdate, enddate, 
                     interval, parameters, coordinate, 
                     request_type="timeseries",
                     model="mix", time_zone="UTC"
                     )
{
  #def Variabeln
  startdate_query = strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  enddate_query = strftime(enddate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  ensSelect = {}
  #URL
  if(request_type == "timeseries")
  {
    query = sprintf("https://%s:%s@api.meteomatics.com/%s--%s:%s/%s/%s/csv?model=%s&connector=R_connector_v%s", 
                    username, password, startdate_query, enddate_query, interval, parameters, coordinate, model, VERSION
                    )
    
    result = api_timeseries(query)
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
    
  } else {
    query = sprintf("https://%s:%s@api.meteomatics.com/%s/%s/%s/csv?model=%s&connector=R_connector_v%s",
                    username, password, startdate_query, parameters, coordinate, model, VERSION
                    )
    
    result = api_domain(query)
    
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
    mm = matrix(unlist(df_domain["Values"]), ncol = c -1 , byrow = TRUE)
    image(z=t(mm[nrow(mm):1,]))
    return(df_domain)
  } 
  
}
