################################################################################
#
# FOURJS_START_COPYRIGHT(U,2015)
# Property of Four Js*
# (c) Copyright Four Js 2015, 2018. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples
# are accurate and suitable for your purposes. Their inclusion is purely for
# information purposes only.
# FOURJS_END_COPYRIGHT
#
IMPORT com
IMPORT XML

IMPORT FGL WSHelper

IMPORT FGL logger
IMPORT FGL http

DEFINE mThisRequest com.HttpServiceRequest

TYPE requestInfoType RECORD
    url               STRING,     # Request URL
    method            STRING,     # HTTP method
    contentType       STRING,     # check the Content-Type
    inputFormat       STRING,     # short word for Content Type 
    acceptFormat      STRING,     # check which format the client accepts
    outputFormat      STRING,     # short word for Accept
    scheme            STRING,
    host              STRING,
    port              STRING,
    resource          STRING,     # request resource
    path              STRING,
    sessionCookie     STRING,
    query             STRING,     # the query string
    items       DYNAMIC ARRAY OF RECORD
        keyName STRING,
        keyValue STRING
    END RECORD
END RECORD
DEFINE mRequestInfo requestInfoType

# Response definition
PUBLIC TYPE responseType RECORD
    code        INTEGER, # HTTP response code
    status      STRING,  # success, fail, or error
    description STRING,  # used for fail or error message
    data        STRING   # response body or error/fail cause or exception name
END RECORD
DEFINE mWrappedResponse responseType
 
DEFINE mBaseUri STRING

DEFINE mSessionCookie STRING

################################################################################
#+
#+ Method: setInterfaceRequestInfo
#+
#+ Description: Creates an object for the incoming REST request
#+
#+ @code
#+ CALL setRestRequest(request)
#+
#+ @param request : com.HTTPServiceRequest - REST style request for a resource
#+
#+ @return NONE
#+ 
FUNCTION setRestRequestInfo(incomingRequest com.HttpServiceRequest)
    DEFINE requestTokenizer base.StringTokenizer

    # Set base URI for parsing: default is for standalone GAS("/ws/r/rest/"); otherwise,
    # pointing to dispatcher (ex. "/genero/ws/r/rest/" )
    LET mBaseUri = IIF(fgl_getenv("WSBASEURI") IS NOT NULL, fgl_getenv("WSBASEURI"), "/ws/r/rest/")

    # Store the current request
    LET mThisRequest = incomingRequest

    # Split the REST request components
    LET mRequestInfo.url = mThisRequest.getUrl()
    CALL WSHelper.SplitURL(mRequestInfo.url) RETURNING mRequestInfo.scheme,
                                                       mRequestInfo.host,
                                                       mRequestInfo.port,
                                                       mRequestInfo.path,
                                                       mRequestInfo.query

    # Populate the query items
    CALL mThisRequest.getUrlQuery(mRequestInfo.items)
    
    # The resource substring start position can derive from length of baseUri constant rather than looping
    LET requestTokenizer = base.StringTokenizer.create(mRequestInfo.path.subString(mBaseUri.getLength(), mRequestInfo.path.getLength()), "/")
    LET mRequestInfo.resource = requestTokenizer.nextToken()

    # Get authorization cookie...
    LET mRequestInfo.sessionCookie = mThisRequest.findRequestCookie("GeneroAuthZ")

    # Set request method
    LET mRequestInfo.method = mThisRequest.getMethod()

    # Get and process Content-Type headers
    LET mRequestInfo.contentType = mThisRequest.getRequestHeader("Content-Type")
    CALL setInputFormat(mRequestInfo.contentType)
    CALL setOutputFormat(mRequestInfo.contentType)
    
END FUNCTION

################################################################################
#
# Mutator for request input content type
#
# TODO: for future in determining request format(JSON/XML)
#
FUNCTION setInputFormat(contentHeader STRING)

    IF contentHeader.getIndexOf("/xml",1) THEN LET mRequestInfo.inputFormat = "XML"
    ELSE LET mRequestInfo.inputFormat = "JSON"
    END IF

    RETURN
    
END FUNCTION

################################################################################
#
# Mutator for request output type
#
# TODO: for future in determining response format(JSON/XML)
#
FUNCTION setOutputFormat(contentHeader STRING)

    IF contentHeader.getIndexOf("/xml",1) THEN LET mRequestInfo.outputFormat = "XML"
    ELSE LET mRequestInfo.outputFormat = "JSON"
    END IF

    RETURN
    
END FUNCTION 

FUNCTION setResponse(statusCode STRING, statusClass STRING, statusDesc STRING, responseData STRING )

    LET mWrappedResponse.code = statusCode
    LET mWrappedResponse.status = statusClass
    LET mWrappedResponse.description = statusDesc
    LET mWrappedResponse.data = responseData

    RETURN

END FUNCTION 

FUNCTION getResponse()
    RETURN mWrappedResponse.*
END FUNCTION

################################################################################
#
# General accessor methods for the REST request informiation
#
FUNCTION getRequestRequest()
    RETURN mThisRequest
END FUNCTION

FUNCTION getRequestUrl()
    RETURN mRequestInfo.url
END FUNCTION

FUNCTION getRequestScheme()
    RETURN mRequestInfo.scheme
END FUNCTION 

FUNCTION getRequestHost()
    RETURN mRequestInfo.host
END FUNCTION 

FUNCTION getRequestPort()
    RETURN mRequestInfo.port
END FUNCTION 

FUNCTION getRequestPath()
    RETURN mRequestInfo.path
END FUNCTION 

FUNCTION getRequestQuery()
    RETURN mRequestInfo.query
END FUNCTION 

FUNCTION getSessionCookie()
    RETURN mRequestInfo.sessionCookie
END FUNCTION

FUNCTION getRestResource()
    RETURN mRequestInfo.resource
END FUNCTION 

FUNCTION getRequestMethod()
    RETURN mRequestInfo.method
END FUNCTION 

FUNCTION getCurrentRequest()
    RETURN mThisRequest
END FUNCTION

FUNCTION getRequestItems()
    RETURN mRequestInfo.items
END FUNCTION