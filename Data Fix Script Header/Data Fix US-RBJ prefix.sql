USE RollinsBackgroundJobs --RBJ US-

SELECT db_name()
SELECT @@SERVERNAME  --RWBDBAGH213\Mobile01
DECLARE @filename nvarchar(100) = 'CHG0042544'  -- Filename here, without extention
DECLARE @cr char(10) = substring(@filename, 1, 10)
if (SELECT @@SERVERNAME) != 'RWBDBAGH213\Mobile01' 
begin 
    print'This script is supposed to be executed on server RWBDBAGH213\Mobile01 (REPLICA02)'
	SELECT 'This script is supposed to be executed on server RWBDBAGH213\Mobile01 (REPLICA02)'
	RETURN
end 

if (select companyname from prodServSuiteData.dbo.tcompany) != 'Rollins Inc.' 
begin 
    print'This script is supposed to be executed against BOSS Orkin US'
end 
PRINT 'CR# - '+ @cr +' Script - ' +@filename +'.sql - Database - '+db_name()+' Server - '+@@SERVERNAME

------------------------------------------------------------------------------------------------------------------------------------
--  Add contents of script below
------------------------------------------------------------------------------------------------------------------------------------
