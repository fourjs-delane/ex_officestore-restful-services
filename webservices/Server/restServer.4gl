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
# TODO: Service versioning?  Do this VERY sparingly
# TODO: Representational formatting...i.e. '.json' or '.xml' in URI?
# TODO: Cacheability?
# TODO: Handling cross-domain(CORS support)?
# TODO: Consider refactoring reposnes for on exit point
# BUG: GWS-999999
#
################################################################################
#+
#+ This module creates a web service server to process and handle ReST style
#+ HTTP requests and return a HTTP response
#+
#+
IMPORT com
IMPORT util

IMPORT FGL http

IMPORT FGL factoryRestInterface
IMPORT FGL logger
IMPORT FGL appUtility

# Freeform error message; not raised by the runtime
& define APP_LOGGING

# Additional app logging variable
DEFINE applicationError STRING

##############################################################################
#+
#+ REST Web Service Server:
#+ - Publication of the services
#+ - Handle the REST protocol
#+
#+ Principles of RESTful design:
#+   https://github.com/tfredrich/RestApiTutorial.com/raw/master/media/RESTful%20Best%20Practices-v1_2.pdf

MAIN
    # Services listener timeout interval(RESTTIMEOUT: -1 is infinite)
    DEFINE listenerTimeout INTEGER
    DEFINE listenerStatus INTEGER

    DEFINE incomingRequest com.HTTPServiceRequest

    WHENEVER ANY ERROR CALL errorHandler
    DEFER INTERRUPT

    TRY
        # Initialize application 
        CALL appUtility.initialize()

        # Set response maximumn length.  This could be parameterized: default -1(unlimited)
        CALL com.WebServiceEngine.SetOption("maximumresponselength",-1)

        # Initialize connection layer.  This could be parameterized in the service config file
        CALL com.WebServiceEngine.SetOption("readwritetimeout",60)
        CALL com.WebServiceEngine.SetOption("connectiontimeout",25)  

        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"Starting server")
        CALL com.WebServiceEngine.Start()
        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"Started")

    CATCH
        # Startup failed for some reason
        LET applicationError = "<MAIN>RESTServer startup failure"
        CALL errorHandler()
        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"Start failed.")
        CALL programExit(1)
    END TRY
    
    # Listen for REST requests and process them
    WHILE TRUE
        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"The server is listening...")

        # Set listener timeout: default -1(infinite)
        LET listenerTimeout = IIF(fgl_getenv("WSTIMEOUT") IS NOT NULL, fgl_getenv("WSTIMEOUT"), -1)
        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),SFMT("Server timeout: %1",listenerTimeout))

        # Process incoming requests 
        LET incomingRequest = com.WebServiceEngine.handleRequest(listenerTimeout, listenerStatus)

        # Check for timeout or socket error
        CALL checkListenerStatus(listenerStatus)

        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"The server is processing request...")

        # Determine the method(verb) and send request to the factory
        CASE incomingRequest.getMethod()
        # The general convention is that GET is a query and performs no update.         
        WHEN "GET"
            CALL factoryRestInterface.marshalRestGet(incomingRequest)

        # POST generally is reserved for create operation
        WHEN "POST"
            CALL factoryRestInterface.marshalRestPost(incomingRequest)
            
        # PUT generally is reserved for update operations
        WHEN "PUT"
            CALL factoryRestInterface.marshalRestPut(incomingRequest)

        # DELETE generally is reserved for delete operations
        WHEN "DELETE"
            CALL factoryRestInterface.marshalRestDelete(incomingRequest)

        OTHERWISE
            LET applicationError = SFMT("<MAIN>Method not allowed: [%1]", incomingRequest.getMethod())
            CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),applicationError)
            CALL incomingRequest.setResponseHeader("Content-Type","application/json")
            CALL incomingRequest.setResponseHeader("Cache","no-cache")
            #LET errorMessage.description = applicationError
            CALL incomingRequest.sendTextResponse(HTTP_NOTALLOWED,incomingRequest.getMethod(),util.JSON.stringify(applicationError))
        END CASE

      IF int_flag<>0 THEN
        LET int_flag=0
        EXIT WHILE
      END IF 
    END WHILE

    CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"The server was stopped, normally.")
    CALL programExit(0)
    
END MAIN
################################################################################
#+
#+ Method: errorHandler()
#+
#+ Description: Standard error function to handle error display
#+
FUNCTION errorHandler()
    DEFINE errorMessage  STRING

    LET errorMessage = "\nSTATUS                : ", STATUS using "<<<<&",
                       "\nSQLERRMESSAGE         : ", SQLERRMESSAGE,
                       "\nSQLSTATE              : ", SQLSTATE USING "<<<<&",
                       "\nSQLERRM               : ", SQLCA.SQLERRM,
                       "\nSQLCODE               : ", SQLCA.SQLCODE USING "<<<<&",
                       "\nSQLERRM               : ", SQLCA.SQLCODE USING "<<<<&",
                       "\nSQLERRD[2]            : ", SQLCA.SQLERRD[2] USING "<<<<&",
                       "\nSQLERRD[3]            : ", SQLCA.SQLERRD[3] USING "<<<<&",
                       "\nOFFSET TO ERROR IN SQL: ", SQLCA.SQLERRD[5] USING "<<<<&",
                       "\nROWID FOR LAST INSERT : ", SQLCA.SQLERRD[6] USING "<<<<&"

    #Optional app debug logging
    &ifdef APP_LOGGING
        LET errorMessage = errorMessage || "\nAPPERROR              : ", applicationError
    &endif
                       
    CALL logger.logEvent(logger._LOGERROR,ARG_VAL(0),SFMT("Line: %1",__LINE__), errorMessage)
    CALL programExit(1)
END FUNCTION

################################################################################
#+
#+ Method: checkListenerStatus()
#+
#+ Description: Evaluate and handle the Wev services listener status
#+
FUNCTION checkListenerStatus(listenerStatus INTEGER)
    IF listenerStatus != 1 THEN
        # Application server timeout
        IF listenerStatus == -15575 THEN
            CALL logger.logEvent(logger._LOGERROR,ARG_VAL(0),SFMT("Line: %1",__LINE__), "REST service listener disconnected by application server.")
            CALL programExit(1) 
        ELSE
            #com.WebServiceEngine error code
            IF listenerStatus IS NULL THEN             
                CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__), "REST Listener status is NULL")
            ELSE
                CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__), SFMT("REST Listener returned a non-zero status. %1 %2", listenerStatus, SQLCA.SQLERRM))
                CALL programExit(0) 
            END IF
        END IF
    END IF 
    RETURN
END FUNCTION