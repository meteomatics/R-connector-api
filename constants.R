# ------------------------------------------------------------------------------
# -------------------- Collect all constant definitions here -------------------
# ------------------------------------------------------------------------------
library(sets)
source('VERSION.R')

DEFAULT_API_BASE_URL <- "https://%s:%s@api.meteomatics.com"

VERSION <- sprintf('R_v{%s%s', VERSION, '}')

NA_VALUES <- tuple(c(-666, -777, -888, -999))

LOGGERNAME <- "meteomatics-api"

logdepth <- 0 