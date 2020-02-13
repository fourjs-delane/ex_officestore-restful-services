IMPORT util

# Logging utility
IMPORT FGL logger

# Http stuff
IMPORT FGL http

#REST interface request
IMPORT FGL interfaceRequest

# Resource factories
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

# Response definition
DEFINE wrappedResponse RECORD
    code    INTEGER, # HTTP response code
    status  STRING,  # success, fail, or error
    message STRING,  # used for fail or error message
    data    STRING   # response body or error/fail cause or exception name
END RECORD 

# Configurator definition
PUBLIC TYPE configuratorType FUNCTION()
PRIVATE DEFINE configurator DICTIONARY OF configuratorType

# Method process definition
PUBLIC TYPE restProcessType FUNCTION(requestPayload STRING) RETURNS (INTEGER, STRING)
PRIVATE DEFINE restProcess DICTIONARY OF restProcessType

################################################################################
#+
#+ Method: initializeConfigurator()
#+
#+ Description: Load the factory configuration functions to can then be called
#+              by reference
#+
#+ @code
#+ CALL initializeConfigurator()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION initializeConfigurator()
    -- Dictionary of rest resource factories
    CALL configurator.CLEAR()
    LET configurator["accounts"]      = FUNCTION configureAccountFactory
    LET configurator["orders"]        = FUNCTION configureOrderFactory
    LET configurator["orderitems"]    = FUNCTION configureOrderItemsFactory
    LET configurator["items"]         = FUNCTION configureItemsFactory
END FUNCTION

################################################################################
#+
#+ Method: configureAccountFactory()
#+
#+ Description: Load the factory resource process methods
#+
#+ @code
#+ CALL configureAccountFactory()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION configureAccountFactory()
    -- Dictionary of process functions
    CALL restProcess.CLEAR()
    LET restProcess["GET"]      = FUNCTION restAccountFactory.processQuery
    LET restProcess["PUT"]      = FUNCTION restAccountFactory.processUpdate
    LET restProcess["POST"]     = FUNCTION restAccountFactory.processInsert
    LET restProcess["DELETE"]   = FUNCTION restAccountFactory.processDelete
END FUNCTION

################################################################################
#+
#+ Method: configureOrderFactory()
#+
#+ Description: Load the factory resource process methods
#+
#+ @code
#+ CALL configureOrderFactory()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION configureOrderFactory()
    -- Dictionary of process functions
    CALL restProcess.CLEAR()
    LET restProcess["GET"]      = FUNCTION restOrderFactory.processQuery
END FUNCTION 

################################################################################
#+
#+ Method: configureOrderItemsFactory()
#+
#+ Description: Load the factory resource process methods
#+
#+ @code
#+ CALL configureOrderItemsFactory()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION configureOrderItemsFactory()
    -- Dictionary of process functions
    CALL restProcess.CLEAR()
    LET restProcess["GET"]      = FUNCTION restOrderItemFactory.processQuery
END FUNCTION 

################################################################################
#+
#+ Method: configureItemsFactory()
#+
#+ Description: Load the factory resource process methods
#+
#+ @code
#+ CALL configureItemsFactory()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION configureItemsFactory()
    -- Dictionary of process functions
    CALL restProcess.CLEAR()
    LET restProcess["GET"]      = FUNCTION restItemFactory.processQuery
END FUNCTION

################################################################################
#+
#+ Method: process()
#+
#+ Description: Process the requested resource
#+
#+ @code
#+ CALL process(restResource STRING)
#+
#+ @parameter
#+ restResource STRING
#+
#+ @return
#+ NONE
#+
FUNCTION process(restResource STRING)
    DEFINE statusCode INTEGER
    DEFINE requestMethod, factoryResponse, applicationError STRING 

    # Check configurator if resource is valid
    IF (isValidResource(restResource)) THEN
        # Run the factory configurator
        CALL configurator[restResource]()

        # Check if request method is valid for the resource
        LET requestMethod = interfaceRequest.getRequestMethod()
        IF (isValidMethod(requestMethod)) THEN
            CALL restProcess[requestMethod]("[]") RETURNING statusCode, factoryResponse
            DISPLAY "r1="||statusCode||" r2="||factoryResponse

        ELSE
            # Method wasn't found in resource configuration
            LET applicationError = SFMT("Method(%1) not allowed on resource: ", getRequestMethod(), getRestResource())
            LET statusCode = HTTP_NOTALLOWED
            LET wrappedResponse.code = HTTP_NOTALLOWED
            LET wrappedResponse.message = applicationError
            LET wrappedResponse.status = "ERROR"
            LET wrappedResponse.data = "[{}]"
            LET factoryResponse = util.JSON.stringify(wrappedResponse)        
            CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),applicationError)
        END IF 

    ELSE
        # Resource wasn't found in the configurator
        LET statusCode = HTTP_NOTFOUND
        LET wrappedResponse.code = HTTP_NOTFOUND
        LET wrappedResponse.message = SFMT("Unknown resource requested/Operation not allowed: %1", restResource)
        LET wrappedResponse.status = "ERROR"
        LET wrappedResponse.data = "[{}]"
        LET factoryResponse = util.JSON.stringify(wrappedResponse)
    END IF 

    RETURN statusCode, factoryResponse    
END FUNCTION

################################################################################
#+
#+ Method: isValidResource()
#+
#+ Description: Determines if request resource is valid
#+
#+ @code
#+ CALL isValidResource(requestResource STRING)
#+
#+ @parameter
#+ requestResource STRING
#+
#+ @return
#+ TRUE/FALSE
#+
FUNCTION isValidResource(requestResource STRING) RETURNS (BOOLEAN)
    RETURN configurator.contains(requestResource)
END FUNCTION

################################################################################
#+
#+ Method: isValidMethod()
#+
#+ Description: Determines if request method is valid for the resource
#+
#+ @code
#+ CALL isValidMethod(requestMethod STRING)
#+
#+ @parameter
#+ requestMethod STRING
#+
#+ @return
#+ TRUE/FALSE
#+
FUNCTION isValidMethod(requestMethod STRING) RETURNS (BOOLEAN)
    RETURN restProcess.contains(requestMethod)
END FUNCTION
