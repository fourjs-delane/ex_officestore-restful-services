IMPORT com
#

###
#+ HTTP methods
PUBLIC CONSTANT HTTP_GET                                = "GET"
PUBLIC CONSTANT HTTP_POST                               = "POST"
PUBLIC CONSTANT HTTP_HEAD                               = "HEAD"
PUBLIC CONSTANT HTTP_PUT                                = "PUT"
PUBLIC CONSTANT HTTP_DELETE                             = "DELETE"
PUBLIC CONSTANT HTTP_TRACE                              = "TRACE"
PUBLIC CONSTANT HTTP_OPTIONS                            = "OPTIONS"
PUBLIC CONSTANT HTTP_CONNECT                            = "CONNECT"
PUBLIC CONSTANT HTTP_PATCH                              = "PATCH"
#
PUBLIC CONSTANT DEF_METHOD                              = "GET"

#+ HTTP response list
PUBLIC CONSTANT HTTP_OK SMALLINT                        = 200
PUBLIC CONSTANT HTTP_OK_CREATED SMALLINT                = 201
PUBLIC CONSTANT HTTP_OK_ACCEPTED SMALLINT               = 202
PUBLIC CONSTANT HTTP_OK_NOCONTENT SMALLINT              = 204
#
PUBLIC CONSTANT HTTP_REDIR_MOVED SMALLINT               = 301
PUBLIC CONSTANT HTTP_REDIR_FOUND SMALLINT               = 302
PUBLIC CONSTANT HTTP_REDIR_SEEOTHER SMALLINT            = 303
PUBLIC CONSTANT HTTP_REDIR_NOTMODIFIED SMALLINT         = 304
PUBLIC CONSTANT HTTP_REDIR_TEMPMOVED SMALLINT           = 307
#
PUBLIC CONSTANT HTTP_BADREQUEST SMALLINT                = 400
PUBLIC CONSTANT HTTP_NOTAUTH SMALLINT                   = 401
PUBLIC CONSTANT HTTP_PAYMENTREQD SMALLINT               = 402
PUBLIC CONSTANT HTTP_FORBIDDEN SMALLINT                 = 403
PUBLIC CONSTANT HTTP_NOTFOUND SMALLINT                  = 404
PUBLIC CONSTANT HTTP_NOTALLOWED SMALLINT                = 405
PUBLIC CONSTANT HTTP_TIMEOUT SMALLINT                   = 408
PUBLIC CONSTANT HTTP_GONE SMALLINT                      = 410
#
PUBLIC CONSTANT HTTP_INTERNALERROR SMALLINT             = 500
PUBLIC CONSTANT HTTP_NOTIMPLEMENTED SMALLINT            = 501
PUBLIC CONSTANT HTTP_SERVICEUNAVAILABLE SMALLINT        = 503

{
#+ Standard header keys and values
PUBLIC CONSTANT HDR_CONTENTTYPE = "Content-Type"
PUBLIC CONSTANT HDR_ACCEPT = "Accept"
#+ IP address lookup
PUBLIC CONSTANT HDR_REMOTE_ADDR = "REMOTE_ADDR"
PUBLIC CONSTANT HDR_CLIENTIP = "HTTP_CLIENT_IP"
PUBLIC CONSTANT HDR_X_FORWARDED_FOR = "HTTP_X_FORWARDED_FOR"
#+ Local headers
PUBLIC CONSTANT HDR_AUTHKEY = "Authorization"
}


###
#+ Public variables
PUBLIC DEFINE HTTPMETHOD        DICTIONARY OF STRING --DYNAMIC ARRAY OF t_Enum
PUBLIC DEFINE WEBPROTOCOL       DICTIONARY OF STRING --DYNAMIC ARRAY OF t_Enum
#PUBLIC DEFINE HTTPSTATUS        DICTIONARY OF STRING --DYNAMIC ARRAY OF t_Enum
PUBLIC DEFINE HTTPSTATUSDESC    DICTIONARY OF STRING --DYNAMIC ARRAY OF t_Enum



