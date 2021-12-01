/*OWSSTDBAGO204.ServSuite... Test4 Environment Scripts Combined*/
/*OWSSTDBAGO204 = Live*/
/*OWSSDDBO248 = Replica1*/
/*Created by Ben Shearouse\Shyam S.*/
/*Created on 12/06/2017*/
/*Revised for new Test-4 Server 2021/11/02 by Blake Ceatham */

/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/
/*YOU MUST TURN ON SQLCMD MODE TO RUN THIS REFRESH SCRIPT!!!*/
/*QUERY MENU - SQLCMD MODE									*/
/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

PRINT '';
PRINT 'Database Refresh Script Last Updated: 2021-11-02 by Blake Cheatham';

/*********************************************************************************************************/
/*********************************************************************************************************/
/*********************************************************************************************************/
:Connect OWSSTDBAGO204

PRINT 'Connected to OWSSTDBAGO204';
PRINT GETDATE();
PRINT '';

PRINT 'Beginning Test4 Database Refresh on OWSSTDBAGO204';
PRINT GETDATE();
PRINT '';

PRINT 'Disable Cohesity backup job';
PRINT GETDATE();
EXEC msdb.dbo.sp_start_job @job_name='Disable cohesity backup job', @server_name='OWSSDDBO249';

PRINT '';
PRINT '';
PRINT 'Disabled testservsuiteapp SQL Login';
PRINT 'Disabled ROLLINS\sststsvc SQL Login';
PRINT GETDATE();
USE [master];
ALTER LOGIN [testservsuiteapp] DISABLE;
ALTER LOGIN [ROLLINS\sststsvc] DISABLE;

/*Remove databases from AlwaysOn Availability Groups*/
PRINT '';
PRINT '';
PRINT 'Remove databases from AlwaysOn Availability Groups';
PRINT GETDATE();
USE [master];
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ServSuiteData];
PRINT 'Removed ServSuiteData from AlwaysOn Availability Groups';
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ServSuiteLog];
PRINT 'Removed ServSuiteLog from AlwaysOn Availability Groups';
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ServSuiteWBProgram];
PRINT 'Removed ServSuiteWBProgram from AlwaysOn Availability Groups';
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ServSuiteWBReport];
PRINT 'Removed ServSuiteWBReport from AlwaysOn Availability Groups';
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ServSuiteWBUser];
PRINT 'Removed ServSuiteWBUser from AlwaysOn Availability Groups';
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ZenithCommissionsIntegrated];
PRINT 'Removed ZenithCommissionsIntegrated from AlwaysOn Availability Groups';
ALTER AVAILABILITY GROUP [BOSS_AG1]
REMOVE DATABASE [ZenithIntegrated];
PRINT 'Removed ZenithIntegrated from AlwaysOn Availability Groups';
PRINT 'Removed 7 databases from AlwaysOn Availability Groups';

/**************************************************************************************************************************/
/*
--Added 3/9/2017 by Ben Shearouse
--This cleans up RollinsBackgroundJobs database so that refreshes don't fail
--due to lack of storage.
--Needs to run everywhere there is an RBJ database: Live, Replica1 and Replica2.
*/

PRINT '';
PRINT '';
PRINT 'Clean out and shrink RollinsBackgroundJobs database.';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
TRUNCATE TABLE ssmobile.mobileq1;
TRUNCATE TABLE ssmobile.mobileq2;
TRUNCATE TABLE ssmobile.mobileq3;
TRUNCATE TABLE BIFEEDQueue_A;
TRUNCATE TABLE BIFEEDQueue_B;

USE [RollinsBackgroundJobs];
DBCC SHRINKFILE (N'RollinsBackgroundJobs' , 50000);
DBCC SHRINKFILE (N'RollinsBackgroundJobs_log' , 2048);
WAITFOR DELAY '00:01';  /*wait 1 minute*/
DBCC SHRINKFILE (N'RollinsBackgroundJobs_log' , 2048);

/**************************************************************************************************************************/


/**************************************************************/
/*Make sure to set the backup location to the correct backups.*/
/**************************************************************/
DECLARE @backupLocationServSuiteData varchar(200)
DECLARE @backupLocationServSuiteLog varchar(200)
DECLARE @backupLocationServSuiteWBProgram varchar(200)
DECLARE @backupLocationServSuiteWBReport varchar(200)
DECLARE @backupLocationServSuiteWBUser varchar(200)
DECLARE @backupLocationZenithCommissionsIntegrated varchar(200)
DECLARE @backupLocationZenithIntegrated varchar(200)

/*OrkinCanada Prod Data Set*/
SET @backupLocationServSuiteData = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteDataCopyOnly.bak'
SET @backupLocationServSuiteLog = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteLogCopyOnly.bak'
SET @backupLocationServSuiteWBProgram = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteWBProgramCopyOnly.bak'
SET @backupLocationServSuiteWBReport = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteWBReportCopyOnly.bak'
SET @backupLocationServSuiteWBUser = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteWBUserCopyOnly.bak'
SET @backupLocationZenithCommissionsIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ZenithCommissionsIntegratedCopyOnly.bak'
SET @backupLocationZenithIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ZenithIntegratedCopyOnly.bak'

--/*Reduced Backup Set*/
--SET @backupLocationServSuiteData = N'\\owssdredo201\DBReduce\DBReduceServSuiteData.bak'
--SET @backupLocationServSuiteLog = N'\\owssdredo201\DBReduce\DBReduceServSuiteLog.bak'
--SET @backupLocationServSuiteWBProgram = N'\\owssdredo201\DBReduce\DBReduceServSuiteWBProgram.bak'
--SET @backupLocationServSuiteWBReport = N'\\owssdredo201\DBReduce\DBReduceServSuiteWBReport.bak'
--SET @backupLocationServSuiteWBUser = N'\\owssdredo201\DBReduce\DBReduceServSuiteWBUser.bak'
--SET @backupLocationZenithCommissionsIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201_ZenithCommissionsIntegrated.full.bak'
--SET @backupLocationZenithIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201_ZenithIntegrated.full.bak'

--========================================================================================================================================================
--BEFORE script
--Author: Carl Florin
--Created on: 3/9/2012
--last changed on: 3/9/2012
--Description: This script must be run BEFORE a database is restored or otherwise over-written, it saves all 4 login tables to a temp location on OWSSCDDBO201.
--This script must be run in conjunction with Restore_logins_run_after, which restores the logins from the temp location after restore is complete.
--Modified on:12/17/2012 
--Mofified Purpose:	To reflect the new location for the "loginrolrestoretest" database.  I also added a section at the bottom to capture information for the 
--training environment on OWSSTRDBO201.
--========================================================================================================================================================
PRINT '';
PRINT '';
PRINT 'Before Scripts';
PRINT GETDATE();

DECLARE @logincompanyTable varchar(200)
DECLARE @logincompanybranchTable varchar(200)
DECLARE @logincurrentcompanyTable varchar(200)
DECLARE @loginroleTable varchar(200)
DECLARE @tlogintable varchar(200)
DECLARE @tdatabasetable varchar(200)
DECLARE @thocreportstable varchar(200)

USE ServSuiteData;
SET @logincompanyTable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogincompany')
SET @logincompanybranchTable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogincompanybranch')
SET @logincurrentcompanyTable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogincurrentcompany')
SET @loginroletable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tloginrole')
SET @thocreportstable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'thocreports')

USE ServSuiteWBUser;
SET @tlogintable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogin')
SET @tdatabasetable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tdatabase')

PRINT '';
PRINT '';
PRINT @logincompanyTable;
PRINT GETDATE();
USE ServSuiteData;
EXEC(N'DELETE FROM ' +@logincompanyTable);
EXEC(N'INSERT INTO ' + @logincompanyTable + ' ([loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby],[createdby])
	SELECT [loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby],[createdby]
	FROM [tlogincompany]');

PRINT '';
PRINT '';
PRINT @logincompanybranchTable;
PRINT GETDATE();
USE ServSuiteData;
EXEC(N'DELETE FROM ' + @logincompanybranchTable);
EXEC(N'INSERT INTO ' + @logincompanybranchTable + ' ([loginbranchid],[companyid],[branchid],[loginid],[utctimestamp],[utclastchanged],[lastchangedby])
	SELECT [loginbranchid],[companyid],[branchid],[loginid],[utctimestamp],[utclastchanged],[lastchangedby]
	FROM [tlogincompanybranch]');

PRINT '';
PRINT '';
PRINT @logincurrentcompanyTable;
PRINT GETDATE();
USE ServSuiteData;
EXEC(N'DELETE FROM ' + @logincurrentcompanyTable);
EXEC(N'INSERT INTO ' + @logincurrentcompanyTable + ' ([loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby])
	SELECT [loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby]
	FROM [tlogincurrentcompany]');

PRINT '';
PRINT '';
PRINT @loginroletable;
PRINT GETDATE();
USE ServSuiteData;
EXEC(N'DELETE FROM ' + @loginroletable); 
EXEC(N'INSERT INTO ' + @loginroletable + ' ([loginid],[roleid],[utctimestamp],[createdby],[utclastchanged],[lastchangedby],[loginstart],
											[loginend],[loginsun],[loginmon],[logintue],[loginwed],[loginthu],[loginfri],[loginsat],[loginmobile],
											[issupportuser],[canlogout],[isservsaleuser],[servsaleroleid],[companyid],[ismobileuser],[mobileroleid])
	SELECT [loginid],[roleid],[utctimestamp],[createdby],[utclastchanged],[lastchangedby],[loginstart],
		   [loginend],[loginsun],[loginmon],[logintue],[loginwed],[loginthu],[loginfri],[loginsat],[loginmobile],
		   [issupportuser],[canlogout],[isservsaleuser],[servsaleroleid],[companyid],[ismobileuser],[mobileroleid]
	FROM [tloginrole]');

PRINT '';
PRINT '';
PRINT @thocreportstable;
PRINT GETDATE();
USE ServSuiteData;
EXEC(N'DELETE FROM ' + @thocreportstable);
EXEC(N'INSERT INTO ' + @thocreportstable + '([reportid],[reportname],[reportitempath],[subscriptionid],[daytorunafterhoc],[renderformat],[commandtext],[matchdata],[parameters],[fieldlist]
           ,[utclastchanged],[lastchangedby],[scheduledtime],[nextrun],[timeout],[istimeoutinitialized],[isfilenamechanged],[emailreport])
	SELECT [reportid],[reportname],[reportitempath],[subscriptionid],[daytorunafterhoc],[renderformat],[commandtext],[matchdata],[parameters],[fieldlist]
           ,[utclastchanged],[lastchangedby],[scheduledtime],[nextrun],[timeout],[istimeoutinitialized],[isfilenamechanged],[emailreport]
	FROM [thocreports]');

PRINT '';
PRINT '';
PRINT @tlogintable;
PRINT GETDATE();
USE ServSuiteWBUser;
EXEC(N'DELETE FROM ' + @tlogintable);
EXEC(N'INSERT INTO ' + @tlogintable + ' ([orgid],[loginid],[logindescription],[isactive],[loginuid],[loginpwd],[databaseid],[lcid],[languageid],
										 [role],[accountid],[utcoffset],[utctimestamp],[utclastchanged],[lastchangedby],[loginpwdexpires],[usedst],
										 [useralias],[usertype],[adusername],[syncrouteid],[syncemployeeid],[ismobileuser],[mobileroleid],[isservsaleuser],
										 [servsaleroleid],[glympseagentid])
	SELECT [orgid],[loginid],[logindescription],[isactive],[loginuid],[loginpwd],[databaseid],[lcid],[languageid],
		   [role],[accountid],[utcoffset],[utctimestamp],[utclastchanged],[lastchangedby],[loginpwdexpires],[usedst],
		   [useralias],[usertype],[adusername],[syncrouteid],[syncemployeeid],[ismobileuser],[mobileroleid],[isservsaleuser],
		   [servsaleroleid],[glympseagentid]
	FROM [tlogin]');

PRINT '';
PRINT '';
PRINT @tdatabasetable;
PRINT GETDATE();
USE ServSuiteWBUser;
EXEC(N'DELETE FROM ' + @tdatabasetable); 
EXEC(N'INSERT INTO ' + @tdatabasetable + ' ([databaseid],[dbtype],[programserver],[programserverssl],[programdb],[dataserver],[dataserverssl],[datadb],
											[logserver],[logserverssl],[logserverinternal],[logserverinternalssl],[logdb],[helpserver],[helpserverssl],
											[helpdb],[userid],[pwd],[available],[netlib],[prgpwd],[prguid],[useaddressval],[addressvalloc],[allowcwp],
											[allownextel],[allowsqllog],[dbversion],[checkload],[singlefilelimit],[totalfilelimit],[sentriconversion],
											[backupdataserver],[backuplogserver],[backupuserid],[backuppwd],[redirect],[registeredusers],[masteracctsvcexternal],
											[masteracctsvcaddress],[apiurl],[replicateserver],[replicatedata],[replicateuserid],[replicatepwd])
	SELECT [databaseid],[dbtype],[programserver],[programserverssl],[programdb],[dataserver],[dataserverssl],[datadb],
		   [logserver],[logserverssl],[logserverinternal],[logserverinternalssl],[logdb],[helpserver],[helpserverssl],
		   [helpdb],[userid],[pwd],[available],[netlib],[prgpwd],[prguid],[useaddressval],[addressvalloc],[allowcwp],
		   [allownextel],[allowsqllog],[dbversion],[checkload],[singlefilelimit],[totalfilelimit],[sentriconversion],
		   [backupdataserver],[backuplogserver],[backupuserid],[backuppwd],[redirect],[registeredusers],[masteracctsvcexternal],
		   [masteracctsvcaddress],[apiurl],[replicateserver],[replicatedata],[replicateuserid],[replicatepwd]
	FROM [tdatabase]');

/******************************************************************************************************************************/
/******************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Restore Integrated Test Databases on OWSSTDBAGO204';
PRINT GETDATE();

/* Execute the Database Refreshes as user 'SA'. This will ensure the database owner as 'sa'.  */

/*ServSuiteData*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteData';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ServSuiteData] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteData] 
FROM  DISK = @backupLocationServSuiteData 
WITH  FILE = 1
, MOVE 'Template_Data_Data' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData.mdf'
, MOVE 'Template_Data_Data2' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData2.ndf'
, MOVE 'Template_Data_Data3' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData3.ndf'
, MOVE 'Template_Data_Data4' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData4.ndf'
, MOVE 'Template_Data_Data5' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData5.ndf'
, MOVE 'Template_Data_Data6' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData6.ndf'
, MOVE 'Template_Data_Data7' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData7.ndf'
, MOVE 'Template_Data_Data8' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData8.ndf'
, MOVE 'Template_Data_Data9' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData9.ndf'
, MOVE 'Template_Data_Data10' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData10.ndf'
, MOVE 'Template_Data_Log' TO 'C:\SQLMounts\Logs1\SQLLogs1\ServSuiteData\ServSuiteData_log.ldf'
,  REPLACE
,  NOUNLOAD
,  NORECOVERY
,  STATS = 5;
PRINT 'Restored ServSuiteData';

/*ServSuiteLog*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteLog';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ServSuiteLog] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteLog] 
FROM  DISK =  @backupLocationServSuiteLog
WITH  FILE = 1
, MOVE 'Template_Log_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteLog\ServSuiteLog.mdf'
, MOVE 'Template_Log_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteLog\ServSuiteLog.ldf'
,  REPLACE
,  NOUNLOAD
,  NORECOVERY
,  STATS = 5;
PRINT 'Restored ServSuiteLog';

/*ServSuiteWBProgram*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteWBProgram';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ServSuiteWBProgram] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteWBProgram] 
FROM  DISK = @backupLocationServSuiteWBProgram
WITH  FILE = 1
, MOVE 'TSP_WB_Program_DB_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteWBProgram\ServSuiteWBProgram.mdf'
, MOVE 'TSP_WB_Program_DB_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteWBProgram\ServSuiteWBProgram.ldf'
,  REPLACE
,  NOUNLOAD
,  NORECOVERY
,  STATS = 5;
PRINT 'Restored ServSuiteWBProgram';

/*ServSuiteWBReport*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteWBReport';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ServSuiteWBReport] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteWBReport] 
FROM  DISK = @backupLocationServSuiteWBReport
WITH  FILE = 1
, MOVE 'TSP_WB_Report_New_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteWBReport\ServSuiteWBReport.mdf'
, MOVE 'TSP_WB_Report_New_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteWBReport\ServSuiteWBReport.ldf'
,  REPLACE
,  NOUNLOAD
,  NORECOVERY
,  STATS = 5;
PRINT 'Restored ServSuiteWBReport';

/*ServSuiteWBUser*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteWBUser';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ServSuiteWBUser] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteWBUser] 
FROM  DISK = @backupLocationServSuiteWBUser
WITH  FILE = 1
, MOVE 'TSP_WB_User_DB_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteWBUser\ServSuiteWBUser.mdf'
, MOVE 'TSP_WB_User_DB_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteWBUser\ServSuiteWBUser.ldf'
,  REPLACE
,  NOUNLOAD
,  NORECOVERY
,  STATS = 5;
PRINT 'Restored ServSuiteWBUser';

/*ZenithCommissionsIntegrated*/
PRINT '';
PRINT '';
PRINT 'Restoring ZenithCommissionsIntegrated';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ZenithCommissionsIntegrated] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ZenithCommissionsIntegrated] 
FROM  DISK = @backupLocationZenithCommissionsIntegrated
WITH  FILE = 1
, MOVE 'ZenithCommissionsIntegrated' TO 'C:\SQLMounts\Data2\SQLData1\ZenithCommissionsIntegrated\ZenithCommissionsIntegrated.mdf'
, MOVE 'ZenithCommissionsIntegrated_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ZenithCommissionsIntegrated\ZenithCommissionsIntegrated.ldf'
,  REPLACE
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ZenithCommissionsIntegrated';

/*ZenithIntegrated*/
PRINT '';
PRINT '';
PRINT 'Restoring ZenithIntegrated';
PRINT GETDATE();
USE [master];
ALTER DATABASE [ZenithIntegrated] SET RESTRICTED_USER WITH ROLLBACK IMMEDIATE;
EXECUTE AS login='sa'
RESTORE DATABASE [ZenithIntegrated] 
FROM  DISK = @backupLocationZenithIntegrated
WITH  FILE = 1
, MOVE 'ZenithIntegrated' TO 'C:\SQLMounts\Data2\SQLData1\ZenithIntegrated\ZenithIntegrated.mdf'
, MOVE 'ZenithIntegrated_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ZenithIntegrated\ZenithIntegrated.ldf'
,  REPLACE
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ZenithIntegrated';

GO
/******************************************************************************************************************************/
/******************************************************************************************************************************/

/* Replica1 SQL Server Database Refresh - NORECOVERY */
   
:Connect OWSSDDBO248

PRINT 'Connected to OWSSDDBO248';
PRINT GETDATE();
PRINT '';

/**************************************************************************************************************************/
/*
--Added 3/9/2017 by Ben Shearouse
--This cleans up RollinsBackgroundJobs database so that refreshes don't fail
--due to lack of storage.
--Needs to run everywhere there is an RBJ database: Live, Replica1 and Replica2.
*/

PRINT '';
PRINT '';
PRINT 'Clean out and shrink RollinsBackgroundJobs database.';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
TRUNCATE TABLE ssmobile.mobileq1;
TRUNCATE TABLE ssmobile.mobileq2;
TRUNCATE TABLE ssmobile.mobileq3;
TRUNCATE TABLE BIFEEDQueue_A;
TRUNCATE TABLE BIFEEDQueue_B;

USE [RollinsBackgroundJobs];
DBCC SHRINKFILE (N'RollinsBackgroundJobs' , 50000);
DBCC SHRINKFILE (N'RollinsBackgroundJobs_log' , 2048);
WAITFOR DELAY '00:01';  /*wait 1 minute*/
DBCC SHRINKFILE (N'RollinsBackgroundJobs_log' , 2048);

/**************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Replica1 SQL Server Database Refresh on OWSSDDBO248';
PRINT GETDATE();

/**************************************************************/
/*Make sure to set the backup location to the correct backups.*/
/**************************************************************/
DECLARE @backupLocationServSuiteData varchar(200)
DECLARE @backupLocationServSuiteLog varchar(200)
DECLARE @backupLocationServSuiteWBProgram varchar(200)
DECLARE @backupLocationServSuiteWBReport varchar(200)
DECLARE @backupLocationServSuiteWBUser varchar(200)
DECLARE @backupLocationZenithCommissionsIntegrated varchar(200)
DECLARE @backupLocationZenithIntegrated varchar(200)

/*OrkinCanada Prod Data Set*/
SET @backupLocationServSuiteData = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteDataCopyOnly.bak'
SET @backupLocationServSuiteLog = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteLogCopyOnly.bak'
SET @backupLocationServSuiteWBProgram = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteWBProgramCopyOnly.bak'
SET @backupLocationServSuiteWBReport = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteWBReportCopyOnly.bak'
SET @backupLocationServSuiteWBUser = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ServSuiteWBUserCopyOnly.bak'
SET @backupLocationZenithCommissionsIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ZenithCommissionsIntegratedCopyOnly.bak'
SET @backupLocationZenithIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201ZenithIntegratedCopyOnly.bak'

--/*Reduced Backup Set*/
--SET @backupLocationServSuiteData = N'\\owssdredo201\DBReduce\DBReduceServSuiteData.bak'
--SET @backupLocationServSuiteLog = N'\\owssdredo201\DBReduce\DBReduceServSuiteLog.bak'
--SET @backupLocationServSuiteWBProgram = N'\\owssdredo201\DBReduce\DBReduceServSuiteWBProgram.bak'
--SET @backupLocationServSuiteWBReport = N'\\owssdredo201\DBReduce\DBReduceServSuiteWBReport.bak'
--SET @backupLocationServSuiteWBUser = N'\\owssdredo201\DBReduce\DBReduceServSuiteWBUser.bak'
--SET @backupLocationZenithCommissionsIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201_ZenithCommissionsIntegrated.full.bak'
--SET @backupLocationZenithIntegrated = N'\\rwfilesvro202.rollins.local\OrkinCanada_BOSS_Full\RWBCDBAGH201_ZenithIntegrated.full.bak'

/* Execute the Database Refreshes as user 'SA'. This will ensure the database owner as 'sa'.  */

/*ServSuiteData*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteData';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteData] 
FROM  DISK = @backupLocationServSuiteData 
WITH  FILE = 1
, REPLACE
, MOVE 'Template_Data_Data' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData.mdf'
, MOVE 'Template_Data_Data2' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData2.ndf'
, MOVE 'Template_Data_Data3' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData3.ndf'
, MOVE 'Template_Data_Data4' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData4.ndf'
, MOVE 'Template_Data_Data5' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData5.ndf'
, MOVE 'Template_Data_Data6' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData6.ndf'
, MOVE 'Template_Data_Data7' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData7.ndf'
, MOVE 'Template_Data_Data8' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData8.ndf'
, MOVE 'Template_Data_Data9' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData9.ndf'
, MOVE 'Template_Data_Data10' TO 'C:\SQLMounts\Data1\SQLData1\ServSuiteData\ServSuiteData10.ndf'
, MOVE 'Template_Data_Log' TO 'C:\SQLMounts\Logs1\SQLLogs1\ServSuiteData\ServSuiteData_log.ldf'
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ServSuiteData';

/***********************************************************************************************/
/*ServSuiteLog*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteLog';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteLog] 
FROM  DISK =  @backupLocationServSuiteLog 
WITH  FILE = 1
, REPLACE
, MOVE 'Template_Log_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteLog\ServSuiteLog.mdf'
, MOVE 'Template_Log_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteLog\ServSuiteLog.ldf'
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ServSuiteLog';

/***********************************************************************************************/
/*ServSuiteWBProgram*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteWBProgram';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteWBProgram] 
FROM  DISK = @backupLocationServSuiteWBProgram 
WITH  FILE = 1
, REPLACE
, MOVE 'TSP_WB_Program_DB_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteWBProgram\ServSuiteWBProgram.mdf'
, MOVE 'TSP_WB_Program_DB_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteWBProgram\ServSuiteWBProgram.ldf'
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ServSuiteWBProgram ';

/***********************************************************************************************/
/*ServSuiteWBReport*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteWBReport';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteWBReport] 
FROM  DISK = @backupLocationServSuiteWBReport 
WITH  FILE = 1
, REPLACE
, MOVE 'TSP_WB_Report_New_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteWBReport\ServSuiteWBReport.mdf'
, MOVE 'TSP_WB_Report_New_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteWBReport\ServSuiteWBReport.ldf'
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ServSuiteWBReport';

/***********************************************************************************************/
/*ServSuiteWBUser*/
PRINT '';
PRINT '';
PRINT 'Restoring ServSuiteWBUser';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ServSuiteWBUser] 
FROM  DISK = @backupLocationServSuiteWBUser
WITH  FILE = 1
, REPLACE
, MOVE 'TSP_WB_User_DB_Data' TO 'C:\SQLMounts\Data2\SQLData1\ServSuiteWBUser\ServSuiteWBUser.mdf'
, MOVE 'TSP_WB_User_DB_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ServSuiteWBUser\ServSuiteWBUser.ldf'
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ServSuiteWBUser';

