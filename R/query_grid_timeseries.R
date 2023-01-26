#' @title Query a Time Series on a Grid
#'
#' @description
#' Retrieve a time series on a grid from the Meteomatics Weather API
#'
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A character vector e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameters A list of strings containing the parameters of interest
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                  "precip_1h:mm").
#' @param lat_N A number giving the most northern coordinate of the desired grid.
#' @param lon_W A number giving the most western coordinate of the desired grid.
#' @param lat_S A number giving the most southern coordinate of the desired grid.
#' @param lon_E A number giving the most eastern coordinate of the desired grid.
#' @param resolution The resolution in latitude and longitude direction. If the
#'                resolution is in degrees then in the form "0.1,0.5", or if the
#'                 resolution is in the number of latitudes/longitudes then in
#'                 the form "4x5".
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param model A character vector containing the model of interest. The default
#'              value is NULL, meaning that the model mix is selected.
#' @param ens_select A character vector containing the ensembles of interest. The
#'                   default value is NULL. Possible inputs are for example:
#'                   "median"; "member:5"; "member:1-50"; "member:0"; "mean";
#'                   "quantile0.2".
#' @param interp_select A character vector specifying the interpolation: The
#'                      default value is NULL. A possible input is:
#'                      "gradient_interpolation".
#' @param cluster_select A character vector containing the cluster of interest.
#'                       The default value is NULL. Possible inputs are for example:
#'                       "cluster:1"; "cluster:1-6".
#' @param on_invalid A character vector specifying the treatment of missing
#'                   weather station values. The default value is NULL. If
#'                   on_invalid = "fill_with_invalid", missing values are filled
#'                   with Na.
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param ... A list of additional arguments.
#'
#' @return A DataFrame containing the latitude, longitude and validdate in the
#'         first three columns and the corresponding parameter values in the
#'         remaining columns.
#'
#' @export
#'
#' @import lubridate
#' @import httr
#' @importFrom data.table fread
#'
#' @examples
#'
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
#' parameters <- list("evapotranspiration_1h:mm")
#' interval <- "PT1H"
#' lat_N <- 50
#' lon_W <- -15
#' lat_S <- 20
#' lon_E <- 10
#' resolution <- "3x4" # or "4,2"
#' model <- "mix"
#' query_grid_timeseries(startdate, enddate, interval, parameters, lat_N, lon_W,
#'                       lat_S, lon_E, resolution,
#'                       username, password, model = model)
#'

# Def Query Grid Timeseries Function
query_grid_timeseries <-
  function(startdate,
           enddate,
           interval,
           parameters,
           lat_N,
           lon_W,
           lat_S,
           lon_E,
           resolution,
           username,
           password,
           model = NULL,
           ens_select = NULL,
           interp_select = NULL,
           cluster_select = NULL,
           on_invalid = NULL,
           request_type = 'GET',
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

    if (!is.null(on_invalid)) {
      on_invalid<- paste0("on_invalid=", on_invalid)
    }

    if (!is.null(interp_select)) {
      interp_select <- paste0("interp_select=", interp_select)
    }

    if (!is.null(cluster_select)) {
      cluster_select <- paste0("cluster_select=", cluster_select)
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
        lat_N,
        ",",
        lon_W,
        "_",
        lat_S,
        ",",
        lon_E,
        ":",
        resolution,
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
      data.table::fread(
        httr::content(response, as = "text", encoding = "UTF-8"),
        skip = 0,
        fill = TRUE
      )
    sl <- as.data.frame(sl)

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
