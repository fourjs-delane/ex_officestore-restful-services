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
################################################################################
#+ This module implements tabname class information handling
#+
#+ This code uses the 'officestore' database tables.
#+ tabname input, query and list handling functions are defined here.
#+

IMPORT util
IMPORT com
IMPORT security

# Logging utility
IMPORT FGL logger
IMPORT FGL WSHelper

SCHEMA officestore

&include "credentialTypes.inc"

#
# Module variables
#
DEFINE mQuery RECORD
    id STRING, 
    fname STRING,
    lname STRING
END RECORD

DEFINE mSqlWhere STRING

TYPE cookiesType WSHelper.WSServerCookiesType
DEFINE mCookies cookiesType

PUBLIC DEFINE mRecords DYNAMIC ARRAY OF recordType 

PRIVATE CONSTANT C_COOKIE_DURATION = INTERVAL (1) DAY TO DAY

################################################################################
#+
#+ Method: addQueryFilter
#+
#+ Description: Add a valid query key and value to the standard query filter(WHERE 1=1)
#+
#+ @code 
#+  CALL account.addQueryFilter(columnKey, columnValue)
#+
#+ @param 
#+ columnKey   STRING : Column name key
#+ columnValue STRING : Column query value
#+
#+ @return 
#+ NONE
#+
PUBLIC FUNCTION addQueryFilter(columnKey STRING, columnValue STRING)
    CASE (columnKey)
        WHEN "id"
            LET mSqlWhere = SFMT("%1 %2 '%3'", mSqlWhere, " AND login LIKE ", columnValue)
    END CASE
END FUNCTION
################################################################################
#+
#+ Method: getQueryFilter
#+
#+ Description: Returns the query filter in the form of a WHERE clause  
#+
#+ @code 
#+ LET sqlStatement = SFMT("%1 %2", _SELECTSQL, getQueryFilter())
#+
#+ @param 
#+ NONE
#+
#+ @return 
#+ mSqlWhere STRING : SQL where clause for query
#+
PRIVATE FUNCTION getQueryFilter() RETURNS STRING
    RETURN mSqlWhere
END FUNCTION

################################################################################
#+
#+ Method: isValidQuery
#+
#+ Description: Returns BOOLEAN true/false
#+
#+ @code 
#+ IF account.isValidQuery(queryParameter)
#+
#+ @param 
#+ queryParameter STRING : Name of query parameter
#+
#+ @return 
#+ TRUE/FALSE
#+
PUBLIC FUNCTION isValidQuery( queryName STRING )

    CASE (queryName)
        WHEN "id"
            RETURN TRUE
        WHEN "password"
            RETURN TRUE
        OTHERWISE
            RETURN FALSE
    END CASE

END FUNCTION

---- DO ALL NEW WHERE BELOW HERE ----
################################################################################
#+
#+ Method: getJSONEncoding
#+
#+ Description: Check in User if given user exists, if password is valid
#+  and return its ID (or null in case of error)
#+
#+ @code
#+ CALL getJSONEncoding()
#+
#+ @param
#+ userPassword STRING
#+
#+ @return 
#+ BOOLEAN TRUE/FALSE
#+
################################################################################

FUNCTION isValid(userPassword STRING) RETURNS BOOLEAN
    DEFINE userIsValid BOOLEAN
    
    DEFINE hashPassword STRING
    DEFINE sqlstatement STRING
    DEFINE i INTEGER 

    # Add query filter to standard SQL
    LET sqlStatement = "SELECT password, first_name, last_name, image_id FROM credentials " || getQueryFilter()

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("credential:%1",__LINE__),"isValid",
        SFMT("SQL statement: %1", sqlStatement))

    CALL mRecords.clear()
    DECLARE curs CURSOR FROM sqlStatement --"SELECT password, first_name, last_name FROM credentials " || getQueryFilter()
    OPEN curs 

    LET i = 1
    FETCH curs INTO hashPassword, mRecords[1].firstname, mRecords[1].lastname, mRecords[1].image
    IF SQLCA.SQLCODE = 0 THEN
        LET userIsValid = security.BCrypt.CheckPassword(userPassword, hashPassword)
    END IF

    CLOSE curs
    FREE curs
    
    RETURN userIsValid
END FUNCTION

