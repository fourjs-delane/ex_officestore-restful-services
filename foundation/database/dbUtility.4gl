################################################################################
# FOURJS_START_COPYRIGHT(U,2017)
# Property of Four Js*
# (c) Copyright Four Js 2017, 2018. All Rights Reserved.
# * Trademark of Four Js Development Tools Europe Ltd
#   in the United States and elsewhere
# 
# Four Js and its suppliers do not warrant or guarantee that these samples
# are accurate and suitable for your purposes. Their inclusion is purely for
# information purposes only.
# FOURJS_END_COPYRIGHT
#
#+  Database Foundation Library
#+  - dbConnect()    : connects to database configured in the environment FGLDBNAME
#+  - dbDisconnect() : disconnects from the current database
#+
IMPORT FGL logger

################################################################################
#+ Connect to a database specified in the environment.
#+
#+ @code
#+ CALL dbConnect()
#+
#+ @param  NONE
#+
#+ @return NONE
#
PUBLIC FUNCTION dbConnect()
    IF ( fgl_getenv("FGLDBNAME") IS NOT NULL ) THEN
        CONNECT TO fgl_getenv("FGLDBNAME")
        
        # Make sure to have committed read isolation level and wait for locks
        WHENEVER ERROR CONTINUE   # Ignore SQL errors if instruction not supported
        SET ISOLATION TO COMMITTED READ
        SET LOCK MODE TO WAIT
    ELSE
        CALL logger.logEvent(logger._LOGMSG,ARG_VAL(0),SFMT("%1:%2",__FILE__,__LINE__), "Application database(FGLDBNAME) is not specified.")
        CALL programExit(1)
    END IF

    WHENEVER ANY ERROR RAISE -- Let the application handle initialization failures
    RETURN 
END FUNCTION

################################################################################
#+ Disconnect from the current database
#+
#+ @code
#+ CALL dbDisconnect()
#+
#+ @param  NONE
#+
#+ @return NONE
#+
PUBLIC FUNCTION dbDisconnect()

  # Disconnect current DB
  DISCONNECT CURRENT 
  
END FUNCTION
