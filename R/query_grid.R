#' @title Query a Grid
#'
#' @description
#' Retrieve a grid from the Meteomatics Weather API
#'
#' @param datetime An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The date
#'                 gets converted into UTC if another timezone is selected.
#' @param parameters A list of strings containing the parameters of interest
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                     "precip_1h:mm").
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
#'                   "median"; "member:5-5"; "member:1-50"; "member:0"; "mean";
#'                   "quantile0.2". If the member is specified, it should be
#'                   specified first.
#' @param interp_select A character vector specifying the interpolation: The
#'                      default value is NULL. A possible input is:
#'                      "gradient_interpolation".
#' @param cluster_select A character vector containing the cluster of interest.
#'                       The default value is NULL. Possible inputs are for example:
#'                       "cluster:1-1" if only the first cluster; "cluster:1-6" for
#'                       the first 6.
#' @param on_invalid A character vector specifying the treatment of missing
#'                   weather station values. The default value is NULL. If
#'                   on_invalid = "fill_with_invalid", missing values are filled
#'                   with Na.
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param ... A list of additional arguments.
#'
#' @return A DataFrame filled with the parameter values. The latitude appears in
#'         the first column of the DataFrame and the longitude in the column names.
#' @export
#'
#' @import httr
#' @import lubridate
#' @importFrom data.table fread
#' @import rlist
#'
#' @examples
#'
#' username <- "r-community"
#' password <- "Utotugode673"
#' time_zone <- "UTC"
#' datetime <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '%Y')),
#'                         month = as.integer(strftime(lubridate::today(), '%m')),
#'                         day = as.integer(strftime(lubridate::today(), '%d')) - 1,
#'                         hour = 00, min = 00, sec = 00, tz = time_zone)
#' parameter <- list("evapotranspiration_1h:mm")
#' lat_N <- 50
#' lon_W <- -15
#' lat_S <- 20
#' lon_E <- 10
#' resolution <- "3,3"
#' model <- "mix"
#' query_grid(datetime, parameter, lat_N, lon_W, lat_S, lon_E, resolution,
#'           username, password, model = model)
#'

# Def Query Grid Function
query_grid <-
  function(datetime,
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
    attr(datetime, "tzone") <- "UTC"
    startdate <-
      strftime(datetime, format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')

    # Get default url
    api_base_url <- constants("DEFAULT_API_BASE_URL")

    # Get na values
    na_values <- constants("NA_VALUES")

    # Build URL
    # Add some parameters together
    if (!is.null(model)) {
      model <- paste0("model=", model)
    }

    if (!is.null(on_invalid)) {
      on_invalid <- paste0("on_invalid=", on_invalid)
    }

    if (!is.null(interp_select)) {
      interp_select <- paste0("interp_select=", interp_select)
    }

    # create empty list to store the data frames
    dataframe_list <- list()

    if (!is.null(ens_select) && !is.null(cluster_select)){
      stop("Please either choose ens_select or cluster_select, but not both.")
    }

    for (parameter in parameters) {
      ### NO CLUSTER OR ENSEMBLE
      if (is.null(cluster_select) && is.null(ens_select)) {
        url_params_dict <-
          list(
            'model' = model,
            'on_invalid' = on_invalid,
            'interp_select' = interp_select
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
            "/",
            parameter,
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
            skip = 2,
            fill = TRUE
          )
        sl <- as.data.frame(sl)
        names(sl)[names(sl) == "data"] <- "lat/lon"

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
        dataframe_list <- list(sl)
      }

      ### CLUSTER SELECTION
      if (!is.null(cluster_select) && is.null(ens_select)) {
        cluster_list <- list()
        a <- strsplit(cluster_select, "-")[[1]][1]
        a <- substring(a, 9, 9) # 9th character
        b <- strsplit(cluster_select, "-")[[1]][2] # last character
        for (i in as.numeric(a):as.numeric(b)) {
          newcluster <- paste0("cluster:", as.character(i))
          cluster_list <-
            rlist::list.append(cluster_list, newcluster)
        }
        for (cluster in cluster_list) {
          url_params_dict <-
            list(
              'model' = model,
              'on_invalid' = on_invalid,
              'interp_select' = interp_select,
              'cluster_select' = paste0("cluster_select=", cluster)
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
              "/",
              parameter,
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
              skip = 2,
              fill = TRUE
            )
          sl <- as.data.frame(sl)
          names(sl)[names(sl) == "data"] <- "lat/lon"

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
          dataframe_list <- rlist::list.append(dataframe_list, sl)
        }
      }

      ### ENSEMBLE SELECTION
      if (is.null(cluster_select) && !is.null(ens_select)) {
        ens_list <- list()
        splitted_list <- strsplit(ens_select, ",")
        if (grepl("member", ens_select)) {
          member_part <- splitted_list[[1]][1]

          for (i in as.numeric(substring(member_part, 8, 8)):as.numeric(substring(member_part, 10, 10))) {
            newens <- paste0("member:", as.character(i))
            ens_list <- rlist::list.append(ens_list, newens)
          }

          if (length(splitted_list[[1]]) > 1) {
            other_part <- splitted_list[[1]]

            for (i in 2:length(splitted_list[[1]])) {
              ens_list <- rlist::list.append(ens_list, splitted_list[[1]][i])
            }
          }
          other_part <- splitted_list[[1]]

        } else {
          for (ens in splitted_list[[1]]) {
            ens_list <- rlist::list.append(ens_list, ens)
          }
        }

        for (ens in ens_list) {
          url_params_dict <-
            list(
              'model' = model,
              'on_invalid' = on_invalid,
              'interp_select' = interp_select,
              'ens_select' = paste0("ens_select=", ens)
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
              "/",
              parameter,
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
              skip = 2,
              fill = TRUE
            )
          sl <- as.data.frame(sl)
          names(sl)[names(sl) == "data"] <- "lat/lon"

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
          dataframe_list <- rlist::list.append(dataframe_list, sl)
        }
      }
    }



    return (dataframe_list)
  }