/*ZenithCommissionsIntegrated*/
PRINT '';
PRINT '';
PRINT 'Restoring ZenithCommissionsIntegrated';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ZenithCommissionsIntegrated] 
FROM  DISK = @backupLocationZenithCommissionsIntegrated
WITH  FILE = 1
, MOVE 'ZenithCommissionsIntegrated' TO 'C:\SQLMounts\Data2\SQLData1\ZenithCommissionsIntegrated\ZenithCommissionsIntegrated.mdf'
, MOVE 'ZenithCommissionsIntegrated_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ZenithCommissionsIntegrated\ZenithCommissionsIntegrated.ldf'
,  REPLACE
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ZenithCommissionsIntegrated';

/*ZenithIntegrated*/
PRINT '';
PRINT '';
PRINT 'Restoring ZenithIntegrated';
PRINT GETDATE();
USE [master];
EXECUTE AS login='sa'
RESTORE DATABASE [ZenithIntegrated] 
FROM  DISK = @backupLocationZenithIntegrated
WITH  FILE = 1
, MOVE 'ZenithIntegrated' TO 'C:\SQLMounts\Data2\SQLData1\ZenithIntegrated\ZenithIntegrated.mdf'
, MOVE 'ZenithIntegrated_Log' TO 'C:\SQLMounts\Logs2\SQLLogs1\ZenithIntegrated\ZenithIntegrated.ldf'
,  REPLACE
,  NOUNLOAD
,  STATS = 5
,  NORECOVERY;
PRINT 'Restored ZenithIntegrated';
GO

/*********************************************************************************************************/
/*********************************************************************************************************/
:Connect OWSSTDBAGO204

PRINT 'Connected to OWSSTDBAGO204';
PRINT GETDATE();
PRINT '';

PRINT 'Recover Live databases on OWSSTDBAGO204';
PRINT GETDATE();
PRINT '';

/*ServSuiteData*/
PRINT '';
PRINT '';
PRINT 'Recovering ServSuiteData';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ServSuiteData] 
WITH  RECOVERY;
PRINT 'Recovered ServSuiteData';

/*ServSuiteLog*/
PRINT '';
PRINT '';
PRINT 'Recovering ServSuiteLog';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ServSuiteLog]
WITH RECOVERY;
PRINT 'Recovered ServSuiteLog';

/*ServSuiteWBProgram*/
PRINT '';
PRINT '';
PRINT 'Recovering ServSuiteWBProgram';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ServSuiteWBProgram] 
WITH  RECOVERY;
PRINT 'Recovered ServSuiteWBProgram';

/*ServSuiteWBReport*/
PRINT '';
PRINT '';
PRINT 'Recovering ServSuiteWBReport';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ServSuiteWBReport] 
WITH  RECOVERY;
PRINT 'Recovered ServSuiteWBReport';

/*ServSuiteWBUser*/
PRINT '';
PRINT '';
PRINT 'Recovering ServSuiteWBUser';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ServSuiteWBUser] 
WITH  RECOVERY;
PRINT 'Recovered ServSuiteWBUser';

/*ZenithCommissionsIntegrated*/
PRINT '';
PRINT '';
PRINT 'Recovering ZenithCommissionsIntegrated';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ZenithCommissionsIntegrated] 
WITH  RECOVERY;
PRINT 'Recovered ZenithCommissionsIntegrated';

/*ZenithIntegrated*/
PRINT '';
PRINT '';
PRINT 'Recovering ZenithIntegrated';
PRINT GETDATE();
USE [master];
RESTORE DATABASE [ZenithIntegrated] 
WITH  RECOVERY;
PRINT 'Recovered ZenithIntegrated';

/*********************************************************************************************************/
PRINT 'Add databases to Availability Group BOSS_AG1';
PRINT GETDATE();
PRINT '';

USE [master];

PRINT 'Added ServSuiteData to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ServSuiteData];

PRINT 'Added ServSuiteLog to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ServSuiteLog];

PRINT 'Added ServSuiteWBProgram to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ServSuiteWBProgram];

PRINT 'Added ServSuiteWBReport to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ServSuiteWBReport];

PRINT 'Added ServSuiteWBUser to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ServSuiteWBUser];

PRINT 'Added ZenithCommissionsIntegrated to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ZenithCommissionsIntegrated];

PRINT 'Added ZenithIntegrated to BOSS_AG1';
ALTER AVAILABILITY GROUP [BOSS_AG1]
ADD DATABASE [ZenithIntegrated];
GO

/*********************************************************************************************************/
/*********************************************************************************************************/
/*********************************************************************************************************/
:Connect OWSSDDBO248

USE [master];
PRINT 'Connected to OWSSDDBO248';
PRINT GETDATE();
PRINT '';

PRINT 'Join AlwaysOn databases to BOSS_AG1 on OWSSDDBO248';
PRINT GETDATE();
PRINT '';

USE [master];
/**************************************************************/
PRINT 'Joining ServSuiteData to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ServSuiteData] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ServSuiteData to BOSS_AG1';
PRINT GETDATE();
GO

USE [master];
/**************************************************************/
PRINT 'Joining ServSuiteLog to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ServSuiteLog] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ServSuiteLog to BOSS_AG1';
PRINT GETDATE();
GO

USE [master];
/**************************************************************/
PRINT 'Joining ServSuiteWBProgram to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ServSuiteWBProgram] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ServSuiteWBProgram to BOSS_AG1';
PRINT GETDATE();
GO

USE [master];
/**************************************************************/
PRINT 'Joining ServSuiteWBReport to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ServSuiteWBReport] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ServSuiteWBReport to BOSS_AG1';
PRINT GETDATE();
GO

USE [master];
/**************************************************************/
PRINT 'Joining ServSuiteWBUser to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ServSuiteWBUser] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ServSuiteWBUser to BOSS_AG1';
PRINT GETDATE();
GO

USE [master];
/**************************************************************/
PRINT 'Joining ZenithCommissionsIntegrated to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ZenithCommissionsIntegrated] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ZenithCommissionsIntegrated to BOSS_AG1';
PRINT GETDATE();
GO

USE [master];
/**************************************************************/
PRINT 'Joining ZenithIntegrated to BOSS_AG1';
PRINT GETDATE();
-- Wait for the replica to start communicating
begin try
declare @conn bit
declare @count int
declare @replica_id uniqueidentifier 
declare @group_id uniqueidentifier
set @conn = 0
set @count = 30 -- wait for 5 minutes 

if (serverproperty('IsHadrEnabled') = 1)
	and (isnull((select member_state from master.sys.dm_hadr_cluster_members where upper(member_name COLLATE Latin1_General_CI_AS) = upper(cast(serverproperty('ComputerNamePhysicalNetBIOS') as nvarchar(256)) COLLATE Latin1_General_CI_AS)), 0) <> 0)
	and (isnull((select state from master.sys.database_mirroring_endpoints), 1) = 0)
begin
    select @group_id = ags.group_id from master.sys.availability_groups as ags where name = N'BOSS_AG1'
	select @replica_id = replicas.replica_id from master.sys.availability_replicas as replicas where upper(replicas.replica_server_name COLLATE Latin1_General_CI_AS) = upper(@@SERVERNAME COLLATE Latin1_General_CI_AS) and group_id = @group_id
	while @conn <> 1 and @count > 0
	begin
		set @conn = isnull((select connected_state from master.sys.dm_hadr_availability_replica_states as states where states.replica_id = @replica_id), 1)
		if @conn = 1
		begin
			-- exit loop when the replica is connected, or if the query cannot find the replica status
			break
		end
		waitfor delay '00:00:10'
		set @count = @count - 1
	end
end
end try
begin catch
	-- If the wait loop fails, do not stop execution of the alter database statement
end catch
ALTER DATABASE [ZenithIntegrated] SET HADR AVAILABILITY GROUP = [BOSS_AG1];
PRINT 'Joined ZenithIntegrated to BOSS_AG1';
PRINT GETDATE();
GO

/*********************************************************************************************************/
/*********************************************************************************************************/
/*********************************************************************************************************/

:Connect OWSSTDBAGO204

PRINT 'Connected to OWSSTDBAGO204';
PRINT GETDATE();
PRINT '';


/*********************************************************************************************************/
/*********************************************************************************************************/
PRINT '';
PRINT 'Disable All Triggers on databases.';
PRINT '';
PRINT GETDATE();

USE [ServSuiteData];
exec sp_MSforeachtable "ALTER TABLE ? DISABLE TRIGGER ALL";
PRINT 'Disabled All Triggers on ServSuiteData.';

USE [ServSuiteLog];
exec sp_MSforeachtable "ALTER TABLE ? DISABLE TRIGGER ALL";
PRINT 'Disabled All Triggers on ServSuiteLog.';

USE [ServSuiteWBProgram];
exec sp_MSforeachtable "ALTER TABLE ? DISABLE TRIGGER ALL";
PRINT 'Disabled All Triggers on ServSuiteWBProgram.';

USE [ServSuiteWBReport];
exec sp_MSforeachtable "ALTER TABLE ? DISABLE TRIGGER ALL";
PRINT 'Disabled All Triggers on ServSuiteWBReport.';

USE [ServSuiteWBUser];
exec sp_MSforeachtable "ALTER TABLE ? DISABLE TRIGGER ALL";
PRINT 'Disabled All Triggers on ServSuiteWBUser.';

/************************************************************************************************************************************/
/******************************************************************************************************************************/
--========================================================================================================================================================
--AFTER Script
--Author: Carl Florin
--Created on: 3/9/2012
--last changed on: 3/9/2012
--Description: This script must be run AFTER a database is restored or otherwise over-written, it loads all 4 login tables from a temp location on rolatl.
--This script must be run in conjunction with Restore_logins_run_before, which saves the logins to the temp location before restore is done.
--Modified on:12/17/2012 
--Mofified Purpose:	To reflect the new location for the "loginrolrestoretest" database.  I also added a section at the bottom to capture information for the 
--training environment on OWSSTRDBO201.
--========================================================================================================================================================
PRINT '';
PRINT '';
PRINT 'After Scripts';
PRINT GETDATE();

DECLARE @logincompanyTable varchar(200)
DECLARE @logincompanybranchTable varchar(200)
DECLARE @logincurrentcompanyTable varchar(200)
DECLARE @loginroleTable varchar(200)
DECLARE @tlogintable varchar(200)
DECLARE @tdatabasetable varchar(200)
DECLARE @thocreportstable varchar(200)

