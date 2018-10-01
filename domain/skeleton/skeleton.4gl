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
################################################################################
#+ This module implements tabname class information handling
#+
#+ This code uses the 'officestore' database tables.
#+ tabname input, query and list handling functions are defined here.
#+

IMPORT util

# Logging utility
IMPORT FGL logger

SCHEMA officestore

&include "skeletonTypes.inc"

#
# Module variables
#
DEFINE mQuery RECORD
    id STRING, 
    fname STRING,
    lname STRING
END RECORD

DEFINE mSqlWhere STRING

#TODO: determine if mutators should be used instead; should be PRIVATE; how to do this for an array
PUBLIC DEFINE mRecords DYNAMIC ARRAY OF recordType 

################################################################################
#+
#+ Method: getRecords
#+
#+ Get the tabname records from the database
#+
#+    Retrieves records from data source and stores in the storage array
#+
#+ @code
#+ CALL getRecords()
#+
#+ @param NONE
#+
#+ @return NONE
#+
PUBLIC FUNCTION getRecords()
    DEFINE i INTEGER 
    DEFINE sqlStatement STRING

    WHENEVER ANY ERROR RAISE -- Let the referencing call handle the errors
    
    # Add query filter to standard SQL
    LET sqlStatement = SFMT("%1 %2", _SELECTSQL, getQueryFilter())

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("tabname:%1",__LINE__),"getRecords",
        SFMT("SQL statement: %1", sqlStatement))

    CALL mRecords.clear()
    PREPARE cursorStatement FROM sqlStatement
    DECLARE curs CURSOR FOR cursorStatement
    LET i = 1
    FOREACH curs INTO mRecords[i].*
        LET i = i+1
    END FOREACH

    CLOSE curs
    FREE curs
    
END FUNCTION

################################################################################
#+
#+ Method: getJSONEncoding()
#+
#+ Format the records from using JSON encoding
#+
#+    Returns a string representation of the sample storage array in JSON format
#+
#+ @code
#+ CALL getJSONEncoding()
#+
#+ @param NONE
#+
#+ @return util.JSON.stringify(mRecords recordType)
#+
PUBLIC FUNCTION getJSONEncoding() RETURNS STRING
    RETURN util.JSON.stringify(mRecords)
END FUNCTION

################################################################################
#+
#+ Method: init()
#+
#+ Initialize the account record storage
#+
#+    Clears the sample storage array of all records
#+
#+ @code
#+ CALL init()
#+
#+ @param NONE
#+
#+ @return NONE
#+
PUBLIC FUNCTION init()
    CALL mRecords.clear()
END FUNCTION

################################################################################
#+
#+ Method: getRecordsList()
#+
#+ Accessor for the tabname records array.
#+
#+    Always return a list array(pointer).  The idea is that one or many it 
#+    doesn't matter, always return a list(array)
#+
#+ @code
#+ CALL getRecordsList()
#+
#+ @param NONE
#+
#+ @return mRecords recordType
#+
PUBLIC FUNCTION getRecordsList() RETURNS DYNAMIC ARRAY OF recordType
    RETURN mRecords
END FUNCTION

################################################################################
#+
#+ Method: processRecordsUpdate(thisData STRING)
#+
#+ Performs tasks to update records in the data source
#+
#+    Processes a list of records to update the changes to the records for storage
#+    to the data source
#+
#+ @code
#+ LET status = processRecordsUpdate(thisData)
#+
#+ @param thisData STRING : representation of an array of records
#+
#+ @return stat INTEGER : appropriate HTTP status code
#+
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
        FOR i = 1 TO thisJSONArr.getLength()-1  --> must account for element "{}"
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
PUBLIC FUNCTION processRecordsInsert(thisData STRING) RETURNS INTEGER 
    DEFINE thisJSONArr  util.JSONArray
    DEFINE thisJSONObj  util.JSONObject
    DEFINE i INTEGER 

    PREPARE recordInsert FROM _INSERTSQL

    IF ( thisData IS NOT NULL )  THEN    --> Don't allow a NULL resource creation
        # Create and array from the string to walk through...much easier than filling BDL arrays:records:elements
        LET thisJSONArr = util.JSONArray.parse(thisData)
        # Walk the JSON Array and insert each element to the data source
        FOR i = 1 TO thisJSONArr.getLength()-1  --> must account for element "{}"
            LET thisJSONObj = thisJSONArr.get(i)
            # Insert new record 
            CALL insertRecord(thisJSONObj.toString())
        END FOR 
     
    END IF

    FREE recordInsert

    # TODO: formulate a JSON style response for an update
    RETURN 200
  
