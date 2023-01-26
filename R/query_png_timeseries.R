#' @title Query a Time Series on a Grid with png as Output Format
#'
#' @description Retrieve a series of pngs for the requested time period and area from the
#'              Meteomatics Weather API
#'
#' @param filepath A character vector specifying the directory of the output
#'                 file. For example: "/your/desired/directory".
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A time interval of the form lubridate::hours(1);
#'                 lubridate::days(1); lubridate::minutes(60), etc.
#' @param parameter A string containing the parameter of interest.
#' @param lat_N A number giving the most northern coordinate of the desired grid.
#' @param lon_W A number giving the most western coordinate of the desired grid.
#' @param lat_S A number giving the most southern coordinate of the desired grid.
#' @param lon_E A number giving the most eastern coordinate of the desired grid.
#' @param resolution The resolution in latitude and longitude direction. If the
#'                  resolution is in degrees then in the form "0.1,0.5", or if the
#'                  resolution is in the number of latitudes/longitudes then in
#'                  the form "4x5".
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
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param ... A list of additional arguments.
#'
#' @return A series of png images for the requested time period and grid.
#'
#' @export
#'
#' @import lubridate
#'
#' @examples
#' \dontrun{
#' username <- "r-community"
#' password <- "Utotugode673"
#' filepath <- "/Users/Desktop"
#' startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                          month = as.integer(strftime(lubridate::today(), '%m')),
#'                          day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                          hour = 00, min = 00, sec = 00, tz = 'UTC')
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                        month = as.integer(strftime(lubridate::today(), '%m')),
#'                        day = as.integer(strftime(lubridate::today(), '%d')),
#'                        hour = 00, min = 00, sec = 00, tz = 'UTC')
#' interval <- lubridate::hours(1)
#' parameter <- "t_2m:C"
#' lat_N <- 90
#' lon_W <- -180
#' lat_S <- -90
#' lon_E <- 180
#' resolution <- "400x600"
#' model <- "mix"
#' query_png_timeseries(filepath, startdate, enddate, interval, parameter, lat_N,
#'                      lon_W, lat_S, lon_E, resolution, username, password, model)
#' }

# Def Query png Timeseries Function
query_png_timeseries <-
  function(filepath,
           startdate,
           enddate,
           interval,
           parameter,
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
           request_type = 'GET',
           ...) {
    # Get default url
    api_base_url <- constants("DEFAULT_API_BASE_URL")


    # Iterate over all requested dates
    this_date <- startdate
    while (this_date <= enddate) {
      # Construct filename
      if (length(filepath) > 0) {
        filename <-
          paste0(
            filepath,
            "/",
            str_replace_all(parameter, ":", '_'),
            "_",
            strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"),
            ".png"
          )
      } else {
        filename <- paste0(
          str_replace_all(parameter, ":", '_'),
          "_",
          strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"),
          ".png"
        )
      }
      # Query base method
      query_grid_png(
        filename,
        this_date,
        parameter,
        lat_N,
        lon_W,
        lat_S,
        lon_E,
        resolution,
        username,
        password,
        model,
        ens_select,
        cluster_select,
        interp_select,
        request_type,
        ...
      )

      this_date <- this_date + interval
    }
    return(paste0("Saved queried png images within ", filepath))
  }
