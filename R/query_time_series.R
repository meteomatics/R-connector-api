#' @title Query Time Series
#'
#' @description
#' Retrieve a time series from the Meteomatics Weather API
#'
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param coordinate_list A character vector or a list of vectors containing the
#'                        coordinates/postal codes of the desired location. All
#'                        following options separated by a semicolon are examples
#'                        of possible input formats: "47.3,9.3";
#'                        c("47.3,9.3", "47.43,9.4"); "47.11,11.47+50,10";
#'                        "postal_CH9000"; c("postal_CH9000", "postal_CH9014");
#'                        c("47.3,9.3", "postal_CH9000"); list(c(47.3,9.3), c(47.43,9.4)).
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A character vector e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameters A list of strings containing the parameters of interest
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                     "precip_1h:mm").
#' @param model A character vector containing the model of interest. The default
#'              value is NULL, meaning that the model mix is selected.
#' @param ens_select A character vector containing the ensembles of interest. The
#'                   default value is NULL. Possible inputs are for example:
#'                   "median"; "member:5"; "member:1-50"; "member:0"; "mean";
#'                   "quantile0.2".
#' @param interp_select A character vector specifying the interpolation: The
#'                      default value is NULL. A possible input is:
#'                      "gradient_interpolation".
#' @param on_invalid A character vector specifying the treatment of missing
#'                   weather station values. The default value is NULL. If
#'                   on_invalid = "fill_with_invalid", missing values are filled
#'                   with Na.
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param cluster_select A character vector containing the cluster of interest.
#'                       The default value is NULL. Possible inputs are for example:
#'                       "cluster:1"; "cluster:1-6".
#' @param ... A list of additional arguments. One possible argument is
#'            calibrated = TRUE.
#'
#' @return A DataFrame containing the coordinates, validdate and the parameter
#'         values.
#' @export
#'
#' @import httr
#' @import utils
#' @import lubridate
#' @importFrom tidyr separate
#'
#' @examples
#' username <- "r-community"
#' password <- "Utotugode673"
#' coordinates <- list(c(47.3,9.3), c(47.43,9.4))
#' startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                          month = as.integer(strftime(lubridate::today(), '%m')),
#'                          day = as.integer(strftime(lubridate::today(), '%d')),
#'                          hour = 00, min = 00, sec = 00, tz = 'UTC')
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                        month = as.integer(strftime(lubridate::today(), '%m')),
#'                        day = as.integer(strftime(lubridate::today(), '%d')) + 1,
#'                        hour = 00, min = 00, sec = 00, tz = 'UTC')
#' interval <- "PT1H"
#' parameters <- list("t_2m:C")
#' model <- "mix"
#' query_time_series(coordinates, startdate, enddate, interval, parameters,
#'                   username, password, model = model, calibrated = TRUE)

# Def Query Timeseries Function
query_time_series <-
  function(coordinate_list,
           startdate,
           enddate,
           interval,
           parameters,
           username,
           password,
           model = NULL,
           ens_select = NULL,
           interp_select = NULL,
           on_invalid = NULL,
           request_type = 'GET',
           cluster_select = NULL,
           ...) {
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
      stop("Please use a list of strings for parameters.")
    }

    # Add some parameters together
    if (!is.null(model)) {
      model <- paste0("model=", model)
    }

    if (!is.null(ens_select)) {
      ens_select <- paste0("ens_select=", ens_select)
    }

    if (!is.null(cluster_select)) {
      cluster_select <- paste0("cluster_select=", cluster_select)
    }

    if (!is.null(interp_select)) {
      interp_select <- paste0("interp_select=", interp_select)
    }
    if (!is.null(on_invalid)) {
      on_invalid <- paste0("on_invalid=", on_invalid)
    }
    url_params_dict <-
      list(
        'model' = model,
        'on_invalid' = on_invalid,
        'ens_select' = ens_select,
        'interp_select' = interp_select,
        'cluster_select' = cluster_select
      )

    # Check for additional arguments
    if (length(list(...)) != 0) {
      for (i in names(list(...))) {
        if (!(i %in% names(url_params_dict))) {
          url_params_dict[i] <- paste0(i, "=", list(...)[i])
        }
      }
    }

    # Filter out keys that do not have any value
    url_params_dict <-
      url_params_dict[!sapply(url_params_dict, is.null)]

    # Check whether all coordinates are postal codes (e.g. postal_CH9014)
    is_postal <- c()
    for (coord in coordinate_list) {
      if (is.character(coord) && startsWith(coord, "postal_")) {
        is_postal <- c(is_postal, TRUE)
      } else {
        is_postal <- c(is_postal, FALSE)
      }
    }
    is_postal <- all(is_postal)

    # Add all coordinates together
    if (is_postal == TRUE) {
      if (length(coordinate_list) != 1) {
        coordinate_list <- paste(coordinate_list, collapse = "+")
      }
    } else {
      coordinate_list <-
        paste(sapply(coordinate_list, paste, collapse = ","),
              collapse = "+")
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
        parameters,
        "/",
        coordinate_list,
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
      unlist(strsplit(coordinate_list, "+", fixed = TRUE))
    if (is_postal == TRUE) {
      if (length(coordinates_vec) == 1) {
        sl <- data.frame(postal_code = coordinates_vec, sl)
      } else {
        names(sl)[names(sl) == "station_id"] <- "postal_code"
      }
    } else {
      if (length(coordinates_vec) == 1) {
        sl <- data.frame(latlon = coordinates_vec, sl)
        sl <-
          tidyr::separate(sl, "latlon", c("lat", "lon"), sep = ",")
      }
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
