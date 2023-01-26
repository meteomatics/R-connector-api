#' @title Query a Grid with geoTIFF as Output Format
#'
#' @description
#' Retrieve a grid from the Meteomatics Weather API and save it as geoTIFF file
#'
#' @param filename A character vector specifying the directory and filename of
#'                 the output file. For example, it can be of the form:
#'                 paste("/your/desired/directory", "filename.tiff", sep = "/").
#' @param datetime An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The date and
#'                 time gets converted into UTC if another timezone is selected.
#' @param parameter_grid A string containing the parameter of interest.
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
#' @param ... A list of additional arguments.
#'
#' @return A geoTIFF image of the queried grid.
#'
#' @export
#'
#' @import lubridate
#'
#' @examples
#' \dontrun{
#' username <- "r-community"
#' password <- "Utotugode673"
#' filename <- paste("/Users/Desktop", "grid.tiff", sep = "/")
#' datetime <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                         month = as.integer(strftime(lubridate::today(), '%m')),
#'                         day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                         hour = 00, min = 00, sec = 00, tz = "UTC")
#' parameter <- "t_2m:C"
#' lat_N <- 90
#' lon_W <- -180
#' lat_S <- -90
#' lon_E <- 180
#' resolution <- "400x600"
#' model <- "mix"
#' query_geotiff(filename, datetime, parameter, lat_N, lon_W, lat_S, lon_E,
#'               resolution, username, password, model)
#'}

# Query geoTIFF Function
query_geotiff <-
  function(filename,
           datetime,
           parameter_grid,
           lat_N,
           lon_W,
           lat_S,
           lon_E,
           resolution,
           username,
           password,
           model = NULL,
           ens_select = NULL,
           cluster_select = NULL,
           interp_select = NULL,
           cbar = NULL,
           request_type = 'GET',
           ...) {
    # Set time zone info to UTC if necessary
    attr(datetime, "tzone") <- "UTC"
    startdate <-
      strftime(datetime, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')

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

    if (!is.null(interp_select)) {
      interp_select <- paste0("interp_select=", interp_select)
    }

    if (!is.null(cluster_select)) {
      cluster_select <- paste0("cluster_select=", cluster_select)
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
    if (!is.null(cbar)) {
      url <-
        paste0(
          sprintf(api_base_url, username, password),
          "/",
          startdate,
          "/",
          parameter_grid,
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
          "/",
          cbar,
          "?",
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
          "/",
          parameter_grid,
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
          "/geotiff?",
          paste(
            url_params_dict,
            sep = "",
            collapse = "&",
            recycle0 = FALSE
          )
        )
    }

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
        headers = "image/geotiff",
        output_dir = output_dir
      )

    return(paste0("Saved queried geoTIFF image as ", output_dir))
  }