###
#+ Initializes static values for HTTP method.
PUBLIC FUNCTION initHttpMethods()
	# parameters
	--DEFINE arr DYNAMIC ARRAY OF t_Enum
    
    #+ HTTP methods
    LET HTTPMETHOD["HTTP_GET"]     = "GET"
    LET HTTPMETHOD["HTTP_POST"]    = "POST"
    LET HTTPMETHOD["HTTP_HEAD"]    = "HEAD"
    LET HTTPMETHOD["HTTP_PUT"]     = "PUT"
    LET HTTPMETHOD["HTTP_DELETE"]  = "DELETE"
    LET HTTPMETHOD["HTTP_TRACE"]   = "TRACE"
    LET HTTPMETHOD["HTTP_OPTIONS"] = "OPTIONS"
    LET HTTPMETHOD["HTTP_CONNECT"] = "CONNECT"
    LET HTTPMETHOD["HTTP_PATCH"]   = "PATCH"

    RETURN
END FUNCTION

###
#+ Initializes static values for log levels.
PUBLIC FUNCTION initHttpStatuses()
	# parameters

#+ HTTP response list descriptions
    LET HTTPSTATUSDESC[HTTP_OK]                     = "OK"
    LET HTTPSTATUSDESC[HTTP_OK_CREATED]             = "Created"
    LET HTTPSTATUSDESC[HTTP_OK_ACCEPTED]            = "Accepted"
    LET HTTPSTATUSDESC[HTTP_OK_NOCONTENT]           = "No Content"
#
    LET HTTPSTATUSDESC[HTTP_REDIR_MOVED]            = "Moved"
    LET HTTPSTATUSDESC[HTTP_REDIR_FOUND]            = "Found"
    LET HTTPSTATUSDESC[HTTP_REDIR_SEEOTHER]         = "See Other"
    LET HTTPSTATUSDESC[HTTP_REDIR_NOTMODIFIED]      = "Not Modified"
    LET HTTPSTATUSDESC[HTTP_REDIR_TEMPMOVED]        = "Temporarily Moved"
#
    LET HTTPSTATUSDESC[HTTP_BADREQUEST]             = "Bad Request"
    LET HTTPSTATUSDESC[HTTP_NOTAUTH]                = "Unauthorized"
    LET HTTPSTATUSDESC[HTTP_PAYMENTREQD]            = "Payment Required"
    LET HTTPSTATUSDESC[HTTP_FORBIDDEN]              = "Forbidden"
    LET HTTPSTATUSDESC[HTTP_NOTFOUND]               = "Not Found"
    LET HTTPSTATUSDESC[HTTP_NOTALLOWED]             = "Method Not Allowed"
    LET HTTPSTATUSDESC[HTTP_TIMEOUT]                = "Request Timeout"
    LET HTTPSTATUSDESC[HTTP_GONE]                   = "Gone"
#
    LET HTTPSTATUSDESC[HTTP_INTERNALERROR]          = "Internal Server Error"
    LET HTTPSTATUSDESC[HTTP_NOTIMPLEMENTED]         = "Not Implemented"
    LET HTTPSTATUSDESC[HTTP_SERVICEUNAVAILABLE]     = "Service Unavailable"    

END FUNCTION

###
#+ If true, a payload (request body) is valid given the method of the call; only certain
#+ methods allow for or define behavior for a request body.
#+
#+ @params method:STRING - HTTP method to test
PUBLIC FUNCTION isHttpPayloadValid(method)
	# parameter
	DEFINE method STRING

	RETURN NOT (method = HTTP_GET
		OR method = HTTP_HEAD
		OR method = HTTP_OPTIONS
		OR method = HTTP_CONNECT
		OR method = HTTP_TRACE)
END FUNCTION
