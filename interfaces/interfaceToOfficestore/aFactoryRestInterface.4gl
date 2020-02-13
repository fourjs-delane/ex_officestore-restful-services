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
################################################################################
#+
#+ This module implements marshalling methods to interface with the officestore 
#+ domain with the use of domain resource factories.  The concept is that a 
#+ factory knows the resources required to create a product.  The factory
#+ invokes the resource methods to mine the raw materials(data) and create the
#+ product(response).
#+
IMPORT com
IMPORT util
IMPORT os

# GWS Helpers
IMPORT FGL WSHelper

# HTTP utility
IMPORT FGL http

# Logging utility
IMPORT FGL logger

# Factories to provide resource requested by REST service
IMPORT FGL restAccountFactory
IMPORT FGL restCategoryFactory
IMPORT FGL restCookieFactory
IMPORT FGL restCredentialFactory
IMPORT FGL restItemFactory
IMPORT FGL restOrderFactory
IMPORT FGL restOrderItemFactory
IMPORT FGL restProductFactory
IMPORT FGL restProductImageFactory
IMPORT FGL restSupplierFactory

DEFINE serviceResource DICTIONARY OF STRING
 
TYPE requestInfoType RECORD
    method            STRING,
    contentType       STRING,     # check the Content-Type
    inputFormat       STRING,     # short word for Content Type 
    acceptFormat      STRING,     # check which format the client accepts
    outputFormat      STRING,     # short word for Accept
    path              STRING,
    query             STRING,     # the query string
    items       DYNAMIC ARRAY OF RECORD
        keyName STRING,
        keyValue STRING
    END RECORD
END RECORD

DEFINE mRequestInfo requestInfoType

DEFINE wrappedResponse RECORD
    code    INTEGER, # HTTP response code
    status  STRING,  # success, fail, or error
    message STRING,  # used for fail or error message
    data    STRING   # response body or error/fail cause or exception name
