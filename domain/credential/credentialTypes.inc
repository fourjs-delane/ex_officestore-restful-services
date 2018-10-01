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
SCHEMA officestore

##############################################################################
#+
#+ CLASS "credentials" record types:
#+ - Complete table list
#+ - Include for types associated with the "credentials" object
#+

#
# Standard SQL statement CONSTANTs
#
CONSTANT _SELECTSQL = "SELECT login, firstname, lastname, image FROM credentials"
#CONSTANT _UPDATESQL = "UPDATE tabname  SET firstname = ?, lastname = ? WHERE userid = ?" 
#CONSTANT _INSERTSQL = "INSERT INTO credentials VALUES (0, ?, ?, ?, ?, ?)"
CONSTANT _DELETESQL = "DELETE FROM credentials WHERE login = ?"

#
# User type definitions
#
TYPE recordType RECORD LIKE credentials.*
{
    login               VARCHAR(255),
    firstname           VARCHAR(255),
    lastname            VARCHAR(255),
    imageId             INTEGER
END RECORD 
}
PUBLIC TYPE loginType RECORD
    login               VARCHAR(255),
    password            VARCHAR(255)
END RECORD

