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
IMPORT com
IMPORT security

# GWS Helpers
IMPORT FGL WSHelper

# Logging utility
IMPORT FGL logger

# HTTP Utility
IMPORT FGL http

# Authorization cookies
IMPORT FGL credential

DEFINE cookieBox WSServerCookiesType

################################################################################
#+
#+ Method: bakeCookies()
#+
#+ Description: Creates a session cookie for WSHelper
#+
#+ @code
#+ CALL bakeCookies(cookieName STRING, base STRING, http BOOLEAN)
#+
#+ @parameter
#+ cookieName STRING
#+ base STRING
#+ http BOOLEAN
#+
#+ @return
#+ NONE
#+ TODO:Perhaps there is more than one cookie; if so, send an array 
#+
FUNCTION bakeCookies(cookieName STRING, base STRING, http BOOLEAN)
    DEFINE expiration DATETIME YEAR TO SECOND

    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("cookieFactory:%1",__LINE__),"bakeCookies",
        "Baking a cookie")

    LET expiration = CURRENT + INTERVAL (1) DAY TO DAY

    LET cookieBox[1].NAME = cookieName
    LET cookieBox[1].path = base
    LET cookieBox[1].httpOnly = http
    LET cookieBox[1].expires = expiration

    # get a token for the cookie
    # set the token in the cookie record    

    LET cookieBox[1].VALUE = credential.createSessionToken(expiration)
    # ? other cookie values

END FUNCTION

################################################################################
#+
#+ Method: getCookies()
#+
#+ Description: Returns pointer to the session cookie(s) for WSHelper
#+
#+ @code
#+ CALL getCookies() RETURNS WSServerCookiesType
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ Return: a box(array pointer) of cookies
#+
FUNCTION getCookies() RETURNS WSServerCookiesType -- box of cookies
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("cookieFactory:%1",__LINE__),"getCookies",
        "Getting a cookie")
    RETURN cookieBox    
END FUNCTION

################################################################################
#+
#+ Method: checkCookie()
#+
#+ Description: Is the cookie good?
#+
#+ @code
#+ CALL checkCookies(thisCookieToken STRING) RETURNS BOOLEAN
#+
#+ @parameter
#+ NONE
#+
#+ @return
#+ BOOLEAN    TRUE=cookie hasn't expired
#+            FALSE=cookie is past it's prime(expired)
#+
FUNCTION checkCookies(thisCookieToken STRING) RETURNS BOOLEAN
    DEFINE clockTime DATETIME YEAR TO SECOND
    DEFINE isValidCookie BOOLEAN
    
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("cookieFactory:%1",__LINE__),"checkCookies",
        "Checking if a cookie is good(not expired)")

    LET clockTime = CURRENT
    
    # Query the cookie token
    # Is it not found or expired?
    SELECT token
      FROM authtokens
     WHERE token = thisCookieToken AND expires > clockTime

    IF SQLCA.sqlcode == 0 THEN
        LET isValidCookie = TRUE # Found valid token
    END IF
    RETURN isValidCookie
END FUNCTION 

################################################################################
#+
#+ Method: eatCookies()
#+
#+ Description: Deletes a session cookie(token)
#+
#+ @code
#+ CALL eatCookies(thisCookie STRING)
#+
#+ @parameter
#+ thisCookie STRING
#+
#+ @return
#+ NONE
#+
FUNCTION eatCookies(thisCookie STRING)
    CALL logger.logEvent(logger._LOGDEBUG ,SFMT("cookieFactory:%1",__LINE__),"eatCookies",
        "Mmmmm, COOKIE!")
    # delete the cookie token
END FUNCTION