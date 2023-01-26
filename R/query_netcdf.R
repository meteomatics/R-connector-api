#' @title Query a Grid Time Series with netcdf as Output Format
#'
#' @description Retrieve a grid time series from the Meteomatics Weather API and save it as
#'              netcdf files
#'
#' @param filename A character vector specifying the directory and filename of
#'                 the output file. For example, it can be of the form:
#'                 paste("/your/desired/directory", "filename.tiff", sep = "/").
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A character vector e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameter_netcdf A string containing the parameter of interest.
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
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param cluster_select A character vector containing the cluster of interest.
#'                       The default value is NULL. Possible inputs are for example:
#'                       "cluster:1"; "cluster:1-6".
#' @param ... A list of additional arguments. One possible argument is
#'            calibrated = TRUE.
#'
#' @return A series of netcdf files on a grid showing values of the specified
#'          parameter.
#' @export
#'
#' @import lubridate
#'
#' @examples
#'\dontrun{
#' username <- "r-community"
#' password <- "Utotugode673"
#' filename <- paste("/Users/Desktop", "grid.tiff", sep = "/")
#' startdate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                          month = as.integer(strftime(lubridate::today(), '%m')),
#'                          day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                          hour = 00, min = 00, sec = 00, tz = 'UTC')
#' enddate <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                        month = as.integer(strftime(lubridate::today(), '%m')),
#'                        day = as.integer(strftime(lubridate::today(), '%d')),
#'                        hour = 00, min = 00, sec = 00, tz = 'UTC')
#' interval <- "PT1H"
#' parameter <- "evapotranspiration_1h:mm"
#' lat_N <- 50
#' lon_W <- -15
#' lat_S <- 20
#' lon_E <- 10
#' resolution <- "4x5" # or "1,0.5"
#' model <- "mix"
#' query_netcdf(filename, startdate, enddate, interval, parameter,
#'              lat_N, lon_W, lat_S, lon_E, resolution, username, password,
#'              model = model)
#'}

# Def Query netcdf Function: Query and save a Timeseries grid as .netcdf
query_netcdf <-
  function(filename,
           startdate,
           enddate,
           interval,
           parameter_netcdf,
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

    # Build URL
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

    url_params_dict <-
      list(
        'model' = model,
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


    # Create final URL for rectangle with fixed resolution
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
        parameter_netcdf,
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
        "/netcdf?",
        paste(
          url_params_dict,
          sep = "",
          collapse = "&",
          recycle0 = FALSE
        )
      )


    # Check if target directory exists, if not create it
    output_dir <- file.path(filename)
    if (!file.exists(output_dir) && length(output_dir) > 0) {
      file.create(output_dir)
    }

    # Call the query_api Function
    response <-
      query_api(
        url,
        username,
        password,
        request_type = request_type,
        headers = "application/netcdf",
        output_dir = output_dir
      )

    return(paste0("Saved netcdf file as ", output_dir))
  }
