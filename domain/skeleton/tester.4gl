IMPORT util
IMPORT FGL skeleton


MAIN
    DEFINE rt INTEGER 
    DATABASE officestore

    WHENEVER ANY ERROR CONTINUE

    # Query test
    TRY
        CALL skeleton.setQueryID("bloggs")
        CALL skeleton.getRecords()
    CATCH
        DISPLAY SFMT("QUERY of tabname '%1' has failed: %2: %3", mRecords[1].userid CLIPPED, SQLCA.sqlcode, SQLERRMESSAGE)
    END TRY 

    # JSON encoding
    DISPLAY SFMT("QUERY JSONEncoding: %1", skeleton.getJSONEncoding())

    # Update test
    TRY 
        LET mRecords[1].firstname  = "Teq"
        LET mRecords[1].lastname   = "Supp"
        
        CALL skeleton.processRecordsUpdate(skeleton.getJSONEncoding()) RETURNING rt
        CALL skeleton.getRecords()
        DISPLAY SFMT("UPDATE JSONEncoding: %1", skeleton.getJSONEncoding())

        LET mRecords[1].firstname  = "Fred"
        LET mRecords[1].lastname   = "Bloggs"
        CALL skeleton.processRecordsUpdate(skeleton.getJSONEncoding()) RETURNING rt
        CALL skeleton.getRecords()
        DISPLAY SFMT("UPDATE2 JSONEncoding: %1", skeleton.getJSONEncoding())
    CATCH
        DISPLAY SFMT("UPDATE of tabname '%1' has failed: %2: %3", mRecords[1].userid CLIPPED, SQLCA.sqlcode, SQLERRMESSAGE)
    END TRY

    # Insert test
    TRY
        CALL skeleton.init()
        LET mRecords[1].userid      = "teqsupp"
        LET mRecords[1].email       = "teq@supp.com" 
        LET mRecords[1].firstname   = "Teq"
        LET mRecords[1].lastname    = "Supp"
        LET mRecords[1].acstatus    = "OK"
        LET mRecords[1].addr1       = "123 Easy Street"
        LET mRecords[1].city        = "Anywhere"
        LET mRecords[1].state       = "Restful"
        LET mRecords[1].country     = "USA"
        LET mRecords[1].zip         = "00000-0000"
        LET mRecords[1].phone       = "COCONUT EXPRESS"
        LET mRecords[1].favcategory = "SUPPLIES"
        LET mRecords[1].langpref    = "Piglat"
        LET mRecords[1].mylistopt   = 1
        LET mRecords[1].banneropt   = 1
        LET mRecords[1].sourceapp   = "WEB"
        
        CALL skeleton.processRecordsInsert(skeleton.getJSONEncoding()) RETURNING rt
        CALL skeleton.setQueryID("teqsupp")
        CALL skeleton.getRecords()
        DISPLAY SFMT("INSERT JSONEncoding: %1", skeleton.getJSONEncoding())
    CATCH
        DISPLAY SFMT("INSERT of tabname '%1' has failed: %2: %3", mRecords[1].userid CLIPPED, SQLCA.sqlcode, SQLERRMESSAGE)
    END TRY
    
    # Delete test
    TRY 
        DISPLAY SFMT("Deleting record: %1", "teqsupp")
        CALL skeleton.init()
        LET mRecords[1].userid     = "teqsupp"
        CALL skeleton.processRecordsDelete(account.getJSONEncoding()) RETURNING rt
        CALL skeleton.setQueryid("teqsupp")
        CALL skeleton.getRecords()
        DISPLAY SFMT("JSONEncoding: %1 <-- Should be the empty set '{}' after the delete of the inserted record", skeleton.getJSONEncoding())
    CATCH 
        DISPLAY SFMT("DELETE of tabname '%1' has failed: %2: %3", mRecords[1].userid CLIPPED, SQLCA.sqlcode, SQLERRMESSAGE)
    END TRY 
END MAIN