END RECORD 
#
# TODO: Implement pagination(Range header vs. query-string(offset and limit)?
# TODO: Content range responses?
# TODO: What about sorting?
#
################################################################################
#+
#+ Method: marshalRestGet
#+
#+ Marshalling function to process REST query(GET) request
#+
#+    Invokes the respective resource factory to produce query results and
#+    sends a HTTP response
#+
#+    Possible status:
#+    200 (OK) – General success status code. Most common code to indicate success.
#+    400 (BAD REQUEST) – General error when fulfilling the request would cause an invalid state.
#+                        Domain validation errors, missing data, etc. are some examples.
#+    500 (INTERNAL SERVER ERROR) – The general catch-all error when the server-side throws an exception.
#+
#+ @code
#+ CALL marshalRESTQuery(request)
#+
#+ @param request : com.HTTPServiceRequest - REST style query for a resource
#+
#+ @return NONE
#+ 
FUNCTION marshalRestGet(request com.HTTPServiceRequest)
    DEFINE requestTokenizer base.StringTokenizer
    DEFINE url STRING
    DEFINE restResource STRING
    DEFINE queryFilter  STRING
    DEFINE factoryResponse STRING
    DEFINE statusCode STRING
    DEFINE baseUri STRING
    DEFINE authorizationHeader STRING
    DEFINE sessionCookie STRING
    
    -- debug stuff
    DEFINE query DYNAMIC ARRAY OF RECORD
          name STRING,
          value  STRING
    END RECORD
    -- end debug stuff

    # Set base URI for parsing: default is for standalone GAS("/ws/r/rest/"); otherwise,
    # pointing to dispatcher (ex. "/genero/ws/r/rest/" )
    LET baseUri = IIF(fgl_getenv("WSBASEURI") IS NOT NULL, fgl_getenv("WSBASEURI"), "/ws/r/rest/")
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTQuery",
        SFMT("baseUri: %1", baseUri))

    CALL setInputFormat(request.getRequestHeader("Content-Type").toLowerCase())
    CALL setOutputFormat(request.getRequestHeader("Accept").toLowerCase())
    CALL request.setResponseHeader("Cache","no-cache")

    # Get the REST request URL
    LET url = request.getUrlPath()
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTQuery",
        SFMT("Host: %1 Port: %2 Path: %3", request.getUrlHost(), request.getUrlPort(), request.getUrlPath()))

    CALL request.getUrlQuery(query)

    # The resource substring start position can derive from length of baseUri constant rather than looping
    LET requestTokenizer = base.StringTokenizer.create(url.subString(baseUri.getLength(), url.getLength()), "/")
    LET restResource = requestTokenizer.nextToken()

    # The request "query" appears after the resource
    LET queryFilter = util.JSON.stringify(query)

    # Assume success(200) unless otherwise reset
    LET statusCode = HTTP_OK
    CALL request.setResponseHeader("Content-Type","application/json")
    CALL request.setResponseHeader("Cache","no-cache")

    # Check authorization cookie...
    LET sessionCookie = request.findRequestCookie("GeneroAuthZ")
    IF restCookieFactory.checkCookies(sessionCookie) 
    OR restResource = "ping"
    THEN
        # Determine the resource and process the request
        CASE restResource

            WHEN ( "ping" )
                LET authorizationHeader = request.getRequestHeader("Officestore-Credential")
                CALL restCredentialFactory.processAuthorization(authorizationHeader) 
                    RETURNING statusCode, factoryResponse 
                IF statusCode = HTTP_OK THEN
                    # Create a session cookie(s)
                    CALL restCookieFactory.bakeCookies("GeneroAuthZ", "/", TRUE)
                    # set the cookies in the resonse
                    CALL request.setResponseCookies(restCookieFactory.getCookies())
                END IF


        # Process account list query; assume query appears after the "?"; 
            # i.e. for "accounts?user=bloggs" would be "bloggs"
            WHEN ( "accounts" )
                CALL restAccountFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse 
                    
            # Process category list query; assume query appears after the "?"; 
            # i.e. for "categories?catnum=SUPPLIES" would be "SUPPLIES"
            WHEN ( "categories" )        
                CALL restCategoryFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse 

            # Process orderItem list query; assume query appears after the "?";
            # i.e. for "items?itemnum=AR-001-A" would be "AR-001-A"
            WHEN ( "items" )
                CALL restItemFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse 

            # Process order list query; assume query appears after the "?"; 
            # i.e. for "orders?ordernum=952121" would be "952121"
            WHEN ( "orders" )
                CALL restOrderFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse 

            # Process item list query; assume query appears after the "?"; 
            # i.e. for "orderItem?ordernum=7" would be "7"
            WHEN ( "orderitems" )
                CALL restOrderItemFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse 

            # Process item list query; assume query appears after the "?"; 
            # i.e. for "orderItem?ordernum=7" would be "7"
            WHEN ( "products" )
                CALL restProductFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse 

            # Process supplier list query; assume query appears after the "?"; 
            # i.e. for "suppliers/101" would be "101"
            WHEN ( "suppliers" )
                CALL restSupplierFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse

            # Process product image query; assume query appears after the "?"; 
            # i.e. for "productImages?prodnum=AR-101"
            WHEN ( "productImages" )
                CALL restProductImageFactory.processQuery(queryFilter)
                RETURNING statusCode, factoryResponse

            # Process discovery query; 
            #WHEN ( "" )
            #    LET factoryResponse = getServicesDiscover()
            #    LET statusCode = HTTP_OK
                
            OTHERWISE
                IF ( url = "/favicon.ico" ) THEN
                    # Handle the browser "favicon.ico" request and errors in general.  Do we need to?
                    LET factoryResponse = "[{}]"
                    LET statusCode = HTTP_OK_ACCEPTED
                ELSE
                    LET statusCode = HTTP_NOTFOUND
                    LET wrappedResponse.code = HTTP_NOTFOUND
                    LET wrappedResponse.message = SFMT("Unknown resource requested/Operation not allowed: %1", restResource)
                    LET wrappedResponse.status = "ERROR"
                    LET wrappedResponse.data = "[{}]"
                    LET factoryResponse = util.JSON.stringify(wrappedResponse)
                END IF
        END CASE
    ELSE
        LET statusCode = HTTP_NOTAUTH
        LET wrappedResponse.code = HTTP_NOTAUTH
        LET wrappedResponse.message = SFMT("Access denied without valid credentials. %1", restResource)
        LET wrappedResponse.status = "ERROR"
        LET wrappedResponse.data = "[{}]"
        LET factoryResponse = util.JSON.stringify(wrappedResponse)
    END IF 
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTQuery",
        SFMT("%1 factory response: %2", restResource, factoryResponse))

    # The productImages resource requires a "sendFileResponse"
    IF  restResource = "productImages" THEN
        IF statusCode = HTTP_OK THEN
            CALL request.sendFileResponse(statusCode,NULL, os.Path.join(fgl_GETENV("IMAGEPATH"),factoryResponse) )
        ELSE
            CALL request.sendTextResponse(HTTP_NOTFOUND,NULL, "Not found")
        END IF 
    ELSE
        # Description is NULL for default value based on status code; 
        # otherwise a message can be supplied
        CALL request.sendTextResponse(statusCode, NULL, factoryResponse)
    END IF 

    RETURN
    
