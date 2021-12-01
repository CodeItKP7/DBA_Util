
--USE prodServSuiteData --BOSS US-
USE ServSuiteData -- Specialty Brands


SELECT db_name()
DECLARE @filename nvarchar(100) = 'CHG0041736_wo_target'  -- FIlename here, without extention
DECLARE @cr char(10) = substring(@filename, 1, 10)
SELECT @@SERVERNAME  --RWSBDBH202
if (SELECT @@SERVERNAME) != 'RWSBDBH201' 
begin 
    print'This script is supposed to be executed on server RWSBDBH201'
	SELECT 'This script is supposed to be executed on server RWSBDBH201'
	RETURN
end 

if (select companyname from tcompany) != 'Western' 
begin 
    print'This script is supposed to be executed against BOSS Specialty Brands' 
	RETURN
end 
PRINT 'CR# - '+ @cr +' Script - ' +@filename +'.sql - Database - '+db_name()+' Server - '+@@SERVERNAME


