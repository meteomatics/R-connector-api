% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/query_user_limits.R
\name{query_user_limits}
\alias{query_user_limits}
\title{Query User Limits}
\usage{
query_user_limits(username, password)
}
\arguments{
\item{username}{A character vector containing the MM API username.}

\item{password}{A character vector containing the MM API password.}
}
\value{
A list with the limits for the following requests (only if the hard
limit != 0): requests total', 'requests since last UTC midnight',
'requests since HH:00:00', 'requests in the last 60 seconds',
'requests in parallel'.
}
\description{
Provides information about the users usage and limits
}
\examples{
username <- "r-community"
password <- "Utotugode673"
query_user_limits(username, password)
}