END FUNCTION

################################################################################
#+
#+ Method: marshalRestPut
#+
#+ Marshalling function to process REST update(PUT) request
#+
#+    Invokes the respective resource factory to perform an update to the resource
#+    and sends a HTTP response
#+
#+ @code
#+ CALL marshalRESTUpdate(request)
#+
#+ @param request : com.HTTPServiceRequest - REST style update for a resource
#+
#+ @return NONE
#+
FUNCTION marshalRestPut(request com.HTTPServiceRequest)
    DEFINE requestTokenizer base.StringTokenizer
    DEFINE url, baseUri STRING
    DEFINE restResource STRING
    DEFINE updatePayload  STRING
    DEFINE factoryResponse STRING
    DEFINE statusCode INTEGER 
    DEFINE sessionCookie STRING
   
    # Set base URI for parsing: default is for standalone GAS("/ws/r/rest/"); otherwise,
    # pointing to dispatcher (ex. "/genero/ws/r/rest/" )
    LET baseUri = IIF(fgl_getenv("WSBASEURI") IS NOT NULL, fgl_getenv("WSBASEURI"), "/ws/r/rest/")
    
    CALL setInputFormat(request.getRequestHeader("Content-Type").toLowerCase())
    CALL setOutputFormat(request.getRequestHeader("Accept").toLowerCase())

    # Get the REST request URL
    LET url = request.getUrlPath()
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTUpdate",
        SFMT("Host: %1 Port: %2 Path: %3", request.getUrlHost(), request.getUrlPort(), request.getUrlPath()))

    # The substring start position should derive from length of baseUri constant
    LET requestTokenizer = base.StringTokenizer.create(url.subString(baseUri.getLength(), url.getLength()), "/")

    # This first token will be the REST resource requested
    LET restResource = requestTokenizer.nextToken()
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTUpdate",
        SFMT("Resource: %1", restResource))

    # Read the request data
    LET updatePayload = request.readTextRequest()
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTUpdate",
        SFMT("Update payload: %1", updatePayload))

    # Assume success(200) unless otherwise reset
    LET statusCode = HTTP_OK
    CALL request.setResponseHeader("Content-Type","application/json")
    CALL request.setResponseHeader("Cache","no-cache")

    # Check authorization cookie...
    LET sessionCookie = request.findRequestCookie("GeneroAuthZ")
    IF restCookieFactory.checkCookies(sessionCookie) THEN
        # Determine and process the resource
        CASE restResource
        # Process account update payload
        WHEN ( "accounts" )
            CALL restAccountFactory.processUpdate(updatePayload) RETURNING statusCode, factoryResponse 
                         
        OTHERWISE
            LET statusCode = HTTP_NOTALLOWED
            LET wrappedResponse.code = HTTP_NOTALLOWED
            LET wrappedResponse.message = "Update not allowed for resource"
            LET wrappedResponse.status = "ERROR"
            LET wrappedResponse.data = "[{}]"
            LET factoryResponse = util.JSON.stringify(wrappedResponse)
        END CASE

    ELSE
        LET statusCode = HTTP_NOTAUTH
        LET wrappedResponse.code = HTTP_NOTAUTH
        LET wrappedResponse.message = SFMT("Access denied without valid credentials. %1", restResource)
        LET wrappedResponse.status = "ERROR"
        LET wrappedResponse.data = "[{}]"
        LET factoryResponse = util.JSON.stringify(wrappedResponse)
    END IF 

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTUpdate",
        SFMT("%1 factory response: %2", restResource, factoryResponse))

    # Description is NULL for default value based on status code; 
    # otherwise a message can be supplied
    CALL request.sendTextResponse(statusCode, NULL, factoryResponse)

    RETURN
    
END FUNCTION