USE ServSuiteData;
SET @logincompanyTable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogincompany')
SET @logincompanybranchTable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogincompanybranch')
SET @logincurrentcompanyTable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogincurrentcompany')
SET @loginroletable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tloginrole')
SET @thocreportstable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'thocreports')

USE ServSuiteWBUser;
SET @tlogintable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tlogin')
SET @tdatabasetable = (select 'OWSSCDDBO201.loginrolerestoretest.dbo.' + @@servername + DB_NAME() + 'tdatabase')

PRINT '';
PRINT '';
PRINT @logincompanyTable;
PRINT GETDATE();
USE ServSuiteData;
TRUNCATE TABLE tlogincompany;
EXEC(N'INSERT INTO [tlogincompany] ([loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby],[createdby])
	SELECT [loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby],[createdby]
	FROM ' + @logincompanyTable);

PRINT '';
PRINT '';
PRINT @logincompanybranchTable;
PRINT GETDATE();
USE ServSuiteData;
TRUNCATE TABLE tlogincompanybranch;
SET IDENTITY_INSERT tlogincompanybranch ON;
EXEC(N'INSERT INTO [tlogincompanybranch]  ([loginbranchid],[companyid],[branchid],[loginid],[utctimestamp],[utclastchanged],[lastchangedby])
SELECT [loginbranchid],[companyid],[branchid],[loginid],[utctimestamp],[utclastchanged],[lastchangedby]
FROM ' + @logincompanybranchTable );
SET IDENTITY_INSERT tlogincompanybranch OFF;

PRINT '';
PRINT '';
PRINT @logincurrentcompanyTable;
PRINT GETDATE();
USE ServSuiteData;
TRUNCATE TABLE tlogincurrentcompany;
EXEC(N'INSERT INTO tlogincurrentcompany ([loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby])
SELECT [loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby]
FROM ' + @logincurrentcompanyTable);

PRINT '';
PRINT '';
PRINT @loginroletable;
PRINT GETDATE();
USE ServSuiteData;
TRUNCATE TABLE tloginrole;
EXEC(N'INSERT INTO tloginrole ([loginid],[roleid],[utctimestamp],[createdby],[utclastchanged],[lastchangedby],[loginstart],
							   [loginend],[loginsun],[loginmon],[logintue],[loginwed],[loginthu],[loginfri],[loginsat],[loginmobile],
							   [issupportuser],[canlogout],[isservsaleuser],[servsaleroleid],[companyid],[ismobileuser],[mobileroleid])
SELECT  [loginid],[roleid],[utctimestamp],[createdby],[utclastchanged],[lastchangedby],[loginstart],
		[loginend],[loginsun],[loginmon],[logintue],[loginwed],[loginthu],[loginfri],[loginsat],[loginmobile],
		[issupportuser],[canlogout],[isservsaleuser],[servsaleroleid],[companyid],[ismobileuser],[mobileroleid]
FROM ' + @loginroletable );

PRINT '';
PRINT '';
PRINT @thocreportstable;
PRINT GETDATE();
USE ServSuiteData;
TRUNCATE TABLE thocreports;
EXEC(N'INSERT INTO thocreports ([reportid],[reportname],[reportitempath],[subscriptionid],[daytorunafterhoc],[renderformat],[commandtext]
			,[matchdata],[parameters],[fieldlist],[utclastchanged],[lastchangedby],[scheduledtime],[nextrun],[timeout]
			,[istimeoutinitialized],[isfilenamechanged],[emailreport])
SELECT  [reportid],[reportname],[reportitempath],[subscriptionid],[daytorunafterhoc],[renderformat],[commandtext],[matchdata],[parameters],[fieldlist]
        ,[utclastchanged],[lastchangedby],[scheduledtime],[nextrun],[timeout],[istimeoutinitialized],[isfilenamechanged],[emailreport]
FROM ' + @thocreportstable );

PRINT '';
PRINT '';
PRINT @tlogintable;
PRINT GETDATE();
USE ServSuiteWBUser;
TRUNCATE TABLE tlogin;
SET IDENTITY_INSERT tlogin ON;
EXEC(N'INSERT INTO tlogin ([orgid],[loginid],[logindescription],[isactive],[loginuid],[loginpwd],[databaseid],[lcid],[languageid],
						   [role],[accountid],[utcoffset],[utctimestamp],[utclastchanged],[lastchangedby],[loginpwdexpires],[usedst],
						   [useralias],[usertype],[adusername],[syncrouteid],[syncemployeeid],[ismobileuser],[mobileroleid],[isservsaleuser],
						   [servsaleroleid],[glympseagentid])
SELECT [orgid],[loginid],[logindescription],[isactive],[loginuid],[loginpwd],[databaseid],[lcid],[languageid],
	   [role],[accountid],[utcoffset],[utctimestamp],[utclastchanged],[lastchangedby],[loginpwdexpires],[usedst],
	   [useralias],[usertype],[adusername],[syncrouteid],[syncemployeeid],[ismobileuser],[mobileroleid],[isservsaleuser],
	   [servsaleroleid],[glympseagentid]
FROM ' + @tlogintable );
SET IDENTITY_INSERT tlogin OFF;

PRINT '';
PRINT '';
PRINT @tdatabasetable;
PRINT GETDATE();
USE ServSuiteWBUser;
TRUNCATE TABLE tdatabase;
SET IDENTITY_INSERT tdatabase ON;
EXEC(N'INSERT INTO tdatabase ([databaseid],[dbtype],[programserver],[programserverssl],[programdb],[dataserver],[dataserverssl],[datadb],
							  [logserver],[logserverssl],[logserverinternal],[logserverinternalssl],[logdb],[helpserver],[helpserverssl],
							  [helpdb],[userid],[pwd],[available],[netlib],[prgpwd],[prguid],[useaddressval],[addressvalloc],[allowcwp],
							  [allownextel],[allowsqllog],[dbversion],[checkload],[singlefilelimit],[totalfilelimit],[sentriconversion],
							  [backupdataserver],[backuplogserver],[backupuserid],[backuppwd],[redirect],[registeredusers],[masteracctsvcexternal],
							  [masteracctsvcaddress],[apiurl],[replicateserver],[replicatedata],[replicateuserid],[replicatepwd])
SELECT [databaseid],[dbtype],[programserver],[programserverssl],[programdb],[dataserver],[dataserverssl],[datadb],
	   [logserver],[logserverssl],[logserverinternal],[logserverinternalssl],[logdb],[helpserver],[helpserverssl],
	   [helpdb],[userid],[pwd],[available],[netlib],[prgpwd],[prguid],[useaddressval],[addressvalloc],[allowcwp],
	   [allownextel],[allowsqllog],[dbversion],[checkload],[singlefilelimit],[totalfilelimit],[sentriconversion],
	   [backupdataserver],[backuplogserver],[backupuserid],[backuppwd],[redirect],[registeredusers],[masteracctsvcexternal],
	   [masteracctsvcaddress],[apiurl],[replicateserver],[replicatedata],[replicateuserid],[replicatepwd]
FROM ' + @tdatabasetable );
SET IDENTITY_INSERT tdatabase OFF;

/******************************************************************************************************************************/

/******************************************************************************************************************************/
/*Drop Production Users from Databases*/
/******************************************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Drop Production Users from Databases';
PRINT GETDATE();

USE ServSuiteData;
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];

USE ServSuiteLog;
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];

USE ServSuiteWBProgram;
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];

USE ServSuiteWBReport;
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];


USE ServSuiteWBUser;
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];

USE [ZenithCommissionsIntegrated];
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];

USE [ZenithIntegrated];
IF EXISTS (select * from sys.sysusers where name = 'cn_oclpdatauser') DROP USER [cn_oclpdatauser];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteapp') DROP USER [cn_servsuiteapp];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteCWR') DROP USER [cn_servsuiteCWR];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitedeploy') DROP USER [cn_servsuitedeploy];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteJDE') DROP USER [cn_servsuiteJDE];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuitePI') DROP USER [cn_servsuitePI];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteSVC') DROP USER [cn_servsuiteSVC];
IF EXISTS (select * from sys.sysusers where name = 'cn_servsuiteVRM') DROP USER [cn_servsuiteVRM];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod DBO') DROP USER [ROLLINS\CN Servsuite Orkin Prod DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\CN Servsuite Orkin Prod Read Only') DROP USER [ROLLINS\CN Servsuite Orkin Prod Read Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\InfAUsr1') DROP USER [ROLLINS\InfAUsr1];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Conv DBO') DROP USER [ROLLINS\ServSuite Orkin Conv DBO];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\ServSuite Orkin Prod View-Only') DROP USER [ROLLINS\ServSuite Orkin Prod View-Only];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnBOSSDeployProd') DROP USER [ROLLINS\SVC_cnBOSSDeployProd];
IF EXISTS (select * from sys.sysusers where name = 'ROLLINS\SVC_cnssprdsvc') DROP USER [ROLLINS\SVC_cnssprdsvc];

/******************************************************************************************************************************/
/******************************************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Recreate Test4 Users';
PRINT GETDATE();

USE [ServSuiteData];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteJDE] FOR LOGIN [testservsuiteJDE] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitePI] FOR LOGIN [testservsuitePI] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteSVC] FOR LOGIN [testservsuiteSVC] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteVRM] FOR LOGIN [testservsuiteVRM] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteJDE';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteJDE';
EXEC sp_addrolemember N'db_executor', N'testservsuiteJDE';
EXEC sp_addrolemember N'db_datareader', N'testservsuitePI';
EXEC sp_addrolemember N'db_datawriter', N'testservsuitePI';
EXEC sp_addrolemember N'db_executor', N'testservsuitePI';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_executor', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';
GRANT ALTER ON SCHEMA :: mm TO [ROLLINS\sststsvc];
GRANT VIEW CHANGE TRACKING ON SCHEMA :: dbo TO [ROLLINS\sststsvc];
GRANT VIEW CHANGE TRACKING ON SCHEMA :: contact360 TO [ROLLINS\sststsvc];
GRANT VIEW CHANGE TRACKING ON SCHEMA :: OPLOC TO [ROLLINS\sststsvc];

USE [ServSuiteLog];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitePI] FOR LOGIN [testservsuitePI] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteVRM] FOR LOGIN [testservsuiteVRM] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuitePI';
EXEC sp_addrolemember N'db_datawriter', N'testservsuitePI';
EXEC sp_addrolemember N'db_executor', N'testservsuitePI';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';

USE [ServSuiteWBProgram];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitePI] FOR LOGIN [testservsuitePI] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteVRM] FOR LOGIN [testservsuiteVRM] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuitePI';
EXEC sp_addrolemember N'db_datawriter', N'testservsuitePI';
EXEC sp_addrolemember N'db_executor', N'testservsuitePI';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';

USE [ServSuiteWBReport];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitePI] FOR LOGIN [testservsuitePI] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteVRM] FOR LOGIN [testservsuiteVRM] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuitePI';
EXEC sp_addrolemember N'db_datawriter', N'testservsuitePI';
EXEC sp_addrolemember N'db_executor', N'testservsuitePI';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';

USE [ServSuiteWBUser];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitePI] FOR LOGIN [testservsuitePI] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteVRM] FOR LOGIN [testservsuiteVRM] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuitePI';
EXEC sp_addrolemember N'db_datawriter', N'testservsuitePI';
EXEC sp_addrolemember N'db_executor', N'testservsuitePI';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteVRM';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';

USE [ZenithCommissionsIntegrated];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteSVC] FOR LOGIN [testservsuiteSVC] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_executor', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';

USE [ZenithIntegrated];
CREATE USER [ROLLINS\ServSuite Orkin Test DBO] FOR LOGIN [ROLLINS\ServSuite Orkin Test DBO];
CREATE USER [ROLLINS\ServSuite Orkin Test Read-Only] FOR LOGIN [ROLLINS\ServSuite Orkin Test Read-Only];
CREATE USER [ROLLINS\sststsvc] FOR LOGIN [ROLLINS\sststsvc];
CREATE USER [testservsuiteapp] FOR LOGIN [testservsuiteapp] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuitedeploy] FOR LOGIN [testservsuitedeploy] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteSVC] FOR LOGIN [testservsuiteSVC] WITH DEFAULT_SCHEMA=[dbo];
CREATE USER [testservsuiteWM] FOR LOGIN [testservsuiteWM] WITH DEFAULT_SCHEMA=[dbo];
EXEC sp_addrolemember N'db_owner', N'ROLLINS\ServSuite Orkin Test DBO';
EXEC sp_addrolemember N'db_datareader', N'ROLLINS\ServSuite Orkin Test Read-Only';
EXEC sp_addrolemember N'db_owner', N'ROLLINS\sststsvc';
EXEC sp_addrolemember N'db_owner', N'testservsuiteapp';
EXEC sp_addrolemember N'db_owner', N'testservsuitedeploy';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_executor', N'testservsuiteSVC';
EXEC sp_addrolemember N'db_datareader', N'testservsuiteWM';
EXEC sp_addrolemember N'db_datawriter', N'testservsuiteWM';
EXEC sp_addrolemember N'db_executor', N'testservsuiteWM';

/******************************************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Element Credentials Script';
PRINT GETDATE();
/******************************************************************************************************************************/
/*Element Credentials Script */
/****************************************************************************************************************/
/*Make sure to run this script against the correct ...ServSuiteData database									*/
/*2018/08/02  Updated by Chris Kennedy																			*/
/*Removed steps to populate tbranchgateway (no longer being used)												*/
/*Added steps to update any existing records in tbranchgateway to use Testing Creditionals for Element/Vantiv	*/
/****************************************************************************************************************/
/* set PASS storage credentials */
USE ServSuiteData; 
PRINT 'UPDATE tcompany';
UPDATE tcompany
SET eps_acceptorid = 3928907
, eps_accountid = 1000681
, eps_accounttoken = 'A52018212D7C6EB4D3A0A53AD81755FE20D1AA970AD599A7CF1F53176B4C239801EAB201'
, eps_terminalid = 0001
PRINT 'UPDATE tbranchgateway';
UPDATE tbranchgateway
SET acceptorid = 3928907
, accountid = 1000681
, accounttoken = 'A52018212D7C6EB4D3A0A53AD81755FE20D1AA970AD599A7CF1F53176B4C239801EAB201'
, terminalid = 0001 
WHERE acceptorid <> ''
PRINT 'UPDATE trollinscompany';
UPDATE trollinscompany
SET accountid = '1000681',
accounttoken = 'A52018212D7C6EB4D3A0A53AD81755FE20D1AA970AD599A7CF1F53176B4C239801EAB201',
acceptorid = '39289073',
terminalid = '0001'
FROM trollinscompany;

/*********************************************************************************************************/
/*Disable EBA Expiration Date Update Process*/
PRINT'';
PRINT'';
PRINT 'Disable EBA Expiration Date Update Process';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tscheduledjob SET enabled = 0 WHERE scheduledjobid = 10;

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Set LinkURL to Integrated Test';
PRINT GETDATE();
USE ServSuiteWBProgram;
UPDATE tlinks
SET linkurl = 'https://Test4-servsuite.rollins.com/fileserver/fileupload.aspx'
WHERE linkid = 339;

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Clean Out Production Account EBA settings';
PRINT GETDATE();
USE ServSuiteData;
UPDATE taccounteba 
SET accountnumber = '', routingnumber = '', verificationnum = '', tokenid = '', lastfour = '9999';

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Delete Production Contact Email Addresses';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tcontact 
SET emailaddress = '';

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Delete email addresses from taxjournalfailureaudience in tbranch table';
PRINT GETDATE();
USE ServSuiteData;
update tbranch
set taxjournalfailureaudience = '';

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Change Production Contact Phone Numbers';
PRINT GETDATE();
USE ServSuiteData;
/*update invalid phone numbers to 555-555-5555*/
UPDATE tcontactphonenumber 
SET  phonenumbersearch = '(555) 555-5555'	
	, phonenumber = '5555555555' 
WHERE LEN(phonenumbersearch) <> 10;

USE ServSuiteData;
/*give all valid phone numbers 555 in the exchange*/
UPDATE tcontactphonenumber 
SET	  phonenumber = '('+left(phonenumbersearch, 3)+') '+'555-'+right(phonenumbersearch,4)
	, phonenumbersearch = left(phonenumbersearch, 3)+'555'+right(phonenumbersearch,4)
WHERE LEN(phonenumbersearch) = 10;

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'ortec_lowers.sql from Troy email on 6/20/17, modified via Troy email on 12/5/17';
PRINT GETDATE();
USE [ServSuiteData];
UPDATE tbranch SET dailyoptimization = 0, longdailyoptimization = 0 WHERE glprefix NOT IN ('165');
UPDATE troute SET dailyoptimization = 0;

/*added the following on 11/21/2019 per Troy's email on 11/11/19.*/
PRINT 'Ortec cleanup via Troy email on 11/11/19';
USE [ServSuiteData];
UPDATE troute SET usevdo = 0;
--TRUNCATE TABLE tphonecall;
TRUNCATE TABLE  workorderphase;

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'TRUNCATE TABLE tbranchemailcontact from Chris Kennedy email on 5/23/17';
PRINT GETDATE();
USE ServSuiteData;
TRUNCATE TABLE tbranchemailcontact;

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Clear emailaddress from tcontactemail from Troy Kellenbarger email on 5/30/17';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tcontactemail SET emailaddress = '';

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Set Curtis Smith Integrated Test Login to Administrator';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tloginrole
SET roleid = -1  /*Administrator*/
WHERE loginid = 8548;   /*Curtis Smith's loginid found in ServSuiteWBUser.dbo.tlogin*/

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Set Nancy Stenzel Integrated Test Login to Administrator';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tloginrole
SET roleid = -1  /*Administrator*/
WHERE loginid = 8654;   /*Nancy Stenzel's loginid found in ServSuiteWBUser.dbo.tlogin*/

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Set Nancy Stenzel Integrated Test Employee to give her the access she needs to test Edge';
PRINT GETDATE();
USE ServSuiteData;  
UPDATE [dbo].[temployee]
SET	[istechnician] = 1,
	[isservicecenteremployee] = 1
WHERE [loginid] = 8654; /*Nancy Stenzel's employee id to give her the access she needs to test Edge.*/

/*****************************************************************************************************************/

/****************************************************************************************************************************/

/****************************************************************************************************************************/
/****************************************************************************************************************************/
/*DataRefresh_UpdateContact360Users_WithoutBroadsoft.sql																	*/
/*Added 3/9/2017 by Ben Shearouse																					 		*/
/*Updated 1/3/2019 by Ben Shearouse per Rafael Zumbado version emailed on 4/30/2019'										*/
/*Updated 8/22/2019 by Ben Shearouse per Rafael Zumbado version emailed on 8/2/2019'										*/
/****************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'DataRefresh_UpdateContact360Users_WithoutBroadsoft.sql - Rafael Zumbado version emailed on 8/2/2019';
PRINT GETDATE();
USE ServSuiteData;

--**************************************************IF USER TABLE HAS USERLOCATIONUNITID COLUMN BUT NOT USERLOCATIONID COLUMN***********************************************************************************--
DECLARE @EmployeeNumber INT = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
and commsalesroleid = 6)


--User rollins\mstojko1
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'mstojko1') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)
	
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('mstojko1','Miroslav','Stojkovski','miroslav@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','mstojko1',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'mstojko1'),'unavail')
END;

--User rollins/mchakalo 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'mchakalo') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)
	
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('mchakalo','Mitko','Chakalov','mitko@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','mchakalo',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'mchakalo'),'unavail')
END;

--User rollins/vtoshikj
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'vtoshikj') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)
	
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('vtoshikj','Viviana','Toshikj','viviana@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','vtoshikj',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'vtoshikj'),'unavail')
END;

--User sthum
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'sthum') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)
	
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('sthum','Sharon','Thum','sthum@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','sthum',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'sthum'),'unavail')
END;

--User tcurrey
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'tcurrey') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)
	
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('tcurrey','Todd','Currey','tcurrey@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','tcurrey',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'tcurrey'),'unavail')
END;

--User kjackson
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'kjackson') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)
	
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('kjackson','Katlyn','Jackson','kjackson@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','kjackson',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'kjackson'),'unavail')
END;

--User b2auto
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'b2auto') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('b2auto','Test','Automation','b2auto@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','b2auto',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'b2auto'),'unavail')
END;

--User dchin
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'dchin') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('dchin','Dale','Chin Loy','dchin@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','dchin',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'dchin'),'unavail')
END;

--User jlongino
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'jlongino') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('jlongino','Jeff','Longino','jlongino@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','jlongino',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'jlongino'),'unavail')
END;

--User zdimcevs
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'zdimcevs') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('zdimcevs','Zoran','Dimcevski','zoran@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','zdimcevs',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'zdimcevs'),'unavail')
END;

--User lbozinov
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'lbozinov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('lbozinov','Ljupcho','Bozhinovski','luke@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','lbozinov',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'lbozinov'),'unavail')
END;

--User ejackson
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ejackson') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('ejackson','Eric','Jackson','ejackson@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','ejackson',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'ejackson'),'unavail')
END;

--User zgaberov
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'zgaberov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('zgaberov','Zoran','Gaberov','zorang@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','zgaberov',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'zgaberov'),'unavail')
END;

--User ealonso
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ealonso') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('ealonso','Everth','Alonso','ealonso@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','ealonso',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'ealonso'),'unavail')
END;

--User cmena2
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'cmena2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('cmena2','Carlos','Mena','cmena@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','cmena2',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'cmena2'),'unavail')
END;

--User grosaria
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'grosaria') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('grosaria','Gino','Rosaria','grosaria@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','grosaria',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'grosaria'),'unavail')
END;

--User jsekulov
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'jsekulov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('jsekulov','Jackie','Sekulovska','jackie@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','jsekulov',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'jsekulov'),'unavail')
END;

--User aaleksov 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'aaleksov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('aaleksov','Aleksandra','Aleksovska','aleks@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','aaleksov',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'aaleksov'),'unavail')
END;

--User zbojcevs 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'zbojcevs') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('zbojcevs','Zlatica','Bojcevska','zlatica@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','zbojcevs',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'zbojcevs'),'unavail')
END;

--User hraval 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'hraval') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('hraval','Hetal','Raval','hraval@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','hraval',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'hraval'),'unavail')
END;

--User rzumbad2 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'rzumbad2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('rzumbad2','Rafael','Zumbado','rzumbado@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','rzumbad2',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'rzumbad2'),'unavail')
END;

--User lturner2 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'lturner2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('lturner2','Laura','Turner','lturner2@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','lturner2',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'lturner2'),'unavail')
END;

--User ljackson 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ljackson') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('ljackson','Lanette','Jackson','ljackson@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','ljackson',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'ljackson'),'unavail')
END;

--User mschaefe 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'mschaefe') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('mschaefe','Megann','Schaefer','Megann.Schaefer@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','mschaefe',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'mschaefe'),'unavail')
END;

--User bisa
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'bisa') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('bisa','Ben','Shearouse','bshearou@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','bisa',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'bisa'),'unavail')
END;

--User rzumbad2
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'rzumbad2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('rzumbad2','Rafael','Zumbado','rzumbado@servsuite.net',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82012','FCTEST27',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'rzumbad2'),'unavail')
END;

--User crand1
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'crand1') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('crand1','Cherita','Rand','crand@rollins.com',@EmployeeNumber,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82012','FCTEST27',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'crand1'),'unavail')
END;

----------------------------------------------------------------MGMT-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--User koconnor 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'koconnor') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('koconnor','Kim','O''Connor','kim@servsuite.net',1436643,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82012','FCTEST27',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'koconnor'),'unavail')
END;

----------------------------------------------------------------OTHERS-----------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--User ehightow
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ehightow') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		NOT EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationUnitId])
			VALUES ('ehightow','Eric','Hightower','ehightow@rollins.com',1287594,'admin',0,'[DATA_REFRESH]',GETUTCDATE(),'[DATA_REFRESH]',GETUTCDATE(),'82011','FCTEST27',9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = 'ehightow'),'unavail')
END;

--**************************************************IF USER TABLE HAS USERLOCATIONUNITID COLUMN AND USERLOCATIONID COLUMN***********************************************************************************--
--User b2auto
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'b2auto') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber)
        and commsalesroleid = 6)

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''b2auto'',''Test'',''Automation'',''b2auto@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''b2auto'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''b2auto''),''unavail'')')
END;

--User bisa
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'bisa') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''bisa'',''Ben'',''Shearouse'',''bshearou@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''bisa'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''bisa''),''unavail'')')
END;

--User dchin
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'dchin') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''dchin'',''Dale'',''Chin Loy'',''dchin@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''dchin'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''dchin''),''unavail'')')
END;

--User jlongino
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'jlongino') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''jlongino'',''Jeff'',''Longino'',''jlongino@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''jlongino'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''jlongino''),''unavail'')')
END;

--User zdimcevs
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'zdimcevs') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''zdimcevs'',''Zoran'',''Dimcevski'',''zoran@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''zdimcevs'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''zdimcevs''),''unavail'')')
END;

--User lbozinov
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'lbozinov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''lbozinov'',''Ljupcho'',''Bozhinovski'',''luke@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''lbozinov'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''lbozinov''),''unavail'')')
END;

--User ejackson
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ejackson') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''ejackson'',''Eric'',''Jackson'',''ejackson@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''ejackson'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''ejackson''),''unavail'')')
END;

--User zgaberov
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'zgaberov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''zgaberov'',''Zoran'',''Gaberov'',''zorang@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''zgaberov'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''zgaberov''),''unavail'')')
END;

--User sristovs
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'sristovs') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''sristovs'',''Sasho'',''Ristovski'',''sasho@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''sristovs'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''sristovs''),''unavail'')')
END;

--User cmena2
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'cmena2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''cmena2'',''Carlos'',''Mena'',''cmena@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''cmena2'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''cmena2''),''unavail'')')
END;

--User grosaria
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'grosaria') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''grosaria'',''Gino'',''Rosaria'',''grosaria@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''grosaria'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''grosaria''),''unavail'')')
END;

--User jsekulov 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'jsekulov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''jsekulov'',''Jackie'',''Sekulovska'',''jackie@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''jsekulov'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''jsekulov''),''unavail'')')
END;

--User aaleksov 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'aaleksov') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''aaleksov'',''Aleksandra'',''Aleksovska'',''aleks@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''aaleksov'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''aaleksov''),''unavail'')')
END;

--User zbojcevs 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'zbojcevs') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''zbojcevs'',''Zlatica'',''Bojcevska'',''zlatica@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''zbojcevs'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''zbojcevs''),''unavail'')')
END;

--User lturner2 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'lturner2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''lturner2'',''Laura'',''Turner'',''lturner2@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''lturner2'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''lturner2''),''unavail'')')
END;

--User mschaefe 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'mschaefe') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''mschaefe'',''Megann'',''Schaefer'',''Megann.Schaefer@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''mschaefe'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''mschaefe''),''unavail'')')
END;

--User ljackson 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ljackson') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]')))
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''ljackson'',''Lanette'',''Jackson'',''ljackson@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''ljackson'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''ljackson''),''unavail'')')
END;

--User rzumbad2
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'rzumbad2') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''rzumbad2'',''Rafael'',''Zumbado'',''rzumbado@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82012'',''FCTEST27'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''rzumbad2''),''unavail'')')
END;

--User crand1
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'crand1') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''crand1'',''Cherita'',''Rand'',''crand@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82012'',''FCTEST27'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''crand1''),''unavail'')')
END;

----------------------------------------------------------------MGMT-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--User koconnor 
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'koconnor') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''koconnor'',''Kim'',''O''''Connor'',''kim@servsuite.net'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82012'',''FCTEST27'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
		INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
			VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''koconnor''),''unavail'')')
END;

----------------------------------------------------------------OTHERS-----------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--User ehightow
IF (NOT EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'ehightow') AND 
		EXISTS(SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationUnitId' AND Object_ID = Object_ID(N'[contact360].[User]')) AND 
		EXISTS (SELECT * FROM SYS.COLUMNS WHERE NAME = N'UserLocationId' AND Object_ID = Object_ID(N'[contact360].[User]'))) 
BEGIN
	SET @EmployeeNumber = (SELECT top 1 employeenumber FROM temployee WHERE isactive = 1 AND ISNUMERIC(EmployeeNumber)=1 AND termdate IS NULL and
		not exists(select 1 from [contact360].[User] cuser where cuser.employeenumber = temployee.employeenumber))

	EXEC('INSERT INTO [contact360].[User]	([Username],[Firstname],[Lastname],[Email],[EmployeeNumber],[RoleCode],[Inactive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate],[AvayaId],[FocusId],[UserLocationId],[UserLocationUnitId])
			VALUES (''ehightow'',''Eric'',''Hightower'',''ehightow@rollins.com'',' + @EmployeeNumber + ',''admin'',0,''[DATA_REFRESH]'',GETUTCDATE(),''[DATA_REFRESH]'',GETUTCDATE(),''82011'',''FCTEST27'',(SELECT UserLocationId FROM contact360.UserLocationUnit WHERE UserLocationUnitId = 9),9)
	INSERT INTO [contact360].[UserStatus] ([UserId],[Availability])
		 VALUES ((SELECT UserId FROM [contact360].[User] WHERE UserName = ''ehightow''),''unavail'')')
END;

/* Delete Users */

--User dmccants
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'dmccants')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dmccants')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dmccants')
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dmccants')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dmccants')
	DELETE FROM [contact360].[User] WHERE Username = 'dmccants' 
