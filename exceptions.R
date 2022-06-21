exceptions <- list("206" = "PartialContent",
                   "400" = "BadRequest",
                   "401" = "Unauthorized",
                   "402" = "PaymentRequired",
                   "403" = "Forbidden",
                   "404" = "NotFound",
                   "408" = "RequestTimeout",
                   "413" = "PayloadTooLarge",
                   "414" = "UriTooLong",
                   "429" = "TooManyRequests",
                   "500" = "InternalServerError",
                   "501" = "NotImplemented",	
                   "503" = "ServiceUnavailable",	
                   "504" = "GatewayTimeout",	
                   "505" = "HTTPVersionNotSupported")

# 100	Continue	Handshake/Authorization 
# 200	OK	
# 206	Partial Content	further clarification about what is available in the error message (e.g. temporal or spatial availability of the queried model)
# 400	Bad Request	further clarification about what part of the URL is wrong in the message
# 401	Unauthorized	Handshake/Authorization
# 402	Payment Required	Handshake/Authorization
# 403	Forbidden	Handshake/Authorization
# 404	Not Found	further clarification about what is available in the error message (e.g. temporal or spatial availability of the queried model)
# 408	Request Time-Out	
# 413	Request Entity Too Large	too much data queried
# 414	Request-URI Too Large	too long URI (try to rewrite)
# 429	Too Many Requests	limits of license reached
# 500	Internal Server Error	further clarification about the problem in the message
# 501	Not Implemented	
# 503	Service Unavailable	
# 504	Gateway Time-Out	
# 505	HTTP version not supported