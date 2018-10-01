SCHEMA officestore

##############################################################################
#+
#+ CLASS "lineitem" record types:
#+ - Complete table list
#+ - Include for types associated with the "lineitem" object
#+

#
# Standard SQL statement CONSTANTs
#
CONSTANT _SELECTSQL = "SELECT a.*, c.productid FROM lineitem a, item b, product c"
CONSTANT _SQL = "SELECT * FROM lineitem"
CONSTANT _UPDATESQL = "UPDATE lineitem SET unitprice = ? WHERE orderid = ? and linenum = ?" 
CONSTANT _INSERTSQL = "INSERT INTO lineitem VALUES (?, ?, ?, ?, ?)"
CONSTANT _DELETESQL = "DELETE FROM lineitem WHERE orderid = ? and linenum = ?"

#
# User type definitions
#
TYPE recordType RECORD
    orderitem RECORD LIKE lineitem.*,
    productID LIKE product.productid
END RECORD
 
