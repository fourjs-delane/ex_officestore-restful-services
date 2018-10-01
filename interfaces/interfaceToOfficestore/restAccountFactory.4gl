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

# Resource domain
IMPORT FGL account

SCHEMA officestore 

DEFINE wrappedResponse RECORD
    code    INTEGER, # HTTP response code
    status  STRING,  # success, fail, or error
    message STRING,  # used for fail or error message
    data    STRING   # response body or error/fail cause or exception name
END RECORD
################################################################################
#+
#+ Method: processQuery(request com.httpServiceRequest)
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
    DEFINE theseRecords DYNAMIC ARRAY OF RECORD LIKE account.*
        
    DEFINE query DYNAMIC ARRAY OF RECORD
          name STRING,
          value  STRING
    END RECORD

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        LET thisJSONArr = util.JSONArray.parse(queryFilter)

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", queryFilter))
                         
        CALL thisJSONArr.toFGL(query)

        # Set the query filter values
        CALL account.initQuery()
        FOR i = 1 TO query.getLength()
            # If the filter key(field) is valid, add to the key/value to the query filter
            IF account.isValidQuery(query[i].name) THEN
                CALL account.addQueryFilter(query[i].name, query[i].value)
            ELSE 
                # Handle unkown/bad parameters
                LET wrappedResponse.code    = HTTP_BADREQUEST
                LET wrappedResponse.status  = "ERROR"
                LET wrappedResponse.message = HTTPSTATUSDESC[HTTP_BADREQUEST] --unkown/bad parameters"
                LET wrappedResponse.data    = queryFilter
                LET queryException = TRUE
            END IF 
        END FOR

        # If no exceptions in the query request, retrieve the resource
        IF NOT queryException THEN
            # Execute resource query
            CALL account.getRecords()

            # Set response data
            LET theseRecords = account.getRecordsList()
            LET wrappedResponse.data = account.getJSONEncoding()
            LET wrappedResponse.code = HTTP_OK
            LET wrappedResponse.status = "SUCCESS"
        END IF

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("Query status: %1", STATUS)
        LET wrappedResponse.code    = HTTP_INTERNALERROR
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = HTTPSTATUSDESC[HTTP_INTERNALERROR]
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION

################################################################################
#+
#+ Method: processUpdate(updatePayload STRING)
#+
#+ Description: Performs tasks to update resource information, 1 or 1,000,000
#+
#+ @code
#+ CALL processUpdate(queryFilter STRING) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ queryFilter STRING
#+
#+ @return
#+ status : HTTP status code
#+ wrappedResponse : JSON encoded string   
#+
FUNCTION processUpdate(updatePayload STRING) RETURNS (INTEGER, STRING)

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processUpdate",
            SFMT("Update payload: %1", updatePayload))
                         
        # Process the update payload
        CALL account.init()
        CALL account.initQuery()
        
        LET wrappedResponse.code = account.processRecordsUpdate(updatePayload)
        LET wrappedResponse.data = account.getJSONEncoding()
        LET wrappedResponse.status = "SUCCESS"

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("Update status: %1", STATUS)
        LET wrappedResponse.code    = HTTP_INTERNALERROR
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = "resource update failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processUpdate",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
        
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION

################################################################################
#+
#+ Method: processInsert(insertPayload STRING)
#+
#+ Description: Performs tasks to insert resource information, 1 or 1,000,000
#+
#+ @code
#+ CALL processInsert(queryFilter STRING) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ queryFilter STRING
#+
#+ @return
#+ status : HTTP status code
#+ wrappedResponse : JSON encoded string   
#+
FUNCTION processInsert(insertPayload STRING) RETURNS (INTEGER, STRING)

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processInsert",
            SFMT("Insert payload: %1", insertPayload))
                         
        # Process the update payload
        CALL account.init()
        CALL account.initQuery()
        
        LET wrappedResponse.code = account.processRecordsInsert(insertPayload)
        LET wrappedResponse.data = account.getJSONEncoding()
        LET wrappedResponse.status = "SUCCESS"

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("Insert status: %1", STATUS)
        LET wrappedResponse.code    = HTTP_INTERNALERROR
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = "resource insert failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processInsert",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
        
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION

################################################################################
#+
#+ Method: processDelete(request com.httpServiceRequest)
#+
#+ Description: Performs tasks to update resource information, 1 or 1,000,000
#+
#+ @code
#+ CALL processDelete(queryFilter STRING) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ queryFilter STRING
#+
#+ @return
#+ status : HTTP status code
#+ wrappedResponse : JSON encoded string   
#+
FUNCTION processDelete(deleteFilter STRING) RETURNS (INTEGER, STRING)
    DEFINE thisJSONArr  util.JSONArray
    DEFINE i, queryException INTEGER
    DEFINE deleteCount INTEGER
        
    DEFINE query DYNAMIC ARRAY OF RECORD
          name STRING,
          value  STRING
    END RECORD

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processDelete",
            SFMT("Delete filter: %1", deleteFilter))
                         
        LET thisJSONArr = util.JSONArray.parse(deleteFilter)

        CALL thisJSONArr.toFGL(query)

        # Set the delete filter values
        CALL account.initQuery()
        FOR i = 1 TO query.getLength()
            CASE query[i].NAME
            WHEN "user"
                CALL account.setQueryID(query[i].value)
            OTHERWISE
                # Handle unkown/bad parameters
                LET wrappedResponse.code    = HTTP_BADREQUEST
                LET wrappedResponse.status  = "ERROR"
                LET wrappedResponse.message = "unkown/bad parameters"
                LET wrappedResponse.data    = deleteFilter
                LET queryException = TRUE
            END CASE 
        END FOR

        IF NOT queryException THEN
            # Execute resource query
            LET deleteCount = account.deleteRecords()

            # Set response data
            #LET theseRecords = account.getRecordsList()
            #LET wrappedResponse.data = account.getJSONEncoding()
            LET wrappedResponse.message = SFMT("%1 records deleted.", deleteCount)
            LET wrappedResponse.code = HTTP_OK
            LET wrappedResponse.status = "SUCCESS"
        END IF

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("Query status: %1", STATUS)
        LET wrappedResponse.code    = HTTP_INTERNALERROR
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = "resource delete failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processDelete",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, util.JSON.stringify(wrappedResponse)

END FUNCTION
