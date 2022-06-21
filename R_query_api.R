################################################################################
# --------------------- Meteomatics Weather API Connector -------------------- #
################################################################################
# Visit https://www.meteomatics.com/en/api/overview/ for an overview of the API.
# Checkout the examples!
# If necessary, you can open an issue at
# https://github.com/meteomatics/python-connector-api or
# write an email to support@meteomatics.com if you need further assistance.
################################################################################
# ------------------------------------------------------------------------------
# ------------------------------- Load Packages --------------------------------
# ------------------------------------------------------------------------------
# Install missing packages using install.packages("")
# Load Packages
library(httr)
library(data.table) #data.table still works on Mac but in single-threaded mode
library(lubridate)
#library(ggplot2)
library(stringr)
library(grid)
source('VERSION.R')
source('constants.R')
source('exceptions.R')

# ------------------------------------------------------------------------------
# -------------------------- Functions to Query Data ---------------------------
# ------------------------------------------------------------------------------
# Def Query API Function
query_api <- function(url, username, password, request_type = "GET", 
                      timeout_seconds = 300, headers = 'application/octet-stream',
                      output_dir = NULL){
  
  # Add username and password to the URL
  url <- httr::parse_url(url)
  url$username <- username
  url$password <- password
  url <- httr::build_url(url)
  
  if(tolower(request_type) == "get"){
    # Call the httr::GET Function to get API Data
    if (is.null(output_dir)){
      response <- httr::GET(url, authenticate(username, password), accept(headers),
                            timeout = timeout_seconds)
    } else {
      response <- httr::GET(url, authenticate(username, password), accept(headers),
                            timeout = timeout_seconds, write_disk(output_dir, overwrite = TRUE))
    }
    
  } else if (tolower(request_type) == "post"){
    # Split the URL into the basic API URL and the Rest/Data
    url_new <- str_extract(url, "(?:.+?/){3}")
    data <- strsplit(url, "(?:.+?/){3}")[[1]][2]
    
    # Deal with short/incomplete URL
    if (is.na(data)){
      data <- NULL
    }
    if (is.na(url_new)){
      url_new <- sprintf('https://%s:%s@api.meteomatics.com/', username, password)
      data <- NULL
    }
    
    # Call the httr::POST Function to get API Data
    if (is.nul.(output_dir)){
      response <- httr::POST(url_new, authenticate(username, password), accept(headers),
                             content_type("text/plain"), body = data, 
                             timeout = timeout_seconds)
    } else {
      response <- httr::POST(url_new, authenticate(username, password), accept(headers),
                             content_type("text/plain"), body = data, 
                             timeout = timeout_seconds, write_disk(output_dir, overwrite = TRUE))
    }
    
  } else {
    # Error if request_type is neither "get" nor "post"
    stop(sprintf("Unknown request_type: %s", request_type))
  }
  
  if (response$status_code != 200) {
    # Error if the status_code of the query is not 200 -> print the Error Message of the API
    stop(paste0(exceptions[[which(as.numeric(names(exceptions)) == response$status_code)]], ": ", 
               content(response, as = "text", encoding = "UTF-8")))
  }
  
  return(response)
}
# ------------------------------------------------------------------------------
# Def Query User Features Function
query_user_features <- function(username, password){
  .Deprecated(msg = paste0("This function will be removed/renamed because it only provides ", 
                           "info about the licensing options and not real user statistics. ", 
                           "In addition, do not programmatically rely on user features since ",
                           "the returned keys can change over time due to internal changes."))
  
  # Call the httr::GET Function to get API Data
  response <- httr::GET(sprintf(paste0(DEFAULT_API_BASE_URL, "/user_stats_json"), username, password), 
                        timeout = 310)
  
  if (response$status_code != 200) {
    # Error if the status_code of the query is not 200 -> print the Error Message of the API
    stop(paste0(exceptions[[which(as.numeric(names(exceptions)) == response$status_code)]], ": ", 
                content(response, as = "text", encoding = "UTF-8")))
  }
  
  # Extract user statistics from HTTP response
  j <- jsonlite::fromJSON(content(response, 'text'))
  
  # Summarize desired Info in a Named Vector
  res <- logical(3)
  names(res) <- c('area request option', 'historic request option', 'model select option')
  res['area request option'] <- j$`user statistics`$`area request option`
  res['historic request option'] <- j$`user statistics`$`historic request option`
  res['model select option'] <- j$`user statistics`$`model select option`
  
  return(res)
}
# ------------------------------------------------------------------------------
# Def Query User Limits Function: Get users usage and limits
query_user_limits <- function(username, password){
  
  # Call the httr::GET Function to get API Data
  response <- httr::GET(sprintf(paste0(DEFAULT_API_BASE_URL, "/user_stats_json"), username, password), 
                        timeout(310))
  
  if (response$status_code != 200) {
    # Error if the status_code of the query is not 200 -> print the Error Message of the API
    stop(paste0(exceptions[[which(as.numeric(names(exceptions)) == response$status_code)]], ": ", 
                content(response, as = "text", encoding = "UTF-8")))
  }
  
  # Extract user limits from HTTP response
  j <- jsonlite::fromJSON(content(response, 'text'))
  
  # Create a list with the limits for the following requests and return them only if the hard limit != 0
  respond <- list()
  key <- c('requests total', 'requests since last UTC midnight', 'requests since HH:00:00',
           'requests in the last 60 seconds', 'requests in parallel')
  
  if (j$`user statistics`$`requests total`$`hard limit` != 0){
     value <- c(j$`user statistics`$`requests total`$`used`, 
                j$`user statistics`$`requests total`$`hard limit`)
     names(value) <- c('used', 'hard limit')
     respond[[key[1]]] <- value
  }
  if (j$`user statistics`$`requests since last UTC midnight`$`hard limit` != 0){
    value <- c(j$`user statistics`$`requests since last UTC midnight`$`used`, 
               j$`user statistics`$`requests since last UTC midnight`$`hard limit`)
    names(value) <- c('used', 'hard limit')
    respond[[key[2]]] <- value
  }
  if (j$`user statistics`$`requests since HH:00:00`$`hard limit` != 0){
    value <- c(j$`user statistics`$`requests since HH:00:00`$`used`, 
               j$`user statistics`$`requests since HH:00:00`$`hard limit`)
    names(value) <- c('used', 'hard limit')
    respond[[key[3]]] <- value
  }
  if (j$`user statistics`$`requests in the last 60 seconds`$`hard limit` != 0){
    value <- c(j$`user statistics`$`requests in the last 60 seconds`$`used`, 
               j$`user statistics`$`requests in the last 60 seconds`$`hard limit`)
    names(value) <- c('used', 'hard limit')
    respond[[key[4]]] <- value
  }
  if (j$`user statistics`$`requests in parallel`$`hard limit` != 0){
    value <- c(j$`user statistics`$`requests in parallel`$`used`, 
               j$`user statistics`$`requests in parallel`$`hard limit`)
    names(value) <- c('used', 'hard limit')
    respond[[key[5]]] <- value
  }
  
  return(respond)
}
# ------------------------------------------------------------------------------
# Def Query Timeseries Function
query_time_series <- function(coordinate_list, startdate, enddate, interval, 
                              parameters, username, password, model = NULL,
                              ens_select = NULL, interp_select = NULL, 
                              on_invalid = NULL, api_base_url = DEFAULT_API_BASE_URL,
                              request_type = 'GET', cluster_select = NULL, 
                              na_values = NA_VALUES, ...){
  
  # Retrieve a time series from the Meteomatics Weather API.
  # Start and End dates have to be in UTC.
  # Returns a DataFrame with a `DateTimeIndex`.
  # request_type is one of 'GET'/'POST'
  # na_values: list of special Values that get converted to Na.
  #            Default = [-666, -777, -888, -999]
  #            See also https://www.meteomatics.com/en/api/response/#reservedvalues
  # ens_select = NULL  #e.g. "median"; "member:5"; "member:1-50"; "member:0"; "mean"; 
  #                          "quantile0.2"
  # cluster_select = NULL  #e.g. "cluster:1"; "cluster:1-6"
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  if (is.null(ens_select)){
    extended_params <- parameters
  } else {
    # Parse ens
    components <- unlist(strsplit(ens_select, ",", fixed = TRUE))
    out <- c()
    for (co in components){
      if (grepl("member:", co) == TRUE){
        numbers <- Xmisc::lstrip(co, char = "member:")
        if (grepl("-", numbers) == TRUE){
          start <- unlist(strsplit(numbers, "-", fixed = TRUE))[1]
          end <- unlist(strsplit(numbers, "-", fixed = TRUE))[2]
          numbers <- seq(from = as.integer(start), to = as.integer(end))
        } else {
          numbers <- as.integer(numbers)
        }
        for (n in numbers){
          out <- c(out, paste0("m", n))
        }
      } else {
        out <- c(out, co)
      }
    }
    ens_params <- out
    
    # Build response params: Combine member strings with the parameter list
    out <- c()
    for (ens in ens_params){
      for (param in parameters){
        if (ens == "m0"){
          out <- param
        } else {
          out <- c(out, paste0(param, "-", ens))
        }
      }
    }
    extended_params <- out
  }
  
  # Create final parameter string
  if (length(parameters) == 1 ){
    parameters_string <- parameters
  } else {
    parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
  }
  parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(on_invalid)){
    on_invalid_string <- NULL
  } else {
    on_invalid_string <- paste0("on_invalid=", on_invalid)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
  }
  
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  url_params_dict <- list('model' = model_string, 'on_invalid' = on_invalid_string, 
                          'ens_select' = ens_select_string, 'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if(!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  # Check whether all coordinates are postal codes (e.g. postal_CH9014)
  is_postal <- c()
  for (coord in coordinate_list){
    if (is.character(coord) && startsWith(coord, "postal_")){
      is_postal <- c(is_postal, TRUE)
    } else {
      is_postal <- c(is_postal, FALSE)
    }
  }
  is_postal <- all(is_postal)
  
  # Add all coordinates together
  if (is_postal == TRUE){
    if (length(coordinate_list) == 1){
      coordinate_list_str <- coordinate_list
    } else {
      coordinate_list_str <- paste(coordinate_list, collapse = "+")
    }
  } else {
    coordinate_list_str <- paste(sapply(coordinate_list, paste, collapse = ","),
                                 collapse = "+")
  }
  
  # Create final URL
  url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                enddate, ":", interval, "/", parameters_string, "/", coordinate_list_str, "/csv?",
                paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";", 
                 check.names = FALSE)
  
  # Add coordinates to final dataframe
  coordinates_vec <- unlist(strsplit(coordinate_list_str, "+", fixed = TRUE))
  if (is_postal == TRUE){
    if (length(coordinates_vec) == 1){
      sl <- data.frame(postal_code = coordinates_vec, sl)
    } else {
      names(sl)[names(sl) == "station_id"] <- "postal_code"
    }
  } else {
    if (length(coordinates_vec) == 1){
      sl <- data.frame(latlon = coordinates_vec, sl)
      sl <- tidyr::separate(sl, "latlon", c("lat", "lon"), sep = ",")
    }
  }
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      for(l in 1:length(unlist(na_values))){
        if (sl[k, i] == unlist(na_values)[l]){
          sl[k, i] <- NA
        }
      }
    }
  }
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Grid Function
query_grid <- function(datetime, parameter_grid, lat_N, lon_W, lat_S, lon_E, 
                       res_lat, res_lon, num_lat, num_lon, username, password, 
                       model = NULL, ens_select = NULL, interp_select = NULL, 
                       cluster_select = NULL, on_invalid = NULL,
                       api_base_url = DEFAULT_API_BASE_URL, request_type = 'GET', 
                       na_values = NA_VALUES, ...){
  
  # Set time zone info to UTC if necessary
  attr(datetime, "tzone") <- "UTC"
  startdate <- strftime(datetime, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Create final parameter string
  if (length(parameter_grid) == 1 ){
    parameters_string <- parameter_grid
  } else {
    parameters_string <- paste(parameter_grid, sep = "", collapse = ",", recycle0 = FALSE)
  }
  parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
    
    # Parse ens -> used to extract data
    components <- unlist(strsplit(ens_select, ",", fixed = TRUE))
    out <- c()
    for (co in components){
      if (grepl("member:", co) == TRUE){
        numbers <- Xmisc::lstrip(co, char = "member:")
        if (grepl("-", numbers) == TRUE){
          start <- unlist(strsplit(numbers, "-", fixed = TRUE))[1]
          end <- unlist(strsplit(numbers, "-", fixed = TRUE))[2]
          numbers <- seq(from = as.integer(start), to = as.integer(end))
        } else {
          numbers <- as.integer(numbers)
        }
        for (n in numbers){
          out <- c(out, paste0("m", n))
        }
      } else {
        out <- c(out, co)
      }
    }
    ens_params <- out
  }
   
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
    
    # Parse cluster -> used to extract data
    components <- unlist(strsplit(cluster_select, ",", fixed = TRUE))
    out <- c()
    for (co in components){
      if (grepl("cluster:", co) == TRUE){
        numbers <- Xmisc::lstrip(co, char = "cluster:")
        if (grepl("-", numbers) == TRUE){
          start <- unlist(strsplit(numbers, "-", fixed = TRUE))[1]
          end <- unlist(strsplit(numbers, "-", fixed = TRUE))[2]
          numbers <- seq(from = as.integer(start), to = as.integer(end))
        } else {
          numbers <- as.integer(numbers)
        }
        for (n in numbers){
          out <- c(out, paste0("m", n))
        }
      } else {
        out <- c(out, co)
      }
    }
    clus_params <- out
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  if (is.null(on_invalid)){
    on_invalid_string <- NULL
  } else {
    on_invalid_string <- paste0("on_invalid=", on_invalid)
  }
  
  url_params_dict <- list('model' = model_string, 'on_invalid' = on_invalid_string, 
                          'ens_select' = ens_select_string, 'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if(!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  if (!is.null(num_lat) && !is.null(num_lon) && !is.null(res_lat) && !is.null(res_lon)){
    stop(paste0("Either num_lat and num_lon or res_lat and res_lon are required but both were given.",
                "Please set either num_lat and num_lon or res_lat and res_lon to NULL."))
  }
  
  if (is.null(num_lat) && is.null(num_lon)){
    # Create final URL for rectangle with fixed resolution
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                  parameters_string, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                  lon_E, ":", res_lat, ",", res_lon, "/csv?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    
  } else if (is.null(res_lat) && is.null(res_lon)){
    # Create final URL for rectangle with fixed number of points
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                  parameters_string, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                  lon_E, ":", num_lon, "x", num_lat, "/csv?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  }
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Extract data
  # Columns and rows look differently for 1 or more parameters; the same for 1 or 
  # more ens-members and for 1 or more clusters
  param_vec <- unlist(strsplit(parameters_string, ",", fixed = TRUE))
  if (length(param_vec) == 1){
    if (!is.null(ens_select)){
      if (length(ens_params) == 1){
        sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 2, fill = TRUE)
        sl <- as.data.frame(sl)
        names(sl)[names(sl) == "data"] <- "lat"
      } else {
        sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 0, fill = TRUE)
        sl <- as.data.frame(sl)
        sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
      }
    } else if (!is.null(cluster_select)){
      if (length(clus_params) == 1){
        sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 2, fill = TRUE)
        sl <- as.data.frame(sl)
        names(sl)[names(sl) == "data"] <- "lat"
      } else {
        sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 0, fill = TRUE)
        sl <- as.data.frame(sl)
        sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
      }
    } else {
      sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 2, fill = TRUE)
      sl <- as.data.frame(sl)
      names(sl)[names(sl) == "data"] <- "lat"
    }
  } else {
    sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 0, fill = TRUE)
    sl <- as.data.frame(sl)
    sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  }
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      for(l in 1:length(unlist(na_values))){
        if (sl[k, i] == unlist(na_values)[l]){
          sl[k, i] <- NA
        }
      }
    }
  }

  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Grid png Function
