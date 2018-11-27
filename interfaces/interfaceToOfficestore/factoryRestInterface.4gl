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
#+
#+ This module implements marshalling methods to interface for the officestore 
#+ domain with the use of domain resource factories.  The concept is that a 
#+ factory knows the resources required to create a product.  The factory
#+ invokes the resource methods to mine the raw materials(data) and create the
#+ product(response).
#+
#+ A configurator DICTIONARY is implemented to setup the factory configuration
#+ functions to be referenced by resource name.  The functions create a dictionary
#+ of processing functions allowed to be called by the resource method(GET, PUT,
#+ POST, etc)
#+
IMPORT util
IMPORT com
IMPORT os

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
    CALL configurator.clear()
    LET configurator["accounts"]        = FUNCTION configureAccountFactory
    LET configurator["items"]           = FUNCTION configureItemFactory
    LET configurator["orders"]          = FUNCTION configureOrderFactory
    LET configurator["orderitems"]      = FUNCTION configureOrderItemsFactory
    LET configurator["ping"]            = FUNCTION configurePingFactory
    LET configurator["products"]        = FUNCTION configureProductFactory
    LET configurator["productImages"]   = FUNCTION configureProductImageFactory
    LET configurator["suppliers"]       = FUNCTION configureSupplierFactory
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
    CALL restProcess.clear()
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
    CALL restProcess.clear()
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
    CALL restProcess.clear()
    LET restProcess["GET"]      = FUNCTION restOrderItemFactory.processQuery
END FUNCTION 

################################################################################
#+
#+ Method: configureItemFactory()
#+
#+ Description: Load the factory resource process methods
#+
#+ @code
#+ CALL configureItemFactory()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION configureItemFactory()
    -- Dictionary of process functions
    CALL restProcess.clear()
    LET restProcess["GET"]      = FUNCTION restItemFactory.processQuery
END FUNCTION

################################################################################
#+
#+ Method: configurePingFactory()
#+
#+ Description: Load the factory resource process methods
#+
#+ @code
#+ CALL configurePingFactory()
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ NONE
#+
FUNCTION configurePingFactory()
    -- Dictionary of process functions
    CALL restProcess.clear()
    LET restProcess["GET"]      = FUNCTION restCredentialFactory.processAuthorization
END FUNCTION

################################################################################
#+
#+ Method: configureProductFactory()
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
FUNCTION configureProductFactory()
    -- Dictionary of process functions
    CALL restProcess.clear()
    LET restProcess["GET"]      = FUNCTION restProductFactory.processQuery
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
FUNCTION configureProductImageFactory()
    -- Dictionary of process functions
    CALL restProcess.clear()
    LET restProcess["GET"]      = FUNCTION restProductImageFactory.processQuery
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
FUNCTION configureSupplierFactory()
    -- Dictionary of process functions
    CALL restProcess.clear()
    LET restProcess["GET"]      = FUNCTION restSupplierFactory.processQuery
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
FUNCTION processRestRequest()
    DEFINE statusCode INTEGER
    DEFINE restResource, requestMethod, requestPayload,
           sessionCookie, factoryResponse, applicationError STRING 
    DEFINE thisRequest com.HttpServiceRequest

    DEFINE responsePayload responseType

    # Get the request for response processing
    LET thisRequest = interfaceRequest.getRequestRequest()

    # Assume success(200) unless otherwise reset
    LET statusCode = HTTP_OK
    LET restResource = interfaceRequest.getRestResource()

    # Check authorization cookie and...resource is valid
    LET sessionCookie = thisRequest.findRequestCookie("GeneroAuthZ")
    IF (restCookieFactory.checkCookies(sessionCookie) OR (restResource = "ping")) 
    AND (isValidResource(restResource)) THEN

        # Run the factory configurator
        CALL configurator[restResource]()

        # Check if request method is valid for the resource
        LET requestMethod = interfaceRequest.getRequestMethod()
        IF (isValidMethod(requestMethod)) THEN

            # Get the request payload(data/query)
            LET requestPayload = util.JSON.stringify(getRequestItems())

            # The "ping" is a speacial case and the payload will be a header value
            IF (restResource = "ping") THEN 
                LET requestPayload = thisRequest.getRequestHeader("Officestore-Credential")
            END IF
            
            # Process the request
            CALL restProcess[requestMethod](requestPayload) RETURNING statusCode, factoryResponse

            # The "ping" is a speacial case and the response sets a cookie
            IF (restResource = "ping") AND (statusCode = HTTP_OK) THEN
                # Create a session cookie(s)
                CALL restCookieFactory.bakeCookies("GeneroAuthZ", "/", TRUE)
                # Set the cookie(s) in the resonse
                CALL thisRequest.setResponseCookies(restCookieFactory.getCookies())
            END IF

        ELSE
            # Method wasn't found in resource configuration
            LET applicationError = SFMT("Method(%1) not allowed on resource: %2 ", getRequestMethod(), getRestResource())
            CALL interfaceRequest.setResponse(HTTP_NOTALLOWED, "ERROR", applicationError, "[{}]")
            CALL interfaceRequest.getResponse() RETURNING responsePayload.*
            LET factoryResponse = util.JSON.stringify(responsePayload)        
            CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),applicationError)
        END IF 

    ELSE
        # Resource wasn't found in the configurator
        LET applicationError = SFMT("Unknown resource requested/Operation not allowed: %1", restResource)
        CALL interfaceRequest.setResponse(HTTP_NOTFOUND, "ERROR", applicationError, "[{}]")
        CALL interfaceRequest.getResponse() RETURNING responsePayload.*
        LET factoryResponse = util.JSON.stringify(responsePayload)
        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("Line: %1",__LINE__),applicationError)
    END IF 

    # TODO: checking and setting headers
    LET thisRequest = interfaceRequest.getRequestRequest()
    CALL thisRequest.setResponseHeader("Content-Type","application/json")
    CALL thisRequest.setResponseHeader("Cache","no-cache")

    # Send the request response
    # The productImages resource requires a "sendFileResponse"
    IF  restResource = "productImages" THEN
        IF statusCode = HTTP_OK THEN
        DISPLAY "this file: ", os.Path.join(fgl_GETENV("IMAGEPATH"),factoryResponse)
            CALL thisRequest.sendFileResponse(statusCode,NULL, os.Path.join(fgl_GETENV("IMAGEPATH"),factoryResponse) )
        ELSE
            CALL thisRequest.sendTextResponse(HTTP_NOTFOUND,NULL, "Not found")
        END IF 
    ELSE
        # Description is NULL for default value based on status code; 
        # otherwise a message can be supplied
        CALL thisRequest.sendTextResponse(statusCode, NULL, factoryResponse)
    END IF     RETURN
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
