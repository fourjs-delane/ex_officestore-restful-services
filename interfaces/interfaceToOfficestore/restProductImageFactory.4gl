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
IMPORT FGL product

################################################################################
#+
#+ Method: processQuery
#+
#+ Description: Performs tasks to retrieve product image
#+
#+ @code 
#+ CALL processQuery(queryFilter STRING) RETURNS (INTEGER, STRING)
#+
#+ @parameter
#+ queryFilter STRING
#+
#+ @return
#+ status : HTTP status code
#+ imagePath : image location   
#+
FUNCTION processQuery(requestPayload STRING) RETURNS (INTEGER, STRING)
    DEFINE thisJSONArr  util.JSONArray
    DEFINE imagePath    STRING

    DEFINE query DYNAMIC ARRAY OF RECORD
          keyName STRING,
          keyValue  STRING
    END RECORD

    DEFINE responsePayload responseType

    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE
    TRY
        LET thisJSONArr = util.JSONArray.parse(requestPayload)

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("productImageFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", requestPayload))
                         
        CALL thisJSONArr.toFGL(query)
        
        # Set response data
        CALL interfaceRequest.setResponse(HTTP_OK, "SUCCESS", "", getProductImagePath(query[1].keyValue))
    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        CALL interfaceRequest.setResponse(HTTP_INTERNALERROR, "ERROR", HTTPSTATUSDESC[HTTP_INTERNALERROR], SFMT("Query status: %1", STATUS))

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("productImageFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY 

    # Return wrapped response AND code(for better upstream performance)
    CALL interfaceRequest.getResponse() RETURNING responsePayload.*
    RETURN responsePayload.code, responsePayload.data
    
END FUNCTION

################################################################################
#+
#+ Method: getProductImage
#+
#+ Description: Retrieves image path for REST request
#+
#+ @code 
#+ CALL getProductImagePath(queryFilter STRING) RETURNS STRING
#+
#+ @param 
#+ queryFilter STRING
#+
#+ @return 
#+ filePath STRING location of file(complete path)
#+
FUNCTION getProductImagePath(queryFilter STRING) RETURNS STRING
    CONSTANT defaultFile="unknown.jpg"
    DEFINE filePath STRING

    LET filePath = getImageFilenameFromProductId(queryFilter)
    
    CASE filePath.getLength()
    WHEN 1
        IF filePath =="/" THEN
            IF queryFilter IS NULL THEN LET filePath = defaultFile END IF 
            
        ELSE
            IF filePath IS NULL THEN LET filePath = defaultFile
            END IF
        END IF

    OTHERWISE
        #CALL req.sendTextResponse(400,NULL, "Invalid operation")
    END CASE
    RETURN filePath

END FUNCTION


################################################################################
#+
#+ Method: getImageFilenameFromProductId
#+
#+ Description: Retrieves image filename for the product id
#+
#+ @code 
#+ CALL getImageFilenameFromProductId(productID STRING) RETURNS STRING
#+
#+ @param 
#+ productId STRING
#+
#+ @return 
#+ pictureFile STRING 
#+
FUNCTION getImageFilenameFromProductId(p_id STRING) RETURNS STRING
  DEFINE pictureFile    STRING

  SELECT prodpic
    INTO pictureFile
    FROM product
   WHERE productid = p_id

    IF sqlca.sqlcode=0 THEN
        RETURN pictureFile
    ELSE
        RETURN NULL
    END IF  

END FUNCTION