END;

--User bsiljano
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'bsiljano')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'bsiljano')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'bsiljano')	
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'bsiljano')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'bsiljano')
	DELETE FROM [contact360].[User] WHERE Username = 'bsiljano' 
END;

--User akyle (QA)
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'akyle')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'akyle')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'akyle')
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'akyle')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'akyle')
	DELETE FROM [contact360].[User] WHERE Username = 'akyle' 
END;

--User jfranco1 (QA)
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'jfranco1')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jfranco1')
		UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jfranco1')	
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jfranco1')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jfranco1')
	DELETE FROM [contact360].[User] WHERE Username = 'jfranco1' 
END;

--User cluu
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'cluu')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'cluu')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'cluu')	
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'cluu')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'cluu')
	DELETE FROM [contact360].[User] WHERE Username = 'cluu' 
END;

--User rphilli (QA)
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'rphilli1')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'rphilli1')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'rphilli1')	
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'rphilli1')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'rphilli1')
	DELETE FROM [contact360].[User] WHERE Username = 'rphilli1' 
END;

--User jearly (DEV)
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'jearly')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jearly')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jearly')
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jearly')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'jearly')
	DELETE FROM [contact360].[User] WHERE Username = 'jearly' 
END;

--User dtrajano (QA)
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'dtrajano')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dtrajano')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dtrajano')
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dtrajano')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'dtrajano')
	DELETE FROM [contact360].[User] WHERE Username = 'dtrajano' 
END;

--User istefano (QA)
IF EXISTS(SELECT * FROM [contact360].[User] WHERE Username = 'istefano')  
BEGIN
	UPDATE [contact360].[Inquiry] SET ResolvedById = 1514 WHERE ResolvedById = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'istefano')
	UPDATE [contact360].[Case] SET AgentId = 1514 WHERE AgentId = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'istefano')
	DELETE FROM [contact360].[AvailabilityLog] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'istefano')
	DELETE FROM [contact360].[UserStatus] WHERE USERID = (SELECT TOP 1 UserId FROM [contact360].[User] WHERE UserName = 'istefano')
	DELETE FROM [contact360].[User] WHERE Username = 'istefano' 
END;


/****************************************************************************************************************************/
/****************************************************************************************************************************/
/*DataRefresh_UpdateOpHierUsers.sql																							*/
/*Added 3/9/2017 by Ben Shearouse																					 		*/
/*Updated 12/19/2018 by Ben Shearouse per Rafael Zumbado version emailed on 4/30/2019'										*/
/*Updated 8/22/2019 by Ben Shearouse per Rafael Zumbado version emailed on 8/2/2019'										*/
/****************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'DataRefresh_UpdateOpHierUsers.sql - Rafael Zumbado version emailed on 8/2/2019';
PRINT GETDATE();
USE ServSuiteData; 

----------------------------------------------------------------DEVs-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--User  sthum 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'vtoshikj') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\sthum')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\sthum'),'ADM', 'sthum', 'Sharon Thum', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User  vtoshikj 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'vtoshikj') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\vtoshikj')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\vtoshikj'),'ADM', 'vtoshikj', 'Viviana Toshikj', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User  mchakalo 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'mchakalo') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\mchakalo')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\mchakalo'),'ADM', 'mchakalo', 'Mitko Chakalov', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User  mstojko1 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'mstojko1') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\mstojko1')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\mstojko1'),'ADM', 'mstojko1', 'Miroslav Stojkovski', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User  tcurrey 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'tcurrey') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\tcurrey')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\tcurrey'),'ADM', 'tcurrey', 'Todd Currey', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User kjackson
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'kjackson') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\kjackson')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\kjackson'),'ADM', 'kjackson', 'Katlyn E. Jackson', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User rzumbado
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'rzumbado') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\rzumbado')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\rzumbado'),'ADM', 'rzumbado', 'Rafael Zumbado', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User zdimcevs
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'zdimcevs') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\zdimcevs')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\zdimcevs'),'ADM', 'zdimcevs', 'Zoran Dimcevski', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User lbozinov
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'lbozinov') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\lbozinov')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\lbozinov'),'ADM', 'lbozinov', 'Ljupcho Bozhinovski', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User zgaberov
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'zgaberov') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\zgaberov')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\zgaberov'),'ADM', 'zgaberov', 'zoran', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User cmena2
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'cmena2') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\cmena2')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\cmena2'),'ADM', 'cmena2', 'Alfreda Jeter', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User grosaria
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'grosaria') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\grosaria')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\grosaria'),'ADM', 'grosaria', 'Gino Rosaria', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User sristovs
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'sristovs') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\sristovs')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\sristovs'),'ADM', 'sristovs', 'Sasho Ristovski', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----------------------------------------------------------------QAs--------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--User crand1 (QA)
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'crand1') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\crand1')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\crand1'),'ADM', 'crand1', 'Cherita Rand', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User b2auto (QA)
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'b2auto') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\b2auto')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\b2auto'),'ADM', 'b2auto', 'Test Automation', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----User aaleksov
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'aaleksov') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\aaleksov')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\aaleksov'),'ADM', 'aaleksov', 'Aleksandra Aleksovska', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----User zbojcevs
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'zbojcevs') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\zbojcevs')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\zbojcevs'),'ADM', 'zbojcevs', 'Zlatica B.', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User jsekulov 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'jsekulov') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\jsekulov')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\jsekulov'),'ADM', 'jsekulov', 'Jackie Sekulovska', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User hraval 
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'hraval') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\hraval')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\hraval'),'ADM', 'hraval', 'Hetal Raval', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----------------------------------------------------------------OTHERS-----------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--User bsmith12
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'bsmith12') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\bsmith12')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\bsmith12'),'SYSADM', 'bsmith12', 'Brian Smith', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;
 
--User dchin
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'dchin') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\dchin')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\dchin'),'ADM', 'dchin', 'Dane Chin Loy', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User jlongino
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'jlongino') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\jlongino')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\jlongino'),'ADM', 'jlongino', 'Jeff Longino', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----User lturner2
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'lturner2') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\lturner2')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\lturner2'),'ADM', 'lturner2', 'Laura Turner', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----User mschaefe
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'mschaefe') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\mschaefe')) 
BEGIN
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\mschaefe'),'ADM', 'mschaefe', 'Megann Schaefer', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

----------------------------------------------------------------MGMT-------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--User jbolitho1
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'jbolith1') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\jbolith1')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\jbolith1'),'ADM', 'jbolith1', 'Jaime Bolitho', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

--User koconnor
IF (NOT EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'koconnor') and exists(select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\koconnor')) 
BEGIN 
	INSERT INTO [OPLOC].[LoginRole]([LoginId],[RoleCode],[UserName],[Name],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
		 VALUES ((select loginid from ServSuiteWBUser.dbo.tlogin where adusername = 'rollins\koconnor'),'ADM', 'koconnor', 'Kim O''Connor', 1, '[Seed]', GETUTCDATE(), '[SEED]',GETUTCDATE())
END;

/* Deleted users */