#+ 
#+ Module mutators
#+
FUNCTION initQuery()
    INITIALIZE mQuery.* TO NULL
    LET mSqlWhere = "WHERE 1=1"
END FUNCTION

################################################################################
#+
#+ Method: getJSONEncoding
#+
#+ Description: Returns a string representation of the sample storage array in JSON format
#+
#+ @code
#+ CALL getJSONEncoding()
#+
#+ @param 
#+ NONE
#+
#+ @return 
#+ util.JSON.stringify(mRecords recordType)
#+
PUBLIC FUNCTION getJSONEncoding() RETURNS STRING
    RETURN util.JSON.stringify(mRecords)
END FUNCTION

################################################################################
#+
#+ Method: init
#+
#+ Description: Clears the sample storage array of all records
#+
#+ @code
#+ CALL init()
#+
#+ @param 
#+ NONE
#+
#+ @return 
#+ NONE
#+
PUBLIC FUNCTION init()
    CALL mRecords.clear()
END FUNCTION

################################################################################
#+
#+ Method: getRecordsList
#+
#+ Description: Always return a list array(pointer).  The idea is that one or many it 
#+    doesn't matter, always return a list(array)
#+
#+ @code
#+ CALL getRecordsList()
#+
#+ @param 
#+ NONE
#+
#+ @return 
#+ mRecords recordType
#+
PUBLIC FUNCTION getRecordsList() RETURNS DYNAMIC ARRAY OF recordType
    RETURN mRecords
END FUNCTION

################################################################################
#+
#+ Method: createSessionToken()
#+
#+ Description: Creates a new session cookie(token) in storage
#+
#+ @code
#+ LET sessionToken = getSessionToken(tokenExpiration DATETIME YEAR TO SECOND)
#+
#+ @paramter
#+ tokenExpiration DATETIME YEAR TO SECOND
#+
#+ @return
#+ newToken STRING
#+
FUNCTION createSessionToken(tokenExpiration DATETIME YEAR TO SECOND)
    DEFINE newToken VARCHAR(255)

    LET newToken = security.randomGenerator.createUUIDString()

    INSERT INTO authtokens (token, expires)
    VALUES (newToken, tokenExpiration)

    IF SQLCA.sqlcode != 0 THEN
        LET newToken = NULL
    END IF

    RETURN newToken
    
END FUNCTION

################################################################################
#+
#+ Method: deleteSessionToken()
#+
#+ Description: Removes a new session cookie(token) in storage
#+
#+ @code
#+ CALL deleteSessionToken(thisToken VARCHAR(255))
#+
#+ @paramter
#+ thisToken STRING
#+
#+ @return
#+ Status : SQLCA.SQLCODE
#+
FUNCTION deleteSessionToken(thisToken VARCHAR(255))
    DELETE FROM authtokens WHERE token = thisToken
    RETURN sqlca.SQLCODE
