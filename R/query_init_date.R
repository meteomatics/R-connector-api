#' @title Query the Latest Initial Times
#'
#' @description
#' Retrieve a list from the Meteomatics Weather API of the latest initial times
#'
#' @param startdate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The start
#'                  date gets converted into UTC if another timezone is selected.
#' @param enddate An ISOdatetime of the format %Y-%m-%dT%H:%M:%OSZ. The end date
#'                gets converted into UTC if another timezone is selected.
#' @param interval A string e.g. of the form "PT1H" specifying the
#'                 interval of the parameter.
#' @param parameters A list of strings containing the parameters of interest.
#' @param username A string containing the MM API username.
#' @param password A string containing the MM API password.
#' @param model A string containing the model of interest. The default
#'              value is NULL, meaning that the model mix is selected.
#'
#' @return A list of initial dates.
#' @export
#'
#' @import lubridate
#' @import utils
#' @import httr
#'
#' @examples
#'\dontrun{
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
#' interval <- "PT3H"
#' parameters <- list("t_2m:C", "dew_point_2m:C", "relative_humidity_2m:p", "precip_1h:mm")
#' model <- "ecmwf-ens"
#' init_dates <- query_init_date(startdate, enddate, interval, parameters, username,
#'                               password, model)
#' head(init_dates)
#' }

# Def Query Init Date Function: Get latest initial time of model
query_init_date <-
  function(startdate,
           enddate,
           interval,
           parameters,
           username,
           password,
           model) {
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

    # Build URL
    url <-
      paste0(
        sprintf(api_base_url, username, password),
        "/get_init_date?model=",
        model,
        "&valid_date=",
        startdate,
        "--",
        enddate,
        ":",
        interval,
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
        if (sl[k, i] == "0000-00-00T00:00:00Z") {
          sl[k, i] <- NA
        }
      }
    }

    # Convert validdate into datetime in UTC
    sl$validdate <-
      as.POSIXct(sl$validdate, format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")

    # Convert all parameters into datetime in UTC
    for (i in 2:ncol(sl)) {
      sl[, i] <-
        as.POSIXct(sl[, i], format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
    }

    return(sl)
  }
