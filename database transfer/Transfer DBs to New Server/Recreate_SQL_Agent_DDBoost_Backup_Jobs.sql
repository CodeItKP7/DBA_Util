-----------------------------------------------------------------------------------------------------------------------
--  Find & Replace <__New DB Server Name__>. with actual server name.
-- Create the output directories.
-----------------------------------------------------------------------------------------------------------------------
USE [master]
GO

/****** Object:  StoredProcedure [dbo].[emc_run_restore]    Script Date: 10/22/2021 10:44:27 AM ******/
DROP PROCEDURE IF EXISTS [dbo].[emc_run_restore]
GO

/****** Object:  StoredProcedure [dbo].[emc_run_delete]    Script Date: 10/22/2021 10:44:27 AM ******/
DROP PROCEDURE IF EXISTS [dbo].[emc_run_delete]
GO

/****** Object:  StoredProcedure [dbo].[emc_run_backup]    Script Date: 10/22/2021 10:44:27 AM ******/
DROP PROCEDURE IF EXISTS [dbo].[emc_run_backup]
GO

/****** Object:  StoredProcedure [dbo].[emc_run_backup]    Script Date: 10/22/2021 10:44:27 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[emc_run_backup]
	@cmdText [nvarchar](max)
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ddbmaSQLCLR].[ddbmaSQLCLRLib.DDBMASQL].[RunBackup]
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_backup] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[emc_run_delete]    Script Date: 10/22/2021 10:44:27 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[emc_run_delete]
	@cmdText [nvarchar](max)
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ddbmaSQLCLR].[ddbmaSQLCLRLib.DDBMASQL].[RunDelete]
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_delete] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[emc_run_restore]    Script Date: 10/22/2021 10:44:27 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[emc_run_restore]
	@cmdText [nvarchar](max)
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ddbmaSQLCLR].[ddbmaSQLCLRLib.DDBMASQL].[RunRestore]
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_restore] TO  SCHEMA OWNER 
GO


USE master
GO
--Procedure
--1.   When you install the Microsoft application agent, do not deploy the CLRAssembly on the SQL Server instance, on which you want to register the
--Microsoft application agent stored procedures in a user database. If the assembly is already registered on the instance, unregister or remove the assembly by using the ddbmaSQLCLRDeployApp.exe file.
--2.   After the Microsoft application agent installation completes, run the followingcommands on the SQL Server:

	sp_configure 'show advanced options',1; 
	GO
	RECONFIGURE; 
	GO
	sp_configure 'clr enabled', 1; 
	GO
	RECONFIGURE; 
	GO
--Note: If you have modified the CPU or IO affinity mask for the server, replace RECONFIGURE with RECONFIGURE WITH OVERRIDE in the above commands.
--This modification disables configuration parameter checking that would otherwise prevent the changes from being made.
--3.   Create a login in the master table by running the following commands:
	create asymmetric key ddbmaCLRExtensionKey from executable file= 'C:\Program Files\DPSAPPS\MSAPPAGENT\bin\DDBMASQLCLRLib.dll' 
	GO
	create login ddbmaCLRExtLogin from asymmetric keyddbmaCLRExtensionKey; 
	GO
	grant unsafe assembly to ddbmaCLRExtLogin; 
	GO
--4.   Run the following commands on the user database, in which you want to register or save the stored procedures:
	CREATE ASSEMBLY ddbmaSQLCLR from 'C:\Program Files\DPSAPPS\MSAPPAGENT\bin\DDBMASQLCLRLib.dll' WITH PERMISSION_SET =UNSAFE; 
	GO
	CREATE PROCEDURE emc_run_backup @cmdText nvarchar(MAX) AS EXTERNAL NAME ddbmaSQLCLR.[ddbmaSQLCLRLib.DDBMASQL].RunBackup; 
	GO
	CREATE PROCEDURE emc_run_restore @cmdText nvarchar(MAX) AS EXTERNAL NAME ddbmaSQLCLR.[ddbmaSQLCLRLib.DDBMASQL].RunRestore; 
	GO
	CREATE PROCEDURE emc_run_delete @cmdText nvarchar(MAX) AS EXTERNAL NAME ddbmaSQLCLR.[ddbmaSQLCLRLib.DDBMASQL].RunDelete; 
	GO

USE [msdb]
GO

/****** Object:  Job [SQL Backup - DDBoost - DIFFERENTIAL]    Script Date: 9/14/2021 7:12:25 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/14/2021 7:12:25 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'SQL Backup - DDBoost - DIFFERENTIAL')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQL Backup - DDBoost - DIFFERENTIAL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [SQL Backup - DDBoost - DIFFERENTIAL]    Script Date: 9/14/2021 7:12:25 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SQL Backup - DDBoost - DIFFERENTIAL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]

GO

DECLARE @t table (msg nvarchar(MAX))

DECLARE @returnCode int

INSERT INTO @t (msg) EXEC @returnCode = dbo.emc_run_backup '' -c <__New DB Server Name__>.rollins.local -A <__New DB Server Name__>.rollins.local -S 4 -l diff -b "Diff_Backup_<__New DB Server Name__>" -y +1d -a "NSR_DFA_SI_DD_HOST=dd-di-occc-01.rollins.local" -a "NSR_DFA_SI_DD_USER=sqldevddboost" -a "NSR_DFA_SI_DEVICE_PATH=/occcsqldev" -a "NSR_DFA_SI_DD_LOCKBOX_PATH=C:\Program Files\DPSAPPS\common\lockbox" -a "NSR_SKIP_NON_BACKUPABLE_STATE_DB=TRUE" -a "BACKUP_PROMOTION=SKIP_RECOVERY_MODEL" -N "Diffl_Backup_<__New DB Server Name__>" MSSQL:''
IF @returnCode <> 0
BEGIN
RAISERROR (''Fail!'', 16, 1)
END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SQL Backup - DDBoost - DIFFERENTIAL', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=126, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160525, 
		@active_end_date=99991231, 
		@active_start_time=500, 
		@active_end_time=235959, 
		@schedule_uid=N'918cd950-fd7e-4d66-a729-a066e80d372c'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [SQL Backup - DDBoost - FULL]    Script Date: 9/14/2021 7:12:25 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/14/2021 7:12:25 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'SQL Backup - DDBoost - FULL')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQL Backup - DDBoost - FULL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [SQL Backup - DDBoost - FULL]    Script Date: 9/14/2021 7:12:26 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SQL Backup - DDBoost - FULL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]

GO

DECLARE @t table (msg nvarchar(MAX))

DECLARE @returnCode int

INSERT INTO @t (msg) EXEC @returnCode = dbo.emc_run_backup '' -c <__New DB Server Name__>.rollins.local -A <__New DB Server Name__>.rollins.local -S 4 -l full -b "Full_Backup_<__New DB Server Name__>" -y +1d -a "NSR_DFA_SI_DD_HOST=dd-di-occc-01.rollins.local" -a "NSR_DFA_SI_DD_USER=sqldevddboost" -a "NSR_DFA_SI_DEVICE_PATH=/occcsqldev" -a "NSR_DFA_SI_DD_LOCKBOX_PATH=C:\Program Files\DPSAPPS\common\lockbox" -a "NSR_SKIP_NON_BACKUPABLE_STATE_DB=TRUE" -a "BACKUP_PROMOTION=ALL" -N "Full_Backup_<__New DB Server Name__>" MSSQL:''
IF @returnCode <> 0
BEGIN
RAISERROR (''Fail!'', 16, 1)
END', 
		@database_name=N'master', 
		@output_file_name=N'D:\Maintenance_Output\EMC_DDBst_Full.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SQL Backup - DDBoost - FULL', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20160525, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'68f08ae0-6796-4065-a1f2-2637b5e01428'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [SQL Backup - DDBoost - MARK_EXPIRE_DELETE]    Script Date: 9/14/2021 7:12:26 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/14/2021 7:12:26 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'SQL Backup - DDBoost - MARK_EXPIRE_DELETE')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQL Backup - DDBoost - MARK_EXPIRE_DELETE', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [Expiry Command]    Script Date: 9/14/2021 7:12:26 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Expiry Command', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/* SQL command to delete the backups - mark all backups for deletion for instance on this server earlier than 2 days. */
