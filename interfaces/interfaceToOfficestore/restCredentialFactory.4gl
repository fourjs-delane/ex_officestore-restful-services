################################################################################
#
# FOURJS_START_COPYRIGHT(U,2015)
# Property of Four Js*
# (c) Copyright Four Js 2015, 2017. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples
# are accurate and suitable for your purposes. Their inclusion is purely for
# information purposes only.
# FOURJS_END_COPYRIGHT
#
IMPORT util
IMPORT com
IMPORT security

# Logging utility
IMPORT FGL logger

# HTTP Utility
IMPORT FGL http

# Resource domain
IMPORT FGL credential

DEFINE wrappedResponse RECORD
    code    INTEGER, # HTTP response code
    status  STRING,  # success, fail, or error
    message STRING,  # used for fail or error message
    data    STRING   # response body or error/fail cause or exception name
END RECORD 

################################################################################
#+
#+ Method: processAuthorization
#+
#+ Description: Performs tasks to validate a user login
#+
#+ @code
#+ CALL processAuthorization(userLogin STRING) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ userLogin STRING
#+
#+ @return
#+ NONE
#+
#+ @return
#+ status : HTTP status code
#+ wrappedResponse : JSON encoded string   
#+
FUNCTION processAuthorization(userLogin STRING) RETURNS (INTEGER, STRING)
    DEFINE queryException INTEGER
    DEFINE tokenizer base.StringTokenizer 
    DEFINE authorizationMethod, userId, password STRING
    
    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 

    TRY 
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("credentialFactory:%1",__LINE__),"processAuthorization",
            SFMT("Query filter: %1", userLogin))
                         

        # Parse for method and credentials
        LET tokenizer = base.StringTokenizer.create(userLogin, " ")
        LET authorizationMethod = tokenizer.nextToken()
        LET userLogin = tokenizer.nextToken()

        # Parse for id and password
        LET userLogin = security.Base64.ToString(userLogin)
        LET tokenizer = base.StringTokenizer.create(userLogin,":")
        LET userId = tokenizer.nextToken()
        LET password = tokenizer.nextToken()
        
        # Set the query filter values
        CALL credential.initQuery()
        IF ( userId ) IS NULL 
        OR ( password ) IS NULL THEN
            LET wrappedResponse.code    = HTTP_NOTAUTH
            LET wrappedResponse.status  = "ERROR"
            LET wrappedResponse.message = HTTPSTATUSDESC[HTTP_NOTAUTH] --unkown/bad parameters"
            LET wrappedResponse.data    = SFMT("Missing valid credentials: %1)", userLogin)
            LET queryException = TRUE
        ELSE 
            CALL credential.addQueryFilter("id", userId)
        END IF 

        IF NOT queryException 
        AND credential.isValid(password) THEN
            # create a session token
            LET wrappedResponse.message = "Credentials validation"
            LET wrappedResponse.code = "200"
            LET wrappedResponse.status = "SUCCESS"
            LET wrappedResponse.data = credential.getJSONEncoding()
        ELSE
            # process !isValid
            LET wrappedResponse.status  = "ERROR"
            LET wrappedResponse.code    = HTTP_NOTAUTH
            LET wrappedResponse.message = HTTPSTATUSDESC[HTTP_NOTAUTH]
            LET wrappedResponse.data    = "User credentials are not valid."
        END IF 

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("Query status: %1, %2", SQLCA.SQLCODE, SQLCA.sqlerrm)
        LET wrappedResponse.code    = HTTP_NOTAUTH
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = HTTPSTATUSDESC[HTTP_NOTAUTH]
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("credentialFactory:%1",__LINE__),"processAuthorization",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("credentialFactory:%1",__LINE__),"processAuthorization",
                        wrappedResponse.data = "User credentials are not valid.")

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION
################################################################################
#+
#+ Method: removeAuthorization
#+
#+ Description: Performs tasks to validate a user login
#+
#+ @code
#+ CALL removeAuthorization(req com.HTTPServiceRequest) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ userLogin STRING
#+
#+ @return
#+ status : HTTP status code
#+ wrappedResponse : JSON encoded string   
#+
#+ TODO: Add logic to remove cookie(s)
#+
PUBLIC FUNCTION removeAuthorization(req com.HTTPServiceRequest) RETURNS (INTEGER, STRING)
    DEFINE  path    STRING
    DEFINE statusCode INTEGER

    CASE req.getMethod()
    WHEN "DELETE"
        LET statusCode = HTTP_OK
        LET wrappedResponse.code = HTTP_OK
        LET wrappedResponse.message = "DELETE is good to go"
        LET wrappedResponse.status = "SUCCESS"
        LET wrappedResponse.data = "[{}]"
#    OTHERWISE
#        CALL req.sendTextResponse(400,NULL, "Unsupported operation")
    END CASE
    
    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION
################################################################################
#+
#+ Method: CheckAuthzCookie(request)
#+
#+ Description: deletes the cookie token from storage
#+
#+ Return: status          : HTTP status code
#+         wrappedResponse : JSON encoded string   
#+
#
# Check whether current request has a valie cookie
#  in fjs_forum_authz database
#
# TODO: Remove this if not needed
{
PUBLIC FUNCTION checkAuthzCookie(req)
  DEFINE  req     com.HttpServiceRequest
  DEFINE  cookie  STRING
  DEFINE  ok      BOOLEAN
  LET ok = FALSE
  LET cookie = req.findRequestCookie("GeneroAuthZ")
  IF cookie IS NOT NULL THEN
    # Check in authz for that value
    #LET ok = DBase.CheckAuthzToken(cookie)
  END IF
  RETURN ok
END FUNCTION
}
{
PRIVATE
FUNCTION PostAuthzRequest(req,path)
  DEFINE  req     com.HTTPServiceRequest
  DEFINE  path    STRING
  DEFINE  ops     Helper.OperationsType
  DEFINE  txt     STRING
  DEFINE  login   DBase.LoginType
  DEFINE  token   STRING
  DEFINE  now     DATETIME YEAR TO SECOND
  DEFINE  cookies WSHelper.WSServerCookiesType
  DEFINE  ret     DBase.UserType
  CALL Helper.SplitOperations(path,C_SERVICE_AUTHZ) RETURNING ops
  CASE ops.getLength()
    WHEN 1
      IF ops[1]!="/" THEN
        CALL req.sendResponse(401,NULL)
      ELSE
        LET txt = req.readTextRequest()
        CALL util.JSON.parse(txt, login)
        CALL DBase.CheckUser(login.*) RETURNING ret.*
        IF ret.login IS NULL THEN
          CALL req.sendResponse(401, NULL)
        ELSE
          LET now = CURRENT
          LET cookies[1].expires = now +  C_COOKIE_DURATION
          LET token = CreateAuthzToken(cookies[1].expires)
          LET cookies[1].NAME = C_COOKIE_NAME
          LET cookies[1].VALUE = token
          LET cookies[1].path = "/" # To apply cookie to all service
          LET cookies[1].httpOnly = TRUE
          CALL req.setResponseCookies(cookies)
          CALL req.setResponseHeader("Content-Type","application/json")
          CALL req.setResponseHeader("Cache","no-cache")
          CALL req.sendTextResponse(200, NULL, util.JSON.stringify(ret))
        END IF
      END IF
      
    OTHERWISE
      CALL req.sendTextResponse(400,NULL, "PUT: Unsupported operation")
    
  END CASE  
  
END FUNCTION
}


{PRIVATE
FUNCTION DeleteAuthzRequest(req,path)
  DEFINE  req     com.HTTPServiceRequest
  DEFINE  path    STRING
  DEFINE  ops     Helper.OperationsType
  DEFINE  cookie  STRING
  DEFINE  cookies WSHelper.WSServerCookiesType
  
  CALL Helper.SplitOperations(path,C_SERVICE_AUTHZ) RETURNING ops
  CASE ops.getLength()
  
    WHEN 1
      IF ops[1]!="/" THEN
        CALL req.sendResponse(400,NULL)
      ELSE
        LET cookie = req.findRequestCookie(C_COOKIE_NAME)
        IF DBase.DeleteAuthzToken(cookie) THEN
          # Change cookie to expire in the past in order to get removed by user-agent
          LET cookies[1].expires = CURRENT -  C_COOKIE_DURATION
          LET cookies[1].NAME = C_COOKIE_NAME
          LET cookies[1].VALUE = "invalid"
          LET cookies[1].path = "/" # To apply cookie to all services
          LET cookies[1].httpOnly = TRUE
          CALL req.setResponseCookies(cookies)
          CALL req.sendResponse(200, NULL)
        ELSE
          CALL req.sendTextResponse(401, NULL, "Forbidden")
        END IF
      END IF
      
    OTHERWISE
      CALL req.sendResponse(400, NULL)

    END CASE
END FUNCTION}


---- END CREDENDTIALS



{
################################################################################
#+
#+ Method: processQuery(request com.httpServiceRequest)
#+
#+ Description: Performs tasks to retrieve information, 1 or 1,000,000
#+
#+ Return: status          : HTTP status code
#+         wrappedResponse : JSON encoded string   
#+
FUNCTION processQuery(queryFilter STRING) RETURNS (INTEGER, STRING)
    DEFINE thisJSONArr  util.JSONArray
    DEFINE i, queryException INTEGER

    DEFINE query DYNAMIC ARRAY OF RECORD
          name STRING,
          value  STRING
    END RECORD

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE
    TRY
        LET thisJSONArr = util.JSONArray.parse(queryFilter)

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("itemFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", queryFilter))
                         
        CALL thisJSONArr.toFGL(query)

        # Set the query filter values
        CALL orderItem.initQuery()
        FOR i = 1 TO query.getLength()
            # If the filter key(field) is valid, add to the key/value to the query filter
            IF orderItem.isValidQuery(query[i].name) THEN
                CALL orderItem.addQueryFilter(query[i].name, query[i].value)
            ELSE 
                # Handle unkown/bad parameters
                LET wrappedResponse.code    = 400
                LET wrappedResponse.status  = "ERROR"
                LET wrappedResponse.message = "unkown/bad parameters"
                LET wrappedResponse.data    = queryFilter
                LET queryException = TRUE
            END IF 
        END FOR

        IF NOT queryException THEN
            # Execute resource query
            CALL orderItem.getRecords()

            # Set response data
            LET wrappedResponse.data = orderItem.getJSONEncoding()
            LET wrappedResponse.code = 200
            LET wrappedResponse.status = "SUCCESS"
        END IF

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("%1: %2", STATUS, err_get(STATUS))
        LET wrappedResponse.code    = 500
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = "resource query failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("itemFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION
}