END FUNCTION


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
PRIVATE FUNCTION insertRecord(thisData)
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
PRIVATE FUNCTION processRecordsDelete(deletePayload STRING) RETURNS INTEGER 
    DEFINE thisJSONArr  util.JSONArray
    DEFINE thisJSONObj  util.JSONObject
    DEFINE i INTEGER 
   
    PREPARE recordDelete FROM _DELETESQL

    IF ( deletePayload IS NOT NULL )  THEN    --> Don't allow a NULL resource creation
      # Create and array from the string to walk through...much easier than filling BDL arrays:records:elements
      #LET thisJSONArr = util.JSONArray.parse(deletePayload)
      # Walk the JSON Array and delete each element from the data source
      #FOR i = 1 TO thisJSONArr.getLength()-1  --> must account for element "{}"
         #LET thisJSONObj = thisJSONArr.get(i)
         # Delete record 
         CALL deleteRecordById(deletePayload)
      #END FOR 
     
    END IF

    FREE recordDelete

    RETURN 200
    
END FUNCTION

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

################################################################################
#+
#+ Method: getQueryFilter()
#+
#+ Return the query filter previously determined using addQueryFilter()
#+
#+    Returns the query filter in the form of a WHERE clause  
#+
#+ @code 
#+  LET sqlStatement = SFMT("%1 %2", _SELECTSQL, getQueryFilter())
#+
#+ @param NONE
#+
#+ @return mSqlWhere STRING : SQL where clause for query
#+
PRIVATE FUNCTION getQueryFilter() RETURNS STRING
    RETURN mSqlWhere
END FUNCTION

################################################################################
#+
#+ Method: isValidQuery()
#+
#+ Boolean method determining valid query filter request
#+
#+    Returns BOOLEAN true/false
#+
#+ @code 
#+  IF account.isValidQuery(queryParameter)
#+
#+ @param queryParameter STRING : Name of query parameter
#+
#+ @return TRUE/FALSE
#+
PUBLIC FUNCTION isValidQuery( queryName STRING )

    CASE (queryName)
        WHEN "queryKey"
            RETURN TRUE
        OTHERWISE
            RETURN FALSE
    END CASE

END FUNCTION

################################################################################
#+
#+ Method: addQueryFilter()
#+
#+ Add a valid query key and value to the standard query filter(WHERE 1=1)
#+
#+ @code 
#+  CALL account.addQueryFilter(columnKey, columnValue)
#+
#+ @param columnKey   STRING : Column name key
#+ @param columnValue STRING : Column query value
#+
#+ @return NONE
#+
PUBLIC FUNCTION addQueryFilter(columnKey STRING, columnValue STRING)

    CASE (columnKey)
        WHEN "queryKey"
            LET mSqlWhere = SFMT("%1 %2 '%3'", mSqlWhere, " AND columnName LIKE ", columnValue)
    END CASE

END FUNCTION

#+ 
#+ Module mutators
#+
FUNCTION initQuery()
    INITIALIZE mQuery.* TO NULL
    LET mSqlWhere = "WHERE 1=1"
END FUNCTION

{
FUNCTION setQueryid(thisID STRING)
    LET mQuery.id = thisID
END FUNCTION

FUNCTION setQueryFname(thisID STRING)
    LET mQuery.fname = thisID
END FUNCTION

FUNCTION setQueryLname(thisID STRING)
    LET mQuery.lname = thisID
END FUNCTION
}