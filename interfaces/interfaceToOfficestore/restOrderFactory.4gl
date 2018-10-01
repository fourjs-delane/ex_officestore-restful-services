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

# Logging utility
IMPORT FGL logger

# Resource domain
IMPORT FGL order

DEFINE wrappedResponse RECORD
    code    INTEGER, # HTTP response code
    status  STRING,  # success, fail, or error
    message STRING,  # used for fail or error message
    data    STRING   # response body or error/fail cause or exception name
END RECORD 
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

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("orderFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", queryFilter))
                         
        CALL thisJSONArr.toFGL(query)

        # Set the query filter values
        CALL order.initQuery()
        FOR i = 1 TO query.getLength()
            # If the filter key(field) is valid, add to the key/value to the query filter
            IF order.isValidQuery(query[i].name) THEN
                CALL order.addQueryFilter(query[i].name, query[i].value)
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
            CALL order.getRecords()

            # Set response data
            LET wrappedResponse.data = order.getJSONEncoding()
            LET wrappedResponse.code = 200
            LET wrappedResponse.status = "SUCCESS"
        END IF 

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("%1: %2", STATUS, err_get(STATUS))
        LET wrappedResponse.code    = 500
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = "resource query failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("orderFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY
        
    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION
