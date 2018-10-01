IMPORT FGL WSHelper

MAIN

DEFINE val, scheme, host, port, path, query STRING
DEFINE ind INTEGER
DEFINE ret WSHelper.WSQueryType

CALL WSHelper.SplitQueryString("name1=val1&name2=val2&name3=val3")
  RETURNING ret

FOR ind = 1 TO ret.getLength()
  DISPLAY "Query",ind
  DISPLAY " name is",ret[ind].name
  DISPLAY " value is ",ret[ind].value
END FOR

LET val = WSHelper.FindQueryStringValue("name1=val1&name2=val2","name1")

CALL WSHelper.SplitUrl("https://cube.strasbourg.4js.com:3128/GWS-492/TestSplitURL/test1?xparm=foo") 
RETURNING scheme, host, port, path, query
DISPLAY SFMT("SplitURL: scheme=%1, host=%2, port=%3, path=%4, query=%5", scheme, host, port, path, query)

END MAIN
