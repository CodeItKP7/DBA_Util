
--USE prodServSuiteData --BOSS US-
USE ServSuiteData -- CRM - Canada 


SELECT db_name()
DECLARE @filename nvarchar(100) = 'CHG0041736_wo_target'  -- FIlename here, without extention
DECLARE @cr char(10) = substring(@filename, 1, 10)
SELECT @@SERVERNAME  --RWBCDBAGH201
if (SELECT @@SERVERNAME) != 'RWBCDBAGH201' 
begin 
    print'This script is supposed to be executed on server RWBCDBAGH201'
	SELECT 'This script is supposed to be executed on server RWBCDBAGH201'
	RETURN
end 

if (select companyname from tcompany) != 'Orkin Canada' 
begin 
    print'This script is supposed to be executed against BOSS Orkin Canada' 
	RETURN
end 
PRINT 'CR# - '+ @cr +' Script - ' +@filename +'.sql - Database - '+db_name()+' Server - '+@@SERVERNAME

