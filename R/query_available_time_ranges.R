#' @title Query the Available Time Ranges
#'
#' @description
#' Retrieve the available time ranges from the Meteomatics Weather API
#'
#' @param parameters A list of strings containing the parameters of interest
#'                  list("t_2m:C", "dew_point_2m:C", "relative_humidity_1000hPa:p",
#'                  "precip_1h:mm").
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param model A character vector containing the model of interest. The default
#'              value is NULL, meaning that the model mix is selected.
#'
#' @return A list of available time ranges.
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
#' parameters <- list("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm",
#'                 "global_rad:W", "evapotranspiration_1h:mm")
#' model <- "ukmo-euro4"
#' available_time_ranges <- query_available_time_ranges(parameters, username, password, model)
#' }

# Def Query Available Time Ranges Function: Get avialable time range of a model
query_available_time_ranges <-
  function(parameters, username, password, model) {
    # Get default url
    api_base_url <- constants("DEFAULT_API_BASE_URL")

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

    # Create final URL
    url <-
      paste0(
        sprintf(api_base_url, username, password),
        "/get_time_range?model=",
        model,
        "&parameters=",
        parameters
      )

    # Call the query_api Function
    response <-
      query_api(url,
                username,
                password,
                request_type = "GET",
                headers = "text/csv")

    # Extract data
    sl <-
      utils::read.csv(
        text = httr::content(response, as = "text", encoding = "UTF-8"),
        sep = ";",
        check.names = FALSE
      )

    # Convert DateTime 0000-00-00T00:00:00Z to Na
    for (i in 1:ncol(sl)) {
      for (k in 1:nrow(sl)) {
        if (!is.na(sl[k, i])) {
          if (sl[k, i] == "0000-00-00T00:00:00Z") {
            sl[k, i] <- NA
          }
          if (sl[k, i] == "") {
            sl[k, i] <- NA
          }
        }
      }
    }

    # Convert min_date and max_date into datetime in UTC
    sl$min_date <-
      as.POSIXct(sl$min_date, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
    sl$max_date <-
      as.POSIXct(sl$max_date, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")

    return(sl)
  }
