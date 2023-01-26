# ------------------------------------------------------------------------------
# -------------------- Collect all constant definitions here -------------------
# ------------------------------------------------------------------------------
#' @title Constants
#'
#' @description
#' All constants are defined within this list
#'
#' @param const A character vector containing the name of the constant.
#'
#' @return The value of the desired constant.
#'
#' @importFrom sets tuple
#' @noRd
#'
#' @examples
#' constants("DEFAULT_API_BASE_URL")

constants <- function(const) {
  constants_list <-
    list(
      "DEFAULT_API_BASE_URL" = "https://%s:%s@api.meteomatics.com",
      "VERSION" = "R_v{4.1.1}",
      "NA_VALUES" = sets::tuple(c(-666,-777,-888,-999))
    )

  return(constants_list[[which(names(constants_list) == const)]])
}

# # MM API base URL
# DEFAULT_API_BASE_URL <- "https://%s:%s@api.meteomatics.com"
#
# # Connector Version
# vers <- "4.1.1"
# VERSION <- sprintf('R_v{%s%s', vers, '}')
#
# # MM API na values
# NA_VALUES <- tuple(c(-666, -777, -888, -999))