query_grid_png <- function(filename, datetime, parameter_grid, lat_N, lon_W, 
                           lat_S, lon_E, res_lat, res_lon, num_lat, num_lon, username,
                           password, model = NULL, ens_select = NULL, cluster_select = NULL,
                           interp_select = NULL, api_base_url = DEFAULT_API_BASE_URL,
                           request_type = 'GET', ...){
  
  # Gets a png image generated by the Meteomatics API from grid data (see method query_grid)
  # and saves it to the specified filename.
  # request_type is one of 'GET'/'POST'
  
  # Set time zone info to UTC if necessary
  attr(datetime, "tzone") <- "UTC"
  startdate <- strftime(datetime, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
  }
  
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  url_params_dict <- list('model' = model_string, 'ens_select' = ens_select_string, 
                          'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if(!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  if (!is.null(num_lat) && !is.null(num_lon) && !is.null(res_lat) && !is.null(res_lon)){
    stop(paste0("Either num_lat and num_lon or res_lat and res_lon are required but both were given.",
                "Please set either num_lat and num_lon or res_lat and res_lon to NULL."))
  }
  
  if (is.null(num_lat) && is.null(num_lon)){
    # Create final URL for rectangle with fixed resolution
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                  parameter_grid, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                  lon_E, ":", res_lat, ",", res_lon, "/png?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    
  } else if (is.null(res_lat) && is.null(res_lon)){
    # Create final URL for rectangle with fixed number of points
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                  parameter_grid, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                  lon_E, ":", num_lon, "x", num_lat, "/png?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  }
  
  # Check if target directory exists, if not create it
  output_dir <- file.path(filename)
  if (!file.exists(output_dir) && length(output_dir) > 0){
    file.create(output_dir)
  }
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type, 
                        headers = "image/png", output_dir = output_dir)
  
  return(paste0("Saved queried png image as ", output_dir))
}
# ------------------------------------------------------------------------------
# Def Query Grid Timeseries Function
query_grid_timeseries <- function(startdate, enddate, interval, parameters, lat_N, 
                                  lon_W, lat_S, lon_E, res_lat, res_lon, num_lat, 
                                  num_lon, username, password, model = NULL, 
                                  ens_select = NULL, interp_select = NULL, 
                                  cluster_select = NULL, on_invalid = NULL,
                                  api_base_url = DEFAULT_API_BASE_URL, request_type = 'GET', 
                                  na_values = NA_VALUES, ...){
  
  # Retrieve a grid time series from the Meteomatics Weather API.
  # Start and End dates have to be in UTC.
  # Returns a `DataFrame` with a `DateTime` row.
  # request_type is one of 'GET'/'POST'
  # na_values: list of special Values that get converted to Na.
  #            Default = [-666, -777, -888, -999]
  #            See also https://www.meteomatics.com/en/api/response/#reservedvalues
  # ens_select = NULL  #e.g. "median"; "member:5"; "member:1-50"; "member:0"; "mean"; 
  #                          "quantile0.2"
  # cluster_select = NULL  #e.g. "cluster:1"; "cluster:1-6"
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Create final parameter string
  if (length(parameters) == 1 ){
    parameters_string <- parameters
  } else {
    parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
  }
  parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
    
    # Parse ens -> used to extract data
    components <- unlist(strsplit(ens_select, ",", fixed = TRUE))
    out <- c()
    for (co in components){
      if (grepl("member:", co) == TRUE){
        numbers <- Xmisc::lstrip(co, char = "member:")
        if (grepl("-", numbers) == TRUE){
          start <- unlist(strsplit(numbers, "-", fixed = TRUE))[1]
          end <- unlist(strsplit(numbers, "-", fixed = TRUE))[2]
          numbers <- seq(from = as.integer(start), to = as.integer(end))
        } else {
          numbers <- as.integer(numbers)
        }
        for (n in numbers){
          out <- c(out, paste0("m", n))
        }
      } else {
        out <- c(out, co)
      }
    }
    ens_params <- out
  }
  
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
    
    # Parse cluster -> used to extract data
    components <- unlist(strsplit(cluster_select, ",", fixed = TRUE))
    out <- c()
    for (co in components){
      if (grepl("cluster:", co) == TRUE){
        numbers <- Xmisc::lstrip(co, char = "cluster:")
        if (grepl("-", numbers) == TRUE){
          start <- unlist(strsplit(numbers, "-", fixed = TRUE))[1]
          end <- unlist(strsplit(numbers, "-", fixed = TRUE))[2]
          numbers <- seq(from = as.integer(start), to = as.integer(end))
        } else {
          numbers <- as.integer(numbers)
        }
        for (n in numbers){
          out <- c(out, paste0("m", n))
        }
      } else {
        out <- c(out, co)
      }
    }
    clus_params <- out
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  if (is.null(on_invalid)){
    on_invalid_string <- NULL
  } else {
    on_invalid_string <- paste0("on_invalid=", on_invalid)
  }
  
  url_params_dict <- list('model' = model_string, 'on_invalid' = on_invalid_string, 
                          'ens_select' = ens_select_string, 'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if (!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  if (!is.null(num_lat) && !is.null(num_lon) && !is.null(res_lat) && !is.null(res_lon)){
    stop(paste0("Either num_lat and num_lon or res_lat and res_lon are required but both were given.",
                "Please set either num_lat and num_lon or res_lat and res_lon to NULL."))
  }
  
    if (is.null(num_lat) && is.null(num_lon)){
    # Create final URL for rectangle with fixed resolution
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                  enddate, ":", interval, "/", parameters_string, "/", lat_N, ",", 
                  lon_W, "_", lat_S, ",", lon_E, ":", res_lat, ",", res_lon, "/csv?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    
  } else if (is.null(res_lat) && is.null(res_lon)){
    # Create final URL for rectangle with fixed number of points
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                  enddate, ":", interval, "/", parameters_string, "/", lat_N, ",", 
                  lon_W, "_", lat_S, ",", lon_E, ":", num_lon, "x", num_lat, "/csv?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  }
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Extract data
  sl <- fread(content(response, as = "text", encoding = "UTF-8"), skip = 0, fill = TRUE)
  sl <- as.data.frame(sl)
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      for (l in 1:length(unlist(na_values))){
        if (sl[k, i] == unlist(na_values)[l]){
          sl[k, i] <- NA
        }
      }
    }
  }
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query png Timeseries Function
query_png_timeseries <- function(filepath, startdate, enddate, interval, parameter, 
                                 lat_N, lon_W, lat_S, lon_E, res_lat, res_lon, 
                                 num_lat, num_lon, username, password, model = NULL, 
                                 ens_select = NULL, interp_select = NULL, 
                                 cluster_select = NULL, api_base_url = DEFAULT_API_BASE_URL, 
                                 request_type = 'GET', ...){
  
  # Queries a series of pngs for the requested time period and area from the Meteomatics API. 
  # The retrieved pngs are saved to the filepath directory.
  # request_type is one of 'GET'/'POST'
  
  # Iterate over all requested dates
  this_date <- startdate
  while (this_date <= enddate){
    # Construct filename
    if (length(filepath) > 0){
      filename <- paste0(filepath, "/", str_replace_all(parameter, ":", '_'), "_", 
                         strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"), ".png")
    } else {
      filename <- paste0(str_replace_all(parameter, ":", '_'), "_", 
                         strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"), ".png")
    }
    # Query base method
    query_grid_png(filename, this_date, parameter, lat_N, lon_W, lat_S, lon_E, 
                   res_lat, res_lon, num_lat, num_lon, username, password, model, 
                   ens_select, cluster_select, interp_select, api_base_url, 
                   request_type, ...)
    
    this_date <- this_date + interval
  }
  return(paste0("Saved queried png images within ", filepath))
}
# ------------------------------------------------------------------------------
# Query geoTIFF Function
query_geotiff <- function(filename, datetime, parameter_grid, lat_N, lon_W, 
                          lat_S, lon_E, res_lat, res_lon, num_lat, num_lon, username,
                          password, model = NULL, ens_select = NULL, cluster_select = NULL,
                          interp_select = NULL, cbar = NULL, api_base_url = DEFAULT_API_BASE_URL,
                          request_type = 'GET', ...){
  
  # Gets a geoTIFF image generated by the Meteomatics API from grid data (see method query_grid)
  # and saves it to the specified filename.
  # request_type is one of 'GET'/'POST'
  
  # Set time zone info to UTC if necessary
  attr(datetime, "tzone") <- "UTC"
  startdate <- strftime(datetime, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
  }
  
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  url_params_dict <- list('model' = model_string, 'ens_select' = ens_select_string, 
                          'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if(!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  if (!is.null(num_lat) && !is.null(num_lon) && !is.null(res_lat) && !is.null(res_lon)){
    stop(paste0("Either num_lat and num_lon or res_lat and res_lon are required but both were given.",
                "Please set either num_lat and num_lon or res_lat and res_lon to NULL."))
  }
  
  if (is.null(num_lat) && is.null(num_lon)){
    # Create final URL for rectangle with fixed resolution
    if (!is.null(cbar)){
      url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                    parameter_grid, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                    lon_E, ":", res_lat, ",", res_lon, "/", cbar, "?",
                    paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    } else {
      url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                    parameter_grid, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                    lon_E, ":", res_lat, ",", res_lon, "/geotiff?",
                    paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    }
  } else if (is.null(res_lat) && is.null(res_lon)){
    # Create final URL for rectangle with fixed number of points
    if (!is.null(cbar)){
      url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                    parameter_grid, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                    lon_E, ":", num_lon, "x", num_lat, "/", cbar, "?",
                    paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    } else {
      url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "/", 
                    parameter_grid, "/", lat_N, ",", lon_W, "_", lat_S, ",", 
                    lon_E, ":", num_lon, "x", num_lat, "/geotiff?",
                    paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    }
  }
  
  # Check if target directory exists, if not create it
  output_dir <- file.path(filename)
  if (!file.exists(output_dir) && length(output_dir) > 0){
    file.create(output_dir)
  }
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type, 
                        headers = "image/geotiff", output_dir = output_dir)
  
  return(paste0("Saved queried geoTIFF image as ", output_dir))
}
# ------------------------------------------------------------------------------
# Def Query geoTIFF Timeseries Function
query_geotiff_timeseries <- function(filepath, startdate, enddate, interval, parameter, 
                                     lat_N, lon_W, lat_S, lon_E, res_lat, res_lon, 
                                     num_lat, num_lon, username, password, model = NULL, 
                                     ens_select = NULL, interp_select = NULL, 
                                     cluster_select = NULL, cbar = NULL, 
                                     api_base_url = DEFAULT_API_BASE_URL, 
                                     request_type = 'GET', ...){
  
  # Queries a series of geotiffs for the requested time period and area from the Meteomatics API. 
  # The retrieved geotiffs are saved to the filepath directory.
  # request_type is one of 'GET'/'POST'
  
  # Iterate over all requested dates
  this_date <- startdate
  while (this_date <= enddate){
    # Construct filename
    if (length(filepath) > 0){
      filename <- paste0(filepath, "/", str_replace_all(parameter, ":", '_'), "_", 
                         strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"), ".tiff")
    } else {
      filename <- paste0(str_replace_all(parameter, ":", '_'), "_", 
                         strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"), ".tiff")
    }
    # Query base method
    query_geotiff(filename, this_date, parameter, lat_N, lon_W, lat_S, lon_E, 
                  res_lat, res_lon, num_lat, num_lon, username, password, model, 
                  ens_select, cluster_select, interp_select, cbar, api_base_url, 
                  request_type, ...)
    
    this_date <- this_date + interval
  }
  return(paste0("Saved queried geoTIFF images within ", filepath))
}
# ------------------------------------------------------------------------------
# Def Query netcdf Function: Query and save a Timeseries grid as .netcdf
query_netcdf <- function(filename, startdate, enddate, interval, parameter_netcdf, 
                         lat_N, lon_W, lat_S, lon_E, res_lat, res_lon, num_lat, 
                         num_lon, username, password, model = NULL, ens_select = NULL, 
                         interp_select = NULL, api_base_url = DEFAULT_API_BASE_URL, 
                         request_type = 'GET', cluster_select = NULL, ...){
  
  # Queries a netCDF file form the Meteomatics API and stores it in filename.
  # request_type is one of 'GET'/'POST'.
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Create final parameter string
  if (length(parameter_netcdf) == 1 ){
    parameters_string <- parameter_netcdf
  } else {
    parameters_string <- paste(parameter_netcdf, sep = "", collapse = ",", recycle0 = FALSE)
  }
  parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
  }
  
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  url_params_dict <- list('model' = model_string, 'ens_select' = ens_select_string, 
                          'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if(!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  if (!is.null(num_lat) && !is.null(num_lon) && !is.null(res_lat) && !is.null(res_lon)){
    stop(paste0("Either num_lat and num_lon or res_lat and res_lon are required but both were given.",
                "Please set either num_lat and num_lon or res_lat and res_lon to NULL."))
  }
  
  if (is.null(num_lat) && is.null(num_lon)){
    # Create final URL for rectangle with fixed resolution
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                  enddate, ":", interval, "/", parameters_string, "/", lat_N, ",", 
                  lon_W, "_", lat_S, ",", lon_E, ":", res_lat, ",", res_lon, "/netcdf?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
    
  } else if (is.null(res_lat) && is.null(res_lon)){
    # Create final URL for rectangle with fixed number of points
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                  enddate, ":", interval, "/", parameters_string, "/", lat_N, ",", 
                  lon_W, "_", lat_S, ",", lon_E, ":", num_lon, "x", num_lat, "/netcdf?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  }
  
  # Check if target directory exists, if not create it
  output_dir <- file.path(filename)
  if (!file.exists(output_dir) && length(output_dir) > 0){
    file.create(output_dir)
  }
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type,
                        headers = "application/netcdf", output_dir = output_dir)
  
  return(paste0("Saved netcdf file as ", output_dir))
}
# ------------------------------------------------------------------------------
# Def Query Lightnings: Query a list of lightning strikes
query_lightnings <- function(startdate, enddate, lat_N, lon_W, lat_S, lon_E, 
                             username, password, api_base_url = DEFAULT_API_BASE_URL, 
                             request_type = 'GET', na_values = NA_VALUES){
  
  # Queries lightning strokes in the specified area during the specified time 
  # via the Meteomatics API.
  # Returns a 'DataFrame'.
  # request_type is one of 'GET'/'POST'.
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  url <- paste0(sprintf(api_base_url, username, password), "/get_lightning_list?time_range=", 
                startdate, "--", enddate, "&bounding_box=", lat_N, ",", lon_W, 
                "_", lat_S, ",", lon_E, "&format=csv")
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type, 
                        headers = "text/csv")
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";", 
                 check.names = FALSE)
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  # for (i in 1:ncol(sl)){
  #   for (k in 1:nrow(sl)){
  #     for(l in 1:length(unlist(na_values))){
  #       if (sl[k, i] == unlist(na_values)[l]){
  #         sl[k, i] <- NA
  #       }
  #     }
  #   }
  # }
  
  # Rename col names
  colnames(sl) <- c("validdate", "lat", "lon", "stroke_current:kA") 
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")

  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Station List Function: Find weather station
query_station_list <- function(username, password, source = NULL, parameters = NULL,
                               startdate = NULL, enddate = NULL, location = NULL,
                               api_base_url = DEFAULT_API_BASE_URL, request_type = "GET",
                               elevation = NULL, id = NULL){
  # Function to query available stations in API:
  # source as string
  # parameters as string
  # startdate as datetime object
  # enddate as datetime object
  # location as string (e.g. "40,10")
  # request_type is one of 'GET'/'POST'
  # elevation as integer/float (e.g. 1050 ; 0.5)
  
  # Parse query station parameters -> bring input parameters in a suitable format
  if (is.null(source)){
    source_string <- NULL
  } else {
    source_string <- paste0("source=", source)
    source_string <- gsub(" ", "", source_string, fixed = TRUE) # Get rid of all white spaces in string
  }
  
  if (is.null(parameters)){
    parameters_string <- NULL
  } else if (is.list(parameters)){
    # If it's a list -> takes only the values not the keys as input!!
    parameters_string <- paste0("parameters=", paste(parameters, sep = "", collapse = ",", 
                                                     recycle0 = FALSE))
    parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  } else if (is.character(parameters)){
    if (length(parameters) == 1 ){
      parameters_string <- paste0("parameters=", parameters)
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    } else if (length(parameters) > 1){
      parameters_string <- paste0("parameters=", paste(parameters, sep = "", collapse = ",", 
                                                       recycle0 = FALSE))
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    }
  } else {
    stop("Please use a string or a list of strings for parameters.")
  }
  
  if (is.null(startdate)){
    startdate_string <- NULL
  } else {
    startdate_string <- strftime(startdate, format = '%Y-%m-%dT%HZ', tz = attr(startdate, "tzone"))
    startdate_string <- paste0("startdate=", startdate_string)
    startdate_string <- gsub(" ", "", startdate_string, fixed = TRUE)
  }
  
  if (is.null(enddate)){
    enddate_string <- NULL
  } else {
    enddate_string <- strftime(enddate, format = '%Y-%m-%dT%HZ', tz = attr(enddate, "tzone"))
    enddate_string <- paste0("enddate=", enddate_string)
    enddate_string <- gsub(" ", "", enddate_string, fixed = TRUE)
  }
  
  if (is.null(location)){
    location_string <- NULL
  } else if (is.list(location)){
    # If it's a list -> takes only the values not the keys as input!!
    location_string <- paste0("location=", paste(location, sep = "", collapse = ",", 
                                                 recycle0 = FALSE))
    location_string <- gsub(" ", "", location_string, fixed = TRUE)
  } else if (is.character(location)){
    if (length(location) == 1 ){
      location_string <- paste0("location=", location)
      location_string <- gsub(" ", "", location_string, fixed = TRUE)
    } else if (length(location) > 1){
      location_string <- paste0("location=", paste(location, sep = "", collapse = ",", 
                                                   recycle0 = FALSE))
      location_string <- gsub(" ", "", location_string, fixed = TRUE)
    }
  } else {
    stop("Please use a string or a list of strings for location.")
  }
  
  if (is.null(elevation)){
    elevation_string <- NULL
  } else {
    elevation_string <- paste0("elevation=", elevation)
    elevation_string <- gsub(" ", "", elevation_string, fixed = TRUE)
  }
  
  if (is.null(id)){
    id_string <- NULL
  } else {
    id_string <- paste0("id=", id)
    id_string <- gsub(" ", "", id_string, fixed = TRUE)
  }
  
  url_params_dict <- list('source' = source_string, 'parameters' = parameters_string,
                          'startdate' = startdate_string, 'enddate' = enddate_string,
                          'location' = location_string, 'elevation' = elevation_string, 
                          'id' = id_string)
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  # Create final URL
  url <- paste0(sprintf(api_base_url, username, password), "/find_station?", 
                paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";", 
                 check.names = FALSE)
  sl <- tidyr::separate(sl, "Location Lat,Lon", c("Lat", "Lon"), sep = ",")
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Station Timeseries Function
query_station_timeseries <- function(startdate, enddate, interval, parameters, 
                                     username, password, model = 'mix-obs',
                                     latlon_tuple_list = NULL, wmo_ids = NULL, 
                                     mch_ids = NULL, general_ids = NULL, hash_ids = NULL,
                                     metar_ids = NULL, amda_ids = NULL, cman_ids = NULL, 
                                     temporal_interpolation = NULL, spatial_interpolation = NULL, 
                                     on_invalid = NULL, api_base_url = DEFAULT_API_BASE_URL, 
                                     request_type = 'GET', na_values = NA_VALUES){
  
  # Retrieve a time series from the Meteomatics Weather API.
  # Requested can be by WMO ID, Metar ID or coordinates. -> leading 0 -> input as string
  # Start and End dates have to be in UTC.
  # Returns a DataFrame with a 'DateTimeIndex'.
  # request_type is one of 'GET/POST'
  # na_values: list of special Values that get converted to Na.
  #            Default = [-666, -777, -888, -999]
  #            See also https://www.meteomatics.com/en/api/response/#reservedvalues
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Add all coordinates together
  coordinate_blocks <- list()
  if (!is.null(latlon_tuple_list)){
    coordinate_blocks <- paste(sapply(latlon_tuple_list, paste, collapse = ","), 
                               collapse = "+")
  }
  
  if (!is.null(wmo_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(sapply(sapply("wmo_", paste, wmo_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks,
                                 paste(sapply(sapply("wmo_", paste, wmo_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+"), sep = "+")
    }
  }
  
  if (!is.null(metar_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(sapply(sapply("metar_", paste, metar_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks,
                                 paste(sapply(sapply("metar_", paste, metar_ids, sep = ""), 
                                              paste, collapse = ","), collapse = "+"), sep = "+")
    }
  }
  
  if (!is.null(mch_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(sapply(sapply("mch_", paste, mch_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks,
                                 paste(sapply(sapply("mch_", paste, mch_ids, sep = ""), 
                                              paste, collapse = ","), collapse = "+"), sep = "+")
    }
  }
  
  if (!is.null(amda_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(sapply(sapply("amda_", paste, amda_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks,
                                 paste(sapply(sapply("amda_", paste, amda_ids, sep = ""), 
                                              paste, collapse = ","), collapse = "+"), sep = "+")
    }
  }
  
  if (!is.null(cman_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(sapply(sapply("cman_", paste, cman_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks,
                                 paste(sapply(sapply("cman_", paste, cman_ids, sep = ""), 
                                              paste, collapse = ","), collapse = "+"), sep = "+")
    }
  }
  
  if (!is.null(general_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(sapply(sapply("id_", paste, general_ids, sep = ""), 
                                        paste, collapse = ","), collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks,
                                 paste(sapply(sapply("id_", paste, general_ids, sep = ""), 
                                              paste, collapse = ","), collapse = "+"), sep = "+")
    }
  }
  
  if (!is.null(hash_ids)){
    if (length(coordinate_blocks) == 0){
      coordinate_blocks <- paste(hash_ids, collapse = "+")
    } else {
      coordinate_blocks <- paste(coordinate_blocks, paste(hash_ids, collapse = "+"), 
                                 sep = "+")
    }
  }
  
  coordinates <- coordinate_blocks
  
  # Add all other parameters together
  model_string <- paste0("model=", model)
  
  
  if (is.null(on_invalid)){
    on_invalid_string <- NULL
  } else {
    on_invalid_string <- paste0("on_invalid=", on_invalid)
  }
  
  if (is.null(temporal_interpolation)){
    temporal_interpolation_string <- NULL
  } else {
    temporal_interpolation_string <- paste0("temporal_interpolation=", temporal_interpolation)
  }
  
  if (is.null(spatial_interpolation)){
    spatial_interpolation_string <- NULL
  } else {
    spatial_interpolation_string <- paste0("spatial_interpolation=", spatial_interpolation)
  }
  
  url_params_dict <- list('model' = model_string, 'on_invalid' = on_invalid_string, 
                          'temporal_interpolation' = temporal_interpolation_string,
                          'spatial_interpolation' = spatial_interpolation_string)
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  # Convert parameters in a suitable format
  if (is.list(parameters)){
    # If it's a list -> takes only the values not the keys as input!!
    parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
    parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  } else if (is.character(parameters)){
    if (length(parameters) == 1 ){
      parameters_string <- parameters
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    } else if (length(parameters) > 1){
      parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    }
  } else {
    stop("Please use a string or a list of strings for parameters.")
  }
  
  # Create final URL
  if (length(coordinates) == 0) {
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                  enddate, ":", interval, "/", parameters_string, "/csv?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  } else {
    url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                  enddate, ":", interval, "/", parameters_string, "/", coordinates, "/csv?",
                  paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  }
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";", 
                 check.names = FALSE)
  
  # Add coordinates to final dataframe
  coordinates_vec <- unlist(strsplit(coordinates, "+", fixed = TRUE))
  if (length(coordinates_vec) == 1){
    sl <- data.frame(station_id = coordinates_vec, sl)
  }
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      for(l in 1:length(unlist(na_values))){
        if (sl[k, i] == unlist(na_values)[l]){
          sl[k, i] <- NA
        }
      }
    }
  }
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Special Locations Timeseries (e.g. Postal Codes) Function
query_special_locations_timeseries <- function(startdate, enddate, interval, parameters, 
                                               username, password, model = 'mix',
                                               postal_codes = NULL, temporal_interpolation = NULL, 
                                               spatial_interpolation = NULL, on_invalid = NULL, 
                                               api_base_url = DEFAULT_API_BASE_URL, 
                                               request_type = 'GET', na_values = NA_VALUES){
  
  # Retrieve a time series from the Meteomatics Weather API.
  # Requested locations can also be specified by Postal Codes;
  #     Input as list, e.g.: postal_codes = list('DE'= c(71679, 70173) ...).
  # Start and End dates have to be in UTC.
  # Returns a Pandas `DataFrame` with a `DateTimeIndex`.
  # request_type is one of 'GET/POST'
  # na_values: list of special Values that get converted to Na.
  #     Default = [-666, -777, -888, -999]
  #     See also https://www.meteomatics.com/en/api/response/#reservedvalues
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Add all Postal Codes together
  if (is.null(postal_codes)){
    coordinates <- ""
  } else {
    coordinates <- c()
    for (i in 1:length(names(postal_codes))){
      for (k in 1:length(postal_codes[[names(postal_codes)[i]]])){
        coordinates <- c(coordinates, paste0("postal_", toupper(names(postal_codes)[i]), 
                                             postal_codes[[names(postal_codes)[i]]][k]))
      }
    }
    coordinates <- paste(coordinates, collapse = "+")
  }
  
  # Add all other parameters together
  model_string <- paste0("model=", model)
  
  
  if (is.null(on_invalid)){
    on_invalid_string <- NULL
  } else {
    on_invalid_string <- paste0("on_invalid=", on_invalid)
  }
  
  if (is.null(temporal_interpolation)){
    temporal_interpolation_string <- NULL
  } else {
    temporal_interpolation_string <- paste0("temporal_interpolation=", temporal_interpolation)
  }
  
  if (is.null(spatial_interpolation)){
    spatial_interpolation_string <- NULL
  } else {
    spatial_interpolation_string <- paste0("spatial_interpolation=", spatial_interpolation)
  }
  
  url_params_dict <- list('model' = model_string, 'on_invalid' = on_invalid_string, 
                          'temporal_interpolation' = temporal_interpolation_string,
                          'spatial_interpolation' = spatial_interpolation_string)
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  # Convert parameters in a suitable format
  if (is.list(parameters)){
    # If it's a list -> takes only the values not the keys as input!!
    parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
    parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  } else if (is.character(parameters)){
    if (length(parameters) == 1 ){
      parameters_string <- parameters
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    } else if (length(parameters) > 1){
      parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    }
  } else {
    stop("Please use a string or a list of strings for parameters.")
  }
  
  # Create final URL
  url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                enddate, ":", interval, "/", parameters_string, "/", coordinates, "/csv?",
                paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";", 
                 check.names = FALSE)
  
  # Add coordinates to final dataframe
  coordinates_vec <- unlist(strsplit(coordinates, "+", fixed = TRUE))
  if (length(coordinates_vec) == 1){
    sl <- data.frame(station_id = coordinates_vec, sl)
  }
  
  # Sort DataFrame alphabetically
  sl <- sl[order(sl$station_id),]
  rownames(sl) <- NULL #Reset Index
  
  # If desired could here add the station_id column also as postal_code column as in python
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      for(l in 1:length(unlist(na_values))){
        if (sl[k, i] == unlist(na_values)[l]){
          sl[k, i] <- NA
        }
      }
    }
  }
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Init Date Function: Get latest initial time of model
query_init_date <- function(startdate, enddate, interval, parameter, username, 
                            password, model, api_base_url = DEFAULT_API_BASE_URL){
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Convert parameters in a suitable format
  if (is.list(parameter)){
    # If it's a list -> takes only the values not the keys as input!!
    parameters_string <- paste(parameter, sep = "", collapse = ",", recycle0 = FALSE)
    parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  } else if (is.character(parameter)){
    if (length(parameter) == 1 ){
      parameters_string <- parameter
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    } else if (length(parameter) > 1){
      parameters_string <- paste(parameter, sep = "", collapse = ",", recycle0 = FALSE)
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    }
  } else {
    stop("Please use a string or a list of strings for parameters.")
  }
  
  # Build URL
  url <- paste0(sprintf(api_base_url, username, password), "/get_init_date?model=", 
                model, "&valid_date=", startdate, "--", enddate, ":", interval, 
                "&parameters=", parameters_string)
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = "GET", headers = "text/csv")
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";", 
                 check.names = FALSE)
  
  # Convert DateTime 0000-00-00T00:00:00Z to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      if (sl[k, i] == "0000-00-00T00:00:00Z"){
        sl[k, i] <- NA
      }
    }
  }
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  # Convert all parameters into datetime in UTC
  for (i in 2:ncol(sl)){
    sl[ , i] <- as.POSIXct(sl[ , i], format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  }
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Available Time Ranges Function: Get avialable time range of a model
query_available_time_ranges <- function(parameters, username, password, model, 
                                        api_base_url = DEFAULT_API_BASE_URL){
  
  # Convert parameters in a suitable format
  if (is.list(parameters)){
    # If it's a list -> takes only the values not the keys as input!!
    parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
    parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  } else if (is.character(parameters)){
    if (length(parameters) == 1 ){
      parameters_string <- parameters
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    } else if (length(parameters) > 1){
      parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
      parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
    }
  } else {
    stop("Please use a string or a list of strings for parameters.")
  }
  
  # Create final URL
  url <- paste0(sprintf(api_base_url, username, password), "/get_time_range?model=", 
                model, "&parameters=", parameters_string)
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = "GET", headers = "text/csv")
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";",
                 check.names = FALSE)
 
  # Convert DateTime 0000-00-00T00:00:00Z to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      if (!is.na(sl[k, i])){
        if (sl[k, i] == "0000-00-00T00:00:00Z"){
          sl[k, i] <- NA
        }
        if (sl[k, i] == ""){
          sl[k, i] <- NA
        }
      }
    }
  }
  
  # Convert min_date and max_date into datetime in UTC
  sl$min_date <- as.POSIXct(sl$min_date, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  sl$max_date <- as.POSIXct(sl$max_date, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  return(sl)
}
# ------------------------------------------------------------------------------
# Def Query Polygon Function
query_polygon <- function(latlon_tuple_lists, startdate, enddate, interval, 
                          parameters, aggregation, username, password, operator = NULL, 
                          model = NULL, ens_select = NULL, interp_select = NULL, 
                          on_invalid = NULL, api_base_url = DEFAULT_API_BASE_URL, 
                          request_type = 'GET', cluster_select = NULL, 
                          na_values = NA_VALUES, ...){
  
  # Retrieve a time series from the Meteomatics Weather API for a selected polygon.
  # Start and End dates have to be in UTC.
  # Returns a `DataFrame` with a `DateTime`.
  # request_type is one of 'GET'/'POST'
  
  # Polygons have to be supplied in lists containing lat/lon tuples. For example, input of 2 polygons:
  # list(list(c(45.1, 8.2), c(45.2, 8.0), c(46.2, 7.5)), list(c(55.1, 8.2), c(55.2, 8.0), c(56.2, 7.5)))
  # If more than 1 polygon is supplied, then the operator key has to be defined!
    
  # The aggregation parameter can be chosen from: mean, max, min, median, mode. 
  # Input format is a list of strings.
  # In case of multiple polygons with different aggregators the number of aggregators 
  # and polygons must match and the operator has to be set to NULL!
  
  # The operator can be either D (difference) or U (union). Input format is a string.
  
  # Set time zone info to UTC if necessary
  attr(startdate, "tzone") <- "UTC"
  attr(enddate, "tzone") <- "UTC"
  
  #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
  startdate <- strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  enddate <- strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
  
  # Build URL
  # Create final parameter string
  if (length(parameters) == 1 ){
    parameters_string <- parameters
  } else {
    parameters_string <- paste(parameters, sep = "", collapse = ",", recycle0 = FALSE)
  }
  parameters_string <- gsub(" ", "", parameters_string, fixed = TRUE)
  
  # Add some parameters together
  if (is.null(model)){
    model_string <- NULL
  } else {
    model_string <- paste0("model=", model)
  }
  
  if (is.null(ens_select)){
    ens_select_string <- NULL
  } else {
    ens_select_string <- paste0("ens_select=", ens_select)
  }
  
  if (is.null(cluster_select)){
    cluster_select_string <- NULL
  } else {
    cluster_select_string <- paste0("cluster_select=", cluster_select)
  }
  
  if (is.null(interp_select)){
    interp_select_string <- NULL
  } else {
    interp_select_string <- paste0("interp_select=", interp_select)
  }
  
  if (is.null(on_invalid)){
    on_invalid_string <- NULL
  } else {
    on_invalid_string <- paste0("on_invalid=", on_invalid)
  }
  
  url_params_dict <- list('model' = model_string, 'on_invalid' = on_invalid_string, 
                          'ens_select' = ens_select_string, 'interp_select' = interp_select_string,
                          'cluster_select' = cluster_select_string)
  
  # Check for additional arguments
  if (length(list(...)) != 0){
    for (i in names(list(...))){
      if (!(i %in% names(url_params_dict))){
        url_params_dict[i] <- paste0(i, "=", list(...)[i])
      }
    }
  }
  
  # Filter out keys that do not have any value
  url_params_dict <- url_params_dict[!sapply(url_params_dict, is.null)]
  
  # Add all coordinates together
  coordinates_polygon_list <- c()
  for (latlon_tuple_list in latlon_tuple_lists){
    coordinates_polygon_list <- c(coordinates_polygon_list, 
                                  paste(sapply(latlon_tuple_list, paste, collapse = ","), 
                                        collapse = "_"))
  }
  
  if (length(coordinates_polygon_list) > 1){
    if (!is.null(operator)){
      coordinates <- paste(coordinates_polygon_list, collapse = operator)
      coordinates <- paste(coordinates, ":", aggregation[1])
    } else {
      coordinates_polygon <- c()
      for (i in 1:length(coordinates_polygon_list)){
        coordinates_polygon <- c(coordinates_polygon, 
                                 paste(coordinates_polygon_list[i], ":", aggregation[i]))
      }
      coordinates <- paste(coordinates_polygon, collapse = "+")
    }
  } else {
    coordinates <- paste(coordinates_polygon_list[1], ":", aggregation[1])
  }
   
  # Create final URL
  url <- paste0(sprintf(api_base_url, username, password), "/", startdate, "--",
                enddate, ":", interval, "/", parameters_string, "/", coordinates, "/csv?",
                paste(url_params_dict, sep = "", collapse = "&", recycle0 = FALSE))
  
  url <- gsub(" ", "", url, fixed = TRUE)
  
  # Call the query_api Function
  response <- query_api(url, username, password, request_type = request_type)
  
  # Example for header of CSV (single polygon, polygon united or polygon difference): 
  # 'validdate;t_2m:C,precip_1h:mm'
  # Example for header of CSV (multiple polygon): 'station_id, validdate;t_2m:C,precip_1h:mm'
  
  # Extract data
  sl <- read.csv(text = content(response, as = "text", encoding = "UTF-8"), sep = ";",
                 check.names = FALSE)
  
  # Add station_id column if not in DataFrame
  if(!"station_id"%in% colnames(sl)){
    sl <- data.frame(station_id = "polygon1", sl)
  }
  
  # Convert validdate into datetime in UTC
  sl$validdate <- as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  
  # Convert Na Values -666; -777; -888 and -999 to Na
  for (i in 1:ncol(sl)){
    for (k in 1:nrow(sl)){
      for(l in 1:length(unlist(na_values))){
        if (sl[k, i] == unlist(na_values)[l]){
          sl[k, i] <- NA
        }
      }
    }
  }
  
  return(sl)
}
# ------------------------------------------------------------------------------