USE [master]
GO
DECLARE @returnCode int
EXEC @returnCode = dbo.emc_run_delete '' -k -e "2 days ago" -n mssql -a DDBOOST_USER=sqldevddboost -a DEVICE_PATH=/occcsqldev -a "LOCKBOX_PATH=C:\Program Files\DPSAPPS\common\lockbox" -a DEVICE_HOST=dd-di-occc-01.rollins.local -a CLIENT=<__New DB Server Name__>.rollins.local ''

IF @returnCode = 1
BEGIN
  print ''Code 1: Error or Notice - Backup result set not found!!''
END
IF @returnCode = 2
BEGIN
    print ''Code 2: Warning - Backup result set not found!!''
END
IF @returnCode > 2
BEGIN
  RAISERROR (''Fail!'', 16, 1)
END', 
		@database_name=N'master', 
		@output_file_name=N'D:\Maintenance_Output\EMC_DDBst_ExpiryDeletion.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'W2', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160525, 
		@active_end_date=99991231, 
		@active_start_time=30000, 
		@active_end_time=235959, 
		@schedule_uid=N'68f08ae0-6796-4065-a1f2-2637b5e01411'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

/****** Object:  Job [SQL Backup - DDBoost - TLOG]    Script Date: 9/14/2021 7:12:26 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 9/14/2021 7:12:26 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
select @jobId = job_id from msdb.dbo.sysjobs where (name = N'SQL Backup - DDBoost - TLOG')
if (@jobId is NULL)
BEGIN
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQL Backup - DDBoost - TLOG', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END
/****** Object:  Step [SQL Backup - DDBoost - TLOG]    Script Date: 9/14/2021 7:12:27 PM ******/
IF NOT EXISTS (SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId AND step_id = 1)
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SQL Backup - DDBoost - TLOG', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [master]

GO

DECLARE @t table (msg nvarchar(MAX))

DECLARE @returnCode int

INSERT INTO @t (msg) EXEC   @returnCode = dbo.emc_run_backup '' -c <__New DB Server Name__>.rollins.local -l incr -y +3d -a "NSR_DFA_SI_DD_HOST=dd-di-occc-01.rollins.local" -a "NSR_DFA_SI_DD_USER=sqldevddboost" -a "NSR_DFA_SI_DEVICE_PATH=/occcsqldev" -a "NSR_DFA_SI_DD_LOCKBOX_PATH=C:\Program Files\DPSAPPS\common\lockbox" -a "SKIP_SIMPLE_DATABASE=FALSE" -a "NSR_SKIP_NON_BACKUPABLE_STATE_DB=TRUE" -N "DB_TLog_Backup" MSSQL:''
IF @returnCode <> 0
BEGIN
RAISERROR (''Fail!'', 16, 1)
END
GO', 
		@database_name=N'master', 
		@output_file_name=N'D:\Maintenance_Output\EMC_DDBst_TLOG.txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'SQL Backup - DDBoost - TLOG', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=15, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20160525, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'b09aec7e-2d18-474b-bae2-077d752f6147'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


