#' @title Query a Time Series at Special Locations
#'
#' @description
#' Retrieve a time series from the Meteomatics Weather API
#'
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A character vector e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameters A list of strings containing the parameters of interest
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                     "precip_1h:mm").
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param model A character vector containing the model of interest. The default
#'              value is NULL, meaning that the model mix is selected.
#' @param postal_codes A list of postal codes, e.g.: postal_codes = list('DE'= c(71679, 70173) ...).
#' @param temporal_interpolation This parameter specifies the temporal interpolation.
#'                              The default value is NULL which means the data is interpolated.
#'                              If no interpolation is needed, one can set
#'                              temporal_interpolation=none.
#' @param spatial_interpolation This parameter specifies the spatial interpolation.
#'                              The default value is NULL which means the data is interpolated.
#'                              If no interpolation is needed, one can set
#'                              spatial_interpolation=none.
#' @param on_invalid A character vector specifying the treatment of missing
#'                   weather station values. The default value is NULL. If
#'                   on_invalid = "fill_with_invalid", missing values are filled
#'                   with Na.
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#'
#' @return Retrieve a time series from the Meteomatics Weather API.
#' @export
#'
#' @import lubridate
#' @import httr
#' @import utils
#'
#' @examples
#'\dontrun{
#' username <- "r-community"
#' password <- "Utotugode673"
#' time_zone <- "UTC"
#' startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                          month = as.integer(strftime(lubridate::today(), '%m')),
#'                          day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                          hour = 00, min = 00, sec = 00, tz = time_zone)
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                        month = as.integer(strftime(lubridate::today(), '%m')),
#'                        day = as.integer(strftime(lubridate::today(), '%d')),
#'                        hour = 00, min = 00, sec = 00, tz = time_zone)
#' interval <- "PT1H"
#' parameters <- list("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")
#' postal_code <- list('DE'= c(71679, 70173), 'CH' = c(9014, 9000))
#' special_timeseries <- query_special_locations_timeseries (startdate, enddate, interval,
#'                                                           parameters, username, password,
#'                                                           postal_code = postal_code,
#'                                                           on_invalid = "fill_with_invalid")
#' head(special_timeseries)
#'}

# Def Query Special Locations Timeseries (e.g. Postal Codes) Function
query_special_locations_timeseries <-
  function(startdate,
           enddate,
           interval,
           parameters,
           username,
           password,
           model = 'mix',
           postal_codes = NULL,
           temporal_interpolation = NULL,
           spatial_interpolation = NULL,
           on_invalid = NULL,
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
    # Add all Postal Codes together
    if (is.null(postal_codes)) {
      coordinates <- ""
    } else {
      coordinates <- c()
      for (i in 1:length(names(postal_codes))) {
        for (k in 1:length(postal_codes[[names(postal_codes)[i]]])) {
          coordinates <-
            c(coordinates,
              paste0("postal_", toupper(names(
                postal_codes
              )[i]),
              postal_codes[[names(postal_codes)[i]]][k]))
        }
      }
      coordinates <- paste(coordinates, collapse = "+")
    }

    # Add all other parameters together
    model <- paste0("model=", model)

    if (!is.null(on_invalid)) {
      on_invalid <- paste0("on_invalid=", on_invalid)
    }

    if (!is.null(temporal_interpolation)) {
      temporal_interpolation <-
        paste0("temporal_interpolation=", temporal_interpolation)
    }

    if (!is.null(spatial_interpolation)) {
      spatial_interpolation <-
        paste0("spatial_interpolation=", spatial_interpolation)
    }

    url_params_dict <-
      list(
        'model' = model,
        'on_invalid' = on_invalid,
        'temporal_interpolation' = temporal_interpolation,
        'spatial_interpolation' = spatial_interpolation
      )

    # Filter out keys that do not have any value
    url_params_dict <-
      url_params_dict[!sapply(url_params_dict, is.null)]

    # Convert parameters in a suitable format
    if (is.list(parameters)) {
      # If it's a list -> takes only the values not the keys as input!!
      parameters_string <-
        paste(
          parameters,
          sep = "",
          collapse = ",",
          recycle0 = FALSE
        )
      parameters_string <-
        gsub(" ", "", parameters_string, fixed = TRUE)
    } else {
      stop("Please use a string or a list of strings for parameters.")
    }

    # Create final URL
    url <-
      paste0(
        sprintf(api_base_url, username, password),
        "/",
        startdate,
        "--",
        enddate,
        ":",
        interval,
        "/",
        parameters_string,
        "/",
        coordinates,
        "/csv?",
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

    # Add coordinates to final dataframe
    coordinates_vec <-
      unlist(strsplit(coordinates, "+", fixed = TRUE))
    if (length(coordinates_vec) == 1) {
      sl <- data.frame(station_id = coordinates_vec, sl)
    }

    # Sort DataFrame alphabetically
    sl <- sl[order(sl$station_id),]
    rownames(sl) <- NULL #Reset Index

    # If desired could here add the station_id column also as postal_code column as in python

    # Convert validdate into datetime in UTC
    sl$validdate <-
      as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")

    # Convert Na Values -666; -777; -888 and -999 to Na
    for (i in 1:ncol(sl)) {
      for (k in 1:nrow(sl)) {
        for (l in 1:length(unlist(na_values))) {
          if (sl[k, i] == unlist(na_values)[l]) {
            sl[k, i] <- NA
          }
        }
      }
    }

    return(sl)
  }