--User dmccants (DEV)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'dmccants')) 
BEGIN
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'dmccants'
END;

--User cluu (DEV)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'cluu')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'cluu'
END;

--User bsiljano (DEV)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'bsiljano')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'bsiljano'
END;

--User rphilli1 (QA)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'rphilli1')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'rphilli1'
END;

--User jfranco1 (QA)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'jfranco1')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'jfranco1'
END;

--User akyle (QA)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'akyle')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'akyle'
END;

--User jearly (DEV)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'jearly')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'jearly'
END;

--User dtrajano (QA)
IF (EXISTS(SELECT * FROM [OPLOC].[LoginRole] WHERE Username = 'dtrajano')) 
BEGIN 
	DELETE FROM [OPLOC].[LoginRole] WHERE Username = 'dtrajano'
END;

/****************************************************************************************************************************/
/****************************************************************************************************************************/
/*DataRefresh_UpdateEmails.sql																								*/
/*Added 11/20/2017 by Ben Shearouse per Jaime Johnson version emailed on 11/29/2017'										*/
/*Updated 12/19/2018 by Ben Shearouse per Rafael Zumbado version emailed on 4/30/2019'										*/
/*Updated 8/22/2019 by Ben Shearouse per Rafael Zumbado version emailed on 8/2/2019'										*/
/****************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'DataRefresh_UpdateEmails.sql - Rafael Zumbado version emailed on 8/2/2019';
PRINT GETDATE();
USE ServSuiteData;

--UPDATE ENTITY EMAILS TO NON-PROD VALUES
IF EXISTS (SELECT 1 FROM OPLOC.Email)
BEGIN
	TRUNCATE TABLE OPLOC.Email
END;

INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'zoran@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'luke@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'aleks@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'zlatica@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'jackie@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'kjackson@rollins.com',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'tcurrey@rollins.com',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'ealonso@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'viviana@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'mitko@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'sthum@rollins.com',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;
INSERT INTO [OPLOC].[Email] ([EntityId],[EmailAddress],[IsActive],[CreatedBy],[UTCCreatedDate],[UpdatedBy],[UTCUpdatedDate])
	SELECT EntityId, 'miroslav@servsuite.net',1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE() FROM OPLOC.Entity;

--UPDATE JOB NOTIFICATION EMAILS TO NON-PROD VALUES
IF EXISTS (SELECT 1 FROM contact360.JobNotificationEmail)
BEGIN
	TRUNCATE TABLE contact360.JobNotificationEmail
END;

BEGIN
SET IDENTITY_INSERT [contact360].[JobNotificationEmail] ON
INSERT INTO [contact360].[JobNotificationEmail] ([JobNotificationEmailId],[EmailAddress],[EmailTypeId],[IsActive],[CreatedBy],[CreatedDate],[UpdatedBy],[UpdatedDate])
     VALUES 
		(1, 'bsmith12@rollins.com',1,1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE()),
		(2, 'bsmith12@rollins.com',2,1,'[DATA_REFRESH_SCRIPT]',GETUTCDATE(),'[DATA_REFRESH_SCRIPT]',GETUTCDATE())
SET IDENTITY_INSERT [contact360].[JobNotificationEmail] OFF
END;

/****************************************************************************************************************************/
/****************************************************************************************************************************/
/****************************************************************************************************************************/

/****************************************************************************************************************************/
/****************************************************************************************************************************/
/*DataRefresh_UpdateMissingCrossMarketEmployees.sql																			*/
/*Added 3/9/2017 by Ben Shearouse																					 		*/
/*Updated 4/18/2017 by Ben Shearouse per Jaime Johnson version emailed on 4/13/2017'										*/
/****************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'DataRefresh_UpdateMissingCrossMarketEmployees.sql - Jaime Johnson version emailed on 4/13/2017';
PRINT GETDATE();

USE ServSuiteData; 

BEGIN TRANSACTION;
	UPDATE contact360.Bundle
	SET CrossMarketLeadSourceId = NULL, SendToJdeDate = NULL
	FROM contact360.Bundle b
	INNER JOIN contact360.[Case] c on c.caseid = b.caseid 
	LEFT JOIN contact360.CrossMarketEmployee cme on cme.EmployeeNumber = b.CrossMarketLeadSourceId
	WHERE b.CrossMarketLeadSourceId is not null and cme.EmployeeNumber is null

	UPDATE contact360.[Case]
	SET UpdatedBy = 'DATAREFRESH', UpdatedDate = GETUTCDATE()
	FROM contact360.Bundle b
	INNER JOIN contact360.[Case] c on c.caseid = b.caseid 
	LEFT JOIN contact360.CrossMarketEmployee cme on cme.EmployeeNumber = b.CrossMarketLeadSourceId
	WHERE b.CrossMarketLeadSourceId is not null and cme.EmployeeNumber is null
COMMIT TRANSACTION;

PRINT GETDATE();

/****************************************************************************************************************************/
/****************************************************************************************************************************/
/*MarketingLeadCleanup.sql																									*/
/*Added 3/9/2017 by Ben Shearouse																					 		*/
/*Updated 4/18/2017 by Ben Shearouse per Jaime Johnson version emailed on 4/13/2017'										*/
/****************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'MarketingLeadCleanup.sql - Jaime Johnson version emailed on 4/13/2017';

USE [ServSuiteData]; 
UPDATE mtk1
SET mtk1.CaseId = NULL
FROM [contact360].[MarketingLead]  mtk1
WHERE mtk1.MarketingLeadId IN 
	(SELECT ml.MarketingLeadId FROM [contact360].[MarketingLead]  ml LEFT JOIN contact360.[Case] c ON ml.CaseId = c.CaseId WHERE c.CaseId IS NULL);
PRINT GETDATE();

/****************************************************************************************************************************/

/****************************************************************************************************************************/
/****************************************************************************************************************************/
/*TRUNCATE TABLE troutemail																									*/
/*Added 8/22/2019 by Ben Shearouse per Rafael Zumbado email on 8/20/2019													*/
/****************************************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'TRUNCATE TABLE troutemail per Rafael Zumbado email on 8/20/2019';
PRINT GETDATE();
USE ServSuiteData;

TRUNCATE TABLE troutemail;
/****************************************************************************************************************************/

/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Update user messages to correct the hyperlinks stored in the messages';
PRINT GETDATE();
USE ServSuiteData; 
--Update user messages to correct the hyperlinks stored in the messages
--This is needed when refreshing data from production
--to insure users do not accidently navigate to production from 
-- a lower environment
--First setup the replacement value
declare @ReplaceVal nvarchar(255)
set @ReplaceVal = '/test-servsuite.rollins.com'-- Setup our search value

declare @SearchVal nvarchar(255)
set @SearchVal = '/servsuite.rollins.com'
-- Now update the tusermessage table to fix
-- any records that have urls pointed to production
-- we have to look at the messagesubject, messageurltitle, messageurl and messagetext fields
update
      tusermessage
set
      messagesubject = 
            case when (len(messagesubject) < (100 -(len(@ReplaceVal) - len(@SearchVal))))
                        then REPLACE(messagesubject,@SearchVal,@ReplaceVal)
                  else REPLACE(messagesubject,@SearchVal,'scrubbedfromproddata')
            end,
      messageurltitle = 
            case when (len(messageurltitle) < (200 -(len(@ReplaceVal) - len(@SearchVal))))
                  then REPLACE(messageurltitle,@SearchVal,@ReplaceVal)
                  else REPLACE(messageurltitle,@SearchVal,'scrubbedfromproddata')
            end,
      messageurl = 
            case when (len(messageurl) < (200 -(len(@ReplaceVal) - len(@SearchVal))))
                  then REPLACE(messageurl,@SearchVal,@ReplaceVal)
                  else REPLACE(messageurl,@SearchVal,'scrubbedfromproddata')
            end,
      messagetext =
            case when (len(messagetext) < (2000 -(len(@ReplaceVal) - len(@SearchVal))))
                  then REPLACE(messagetext,@SearchVal,@ReplaceVal)
                  else REPLACE(messagetext,@SearchVal,'scrubbedfromproddata')
            end

/*****************************************************************************************************************/
/*Update tbranchemailsetting*/
PRINT '';
PRINT '';
PRINT 'Update tbranchemailsetting';
PRINT GETDATE();
USE ServSuiteData;
UPDATE [tbranchemailsetting]
SET smtplogin = 'test-servsuite@rollins.local'

/*****************************************************************************************************************/
/*Update tloginportal*/
/*Added by Ben Shearouse on 1/19/2018 per Jaime Johnson and Vipin email.*/
PRINT '';
PRINT '';
PRINT 'Update tloginportal';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tloginportal
       SET loginuid = '' 
WHERE loginuid NOT IN ('vmalhotr@rollins.com', 'crivers@rollins.com', 'aleksandra.stamenovska04@yahoo.com', 'dsysvipin@gmail.com', 'vipy_in@yahoo.com');

/*****************************************************************************************************************/
/*Update tcwpuserinvitations*/
/*Added by Ben Shearouse on 1/19/2018 per Jaime Johnson and Vipin email.*/
PRINT '';
PRINT '';
PRINT 'Update tcwpuserinvitations';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tcwpuserinvitations
       SET primaryemailaddress = ''
WHERE primaryemailaddress NOT IN ('vmalhotr@rollins.com', 'crivers@rollins.com', 'aleksandra.stamenovska04@yahoo.com', 'dsysvipin@gmail.com', 'vipy_in@yahoo.com');

/*****************************************************************************************************************/
/*Update tmobileversion*/
/*Added by Ben Shearouse on 5/18/2018 per Troy Kellenbarger email.*/
PRINT '';
PRINT '';
PRINT 'Update tmobileversion';
PRINT GETDATE();
USE ServSuiteData;
UPDATE tmobileversion SET numberofrecords = 1, maxnumberofphones = 1

/*****************************************************************************************************************/
PRINT '';
PRINT '';
PRINT GETDATE();

USE ServSuiteData; 

PRINT 'Truncate tmobilesiterecentcontacts';
TRUNCATE TABLE tmobilesiterecentcontacts;

PRINT 'Truncate tmobilefailure';
TRUNCATE TABLE tmobilefailure;

PRINT 'Truncate tmobileprocessdebug';
TRUNCATE TABLE tmobileprocessdebug;

PRINT 'Truncate tlogdata';
TRUNCATE TABLE tlogdata;

PRINT 'Truncate tlogentry';
TRUNCATE TABLE tlogentry;

/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Clear emailaddress and phone numbers c360, acq,and OPLOC schemas from Troy Kellenbarger and Raf 3/2/2018';
PRINT GETDATE();
USE ServSuiteData;

UPDATE [contact360].[MarketingLead]
SET Email='fake@email.com', SecondaryPhone='5555555555',  PrimaryPhone='5555555555';

UPDATE [acq].[Phone]
SET Number='5555555555', Ext='';

UPDATE [acq].[Site]
SET EMail='fake@email.com';

UPDATE [acq].[WelcomeLetterSetup]
SET OrkinBranchPhoneNumber='5555555555';
       
UPDATE [contact360].[CustomerContact]
SET Email='fake@email.com';

UPDATE [contact360].[CustomerPhone]
SET Number='5555555555', Extension='', Search='5555555555';

UPDATE [contact360].[call]
SET PersonPhone='5555555555';

UPDATE  [OPLOC].[Phone]
SET PhoneNumber='5555555555';

/*********************************************************************************************************/
/**************************************************************************************************************************************/
PRINT'';
PRINT'';
PRINT 'To allow the RAC Purchase Automation RBJ to run correctly in lower environments- Jasper Dumas version emailed on 7/24/2018';
PRINT GETDATE();
USE ServSuiteData;
update tcompany set racownerid = (select top 1 loginid from tloginrole);

/**************************************************************************************************************************************/
/**************************************************************************************************************************************/
PRINT'';
PRINT'';
PRINT 'Clear billing and Mass emails from Profiles - Jody Pope version emailed on 8/27/2018';
PRINT GETDATE();
USE ServSuiteData;
--Clear billing and Mass emails from Profiles
update ea
set value = ''
from   oploc.entityattribute ea
       join oploc.attributetype at
       on ea.attributetypeid = at.attributetypeid
where at.name in ('BillingRecipients','MassEmailRecipients');

--Clear billing and Mass emails from account/site settings
update taccountsettings set attributevalue = '' where attributename in ('BillingRecipients','MassEmailRecipients');
update tsitesettings set attributevalue = '' where attributename in ('BillingRecipients','MassEmailRecipients');

--Clear biling from invoice groups
update taccountinvoicegroup set EmailRecipientsCsv = '';

/*********************************************************************************************************/
/*********************************************************************************************************/
PRINT '';
PRINT 'Scrubb tsscustomers table. Per Vipin email on 1/1/2019.';
PRINT '';
PRINT GETDATE();

USE ServSuiteData;
UPDATE tsscustomers
       SET email = 'fake@nomail.com'
WHERE ISNULL(email, '') <> '' ;

UPDATE tsscustomers
       SET primaryphone = '(555) 555-5555'
WHERE ISNULL(primaryphone, '') <> '';

UPDATE tsscustomers
       SET secondaryphone = '(555) 555-5555'
WHERE ISNULL(secondaryphone, '') <> '';

/*********************************************************************************************************/

/**************************************************************************************************************************************/
/**************************************************************************************************************************************/

PRINT'';
PRINT'';
PRINT 'Update all merchant ID information to test values - Dane Chin Loy version emailed on 8/27/2018';
PRINT GETDATE();
USE ServSuiteData;
-- Update all merchant ID information to test values
-- Update the legacy locations
UPDATE trollinscompany set acceptorid='3928907', accountid='1000681', accounttoken='A52018212D7C6EB4D3A0A53AD81755FE20D1AA970AD599A7CF1F53176B4C239801EAB201', terminalid='0001', applicationid='691', lastchanged=getutcdate(), lastchangedby='DBRefresh';
UPDATE tcompany SET eps_acceptorid='3928907', eps_accountid='1000681', eps_accounttoken='A52018212D7C6EB4D3A0A53AD81755FE20D1AA970AD599A7CF1F53176B4C239801EAB201', eps_terminalid='0001' where companyid=1;
UPDATE tcompany SET eps_acceptorid='3928907', eps_accountid='1055194', eps_accounttoken='82A6E968AD54A2BDA6949E789371142F94CC31215B6CDF18E9779AD63B6FD9B7DE308A01', eps_terminalid='0001' where companyid=2;

-- This table shouldn't even be used anymore, so inject some bogus stuff
update tbranchgateway set accountid='N/A', accounttoken='N/A', applicationid=691, acceptorid='N/A', terminalid='N/A', lastchanged=getutcdate(), lastchangedby='DBRefresh';

-- Delete all the oploc merchant info and then repopulate it
delete oea from oploc.entityattribute oea join oploc.entity oen on oea.entityid = oen.entityid where oea.attributetypeid in (1101, 1102, 1103, 1104, 1105, 1106);

-- US test merchant ID's
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1101, '4', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber in ('BRAND1', 'GBL-BRAND');
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1102, '3928907', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber in ('BRAND1', 'GBL-BRAND');
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1103, '1000681', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber in ('BRAND1', 'GBL-BRAND');
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1104, 'A52018212D7C6EB4D3A0A53AD81755FE20D1AA970AD599A7CF1F53176B4C239801EAB201', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber in ('BRAND1', 'GBL-BRAND');
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1105, '0001', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber in ('BRAND1', 'GBL-BRAND');
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1106, '691', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber in ('BRAND1', 'GBL-BRAND');

