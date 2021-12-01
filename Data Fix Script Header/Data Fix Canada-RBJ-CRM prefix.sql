
--USE prodServSuiteData --BOSS US-
USE RollinsBackgroundJobs -- CRM - Canada 


SELECT db_name()
DECLARE @filename nvarchar(100) = 'CHG0042553_Request Full feed of all tables Date filter_SB and CRMbrandon'  -- FIlename here, without extention
DECLARE @cr char(10) = substring(@filename, 1, 10)
SELECT @@SERVERNAME  --RWBCDBAGH201
if (SELECT @@SERVERNAME) != 'RWBCDBAGH202\REPLICA01' 
begin 
    print'This script is supposed to be executed on server RWBCDBAGH202\REPLICA01'
	SELECT 'This script is supposed to be executed on server RWBCDBAGH202\REPLICA01'
	RETURN
end 

if (select companyname from ServSuiteData.dbo.tcompany) != 'Orkin Canada' 
begin 
    print'This script is supposed to be executed against BOSS Orkin Canada' 
	RETURN
end 
PRINT 'CR# - '+ @cr +' Script - ' +@filename +'.sql - Database - '+db_name()+' Server - '+@@SERVERNAME