################################################################################
#+
#+ Method: marshalRestPost
#+
#+ Marshalling function to process REST insert(POST) request
#+
#+    Invokes the respective resource factory to create a new resource element
#+    and sends a HTTP response
#+
#+ @code
#+ CALL marshalRESTInsert(request)
#+
#+ @param request : com.HTTPServiceRequest - REST style insert for a resource
#+
#+ @return NONE
#+
FUNCTION marshalRestPost(request com.HTTPServiceRequest)
    DEFINE requestTokenizer base.StringTokenizer
    DEFINE url, baseUri STRING
    DEFINE restResource STRING
    DEFINE requestPayload   STRING
    DEFINE factoryResponse STRING
    DEFINE statusCode STRING
    
    DEFINE cookies WSServerCookiesType
    DEFINE token STRING

    # Set base URI for parsing: default is for standalone GAS("/ws/r/rest/"); otherwise,
    # pointing to dispatcher (ex. "/genero/ws/r/rest/" )
    LET baseUri = IIF(fgl_getenv("WSBASEURI") IS NOT NULL, fgl_getenv("WSBASEURI"), "/ws/r/rest/")
    
    # Get the REST request URL
    LET url = request.getUrlPath()

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTInsert",
        SFMT("Host: %1 Port: %2 Path: %3", request.getUrlHost(), request.getUrlPort(), request.getUrlPath()))

    # The substring start position should derive from length of baseUri constant
    LET requestTokenizer = base.StringTokenizer.create(url.subString(baseUri.getLength(), url.getLength()), "/")

    # This first token will be the REST resource requested
    LET restResource = requestTokenizer.nextToken()
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTInsert",
        SFMT("Resource: %1", restResource))

    # Read the request data
    LET requestPayload = request.readTextRequest()
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTInsert",
        SFMT("Insert payload: %1", requestPayload))

    CALL request.setResponseHeader("Content-Type","application/json")
    CALL request.setResponseHeader("Cache","no-cache")
    
    # Determine and process the request
    CASE restResource
    # Process authorization insert, credentials TBD; 
    # TODO: may need to move authZ up to the server
    # Process heterogeneous account update; assume queryToken is the key value or NULL; 
    # i.e. for "accounts/smith" would be "smith":NULL could(cautiously) update all accounts            
    WHEN ( "accounts" )
        CALL restAccountFactory.processInsert(requestPayload) RETURNING statusCode, factoryResponse 
     
    OTHERWISE
        LET statusCode = HTTP_NOTALLOWED
        LET wrappedResponse.code = HTTP_NOTALLOWED
        LET wrappedResponse.message = "Resource creation not allowed"
        LET wrappedResponse.status = "ERROR"
        LET wrappedResponse.data = "[{}]"
        LET factoryResponse = util.JSON.stringify(wrappedResponse)
    END CASE

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTInsert",
        SFMT("%1 factory response: %2", restResource, factoryResponse))

    # Description is NULL for default value based on status code; 
    # otherwise a message can be supplied
    CALL request.sendTextResponse(statusCode, NULL, factoryResponse)

    RETURN
    
END FUNCTION