END FUNCTION 
################################################################################
#+
#+ Method: processRecordsUpdate
#+
#+ Description: Processes a list of records to update the changes to the records for storage
#+    to the data source
#+
#+ @code
#+ LET status = processRecordsUpdate(thisData)
#+
#+ @param 
#+ thisData STRING : representation of an array of records
#+
#+ @return 
#+ stat INTEGER : appropriate HTTP status code
#+
{
PUBLIC FUNCTION processRecordsUpdate(thisData STRING) RETURNS INTEGER
    DEFINE thisJSONArr  util.JSONArray
    DEFINE thisJSONObj  util.JSONObject
    DEFINE rowsUpdated  INTEGER
    DEFINE i, stat      INTEGER

    PREPARE recordUpdate FROM _UPDATESQL

    IF ( thisData IS NOT NULL ) THEN   --> Don't allow a NULL key value for update
        # Create and array from the string to walk through...much easier than filling BDL arrays:records:elements
        LET thisJSONArr = util.JSONArray.parse(thisData)

        # Walk the JSON Array and update each element to the data source
        FOR i = 1 TO thisJSONArr.getLength()-1  --> must account for empty element 
            LET thisJSONObj = thisJSONArr.get(i)

            # Update account by userid    
            CALL updateRecordById(thisJSONObj.toString()) RETURNING rowsUpdated

            CALL logger.logEvent(logger._LOGDEBUG ,SFMT("Rows Updated:%1",__LINE__),"processRecordsUpdate",
                SFMT("Update status: %1 - %2", SQLSTATE, SQLERRMESSAGE ))
        END FOR 
    END IF

    IF ( rowsUpdated ) THEN 
        LET stat = 200
    ELSE 
        LET stat = 204  --> Just something to show no rows updated.  Should respond
                        --> with 200 and message text "no rows updated".
    END IF

    FREE recordUpdate

    # TODO: formulate a JSON style response for an update
    RETURN stat
  
END FUNCTION
}
################################################################################
#+
#+ Method: updateRecordById(thisData STRING)
#+
#+ Update the given record in the data source.
#+
#+    Executes the update to the given record in the datasource returning  
#+    the number of rows processed.  If no rows found, return zero.
#+
#+ @code
#+ CALL updateRecordById(thisID) RETURNING rowsUpdated
#+
#+ @param thisData STRING : representation of sample record
#+
#+ @return stat INTEGER : number of rows updated
#+
{
PRIVATE FUNCTION updateRecordById(thisData STRING) RETURNS INTEGER 
    DEFINE thisRecord recordType
    DEFINE parseObject util.JSONObject
    DEFINE stat INTEGER 
    
    LET parseObject = util.JSONObject.parse(thisData)  
    CALL parseObject.toFGL(thisRecord)

    ##For brevity in demo, only updating first and last name...it could be all fields
    ##UPDATE tabname SET firstname = ?, lastname = ? WHERE userid = ?" 

    ###EXECUTE recordUpdate USING thisRecord.firstname, thisRecord.lastname, thisRecord.userid -- a list from the record thisAccount.firstname, 

    # Return the number of rows processed to report success status                           
    LET stat = SQLCA.SQLERRD[3]

    RETURN stat
    
END FUNCTION
}
################################################################################
#+
#+ Method: processRecordInsert(query STRING)
#+
#+ Performs tasks to insert a list of records information into the datasource.
#+
#+    Processes a list of records to be inserted into the datasource returning 
#+    success/fail 
#+
#+ @code
#+ LET status = processRecordInsert(thisData)
#+
#+ @param thisData STRING : representation of sample array
#+
#+ @return stat INTEGER : HTTP status code
#+
{
PUBLIC FUNCTION processRecordsInsert(thisData STRING, p STRING) RETURNS INTEGER 
    DEFINE thisJSONArr  util.JSONArray
    DEFINE thisJSONObj  util.JSONObject
    DEFINE i INTEGER
    DEFINE txt STRING
    DEFINE login loginType
    DEFINE theseRecords DYNAMIC ARRAY OF recordType
    DEFINE createStatus INTEGER
  DEFINE now DATETIME YEAR TO SECOND
  DEFINE  token   STRING

    WHENEVER ANY ERROR RAISE
    LET createStatus = 200
    PREPARE recordInsert FROM _INSERTSQL

    ## Get the user login from the request
    CALL util.JSON.parse(thisData, login)

    ## Validate user login
    CALL getRecords()
    ## We only expect one record, so only look at the first one
    LET theseRecords = getRecordsList()
    IF theseRecords[1].login IS NULL THEN
        LET createStatus = 401
    ELSE
          ## Create a session cookie(s)
          LET now = CURRENT
          LET mCookies[1].expires = CURRENT +  C_COOKIE_DURATION
          LET mCookies[1].name = "GeneroAuthz"
          LET mCookies[1].value = createAuthzToken(mCookies[1].expires)
          LET mCookies[1].path = "/" # To apply cookie to all service
          LET mCookies[1].httpOnly = TRUE

    END IF 

    FREE recordInsert

    # TODO: formulate a JSON style response for an update
    RETURN createStatus
  
END FUNCTION
}

################################################################################
#+
#+ Method: insertRecord(thisData STRING)
#+
#+ Creates the given record in the data source.
#+
#+    Executes the insert of the given record into the datasource returning  
#+    the number of rows processed.  If no rows found, return zero.
#+
#+ @code
#+ LET status = insertRecord(thisData)
#+
#+ @param thisData STRING : representation of sample record
#+
#+ @return stat INTEGER : SQLCA.SQLCODE
#+
{PRIVATE FUNCTION insertRecord(thisData)
    DEFINE thisData    STRING
    DEFINE thisRecord  recordType
    DEFINE parseObject util.JSONObject
    DEFINE stat INT
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("tabname:%1",__LINE__),"insertRecord",
        SFMT("Record data: %1", thisData))

    LET parseObject = util.JSONObject.parse(thisData)  --> Parse JSON string
    CALL parseObject.toFGL(thisRecord)                 --> Put JSON into FGL

    EXECUTE recordInsert USING thisRecord.*

    LET stat = SQLCA.SQLCODE

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("tabname:%1",__LINE__),"insertRecord",
        SFMT("Insert status: %1 - %2", SQLSTATE, SQLERRMESSAGE ))

    RETURN --stat
    
