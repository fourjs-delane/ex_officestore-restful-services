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
IMPORT FGL product

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
FUNCTION processQuery(queryFilter STRING) RETURNS (INTEGER, STRING)

    DEFINE thisJSONArr  util.JSONArray
    DEFINE imagePath    STRING

    DEFINE query DYNAMIC ARRAY OF RECORD
          name STRING,
          value  STRING
    END RECORD
    # Let the referencing entity handle errors
    WHENEVER ANY ERROR RAISE

    TRY
        LET thisJSONArr = util.JSONArray.parse(queryFilter)

        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("productImageFactory:%1",__LINE__),"processQuery",
            SFMT("Query filter: %1", queryFilter))
                         
        CALL thisJSONArr.toFGL(query)
        
        LET imagePath = getProductImagePath(query[1].value)
        LET wrappedResponse.code = 200
        
    CATCH
        # Return some kind of error: must use STATUS before it is reset by next code statment
        LET wrappedResponse.data    = SFMT("%1: %2", STATUS, err_get(STATUS))
        LET wrappedResponse.code    = 500
        LET wrappedResponse.status  = "ERROR"
        LET wrappedResponse.message = "resource query failed"
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("productImageFactory:%1",__LINE__),"processQuery",
            SFMT("SQLSTATE: %1 SQLERRMESSAGE: %2", SQLSTATE, SQLERRMESSAGE))
    END TRY 

    # Return wrapped response AND code(for better upstream performance)
    RETURN wrappedResponse.code, imagePath
    
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