################################################################################
#+
#+ Method: marshalRESTDelete
#+
#+ Marshalling function to process REST delete(DELETE) request
#+
#+    Invokes the respective resource factory to delete and existing resource
#+    element and sends a HTTP response
#+
#+ @code
#+ CALL marshalRESTDelete(request)
#+
#+ @param request : com.HTTPServiceRequest - REST style delete for a resource
#+
#+ @return NONE
#+
FUNCTION marshalRestDelete(request com.HTTPServiceRequest)
    DEFINE requestTokenizer base.StringTokenizer
    DEFINE url, baseUri STRING
    DEFINE restResource STRING
    DEFINE queryFilter  STRING
    DEFINE factoryResponse STRING
    DEFINE statusCode STRING
    DEFINE sessionCookie STRING

    DEFINE query DYNAMIC ARRAY OF RECORD
          name STRING,
          value  STRING
    END RECORD

    # Set base URI for parsing: default is for standalone GAS("/ws/r/rest/"); otherwise,
    # pointing to dispatcher (ex. "/genero/ws/r/rest/" )
    LET baseUri = IIF(fgl_getenv("WSBASEURI") IS NOT NULL, fgl_getenv("WSBASEURI"), "/ws/r/rest/")
    
    CALL setInputFormat(request.getRequestHeader("Content-Type").toLowerCase())
    CALL setOutputFormat(request.getRequestHeader("Accept").toLowerCase())

    # Get the REST request URL
    LET url = request.getUrlPath()
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTDelete",
        SFMT("Host: %1 Port: %2 Path: %3", request.getUrlHost(), request.getUrlPort(), request.getUrlPath()))

    CALL request.getUrlQuery(query)

    # The resource substring start position can derive from length of baseUri constant rather than looping
    LET requestTokenizer = base.StringTokenizer.create(url.subString(baseUri.getLength(), url.getLength()), "/")
    LET restResource = requestTokenizer.nextToken()

    # The request "query" appears after the resource
    LET queryFilter = util.JSON.stringify(query)

    CALL request.setResponseHeader("Content-Type","application/json")
    CALL request.setResponseHeader("Cache","no-cache")
    
    # Check authorization cookie...
    LET sessionCookie = request.findRequestCookie("GeneroAuthZ")
    IF restCookieFactory.checkCookies(sessionCookie) THEN
        # Determine and process the request
        CASE restResource
        # TODO:Process authorization delete, TBD; 
        WHEN ( "authZ" )
            # Processing for authorization request 
            CALL restCredentialFactory.removeAuthorization(request) RETURNING statusCode, factoryResponse -- .processInsert(insertPayload) RETURNING statusCode, factoryResponse 

        # Process heterogeneous account delete; assume queryToken is the query value; 
        # i.e. for "accounts/smith" would be "smith"
        WHEN ( "accounts" )
            CALL restAccountFactory.processDelete(queryFilter) RETURNING statusCode, factoryResponse 
         
        OTHERWISE
            LET statusCode = HTTP_NOTALLOWED
            LET wrappedResponse.code = HTTP_NOTALLOWED
            LET wrappedResponse.message = "Resource deletion not allowed"
            LET wrappedResponse.status = "ERROR"
            LET wrappedResponse.data = "[{}]"
            LET factoryResponse = util.JSON.stringify(wrappedResponse)
        END CASE

    ELSE
        LET statusCode = HTTP_NOTAUTH
        LET wrappedResponse.code = HTTP_NOTAUTH
        LET wrappedResponse.message = SFMT("Access denied without valid credentials. %1", restResource)
        LET wrappedResponse.status = "ERROR"
        LET wrappedResponse.data = "[{}]"
        LET factoryResponse = util.JSON.stringify(wrappedResponse)
    END IF 

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("factoryInterface:%1",__LINE__),"marshalRESTDelete",
        SFMT("%1 factory response: %2", restResource, factoryResponse))

    # Description is NULL for default value based on status code; 
    # otherwise a message can be supplied
    CALL request.sendTextResponse(statusCode, NULL, factoryResponse)

    RETURN
    
END FUNCTION

################################################################################
#
# Provides documentation for the web service
#
# TODO: Is this resource specific or an API docuement?
PRIVATE FUNCTION getServicesDiscover() RETURNS STRING 
    LET wrappedResponse.code = HTTP_OK
    LET wrappedResponse.status = "success"
    LET wrappedResponse.message = "Resource discovery"

    RETURN util.JSON.stringify(wrappedResponse)
END FUNCTION 

{
################################################################################
#
# Splits an URL into resource and query string parts
#
# TODO: Is parseRequest(url) used now?
FUNCTION parseRequest(url STRING) RETURNS (STRING, STRING)
    DEFINE  i         INTEGER
    DEFINE  query     STRING
    DEFINE  resource  STRING
    LET i = url.getIndexOf("?",1)
    IF i>1 THEN
        LET query = url.subString(i+1,url.getLength())
        LET resource = url.subString(1,i-1)
    ELSE
        LET query = NULL
        LET resource = url.subString(1,url.getLength())
    END IF

    RETURN resource, query

END FUNCTION

################################################################################
#
# Parse given string and returns a dynamic array of the elements inside the
#   query string
#
# TODO: Is parseQueryString() used now?
#
FUNCTION parseQueryString(str STRING)
    DEFINE  tkz   base.StringTokenizer
    DEFINE  token STRING
    DEFINE  ind   INTEGER
    DEFINE  ret   DYNAMIC ARRAY OF RECORD
                  qname   STRING,
                  qvalue  STRING
                END RECORD
    INITIALIZE ret TO NULL
    LET tkz = base.StringTokenizer.create(str,"&")
    WHILE (tkz.hasMoreTokens())
        LET token = tkz.nextToken()
        CALL ret.appendElement()
        LET ind = ind + 1
        CALL extractKeyValueFromQuery(token) RETURNING ret[ind].qname,ret[ind].qvalue
    END WHILE

    RETURN ret

END FUNCTION

################################################################################
#
# Extract Key and Value from query string
#
# TODO: Is extractKeyValueFromQuery() used now?
FUNCTION extractKeyValueFromQuery(str STRING) RETURNS (STRING, STRING)
    DEFINE ind  INTEGER
    LET ind = str.getIndexOf("=",1)
    IF ind>1 THEN
        RETURN str.subString(1,ind-1),str.subString(ind+1,str.getLength())
    ELSE
        RETURN str,NULL
    END IF
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
}