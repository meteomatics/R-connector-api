#Program for Meteomatics_Weather_API
#Packages
# install.packages("")

library(httr)
library(data.table)
library(lubridate)
library(ggplot2)
library(stringr)
library(grid)
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

#Def Multi Plot Function
multiplot = function(..., plotlist=NULL, file, cols=1, layout=NULL)  {
 
 
  #Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  numPlots <- length(plots)
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


#Timeseries
timeseries <- function(startdate, enddate, interval, parameters, coordinate, plot = FALSE, model="mix", save_png = FALSE, target_directory = paste(getwd(),"timeseries.png",sep ="/"), plot_directory=getwd())
{
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  enddate_query <- strftime(enddate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  query = sprintf("https://%s:%s@api.meteomatics.com/%s--%s:%s/%s/%s/csv?model=%s", 
                  username, password, startdate_query, enddate_query, interval, parameters, coordinate, model)
  resp1 <- GET(query)
  
  con <- textConnection(content(resp1,"text"))
  parsed1 <- read.csv(con, sep = ";")
  result <- structure(list(content = parsed1))
  
  if (resp1$status_code != 200) {return(result$content)}  else {
    
    df_timeseries <- as.data.frame(result$content)
    df_timeseries$validdate <- as.POSIXct(df_timeseries$validdate,format='%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
    df_timeseries$validdate <- with_tz(df_timeseries$validdate, tzone = time_zone)
  
    number_coordinates <- str_count(coordinate, pattern = "\\+")+1
    
    
    if (number_coordinates == 1) {
      split_list <- strsplit(parameters, ",")
      colnames(df_timeseries) <- c("valid date",split_list[[1]][])
      if (plot == TRUE) {
      plots = NULL
      for (i in names(df_timeseries[2:ncol(df_timeseries)]))  {
        plots[[i]] = ggplot(data=df_timeseries, aes_string(x = df_timeseries$validdate, y = i)) +
        geom_line(aes_string(y = i)) + geom_point(aes_string(y = i)) +
        labs(x = "Time") 
        }
  
      mp <- multiplot(plotlist = plots)
    
      if (save_png == TRUE) {
      dev.copy(png, target_directory)
      dev.off()
      
      }
      }
    }
  
    else {
    split_list <- strsplit(parameters, ",")
    colnames(df_timeseries) <- c("lat","lon","valid date",split_list[[1]][])
    n <- nrow(df_timeseries)
    df_split <- split(df_timeseries, rep(1:number_coordinates, each=n/number_coordinates))    
    if (plot == TRUE) {
      for (i in 1:number_coordinates){
        df_timeseries_split <- as.data.frame(df_split[i])
        plots <- NULL
        for (j in names(df_timeseries_split[4:ncol(df_timeseries_split)]))  {
       
          plots[[j]] <- ggplot(data=df_timeseries_split, aes_string(x = df_timeseries_split[,3], y = j)) +
          geom_line(aes_string(y = j)) + geom_point(aes_string(y = j)) +
          labs(x = "Time") 
          mp <- multiplot(plotlist=plots)
             
          #save png
          
          filename <- paste("timeseries", j, sep="-")
          fullname <- paste(filename, ".png", sep="")
          
          if (save_png == TRUE) {
            current_wd <- getwd()
            setwd(plot_directory)
            dev.copy(png,fullname)
            dev.off()
            setwd(current_wd)
          }
            
          } 
        }
      }
    }
   }
  
 
  #split_list <- strsplit(parameters, ",")
  #if (ncol(df_timeseries))
  #colnames(df_timeseries) <- c("valid date",split_list[[1]][])
  
  return(df_timeseries)
   }
  

#Grid
grid <- function(startdate, parameter, coordinate, model="mix", plot = FALSE, save_png = FALSE, target_directory = paste(getwd(),"grid.png",sep ="/"))
{
  startdate_query = strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  ensSelect = {}
  
  query = sprintf("https://%s:%s@api.meteomatics.com/%s/%s/%s/csv?model=%s", username, password, startdate_query, parameter, coordinate, model)
  response <- GET(query)
  
  if (status_code(response) != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  else {
    resp1 <- fread(query, skip=2, fill = TRUE)
    result <- structure(list(content = resp1))
    df = as.data.frame(result$content)
 
    #Generate plot
    r = nrow(df)
    c = ncol(df)
    Longs = as.numeric(colnames(df[2:c]))
    Lon = rep(c(t(Longs)),r)    
    df_domain = data.frame(Lon) 
    Lat = rep(df[1:r,1], each = c-1)
    df_domain["Lat"] = data.frame(as.numeric(Lat))
    df_domain["Values"] = data.frame(Values = c(t(df[1:r,2:c])))
    mm = matrix(unlist(df_domain["Values"]), ncol = c -1 , byrow = TRUE)
    
  if (plot == TRUE) {
    image(z=t(mm[nrow(mm):1,]))
  }
  
  if (save_png == TRUE) {
    dev.copy(png,target_directory)
    dev.off()
   setwd(current_wd)
  }
 
  colnames(df_domain) <- c("Lon","Lat",parameter)
  return(df_domain)
  }
}


#Pivoted grid
grid_pivot <- function(startdate, parameter, coordinate, model="mix", plot = FALSE, save_png = FALSE, target_directory = paste(getwd(),"pivoted_grid.png",sep ="/"))
{
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  ensSelect <- {}
  
  query <- sprintf("https://%s:%s@api.meteomatics.com/%s/%s/%s/csv?model=%s",
                  username, password, startdate_query, parameter, coordinate, model)
  response <- GET(query)
  
  if (status_code(response) != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  else {

    resp1 <- fread(query, skip=2, fill = TRUE)
    result <- structure(list(content = resp1))
    df <- as.data.frame(result$content)
  

   r <- nrow(df)
   c <- ncol(df)
   Longs <- as.numeric(colnames(df[2:c]))
   Lon <- rep(c(t(Longs)),r)    
   df_domain <- data.frame(Lon) 
   Lat <- rep(df[1:r,1], each = c-1)
   df_domain["Lat"] <- data.frame(as.numeric(Lat))

   df_domain["Values"] <- data.frame(Values = c(t(df[1:r,2:c])))
   mm <- matrix(unlist(df_domain["Values"]), ncol = c -1 , byrow = TRUE)
   if (plot == TRUE) {
    image(z=t(mm[nrow(mm):1,]))
  }
  
  if (save_png == TRUE) {
    dev.copy(png,target_directory)
    dev.off()
  }
  
  pivot_grid <- with(df_domain, tapply(Values, list(Lat, Lon) , I)  )
  return(pivot_grid)
  }
}


#Timeseries grid
timeseries_grid = function(startdate, enddate, interval, parameter, coordinate, model="mix", plot = FALSE, save_png = FALSE, plot_directory= getwd())
{
 
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  enddate_query <- strftime(enddate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  ensSelect <- {}
  query <- sprintf("https://%s:%s@api.meteomatics.com/%s--%s:%s/%s/%s/csv?model=%s", username, password, startdate_query, enddate_query, interval, parameter, coordinate, model)
  response <- GET(query)
  if (status_code(response) != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  else {
    con = textConnection(content(response,"text"))
    parsed1 = read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    df_timeseries <- as.data.frame(result$content)
    df_timeseries$validdate <- as.POSIXct(df_timeseries$validdate,format='%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
    df_timeseries$validdate <- with_tz(df_timeseries$validdate, tzone = time_zone)
  

  df_timeseries <- df_timeseries[order(df_timeseries$validdate),]
  #Image every timestep and safe PNG
  df_ts_split <- split(df_timeseries, df_timeseries$validdate)
  l<-length(df_ts_split)
  times<-unique(df_timeseries$validdate)
  
  if (plot == TRUE) {
  
    for (i in 1:l) {
     df <- as.data.frame(df_ts_split[i])
     lat <- df[,1]
     nlat <- nrow(as.data.frame(unique(lat)))
     value <- df[,4]
     ma <- matrix(value, ncol = nlat)
    
     image(ma)
     title(times[i])
    
     filename <- paste("timeseries grid", i, sep="-")
     fullname <- paste(filename, ".png", sep="")
    
     if (save_png == TRUE) {
      current_wd <- getwd()
      setwd(plot_directory)
      dev.copy(png,fullname)
      dev.off()
      setwd(current_wd)
      }
    }
  }
  
  colnames(df_timeseries) <- c("Lat", "Lon", "validdate", parameter)
  return(df_timeseries)
  } 
} 
    

#Query and save a Timeseries grid as .netcdf if possible
save_netcdf <- function(startdate, duration, interval, parameters, coordinate, target_directory = paste(getwd(),"timeseries_grid_netcdf.netcdf",sep ="/") ) {
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  query <- sprintf("https://%s:%s@api.meteomatics.com/%s%s:%s/%s/%s/netcdf", 
                  username, password, startdate_query, duration, interval, parameters, coordinate)
  response <- GET(query)
  if (status_code(response) != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  else {
  download.file(query, target_directory, mode="wb")
  }
}


#Query a list of lightning strikes if possible
lightning_strikes <- function(time_range, bounding_box) {
  query = sprintf("https://%s:%s@api.meteomatics.com/get_lightning_list?time_range=%s&bounding_box=%s&format=csv",
                  username, password, time_range, bounding_box)
  response <- GET(query)
  
  if (status_code(response) != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  
  else {
    
    download.file(query, "lightnings.csv", mode="wb")
    lightnings <- read.csv("lightnings.csv",encoding = "UTF-8")
    
    if (nrow(lightnings) == 0) { print("No lightning strikes in this time period.")}
    
    else {
      
      resp1 <- fread(query, skip=2, fill = TRUE)
      data <- structure(list(content = resp1)) 
      cn <- c("Time","Lat","Lon","Stroke_current")
      colnames(data$content)<-cn
      return(as.data.frame(data$content))
      
    }
  }
}


#Query and download a grad plot if possible
save_grads_plot <- function(startdate, parameters, coordinate, target_directory = paste(getwd(),"grad_plot.png",sep ="/")) {
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  
  query = sprintf("https://%s:%s@api.meteomatics.com/%s/%s/%s/grads?model=ecmwf-ifs",
                  username, password, startdate_query, parameters, coordinate)
  response <- GET(query)
  if (status_code(response) != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
   else {

  download.file(query, target_directory, mode="wb")
  }
}


#Find weather station
find_station <- function(location, parameters){
  query <- sprintf("https://%s:%s@api.meteomatics.com/find_station?%s&%s",
                  username, password, location, parameters)
  response <- GET(query)
  
  if (response$status_code != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  
  else {
    download.file(query, "stations.csv", mode="wb")
    stations <- read.csv("stations.csv",encoding = "UTF-8")
    df1 <- as.data.frame(stations[,1])
    df2 <- as.data.frame(stations[,2])
    df <- cbind(df1,df2)
    df <- paste(df$`stations[, 1]`,df$`stations[, 2]`)
  
    split <- str_split_fixed(df, ";", 14)
    split_df <- as.data.frame(split)
    split_df[,14]<-NULL

    colnames <- c("Station Category","Station Type","ID Hash","WMO ID","Alternative IDs","Name","Location Lat,Lon","Elevation","Start Date","End Date","Horizontal Distance","Vertical Distance","Effective Distance")
    colnames(split_df) <-colnames

    return(split_df)
    
  }
}


#Timeseries weather station
station_timeseries <- function(startdate, enddate, interval, parameters, coordinate, model='mix-obs') {
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  enddate_query <- strftime(enddate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  
  query <- sprintf("https://%s:%s@api.meteomatics.com/%s--%s:%s/%s/%s/csv?model=%s", 
                username, password, startdate_query, enddate_query, interval, parameters, coordinate, model)
  response <- GET(query)
  
  if (response$status_code != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  
  else {
    resp1 <- fread(query, skip=2, fill = TRUE)
    data <- structure(list(content = resp1)) 
    df_timeseries <- as.data.frame(data$content)
    split_list <- strsplit(parameters, ",")
    colnames(df_timeseries) <- c("validdate",split_list[[1]][])
    return(df_timeseries)
  } 
}


#Station WMO Metar
timeseries_station_id <- function(startdate, enddate, interval, parameters, station, model='mix-obs'){
  
  startdate_query <- strftime(startdate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  enddate_query <- strftime(enddate,format='%Y-%m-%dT%H:%M:%OSZ', tz='UTC')
  
  query <- sprintf("https://%s:%s@api.meteomatics.com/%s--%s:%s/%s/%s/csv?model=%s", 
                  username, password, startdate_query, enddate_query, interval, parameters, station, model)
  response <- GET(query)
  
  if (response$status_code != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  
  else {
    resp1 <- fread(query, skip=2, fill = TRUE)
    data <- structure(list(content = resp1)) 
    df_timeseries <- as.data.frame(data$content)
    split_list <- strsplit(parameters, ",")
    colnames(df_timeseries) <- c("validdate",split_list[[1]][])
    cat("\n")
    return(df_timeseries)
  }
}


#Get latest initial time of model if possible
init_dates <- function(model,date,parameters) {
  query <- sprintf("https://%s:%s@api.meteomatics.com/get_init_date?model=%s&valid_date=%s&parameters=%s",
                   username, password, model, date, parameters)
  response <- GET(query)
  
  if (response$status_code != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  
  else {
    resp1 = fread(query, fill = TRUE)
    data<-structure(list(content = resp1))
    df <- as.data.frame(data)
  
    #Set column names
    split_list <- strsplit(parameters, ",")
    colnames(df) <- c("validdate",split_list[[1]][])
    cat("\n")
    print(df)
    }
}


#Get avialable time range of a model if possible
available_time_range <- function(model, paramters){
  query = sprintf("https://%s:%s@api.meteomatics.com/get_time_range?model=%s&parameters=%s",
                  username, password, model, paramters)
  response <- GET(query)
  
  if (response$status_code != 200) {
    con <- textConnection(content(response,"text"))
    parsed1 <- read.csv(con, sep = ";")
    result <- structure(list(content = parsed1))
    return(result$content)}
  
  else {
    download.file(query, "available_time_range.csv", mode="wb")
    time_range<-read.csv("available_time_range.csv")
    colnames(time_range) <- "parameter;min_date;max_date"
    time_range <- str_split_fixed(time_range$`parameter;min_date;max_date`, ";", 3)
    colnames(time_range) <-c ("parameter","min_date","max_date")
    return(as.data.frame(time_range))
  }
}
