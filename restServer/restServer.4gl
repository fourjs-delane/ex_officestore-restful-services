################################################################################
#
# FOURJS_START_COPYRIGHT(U,2015)
# Property of Four Js*
# (c) Copyright Four Js 2015, 2019. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples
# are accurate and suitable for your purposes. Their inclusion is purely for
# information purposes only.
# FOURJS_END_COPYRIGHT
#
################################################################################
IMPORT com
IMPORT util

# Application utilities
IMPORT FGL appUtility

# Application logging 
IMPORT FGL logger

# HTTP utilities
IMPORT FGL http

# Incoming request object
IMPORT FGL interfaceRequest
IMPORT FGL factoryRestInterface

# Additional app logging variable
DEFINE applicationError STRING

################################################################################
#+
#+ Application: Application MAIN
#+
#+ Description: RESTful services server to hand incoming requests.
#+
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
        CALL initializeConfigurator()

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

        #CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),"The server is processing request...")
        CALL interfaceRequest.setRestRequestInfo(incomingRequest)
        CALL factoryRestInterface.processRestRequest()

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