-- Canadian test merchant ID's
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1101, '4', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber='BRAND8';
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1102, '3928907', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber='BRAND8';
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1103, '1055194', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber='BRAND8';
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1104, '82A6E968AD54A2BDA6949E789371142F94CC31215B6CDF18E9779AD63B6FD9B7DE308A01',  'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber='BRAND8';
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1105, '0001', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber='BRAND8';
insert into oploc.entityattribute (EntityId, AttributeTypeId, Value, CreatedBy, UTCCreatedDate, UpdatedBy, UTCUpdatedDate) select entityid, 1106, '9428', 'DBRefresh', getutcdate(), 'DBRefresh', getutcdate() from oploc.entity oen where oen.entitynumber='BRAND8';

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 10/19/2018 by Ben Shearouse per Troy Kellenberger's email on 10/18/2018.						 */
/*Run this script on Replica1 if it exists or Live if it is a stand alone.								 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Update Synonym definition pointed to production database name';
PRINT '';
PRINT GETDATE();


USE ServSuiteData;
IF EXISTS(SELECT * FROM  sys.synonyms s WHERE s.name = 'teventtargetlog')
BEGIN
drop synonym teventtargetlog
END;

declare @logdb nvarchar(128)
select @logdb = name from sys.databases where name like '%ServSuiteLog';

declare @sqlsyn nvarchar(max) =N'create synonym dbo.teventtargetlog for ' + @logdb + '.dbo.teventtargetlog';

exec sp_executesql @sqlsyn;

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 01/08/2019 by Ben Shearouse per Troy Kellenberger's email on 01/03/2019.						 */
/*Run this script on Live.																				 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Update Glympse Information per Troy K. email on 1/3/19';
PRINT '';
PRINT GETDATE();

USE ServSuiteData;
--LIVE Data DB
update tbranch set glympseorgid = 0, notificationservicetyperesidential = 0, notificationservicetypecommercial = 0, 
notificationservicetypetctb = 0, glympsenotificationoptions = 0

USE ServSuiteWBUser;
--USER DB NOTE: this will need changed for hotfix [hotfixservsuitewbuser] and datafix [datafixservsuitewbuser]
update servsuitewbuser.dbo.tlogin set glympseagentid = 0 where glympseagentid > 0

/*Added this on 4/30/19 per Troy's email.*/
USE ServSuiteData;
TRUNCATE TABLE tworkorderheadermobile;

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 05/08/2019 by Ben Shearouse per Rafael Zumbado's email on 05/07/2019.							 */
/*Run this script on Live.																				 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Delete mail schema data per Rafael Zumbado email on 05/07/2019';
PRINT '';
PRINT GETDATE();

USE [ServSuiteData];
EXEC sys.sp_dropextendedproperty @name=N'MS_DescriptionTo' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAddress', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAddress';
EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAddress', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAddress';
ALTER TABLE [mail].[MessageAddress] DROP CONSTRAINT [FK_Message_MessageAddress];

EXEC sys.sp_dropextendedproperty @name=N'MS_DescriptionTo' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAttachment';
EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAttachment';
ALTER TABLE [mail].[MessageAttachment] DROP CONSTRAINT [FK_Message_MessageAttachment];

ALTER TABLE [mail].[Message] DROP CONSTRAINT [DF_mailMessage_CreatedOnUtc];
ALTER TABLE [mail].[Message] DROP CONSTRAINT [DF_mailMessage_Priority];
ALTER TABLE [mail].[Message] DROP CONSTRAINT [DF_mailMessage_QuietTimeUTCEndHour];
ALTER TABLE [mail].[Message] DROP CONSTRAINT [DF_mailMessage_QuietTimeUTCStartHour];
ALTER TABLE [mail].[Message] DROP CONSTRAINT [DF_mailMessage_UTCScheduledSendTime];

IF EXISTS (select a.name as schema_name, b.name as object_name from sys.schemas a inner join sys.objects b on a.schema_id = b.schema_id where a.name = 'mail' and b.name = 'MessageAttachment')
TRUNCATE TABLE [mail].[MessageAttachment];
IF EXISTS (select a.name as schema_name, b.name as object_name from sys.schemas a inner join sys.objects b on a.schema_id = b.schema_id where a.name = 'mail' and b.name = 'MessageAddress')
TRUNCATE TABLE [mail].[MessageAddress];
IF EXISTS (select a.name as schema_name, b.name as object_name from sys.schemas a inner join sys.objects b on a.schema_id = b.schema_id where a.name = 'mail' and b.name = 'Message')
TRUNCATE TABLE [mail].[Message];

ALTER TABLE [mail].[Message] ADD  CONSTRAINT [DF_mailMessage_CreatedOnUtc]  DEFAULT (getutcdate()) FOR [CreatedOnUtc];
ALTER TABLE [mail].[Message] ADD  CONSTRAINT [DF_mailMessage_Priority]  DEFAULT ((999)) FOR [MessagePriority];
ALTER TABLE [mail].[Message] ADD  CONSTRAINT [DF_mailMessage_QuietTimeUTCEndHour]  DEFAULT ((0)) FOR [QuietTimeUTCEndHour];
ALTER TABLE [mail].[Message] ADD  CONSTRAINT [DF_mailMessage_QuietTimeUTCStartHour]  DEFAULT ((0)) FOR [QuietTimeUTCStartHour];
ALTER TABLE [mail].[Message] ADD  CONSTRAINT [DF_mailMessage_UTCScheduledSendTime]  DEFAULT (getutcdate()) FOR [UTCScheduledSendTime];

ALTER TABLE [mail].[MessageAddress]  WITH CHECK ADD  CONSTRAINT [FK_Message_MessageAddress] FOREIGN KEY([MessageId])
REFERENCES [mail].[Message] ([MessageId]);
ALTER TABLE [mail].[MessageAddress] CHECK CONSTRAINT [FK_Message_MessageAddress];
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Message' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAddress', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAddress';
EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'MessageAddresses' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAddress', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAddress';

ALTER TABLE [mail].[MessageAttachment]  WITH CHECK ADD  CONSTRAINT [FK_Message_MessageAttachment] FOREIGN KEY([MessageId])
REFERENCES [mail].[Message] ([MessageId]);
ALTER TABLE [mail].[MessageAttachment] CHECK CONSTRAINT [FK_Message_MessageAttachment];
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Message' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAttachment';
EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'MessageAttachments' , @level0type=N'SCHEMA',@level0name=N'mail', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_Message_MessageAttachment';

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 6/12/2019 by Ben Shearouse per Jody Pope's email on 5/31/2019.									 */
/*Delete textmessage schema data after R150 on 6/12/2019.												 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Delete textmessage schema data per Jody Pope email on 5/31/2019 to go in after R150 on 6/12/2019';
PRINT '';
PRINT GETDATE();

USE [ServSuiteData];
EXEC sys.sp_dropextendedproperty @name=N'MS_DescriptionTo' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessageAttachment';
EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessageAttachment';
ALTER TABLE [textmessage].[MessageAttachment] DROP CONSTRAINT [FK_textmessageMessage_textmessageMessageAttachment];

EXEC sys.sp_dropextendedproperty @name=N'MS_DescriptionTo' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessagePhoneNumber', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessagePhoneNumber';
EXEC sys.sp_dropextendedproperty @name=N'MS_Description' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessagePhoneNumber', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessagePhoneNumber';
ALTER TABLE [textmessage].[MessagePhoneNumber] DROP CONSTRAINT [FK_textmessageMessage_textmessageMessagePhoneNumber];

IF EXISTS (select a.name as schema_name, b.name as object_name from sys.schemas a inner join sys.objects b on a.schema_id = b.schema_id where a.name = 'textmessage' and b.name = 'MessageAttachment')
TRUNCATE TABLE [textmessage].[MessageAttachment];
IF EXISTS (select a.name as schema_name, b.name as object_name from sys.schemas a inner join sys.objects b on a.schema_id = b.schema_id where a.name = 'textmessage' and b.name = 'MessagePhoneNumber')
TRUNCATE TABLE [textmessage].[MessagePhoneNumber];
IF EXISTS (select a.name as schema_name, b.name as object_name from sys.schemas a inner join sys.objects b on a.schema_id = b.schema_id where a.name = 'textmessage' and b.name = 'Message')
TRUNCATE TABLE [textmessage].[Message];

ALTER TABLE [textmessage].[MessageAttachment]  WITH CHECK ADD  CONSTRAINT [FK_textmessageMessage_textmessageMessageAttachment] FOREIGN KEY([MessageId])
REFERENCES [textmessage].[Message] ([MessageId]);
ALTER TABLE [textmessage].[MessageAttachment] CHECK CONSTRAINT [FK_textmessageMessage_textmessageMessageAttachment];
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Message' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessageAttachment';
EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'MessageAttachments' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessageAttachment', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessageAttachment';

ALTER TABLE [textmessage].[MessagePhoneNumber]  WITH CHECK ADD  CONSTRAINT [FK_textmessageMessage_textmessageMessagePhoneNumber] FOREIGN KEY([MessageId])
REFERENCES [textmessage].[Message] ([MessageId]);
ALTER TABLE [textmessage].[MessagePhoneNumber] CHECK CONSTRAINT [FK_textmessageMessage_textmessageMessagePhoneNumber];
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsNumberForMessage' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessagePhoneNumber', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessagePhoneNumber';
EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'HasMessagePhoneNumber' , @level0type=N'SCHEMA',@level0name=N'textmessage', @level1type=N'TABLE',@level1name=N'MessagePhoneNumber', @level2type=N'CONSTRAINT',@level2name=N'FK_textmessageMessage_textmessageMessagePhoneNumber';

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 7/26/2019 by Ben Shearouse per Troy Kellenbarger's email on 7/25/2019.							 */
/*TRUNCATE TABLE tapitoken																				 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'TRUNCATE TABLE tapitoken';
PRINT GETDATE();
USE ServSuiteWBUser;
TRUNCATE TABLE tapitoken;

/**************************************************************************************************************************/

/****************************************************************************************************************************/
/*UPDATE contact360.marketinglead SET externalid = -1																		*/
/*Added 7/26/2019 by Ben Shearouse																					 		*/
/*per Rafael Zumbado email on 7/17/2019																						*/
/****************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'UPDATE contact360.marketinglead SET externalid = -1; per Rafael Zumbado email on 7/17/2019';
PRINT GETDATE();
USE [ServSuiteData];
UPDATE contact360.marketinglead 
SET externalid = -1;

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 5/15/2020 by Ben Shearouse per Jafett Sandi's email on 4/30/2020.															*/
/*Updated on 6/15/2020.																												*/
/*Run this script on Live.																											*/
/************************************************************************************************************************************/

/**/
/*Against SSDATA Live:*/
--Oploc Use OSP = None
USE [ServSuiteData];
UPDATE oploc.entityattribute SET value = 0 WHERE  attributetypeid = 842 and value <> 0;

--Routes
USE [ServSuiteData];
UPDATE troute  SET usevdo = 0 WHERE usevdo > 0;


/****************************************************************************************************************************/
/**************************************************************************************************************************/
/*
--Added 7/14/2021 by Blake Cheatham
--This deletes the tables being tested for permanent removal.
--08/06/2021 Removed Round 1 drops because they have moved to production
*/


/**************************************************************************************************************************/
/*
--Added 7/21/2021 by Blake Cheatham
--This deletes the round 2 tables being tested for permanent removal.
--Needs to run on lower environments after restore completes.
Removed 08/30/2021
*/

/*
--Added 8/5/2021 by Blake Cheatham
--This deletes the round 3 tables being tested for permanent removal.
--Needs to run on lower environments after restore completes.
Removed 10/11/2021
*/
/*
--Added 10/11/2021 by Blake Cheatham
--This deletes the round 4 tables being tested for permanent removal.
--Needs to run on lower environments after restore completes.
*/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF exists(Select Name from sys.objects where name = '_tmpincdecbalance')
DROP TABLE [dbo].[_tmpincdecbalance]

IF exists(Select Name from sys.objects where name = 'mapping_branch_fix')
DROP TABLE [dbo].[mapping_branch_fix]

IF exists(Select Name from sys.objects where name = 'Mapping_Employees')
DROP TABLE [dbo].[Mapping_Employees]

IF exists(Select Name from sys.objects where name = 'Mapping_EmployeesMap')
DROP TABLE [dbo].[Mapping_EmployeesMap]

IF exists(Select Name from sys.objects where name = 'Mapping_Inspectionpointtype20140626')
DROP TABLE [dbo].[Mapping_Inspectionpointtype20140626]

IF exists(Select Name from sys.objects where name = 'removed_teventprice')
DROP TABLE [dbo].[removed_teventprice]

IF exists(Select Name from sys.objects where name = 'temp_INCDEC_Detail')
DROP TABLE [dbo].[temp_INCDEC_Detail]

IF exists(Select Name from sys.objects where name = 'temp_INCDEC_Detail_Final')
DROP TABLE [dbo].[temp_INCDEC_Detail_Final]

IF exists(Select Name from sys.objects where name = 'inv_glsPreDF')
DROP TABLE [dbo].[inv_glsPreDF]

IF exists(Select Name from sys.objects where name = 'Jody_AGP_auxlist')
DROP TABLE [dbo].[Jody_AGP_auxlist]

IF exists(Select Name from sys.objects where name = 'OC_InventoryFinal')
DROP TABLE [dbo].[OC_InventoryFinal]

IF exists(Select Name from sys.objects where name = 'OCEmployeeList')
DROP TABLE [dbo].[OCEmployeeList]

IF exists(Select Name from sys.objects where name = 'octobervalues')
DROP TABLE [dbo].[octobervalues]

IF exists(Select Name from sys.objects where name = 'OctVariableWOupdate')
DROP TABLE [dbo].[OctVariableWOupdate]

IF exists(Select Name from sys.objects where name = 'OrkinAire')
DROP TABLE [dbo].[OrkinAire]

IF exists(Select Name from sys.objects where name = 'OrkinCA_Branch_Address')
DROP TABLE [dbo].[OrkinCA_Branch_Address]

IF exists(Select Name from sys.objects where name = 'pay_glsPreDF')
DROP TABLE [dbo].[pay_glsPreDF]

IF exists(Select Name from sys.objects where name = 'ProgramSetupOC')
DROP TABLE [dbo].[ProgramSetupOC]

IF exists(Select Name from sys.objects where name = 'ProgramSetupOCNC')
DROP TABLE [dbo].[ProgramSetupOCNC]

IF exists(Select Name from sys.objects where name = 'Psocid')
DROP TABLE [dbo].[Psocid]

IF exists(Select Name from sys.objects where name = 'StorageFee')
DROP TABLE [dbo].[StorageFee]

IF exists(Select Name from sys.objects where name = 'tmpSanofiChanges')
DROP TABLE [dbo].[tmpSanofiChanges]

IF exists(Select Name from sys.objects where name = 'tmpSanofiChanges2')
DROP TABLE [dbo].[tmpSanofiChanges2]

IF exists(Select Name from sys.objects where name = 'tmpSanofiChanges3')
DROP TABLE [dbo].[tmpSanofiChanges3]

IF exists(Select Name from sys.objects where name = 'tmpWOTargetDeleted')
DROP TABLE [dbo].[tmpWOTargetDeleted]

IF exists(Select Name from sys.objects where name = 'tOCZenithAccountMap')
DROP TABLE [dbo].[tOCZenithAccountMap]

IF exists(Select Name from sys.objects where name = 'tOCZenithInvoiceGroupMap')
DROP TABLE [dbo].[tOCZenithInvoiceGroupMap]

IF exists(Select Name from sys.objects where name = 'tOCZenithSiteMap')
DROP TABLE [dbo].[tOCZenithSiteMap]

IF exists(Select Name from sys.objects where name = 'WosToBeSpiltted')
DROP TABLE [dbo].[WosToBeSpiltted]

IF exists(Select Name from sys.objects where name = 'WosToBeSpiltted2')
DROP TABLE [dbo].[WosToBeSpiltted2]

IF exists(Select Name from sys.objects where name = 'WosToBeSpiltted3')
DROP TABLE [dbo].[WosToBeSpiltted3]

IF exists(Select Name from sys.objects where name = 'WosToBeSpiltted4')
DROP TABLE [dbo].[WosToBeSpiltted4]

IF exists(Select Name from sys.objects where name = '_308Increase')
DROP TABLE [dbo].[_308Increase]

IF exists(Select Name from sys.objects where name = '_Balancing_AccountBalance')
DROP TABLE [dbo].[_Balancing_AccountBalance]

IF exists(Select Name from sys.objects where name = '_balancing_baddebtcredits')
DROP TABLE [dbo].[_balancing_baddebtcredits]

IF exists(Select Name from sys.objects where name = '_balancing_creditsumbyaccount')
DROP TABLE [dbo].[_balancing_creditsumbyaccount]

IF exists(Select Name from sys.objects where name = '_balancing_invoicesum')
DROP TABLE [dbo].[_balancing_invoicesum]

IF exists(Select Name from sys.objects where name = '_balancing_invoicesumbyaccount')
DROP TABLE [dbo].[_balancing_invoicesumbyaccount]

IF exists(Select Name from sys.objects where name = '_balancing_paymentsreceivedsum')
DROP TABLE [dbo].[_balancing_paymentsreceivedsum]

IF exists(Select Name from sys.objects where name = '_balancing_paymentsreceivedsumwithCOP')
DROP TABLE [dbo].[_balancing_paymentsreceivedsumwithCOP]

IF exists(Select Name from sys.objects where name = '_balancing_paymentssumbyaccount')
DROP TABLE [dbo].[_balancing_paymentssumbyaccount]

IF exists(Select Name from sys.objects where name = '_balancing_paymentssumbyaccountwithCOP')
DROP TABLE [dbo].[_balancing_paymentssumbyaccountwithCOP]

IF exists(Select Name from sys.objects where name = '_balancing_WOsumbyaccount')
DROP TABLE [dbo].[_balancing_WOsumbyaccount]

IF exists(Select Name from sys.objects where name = '_Balancing_WOValue')
DROP TABLE [dbo].[_Balancing_WOValue]

IF exists(Select Name from sys.objects where name = '_bkp_tprogrampirollbackrequest')
DROP TABLE [dbo].[_bkp_tprogrampirollbackrequest]

IF exists(Select Name from sys.objects where name = '_bkp_tprogrampirollbackrequestchangehistory')
DROP TABLE [dbo].[_bkp_tprogrampirollbackrequestchangehistory]

IF exists(Select Name from sys.objects where name = '_DeferredRevenueFocusImport')
DROP TABLE [dbo].[_DeferredRevenueFocusImport]

IF exists(Select Name from sys.objects where name = '_defrev_eventdeferalstoremove')
DROP TABLE [dbo].[_defrev_eventdeferalstoremove]

IF exists(Select Name from sys.objects where name = '_defrev_eventprice')
DROP TABLE [dbo].[_defrev_eventprice]

IF exists(Select Name from sys.objects where name = '_defrev_eventsrenewalamount')
DROP TABLE [dbo].[_defrev_eventsrenewalamount]

IF exists(Select Name from sys.objects where name = '_defrev_quaraterlyrenewalpaysum')
DROP TABLE [dbo].[_defrev_quaraterlyrenewalpaysum]

IF exists(Select Name from sys.objects where name = '_defrevenueevents_calcyears')
DROP TABLE [dbo].[_defrevenueevents_calcyears]

