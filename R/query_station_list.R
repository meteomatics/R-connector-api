#' @title Query all the available stations for the specified parameters
#'
#' @description
#' Retrieve a station list from the Meteomatics Weather API
#'
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param source The source of the data, by default mix-obs. String.
#' @param parameters A list of strings containing the parameters of interest:
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                  "precip_1h:mm"). If not specified, then the default value is NULL.
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#'                   If not specified, then the default value is NULL.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected. If
#'                not specified, then the default value is NULL.
#' @param location The location as a string, for example location <- ‘47,8_40,15’,
#'                 location <- ‘uk’ or location <- "47.3,9.3",
#'                 location <- c("47.3", "9.3").
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param elevation Height above sea level. It will look first for stations that
#'                   are close to this height. Integer or float.
#' @param id This is the WMO id, e.g. 66810.
#'
#' @return A DataFrame containing the stations. The best matching stations to
#'        your request appear on top.
#' @export
#'
#' @import lubridate
#' @import utils
#' @import httr
#' @import tidyr
#'
#' @examples
#'
#' username <- "r-community"
#' password <- "Utotugode673"
#' source <- "mix-obs"
#' #parameter <- list("t_2m:C")
#' #elevation <- 300
#' #id <- 66810
#' location <- "47.3,9.3"
#' query_station_list(username, password, source = source, location = location)
#'

# Def Query Station List Function: Find weather station
query_station_list <-
  function(username,
           password,
           source = NULL,
           parameters = NULL,
           startdate = NULL,
           enddate = NULL,
           location = NULL,
           request_type = "GET",
           elevation = NULL,
           id = NULL) {
    # Get default url
    api_base_url <- constants("DEFAULT_API_BASE_URL")

    # Parse query station parameters -> bring input parameters in a suitable format
    if (!is.null(source)) {
      source <- paste0("source=", source)
      # Get rid of all white spaces in string
      source <- gsub(" ", "", source, fixed = TRUE)
    }
    if (!is.null(parameters)) {
      if (is.list(parameters)) {
        # If it's a list -> takes only the values not the keys as input!!
        parameters <-
          paste0("parameters=",
                 paste(
                   parameters,
                   sep = "",
                   collapse = ",",
                   recycle0 = FALSE
                 ))
        parameters <- gsub(" ", "", parameters, fixed = TRUE)
      } else {
        stop("Please use a list of strings for parameters.")
      }
    }

    if (!is.null(startdate)) {
      startdate <-
        strftime(startdate,
                 format = '%Y-%m-%dT%HZ',
                 tz = attr(startdate, "tzone"))
      startdate <- paste0("startdate=", startdate)
      startdate <- gsub(" ", "", startdate, fixed = TRUE)
    }

    if (!is.null(enddate)) {
      enddate <-
        strftime(enddate,
                 format = '%Y-%m-%dT%HZ',
                 tz = attr(enddate, "tzone"))
      enddate <- paste0("enddate=", enddate)
      enddate <- gsub(" ", "", enddate, fixed = TRUE)
    }

    if (!is.null(location)) {
      if (is.list(location)) {
        # If it's a list -> takes only the values not the keys as input!!
        location <-
          paste0("location=",
                 paste(
                   location,
                   sep = "",
                   collapse = ",",
                   recycle0 = FALSE
                 ))
        location <-
          gsub(" ", "", location, fixed = TRUE)
      } else if (is.character(location)) {
        if (length(location) == 1) {
          location <- paste0("location=", location)
          location <-
            gsub(" ", "", location, fixed = TRUE)
        } else if (length(location) > 1) {
          location <-
            paste0("location=",
                   paste(
                     location,
                     sep = "",
                     collapse = ",",
                     recycle0 = FALSE
                   ))
          location <-
            gsub(" ", "", location, fixed = TRUE)
        }
      } else {
        stop("Please use a string or a list of strings for location.")
      }
    }

    if (!is.null(elevation)) {
      elevation <- paste0("elevation=", elevation)
      elevation <- gsub(" ", "", elevation, fixed = TRUE)
    }

    if (!is.null(id)) {
      id <- paste0("id=", id)
      id <- gsub(" ", "", id, fixed = TRUE)
    }

    url_params_dict <-
      list(
        'source' = source,
        'parameters' = parameters,
        'startdate' = startdate,
        'enddate' = enddate,
        'location' = location,
        'elevation' = elevation,
        'id' = id
      )

    # Filter out keys that do not have any value
    url_params_dict <-
      url_params_dict[!sapply(url_params_dict, is.null)]

    # Create final URL
    url <-
      paste0(
        sprintf(api_base_url, username, password),
        "/find_station?",
        paste(
          url_params_dict,
          sep = "",
          collapse = "&",
          recycle0 = FALSE
        )
      )

    # Call the query_api Function
    response <-
      query_api(url, username, password, request_type = request_type)

    # Extract data
    sl <-
      utils::read.csv(
        text = httr::content(response, as = "text", encoding = "UTF-8"),
        sep = ";",
        check.names = FALSE
      )
    sl <-
      tidyr::separate(sl, "Location Lat,Lon", c("Lat", "Lon"), sep = ",")

    return(sl)
  }
