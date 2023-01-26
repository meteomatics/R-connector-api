#' @title Query a Polygon
#'
#' @description Query any weather parameter for the selected polygon and obtain mean, median,
#'              minimum or maximum values from the Meteomatics Weather API
#'
#' @param latlon_tuple_lists The coordinates, in either of these forms:
#'                          "47.3,9.3", c("47.3,9.3", "47.43,9.4") or
#'                          list(c(47.3,9.3), c(47.43,9.4)).
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A character vector e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameters A list of strings containing the parameters of interest
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                  "precip_1h:mm").
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param aggregation Select one of the following aggregates: min; max; mean;
#'                    median; mode. In case of multiple polygons with different
#'                    aggregators the number of aggregators and polygons must
#'                    match and the operator has to be set to NULL!
#' @param operator Specify an operator. Can be either "D" (difference) or "U" (union).
#'                If more than one polygon is supplied, then the operator key has
#'                to be defined except if different aggregators for multiple
#'                polygons are selected.
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
#' @return A dataframe containing the valid date and queried parameters.
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
#'                          month = as.integer(strftime(lubridate::today(), '%m')),
#'                          day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                          hour = 00, min = 00, sec = 00, tz = time_zone)
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                        month = as.integer(strftime(lubridate::today(), '%m')),
#'                        day = as.integer(strftime(lubridate::today(), '%d')),
#'                        hour = 00, min = 00, sec = 00, tz = time_zone)
#' interval <- "PT1H"
#' parameters <- list("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")
#' coordinates <- list(list(c(45.1, 8.2), c(45.2, 8.0), c(46.2, 7.5)),
#'                     list(c(55.1, 8.2), c(55.2, 8.0), c(56.2, 7.5)))
#' aggregation <- "mean"
#' operator <- "U"
#' model <- "mix"
#' ens_select <- NULL
#' interp_select <- NULL
#' cluster_select <- NULL
#' polygon <- query_polygon(coordinates, startdate, enddate, interval, parameters,
#'                          aggregation, username, password, operator, model,
#'                          ens_select, interp_select, on_invalid = "fill_with_invalid",
#'                          cluster_select = cluster_select, calibrated = TRUE)
#' head(polygon)
#' }

# Def Query Polygon Function
query_polygon <-
  function(latlon_tuple_lists,
           startdate,
           enddate,
           interval,
           parameters,
           aggregation,
           username,
           password,
           operator = NULL,
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

    # Add all coordinates together
    coordinates_polygon_list <- c()
    for (latlon_tuple_list in latlon_tuple_lists) {
      coordinates_polygon_list <- c(coordinates_polygon_list,
                                    paste(sapply(latlon_tuple_list, paste, collapse = ","),
                                          collapse = "_"))
    }

    if (length(coordinates_polygon_list) > 1) {
      if (!is.null(operator)) {
        coordinates <- paste(coordinates_polygon_list, collapse = operator)
        coordinates <- paste(coordinates, ":", aggregation[1])
      } else {
        coordinates_polygon <- c()
        for (i in 1:length(coordinates_polygon_list)) {
          coordinates_polygon <- c(coordinates_polygon,
                                   paste(coordinates_polygon_list[i], ":", aggregation[i]))
        }
        coordinates <- paste(coordinates_polygon, collapse = "+")
      }
    } else {
      coordinates <-
        paste(coordinates_polygon_list[1], ":", aggregation[1])
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
        coordinates,
        "/csv?",
        paste(
          url_params_dict,
          sep = "",
          collapse = "&",
          recycle0 = FALSE
        )
      )

    url <- gsub(" ", "", url, fixed = TRUE)

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

    # Add station_id column if not in DataFrame
    if (!"station_id" %in% colnames(sl)) {
      sl <- data.frame(station_id = "polygon1", sl)
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
