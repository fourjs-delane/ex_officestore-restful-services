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
IMPORT FGL account

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

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", requestPayload))
                         
        CALL thisJSONArr.toFGL(query)

        # Set the query filter values
        CALL account.initQuery()
        FOR i = 1 TO query.getLength()
            # If the filter key(field) is valid, add to the key/value to the query filter
            IF account.isValidQuery(query[i].keyName) THEN
                CALL account.addQueryFilter(query[i].keyName, query[i].keyValue)
            ELSE 
                # Handle unkown/bad parameters
                CALL interfaceRequest.setResponse(HTTP_BADREQUEST, "ERROR", "unkown/bad parameters", requestPayload)
                LET queryException = TRUE
            END IF 
        END FOR

        # If no exceptions in the query request, retrieve the resource
        IF NOT queryException THEN
            # Execute resource query
            CALL account.getRecords()

            # Set response data
            CALL interfaceRequest.setResponse(HTTP_OK, "SUCCESS", "", account.getJSONEncoding())
        END IF

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        CALL interfaceRequest.setResponse(HTTP_INTERNALERROR, "ERROR", HTTPSTATUSDESC[HTTP_INTERNALERROR], SFMT("Query status: %1", STATUS))

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    CALL interfaceRequest.getResponse() RETURNING responsePayload.*
    RETURN responsePayload.code, util.JSON.stringify(responsePayload)

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
FUNCTION processUpdate(requestPayload STRING) RETURNS (INTEGER, STRING)
    DEFINE tempString STRING
    DEFINE responsePayload responseType

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processUpdate",
            SFMT("Update payload: %1", requestPayload))
                         
        # Process the update payload
        CALL account.init()
        CALL account.initQuery()
        
        CALL interfaceRequest.setResponse(account.processRecordsUpdate(requestPayload), "SUCCESS", "", account.getJSONEncoding())
        #LET wrappedResponse.code = account.processRecordsUpdate(requestPayload)
        #LET wrappedResponse.data = account.getJSONEncoding()
        #LET wrappedResponse.status = "SUCCESS"

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET tempString    = SFMT("Update status: %1", STATUS)
        CALL interfaceRequest.setResponse(HTTP_INTERNALERROR, "ERROR", "resource update failed", tempString)
        #LET wrappedResponse.data    = SFMT("Update status: %1", STATUS)
        #LET wrappedResponse.code    = HTTP_INTERNALERROR
        #LET wrappedResponse.status  = "ERROR"
        #LET wrappedResponse.message = "resource update failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processUpdate",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
        
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    CALL interfaceRequest.getResponse() RETURNING responsePayload.*
    RETURN responsePayload.code, util.JSON.stringify(responsePayload.data)
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
FUNCTION processInsert(requestPayload STRING) RETURNS (INTEGER, STRING)
    DEFINE tempString STRING
    DEFINE responsePayload responseType

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processInsert",
            SFMT("Insert payload: %1", requestPayload))
                         
        # Process the update payload
        CALL account.init()
        CALL account.initQuery()
        
        CALL interfaceRequest.setResponse(account.processRecordsInsert(requestPayload), "SUCCESS", "", account.getJSONEncoding())
        #LET wrappedResponse.code = account.processRecordsInsert(requestPayload)
        #LET wrappedResponse.data = account.getJSONEncoding()
        #LET wrappedResponse.status = "SUCCESS"

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET tempString    = SFMT("Insert status: %1", STATUS)
        CALL interfaceRequest.setResponse(HTTP_INTERNALERROR, "ERROR", "resource insert failed", tempString)
        #LET wrappedResponse.data    = SFMT("Insert status: %1", STATUS)
        #LET wrappedResponse.code    = HTTP_INTERNALERROR
        #LET wrappedResponse.status  = "ERROR"
        #LET wrappedResponse.message = "resource insert failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processInsert",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
        
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    CALL interfaceRequest.getResponse() RETURNING responsePayload.*
    RETURN responsePayload.code, util.JSON.stringify(responsePayload.data)

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
FUNCTION processDelete(requestPayload STRING) RETURNS (INTEGER, STRING)
    DEFINE tempString STRING
    DEFINE responsePayload responseType

    DEFINE thisJSONArr  util.JSONArray
    DEFINE i, queryException INTEGER
    DEFINE deleteCount INTEGER
        
    DEFINE query DYNAMIC ARRAY OF RECORD
          keyName STRING,
          keyValue  STRING
    END RECORD

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE 
    TRY
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processDelete",
            SFMT("Delete filter: %1", requestPayload))
                         
        LET thisJSONArr = util.JSONArray.parse(requestPayload)

        CALL thisJSONArr.toFGL(query)

        # Set the delete filter values
        CALL account.initQuery()
        FOR i = 1 TO query.getLength()
            CASE query[i].keyName
            WHEN "user"
                CALL account.setQueryID(query[i].keyValue)
            OTHERWISE
                # Handle unkown/bad parameters
                CALL interfaceRequest.setResponse(HTTP_BADREQUEST, "ERROR", "unkown/bad parameters", requestPayload)
                #LET wrappedResponse.code    = HTTP_BADREQUEST
                #LET wrappedResponse.status  = "ERROR"
                #LET wrappedResponse.message = "unkown/bad parameters"
                #LET wrappedResponse.data    = requestPayload
                LET queryException = TRUE
            END CASE 
        END FOR

        IF NOT queryException THEN
            # Execute resource query
            LET deleteCount = account.deleteRecords()

            # Set response data
            CALL interfaceRequest.setResponse(HTTP_OK, "SUCCESS", SFMT("%1 records deleted.", deleteCount), account.getJSONEncoding())
            #LET theseRecords = account.getRecordsList()
            #LET wrappedResponse.data = account.getJSONEncoding()
            #LET wrappedResponse.message = SFMT("%1 records deleted.", deleteCount)
            #LET wrappedResponse.code = HTTP_OK
            #LET wrappedResponse.status = "SUCCESS"
        END IF

    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET tempString    = SFMT("Query status: %1", STATUS)
        CALL interfaceRequest.setResponse(HTTP_INTERNALERROR, "ERROR", "resource delete failed", tempString)
        #LET wrappedResponse.data    = SFMT("Query status: %1", STATUS)
        #LET wrappedResponse.code    = HTTP_INTERNALERROR
        #LET wrappedResponse.status  = "ERROR"
        #LET wrappedResponse.message = "resource delete failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("accountFactory:%1",__LINE__),"processDelete",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY

    # Return wrapped response AND code(for better upstream performance)
    CALL interfaceRequest.getResponse() RETURNING responsePayload.*
    RETURN responsePayload.code, util.JSON.stringify(responsePayload.data)

END FUNCTION