IF exists(Select Name from sys.objects where name = '_DefRevenueProjectionReport')
DROP TABLE [dbo].[_DefRevenueProjectionReport]

IF exists(Select Name from sys.objects where name = '_defrevenueprojectionreport_maxpaydate')
DROP TABLE [dbo].[_defrevenueprojectionreport_maxpaydate]

IF exists(Select Name from sys.objects where name = '_DefRevEvents')
DROP TABLE [dbo].[_DefRevEvents]

IF exists(Select Name from sys.objects where name = '_DefRevRenewals')
DROP TABLE [dbo].[_DefRevRenewals]

IF exists(Select Name from sys.objects where name = '_HOProjectionForecast')
DROP TABLE [dbo].[_HOProjectionForecast]

IF exists(Select Name from sys.objects where name = '_renewalPayments')
DROP TABLE [dbo].[_renewalPayments]

IF exists(Select Name from sys.objects where name = '_renewalPaymentsSum')
DROP TABLE [dbo].[_renewalPaymentsSum]

IF exists(Select Name from sys.objects where name = '_tmp_acquisitionsTable')
DROP TABLE [dbo].[_tmp_acquisitionsTable]

IF exists(Select Name from sys.objects where name = '_tmp_COPMovements')
DROP TABLE [dbo].[_tmp_COPMovements]

IF exists(Select Name from sys.objects where name = '_tmpAR')
DROP TABLE [dbo].[_tmpAR]

IF exists(Select Name from sys.objects where name = '_tmpglquery')
DROP TABLE [dbo].[_tmpglquery]

IF exists(Select Name from sys.objects where name = '_tmpmaterial')
DROP TABLE [dbo].[_tmpmaterial]

IF exists(Select Name from sys.objects where name = '_tmpmatused')
DROP TABLE [dbo].[_tmpmatused]

IF exists(Select Name from sys.objects where name = '_tmpstnsumm')
DROP TABLE [dbo].[_tmpstnsumm]

IF exists(Select Name from sys.objects where name = '_tmpsvcs')
DROP TABLE [dbo].[_tmpsvcs]

IF exists(Select Name from sys.objects where name = '_tmptable')
DROP TABLE [dbo].[_tmptable]

IF exists(Select Name from sys.objects where name = '_tmptimeline')
DROP TABLE [dbo].[_tmptimeline]

IF exists(Select Name from sys.objects where name = '_tmpusagedist')
DROP TABLE [dbo].[_tmpusagedist]

IF exists(Select Name from sys.objects where name = '_tmpwoactvity')
DROP TABLE [dbo].[_tmpwoactvity]

IF exists(Select Name from sys.objects where name = '_tprojectionforecast')
DROP TABLE [dbo].[_tprojectionforecast]

IF exists(Select Name from sys.objects where name = 'AdditionalAccountAnnValue')
DROP TABLE [dbo].[AdditionalAccountAnnValue]

IF exists(Select Name from sys.objects where name = 'aTempService')
DROP TABLE [dbo].[aTempService]

IF exists(Select Name from sys.objects where name = 'aTempServiceNotPaid')
DROP TABLE [dbo].[aTempServiceNotPaid]

IF exists(Select Name from sys.objects where name = 'barcodeDups')
DROP TABLE [dbo].[barcodeDups]

IF exists(Select Name from sys.objects where name = 'CraneEmployeeXref')
DROP TABLE [dbo].[CraneEmployeeXref]

IF exists(Select Name from sys.objects where name = 'CraneMaterials')
DROP TABLE [dbo].[CraneMaterials]

IF exists(Select Name from sys.objects where name = 'craneStationsXref')
DROP TABLE [dbo].[craneStationsXref]

IF exists(Select Name from sys.objects where name = 'CraneStationType')
DROP TABLE [dbo].[CraneStationType]

IF exists(Select Name from sys.objects where name = 'CWeventdups')
DROP TABLE [dbo].[CWeventdups]

IF exists(Select Name from sys.objects where name = 'CWUniqueEvents')
DROP TABLE [dbo].[CWUniqueEvents]

IF exists(Select Name from sys.objects where name = 'DevRev_nov2018')
DROP TABLE [dbo].[DevRev_nov2018]

IF exists(Select Name from sys.objects where name = 'DupFocusConvServ')
DROP TABLE [dbo].[DupFocusConvServ]

IF exists(Select Name from sys.objects where name = 'DupWos')
DROP TABLE [dbo].[DupWos]

IF exists(Select Name from sys.objects where name = 'FIX_CARDHOLDERINFO')
DROP TABLE [dbo].[FIX_CARDHOLDERINFO]

--IF exists(Select Name from sys.objects where name = 'FlatRatePricingMethod')
--DROP TABLE [dbo].[FlatRatePricingMethod]

IF exists(Select Name from sys.objects where name = 'HnHpreserve')
DROP TABLE [dbo].[HnHpreserve]

IF exists(Select Name from sys.objects where name = 'HulettTransfers')
DROP TABLE [dbo].[HulettTransfers]

IF exists(Select Name from sys.objects where name = 'InvoiceWrongProgram')
DROP TABLE [dbo].[InvoiceWrongProgram]

IF exists(Select Name from sys.objects where name = 'Mapping_AppMethod')
DROP TABLE [dbo].[Mapping_AppMethod]

IF exists(Select Name from sys.objects where name = 'Mapping_Branch')
DROP TABLE [dbo].[Mapping_Branch]

IF exists(Select Name from sys.objects where name = 'Mapping_CancelReason')
DROP TABLE [dbo].[Mapping_CancelReason]

IF exists(Select Name from sys.objects where name = 'Mapping_Credit')
DROP TABLE [dbo].[Mapping_Credit]

IF exists(Select Name from sys.objects where name = 'Mapping_Credits')
DROP TABLE [dbo].[Mapping_Credits]

IF exists(Select Name from sys.objects where name = 'Mapping_Discounts')
DROP TABLE [dbo].[Mapping_Discounts]

IF exists(Select Name from sys.objects where name = 'Mapping_Employees20140626')
DROP TABLE [dbo].[Mapping_Employees20140626]

IF exists(Select Name from sys.objects where name = 'Mapping_EstimateTypes')
DROP TABLE [dbo].[Mapping_EstimateTypes]

IF exists(Select Name from sys.objects where name = 'Mapping_InspectionPoint')
DROP TABLE [dbo].[Mapping_InspectionPoint]

IF exists(Select Name from sys.objects where name = 'Mapping_Materials')
DROP TABLE [dbo].[Mapping_Materials]

IF exists(Select Name from sys.objects where name = 'Mapping_Payplans')
DROP TABLE [dbo].[Mapping_Payplans]

IF exists(Select Name from sys.objects where name = 'Mapping_Propertytype')
DROP TABLE [dbo].[Mapping_Propertytype]

IF exists(Select Name from sys.objects where name = 'Mapping_Route')
DROP TABLE [dbo].[Mapping_Route]

IF exists(Select Name from sys.objects where name = 'Mapping_Routes20140626')
DROP TABLE [dbo].[Mapping_Routes20140626]

IF exists(Select Name from sys.objects where name = 'Mapping_ServiceCode')
DROP TABLE [dbo].[Mapping_ServiceCode]

IF exists(Select Name from sys.objects where name = 'Mapping_ServiceCode20140626')
DROP TABLE [dbo].[Mapping_ServiceCode20140626]

IF exists(Select Name from sys.objects where name = 'Mapping_ServiceName')
DROP TABLE [dbo].[Mapping_ServiceName]

IF exists(Select Name from sys.objects where name = 'Mapping_Sources')
DROP TABLE [dbo].[Mapping_Sources]

IF exists(Select Name from sys.objects where name = 'Mapping_Target')
DROP TABLE [dbo].[Mapping_Target]

IF exists(Select Name from sys.objects where name = 'Mapping_TargetPest')
DROP TABLE [dbo].[Mapping_TargetPest]

IF exists(Select Name from sys.objects where name = 'Mapping_TimeOption')
DROP TABLE [dbo].[Mapping_TimeOption]

IF exists(Select Name from sys.objects where name = 'Mapping_Warranty')
DROP TABLE [dbo].[Mapping_Warranty]

IF exists(Select Name from sys.objects where name = 'Match_CheckBillingAddress')
DROP TABLE [dbo].[Match_CheckBillingAddress]

IF exists(Select Name from sys.objects where name = 'matchdups')
DROP TABLE [dbo].[matchdups]

IF exists(Select Name from sys.objects where name = 'MATCHSAVE')
DROP TABLE [dbo].[MATCHSAVE]

IF exists(Select Name from sys.objects where name = 'OrkinNationals')
DROP TABLE [dbo].[OrkinNationals]

IF exists(Select Name from sys.objects where name = 'PTPRODTC')
DROP TABLE [dbo].[PTPRODTC]

IF exists(Select Name from sys.objects where name = 'RACFinance_TMP')
DROP TABLE [dbo].[RACFinance_TMP]

IF exists(Select Name from sys.objects where name = 'reconv_services_fix')
DROP TABLE [dbo].[reconv_services_fix]

IF exists(Select Name from sys.objects where name = 'RenewalsNotPaid')
DROP TABLE [dbo].[RenewalsNotPaid]

IF exists(Select Name from sys.objects where name = 'RenewalsNotPaidInvoices')
DROP TABLE [dbo].[RenewalsNotPaidInvoices]

IF exists(Select Name from sys.objects where name = 'RenewalsNotPaidPayments')
DROP TABLE [dbo].[RenewalsNotPaidPayments]

IF exists(Select Name from sys.objects where name = 'Routes_Excel')
DROP TABLE [dbo].[Routes_Excel]

IF exists(Select Name from sys.objects where name = 'Sheet1$baddebt')
DROP TABLE [dbo].[Sheet1$baddebt]

IF exists(Select Name from sys.objects where name = 'site47028CNStations')
DROP TABLE [dbo].[site47028CNStations]

IF exists(Select Name from sys.objects where name = 'SSPGM$MC')
DROP TABLE [dbo].[SSPGM$MC]

IF exists(Select Name from sys.objects where name = 'Stg_Conv_ProductNames')
DROP TABLE [dbo].[Stg_Conv_ProductNames]

IF exists(Select Name from sys.objects where name = 'STG_CONV_Services')
DROP TABLE [dbo].[STG_CONV_Services]

IF exists(Select Name from sys.objects where name = 'Stg_Seasonal_Multi')
DROP TABLE [dbo].[Stg_Seasonal_Multi]

IF exists(Select Name from sys.objects where name = 'TargetPestsXref')
DROP TABLE [dbo].[TargetPestsXref]

IF exists(Select Name from sys.objects where name = 'tbl_HOC_monthly_metrics')
DROP TABLE [dbo].[tbl_HOC_monthly_metrics]

IF exists(Select Name from sys.objects where name = 'Temp_1_WO')
DROP TABLE [dbo].[Temp_1_WO]

IF exists(Select Name from sys.objects where name = 'Temp_2_WO')
DROP TABLE [dbo].[Temp_2_WO]

IF exists(Select Name from sys.objects where name = 'Temp_4_WO')
DROP TABLE [dbo].[Temp_4_WO]

IF exists(Select Name from sys.objects where name = 'Temp_5_WO')
DROP TABLE [dbo].[Temp_5_WO]

IF exists(Select Name from sys.objects where name = 'temp_annuals')
DROP TABLE [dbo].[temp_annuals]

IF exists(Select Name from sys.objects where name = 'temp_ARbyInvoice')
DROP TABLE [dbo].[temp_ARbyInvoice]

IF exists(Select Name from sys.objects where name = 'temp_ARbyProgram')
DROP TABLE [dbo].[temp_ARbyProgram]

IF exists(Select Name from sys.objects where name = 'Temp_INCDEC_Summary')
DROP TABLE [dbo].[Temp_INCDEC_Summary]

IF exists(Select Name from sys.objects where name = 'temp_ipptotal')
DROP TABLE [dbo].[temp_ipptotal]

IF exists(Select Name from sys.objects where name = 'temp_pprice')
DROP TABLE [dbo].[temp_pprice]

IF exists(Select Name from sys.objects where name = 'temp_prices')
DROP TABLE [dbo].[temp_prices]

IF exists(Select Name from sys.objects where name = 'temp_ServiceTeam')
DROP TABLE [dbo].[temp_ServiceTeam]

IF exists(Select Name from sys.objects where name = 'Temp_TFS104287')
DROP TABLE [dbo].[Temp_TFS104287]

IF exists(Select Name from sys.objects where name = 'temp_wolabor')
DROP TABLE [dbo].[temp_wolabor]

IF exists(Select Name from sys.objects where name = 'tempebaidtoupdate')
DROP TABLE [dbo].[tempebaidtoupdate]

IF exists(Select Name from sys.objects where name = 'tempHD769928_2')
DROP TABLE [dbo].[tempHD769928_2]

IF exists(Select Name from sys.objects where name = 'temployee_emp_int_backup_616')
DROP TABLE [dbo].[temployee_emp_int_backup_616]

IF exists(Select Name from sys.objects where name = 'temployee_emp_int_backup_617')
DROP TABLE [dbo].[temployee_emp_int_backup_617]

IF exists(Select Name from sys.objects where name = 'temppcbacklog_reportall')
DROP TABLE [dbo].[temppcbacklog_reportall]

IF exists(Select Name from sys.objects where name = 'tEnhancedBillingHOCTracking')
DROP TABLE [dbo].[tEnhancedBillingHOCTracking]

IF exists(Select Name from sys.objects where name = 'tfinstatglreport_original')
DROP TABLE [dbo].[tfinstatglreport_original]

IF exists(Select Name from sys.objects where name = 'tmpDeletedCreditCards')
DROP TABLE [dbo].[tmpDeletedCreditCards]

IF exists(Select Name from sys.objects where name = 'tmpdeviceactivity')
DROP TABLE [dbo].[tmpdeviceactivity]

IF exists(Select Name from sys.objects where name = 'tmpFinstatGlReport_new')
DROP TABLE [dbo].[tmpFinstatGlReport_new]

IF exists(Select Name from sys.objects where name = 'tmpPplanPriceRemoval')
DROP TABLE [dbo].[tmpPplanPriceRemoval]

IF exists(Select Name from sys.objects where name = 'tmpsrv1')
DROP TABLE [dbo].[tmpsrv1]

IF exists(Select Name from sys.objects where name = 'tmpstnsummary')
DROP TABLE [dbo].[tmpstnsummary]

IF exists(Select Name from sys.objects where name = 'TmpTBDserv')
DROP TABLE [dbo].[TmpTBDserv]

IF exists(Select Name from sys.objects where name = 'tmpTransactionDetailsAR_new')
DROP TABLE [dbo].[tmpTransactionDetailsAR_new]

IF exists(Select Name from sys.objects where name = 'toremove2017')
DROP TABLE [dbo].[toremove2017]

IF exists(Select Name from sys.objects where name = 'tpaymentitemTesting01202012')
DROP TABLE [dbo].[tpaymentitemTesting01202012]

IF exists(Select Name from sys.objects where name = 'WesternMigration_taccountbilling')
DROP TABLE [dbo].[WesternMigration_taccountbilling]

IF exists(Select Name from sys.objects where name = 'WesternMigration_taccountbillingevent')
DROP TABLE [dbo].[WesternMigration_taccountbillingevent]

IF exists(Select Name from sys.objects where name = 'WesternMigration_taccountbillinghistory')
DROP TABLE [dbo].[WesternMigration_taccountbillinghistory]

IF exists(Select Name from sys.objects where name = 'WesternMigration_taccounteba')
DROP TABLE [dbo].[WesternMigration_taccounteba]

IF exists(Select Name from sys.objects where name = 'WesternMigration_taccountnote')
DROP TABLE [dbo].[WesternMigration_taccountnote]

IF exists(Select Name from sys.objects where name = 'WesternMigration_tevent')
DROP TABLE [dbo].[WesternMigration_tevent]

IF exists(Select Name from sys.objects where name = 'WesternMigration_teventprice')
DROP TABLE [dbo].[WesternMigration_teventprice]

IF exists(Select Name from sys.objects where name = 'WesternMigration_tprogram')
DROP TABLE [dbo].[WesternMigration_tprogram]

IF exists(Select Name from sys.objects where name = 'WesternMigration_tprogramvalue')
DROP TABLE [dbo].[WesternMigration_tprogramvalue]

IF exists(Select Name from sys.objects where name = 'ZonesWithStationHistory')
DROP TABLE [dbo].[ZonesWithStationHistory]

IF exists(Select Name from sys.objects where name = 'Deleted_tworkorderPendinbservation_HD0000001120218')
DROP TABLE [dbo].[Deleted_tworkorderPendinbservation_HD0000001120218]
GO

/*********************************************************************************************************/

/************************************************************************************************************************************/
/*Added 4/9/2021 by Ben Shearouse per Dane Chin Loy's email on 3/23/2021.															*/
/*Run this script on Live ServSuiteData.																							*/
/************************************************************************************************************************************/

/**/
/*Against ServSuiteData Live:*/
PRINT '';
PRINT '';
PRINT 'Reset and disable the Marketo synchronization process for all companies. Per Dane Chin Loy email on 3/23/2021';
PRINT GETDATE();

--Reset and disable the Marketo synchronization process for all companies
USE [ServSuiteData];
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'pConfigMarketingSync')
exec pConfigMarketingSync 'DataRefresh', -999, 0, 1;

/****************************************************************************************************************************/

/*********************************************************************************************************/
/*This script checks to make sure that production connection values have been changed to non-prod values.*/
/*It will set the values to blank if they are production values.										 */
/*If they are not production values it leaves them alone.												 */
/*The Before/After script is supposed to change the values from prod to the correct non-prod values.	 */
/*However, sometimes it fails and this is to catch any mishaps in the restore process.					 */
/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Verifing tdatabase settings do NOT point to production';
PRINT GETDATE();

USE [ServSuiteWBUser];

