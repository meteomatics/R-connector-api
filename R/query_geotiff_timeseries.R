#' @title Query a Timeseries with geoTIFF as Output Format
#'
#' @description
#' Retrieve a time series from the Meteomatics Weather API and save it as geoTIFF
#' files
#'
#' @param filepath A character vector specifying the directory of the output
#'                 file. For example: "/your/desired/directory".
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval The time interval: should contain the library (e.g. lubridate),
#'                 the unit (days, hours, minutes etc) and the number of days/
#'                 hours/ minutes etc, for example: lubridate::hours(3).
#' @param parameter A character vector containing the parameter of interest.
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
#' @param cbar A character vector specifying a colorbar. The default value is NULL.
#'             A possible input would be "geotiff_magenta_blue".
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param ... A list of additional arguments. One possible argument is
#'            calibrated = TRUE.
#'
#' @return A series of geotiff files on a grid.
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
#' parameter <- "evapotranspiration_1h:mm"
#' interval <- lubridate::hours(3) # or as.numeric(1, units = "hours")
#' lat_N <- 50
#' lon_W <- -15
#' lat_S <- 20
#' lon_E <- 10
#' resolution <- "3,3"
#' model <- "mix"
#' query_geotiff_timeseries(filepath, startdate, enddate, interval, parameter,
#'                          lat_N, lon_W, lat_S, lon_E, resolution, username,
#'                          password, model=model)
#'}

# Def Query geoTIFF Timeseries Function
query_geotiff_timeseries <-
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
           cbar = NULL,
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
            ".tiff"
          )
      } else {
        filename <- paste0(
          str_replace_all(parameter, ":", '_'),
          "_",
          strftime(this_date, format = '%Y%m%d_%H%M%S', tz = "UTC"),
          ".tiff"
        )
      }
      # Query base method
      query_geotiff(
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
        cbar,
        request_type,
        ...
      )

      this_date <- this_date + interval
    }
    return(paste0("Saved queried geoTIFF images within ", filepath))
  }
