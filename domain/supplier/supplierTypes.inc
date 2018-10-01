SCHEMA officestore

##############################################################################
#+
#+ CLASS "supplier" record types:
#+ - Complete table list
#+ - Include for types associated with the "supplier" object
#+

#
# Standard SQL statement CONSTANTs
#
CONSTANT _SELECTSQL = "SELECT * FROM supplier"
CONSTANT _UPDATESQL = "UPDATE supplier SET name = ? WHERE suppid = ?" 
CONSTANT _INSERTSQL = "INSERT INTO supplier VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
CONSTANT _DELETESQL = "DELETE FROM supplier WHERE suppid = ?"

#
# User type definitions
#
TYPE recordType RECORD LIKE supplier.*