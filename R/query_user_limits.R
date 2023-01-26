#' @title Query User Limits
#'
#' @description
#' Provides information about the users usage and limits
#'
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#'
#' @return A list with the limits for the following requests (only if the hard
#'         limit != 0): requests total', 'requests since last UTC midnight',
#'         'requests since HH:00:00', 'requests in the last 60 seconds',
#'         'requests in parallel'.
#'
#' @export
#'
#' @import httr
#' @import jsonlite
#'
#' @examples
#' username <- "r-community"
#' password <- "Utotugode673"
#' query_user_limits(username, password)

# Def Query User Limits Function: Get users usage and limits
query_user_limits <- function(username, password) {
  # Call the httr::GET Function to get API Data
  DEFAULT_API_BASE_URL <- constants("DEFAULT_API_BASE_URL")
  response <-
    httr::GET(sprintf(
      paste0(DEFAULT_API_BASE_URL, "/user_stats_json"),
      username,
      password
    ),
    timeout(310))

  if (response$status_code != 200) {
    # Error if the status_code of the query is not 200 -> print the Error Message of the API
    exceptions_code <- exceptions(response$status_code)
    stop(paste0(
      exceptions_code,
      ": ",
      httr::content(response, as = "text", encoding = "UTF-8")
    ))
  }

  # Extract user limits from HTTP response
  j <- jsonlite::fromJSON(content(response, 'text'))

  # Create a list with the limits for the following requests and return them only if the hard limit != 0
  respond <- list()
  key <-
    c(
      'requests total',
      'requests since last UTC midnight',
      'requests since HH:00:00',
      'requests in the last 60 seconds',
      'requests in parallel'
    )

  if (j$`user statistics`$`requests total`$`hard limit` != 0) {
    value <- c(
      j$`user statistics`$`requests total`$`used`,
      j$`user statistics`$`requests total`$`hard limit`
    )
    names(value) <- c('used', 'hard limit')
    respond[[key[1]]] <- value
  }
  if (j$`user statistics`$`requests since last UTC midnight`$`hard limit` != 0) {
    value <-
      c(
        j$`user statistics`$`requests since last UTC midnight`$`used`,
        j$`user statistics`$`requests since last UTC midnight`$`hard limit`
      )
    names(value) <- c('used', 'hard limit')
    respond[[key[2]]] <- value
  }
  if (j$`user statistics`$`requests since HH:00:00`$`hard limit` != 0) {
    value <- c(
      j$`user statistics`$`requests since HH:00:00`$`used`,
      j$`user statistics`$`requests since HH:00:00`$`hard limit`
    )
    names(value) <- c('used', 'hard limit')
    respond[[key[3]]] <- value
  }
  if (j$`user statistics`$`requests in the last 60 seconds`$`hard limit` != 0) {
    value <-
      c(
        j$`user statistics`$`requests in the last 60 seconds`$`used`,
        j$`user statistics`$`requests in the last 60 seconds`$`hard limit`
      )
    names(value) <- c('used', 'hard limit')
    respond[[key[4]]] <- value
  }
  if (j$`user statistics`$`requests in parallel`$`hard limit` != 0) {
    value <- c(
      j$`user statistics`$`requests in parallel`$`used`,
      j$`user statistics`$`requests in parallel`$`hard limit`
    )
    names(value) <- c('used', 'hard limit')
    respond[[key[5]]] <- value
  }

  return(respond)
}
