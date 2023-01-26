#' @title Query API
#'
#' @description
#' Query weather data from the Meteomatics API. The full URL including the
#' Meteomatics username and password is required as input
#'
#' @param url A character vector containing the URL to query the MM API.
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#' @param request_type A character vector containing the request type - either
#'                     "get" (Default) or "post".
#' @param timeout_seconds A number giving the time in seconds, when the request
#'                        results in a timeout. The default value is 300.
#' @param headers A character vector with one element. The default value is
#'                "application/octet-stream".
#' @param output_dir A character vector containing the output directory and the
#'                   file name. It is used for saving images as .png and .geoTiff
#'                   files as well as for saving netcdf files. The default
#'                   value is NULL.
#'
#' @return A list containing the API response.
#' @export
#'
#' @import httr
#' @import stringr
#' @import lubridate
#'
#' @examples
#' \dontrun{
#' username <- 'r-community'
#' password <- 'Utotugode673'
#' datetime <- strftime(ISOdatetime(year=as.integer(strftime(lubridate::today(),'%Y')),
#'                                  month=as.integer(strftime(lubridate::today(),'%m')),
#'                                  day=as.integer(strftime(lubridate::today(),'%d')),
#'                                  hour = 00, min = 00, sec = 00, tz = 'UTC'),
#'                      format = '%Y-%m-%dT%H:%M:%OSZ', tz = 'UTC')
#' url <- paste0(sprintf('https://%s:%s@api.meteomatics.com/', username, password),
#'                       datetime, '/t_2m:C/52.520551,13.461804/csv')
#' query_api(url, username, password)
#' }

# Def Query API Function
query_api <- function(url,
                      username,
                      password,
                      request_type = "GET",
                      timeout_seconds = 300,
                      headers = 'application/octet-stream',
                      output_dir = NULL) {
  # Print url -> debug
  print_url <- url
  print_url <- strsplit(url, "/") # Split the URL
  print_url[[1]][3] <- "api.meteomatics.com"
  print_url <- c(print_url[[1]])
  cat("Calling URL:\n" , paste(print_url, collapse = "/"), "\n")

  # Add username and password to the URL
  url <- httr::parse_url(url)
  url$username <- username
  url$password <- password
  url <- httr::build_url(url)

  if (tolower(request_type) == "get") {
    # Call the httr::GET Function to get API Data
    if (is.null(output_dir)) {
      response <- httr::GET(url,
                            httr::authenticate(username, password),
                            httr::accept(headers),
                            timeout = timeout_seconds)
    } else {
      response <- httr::GET(
        url,
        httr::authenticate(username, password),
        httr::accept(headers),
        timeout = timeout_seconds,
        httr::write_disk(output_dir, overwrite = TRUE)
      )
    }

  } else if (tolower(request_type) == "post") {
    #Does not work for all queries (e.g. lightning is not working)
    # Split the URL into the basic API URL and the Rest/Data
    url_new <- stringr::str_extract(url, "(?:.+?/){3}")
    data <- strsplit(url, "(?:.+?/){3}")[[1]][2]

    # Deal with short/incomplete URL
    if (is.na(data)) {
      data <- NULL
    }
    if (is.na(url_new)) {
      url_new <-
        sprintf('https://%s:%s@api.meteomatics.com/',
                username,
                password)
      data <- NULL
    }

    # Call the httr::POST Function to get API Data
    if (is.null(output_dir)) {
      response <-
        httr::POST(
          url_new,
          httr::authenticate(username, password),
          httr::accept(headers),
          httr::content_type("text/plain"),
          body = data,
          timeout = timeout_seconds
        )
    } else {
      response <-
        httr::POST(
          url_new,
          httr::authenticate(username, password),
          httr::accept(headers),
          httr::content_type("text/plain"),
          body = data,
          timeout = timeout_seconds,
          httr::write_disk(output_dir, overwrite = TRUE)
        )
    }

  } else {
    # Error if request_type is neither "get" nor "post"
    stop(sprintf("Unknown request_type: %s", request_type))
  }

  if (response$status_code != 200) {
    # Error if the status_code of the query is not 200 -> print the Error Message of the API
    exceptions_code <- exceptions(response$status_code)
    stop(paste0(
      exceptions_code,
      ": ",
      httr::content(response, as = "text", encoding = "UTF-8")
    ))
  }

  return(response)
}
