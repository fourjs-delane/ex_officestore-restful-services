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
IMPORT util
IMPORT com
IMPORT security

# GWS Helpers
IMPORT FGL WSHelper

# Logging utility
IMPORT FGL logger

# HTTP Utility
IMPORT FGL http

################################################################################
#+
#+ Method: createSessionToken()
#+
#+ Description: Creates a new session cookie(token) in storage
#+
#+ Return: ?
#+
# TODO: how much of creating a cookie belongs in the domain?
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
#+ Return: ?
#+
FUNCTION deleteSessionToken(thisToken VARCHAR(255))
    DELETE FROM authtokens WHERE token = thisToken
    RETURN sqlca.SQLCODE
END FUNCTION 