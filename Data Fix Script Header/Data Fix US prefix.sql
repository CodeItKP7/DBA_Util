
--CONNECT RWBDBAGH211
USE prodServSuiteData --BOSS US-

SELECT db_name()
SELECT @@SERVERNAME  --RWBDBAGH211
DECLARE @filename nvarchar(100) = 'CHG0041734_Prog_Change_NEW'  -- Filename here, without extention
DECLARE @cr char(10) = substring(@filename, 1, 10)
if (SELECT @@SERVERNAME) != 'RWBDBAGH211' 
begin 
    print'This script is supposed to be executed on server RWBDBAGH211'
	SELECT 'This script is supposed to be executed on server RWBDBAGH211'
	RETURN
end 

if (select companyname from tcompany) != 'Rollins Inc.' 
begin 
    print'This script is supposed to be executed against BOSS Orkin US'
end 
PRINT 'CR# - '+ @cr +' Script - ' +@filename +'.sql - Database - '+db_name()+' Server - '+@@SERVERNAME

------------------------------------------------------------------------------------------------------------------------------------
--  Add contents of script below
------------------------------------------------------------------------------------------------------------------------------------