END FUNCTION
}

################################################################################
#+
#+ Method: deleteRecords
#+
#+ Delete the account records from the database
#+
#+    Deletes records from data source
#+
#+ @code
#+ CALL deleteRecords()
#+
#+ @param NONE
#+
#+ @return stat INTEGER
#+
{
PUBLIC FUNCTION deleteRecords() RETURNS INTEGER
    DEFINE i, stat INTEGER 
    DEFINE sqlStatement STRING

    WHENEVER ANY ERROR RAISE -- Let the referencing call handle the errors
    
    # Add query filter to standard SQL
    LET sqlStatement = _DELETESQL
    
    IF ( mQuery.id IS NOT NULL ) THEN -- Don't execute a DELETE without a filter   
        CALL logger.logEvent(logger._LOGDEBUG ,SFMT("tabname:%1",__LINE__),"deleteRecords",
            SFMT("SQL statement: %1", sqlStatement))

        PREPARE deleteStatement FROM sqlStatement
        EXECUTE deleteStatement USING mQuery.id

        # Return the number of rows processed to report success status                           
        LET stat = SQLCA.SQLERRD[3]

        CLOSE curs
        FREE curs
    END IF

    RETURN stat
    
END FUNCTION
}
################################################################################
#+
#+ Method: processRecordsDelete(thisID STRING)
#+
#+ Performs tasks to delete a list of records from the datasource.
#+
#+    Processes a list of records to delete from the datasource returning  
#+    success/fail.
#+
#+ @code
#+ LET status = processRecordsDelete(thisID STRING)
#+
#+ @param thisData STRING : record key to be deleted
#+
#+ @return stat INTEGER : HTTP status code
#+
{
PRIVATE FUNCTION processRecordsDelete(deletePayload STRING) RETURNS INTEGER 
    DEFINE thisJSONArr  util.JSONArray
    DEFINE thisJSONObj  util.JSONObject
    DEFINE i INTEGER 
   
    PREPARE recordDelete FROM _DELETESQL

    IF ( deletePayload IS NOT NULL )  THEN    --> Don't allow a NULL resource creation
      # Create and array from the string to walk through...much easier than filling BDL arrays:records:elements
      #LET thisJSONArr = util.JSONArray.parse(deletePayload)
      # Walk the JSON Array and delete each element from the data source
      #FOR i = 1 TO thisJSONArr.getLength()-1  --> must account for element ""
         #LET thisJSONObj = thisJSONArr.get(i)
         # Delete record 
         CALL deleteRecordById(deletePayload)
      #END FOR 
     
    END IF

    FREE recordDelete

    RETURN 200
    
END FUNCTION
}
################################################################################
#+
#+ Method: deleteRecordById(thisID)
#+
#+ Delete the given record in the data source.
#+
#+    Executes the delete of the given sample record in the datasource returning  
#+    the number of rows processed.
#+
#+ @code
#+ LET status = deleteRecordById(thisID)
#+
#+ @param thisID STRING : record key of sample record
#+
#+ @return NONE
#+
{
PRIVATE FUNCTION deleteRecordById(recordID STRING)
    DEFINE thisRecord  recordType
    DEFINE parseObject util.JSONObject
    DEFINE stat INT
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("account:%1",__LINE__),"deleteRecordById",
        SFMT("Record data: %1", recordID))
        
    #LET parseObject = util.JSONObject.parse(recordID)  --> Parse JSON string
    #CALL parseObject.toFGL(thisRecord)                 --> Put JSON into FGL

    EXECUTE recordDelete USING recordID
    LET stat = SQLCA.SQLCODE

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("account:%1",__LINE__),"deleteRecordById",
        SFMT("Delete status: %1 - %2", SQLSTATE, SQLERRMESSAGE ))

   # TODO: formulate a JSON style response for an update
    RETURN --stat

END FUNCTION
}
