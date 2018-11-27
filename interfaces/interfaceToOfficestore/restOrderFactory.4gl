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
IMPORT util

# HTTP Utility
IMPORT FGL http

# Logging utility
IMPORT FGL logger

# Interface Request
IMPORT FGL interfaceRequest

# Resource domain
IMPORT FGL order

################################################################################
#+
#+ Method: processQuery
#+
#+ Description: Performs tasks to retrieve information, 1 or 1,000,000
#+
#+ @code
#+ CALL processQuery(queryFilter STRING) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ queryFilter STRING
#+
#+ @return
#+ status : HTTP status code
#+ wrappedResponse : JSON encoded string   
#+
FUNCTION processQuery(requestPayload STRING) RETURNS (INTEGER, STRING)
    DEFINE thisJSONArr  util.JSONArray
    DEFINE i, queryException INTEGER

    DEFINE query DYNAMIC ARRAY OF RECORD
          keyName STRING,
          keyValue  STRING
    END RECORD

    DEFINE responsePayload responseType

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE
    TRY
        LET thisJSONArr = util.JSONArray.parse(requestPayload)

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("orderFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", requestPayload))
                         
        CALL thisJSONArr.toFGL(query)

        # Set the query filter values
        CALL order.initQuery()
        FOR i = 1 TO query.getLength()
            # If the filter key(field) is valid, add to the key/value to the query filter
            IF order.isValidQuery(query[i].keyName) THEN
                CALL order.addQueryFilter(query[i].keyName, query[i].keyValue)
            ELSE 
                # Handle unkown/bad parameters
                CALL interfaceRequest.setResponse(HTTP_BADREQUEST, "ERROR", "unkown/bad parameters", requestPayload)
                LET queryException = TRUE
            END IF  
        END FOR

        # If no exceptions in the query request, retrieve the resource
        IF NOT queryException THEN
            # Execute resource query
            CALL order.getRecords()

            # Set response data
            CALL interfaceRequest.setResponse(HTTP_OK, "SUCCESS", "", order.getJSONEncoding())
        END IF 

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        CALL interfaceRequest.setResponse(HTTP_INTERNALERROR, "ERROR", HTTPSTATUSDESC[HTTP_INTERNALERROR], SFMT("Query status: %1", STATUS))
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("orderFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY
        
    # Return wrapped response AND code(for better upstream performance)
    CALL interfaceRequest.getResponse() RETURNING responsePayload.*
    RETURN responsePayload.code, util.JSON.stringify(responsePayload)

END FUNCTION