IF  EXISTS 
(
SELECT *
  FROM [tdatabase]
  WHERE [programserver] = '0x08fa4552246b8effcb7d08d3dfb0a8e8'					/*ServSuiteDBProd - alais*/
	or [programserver] = '0xf2e6e4ad8690ea3e98b8c92802f3fa95'					/*RWBDBAGH201 - SQL Role Name*/
	or [dataserver] = '0x08fa4552246b8effcb7d08d3dfb0a8e8'						/*ServSuiteDBProd - alais*/
	or [dataserver] = '0xf2e6e4ad8690ea3e98b8c92802f3fa95'						/*RWBDBAGH201 - SQL Role Name*/
	or [logserver] = '0x08fa4552246b8effcb7d08d3dfb0a8e8'						/*ServSuiteDBProd - alais*/
	or [logserver] = '0xf2e6e4ad8690ea3e98b8c92802f3fa95'						/*RWBDBAGH201 - SQL Role Name*/
	or [userid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'							/*ServSuiteapp - user name*/
	or [replicateserver] = '0x08fa4552246b8eff74e2df3a55b06cacc3640ee3b6bebbde' /*ServSuiteDBProdRpt - alais*/
	or [replicateserver] = '0xe9ecef7309d880ff562c39c5327c54ff'					/*RWBDBH204 - SQL Role Name*/
	or [replicateuserid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'					/*ServSuiteapp - user name*/
/*CRM - Orkin Canada*/
	or [programserver] = '0xf84a8537edf4a82bbd1d456f0cf776dd'					/*RWBCDBAGH201*/
	or [dataserver] = '0xf84a8537edf4a82bbd1d456f0cf776dd'						/*RWBCDBAGH201*/
	or [logserver] = '0xf84a8537edf4a82bbd1d456f0cf776dd'						/*RWBCDBAGH201*/
	or [userid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'							/*cn_servsuiteapp*/
	or [replicateserver] = '0xf84a8537edf4a82b5f1316fb1b757fcb5d4873244331ff17'	/*RWBCDBAGH202\REPLICA01*/
	or [replicateuserid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'					/*cn_servsuiteapp*/
)

BEGIN

	UPDATE [tdatabase]
	SET	[programserver] = ''
	, [dataserver] = ''
	, [logserver] = ''
	, [userid] = ''
	, [replicateserver] = ''
	, [replicateuserid] = ''

	PRINT 'WARNING!! WARNING!!'
	PRINT 'You must change the connection settings in the tdatabase table in ServSuiteWBUser.'
	PRINT 'WARNING!! WARNING!!'
	PRINT GETDATE();
END;

IF NOT EXISTS 
(
SELECT *
  FROM [tdatabase]
  WHERE [programserver] = '0x08fa4552246b8effcb7d08d3dfb0a8e8'					/*ServSuiteDBProd*/
	or [programserver] = '0xf2e6e4ad8690ea3e98b8c92802f3fa95'					/*RWBDBAGH201*/
	or [dataserver] = '0x08fa4552246b8effcb7d08d3dfb0a8e8'						/*ServSuiteDBProd*/
	or [dataserver] = '0xf2e6e4ad8690ea3e98b8c92802f3fa95'						/*RWBDBAGH201*/
	or [logserver] = '0x08fa4552246b8effcb7d08d3dfb0a8e8'						/*ServSuiteDBProd*/
	or [logserver] = '0xf2e6e4ad8690ea3e98b8c92802f3fa95'						/*RWBDBAGH201*/
	or [userid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'							/*ServSuiteapp*/
	or [replicateserver] = '0x08fa4552246b8eff74e2df3a55b06cacc3640ee3b6bebbde' /*ServSuiteDBProdRpt*/
	or [replicateserver] = '0xe9ecef7309d880ff562c39c5327c54ff'					/*RWBDBH204*/
	or [replicateuserid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'					/*ServSuiteapp*/
/*CRM - Orkin Canada*/
	or [programserver] = '0xf84a8537edf4a82bbd1d456f0cf776dd'					/*RWBCDBAGH201*/
	or [dataserver] = '0xf84a8537edf4a82bbd1d456f0cf776dd'						/*RWBCDBAGH201*/
	or [logserver] = '0xf84a8537edf4a82bbd1d456f0cf776dd'						/*RWBCDBAGH201*/
	or [userid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'							/*cn_servsuiteapp*/
	or [replicateserver] = '0xf84a8537edf4a82b5f1316fb1b757fcb5d4873244331ff17'	/*RWBCDBAGH202\REPLICA01*/
	or [replicateuserid] = '0x00f91f4464c1ba2c2be3c96cfbc426fb'					/*cn_servsuiteapp*/
)

BEGIN

PRINT 'Verified tdatabase settings do NOT point to production.';
PRINT GETDATE();

END;

/*********************************************************************************************************/

/*********************************************************************************************************/
/*Cleanup Mobile Full and Change Tracking jobs in RBJ													 */
/*Added 7/15/2016 by Ben Shearouse per Troy's request.													 */
/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Cleanup Mobile Full and Change Tracking jobs in RBJ';
PRINT GETDATE();
PRINT '';
USE RollinsBackgroundJobs;
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-FULL' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-FULL' and status = 'RUNNING');
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-CHANGES' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-CHANGES' and status = 'RUNNING');
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'CustomerJourneyUpdateJob' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'CustomerJourneyUpdateJob' and status = 'RUNNING');
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'QueuedTextMessageProcessor' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'QueuedTextMessageProcessor' and status = 'RUNNING');

Update tservicenotificationqueue
set DeliveryTarget = '',
processing = 2

USE RollinsBackgroundJobs;
TRUNCATE TABLE ssmobile.mobileq1;
TRUNCATE TABLE ssmobile.mobileq2;
TRUNCATE TABLE ssmobile.mobileq3;
TRUNCATE TABLE ssmobile.mobilesynctracking;

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 3/9/2017 by Ben Shearouse per Janice Uwujaren.													 */
/*Run this script on Replica1 if it exists or Live if it is a stand alone.								 */
/*I decided to run it on all nodes; Live, Replica1, and Replica2 because								 */
/*there are plans to have RBJ jobs move to Replica2.													 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Disable_Claims_Processing_Jobs.sql from Janice Uwujaren';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
UPDATE tJobInstanceAssignment SET isEnabled = 0 FROM tJobInstanceAssignment ia INNER JOIN tJobList jl ON ia.ID = jl.ID WHERE jobName LIKE '%claimsprocessing%';
UPDATE tJobList SET isEnabled = 0 WHERE jobName LIKE '%claimsprocessing%';

/*********************************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 7/26/2019 by Ben Shearouse per Troy Kellenbarger's email on 5/9/2019.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/*Troy wants it to be added to all rbj refresh scripts excluding dev2, test2, itest usa, itest crm, stage usa, stage crm			*/
/*I decided to run it on all nodes; Live, Replica1, and Replica2 because															*/
/*there are plans to have RBJ jobs move to Replica2.																				*/
/*To be run in all non-prod environments.																							*/
/************************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'UPDATE tjoblist SET isenabled = 0 for specific jobs per Troy email on 5/9/19';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
UPDATE tjoblist SET isenabled = 0 
WHERE jobname in ( 'CapsurePublicAPI', 'Capsure-Export-Customers', 'GoGPS', 'RouteOptimize', 'PhoneValidator'
					, 'ServiceNotificationQueue', 'ServiceNotificationProcess', 'GlympseCheck', 'Geocode', 'Podium' );

/****************************************************************************************************************************/

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 01/08/2019 by Ben Shearouse per Troy Kellenberger's email on 01/03/2019.						 */
/*Run this script on the active RBJ.																	 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Update Glympse Information per Troy K. email on 1/3/19';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
TRUNCATE TABLE tservicenotificationqueue;

/**************************************************************************************************************************/

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 11/21/2019 by Ben Shearouse per Troy K on 11/11/19.												 */
/*Run this script on the active RBJ.																	 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Disable Ortec RBJ jobs per Troys email on 11/11/19';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
DELETE tlogin_ortecsent;
DELETE trouteday_ortecsent;
DELETE testimate_ortecsent;
DELETE tworkorderheader_ortecsent;

DELETE tlogin_ortec;
DELETE trouteday_ortec;
DELETE testimate_ortec;
DELETE tworkorderheader_ortec;

TRUNCATE TABLE workorderphaseortec;

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 5/8/2020 by Ben Shearouse per Troy Kellenbarger's email on 4/17/2020.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'UPDATE tjoblist SET isenabled = 0 WHERE jobname = ''gogps'' for specific jobs per Troy email on 4/17/20';
PRINT '';
PRINT GETDATE();
USE [RollinsBackgroundJobs];
UPDATE tjoblist SET isenabled = 0 WHERE jobname = 'gogps'
UPDATE tjobinstanceassignment SET isenabled = 0 WHERE id = (SELECT TOP 1 id FROM tjoblist WHERE jobname = 'gogps')

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 5/8/2020 by Ben Shearouse per Troy Kellenbarger's email on 5/8/2020.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'UPDATE tjoblist SET UTCNextScheduledRun = GETUTCDATE() WHERE jobname= ''SSMobile-Download-Sync-Feed-FULL'' for specific jobs per Troy email on 5/8/20';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
TRUNCATE TABLE ssmobile.MobileSyncTracking
UPDATE tjoblist SET UTCNextScheduledRun = GETUTCDATE() WHERE jobname= 'SSMobile-Download-Sync-Feed-FULL'

/**************************************************************************************************************************/

GO


:Connect OWSSDDBO248


/*********************************************************************************************************/
/*Cleanup Mobile Full and Change Tracking jobs in RBJ													 */
/*Added 7/15/2016 by Ben Shearouse per Troy's request.													 */
/*********************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'Cleanup Mobile Full and Change Tracking jobs in RBJ';
PRINT GETDATE();
PRINT '';
USE RollinsBackgroundJobs;
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-FULL' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-FULL' and status = 'RUNNING');
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-CHANGES' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'SSMobile-Download-Sync-Feed-CHANGES' and status = 'RUNNING');
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'CustomerJourneyUpdateJob' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'CustomerJourneyUpdateJob' and status = 'RUNNING');
delete tstepstatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'QueuedTextMessageProcessor' and status = 'RUNNING');
delete tjobStatus where jobinstanceid = (select jobinstanceid from tjobstatus where jobname = 'QueuedTextMessageProcessor' and status = 'RUNNING');

Update tservicenotificationqueue
set DeliveryTarget = '',
processing = 2
USE RollinsBackgroundJobs;
TRUNCATE TABLE ssmobile.mobileq1;
TRUNCATE TABLE ssmobile.mobileq2;
TRUNCATE TABLE ssmobile.mobileq3;
TRUNCATE TABLE ssmobile.mobilesynctracking;

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 3/9/2017 by Ben Shearouse per Janice Uwujaren.													 */
/*Run this script on Replica1 if it exists or Live if it is a stand alone.								 */
/*I decided to run it on all nodes; Live, Replica1, and Replica2 because								 */
/*there are plans to have RBJ jobs move to Replica2.													 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Disable_Claims_Processing_Jobs.sql from Janice Uwujaren';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
UPDATE tJobInstanceAssignment SET isEnabled = 0 FROM tJobInstanceAssignment ia INNER JOIN tJobList jl ON ia.ID = jl.ID WHERE jobName LIKE '%claimsprocessing%';
UPDATE tJobList SET isEnabled = 0 WHERE jobName LIKE '%claimsprocessing%';

/*********************************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 7/26/2019 by Ben Shearouse per Troy Kellenbarger's email on 5/9/2019.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/*Troy wants it to be added to all rbj refresh scripts excluding dev2, test2, itest usa, itest crm, stage usa, stage crm			*/
/*I decided to run it on all nodes; Live, Replica1, and Replica2 because															*/
/*there are plans to have RBJ jobs move to Replica2.																				*/
/*To be run in all non-prod environments.																							*/
/************************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'UPDATE tjoblist SET isenabled = 0 for specific jobs per Troy email on 5/9/19';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
UPDATE tjoblist SET isenabled = 0 
WHERE jobname in ( 'CapsurePublicAPI', 'Capsure-Export-Customers', 'GoGPS', 'RouteOptimize', 'PhoneValidator'
					, 'ServiceNotificationQueue', 'ServiceNotificationProcess', 'GlympseCheck', 'Geocode', 'Podium' );

/****************************************************************************************************************************/

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 01/08/2019 by Ben Shearouse per Troy Kellenberger's email on 01/03/2019.						 */
/*Run this script on the active RBJ.																	 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Update Glympse Information per Troy K. email on 1/3/19';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
TRUNCATE TABLE tservicenotificationqueue;

/**************************************************************************************************************************/

/**************************************************************************************************************************/
/*********************************************************************************************************/
/*Added 11/21/2019 by Ben Shearouse per Troy K on 11/11/19.												 */
/*Run this script on the active RBJ.																	 */
/*To be run in all non-prod environments.																 */
/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Disable Ortec RBJ jobs per Troys email on 11/11/19';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
DELETE tlogin_ortecsent;
DELETE trouteday_ortecsent;
DELETE testimate_ortecsent;
DELETE tworkorderheader_ortecsent;

DELETE tlogin_ortec;
DELETE trouteday_ortec;
DELETE testimate_ortec;
DELETE tworkorderheader_ortec;

TRUNCATE TABLE workorderphaseortec;

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 5/8/2020 by Ben Shearouse per Troy Kellenbarger's email on 4/17/2020.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/
PRINT '';
PRINT '';
PRINT 'UPDATE tjoblist SET isenabled = 0 WHERE jobname = ''gogps'' for specific jobs per Troy email on 4/17/20';
PRINT '';
PRINT GETDATE();
USE [RollinsBackgroundJobs];
UPDATE tjoblist SET isenabled = 0 WHERE jobname = 'gogps'
UPDATE tjobinstanceassignment SET isenabled = 0 WHERE id = (SELECT TOP 1 id FROM tjoblist WHERE jobname = 'gogps')

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 5/8/2020 by Ben Shearouse per Troy Kellenbarger's email on 5/8/2020.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'UPDATE tjoblist SET UTCNextScheduledRun = GETUTCDATE() WHERE jobname= ''SSMobile-Download-Sync-Feed-FULL'' for specific jobs per Troy email on 5/8/20';
PRINT '';
PRINT GETDATE();

USE [RollinsBackgroundJobs];
TRUNCATE TABLE ssmobile.MobileSyncTracking
UPDATE tjoblist SET UTCNextScheduledRun = GETUTCDATE() WHERE jobname= 'SSMobile-Download-Sync-Feed-FULL'

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 5/15/2020 by Ben Shearouse per Jafett Sandi's email on 4/30/2020.															*/
/*Updated on 6/15/2020.																												*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/

/*Against RBJ on the env appropriate replica:*/
USE [RollinsBackgroundJobs];
TRUNCATE TABLE tlogin_ortecsent;
TRUNCATE TABLE trouteday_ortecsent;
TRUNCATE TABLE testimate_ortecsent;
TRUNCATE TABLE tworkorderheader_ortecsent;

DELETE tlogin_ortec;
DELETE trouteday_ortec;
DELETE testimate_ortec;
DELETE tworkorderheader_ortec;

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 11/5/2020 by Ben Shearouse per Jeff Longino's email on 11/5/2020.															*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/
DELETE RollinsBackgroundJobs..tRunOnceHistory  WHERE ScriptName = 'Migrate-RFS-HWM-2Shadow.tpl.sql'

/****************************************************************************************************************************/
/************************************************************************************************************************************/
/*Added 10/7/2020 by Ben Shearouse per Troy Kellenbarger's email on 9/1/2020.														*/
/*Run this script on Replica1 if it exists or Live if it is a stand alone.															*/
/************************************************************************************************************************************/

USE [RollinsBackgroundJobs]; 
TRUNCATE TABLE BranchMEC_ClaimQ; 

/**************************************************************************************************************************/

GO


:Connect OWSSTDBAGO204

/**************************************************************************************************************************/
/*********************************************************************************************************/
PRINT '';
PRINT 'Enable All Triggers on databases.';
PRINT '';
PRINT GETDATE();

USE [ServSuiteData];
exec sp_MSforeachtable "ALTER TABLE ? ENABLE TRIGGER ALL";
PRINT 'Enabled All Triggers on ServSuiteData.';

USE [ServSuiteLog];
exec sp_MSforeachtable "ALTER TABLE ? ENABLE TRIGGER ALL";
PRINT 'Enabled All Triggers on ServSuiteLog.';

USE [ServSuiteWBProgram];
exec sp_MSforeachtable "ALTER TABLE ? ENABLE TRIGGER ALL";
PRINT 'Enabled All Triggers on ServSuiteWBProgram.';

USE [ServSuiteWBReport];
exec sp_MSforeachtable "ALTER TABLE ? ENABLE TRIGGER ALL";
PRINT 'Enabled All Triggers on ServSuiteWBReport.';

USE [ServSuiteWBUser];
exec sp_MSforeachtable "ALTER TABLE ? ENABLE TRIGGER ALL";
PRINT 'Enabled All Triggers on ServSuiteWBUser.';

/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Enabled testservsuiteapp SQL Login';
PRINT 'Enabled ROLLINS\sststsvc SQL Login';
PRINT GETDATE();
USE [master];
ALTER LOGIN [testservsuiteapp] ENABLE;
ALTER LOGIN [ROLLINS\sststsvc] ENABLE;

/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Enable cohesity backup job';
EXEC msdb.dbo.sp_start_job @job_name='Enable cohesity backup job', @server_name='OWSSDDBO249';

/*********************************************************************************************************/

PRINT '';
PRINT '';
PRINT 'Test4 Environment Database Refresh Complete on OWSSTDBAGO204';
PRINT 'and AlwaysOn set up on OWSSDDBO248';
PRINT GETDATE();
/*********************************************************************************************************/
/*********************************************************************************************************/
/*********************************************************************************************************/


GO
