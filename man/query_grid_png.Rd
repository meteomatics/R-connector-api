% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/query_grid_png.R
\name{query_grid_png}
\alias{query_grid_png}
\title{Query a Grid with png as Output Format}
\usage{
query_grid_png(
  filename,
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
  request_type = "GET",
  ...
)
}
\arguments{
\item{filename}{A string specifying the directory and filename of
the output file. For example, it can be of the form:
paste("/your/desired/directory", "filename.png", sep = "/").}

\item{datetime}{An ISOdatetime of the format \%Y-\%m-\%dT\%H:\%M:\%OSZ. The date and
time gets converted into UTC if another timezone is selected.}

\item{parameter_grid}{A string containing the parameter of interest.}

\item{lat_N}{A number giving the most northern coordinate of the desired grid.}

\item{lon_W}{A number giving the most western coordinate of the desired grid.}

\item{lat_S}{A number giving the most southern coordinate of the desired grid.}

\item{lon_E}{A number giving the most eastern coordinate of the desired grid.}

\item{resolution}{The resolution in latitude and longitude direction. If the
resolution is in degrees then in the form "0.1,0.5", or if the
resolution is in the number of latitudes/longitudes then in
the form "4x5".}

\item{username}{A string containing the MM API username.}

\item{password}{A string containing the MM API password.}

\item{model}{A string containing the model of interest. The default
value is NULL, meaning that the model mix is selected.}

\item{ens_select}{A string containing the ensembles of interest. The
default value is NULL. Possible inputs are for example:
"median"; "member:5"; "member:1-50"; "member:0"; "mean";
"quantile0.2".}

\item{cluster_select}{A string containing the cluster of interest.
The default value is NULL. Possible inputs are for example:
"cluster:1"; "cluster:1-6".}

\item{interp_select}{A string specifying the interpolation: The
default value is NULL. A possible input is:
"gradient_interpolation".}

\item{request_type}{A string containing the request type - either
"get" (Default) or "post".}

\item{...}{A list of additional arguments.}
}
\value{
A png image of the queried grid.
}
\description{
Retrieve a grid from the Meteomatics Weather API and save it as png file
}
\examples{
\dontrun{
username <- "r-community"
password <- "Utotugode673"
filename <- paste("/Users/Desktop", "grid.png", sep = "/")
datetime <- ISOdatetime(year = as.integer(strftime(lubridate::today(), '\%Y')),
                        month = as.integer(strftime(lubridate::today(), '\%m')),
                        day = as.integer(strftime(lubridate::today(), '\%d')) - 1,
                        hour = 00, min = 00, sec = 00, tz = "UTC")
parameter <- "t_2m:C"
lat_N <- 90
lon_W <- -180
lat_S <- -90
lon_E <- 180
resolution <- "400x600"
model <- "mix"
query_grid_png(filename, datetime, parameter, lat_N, lon_W, lat_S, lon_E,
               resolution, username, password,
               model = model)
}
}
