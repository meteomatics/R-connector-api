#' @title Query a Timeseries at Specified Stations
#'
#' @description
#' Retrieve a time series from the Meteomatics Weather API

#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A character vector e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameters A list of strings containing the parameters of interest:
#'                  list("t_2m:C", "dew_point_2m:C",
#'                   "relative_humidity_1000hPa:p", "precip_1h:mm"). If not
#'                   specified, then the default value is NULL.
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param model A character vector containing the model of interest. The default
#'              value is NULL, meaning that the model mix is selected.
#' @param latlon_tuple_list The coordinates, in either of these forms:
#'                        "47.3,9.3", c("47.3,9.3", "47.43,9.4") or
#'                        list(c(47.3,9.3), c(47.43,9.4)).
#' @param wmo_ids WMO Station id as string or list of strings.
#' @param mch_ids MCH Station id as string or list of strings.
#' @param general_ids General Station id as string or list of strings.
#' @param hash_ids HASH Station id as string or list of strings.
#' @param metar_ids METAR Station id as string or list of strings.
#' @param amda_ids AMDA Station id as string or list of strings.
#' @param cman_ids C-MAN Station id as string or list of strings.
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
#' @return A dataframe containing the valid date and the specified parameters.
#' @export
#'
#' @import lubridate
#' @import utils
#' @import httr
#'
#' @examples
#' \dontrun{
#' username <- "r-community"
#' password <- "Utotugode673"
#' time_zone <- "UTC"
#' startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                       month = as.integer(strftime(lubridate::today(), '%m')),
#'                       day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                       hour = 00, min = 00, sec = 00, tz = time_zone)
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                      month = as.integer(strftime(lubridate::today(), '%m')),
#'                      day = as.integer(strftime(lubridate::today(), '%d')),
#'                      hour = 00, min = 00, sec = 00, tz = time_zone)
#' interval <- "PT1H"
#' parameters <- list("t_2m:C")
#' coordinates <- list(c(47.3,9.3), c(47.43,9.4))
#' wmo_ids <- c("066600", "066810")
#' mch_ids <- c("LUG", "STG")
#' metar_ids <- c("LSZH", "LSGG")
#' amda_ids <- "P100"
#' cman_ids <- "mrka2"
#' hash_ids <- c("3817692398")
#' query_station_timeseries(startdate, enddate, interval, parameters,username,
#'                          password, model = 'mix-obs',
#'                          latlon_tuple_list = coordinates, wmo_ids = wmo_ids,
#'                          mch_ids = mch_ids, hash_ids = hash_ids,
#'                          metar_ids = metar_ids, amda_ids = amda_ids,
#'                          cman_ids = cman_ids)
#' }

# Def Query Station Timeseries Function
query_station_timeseries <-
  function(startdate,
           enddate,
           interval,
           parameters,
           username,
           password,
           model = 'mix-obs',
           latlon_tuple_list = NULL,
           wmo_ids = NULL,
           mch_ids = NULL,
           general_ids = NULL,
           hash_ids = NULL,
           metar_ids = NULL,
           amda_ids = NULL,
           cman_ids = NULL,
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
    # Add all coordinates together
    coordinates <- list()
    if (!is.null(latlon_tuple_list)) {
      coordinates <-
        paste(sapply(latlon_tuple_list, paste, collapse = ","),
              collapse = "+")
    }

    if (!is.null(wmo_ids)) {
      if (length(coordinates) == 0) {
        coordinates <-
          paste(sapply(sapply("wmo_", paste, wmo_ids, sep = ""),
                       paste, collapse = ","), collapse = "+")
      } else {
        coordinates <- paste(coordinates,
                                   paste(sapply(
                                     sapply("wmo_", paste, wmo_ids, sep = ""),
                                     paste, collapse = ","
                                   ), collapse = "+"), sep = "+")
      }
    }

    if (!is.null(metar_ids)) {
      if (length(coordinates) == 0) {
        coordinates <-
          paste(sapply(
            sapply("metar_", paste, metar_ids, sep = ""),
            paste,
            collapse = ","
          ), collapse = "+")
      } else {
        coordinates <- paste(coordinates,
                                   paste(sapply(
                                     sapply("metar_", paste, metar_ids, sep = ""),
                                     paste,
                                     collapse = ","
                                   ), collapse = "+"), sep = "+")
      }
    }

    if (!is.null(mch_ids)) {
      if (length(coordinates) == 0) {
        coordinates <-
          paste(sapply(sapply("mch_", paste, mch_ids, sep = ""),
                       paste, collapse = ","), collapse = "+")
      } else {
        coordinates <- paste(coordinates,
                                   paste(sapply(
                                     sapply("mch_", paste, mch_ids, sep = ""),
                                     paste, collapse = ","
                                   ), collapse = "+"), sep = "+")
      }
    }

    if (!is.null(amda_ids)) {
      if (length(coordinates) == 0) {
        coordinates <-
          paste(sapply(
            sapply("amda_", paste, amda_ids, sep = ""),
            paste,
            collapse = ","
          ), collapse = "+")
      } else {
        coordinates <- paste(coordinates,
                                   paste(sapply(
                                     sapply("amda_", paste, amda_ids, sep = ""),
                                     paste,
                                     collapse = ","
                                   ), collapse = "+"), sep = "+")
      }
    }

    if (!is.null(cman_ids)) {
      if (length(coordinates) == 0) {
        coordinates <-
          paste(sapply(
            sapply("cman_", paste, cman_ids, sep = ""),
            paste,
            collapse = ","
          ), collapse = "+")
      } else {
        coordinates <- paste(coordinates,
                                   paste(sapply(
                                     sapply("cman_", paste, cman_ids, sep = ""),
                                     paste,
                                     collapse = ","
                                   ), collapse = "+"), sep = "+")
      }
    }

    if (!is.null(general_ids)) {
      if (length(coordinates) == 0) {
        coordinates <-
          paste(sapply(
            sapply("id_", paste, general_ids, sep = ""),
            paste,
            collapse = ","
          ), collapse = "+")
      } else {
        coordinates <- paste(coordinates,
                                   paste(sapply(
                                     sapply("id_", paste, general_ids, sep = ""),
                                     paste,
                                     collapse = ","
                                   ), collapse = "+"), sep = "+")
      }
    }

    if (!is.null(hash_ids)) {
      if (length(coordinates) == 0) {
        coordinates <- paste(hash_ids, collapse = "+")
      } else {
        coordinates <-
          paste(coordinates, paste(hash_ids, collapse = "+"),
                sep = "+")
      }
    }

    # Add all other parameters together


    if (!is.null(on_invalid)) {
      on_invalid <- paste0("on_invalid=", on_invalid)
    }

    if (!is.null(model)) {
      model <- paste0("model=", model)
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
      parameters <-
        paste(
          parameters,
          sep = "",
          collapse = ",",
          recycle0 = FALSE
        )
      parameters <-
        gsub(" ", "", parameters, fixed = TRUE)
    } else {
      stop("Please use a string or a list of strings for parameters.")
    }

    # Create final URL
    if (length(coordinates) == 0) {
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
          parameters,
          "/csv?",
          paste(
            url_params_dict,
            sep = "",
            collapse = "&",
            recycle0 = FALSE
          )
        )
    } else {
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
          parameters,
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
    }

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
