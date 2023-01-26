#' @title Query User Features
#'
#' @description
#' Provides information about your Meteomatics licensing options
#'
#' @param username A character vector containing the MM API username.
#' @param password A character vector containing the MM API password.
#'
#' @return A named character vector containing the licensing options.
#' @export
#'
#' @import httr
#' @import jsonlite
#'
#' @examples
#' username <- "r-community"
#' password <- "Utotugode673"
#' query_user_features(username, password)

# Def Query User Features Function
query_user_features <- function(username, password) {
  .Deprecated(
    msg = paste0(
      "This function will be removed/renamed because it only provides ",
      "info about the licensing options and not real user statistics. ",
      "In addition, do not programmatically rely on user features since ",
      "the returned keys can change over time due to internal changes."
    )
  )

  # Call the httr::GET Function to get API Data
  DEFAULT_API_BASE_URL <- constants("DEFAULT_API_BASE_URL")
  response <-
    httr::GET(sprintf(
      paste0(DEFAULT_API_BASE_URL, "/user_stats_json"),
      username,
      password
    ), timeout = 310)

  if (response$status_code != 200) {
    # Error if the status_code of the query is not 200 -> print the Error Message of the API
    exceptions_code <- exceptions(response$status_code)
    stop(paste0(
      exceptions_code,
      ": ",
      httr::content(response, as = "text", encoding = "UTF-8")
    ))
  }

  # Extract user statistics from HTTP response
  j <- jsonlite::fromJSON(httr::content(response, 'text'))

  # Summarize desired Info in a Named Vector
  res <- logical(3)
  names(res) <-
    c('area request option',
      'historic request option',
      'model select option')
  res['area request option'] <-
    j$`user statistics`$`area request option`
  res['historic request option'] <-
    j$`user statistics`$`historic request option`
  res['model select option'] <-
    j$`user statistics`$`model select option`

  return(res)
}
