#' @title Query a List of Lightnings
#'
#' @description
#' Retrieve a list of lightning strikes from the Meteomatics Weather API
#'
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param lat_N A number giving the most northern coordinate of the desired grid.
#' @param lon_W A number giving the most western coordinate of the desired grid.
#' @param lat_S A number giving the most southern coordinate of the desired grid.
#' @param lon_E A number giving the most eastern coordinate of the desired grid.
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param request_type A character vector containing the request type - either
#'                     "get" (default) or "post".
#' @return A DataFrame containing the valid date, coordinates and current in kA
#'        of each lightning strike.
#'
#' @import lubridate
#' @import httr
#' @import utils
#'
#' @examples
#' \dontrun{
#' username <- "r-community"
#' password <- "Utotugode673"
#' startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                          month = as.integer(strftime(lubridate::today(), '%m')),
#'                          day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                          hour = 00, min = 00, sec = 00, tz = 'UTC')
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                        month = as.integer(strftime(lubridate::today(), '%m')),
#'                        day = as.integer(strftime(lubridate::today(), '%d')),
#'                        hour = 00, min = 00, sec = 00, tz = 'UTC')
#' lat_N <- 50
#' lon_W <- -15
#' lat_S <- 20
#' lon_E <- 10
#' query_lightnings(startdate, enddate, lat_N, lon_W, lat_S, lon_E, username,
#'                 password)
#' }

# Def Query Lightnings: Query a list of lightning strikes
query_lightnings <-
  function(startdate,
           enddate,
           lat_N,
           lon_W,
           lat_S,
           lon_E,
           username,
           password,
           request_type = 'GET') {

    # Set time zone info to UTC if necessary
    attr(startdate, "tzone") <- "UTC"
    attr(enddate, "tzone") <- "UTC"

    #format = '%Y-%m-%dT%HZ'; format='%Y-%m-%dT%H:%M:%OSZ'
    startdate <-
      strftime(startdate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
    enddate <-
      strftime(enddate, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')

    # Get default url
    api_base_url <- constants("DEFAULT_API_BASE_URL")

    # Get na values
    na_values <- constants("NA_VALUES")

    # Build URL
    url <-
      paste0(
        sprintf(api_base_url, username, password),
        "/get_lightning_list?time_range=",
        startdate,
        "--",
        enddate,
        "&bounding_box=",
        lat_N,
        ",",
        lon_W,
        "_",
        lat_S,
        ",",
        lon_E,
        "&format=csv"
      )

    # Call the query_api Function
    response <-
      query_api(url,
                username,
                password,
                request_type = request_type,
                headers = "text/csv")

    # Extract data
    sl <-
      utils::read.csv(
        text = httr::content(response, as = "text", encoding = "UTF-8"),
        sep = ";",
        check.names = FALSE
      )

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

    # Rename col names
    colnames(sl) <- c("validdate", "lat", "lon", "stroke_current:kA")

    # Convert validdate into datetime in UTC
    sl$validdate <-
      as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")

    return(sl)
  }
