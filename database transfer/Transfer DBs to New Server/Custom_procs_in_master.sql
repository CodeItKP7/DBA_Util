USE [master]
GO

/****** Object:  StoredProcedure [dbo].[DatabaseBackup]    Script Date: 10/13/2021 12:39:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DatabaseBackup]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[DatabaseBackup] AS' 
END
GO

ALTER PROCEDURE [dbo].[DatabaseBackup]

@Databases nvarchar(max) = NULL,
@Directory nvarchar(max) = NULL,
@BackupType nvarchar(max),
@Verify nvarchar(max) = 'N',
@CleanupTime int = NULL,
@CleanupMode nvarchar(max) = 'AFTER_BACKUP',
@Compress nvarchar(max) = NULL,
@CopyOnly nvarchar(max) = 'N',
@ChangeBackupType nvarchar(max) = 'N',
@BackupSoftware nvarchar(max) = NULL,
@CheckSum nvarchar(max) = 'N',
@BlockSize int = NULL,
@BufferCount int = NULL,
@MaxTransferSize int = NULL,
@NumberOfFiles int = NULL,
@MinBackupSizeForMultipleFiles int = NULL,
@MaxFileSize int = NULL,
@CompressionLevel int = NULL,
@Description nvarchar(max) = NULL,
@Threads int = NULL,
@Throttle int = NULL,
@Encrypt nvarchar(max) = 'N',
@EncryptionAlgorithm nvarchar(max) = NULL,
@ServerCertificate nvarchar(max) = NULL,
@ServerAsymmetricKey nvarchar(max) = NULL,
@EncryptionKey nvarchar(max) = NULL,
@ReadWriteFileGroups nvarchar(max) = 'N',
@OverrideBackupPreference nvarchar(max) = 'N',
@NoRecovery nvarchar(max) = 'N',
@URL nvarchar(max) = NULL,
@Credential nvarchar(max) = NULL,
@MirrorDirectory nvarchar(max) = NULL,
@MirrorCleanupTime int = NULL,
@MirrorCleanupMode nvarchar(max) = 'AFTER_BACKUP',
@MirrorURL nvarchar(max) = NULL,
@AvailabilityGroups nvarchar(max) = NULL,
@Updateability nvarchar(max) = 'ALL',
@AdaptiveCompression nvarchar(max) = NULL,
@ModificationLevel int = NULL,
@LogSizeSinceLastLogBackup int = NULL,
@TimeSinceLastLogBackup int = NULL,
@DataDomainBoostHost nvarchar(max) = NULL,
@DataDomainBoostUser nvarchar(max) = NULL,
@DataDomainBoostDevicePath nvarchar(max) = NULL,
@DataDomainBoostLockboxPath nvarchar(max) = NULL,
@DirectoryStructure nvarchar(max) = '{ServerName}${InstanceName}{DirectorySeparator}{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}',
@AvailabilityGroupDirectoryStructure nvarchar(max) = '{ClusterName}${AvailabilityGroupName}{DirectorySeparator}{DatabaseName}{DirectorySeparator}{BackupType}_{Partial}_{CopyOnly}',
@FileName nvarchar(max) = '{ServerName}${InstanceName}_{DatabaseName}_{BackupType}_{Partial}_{CopyOnly}_{Year}{Month}{Day}_{Hour}{Minute}{Second}_{FileNumber}.{FileExtension}',
@AvailabilityGroupFileName nvarchar(max) = '{ClusterName}${AvailabilityGroupName}_{DatabaseName}_{BackupType}_{Partial}_{CopyOnly}_{Year}{Month}{Day}_{Hour}{Minute}{Second}_{FileNumber}.{FileExtension}',
@FileExtensionFull nvarchar(max) = NULL,
@FileExtensionDiff nvarchar(max) = NULL,
@FileExtensionLog nvarchar(max) = NULL,
@Init nvarchar(max) = 'N',
@Format nvarchar(max) = 'N',
@ObjectLevelRecoveryMap nvarchar(max) = 'N',
@ExcludeLogShippedFromLogBackup nvarchar(max) = 'Y',
@StringDelimiter nvarchar(max) = ',',
@DatabaseOrder nvarchar(max) = NULL,
@DatabasesInParallel nvarchar(max) = 'N',
@LogToTable nvarchar(max) = 'N',
@Execute nvarchar(max) = 'Y'

AS

BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source:  https://ola.hallengren.com                                                        //--
  --// License: https://ola.hallengren.com/license.html                                           //--
  --// GitHub:  https://github.com/olahallengren/sql-server-maintenance-solution                  //--
  --// Version: 2020-12-06 00:32:13                                                               //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @DatabaseMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)

  DECLARE @StartTime datetime2 = SYSDATETIME()
  DECLARE @SchemaName nvarchar(max) = OBJECT_SCHEMA_NAME(@@PROCID)
  DECLARE @ObjectName nvarchar(max) = OBJECT_NAME(@@PROCID)
  DECLARE @VersionTimestamp nvarchar(max) = SUBSTRING(OBJECT_DEFINITION(@@PROCID),CHARINDEX('--// Version: ',OBJECT_DEFINITION(@@PROCID)) + LEN('--// Version: ') + 1, 19)
  DECLARE @Parameters nvarchar(max)

  DECLARE @HostPlatform nvarchar(max)
  DECLARE @DirectorySeparator nvarchar(max)

  DECLARE @Updated bit

  DECLARE @Cluster nvarchar(max)

  DECLARE @DefaultDirectory nvarchar(4000)

  DECLARE @QueueID int
  DECLARE @QueueStartTime datetime2

  DECLARE @CurrentRootDirectoryID int
  DECLARE @CurrentRootDirectoryPath nvarchar(4000)

  DECLARE @CurrentDBID int
  DECLARE @CurrentDatabaseName nvarchar(max)

  DECLARE @CurrentDatabase_sp_executesql nvarchar(max)

  DECLARE @CurrentUserAccess nvarchar(max)
  DECLARE @CurrentIsReadOnly bit
  DECLARE @CurrentDatabaseState nvarchar(max)
  DECLARE @CurrentInStandby bit
  DECLARE @CurrentRecoveryModel nvarchar(max)
  DECLARE @CurrentDatabaseSize bigint

  DECLARE @CurrentIsEncrypted bit

  DECLARE @CurrentBackupType nvarchar(max)
  DECLARE @CurrentMaxTransferSize int
  DECLARE @CurrentNumberOfFiles int
  DECLARE @CurrentFileExtension nvarchar(max)
  DECLARE @CurrentFileNumber int
  DECLARE @CurrentDifferentialBaseLSN numeric(25,0)
  DECLARE @CurrentDifferentialBaseIsSnapshot bit
  DECLARE @CurrentLogLSN numeric(25,0)
  DECLARE @CurrentLatestBackup datetime2
  DECLARE @CurrentDatabaseNameFS nvarchar(max)
  DECLARE @CurrentDirectoryStructure nvarchar(max)
  DECLARE @CurrentDatabaseFileName nvarchar(max)
  DECLARE @CurrentMaxFilePathLength nvarchar(max)
  DECLARE @CurrentFileName nvarchar(max)
  DECLARE @CurrentDirectoryID int
  DECLARE @CurrentDirectoryPath nvarchar(max)
  DECLARE @CurrentFilePath nvarchar(max)
  DECLARE @CurrentDate datetime2
  DECLARE @CurrentCleanupDate datetime2
  DECLARE @CurrentIsDatabaseAccessible bit
  DECLARE @CurrentReplicaID uniqueidentifier
  DECLARE @CurrentAvailabilityGroupID uniqueidentifier
  DECLARE @CurrentAvailabilityGroup nvarchar(max)
  DECLARE @CurrentAvailabilityGroupRole nvarchar(max)
  DECLARE @CurrentAvailabilityGroupBackupPreference nvarchar(max)
  DECLARE @CurrentIsPreferredBackupReplica bit
  DECLARE @CurrentDatabaseMirroringRole nvarchar(max)
  DECLARE @CurrentLogShippingRole nvarchar(max)

  DECLARE @CurrentBackupSetID int
  DECLARE @CurrentIsMirror bit
  DECLARE @CurrentLastLogBackup datetime2
  DECLARE @CurrentLogSizeSinceLastLogBackup float
  DECLARE @CurrentAllocatedExtentPageCount bigint
  DECLARE @CurrentModifiedExtentPageCount bigint

  DECLARE @CurrentDatabaseContext nvarchar(max)
  DECLARE @CurrentCommand nvarchar(max)
  DECLARE @CurrentCommandOutput int
  DECLARE @CurrentCommandType nvarchar(max)

  DECLARE @Errors TABLE (ID int IDENTITY PRIMARY KEY,
                         [Message] nvarchar(max) NOT NULL,
                         Severity int NOT NULL,
                         [State] int)

  DECLARE @CurrentMessage nvarchar(max)
  DECLARE @CurrentSeverity int
  DECLARE @CurrentState int

  DECLARE @Directories TABLE (ID int PRIMARY KEY,
                              DirectoryPath nvarchar(max),
                              Mirror bit,
                              Completed bit)

  DECLARE @URLs TABLE (ID int PRIMARY KEY,
                       DirectoryPath nvarchar(max),
                       Mirror bit)

  DECLARE @DirectoryInfo TABLE (FileExists bit,
                                FileIsADirectory bit,
                                ParentDirectoryExists bit)

  DECLARE @tmpDatabases TABLE (ID int IDENTITY,
                               DatabaseName nvarchar(max),
                               DatabaseNameFS nvarchar(max),
                               DatabaseType nvarchar(max),
                               AvailabilityGroup bit,
                               StartPosition int,
                               DatabaseSize bigint,
                               LogSizeSinceLastLogBackup float,
                               [Order] int,
                               Selected bit,
                               Completed bit,
                               PRIMARY KEY(Selected, Completed, [Order], ID))

  DECLARE @tmpAvailabilityGroups TABLE (ID int IDENTITY PRIMARY KEY,
                                        AvailabilityGroupName nvarchar(max),
                                        StartPosition int,
                                        Selected bit)

  DECLARE @tmpDatabasesAvailabilityGroups TABLE (DatabaseName nvarchar(max),
                                                 AvailabilityGroupName nvarchar(max))

  DECLARE @SelectedDatabases TABLE (DatabaseName nvarchar(max),
                                    DatabaseType nvarchar(max),
                                    AvailabilityGroup nvarchar(max),
                                    StartPosition int,
                                    Selected bit)

  DECLARE @SelectedAvailabilityGroups TABLE (AvailabilityGroupName nvarchar(max),
                                             StartPosition int,
                                             Selected bit)

  DECLARE @CurrentBackupOutput bit

  DECLARE @CurrentBackupSet TABLE (ID int IDENTITY PRIMARY KEY,
                                   Mirror bit,
                                   VerifyCompleted bit,
                                   VerifyOutput int)

  DECLARE @CurrentDirectories TABLE (ID int PRIMARY KEY,
                                     DirectoryPath nvarchar(max),
                                     Mirror bit,
                                     DirectoryNumber int,
                                     CleanupDate datetime2,
                                     CleanupMode nvarchar(max),
                                     CreateCompleted bit,
                                     CleanupCompleted bit,
                                     CreateOutput int,
                                     CleanupOutput int)

  DECLARE @CurrentURLs TABLE (ID int PRIMARY KEY,
                              DirectoryPath nvarchar(max),
                              Mirror bit,
                              DirectoryNumber int)

  DECLARE @CurrentFiles TABLE ([Type] nvarchar(max),
                               FilePath nvarchar(max),
                               Mirror bit)

  DECLARE @CurrentCleanupDates TABLE (CleanupDate datetime2,
                                      Mirror bit)

  DECLARE @Error int = 0
  DECLARE @ReturnCode int = 0

  DECLARE @EmptyLine nvarchar(max) = CHAR(9)

  DECLARE @Version numeric(18,10) = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

  IF @Version >= 14
  BEGIN
    SELECT @HostPlatform = host_platform
    FROM sys.dm_os_host_info
  END
  ELSE
  BEGIN
    SET @HostPlatform = 'Windows'
  END

  DECLARE @AmazonRDS bit = CASE WHEN DB_ID('rdsadmin') IS NOT NULL AND SUSER_SNAME(0x01) = 'rdsa' THEN 1 ELSE 0 END

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------

  SET @Parameters = '@Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
  SET @Parameters += ', @Directory = ' + ISNULL('''' + REPLACE(@Directory,'''','''''') + '''','NULL')
  SET @Parameters += ', @BackupType = ' + ISNULL('''' + REPLACE(@BackupType,'''','''''') + '''','NULL')
  SET @Parameters += ', @Verify = ' + ISNULL('''' + REPLACE(@Verify,'''','''''') + '''','NULL')
  SET @Parameters += ', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL')
  SET @Parameters += ', @CleanupMode = ' + ISNULL('''' + REPLACE(@CleanupMode,'''','''''') + '''','NULL')
  SET @Parameters += ', @Compress = ' + ISNULL('''' + REPLACE(@Compress,'''','''''') + '''','NULL')
  SET @Parameters += ', @CopyOnly = ' + ISNULL('''' + REPLACE(@CopyOnly,'''','''''') + '''','NULL')
  SET @Parameters += ', @ChangeBackupType = ' + ISNULL('''' + REPLACE(@ChangeBackupType,'''','''''') + '''','NULL')
  SET @Parameters += ', @BackupSoftware = ' + ISNULL('''' + REPLACE(@BackupSoftware,'''','''''') + '''','NULL')
  SET @Parameters += ', @CheckSum = ' + ISNULL('''' + REPLACE(@CheckSum,'''','''''') + '''','NULL')
  SET @Parameters += ', @BlockSize = ' + ISNULL(CAST(@BlockSize AS nvarchar),'NULL')
  SET @Parameters += ', @BufferCount = ' + ISNULL(CAST(@BufferCount AS nvarchar),'NULL')
  SET @Parameters += ', @MaxTransferSize = ' + ISNULL(CAST(@MaxTransferSize AS nvarchar),'NULL')
  SET @Parameters += ', @NumberOfFiles = ' + ISNULL(CAST(@NumberOfFiles AS nvarchar),'NULL')
  SET @Parameters += ', @MinBackupSizeForMultipleFiles = ' + ISNULL(CAST(@MinBackupSizeForMultipleFiles AS nvarchar),'NULL')
  SET @Parameters += ', @MaxFileSize = ' + ISNULL(CAST(@MaxFileSize AS nvarchar),'NULL')
  SET @Parameters += ', @CompressionLevel = ' + ISNULL(CAST(@CompressionLevel AS nvarchar),'NULL')
  SET @Parameters += ', @Description = ' + ISNULL('''' + REPLACE(@Description,'''','''''') + '''','NULL')
  SET @Parameters += ', @Threads = ' + ISNULL(CAST(@Threads AS nvarchar),'NULL')
  SET @Parameters += ', @Throttle = ' + ISNULL(CAST(@Throttle AS nvarchar),'NULL')
  SET @Parameters += ', @Encrypt = ' + ISNULL('''' + REPLACE(@Encrypt,'''','''''') + '''','NULL')
  SET @Parameters += ', @EncryptionAlgorithm = ' + ISNULL('''' + REPLACE(@EncryptionAlgorithm,'''','''''') + '''','NULL')
  SET @Parameters += ', @ServerCertificate = ' + ISNULL('''' + REPLACE(@ServerCertificate,'''','''''') + '''','NULL')
  SET @Parameters += ', @ServerAsymmetricKey = ' + ISNULL('''' + REPLACE(@ServerAsymmetricKey,'''','''''') + '''','NULL')
  SET @Parameters += ', @EncryptionKey = ' + ISNULL('''' + REPLACE(@EncryptionKey,'''','''''') + '''','NULL')
  SET @Parameters += ', @ReadWriteFileGroups = ' + ISNULL('''' + REPLACE(@ReadWriteFileGroups,'''','''''') + '''','NULL')
  SET @Parameters += ', @OverrideBackupPreference = ' + ISNULL('''' + REPLACE(@OverrideBackupPreference,'''','''''') + '''','NULL')
  SET @Parameters += ', @NoRecovery = ' + ISNULL('''' + REPLACE(@NoRecovery,'''','''''') + '''','NULL')
  SET @Parameters += ', @URL = ' + ISNULL('''' + REPLACE(@URL,'''','''''') + '''','NULL')
  SET @Parameters += ', @Credential = ' + ISNULL('''' + REPLACE(@Credential,'''','''''') + '''','NULL')
  SET @Parameters += ', @MirrorDirectory = ' + ISNULL('''' + REPLACE(@MirrorDirectory,'''','''''') + '''','NULL')
  SET @Parameters += ', @MirrorCleanupTime = ' + ISNULL(CAST(@MirrorCleanupTime AS nvarchar),'NULL')
  SET @Parameters += ', @MirrorCleanupMode = ' + ISNULL('''' + REPLACE(@MirrorCleanupMode,'''','''''') + '''','NULL')
  SET @Parameters += ', @MirrorURL = ' + ISNULL('''' + REPLACE(@MirrorURL,'''','''''') + '''','NULL')
  SET @Parameters += ', @AvailabilityGroups = ' + ISNULL('''' + REPLACE(@AvailabilityGroups,'''','''''') + '''','NULL')
  SET @Parameters += ', @Updateability = ' + ISNULL('''' + REPLACE(@Updateability,'''','''''') + '''','NULL')
  SET @Parameters += ', @AdaptiveCompression = ' + ISNULL('''' + REPLACE(@AdaptiveCompression,'''','''''') + '''','NULL')
  SET @Parameters += ', @ModificationLevel = ' + ISNULL(CAST(@ModificationLevel AS nvarchar),'NULL')
  SET @Parameters += ', @LogSizeSinceLastLogBackup = ' + ISNULL(CAST(@LogSizeSinceLastLogBackup AS nvarchar),'NULL')
  SET @Parameters += ', @TimeSinceLastLogBackup = ' + ISNULL(CAST(@TimeSinceLastLogBackup AS nvarchar),'NULL')
  SET @Parameters += ', @DataDomainBoostHost = ' + ISNULL('''' + REPLACE(@DataDomainBoostHost,'''','''''') + '''','NULL')
  SET @Parameters += ', @DataDomainBoostUser = ' + ISNULL('''' + REPLACE(@DataDomainBoostUser,'''','''''') + '''','NULL')
  SET @Parameters += ', @DataDomainBoostDevicePath = ' + ISNULL('''' + REPLACE(@DataDomainBoostDevicePath,'''','''''') + '''','NULL')
  SET @Parameters += ', @DataDomainBoostLockboxPath = ' + ISNULL('''' + REPLACE(@DataDomainBoostLockboxPath,'''','''''') + '''','NULL')
  SET @Parameters += ', @DirectoryStructure = ' + ISNULL('''' + REPLACE(@DirectoryStructure,'''','''''') + '''','NULL')
  SET @Parameters += ', @AvailabilityGroupDirectoryStructure = ' + ISNULL('''' + REPLACE(@AvailabilityGroupDirectoryStructure,'''','''''') + '''','NULL')
  SET @Parameters += ', @FileName = ' + ISNULL('''' + REPLACE(@FileName,'''','''''') + '''','NULL')
  SET @Parameters += ', @AvailabilityGroupFileName = ' + ISNULL('''' + REPLACE(@AvailabilityGroupFileName,'''','''''') + '''','NULL')
  SET @Parameters += ', @FileExtensionFull = ' + ISNULL('''' + REPLACE(@FileExtensionFull,'''','''''') + '''','NULL')
  SET @Parameters += ', @FileExtensionDiff = ' + ISNULL('''' + REPLACE(@FileExtensionDiff,'''','''''') + '''','NULL')
  SET @Parameters += ', @FileExtensionLog = ' + ISNULL('''' + REPLACE(@FileExtensionLog,'''','''''') + '''','NULL')
  SET @Parameters += ', @Init = ' + ISNULL('''' + REPLACE(@Init,'''','''''') + '''','NULL')
  SET @Parameters += ', @Format = ' + ISNULL('''' + REPLACE(@Format,'''','''''') + '''','NULL')
  SET @Parameters += ', @ObjectLevelRecoveryMap = ' + ISNULL('''' + REPLACE(@ObjectLevelRecoveryMap,'''','''''') + '''','NULL')
  SET @Parameters += ', @ExcludeLogShippedFromLogBackup = ' + ISNULL('''' + REPLACE(@ExcludeLogShippedFromLogBackup,'''','''''') + '''','NULL')
  SET @Parameters += ', @StringDelimiter = ' + ISNULL('''' + REPLACE(@StringDelimiter,'''','''''') + '''','NULL')
  SET @Parameters += ', @DatabaseOrder = ' + ISNULL('''' + REPLACE(@DatabaseOrder,'''','''''') + '''','NULL')
  SET @Parameters += ', @DatabasesInParallel = ' + ISNULL('''' + REPLACE(@DatabasesInParallel,'''','''''') + '''','NULL')
  SET @Parameters += ', @LogToTable = ' + ISNULL('''' + REPLACE(@LogToTable,'''','''''') + '''','NULL')
  SET @Parameters += ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL')

  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,@StartTime,120)
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Platform: ' + @HostPlatform
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName)
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Parameters: ' + @Parameters
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Version: ' + @VersionTimestamp
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Source: https://ola.hallengren.com'
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  RAISERROR(@EmptyLine,10,1) WITH NOWAIT

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF NOT (SELECT [compatibility_level] FROM sys.databases WHERE database_id = DB_ID()) >= 90
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The database ' + QUOTENAME(DB_NAME(DB_ID())) + ' has to be in compatibility level 90 or higher.', 16, 1
  END

  IF NOT (SELECT uses_ansi_nulls FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'ANSI_NULLS has to be set to ON for the stored procedure.', 16, 1
  END

  IF NOT (SELECT uses_quoted_identifier FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'QUOTED_IDENTIFIER has to be set to ON for the stored procedure.', 16, 1
  END

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure CommandExecute is missing. Download https://ola.hallengren.com/scripts/CommandExecute.sql.', 16, 1
  END

  IF EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute' AND OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@DatabaseContext%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure CommandExecute needs to be updated. Download https://ola.hallengren.com/scripts/CommandExecute.sql.', 16, 1
  END

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table CommandLog is missing. Download https://ola.hallengren.com/scripts/CommandLog.sql.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'Queue')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table Queue is missing. Download https://ola.hallengren.com/scripts/Queue.sql.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'QueueDatabase')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table QueueDatabase is missing. Download https://ola.hallengren.com/scripts/QueueDatabase.sql.', 16, 1
  END

  IF @@TRANCOUNT <> 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The transaction count is not 0.', 16, 1
  END

  IF @AmazonRDS = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure DatabaseBackup is not supported on Amazon RDS.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select databases                                                                           //--
  ----------------------------------------------------------------------------------------------------

  SET @Databases = REPLACE(@Databases, CHAR(10), '')
  SET @Databases = REPLACE(@Databases, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @Databases) > 0 SET @Databases = REPLACE(@Databases, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @Databases) > 0 SET @Databases = REPLACE(@Databases, ' ' + @StringDelimiter, @StringDelimiter)

  SET @Databases = LTRIM(RTRIM(@Databases));

  WITH Databases1 (StartPosition, EndPosition, DatabaseItem) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, 1), 0), LEN(@Databases) + 1) AS EndPosition,
         SUBSTRING(@Databases, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, 1), 0), LEN(@Databases) + 1) - 1) AS DatabaseItem
  WHERE @Databases IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) AS EndPosition,
         SUBSTRING(@Databases, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) - EndPosition - 1) AS DatabaseItem
  FROM Databases1
  WHERE EndPosition < LEN(@Databases) + 1
  ),
  Databases2 (DatabaseItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem LIKE '-%' THEN RIGHT(DatabaseItem,LEN(DatabaseItem) - 1) ELSE DatabaseItem END AS DatabaseItem,
         StartPosition,
         CASE WHEN DatabaseItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Databases1
  ),
  Databases3 (DatabaseItem, DatabaseType, AvailabilityGroup, StartPosition, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem IN('ALL_DATABASES','SYSTEM_DATABASES','USER_DATABASES','AVAILABILITY_GROUP_DATABASES') THEN '%' ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem = 'SYSTEM_DATABASES' THEN 'S' WHEN DatabaseItem = 'USER_DATABASES' THEN 'U' ELSE NULL END AS DatabaseType,
         CASE WHEN DatabaseItem = 'AVAILABILITY_GROUP_DATABASES' THEN 1 ELSE NULL END AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases2
  ),
  Databases4 (DatabaseName, DatabaseType, AvailabilityGroup, StartPosition, Selected) AS
  (
  SELECT CASE WHEN LEFT(DatabaseItem,1) = '[' AND RIGHT(DatabaseItem,1) = ']' THEN PARSENAME(DatabaseItem,1) ELSE DatabaseItem END AS DatabaseItem,
         DatabaseType,
         AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases3
  )
  INSERT INTO @SelectedDatabases (DatabaseName, DatabaseType, AvailabilityGroup, StartPosition, Selected)
  SELECT DatabaseName,
         DatabaseType,
         AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases4
  OPTION (MAXRECURSION 0)

  IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN
    INSERT INTO @tmpAvailabilityGroups (AvailabilityGroupName, Selected)
    SELECT name AS AvailabilityGroupName,
           0 AS Selected
    FROM sys.availability_groups

    INSERT INTO @tmpDatabasesAvailabilityGroups (DatabaseName, AvailabilityGroupName)
    SELECT databases.name,
           availability_groups.name
    FROM sys.databases databases
    INNER JOIN sys.availability_replicas availability_replicas ON databases.replica_id = availability_replicas.replica_id
    INNER JOIN sys.availability_groups availability_groups ON availability_replicas.group_id = availability_groups.group_id
  END

  INSERT INTO @tmpDatabases (DatabaseName, DatabaseNameFS, DatabaseType, AvailabilityGroup, [Order], Selected, Completed)
  SELECT [name] AS DatabaseName,
         RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([name],'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|','')) AS DatabaseNameFS,
         CASE WHEN name IN('master','msdb','model') OR is_distributor = 1 THEN 'S' ELSE 'U' END AS DatabaseType,
         NULL AS AvailabilityGroup,
         0 AS [Order],
         0 AS Selected,
         0 AS Completed
  FROM sys.databases
  WHERE [name] <> 'tempdb'
  AND source_database_id IS NULL
  ORDER BY [name] ASC

  UPDATE tmpDatabases
  SET AvailabilityGroup = CASE WHEN EXISTS (SELECT * FROM @tmpDatabasesAvailabilityGroups WHERE DatabaseName = tmpDatabases.DatabaseName) THEN 1 ELSE 0 END
  FROM @tmpDatabases tmpDatabases

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
  WHERE SelectedDatabases.Selected = 1

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
  WHERE SelectedDatabases.Selected = 0

  UPDATE tmpDatabases
  SET tmpDatabases.StartPosition = SelectedDatabases2.StartPosition
  FROM @tmpDatabases tmpDatabases
  INNER JOIN (SELECT tmpDatabases.DatabaseName, MIN(SelectedDatabases.StartPosition) AS StartPosition
              FROM @tmpDatabases tmpDatabases
              INNER JOIN @SelectedDatabases SelectedDatabases
              ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
              AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
              AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
              WHERE SelectedDatabases.Selected = 1
              GROUP BY tmpDatabases.DatabaseName) SelectedDatabases2
  ON tmpDatabases.DatabaseName = SelectedDatabases2.DatabaseName

  IF @Databases IS NOT NULL AND (NOT EXISTS(SELECT * FROM @SelectedDatabases) OR EXISTS(SELECT * FROM @SelectedDatabases WHERE DatabaseName IS NULL OR DatabaseName = ''))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Databases is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select availability groups                                                                 //--
  ----------------------------------------------------------------------------------------------------

  IF @AvailabilityGroups IS NOT NULL AND @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN

    SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, CHAR(10), '')
    SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, CHAR(13), '')

    WHILE CHARINDEX(@StringDelimiter + ' ', @AvailabilityGroups) > 0 SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, @StringDelimiter + ' ', @StringDelimiter)
    WHILE CHARINDEX(' ' + @StringDelimiter, @AvailabilityGroups) > 0 SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, ' ' + @StringDelimiter, @StringDelimiter)

    SET @AvailabilityGroups = LTRIM(RTRIM(@AvailabilityGroups));

    WITH AvailabilityGroups1 (StartPosition, EndPosition, AvailabilityGroupItem) AS
    (
    SELECT 1 AS StartPosition,
           ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, 1), 0), LEN(@AvailabilityGroups) + 1) AS EndPosition,
           SUBSTRING(@AvailabilityGroups, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, 1), 0), LEN(@AvailabilityGroups) + 1) - 1) AS AvailabilityGroupItem
    WHERE @AvailabilityGroups IS NOT NULL
    UNION ALL
    SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
           ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, EndPosition + 1), 0), LEN(@AvailabilityGroups) + 1) AS EndPosition,
           SUBSTRING(@AvailabilityGroups, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, EndPosition + 1), 0), LEN(@AvailabilityGroups) + 1) - EndPosition - 1) AS AvailabilityGroupItem
    FROM AvailabilityGroups1
    WHERE EndPosition < LEN(@AvailabilityGroups) + 1
    ),
    AvailabilityGroups2 (AvailabilityGroupItem, StartPosition, Selected) AS
    (
    SELECT CASE WHEN AvailabilityGroupItem LIKE '-%' THEN RIGHT(AvailabilityGroupItem,LEN(AvailabilityGroupItem) - 1) ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           CASE WHEN AvailabilityGroupItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
    FROM AvailabilityGroups1
    ),
    AvailabilityGroups3 (AvailabilityGroupItem, StartPosition, Selected) AS
    (
    SELECT CASE WHEN AvailabilityGroupItem = 'ALL_AVAILABILITY_GROUPS' THEN '%' ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           Selected
    FROM AvailabilityGroups2
    ),
    AvailabilityGroups4 (AvailabilityGroupName, StartPosition, Selected) AS
    (
    SELECT CASE WHEN LEFT(AvailabilityGroupItem,1) = '[' AND RIGHT(AvailabilityGroupItem,1) = ']' THEN PARSENAME(AvailabilityGroupItem,1) ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           Selected
    FROM AvailabilityGroups3
    )
    INSERT INTO @SelectedAvailabilityGroups (AvailabilityGroupName, StartPosition, Selected)
    SELECT AvailabilityGroupName, StartPosition, Selected
    FROM AvailabilityGroups4
    OPTION (MAXRECURSION 0)

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.Selected = SelectedAvailabilityGroups.Selected
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
    ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
    WHERE SelectedAvailabilityGroups.Selected = 1

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.Selected = SelectedAvailabilityGroups.Selected
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
    ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
    WHERE SelectedAvailabilityGroups.Selected = 0

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.StartPosition = SelectedAvailabilityGroups2.StartPosition
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN (SELECT tmpAvailabilityGroups.AvailabilityGroupName, MIN(SelectedAvailabilityGroups.StartPosition) AS StartPosition
                FROM @tmpAvailabilityGroups tmpAvailabilityGroups
                INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
                ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
                WHERE SelectedAvailabilityGroups.Selected = 1
                GROUP BY tmpAvailabilityGroups.AvailabilityGroupName) SelectedAvailabilityGroups2
    ON tmpAvailabilityGroups.AvailabilityGroupName = SelectedAvailabilityGroups2.AvailabilityGroupName

    UPDATE tmpDatabases
    SET tmpDatabases.StartPosition = tmpAvailabilityGroups.StartPosition,
        tmpDatabases.Selected = 1
    FROM @tmpDatabases tmpDatabases
    INNER JOIN @tmpDatabasesAvailabilityGroups tmpDatabasesAvailabilityGroups ON tmpDatabases.DatabaseName = tmpDatabasesAvailabilityGroups.DatabaseName
    INNER JOIN @tmpAvailabilityGroups tmpAvailabilityGroups ON tmpDatabasesAvailabilityGroups.AvailabilityGroupName = tmpAvailabilityGroups.AvailabilityGroupName
    WHERE tmpAvailabilityGroups.Selected = 1

  END

  IF @AvailabilityGroups IS NOT NULL AND (NOT EXISTS(SELECT * FROM @SelectedAvailabilityGroups) OR EXISTS(SELECT * FROM @SelectedAvailabilityGroups WHERE AvailabilityGroupName IS NULL OR AvailabilityGroupName = '') OR @Version < 11 OR SERVERPROPERTY('IsHadrEnabled') = 0)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroups is not supported.', 16, 1
  END

  IF (@Databases IS NULL AND @AvailabilityGroups IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You need to specify one of the parameters @Databases and @AvailabilityGroups.', 16, 2
  END

  IF (@Databases IS NOT NULL AND @AvailabilityGroups IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You can only specify one of the parameters @Databases and @AvailabilityGroups.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------
  --// Check database names                                                                       //--
  ----------------------------------------------------------------------------------------------------

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @tmpDatabases
  WHERE Selected = 1
  AND DatabaseNameFS = ''
  ORDER BY DatabaseName ASC
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The names of the following databases are not supported: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 16, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @tmpDatabases
  WHERE UPPER(DatabaseNameFS) IN(SELECT UPPER(DatabaseNameFS) FROM @tmpDatabases GROUP BY UPPER(DatabaseNameFS) HAVING COUNT(*) > 1)
  AND UPPER(DatabaseNameFS) IN(SELECT UPPER(DatabaseNameFS) FROM @tmpDatabases WHERE Selected = 1)
  AND DatabaseNameFS <> ''
  ORDER BY DatabaseName ASC
  OPTION (RECOMPILE)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The names of the following databases are not unique in the file system: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select default directory                                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @Directory IS NULL AND @URL IS NULL AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
  BEGIN
    IF @Version >= 15
    BEGIN
      SET @DefaultDirectory = CAST(SERVERPROPERTY('InstanceDefaultBackupPath') AS nvarchar(max))
    END
    ELSE
    BEGIN
      EXECUTE [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @DefaultDirectory OUTPUT
    END

    IF @DefaultDirectory LIKE 'http://%' OR @DefaultDirectory LIKE 'https://%'
    BEGIN
      SET @URL = @DefaultDirectory
    END
    ELSE
    BEGIN
      INSERT INTO @Directories (ID, DirectoryPath, Mirror, Completed)
      SELECT 1, @DefaultDirectory, 0, 0
    END
  END

  ----------------------------------------------------------------------------------------------------
  --// Select directories                                                                         //--
  ----------------------------------------------------------------------------------------------------

  SET @Directory = REPLACE(@Directory, CHAR(10), '')
  SET @Directory = REPLACE(@Directory, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @Directory) > 0 SET @Directory = REPLACE(@Directory, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @Directory) > 0 SET @Directory = REPLACE(@Directory, ' ' + @StringDelimiter, @StringDelimiter)

  SET @Directory = LTRIM(RTRIM(@Directory));

  WITH Directories (StartPosition, EndPosition, Directory) AS
  (
  SELECT 1 AS StartPosition,
          ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Directory, 1), 0), LEN(@Directory) + 1) AS EndPosition,
          SUBSTRING(@Directory, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Directory, 1), 0), LEN(@Directory) + 1) - 1) AS Directory
  WHERE @Directory IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
          ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Directory, EndPosition + 1), 0), LEN(@Directory) + 1) AS EndPosition,
          SUBSTRING(@Directory, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Directory, EndPosition + 1), 0), LEN(@Directory) + 1) - EndPosition - 1) AS Directory
  FROM Directories
  WHERE EndPosition < LEN(@Directory) + 1
  )
  INSERT INTO @Directories (ID, DirectoryPath, Mirror, Completed)
  SELECT ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS ID,
          Directory,
          0,
          0
  FROM Directories
  OPTION (MAXRECURSION 0)

  SET @MirrorDirectory = REPLACE(@MirrorDirectory, CHAR(10), '')
  SET @MirrorDirectory = REPLACE(@MirrorDirectory, CHAR(13), '')

  WHILE CHARINDEX(', ',@MirrorDirectory) > 0 SET @MirrorDirectory = REPLACE(@MirrorDirectory,', ',',')
  WHILE CHARINDEX(' ,',@MirrorDirectory) > 0 SET @MirrorDirectory = REPLACE(@MirrorDirectory,' ,',',')

  SET @MirrorDirectory = LTRIM(RTRIM(@MirrorDirectory));

  WITH Directories (StartPosition, EndPosition, Directory) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorDirectory, 1), 0), LEN(@MirrorDirectory) + 1) AS EndPosition,
         SUBSTRING(@MirrorDirectory, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorDirectory, 1), 0), LEN(@MirrorDirectory) + 1) - 1) AS Directory
  WHERE @MirrorDirectory IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorDirectory, EndPosition + 1), 0), LEN(@MirrorDirectory) + 1) AS EndPosition,
         SUBSTRING(@MirrorDirectory, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorDirectory, EndPosition + 1), 0), LEN(@MirrorDirectory) + 1) - EndPosition - 1) AS Directory
  FROM Directories
  WHERE EndPosition < LEN(@MirrorDirectory) + 1
  )
  INSERT INTO @Directories (ID, DirectoryPath, Mirror, Completed)
  SELECT (SELECT COUNT(*) FROM @Directories) + ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS ID,
         Directory,
         1,
         0
  FROM Directories
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Check directories                                                                          //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM @Directories WHERE Mirror = 0 AND (NOT (DirectoryPath LIKE '_:' OR DirectoryPath LIKE '_:\%' OR DirectoryPath LIKE '\\%\%' OR (DirectoryPath LIKE '/%/%' AND @HostPlatform = 'Linux') OR DirectoryPath = 'NUL') OR DirectoryPath IS NULL OR LEFT(DirectoryPath,1) = ' ' OR RIGHT(DirectoryPath,1) = ' '))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Directory is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @Directories GROUP BY DirectoryPath HAVING COUNT(*) <> 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Directory is not supported.', 16, 2
  END

  IF (SELECT COUNT(*) FROM @Directories WHERE Mirror = 0) <> (SELECT COUNT(*) FROM @Directories WHERE Mirror = 1) AND (SELECT COUNT(*) FROM @Directories WHERE Mirror = 1) > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Directory is not supported.', 16, 3
  END

  IF (@Directory IS NOT NULL AND SERVERPROPERTY('EngineEdition') = 8) OR (@Directory IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Directory is not supported.', 16, 4
  END

  IF EXISTS (SELECT * FROM @Directories WHERE Mirror = 0 AND DirectoryPath = 'NUL') AND EXISTS(SELECT * FROM @Directories WHERE Mirror = 0 AND DirectoryPath <> 'NUL')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Directory is not supported.', 16, 5
  END

  IF EXISTS (SELECT * FROM @Directories WHERE Mirror = 0 AND DirectoryPath = 'NUL') AND EXISTS(SELECT * FROM @Directories WHERE Mirror = 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Directory is not supported.', 16, 6
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @Directories WHERE Mirror = 1 AND (NOT (DirectoryPath LIKE '_:' OR DirectoryPath LIKE '_:\%' OR DirectoryPath LIKE '\\%\%' OR (DirectoryPath LIKE '/%/%' AND @HostPlatform = 'Linux')) OR DirectoryPath IS NULL OR LEFT(DirectoryPath,1) = ' ' OR RIGHT(DirectoryPath,1) = ' '))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @Directories GROUP BY DirectoryPath HAVING COUNT(*) <> 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 2
  END

  IF (SELECT COUNT(*) FROM @Directories WHERE Mirror = 0) <> (SELECT COUNT(*) FROM @Directories WHERE Mirror = 1) AND (SELECT COUNT(*) FROM @Directories WHERE Mirror = 1) > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 3
  END

  IF @BackupSoftware IN('SQLBACKUP','SQLSAFE') AND (SELECT COUNT(*) FROM @Directories WHERE Mirror = 1) > 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 4
  END

  IF @MirrorDirectory IS NOT NULL AND SERVERPROPERTY('EngineEdition') = 8
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 5
  END

  IF @MirrorDirectory IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 6
  END

  IF EXISTS(SELECT * FROM @Directories WHERE Mirror = 0 AND DirectoryPath = 'NUL') AND EXISTS(SELECT * FROM @Directories WHERE Mirror = 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported.', 16, 7
  END

  IF (@BackupSoftware IS NULL AND EXISTS(SELECT * FROM @Directories WHERE Mirror = 1) AND SERVERPROPERTY('EngineEdition') <> 3)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorDirectory is not supported. Mirrored backup to disk is only available in Enterprise and Developer Edition.', 16, 8
  END

  ----------------------------------------------------------------------------------------------------

  IF NOT EXISTS (SELECT * FROM @Errors WHERE Severity >= 16)
  BEGIN
    WHILE (1 = 1)
    BEGIN
      SELECT TOP 1 @CurrentRootDirectoryID = ID,
                   @CurrentRootDirectoryPath = DirectoryPath
      FROM @Directories
      WHERE Completed = 0
      AND DirectoryPath <> 'NUL'
      ORDER BY ID ASC

      IF @@ROWCOUNT = 0
      BEGIN
        BREAK
      END

      INSERT INTO @DirectoryInfo (FileExists, FileIsADirectory, ParentDirectoryExists)
      EXECUTE [master].dbo.xp_fileexist @CurrentRootDirectoryPath

      IF NOT EXISTS (SELECT * FROM @DirectoryInfo WHERE FileExists = 0 AND FileIsADirectory = 1 AND ParentDirectoryExists = 1)
      BEGIN
        INSERT INTO @Errors ([Message], Severity, [State])
        SELECT 'The directory ' + @CurrentRootDirectoryPath + ' does not exist.', 16, 1
      END

      UPDATE @Directories
      SET Completed = 1
      WHERE ID = @CurrentRootDirectoryID

      SET @CurrentRootDirectoryID = NULL
      SET @CurrentRootDirectoryPath = NULL

      DELETE FROM @DirectoryInfo
    END
  END

  ----------------------------------------------------------------------------------------------------
  --// Select URLs                                                                                //--
  ----------------------------------------------------------------------------------------------------

  SET @URL = REPLACE(@URL, CHAR(10), '')
  SET @URL = REPLACE(@URL, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @URL) > 0 SET @URL = REPLACE(@URL, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @URL) > 0 SET @URL = REPLACE(@URL, ' ' + @StringDelimiter, @StringDelimiter)

  SET @URL = LTRIM(RTRIM(@URL));

  WITH URLs (StartPosition, EndPosition, [URL]) AS
  (
  SELECT 1 AS StartPosition,
          ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @URL, 1), 0), LEN(@URL) + 1) AS EndPosition,
          SUBSTRING(@URL, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @URL, 1), 0), LEN(@URL) + 1) - 1) AS [URL]
  WHERE @URL IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
          ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @URL, EndPosition + 1), 0), LEN(@URL) + 1) AS EndPosition,
          SUBSTRING(@URL, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @URL, EndPosition + 1), 0), LEN(@URL) + 1) - EndPosition - 1) AS [URL]
  FROM URLs
  WHERE EndPosition < LEN(@URL) + 1
  )
  INSERT INTO @URLs (ID, DirectoryPath, Mirror)
  SELECT ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS ID,
          [URL],
          0
  FROM URLs
  OPTION (MAXRECURSION 0)

  SET @MirrorURL = REPLACE(@MirrorURL, CHAR(10), '')
  SET @MirrorURL = REPLACE(@MirrorURL, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @MirrorURL) > 0 SET @MirrorURL = REPLACE(@MirrorURL, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter ,@MirrorURL) > 0 SET @MirrorURL = REPLACE(@MirrorURL, ' ' + @StringDelimiter, @StringDelimiter)

  SET @MirrorURL = LTRIM(RTRIM(@MirrorURL));

  WITH URLs (StartPosition, EndPosition, [URL]) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorURL, 1), 0), LEN(@MirrorURL) + 1) AS EndPosition,
         SUBSTRING(@MirrorURL, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorURL, 1), 0), LEN(@MirrorURL) + 1) - 1) AS [URL]
  WHERE @MirrorURL IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorURL, EndPosition + 1), 0), LEN(@MirrorURL) + 1) AS EndPosition,
         SUBSTRING(@MirrorURL, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @MirrorURL, EndPosition + 1), 0), LEN(@MirrorURL) + 1) - EndPosition - 1) AS [URL]
  FROM URLs
  WHERE EndPosition < LEN(@MirrorURL) + 1
  )
  INSERT INTO @URLs (ID, DirectoryPath, Mirror)
  SELECT (SELECT COUNT(*) FROM @URLs) + ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS ID,
         [URL],
         1
  FROM URLs
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Check URLs                                                                          //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @URLs WHERE Mirror = 0 AND DirectoryPath NOT LIKE 'https://%/%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @URLs GROUP BY DirectoryPath HAVING COUNT(*) <> 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 2
  END

  IF (SELECT COUNT(*) FROM @URLs WHERE Mirror = 0) <> (SELECT COUNT(*) FROM @URLs WHERE Mirror = 1) AND (SELECT COUNT(*) FROM @URLs WHERE Mirror = 1) > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @URLs WHERE Mirror = 1 AND DirectoryPath NOT LIKE 'https://%/%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @URLs GROUP BY DirectoryPath HAVING COUNT(*) <> 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 2
  END

  IF (SELECT COUNT(*) FROM @URLs WHERE Mirror = 0) <> (SELECT COUNT(*) FROM @URLs WHERE Mirror = 1) AND (SELECT COUNT(*) FROM @URLs WHERE Mirror = 1) > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------
  --// Get directory separator                                                                   //--
  ----------------------------------------------------------------------------------------------------

  SELECT @DirectorySeparator = CASE
  WHEN @URL IS NOT NULL THEN '/'
  WHEN @HostPlatform = 'Windows' THEN '\'
  WHEN @HostPlatform = 'Linux' THEN '/'
  END

  UPDATE @Directories
  SET DirectoryPath = LEFT(DirectoryPath,LEN(DirectoryPath) - 1)
  WHERE RIGHT(DirectoryPath,1) = @DirectorySeparator

  UPDATE @URLs
  SET DirectoryPath = LEFT(DirectoryPath,LEN(DirectoryPath) - 1)
  WHERE RIGHT(DirectoryPath,1) = @DirectorySeparator

  ----------------------------------------------------------------------------------------------------
  --// Get file extension                                                                         //--
  ----------------------------------------------------------------------------------------------------

  IF @FileExtensionFull IS NULL
  BEGIN
    SELECT @FileExtensionFull = CASE
    WHEN @BackupSoftware IS NULL THEN 'bak'
    WHEN @BackupSoftware = 'LITESPEED' THEN 'bak'
    WHEN @BackupSoftware = 'SQLBACKUP' THEN 'sqb'
    WHEN @BackupSoftware = 'SQLSAFE' THEN 'safe'
    END
  END

  IF @FileExtensionDiff IS NULL
  BEGIN
    SELECT @FileExtensionDiff = CASE
    WHEN @BackupSoftware IS NULL THEN 'bak'
    WHEN @BackupSoftware = 'LITESPEED' THEN 'bak'
    WHEN @BackupSoftware = 'SQLBACKUP' THEN 'sqb'
    WHEN @BackupSoftware = 'SQLSAFE' THEN 'safe'
    END
  END

  IF @FileExtensionLog IS NULL
  BEGIN
    SELECT @FileExtensionLog = CASE
    WHEN @BackupSoftware IS NULL THEN 'trn'
    WHEN @BackupSoftware = 'LITESPEED' THEN 'trn'
    WHEN @BackupSoftware = 'SQLBACKUP' THEN 'sqb'
    WHEN @BackupSoftware = 'SQLSAFE' THEN 'safe'
    END
  END

  ----------------------------------------------------------------------------------------------------
  --// Get default compression                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF @Compress IS NULL
  BEGIN
    SELECT @Compress = CASE WHEN @BackupSoftware IS NULL AND EXISTS(SELECT * FROM sys.configurations WHERE name = 'backup compression default' AND value_in_use = 1) THEN 'Y'
                            WHEN @BackupSoftware IS NULL AND NOT EXISTS(SELECT * FROM sys.configurations WHERE name = 'backup compression default' AND value_in_use = 1) THEN 'N'
                            WHEN @BackupSoftware IS NOT NULL AND (@CompressionLevel IS NULL OR @CompressionLevel > 0)  THEN 'Y'
                            WHEN @BackupSoftware IS NOT NULL AND @CompressionLevel = 0  THEN 'N' END
  END

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF @BackupType NOT IN ('FULL','DIFF','LOG') OR @BackupType IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BackupType is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF SERVERPROPERTY('EngineEdition') = 8 AND NOT (@BackupType = 'FULL' AND @CopyOnly = 'Y')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'SQL Database Managed Instance only supports COPY_ONLY full backups.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Verify NOT IN ('Y','N') OR @Verify IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Verify is not supported.', 16, 1
  END

  IF @BackupSoftware = 'SQLSAFE' AND @Encrypt = 'Y' AND @Verify = 'Y'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Verify is not supported. Verify is not supported with encrypted backups with Idera SQL Safe Backup', 16, 2
  END

  IF @Verify = 'Y' AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Verify is not supported. Verify is not supported with Data Domain Boost', 16, 3
  END

  IF @Verify = 'Y' AND EXISTS(SELECT * FROM @Directories WHERE DirectoryPath = 'NUL')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Verify is not supported. Verify is not supported when backing up to NUL.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @CleanupTime < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupTime is not supported.', 16, 1
  END

  IF @CleanupTime IS NOT NULL AND @URL IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupTime is not supported. Cleanup is not supported on Azure Blob Storage.', 16, 2
  END

  IF @CleanupTime IS NOT NULL AND EXISTS(SELECT * FROM @Directories WHERE DirectoryPath = 'NUL')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupTime is not supported. Cleanup is not supported when backing up to NUL.', 16, 4
  END

  IF @CleanupTime IS NOT NULL AND ((@DirectoryStructure NOT LIKE '%{DatabaseName}%' OR @DirectoryStructure IS NULL) OR (SERVERPROPERTY('IsHadrEnabled') = 1 AND (@AvailabilityGroupDirectoryStructure NOT LIKE '%{DatabaseName}%' OR @AvailabilityGroupDirectoryStructure IS NULL)))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupTime is not supported. Cleanup is not supported if the token {DatabaseName} is not part of the directory.', 16, 5
  END

  IF @CleanupTime IS NOT NULL AND ((@DirectoryStructure NOT LIKE '%{BackupType}%' OR @DirectoryStructure IS NULL) OR (SERVERPROPERTY('IsHadrEnabled') = 1 AND (@AvailabilityGroupDirectoryStructure NOT LIKE '%{BackupType}%' OR @AvailabilityGroupDirectoryStructure IS NULL)))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupTime is not supported. Cleanup is not supported if the token {BackupType} is not part of the directory.', 16, 6
  END

  IF @CleanupTime IS NOT NULL AND @CopyOnly = 'Y' AND ((@DirectoryStructure NOT LIKE '%{CopyOnly}%' OR @DirectoryStructure IS NULL) OR (SERVERPROPERTY('IsHadrEnabled') = 1 AND (@AvailabilityGroupDirectoryStructure NOT LIKE '%{CopyOnly}%' OR @AvailabilityGroupDirectoryStructure IS NULL)))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupTime is not supported. Cleanup is not supported if the token {CopyOnly} is not part of the directory.', 16, 7
  END

  ----------------------------------------------------------------------------------------------------

  IF @CleanupMode NOT IN('BEFORE_BACKUP','AFTER_BACKUP') OR @CleanupMode IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CleanupMode is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Compress NOT IN ('Y','N') OR @Compress IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Compress is not supported.', 16, 1
  END

  IF @Compress = 'Y' AND @BackupSoftware IS NULL AND NOT ((@Version >= 10 AND @Version < 10.5 AND SERVERPROPERTY('EngineEdition') = 3) OR (@Version >= 10.5 AND (SERVERPROPERTY('EngineEdition') IN (3, 8) OR SERVERPROPERTY('EditionID') IN (-1534726760, 284895786))))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Compress is not supported.', 16, 2
  END

  IF @Compress = 'N' AND @BackupSoftware IN ('LITESPEED','SQLBACKUP','SQLSAFE') AND (@CompressionLevel IS NULL OR @CompressionLevel >= 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Compress is not supported.', 16, 3
  END

  IF @Compress = 'Y' AND @BackupSoftware IN ('LITESPEED','SQLBACKUP','SQLSAFE') AND @CompressionLevel = 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Compress is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @CopyOnly NOT IN ('Y','N') OR @CopyOnly IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CopyOnly is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @ChangeBackupType NOT IN ('Y','N') OR @ChangeBackupType IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ChangeBackupType is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @BackupSoftware NOT IN ('LITESPEED','SQLBACKUP','SQLSAFE','DATA_DOMAIN_BOOST')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BackupSoftware is not supported.', 16, 1
  END

  IF @BackupSoftware IS NOT NULL AND @HostPlatform = 'Linux'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BackupSoftware is not supported. Only native backups are supported on Linux', 16, 2
  END

  IF @BackupSoftware = 'LITESPEED' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'xp_backup_database')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'LiteSpeed for SQL Server is not installed. Download https://www.quest.com/products/litespeed-for-sql-server/.', 16, 3
  END

  IF @BackupSoftware = 'SQLBACKUP' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'sqlbackup')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'Red Gate SQL Backup Pro is not installed. Download https://www.red-gate.com/products/dba/sql-backup/.', 16, 4
  END

  IF @BackupSoftware = 'SQLSAFE' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'xp_ss_backup')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'Idera SQL Safe Backup is not installed. Download https://www.idera.com/productssolutions/sqlserver/sqlsafebackup.', 16, 5
  END

  IF @BackupSoftware = 'DATA_DOMAIN_BOOST' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'PC' AND [name] = 'emc_run_backup')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'EMC Data Domain Boost is not installed. Download https://www.emc.com/en-us/data-protection/data-domain.htm.', 16, 6
  END

  ----------------------------------------------------------------------------------------------------

  IF @CheckSum NOT IN ('Y','N') OR @CheckSum IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CheckSum is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @BlockSize NOT IN (512,1024,2048,4096,8192,16384,32768,65536)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BlockSize is not supported.', 16, 1
  END

  IF @BlockSize IS NOT NULL AND @BackupSoftware = 'SQLBACKUP'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BlockSize is not supported. This parameter is not supported with Redgate SQL Backup Pro', 16, 2
  END

  IF @BlockSize IS NOT NULL AND @BackupSoftware = 'SQLSAFE'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BlockSize is not supported. This parameter is not supported with Idera SQL Safe', 16, 3
  END

  IF @BlockSize IS NOT NULL AND @URL IS NOT NULL AND @Credential IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BlockSize is not supported.', 16, 4
  END

  IF @BlockSize IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BlockSize is not supported. This parameter is not supported with Data Domain Boost', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF @BufferCount <= 0 OR @BufferCount > 2147483647
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BufferCount is not supported.', 16, 1
  END

  IF @BufferCount IS NOT NULL AND @BackupSoftware = 'SQLBACKUP'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BufferCount is not supported.', 16, 2
  END

  IF @BufferCount IS NOT NULL AND @BackupSoftware = 'SQLSAFE'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @BufferCount is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @MaxTransferSize < 65536 OR @MaxTransferSize > 4194304
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxTransferSize is not supported.', 16, 1
  END

  IF @MaxTransferSize > 1048576 AND @BackupSoftware = 'SQLBACKUP'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxTransferSize is not supported.', 16, 2
  END

  IF @MaxTransferSize IS NOT NULL AND @BackupSoftware = 'SQLSAFE'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxTransferSize is not supported.', 16, 3
  END

  IF @MaxTransferSize IS NOT NULL AND @URL IS NOT NULL AND @Credential IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxTransferSize is not supported.', 16, 4
  END

  IF @MaxTransferSize IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxTransferSize is not supported.', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF @NumberOfFiles < 1 OR @NumberOfFiles > 64
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 1
  END

  IF @NumberOfFiles > 32 AND @BackupSoftware = 'SQLBACKUP'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 2
  END

  IF @NumberOfFiles < (SELECT COUNT(*) FROM @Directories WHERE Mirror = 0)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 3
  END

  IF @NumberOfFiles % (SELECT NULLIF(COUNT(*),0) FROM @Directories WHERE Mirror = 0) > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 4
  END

  IF @URL IS NOT NULL AND @Credential IS NOT NULL AND @NumberOfFiles <> 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 5
  END

  IF @NumberOfFiles > 1 AND @BackupSoftware IN('SQLBACKUP','SQLSAFE') AND EXISTS(SELECT * FROM @Directories WHERE Mirror = 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 6
  END

  IF @NumberOfFiles > 32 AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 7
  END

  IF @NumberOfFiles < (SELECT COUNT(*) FROM @URLs WHERE Mirror = 0)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 8
  END

  IF @NumberOfFiles % (SELECT NULLIF(COUNT(*),0) FROM @URLs WHERE Mirror = 0) > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NumberOfFiles is not supported.', 16, 9
  END

    ----------------------------------------------------------------------------------------------------

  IF @MinBackupSizeForMultipleFiles <= 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MinBackupSizeForMultipleFiles is not supported.', 16, 1
  END

  IF @MinBackupSizeForMultipleFiles IS NOT NULL AND @NumberOfFiles IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MinBackupSizeForMultipleFiles is not supported. This parameter can only be used together with @NumberOfFiles.', 16, 2
  END

  IF @MinBackupSizeForMultipleFiles IS NOT NULL AND @BackupType = 'DIFF' AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_file_space_usage') AND name = 'modified_extent_page_count')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MinBackupSizeForMultipleFiles is not supported. The column sys.dm_db_file_space_usage.modified_extent_page_count is not available in this version of SQL Server.', 16, 3
  END

  IF @MinBackupSizeForMultipleFiles IS NOT NULL AND @BackupType = 'LOG' AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_since_last_log_backup_mb')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MinBackupSizeForMultipleFiles is not supported. The column sys.dm_db_log_stats.log_since_last_log_backup_mb is not available in this version of SQL Server.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @MaxFileSize <= 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxFileSize is not supported.', 16, 1
  END

  IF @MaxFileSize IS NOT NULL AND @NumberOfFiles IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameters @MaxFileSize and @NumberOfFiles cannot be used together.', 16, 2
  END

  IF @MaxFileSize IS NOT NULL AND @BackupType = 'DIFF' AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_file_space_usage') AND name = 'modified_extent_page_count')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxFileSize is not supported. The column sys.dm_db_file_space_usage.modified_extent_page_count is not available in this version of SQL Server.', 16, 3
  END

  IF @MaxFileSize IS NOT NULL AND @BackupType = 'LOG' AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_since_last_log_backup_mb')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxFileSize is not supported. The column sys.dm_db_log_stats.log_since_last_log_backup_mb is not available in this version of SQL Server.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF (@BackupSoftware IS NULL AND @CompressionLevel IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CompressionLevel is not supported.', 16, 1
  END

  IF @BackupSoftware = 'LITESPEED' AND (@CompressionLevel < 0  OR @CompressionLevel > 8)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CompressionLevel is not supported.', 16, 2
  END

  IF @BackupSoftware = 'SQLBACKUP' AND (@CompressionLevel < 0 OR @CompressionLevel > 4)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CompressionLevel is not supported.', 16, 3
  END

  IF @BackupSoftware = 'SQLSAFE' AND (@CompressionLevel < 1 OR @CompressionLevel > 4)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CompressionLevel is not supported.', 16, 4
  END

  IF @CompressionLevel IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CompressionLevel is not supported.', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF LEN(@Description) > 255
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Description is not supported.', 16, 1
  END

  IF @BackupSoftware = 'LITESPEED' AND LEN(@Description) > 128
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Description is not supported.', 16, 2
  END

  IF @BackupSoftware = 'DATA_DOMAIN_BOOST' AND LEN(@Description) > 254
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Description is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @Threads IS NOT NULL AND (@BackupSoftware NOT IN('LITESPEED','SQLBACKUP','SQLSAFE') OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Threads is not supported.', 16, 1
  END

  IF @BackupSoftware = 'LITESPEED' AND (@Threads < 1 OR @Threads > 32)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Threads is not supported.', 16, 2
  END

  IF @BackupSoftware = 'SQLBACKUP' AND (@Threads < 2 OR @Threads > 32)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Threads is not supported.', 16, 3
  END

  IF @BackupSoftware = 'SQLSAFE' AND (@Threads < 1 OR @Threads > 64)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Threads is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @Throttle < 1 OR @Throttle > 100
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Throttle is not supported.', 16, 1
  END

  IF @Throttle IS NOT NULL AND (@BackupSoftware NOT IN('LITESPEED') OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Throttle is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @Encrypt NOT IN('Y','N') OR @Encrypt IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Encrypt is not supported.', 16, 1
  END

  IF @Encrypt = 'Y' AND @BackupSoftware IS NULL AND NOT (@Version >= 12 AND (SERVERPROPERTY('EngineEdition') = 3) OR SERVERPROPERTY('EditionID') IN(-1534726760, 284895786))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Encrypt is not supported.', 16, 2
  END

  IF @Encrypt = 'Y' AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Encrypt is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @BackupSoftware IS NULL AND @Encrypt = 'Y' AND (@EncryptionAlgorithm NOT IN('AES_128','AES_192','AES_256','TRIPLE_DES_3KEY') OR @EncryptionAlgorithm IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionAlgorithm is not supported.', 16, 1
  END

  IF @BackupSoftware = 'LITESPEED' AND @Encrypt = 'Y' AND (@EncryptionAlgorithm NOT IN('RC2_40','RC2_56','RC2_112','RC2_128','TRIPLE_DES_3KEY','RC4_128','AES_128','AES_192','AES_256') OR @EncryptionAlgorithm IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionAlgorithm is not supported.', 16, 2
  END

  IF @BackupSoftware = 'SQLBACKUP' AND @Encrypt = 'Y' AND (@EncryptionAlgorithm NOT IN('AES_128','AES_256') OR @EncryptionAlgorithm IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionAlgorithm is not supported.', 16, 3
  END

  IF @BackupSoftware = 'SQLSAFE' AND @Encrypt = 'Y' AND (@EncryptionAlgorithm NOT IN('AES_128','AES_256') OR @EncryptionAlgorithm IS NULL)
  OR (@EncryptionAlgorithm IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionAlgorithm is not supported.', 16, 4
  END

  IF @EncryptionAlgorithm IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionAlgorithm is not supported.', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF (NOT (@BackupSoftware IS NULL AND @Encrypt = 'Y') AND @ServerCertificate IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerCertificate is not supported.', 16, 1
  END

  IF @BackupSoftware IS NULL AND @Encrypt = 'Y' AND @ServerCertificate IS NULL AND @ServerAsymmetricKey IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerCertificate is not supported.', 16, 2
  END

  IF @BackupSoftware IS NULL AND @Encrypt = 'Y' AND @ServerCertificate IS NOT NULL AND @ServerAsymmetricKey IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerCertificate is not supported.', 16, 3
  END

  IF @ServerCertificate IS NOT NULL AND NOT EXISTS(SELECT * FROM master.sys.certificates WHERE name = @ServerCertificate)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerCertificate is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF NOT (@BackupSoftware IS NULL AND @Encrypt = 'Y') AND @ServerAsymmetricKey IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerAsymmetricKey is not supported.', 16, 1
  END

  IF @BackupSoftware IS NULL AND @Encrypt = 'Y' AND @ServerAsymmetricKey IS NULL AND @ServerCertificate IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerAsymmetricKey is not supported.', 16, 2
  END

  IF @BackupSoftware IS NULL AND @Encrypt = 'Y' AND @ServerAsymmetricKey IS NOT NULL AND @ServerCertificate IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerAsymmetricKey is not supported.', 16, 3
  END

  IF @ServerAsymmetricKey IS NOT NULL AND NOT EXISTS(SELECT * FROM master.sys.asymmetric_keys WHERE name = @ServerAsymmetricKey)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ServerAsymmetricKey is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @EncryptionKey IS NOT NULL AND @BackupSoftware IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionKey is not supported.', 16, 1
  END

  IF @EncryptionKey IS NOT NULL AND @Encrypt = 'N'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionKey is not supported.', 16, 2
  END

  IF @EncryptionKey IS NULL AND @Encrypt = 'Y' AND @BackupSoftware IN('LITESPEED','SQLBACKUP','SQLSAFE')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionKey is not supported.', 16, 3
  END

  IF @EncryptionKey IS NOT NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @EncryptionKey is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @ReadWriteFileGroups NOT IN('Y','N') OR @ReadWriteFileGroups IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ReadWriteFileGroups is not supported.', 16, 1
  END

  IF @ReadWriteFileGroups = 'Y' AND @BackupType = 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ReadWriteFileGroups is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @OverrideBackupPreference NOT IN('Y','N') OR @OverrideBackupPreference IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @OverrideBackupPreference is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @NoRecovery NOT IN('Y','N') OR @NoRecovery IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NoRecovery is not supported.', 16, 1
  END

  IF @NoRecovery = 'Y' AND @BackupType <> 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NoRecovery is not supported.', 16, 2
  END

  IF @NoRecovery = 'Y' AND @BackupSoftware = 'SQLSAFE'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NoRecovery is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @URL IS NOT NULL AND @Directory IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 1
  END

  IF @URL IS NOT NULL AND @MirrorDirectory IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 2
  END

  IF @URL IS NOT NULL AND @Version < 11.03339
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 3
  END

  IF @URL IS NOT NULL AND @BackupSoftware IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @URL is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @Credential IS NULL AND @URL IS NOT NULL AND NOT (@Version >= 13 OR SERVERPROPERTY('EngineEdition') = 8)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Credential is not supported.', 16, 1
  END

  IF @Credential IS NOT NULL AND @URL IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Credential is not supported.', 16, 2
  END

  IF @URL IS NOT NULL AND @Credential IS NULL AND NOT EXISTS(SELECT * FROM sys.credentials WHERE UPPER(credential_identity) = 'SHARED ACCESS SIGNATURE')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Credential is not supported.', 16, 3
  END

  IF @Credential IS NOT NULL AND NOT EXISTS(SELECT * FROM sys.credentials WHERE name = @Credential)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Credential is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @MirrorCleanupTime < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorCleanupTime is not supported.', 16, 1
  END

  IF @MirrorCleanupTime IS NOT NULL AND @MirrorDirectory IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorCleanupTime is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @MirrorCleanupMode NOT IN('BEFORE_BACKUP','AFTER_BACKUP') OR @MirrorCleanupMode IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorCleanupMode is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @MirrorURL IS NOT NULL AND @Directory IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 1
  END

  IF @MirrorURL IS NOT NULL AND @MirrorDirectory IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 2
  END

  IF @MirrorURL IS NOT NULL AND @Version < 11.03339
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 3
  END

  IF @MirrorURL IS NOT NULL AND @BackupSoftware IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 4
  END

  IF @MirrorURL IS NOT NULL AND @URL IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MirrorURL is not supported.', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF @Updateability NOT IN('READ_ONLY','READ_WRITE','ALL') OR @Updateability IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Updateability is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @AdaptiveCompression NOT IN('SIZE','SPEED')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AdaptiveCompression is not supported.', 16, 1
  END

  IF @AdaptiveCompression IS NOT NULL AND (@BackupSoftware NOT IN('LITESPEED') OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AdaptiveCompression is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @ModificationLevel IS NOT NULL AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_file_space_usage') AND name = 'modified_extent_page_count')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ModificationLevel is not supported.', 16, 1
  END

  IF @ModificationLevel IS NOT NULL AND @ChangeBackupType = 'N'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ModificationLevel is not supported.', 16, 2
  END

  IF @ModificationLevel IS NOT NULL AND @BackupType <> 'DIFF'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ModificationLevel is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @LogSizeSinceLastLogBackup IS NOT NULL AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_since_last_log_backup_mb')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LogSizeSinceLastLogBackup is not supported.', 16, 1
  END

  IF @LogSizeSinceLastLogBackup IS NOT NULL AND @BackupType <> 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LogSizeSinceLastLogBackup is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @TimeSinceLastLogBackup IS NOT NULL AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_backup_time')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @TimeSinceLastLogBackup is not supported.', 16, 1
  END

  IF @TimeSinceLastLogBackup IS NOT NULL AND @BackupType <> 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @TimeSinceLastLogBackup is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF (@TimeSinceLastLogBackup IS NOT NULL AND @LogSizeSinceLastLogBackup IS NULL) OR (@TimeSinceLastLogBackup IS NULL AND @LogSizeSinceLastLogBackup IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameters @TimeSinceLastLogBackup and @LogSizeSinceLastLogBackup can only be used together.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @DataDomainBoostHost IS NOT NULL AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostHost is not supported.', 16, 1
  END

  IF @DataDomainBoostHost IS NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostHost is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @DataDomainBoostUser IS NOT NULL AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostUser is not supported.', 16, 1
  END

  IF @DataDomainBoostUser IS NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostUser is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @DataDomainBoostDevicePath IS NOT NULL AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostDevicePath is not supported.', 16, 1
  END

  IF @DataDomainBoostDevicePath IS NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostDevicePath is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @DataDomainBoostLockboxPath IS NOT NULL AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataDomainBoostLockboxPath is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @DirectoryStructure = ''
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DirectoryStructure is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @AvailabilityGroupDirectoryStructure = ''
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupDirectoryStructure is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @FileName IS NULL OR @FileName = ''
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileName is not supported.', 16, 1
  END

  IF @FileName NOT LIKE '%.{FileExtension}'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileName is not supported.', 16, 2
  END

  IF (@NumberOfFiles > 1 AND @FileName NOT LIKE '%{FileNumber}%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileName is not supported.', 16, 3
  END

  IF @FileName LIKE '%{DirectorySeparator}%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileName is not supported.', 16, 4
  END

  IF @FileName LIKE '%/%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileName is not supported.', 16, 5
  END

  IF @FileName LIKE '%\%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileName is not supported.', 16, 6
  END

  ----------------------------------------------------------------------------------------------------

  IF (SERVERPROPERTY('IsHadrEnabled') = 1 AND @AvailabilityGroupFileName IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 1
  END

  IF @AvailabilityGroupFileName = ''
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 2
  END

  IF @AvailabilityGroupFileName NOT LIKE '%.{FileExtension}'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 3
  END

  IF (@NumberOfFiles > 1 AND @AvailabilityGroupFileName NOT LIKE '%{FileNumber}%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 4
  END

  IF @AvailabilityGroupFileName LIKE '%{DirectorySeparator}%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 5
  END

  IF @AvailabilityGroupFileName LIKE '%/%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 6
  END

  IF @AvailabilityGroupFileName LIKE '%\%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupFileName is not supported.', 16, 7
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@DirectoryStructure,'{DirectorySeparator}',''),'{ServerName}',''),'{InstanceName}',''),'{ServiceName}',''),'{ClusterName}',''),'{AvailabilityGroupName}',''),'{DatabaseName}',''),'{BackupType}',''),'{Partial}',''),'{CopyOnly}',''),'{Description}',''),'{Year}',''),'{Month}',''),'{Day}',''),'{Week}',''),'{Hour}',''),'{Minute}',''),'{Second}',''),'{Millisecond}',''),'{Microsecond}',''),'{MajorVersion}',''),'{MinorVersion}','') AS DirectoryStructure) Temp WHERE DirectoryStructure LIKE '%{%' OR DirectoryStructure LIKE '%}%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameter @DirectoryStructure contains one or more tokens that are not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@AvailabilityGroupDirectoryStructure,'{DirectorySeparator}',''),'{ServerName}',''),'{InstanceName}',''),'{ServiceName}',''),'{ClusterName}',''),'{AvailabilityGroupName}',''),'{DatabaseName}',''),'{BackupType}',''),'{Partial}',''),'{CopyOnly}',''),'{Description}',''),'{Year}',''),'{Month}',''),'{Day}',''),'{Week}',''),'{Hour}',''),'{Minute}',''),'{Second}',''),'{Millisecond}',''),'{Microsecond}',''),'{MajorVersion}',''),'{MinorVersion}','') AS AvailabilityGroupDirectoryStructure) Temp WHERE AvailabilityGroupDirectoryStructure LIKE '%{%' OR AvailabilityGroupDirectoryStructure LIKE '%}%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameter @AvailabilityGroupDirectoryStructure contains one or more tokens that are not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@FileName,'{DirectorySeparator}',''),'{ServerName}',''),'{InstanceName}',''),'{ServiceName}',''),'{ClusterName}',''),'{AvailabilityGroupName}',''),'{DatabaseName}',''),'{BackupType}',''),'{Partial}',''),'{CopyOnly}',''),'{Description}',''),'{Year}',''),'{Month}',''),'{Day}',''),'{Week}',''),'{Hour}',''),'{Minute}',''),'{Second}',''),'{Millisecond}',''),'{Microsecond}',''),'{FileNumber}',''),'{NumberOfFiles}',''),'{FileExtension}',''),'{MajorVersion}',''),'{MinorVersion}','') AS [FileName]) Temp WHERE [FileName] LIKE '%{%' OR [FileName] LIKE '%}%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameter @FileName contains one or more tokens that are not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM (SELECT REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@AvailabilityGroupFileName,'{DirectorySeparator}',''),'{ServerName}',''),'{InstanceName}',''),'{ServiceName}',''),'{ClusterName}',''),'{AvailabilityGroupName}',''),'{DatabaseName}',''),'{BackupType}',''),'{Partial}',''),'{CopyOnly}',''),'{Description}',''),'{Year}',''),'{Month}',''),'{Day}',''),'{Week}',''),'{Hour}',''),'{Minute}',''),'{Second}',''),'{Millisecond}',''),'{Microsecond}',''),'{FileNumber}',''),'{NumberOfFiles}',''),'{FileExtension}',''),'{MajorVersion}',''),'{MinorVersion}','') AS AvailabilityGroupFileName) Temp WHERE AvailabilityGroupFileName LIKE '%{%' OR AvailabilityGroupFileName LIKE '%}%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameter @AvailabilityGroupFileName contains one or more tokens that are not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @FileExtensionFull LIKE '%.%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileExtensionFull is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @FileExtensionDiff LIKE '%.%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileExtensionDiff is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @FileExtensionLog LIKE '%.%'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileExtensionLog is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Init NOT IN('Y','N') OR @Init IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Init is not supported.', 16, 1
  END

  IF @Init = 'Y' AND @BackupType = 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Init is not supported.', 16, 2
  END

  IF @Init = 'Y' AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Init is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @Format NOT IN('Y','N') OR @Format IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Format is not supported.', 16, 1
  END

  IF @Format = 'Y' AND @BackupType = 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Format is not supported.', 16, 2
  END

  IF @Format = 'Y' AND @BackupSoftware = 'DATA_DOMAIN_BOOST'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Format is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @ObjectLevelRecoveryMap NOT IN('Y','N') OR @ObjectLevelRecoveryMap IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ObjectLevelRecovery is not supported.', 16, 1
  END

  IF @ObjectLevelRecoveryMap = 'Y' AND @BackupSoftware IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ObjectLevelRecovery is not supported.', 16, 2
  END

  IF @ObjectLevelRecoveryMap = 'Y' AND @BackupSoftware <> 'LITESPEED'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ObjectLevelRecovery is not supported.', 16, 3
  END

  IF @ObjectLevelRecoveryMap = 'Y' AND @BackupType = 'LOG'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ObjectLevelRecovery is not supported.', 16, 4
  END

  ----------------------------------------------------------------------------------------------------

  IF @ExcludeLogShippedFromLogBackup NOT IN('Y','N') OR @ExcludeLogShippedFromLogBackup IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ExcludeLogShippedFromLogBackup is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @StringDelimiter IS NULL OR LEN(@StringDelimiter) > 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StringDelimiter is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @DatabaseOrder NOT IN('DATABASE_NAME_ASC','DATABASE_NAME_DESC','DATABASE_SIZE_ASC','DATABASE_SIZE_DESC','LOG_SIZE_SINCE_LAST_LOG_BACKUP_ASC','LOG_SIZE_SINCE_LAST_LOG_BACKUP_DESC')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported.', 16, 1
  END

  IF @DatabaseOrder IN('LOG_SIZE_SINCE_LAST_LOG_BACKUP_ASC','LOG_SIZE_SINCE_LAST_LOG_BACKUP_DESC') AND NOT EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_since_last_log_backup_mb')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported. The column sys.dm_db_log_stats.log_since_last_log_backup_mb is not available in this version of SQL Server.', 16, 2
  END

  IF @DatabaseOrder IS NOT NULL AND SERVERPROPERTY('EngineEdition') = 5
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @DatabasesInParallel NOT IN('Y','N') OR @DatabasesInParallel IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabasesInParallel is not supported.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND SERVERPROPERTY('EngineEdition') = 5
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabasesInParallel is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LogToTable is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Execute is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @Errors)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The documentation is available at https://ola.hallengren.com/sql-server-backup.html.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Check that selected databases and availability groups exist                                //--
  ----------------------------------------------------------------------------------------------------

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedDatabases
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases in the @Databases parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(AvailabilityGroupName) + ', '
  FROM @SelectedAvailabilityGroups
  WHERE AvailabilityGroupName NOT LIKE '%[%]%'
  AND AvailabilityGroupName NOT IN (SELECT AvailabilityGroupName FROM @tmpAvailabilityGroups)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following availability groups do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Check @@SERVERNAME                                                                         //--
  ----------------------------------------------------------------------------------------------------

  IF @@SERVERNAME <> CAST(SERVERPROPERTY('ServerName') AS nvarchar(max)) AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The @@SERVERNAME does not match SERVERPROPERTY(''ServerName''). See ' + CASE WHEN SERVERPROPERTY('IsClustered') = 0 THEN 'https://docs.microsoft.com/en-us/sql/database-engine/install-windows/rename-a-computer-that-hosts-a-stand-alone-instance-of-sql-server' WHEN SERVERPROPERTY('IsClustered') = 1 THEN 'https://docs.microsoft.com/en-us/sql/sql-server/failover-clusters/install/rename-a-sql-server-failover-cluster-instance' END + '.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Raise errors                                                                               //--
  ----------------------------------------------------------------------------------------------------

  DECLARE ErrorCursor CURSOR FAST_FORWARD FOR SELECT [Message], Severity, [State] FROM @Errors ORDER BY [ID] ASC

  OPEN ErrorCursor

  FETCH ErrorCursor INTO @CurrentMessage, @CurrentSeverity, @CurrentState

  WHILE @@FETCH_STATUS = 0
  BEGIN
    RAISERROR('%s', @CurrentSeverity, @CurrentState, @CurrentMessage) WITH NOWAIT
    RAISERROR(@EmptyLine, 10, 1) WITH NOWAIT

    FETCH NEXT FROM ErrorCursor INTO @CurrentMessage, @CurrentSeverity, @CurrentState
  END

  CLOSE ErrorCursor

  DEALLOCATE ErrorCursor

  IF EXISTS (SELECT * FROM @Errors WHERE Severity >= 16)
  BEGIN
    SET @ReturnCode = 50000
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Check Availability Group cluster name                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN
    SELECT @Cluster = NULLIF(cluster_name,'')
    FROM sys.dm_hadr_cluster
  END

  ----------------------------------------------------------------------------------------------------
  --// Update database order                                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @DatabaseOrder IN('DATABASE_SIZE_ASC','DATABASE_SIZE_DESC')
  BEGIN
    UPDATE tmpDatabases
    SET DatabaseSize = (SELECT SUM(CAST(size AS bigint)) FROM sys.master_files WHERE [type] = 0 AND database_id = DB_ID(tmpDatabases.DatabaseName))
    FROM @tmpDatabases tmpDatabases
  END

  IF @DatabaseOrder IN('LOG_SIZE_SINCE_LAST_LOG_BACKUP_ASC','LOG_SIZE_SINCE_LAST_LOG_BACKUP_DESC')
  BEGIN
    UPDATE tmpDatabases
    SET LogSizeSinceLastLogBackup = (SELECT log_since_last_log_backup_mb FROM sys.dm_db_log_stats(DB_ID(tmpDatabases.DatabaseName)))
    FROM @tmpDatabases tmpDatabases
  END

  IF @DatabaseOrder IS NULL
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY StartPosition ASC, DatabaseName ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_NAME_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseName ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_NAME_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseName DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_SIZE_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseSize ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_SIZE_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseSize DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'LOG_SIZE_SINCE_LAST_LOG_BACKUP_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY LogSizeSinceLastLogBackup ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'LOG_SIZE_SINCE_LAST_LOG_BACKUP_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY LogSizeSinceLastLogBackup DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END

  ----------------------------------------------------------------------------------------------------
  --// Update the queue                                                                           //--
  ----------------------------------------------------------------------------------------------------

  IF @DatabasesInParallel = 'Y'
  BEGIN

    BEGIN TRY

      SELECT @QueueID = QueueID
      FROM dbo.[Queue]
      WHERE SchemaName = @SchemaName
      AND ObjectName = @ObjectName
      AND [Parameters] = @Parameters

      IF @QueueID IS NULL
      BEGIN
        BEGIN TRANSACTION

        SELECT @QueueID = QueueID
        FROM dbo.[Queue] WITH (UPDLOCK, HOLDLOCK)
        WHERE SchemaName = @SchemaName
        AND ObjectName = @ObjectName
        AND [Parameters] = @Parameters

        IF @QueueID IS NULL
        BEGIN
          INSERT INTO dbo.[Queue] (SchemaName, ObjectName, [Parameters])
          SELECT @SchemaName, @ObjectName, @Parameters

          SET @QueueID = SCOPE_IDENTITY()
        END

        COMMIT TRANSACTION
      END

      BEGIN TRANSACTION

      UPDATE [Queue]
      SET QueueStartTime = SYSDATETIME(),
          SessionID = @@SPID,
          RequestID = (SELECT request_id FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          RequestStartTime = (SELECT start_time FROM sys.dm_exec_requests WHERE session_id = @@SPID)
      FROM dbo.[Queue] [Queue]
      WHERE QueueID = @QueueID
      AND NOT EXISTS (SELECT *
                      FROM sys.dm_exec_requests
                      WHERE session_id = [Queue].SessionID
                      AND request_id = [Queue].RequestID
                      AND start_time = [Queue].RequestStartTime)
      AND NOT EXISTS (SELECT *
                      FROM dbo.QueueDatabase QueueDatabase
                      INNER JOIN sys.dm_exec_requests ON QueueDatabase.SessionID = session_id AND QueueDatabase.RequestID = request_id AND QueueDatabase.RequestStartTime = start_time
                      WHERE QueueDatabase.QueueID = @QueueID)

      IF @@ROWCOUNT = 1
      BEGIN
        INSERT INTO dbo.QueueDatabase (QueueID, DatabaseName)
        SELECT @QueueID AS QueueID,
               DatabaseName
        FROM @tmpDatabases tmpDatabases
        WHERE Selected = 1
        AND NOT EXISTS (SELECT * FROM dbo.QueueDatabase WHERE DatabaseName = tmpDatabases.DatabaseName AND QueueID = @QueueID)

        DELETE QueueDatabase
        FROM dbo.QueueDatabase QueueDatabase
        WHERE QueueID = @QueueID
        AND NOT EXISTS (SELECT * FROM @tmpDatabases tmpDatabases WHERE DatabaseName = QueueDatabase.DatabaseName AND Selected = 1)

        UPDATE QueueDatabase
        SET DatabaseOrder = tmpDatabases.[Order]
        FROM dbo.QueueDatabase QueueDatabase
        INNER JOIN @tmpDatabases tmpDatabases ON QueueDatabase.DatabaseName = tmpDatabases.DatabaseName
        WHERE QueueID = @QueueID
      END

      COMMIT TRANSACTION

      SELECT @QueueStartTime = QueueStartTime
      FROM dbo.[Queue]
      WHERE QueueID = @QueueID

    END TRY

    BEGIN CATCH
      IF XACT_STATE() <> 0
      BEGIN
        ROLLBACK TRANSACTION
      END
      SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'')
      RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
      SET @ReturnCode = ERROR_NUMBER()
      GOTO Logging
    END CATCH

  END

  ----------------------------------------------------------------------------------------------------
  --// Execute backup commands                                                                    //--
  ----------------------------------------------------------------------------------------------------

  WHILE (1 = 1)
  BEGIN

    IF @DatabasesInParallel = 'Y'
    BEGIN
      UPDATE QueueDatabase
      SET DatabaseStartTime = NULL,
          SessionID = NULL,
          RequestID = NULL,
          RequestStartTime = NULL
      FROM dbo.QueueDatabase QueueDatabase
      WHERE QueueID = @QueueID
      AND DatabaseStartTime IS NOT NULL
      AND DatabaseEndTime IS NULL
      AND NOT EXISTS (SELECT * FROM sys.dm_exec_requests WHERE session_id = QueueDatabase.SessionID AND request_id = QueueDatabase.RequestID AND start_time = QueueDatabase.RequestStartTime)

      UPDATE QueueDatabase
      SET DatabaseStartTime = SYSDATETIME(),
          DatabaseEndTime = NULL,
          SessionID = @@SPID,
          RequestID = (SELECT request_id FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          RequestStartTime = (SELECT start_time FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          @CurrentDatabaseName = DatabaseName,
          @CurrentDatabaseNameFS = (SELECT DatabaseNameFS FROM @tmpDatabases WHERE DatabaseName = QueueDatabase.DatabaseName)
      FROM (SELECT TOP 1 DatabaseStartTime,
                         DatabaseEndTime,
                         SessionID,
                         RequestID,
                         RequestStartTime,
                         DatabaseName
            FROM dbo.QueueDatabase
            WHERE QueueID = @QueueID
            AND (DatabaseStartTime < @QueueStartTime OR DatabaseStartTime IS NULL)
            AND NOT (DatabaseStartTime IS NOT NULL AND DatabaseEndTime IS NULL)
            ORDER BY DatabaseOrder ASC
            ) QueueDatabase
    END
    ELSE
    BEGIN
      SELECT TOP 1 @CurrentDBID = ID,
                   @CurrentDatabaseName = DatabaseName,
                   @CurrentDatabaseNameFS = DatabaseNameFS
      FROM @tmpDatabases
      WHERE Selected = 1
      AND Completed = 0
      ORDER BY [Order] ASC
    END

    IF @@ROWCOUNT = 0
    BEGIN
      BREAK
    END

    SET @CurrentDatabase_sp_executesql = QUOTENAME(@CurrentDatabaseName) + '.sys.sp_executesql'

    BEGIN
      SET @DatabaseMessage = 'Date and time: ' + CONVERT(nvarchar,SYSDATETIME(),120)
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Database: ' + QUOTENAME(@CurrentDatabaseName)
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    SELECT @CurrentUserAccess = user_access_desc,
           @CurrentIsReadOnly = is_read_only,
           @CurrentDatabaseState = state_desc,
           @CurrentInStandby = is_in_standby,
           @CurrentRecoveryModel = recovery_model_desc,
           @CurrentIsEncrypted = is_encrypted,
           @CurrentDatabaseSize = (SELECT SUM(CAST(size AS bigint)) FROM sys.master_files WHERE [type] = 0 AND database_id = sys.databases.database_id)
    FROM sys.databases
    WHERE [name] = @CurrentDatabaseName

    BEGIN
      SET @DatabaseMessage = 'State: ' + @CurrentDatabaseState
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Standby: ' + CASE WHEN @CurrentInStandby = 1 THEN 'Yes' ELSE 'No' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage =  'Updateability: ' + CASE WHEN @CurrentIsReadOnly = 1 THEN 'READ_ONLY' WHEN  @CurrentIsReadOnly = 0 THEN 'READ_WRITE' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage =  'User access: ' + @CurrentUserAccess
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Recovery model: ' + @CurrentRecoveryModel
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Encrypted: ' + CASE WHEN @CurrentIsEncrypted = 1 THEN 'Yes' WHEN @CurrentIsEncrypted = 0 THEN 'No' ELSE 'N/A' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    SELECT @CurrentMaxTransferSize = CASE
    WHEN @MaxTransferSize IS NOT NULL THEN @MaxTransferSize
    WHEN @MaxTransferSize IS NULL AND @Compress = 'Y' AND @CurrentIsEncrypted = 1 AND @BackupSoftware IS NULL AND (@Version >= 13 OR SERVERPROPERTY('EngineEdition') = 8) THEN 65537
    END

    IF @CurrentDatabaseState = 'ONLINE'
    BEGIN
      IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = DB_ID(@CurrentDatabaseName) AND database_guid IS NOT NULL)
      BEGIN
        SET @CurrentIsDatabaseAccessible = 1
      END
      ELSE
      BEGIN
        SET @CurrentIsDatabaseAccessible = 0
      END
    END

    IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
    BEGIN
      SELECT @CurrentReplicaID = databases.replica_id
      FROM sys.databases databases
      INNER JOIN sys.availability_replicas availability_replicas ON databases.replica_id = availability_replicas.replica_id
      WHERE databases.[name] = @CurrentDatabaseName

      SELECT @CurrentAvailabilityGroupID = group_id
      FROM sys.availability_replicas
      WHERE replica_id = @CurrentReplicaID

      SELECT @CurrentAvailabilityGroupRole = role_desc
      FROM sys.dm_hadr_availability_replica_states
      WHERE replica_id = @CurrentReplicaID

      SELECT @CurrentAvailabilityGroup = [name],
             @CurrentAvailabilityGroupBackupPreference = UPPER(automated_backup_preference_desc)
      FROM sys.availability_groups
      WHERE group_id = @CurrentAvailabilityGroupID
    END

    IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1 AND @CurrentAvailabilityGroup IS NOT NULL
    BEGIN
      SELECT @CurrentIsPreferredBackupReplica = sys.fn_hadr_backup_is_preferred_replica(@CurrentDatabaseName)
    END

    SELECT @CurrentDifferentialBaseLSN = differential_base_lsn
    FROM sys.master_files
    WHERE database_id = DB_ID(@CurrentDatabaseName)
    AND [type] = 0
    AND [file_id] = 1

    IF @CurrentDatabaseState = 'ONLINE'
    BEGIN
      SELECT @CurrentLogLSN = last_log_backup_lsn
      FROM sys.database_recovery_status
      WHERE database_id = DB_ID(@CurrentDatabaseName)
    END

    IF @CurrentDatabaseState = 'ONLINE' AND EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_file_space_usage') AND name = 'modified_extent_page_count') AND (@CurrentAvailabilityGroupRole = 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL)
    BEGIN
      SET @CurrentCommand = 'SELECT @ParamAllocatedExtentPageCount = SUM(allocated_extent_page_count), @ParamModifiedExtentPageCount = SUM(modified_extent_page_count) FROM sys.dm_db_file_space_usage'

      EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamAllocatedExtentPageCount bigint OUTPUT, @ParamModifiedExtentPageCount bigint OUTPUT', @ParamAllocatedExtentPageCount = @CurrentAllocatedExtentPageCount OUTPUT, @ParamModifiedExtentPageCount = @CurrentModifiedExtentPageCount OUTPUT
    END

    SET @CurrentBackupType = @BackupType

    IF @ChangeBackupType = 'Y'
    BEGIN
      IF @CurrentBackupType = 'LOG' AND @CurrentRecoveryModel IN('FULL','BULK_LOGGED') AND @CurrentLogLSN IS NULL AND @CurrentDatabaseName <> 'master'
      BEGIN
        SET @CurrentBackupType = 'DIFF'
      END
      IF @CurrentBackupType = 'DIFF' AND (@CurrentDatabaseName = 'master' OR @CurrentDifferentialBaseLSN IS NULL OR (@CurrentModifiedExtentPageCount * 1. / @CurrentAllocatedExtentPageCount * 100 >= @ModificationLevel))
      BEGIN
        SET @CurrentBackupType = 'FULL'
      END
    END

    IF @CurrentDatabaseState = 'ONLINE' AND EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_since_last_log_backup_mb')
    BEGIN
      SELECT @CurrentLastLogBackup = log_backup_time,
             @CurrentLogSizeSinceLastLogBackup = log_since_last_log_backup_mb
      FROM sys.dm_db_log_stats (DB_ID(@CurrentDatabaseName))
    END

    IF @CurrentBackupType = 'DIFF'
    BEGIN
      SELECT @CurrentDifferentialBaseIsSnapshot = is_snapshot
      FROM msdb.dbo.backupset
      WHERE database_name = @CurrentDatabaseName
      AND [type] = 'D'
      AND checkpoint_lsn = @CurrentDifferentialBaseLSN
    END

    IF @ChangeBackupType = 'Y'
    BEGIN
      IF @CurrentBackupType = 'DIFF' AND @CurrentDifferentialBaseIsSnapshot = 1
      BEGIN
        SET @CurrentBackupType = 'FULL'
      END
    END;

    WITH CurrentDatabase AS
    (
    SELECT BackupSize = CASE WHEN @CurrentBackupType = 'FULL' THEN COALESCE(CAST(@CurrentAllocatedExtentPageCount AS bigint) * 8192, CAST(@CurrentDatabaseSize AS bigint) * 8192)
                             WHEN @CurrentBackupType = 'DIFF' THEN CAST(@CurrentModifiedExtentPageCount AS bigint) * 8192
                             WHEN @CurrentBackupType = 'LOG' THEN CAST(@CurrentLogSizeSinceLastLogBackup * 1024 * 1024 AS bigint)
                             END,
           MaxNumberOfFiles = CASE WHEN @BackupSoftware IN('SQLBACKUP','DATA_DOMAIN_BOOST') THEN 32 ELSE 64 END,
           CASE WHEN (SELECT COUNT(*) FROM @Directories WHERE Mirror = 0) > 0 THEN (SELECT COUNT(*) FROM @Directories WHERE Mirror = 0) ELSE (SELECT COUNT(*) FROM @URLs WHERE Mirror = 0) END AS NumberOfDirectories,
           CAST(@MinBackupSizeForMultipleFiles AS bigint) * 1024 * 1024 AS MinBackupSizeForMultipleFiles,
           CAST(@MaxFileSize AS bigint) * 1024 * 1024 AS MaxFileSize
    )
    SELECT @CurrentNumberOfFiles = CASE WHEN @NumberOfFiles IS NULL AND @BackupSoftware = 'DATA_DOMAIN_BOOST' THEN 1
                                        WHEN @NumberOfFiles IS NULL AND @MaxFileSize IS NULL THEN NumberOfDirectories
                                        WHEN @NumberOfFiles = 1 THEN @NumberOfFiles
                                        WHEN @NumberOfFiles > 1 AND (BackupSize >= MinBackupSizeForMultipleFiles OR MinBackupSizeForMultipleFiles IS NULL OR BackupSize IS NULL) THEN @NumberOfFiles
                                        WHEN @NumberOfFiles > 1 AND (BackupSize < MinBackupSizeForMultipleFiles) THEN NumberOfDirectories
                                        WHEN @NumberOfFiles IS NULL AND @MaxFileSize IS NOT NULL AND (BackupSize IS NULL OR BackupSize = 0) THEN NumberOfDirectories
                                        WHEN @NumberOfFiles IS NULL AND @MaxFileSize IS NOT NULL THEN (SELECT MIN(NumberOfFilesInEachDirectory)
                                                                                                       FROM (SELECT ((BackupSize / NumberOfDirectories) / MaxFileSize + CASE WHEN (BackupSize / NumberOfDirectories) % MaxFileSize = 0 THEN 0 ELSE 1 END) AS NumberOfFilesInEachDirectory
                                                                                                             UNION
                                                                                                             SELECT MaxNumberOfFiles / NumberOfDirectories) Files) * NumberOfDirectories
                                        END

    FROM CurrentDatabase

    SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
    FROM sys.database_mirroring
    WHERE database_id = DB_ID(@CurrentDatabaseName)

    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_primary_databases WHERE primary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'PRIMARY'
    END
    ELSE
    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_secondary_databases WHERE secondary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'SECONDARY'
    END

    IF @CurrentIsDatabaseAccessible IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentAvailabilityGroup IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Availability group: ' + ISNULL(@CurrentAvailabilityGroup,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Availability group role: ' + ISNULL(@CurrentAvailabilityGroupRole,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Availability group backup preference: ' + ISNULL(@CurrentAvailabilityGroupBackupPreference,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Is preferred backup replica: ' + CASE WHEN @CurrentIsPreferredBackupReplica = 1 THEN 'Yes' WHEN @CurrentIsPreferredBackupReplica = 0 THEN 'No' ELSE 'N/A' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentDatabaseMirroringRole IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Database mirroring role: ' + @CurrentDatabaseMirroringRole
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentLogShippingRole IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Log shipping role: ' + @CurrentLogShippingRole
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    SET @DatabaseMessage = 'Differential base LSN: ' + ISNULL(CAST(@CurrentDifferentialBaseLSN AS nvarchar),'N/A')
    RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

    IF @CurrentBackupType = 'DIFF' OR @CurrentDifferentialBaseIsSnapshot IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Differential base is snapshot: ' + CASE WHEN @CurrentDifferentialBaseIsSnapshot = 1 THEN 'Yes' WHEN @CurrentDifferentialBaseIsSnapshot = 0 THEN 'No' ELSE 'N/A' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    SET @DatabaseMessage = 'Last log backup LSN: ' + ISNULL(CAST(@CurrentLogLSN AS nvarchar),'N/A')
    RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

    IF @CurrentBackupType IN('DIFF','FULL') AND EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_file_space_usage') AND name = 'modified_extent_page_count')
    BEGIN
      SET @DatabaseMessage = 'Allocated extent page count: ' + ISNULL(CAST(@CurrentAllocatedExtentPageCount AS nvarchar) + ' (' + CAST(@CurrentAllocatedExtentPageCount * 1. * 8 / 1024 AS nvarchar) + ' MB)','N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Modified extent page count: ' + ISNULL(CAST(@CurrentModifiedExtentPageCount AS nvarchar) + ' (' + CAST(@CurrentModifiedExtentPageCount * 1. * 8 / 1024 AS nvarchar) + ' MB)','N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentBackupType = 'LOG' AND EXISTS(SELECT * FROM sys.all_columns WHERE object_id = OBJECT_ID('sys.dm_db_log_stats') AND name = 'log_since_last_log_backup_mb')
    BEGIN
      SET @DatabaseMessage = 'Last log backup: ' + ISNULL(CONVERT(nvarchar(19),NULLIF(@CurrentLastLogBackup,'1900-01-01'),120),'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Log size since last log backup (MB): ' + ISNULL(CAST(@CurrentLogSizeSinceLastLogBackup AS nvarchar),'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    RAISERROR(@EmptyLine,10,1) WITH NOWAIT

    IF @CurrentDatabaseState = 'ONLINE'
    AND NOT (@CurrentUserAccess = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)
    AND NOT (@CurrentInStandby = 1)
    AND NOT (@CurrentBackupType = 'LOG' AND @CurrentRecoveryModel = 'SIMPLE')
    AND NOT (@CurrentBackupType = 'LOG' AND @CurrentRecoveryModel IN('FULL','BULK_LOGGED') AND @CurrentLogLSN IS NULL)
    AND NOT (@CurrentBackupType = 'DIFF' AND @CurrentDifferentialBaseLSN IS NULL)
    AND NOT (@CurrentBackupType IN('DIFF','LOG') AND @CurrentDatabaseName = 'master')
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'FULL' AND @CopyOnly = 'N' AND (@CurrentAvailabilityGroupRole <> 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL))
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'FULL' AND @CopyOnly = 'Y' AND (@CurrentIsPreferredBackupReplica <> 1 OR @CurrentIsPreferredBackupReplica IS NULL) AND @OverrideBackupPreference = 'N')
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'DIFF' AND (@CurrentAvailabilityGroupRole <> 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL))
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'LOG' AND @CopyOnly = 'N' AND (@CurrentIsPreferredBackupReplica <> 1 OR @CurrentIsPreferredBackupReplica IS NULL) AND @OverrideBackupPreference = 'N')
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'LOG' AND @CopyOnly = 'Y' AND (@CurrentAvailabilityGroupRole <> 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL))
    AND NOT ((@CurrentLogShippingRole = 'PRIMARY' AND @CurrentLogShippingRole IS NOT NULL) AND @CurrentBackupType = 'LOG' AND @ExcludeLogShippedFromLogBackup = 'Y')
    AND NOT (@CurrentIsReadOnly = 1 AND @Updateability = 'READ_WRITE')
    AND NOT (@CurrentIsReadOnly = 0 AND @Updateability = 'READ_ONLY')
    AND NOT (@CurrentBackupType = 'LOG' AND @LogSizeSinceLastLogBackup IS NOT NULL AND @TimeSinceLastLogBackup IS NOT NULL AND NOT(@CurrentLogSizeSinceLastLogBackup >= @LogSizeSinceLastLogBackup OR @CurrentLogSizeSinceLastLogBackup IS NULL OR DATEDIFF(SECOND,@CurrentLastLogBackup,SYSDATETIME()) >= @TimeSinceLastLogBackup OR @CurrentLastLogBackup IS NULL))
    AND NOT (@CurrentBackupType = 'LOG' AND @Updateability = 'READ_ONLY' AND @BackupSoftware = 'DATA_DOMAIN_BOOST')
    BEGIN

      IF @CurrentBackupType = 'LOG' AND (@CleanupTime IS NOT NULL OR @MirrorCleanupTime IS NOT NULL)
      BEGIN
        SELECT @CurrentLatestBackup = MAX(backup_start_date)
        FROM msdb.dbo.backupset
        WHERE ([type] IN('D','I')
        OR ([type] = 'L' AND last_lsn < @CurrentDifferentialBaseLSN))
        AND is_damaged = 0
        AND [database_name] = @CurrentDatabaseName
      END

      SET @CurrentDate = SYSDATETIME()

      INSERT INTO @CurrentCleanupDates (CleanupDate)
      SELECT @CurrentDate

      IF @CurrentBackupType = 'LOG'
      BEGIN
        INSERT INTO @CurrentCleanupDates (CleanupDate)
        SELECT @CurrentLatestBackup
      END

      SELECT @CurrentDirectoryStructure = CASE
      WHEN @CurrentAvailabilityGroup IS NOT NULL THEN @AvailabilityGroupDirectoryStructure
      ELSE @DirectoryStructure
      END

      IF @CurrentDirectoryStructure IS NOT NULL
      BEGIN
      -- Directory structure - remove tokens that are not needed
        IF @ReadWriteFileGroups = 'N' SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Partial}','')
        IF @CopyOnly = 'N' SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{CopyOnly}','')
        IF @Cluster IS NULL SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ClusterName}','')
        IF @CurrentAvailabilityGroup IS NULL SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{AvailabilityGroupName}','')
        IF SERVERPROPERTY('InstanceName') IS NULL SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{InstanceName}','')
        IF @@SERVICENAME IS NULL SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ServiceName}','')
        IF @Description IS NULL SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Description}','')

        IF @Directory IS NULL AND @MirrorDirectory IS NULL AND @URL IS NULL AND @DefaultDirectory LIKE '%' + '.' + @@SERVICENAME + @DirectorySeparator + 'MSSQL' + @DirectorySeparator + 'Backup'
        BEGIN
          SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ServerName}','')
          SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{InstanceName}','')
          SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ClusterName}','')
          SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{AvailabilityGroupName}','')
        END

        WHILE (@Updated = 1 OR @Updated IS NULL)
        BEGIN
          SET @Updated = 0

          IF CHARINDEX('\',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'\','{DirectorySeparator}')
            SET @Updated = 1
          END

          IF CHARINDEX('/',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'/','{DirectorySeparator}')
            SET @Updated = 1
          END

          IF CHARINDEX('__',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'__','_')
            SET @Updated = 1
          END

          IF CHARINDEX('--',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'--','-')
            SET @Updated = 1
          END

          IF CHARINDEX('{DirectorySeparator}{DirectorySeparator}',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{DirectorySeparator}{DirectorySeparator}','{DirectorySeparator}')
            SET @Updated = 1
          END

          IF CHARINDEX('{DirectorySeparator}$',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{DirectorySeparator}$','{DirectorySeparator}')
            SET @Updated = 1
          END
          IF CHARINDEX('${DirectorySeparator}',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'${DirectorySeparator}','{DirectorySeparator}')
            SET @Updated = 1
          END

          IF CHARINDEX('{DirectorySeparator}_',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{DirectorySeparator}_','{DirectorySeparator}')
            SET @Updated = 1
          END
          IF CHARINDEX('_{DirectorySeparator}',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'_{DirectorySeparator}','{DirectorySeparator}')
            SET @Updated = 1
          END

          IF CHARINDEX('{DirectorySeparator}-',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{DirectorySeparator}-','{DirectorySeparator}')
            SET @Updated = 1
          END
          IF CHARINDEX('-{DirectorySeparator}',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'-{DirectorySeparator}','{DirectorySeparator}')
            SET @Updated = 1
          END

          IF CHARINDEX('_$',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'_$','_')
            SET @Updated = 1
          END
          IF CHARINDEX('$_',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'$_','_')
            SET @Updated = 1
          END

          IF CHARINDEX('-$',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'-$','-')
            SET @Updated = 1
          END
          IF CHARINDEX('$-',@CurrentDirectoryStructure) > 0
          BEGIN
            SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'$-','-')
            SET @Updated = 1
          END

          IF LEFT(@CurrentDirectoryStructure,1) = '_'
          BEGIN
            SET @CurrentDirectoryStructure = RIGHT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 1)
            SET @Updated = 1
          END
          IF RIGHT(@CurrentDirectoryStructure,1) = '_'
          BEGIN
            SET @CurrentDirectoryStructure = LEFT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 1)
            SET @Updated = 1
          END

          IF LEFT(@CurrentDirectoryStructure,1) = '-'
          BEGIN
            SET @CurrentDirectoryStructure = RIGHT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 1)
            SET @Updated = 1
          END
          IF RIGHT(@CurrentDirectoryStructure,1) = '-'
          BEGIN
            SET @CurrentDirectoryStructure = LEFT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 1)
            SET @Updated = 1
          END

          IF LEFT(@CurrentDirectoryStructure,1) = '$'
          BEGIN
            SET @CurrentDirectoryStructure = RIGHT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 1)
            SET @Updated = 1
          END
          IF RIGHT(@CurrentDirectoryStructure,1) = '$'
          BEGIN
            SET @CurrentDirectoryStructure = LEFT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 1)
            SET @Updated = 1
          END

          IF LEFT(@CurrentDirectoryStructure,20) = '{DirectorySeparator}'
          BEGIN
            SET @CurrentDirectoryStructure = RIGHT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 20)
            SET @Updated = 1
          END
          IF RIGHT(@CurrentDirectoryStructure,20) = '{DirectorySeparator}'
          BEGIN
            SET @CurrentDirectoryStructure = LEFT(@CurrentDirectoryStructure,LEN(@CurrentDirectoryStructure) - 20)
            SET @Updated = 1
          END
        END

        SET @Updated = NULL

        -- Directory structure - replace tokens with real values
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{DirectorySeparator}',@DirectorySeparator)
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ServerName}',CASE WHEN SERVERPROPERTY('EngineEdition') = 8 THEN LEFT(CAST(SERVERPROPERTY('ServerName') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ServerName') AS nvarchar(max))) - 1) ELSE CAST(SERVERPROPERTY('MachineName') AS nvarchar(max)) END)
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{InstanceName}',ISNULL(CAST(SERVERPROPERTY('InstanceName') AS nvarchar(max)),''))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ServiceName}',ISNULL(@@SERVICENAME,''))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{ClusterName}',ISNULL(@Cluster,''))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{AvailabilityGroupName}',ISNULL(@CurrentAvailabilityGroup,''))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{DatabaseName}',@CurrentDatabaseNameFS)
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{BackupType}',@CurrentBackupType)
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Partial}','PARTIAL')
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{CopyOnly}','COPY_ONLY')
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Description}',LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Description,''),'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''))))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Year}',CAST(DATEPART(YEAR,@CurrentDate) AS nvarchar))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Month}',RIGHT('0' + CAST(DATEPART(MONTH,@CurrentDate) AS nvarchar),2))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Day}',RIGHT('0' + CAST(DATEPART(DAY,@CurrentDate) AS nvarchar),2))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Week}',RIGHT('0' + CAST(DATEPART(WEEK,@CurrentDate) AS nvarchar),2))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Hour}',RIGHT('0' + CAST(DATEPART(HOUR,@CurrentDate) AS nvarchar),2))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Minute}',RIGHT('0' + CAST(DATEPART(MINUTE,@CurrentDate) AS nvarchar),2))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Second}',RIGHT('0' + CAST(DATEPART(SECOND,@CurrentDate) AS nvarchar),2))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Millisecond}',RIGHT('00' + CAST(DATEPART(MILLISECOND,@CurrentDate) AS nvarchar),3))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{Microsecond}',RIGHT('00000' + CAST(DATEPART(MICROSECOND,@CurrentDate) AS nvarchar),6))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{MajorVersion}',ISNULL(CAST(SERVERPROPERTY('ProductMajorVersion') AS nvarchar),PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),4)))
        SET @CurrentDirectoryStructure = REPLACE(@CurrentDirectoryStructure,'{MinorVersion}',ISNULL(CAST(SERVERPROPERTY('ProductMinorVersion') AS nvarchar),PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),3)))
      END

      INSERT INTO @CurrentDirectories (ID, DirectoryPath, Mirror, DirectoryNumber, CreateCompleted, CleanupCompleted)
      SELECT ROW_NUMBER() OVER (ORDER BY ID),
             DirectoryPath + CASE WHEN DirectoryPath = 'NUL' THEN '' WHEN @CurrentDirectoryStructure IS NOT NULL THEN @DirectorySeparator + @CurrentDirectoryStructure ELSE '' END,
             Mirror,
             ROW_NUMBER() OVER (PARTITION BY Mirror ORDER BY ID ASC),
             0,
             0
      FROM @Directories
      ORDER BY ID ASC

      INSERT INTO @CurrentURLs (ID, DirectoryPath, Mirror, DirectoryNumber)
      SELECT ROW_NUMBER() OVER (ORDER BY ID),
             DirectoryPath + CASE WHEN @CurrentDirectoryStructure IS NOT NULL THEN @DirectorySeparator + @CurrentDirectoryStructure ELSE '' END,
             Mirror,
             ROW_NUMBER() OVER (PARTITION BY Mirror ORDER BY ID ASC)
      FROM @URLs
      ORDER BY ID ASC

      SELECT @CurrentDatabaseFileName = CASE
      WHEN @CurrentAvailabilityGroup IS NOT NULL THEN @AvailabilityGroupFileName
      ELSE @FileName
      END

      -- File name - remove tokens that are not needed
      IF @ReadWriteFileGroups = 'N' SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Partial}','')
      IF @CopyOnly = 'N' SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{CopyOnly}','')
      IF @Cluster IS NULL SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{ClusterName}','')
      IF @CurrentAvailabilityGroup IS NULL SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{AvailabilityGroupName}','')
      IF SERVERPROPERTY('InstanceName') IS NULL SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{InstanceName}','')
      IF @@SERVICENAME IS NULL SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{ServiceName}','')
      IF @Description IS NULL SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Description}','')
      IF @CurrentNumberOfFiles = 1 SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{FileNumber}','')
      IF @CurrentNumberOfFiles = 1 SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{NumberOfFiles}','')

      WHILE (@Updated = 1 OR @Updated IS NULL)
      BEGIN
        SET @Updated = 0

        IF CHARINDEX('__',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'__','_')
          SET @Updated = 1
        END

        IF CHARINDEX('--',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'--','-')
          SET @Updated = 1
        END

        IF CHARINDEX('_$',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'_$','_')
          SET @Updated = 1
        END
        IF CHARINDEX('$_',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'$_','_')
          SET @Updated = 1
        END

        IF CHARINDEX('-$',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'-$','-')
          SET @Updated = 1
        END
        IF CHARINDEX('$-',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'$-','-')
          SET @Updated = 1
        END

        IF CHARINDEX('_.',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'_.','.')
          SET @Updated = 1
        END

        IF CHARINDEX('-.',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'-.','.')
          SET @Updated = 1
        END

        IF CHARINDEX('of.',@CurrentDatabaseFileName) > 0
        BEGIN
          SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'of.','.')
          SET @Updated = 1
        END

        IF LEFT(@CurrentDatabaseFileName,1) = '_'
        BEGIN
          SET @CurrentDatabaseFileName = RIGHT(@CurrentDatabaseFileName,LEN(@CurrentDatabaseFileName) - 1)
          SET @Updated = 1
        END
        IF RIGHT(@CurrentDatabaseFileName,1) = '_'
        BEGIN
          SET @CurrentDatabaseFileName = LEFT(@CurrentDatabaseFileName,LEN(@CurrentDatabaseFileName) - 1)
          SET @Updated = 1
        END

        IF LEFT(@CurrentDatabaseFileName,1) = '-'
        BEGIN
          SET @CurrentDatabaseFileName = RIGHT(@CurrentDatabaseFileName,LEN(@CurrentDatabaseFileName) - 1)
          SET @Updated = 1
        END
        IF RIGHT(@CurrentDatabaseFileName,1) = '-'
        BEGIN
          SET @CurrentDatabaseFileName = LEFT(@CurrentDatabaseFileName,LEN(@CurrentDatabaseFileName) - 1)
          SET @Updated = 1
        END

        IF LEFT(@CurrentDatabaseFileName,1) = '$'
        BEGIN
          SET @CurrentDatabaseFileName = RIGHT(@CurrentDatabaseFileName,LEN(@CurrentDatabaseFileName) - 1)
          SET @Updated = 1
        END
        IF RIGHT(@CurrentDatabaseFileName,1) = '$'
        BEGIN
          SET @CurrentDatabaseFileName = LEFT(@CurrentDatabaseFileName,LEN(@CurrentDatabaseFileName) - 1)
          SET @Updated = 1
        END
      END

      SET @Updated = NULL

      SELECT @CurrentFileExtension = CASE
      WHEN @CurrentBackupType = 'FULL' THEN @FileExtensionFull
      WHEN @CurrentBackupType = 'DIFF' THEN @FileExtensionDiff
      WHEN @CurrentBackupType = 'LOG' THEN @FileExtensionLog
      END

      -- File name - replace tokens with real values
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{ServerName}',CASE WHEN SERVERPROPERTY('EngineEdition') = 8 THEN LEFT(CAST(SERVERPROPERTY('ServerName') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ServerName') AS nvarchar(max))) - 1) ELSE CAST(SERVERPROPERTY('MachineName') AS nvarchar(max)) END)
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{InstanceName}',ISNULL(CAST(SERVERPROPERTY('InstanceName') AS nvarchar(max)),''))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{ServiceName}',ISNULL(@@SERVICENAME,''))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{ClusterName}',ISNULL(@Cluster,''))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{AvailabilityGroupName}',ISNULL(@CurrentAvailabilityGroup,''))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{BackupType}',@CurrentBackupType)
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Partial}','PARTIAL')
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{CopyOnly}','COPY_ONLY')
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Description}',LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(ISNULL(@Description,''),'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''))))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Year}',CAST(DATEPART(YEAR,@CurrentDate) AS nvarchar))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Month}',RIGHT('0' + CAST(DATEPART(MONTH,@CurrentDate) AS nvarchar),2))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Day}',RIGHT('0' + CAST(DATEPART(DAY,@CurrentDate) AS nvarchar),2))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Week}',RIGHT('0' + CAST(DATEPART(WEEK,@CurrentDate) AS nvarchar),2))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Hour}',RIGHT('0' + CAST(DATEPART(HOUR,@CurrentDate) AS nvarchar),2))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Minute}',RIGHT('0' + CAST(DATEPART(MINUTE,@CurrentDate) AS nvarchar),2))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Second}',RIGHT('0' + CAST(DATEPART(SECOND,@CurrentDate) AS nvarchar),2))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Millisecond}',RIGHT('00' + CAST(DATEPART(MILLISECOND,@CurrentDate) AS nvarchar),3))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{Microsecond}',RIGHT('00000' + CAST(DATEPART(MICROSECOND,@CurrentDate) AS nvarchar),6))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{NumberOfFiles}',@CurrentNumberOfFiles)
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{FileExtension}',@CurrentFileExtension)
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{MajorVersion}',ISNULL(CAST(SERVERPROPERTY('ProductMajorVersion') AS nvarchar),PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),4)))
      SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{MinorVersion}',ISNULL(CAST(SERVERPROPERTY('ProductMinorVersion') AS nvarchar),PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar),3)))

      SELECT @CurrentMaxFilePathLength = CASE
      WHEN EXISTS (SELECT * FROM @CurrentDirectories) THEN (SELECT MAX(LEN(DirectoryPath + @DirectorySeparator)) FROM @CurrentDirectories)
      WHEN EXISTS (SELECT * FROM @CurrentURLs) THEN (SELECT MAX(LEN(DirectoryPath + @DirectorySeparator)) FROM @CurrentURLs)
      END
      + LEN(REPLACE(REPLACE(@CurrentDatabaseFileName,'{DatabaseName}',@CurrentDatabaseNameFS), '{FileNumber}', CASE WHEN @CurrentNumberOfFiles >= 1 AND @CurrentNumberOfFiles <= 9 THEN '1' WHEN @CurrentNumberOfFiles >= 10 THEN '01' END))

      -- The maximum length of a backup device is 259 characters
      IF @CurrentMaxFilePathLength > 259
      BEGIN
        SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{DatabaseName}',LEFT(@CurrentDatabaseNameFS,CASE WHEN (LEN(@CurrentDatabaseNameFS) + 259 - @CurrentMaxFilePathLength - 3) < 20 THEN 20 ELSE (LEN(@CurrentDatabaseNameFS) + 259 - @CurrentMaxFilePathLength - 3) END) + '...')
      END
      ELSE
      BEGIN
        SET @CurrentDatabaseFileName = REPLACE(@CurrentDatabaseFileName,'{DatabaseName}',@CurrentDatabaseNameFS)
      END

      IF EXISTS (SELECT * FROM @CurrentDirectories WHERE Mirror = 0)
      BEGIN
        SET @CurrentFileNumber = 0

        WHILE @CurrentFileNumber < @CurrentNumberOfFiles
        BEGIN
          SET @CurrentFileNumber = @CurrentFileNumber + 1

          SELECT @CurrentDirectoryPath = DirectoryPath
          FROM @CurrentDirectories
          WHERE @CurrentFileNumber >= (DirectoryNumber - 1) * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentDirectories WHERE Mirror = 0) + 1
          AND @CurrentFileNumber <= DirectoryNumber * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentDirectories WHERE Mirror = 0)
          AND Mirror = 0

          SET @CurrentFileName = REPLACE(@CurrentDatabaseFileName, '{FileNumber}', CASE WHEN @CurrentNumberOfFiles >= 1 AND @CurrentNumberOfFiles <= 9 THEN CAST(@CurrentFileNumber AS nvarchar) WHEN @CurrentNumberOfFiles >= 10 THEN RIGHT('0' + CAST(@CurrentFileNumber AS nvarchar),2) END)

          IF @CurrentDirectoryPath = 'NUL'
          BEGIN
            SET @CurrentFilePath = 'NUL'
          END
          ELSE
          BEGIN
            SET @CurrentFilePath = @CurrentDirectoryPath + @DirectorySeparator + @CurrentFileName
          END

          INSERT INTO @CurrentFiles ([Type], FilePath, Mirror)
          SELECT 'DISK', @CurrentFilePath, 0

          SET @CurrentDirectoryPath = NULL
          SET @CurrentFileName = NULL
          SET @CurrentFilePath = NULL
        END

        INSERT INTO @CurrentBackupSet (Mirror, VerifyCompleted)
        SELECT 0, 0
      END

      IF EXISTS (SELECT * FROM @CurrentDirectories WHERE Mirror = 1)
      BEGIN
        SET @CurrentFileNumber = 0

        WHILE @CurrentFileNumber < @CurrentNumberOfFiles
        BEGIN
          SET @CurrentFileNumber = @CurrentFileNumber + 1

          SELECT @CurrentDirectoryPath = DirectoryPath
          FROM @CurrentDirectories
          WHERE @CurrentFileNumber >= (DirectoryNumber - 1) * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentDirectories WHERE Mirror = 1) + 1
          AND @CurrentFileNumber <= DirectoryNumber * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentDirectories WHERE Mirror = 1)
          AND Mirror = 1

          SET @CurrentFileName = REPLACE(@CurrentDatabaseFileName, '{FileNumber}', CASE WHEN @CurrentNumberOfFiles > 1 AND @CurrentNumberOfFiles <= 9 THEN CAST(@CurrentFileNumber AS nvarchar) WHEN @CurrentNumberOfFiles >= 10 THEN RIGHT('0' + CAST(@CurrentFileNumber AS nvarchar),2) ELSE '' END)

          SET @CurrentFilePath = @CurrentDirectoryPath + @DirectorySeparator + @CurrentFileName

          INSERT INTO @CurrentFiles ([Type], FilePath, Mirror)
          SELECT 'DISK', @CurrentFilePath, 1

          SET @CurrentDirectoryPath = NULL
          SET @CurrentFileName = NULL
          SET @CurrentFilePath = NULL
        END

        INSERT INTO @CurrentBackupSet (Mirror, VerifyCompleted)
        SELECT 1, 0
      END

      IF EXISTS (SELECT * FROM @CurrentURLs WHERE Mirror = 0)
      BEGIN
        SET @CurrentFileNumber = 0

        WHILE @CurrentFileNumber < @CurrentNumberOfFiles
        BEGIN
          SET @CurrentFileNumber = @CurrentFileNumber + 1

          SELECT @CurrentDirectoryPath = DirectoryPath
          FROM @CurrentURLs
          WHERE @CurrentFileNumber >= (DirectoryNumber - 1) * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentURLs WHERE Mirror = 0) + 1
          AND @CurrentFileNumber <= DirectoryNumber * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentURLs WHERE Mirror = 0)
          AND Mirror = 0

          SET @CurrentFileName = REPLACE(@CurrentDatabaseFileName, '{FileNumber}', CASE WHEN @CurrentNumberOfFiles > 1 AND @CurrentNumberOfFiles <= 9 THEN CAST(@CurrentFileNumber AS nvarchar) WHEN @CurrentNumberOfFiles >= 10 THEN RIGHT('0' + CAST(@CurrentFileNumber AS nvarchar),2) ELSE '' END)

          SET @CurrentFilePath = @CurrentDirectoryPath + @DirectorySeparator + @CurrentFileName

          INSERT INTO @CurrentFiles ([Type], FilePath, Mirror)
          SELECT 'URL', @CurrentFilePath, 0

          SET @CurrentDirectoryPath = NULL
          SET @CurrentFileName = NULL
          SET @CurrentFilePath = NULL
        END

        INSERT INTO @CurrentBackupSet (Mirror, VerifyCompleted)
        SELECT 0, 0
      END

      IF EXISTS (SELECT * FROM @CurrentURLs WHERE Mirror = 1)
      BEGIN
        SET @CurrentFileNumber = 0

        WHILE @CurrentFileNumber < @CurrentNumberOfFiles
        BEGIN
          SET @CurrentFileNumber = @CurrentFileNumber + 1

          SELECT @CurrentDirectoryPath = DirectoryPath
          FROM @CurrentURLs
          WHERE @CurrentFileNumber >= (DirectoryNumber - 1) * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentURLs WHERE Mirror = 0) + 1
          AND @CurrentFileNumber <= DirectoryNumber * (SELECT @CurrentNumberOfFiles / COUNT(*) FROM @CurrentURLs WHERE Mirror = 0)
          AND Mirror = 1

          SET @CurrentFileName = REPLACE(@CurrentDatabaseFileName, '{FileNumber}', CASE WHEN @CurrentNumberOfFiles > 1 AND @CurrentNumberOfFiles <= 9 THEN CAST(@CurrentFileNumber AS nvarchar) WHEN @CurrentNumberOfFiles >= 10 THEN RIGHT('0' + CAST(@CurrentFileNumber AS nvarchar),2) ELSE '' END)

          SET @CurrentFilePath = @CurrentDirectoryPath + @DirectorySeparator + @CurrentFileName

          INSERT INTO @CurrentFiles ([Type], FilePath, Mirror)
          SELECT 'URL', @CurrentFilePath, 1

          SET @CurrentDirectoryPath = NULL
          SET @CurrentFileName = NULL
          SET @CurrentFilePath = NULL
        END

        INSERT INTO @CurrentBackupSet (Mirror, VerifyCompleted)
        SELECT 1, 0
      END

      -- Create directory
      IF @HostPlatform = 'Windows'
      AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
      AND NOT EXISTS(SELECT * FROM @CurrentDirectories WHERE DirectoryPath = 'NUL')
      BEGIN
        WHILE (1 = 1)
        BEGIN
          SELECT TOP 1 @CurrentDirectoryID = ID,
                       @CurrentDirectoryPath = DirectoryPath
          FROM @CurrentDirectories
          WHERE CreateCompleted = 0
          ORDER BY ID ASC

          IF @@ROWCOUNT = 0
          BEGIN
            BREAK
          END

          SET @CurrentDatabaseContext = 'master'

          SET @CurrentCommandType = 'xp_create_subdir'

          SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_create_subdir N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''' IF @ReturnCode <> 0 RAISERROR(''Error creating directory.'', 16, 1)'

          EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput = @Error
          IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput

          UPDATE @CurrentDirectories
          SET CreateCompleted = 1,
              CreateOutput = @CurrentCommandOutput
          WHERE ID = @CurrentDirectoryID

          SET @CurrentDirectoryID = NULL
          SET @CurrentDirectoryPath = NULL

          SET @CurrentDatabaseContext = NULL
          SET @CurrentCommand = NULL
          SET @CurrentCommandOutput = NULL
          SET @CurrentCommandType = NULL
        END
      END

      IF @CleanupMode = 'BEFORE_BACKUP'
      BEGIN
        INSERT INTO @CurrentCleanupDates (CleanupDate, Mirror)
        SELECT DATEADD(hh,-(@CleanupTime),SYSDATETIME()), 0

        IF NOT EXISTS(SELECT * FROM @CurrentCleanupDates WHERE (Mirror = 0 OR Mirror IS NULL) AND CleanupDate IS NULL)
        BEGIN
          UPDATE @CurrentDirectories
          SET CleanupDate = (SELECT MIN(CleanupDate)
                             FROM @CurrentCleanupDates
                             WHERE (Mirror = 0 OR Mirror IS NULL)),
              CleanupMode = 'BEFORE_BACKUP'
          WHERE Mirror = 0
        END
      END

      IF @MirrorCleanupMode = 'BEFORE_BACKUP'
      BEGIN
        INSERT INTO @CurrentCleanupDates (CleanupDate, Mirror)
        SELECT DATEADD(hh,-(@MirrorCleanupTime),SYSDATETIME()), 1

        IF NOT EXISTS(SELECT * FROM @CurrentCleanupDates WHERE (Mirror = 1 OR Mirror IS NULL) AND CleanupDate IS NULL)
        BEGIN
          UPDATE @CurrentDirectories
          SET CleanupDate = (SELECT MIN(CleanupDate)
                             FROM @CurrentCleanupDates
                             WHERE (Mirror = 1 OR Mirror IS NULL)),
              CleanupMode = 'BEFORE_BACKUP'
          WHERE Mirror = 1
        END
      END

      -- Delete old backup files, before backup
      IF NOT EXISTS (SELECT * FROM @CurrentDirectories WHERE CreateOutput <> 0 OR CreateOutput IS NULL)
      AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
      AND @CurrentBackupType = @BackupType
      BEGIN
        WHILE (1 = 1)
        BEGIN
          SELECT TOP 1 @CurrentDirectoryID = ID,
                       @CurrentDirectoryPath = DirectoryPath,
                       @CurrentCleanupDate = CleanupDate
          FROM @CurrentDirectories
          WHERE CleanupDate IS NOT NULL
          AND CleanupMode = 'BEFORE_BACKUP'
          AND CleanupCompleted = 0
          ORDER BY ID ASC

          IF @@ROWCOUNT = 0
          BEGIN
            BREAK
          END

          IF @BackupSoftware IS NULL
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_delete_file'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_delete_file 0, N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + @CurrentFileExtension + ''', ''' + CONVERT(nvarchar(19),@CurrentCleanupDate,126) + ''' IF @ReturnCode <> 0 RAISERROR(''Error deleting files.'', 16, 1)'
          END

          IF @BackupSoftware = 'LITESPEED'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_slssqlmaint'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_slssqlmaint N''-MAINTDEL -DELFOLDER "' + REPLACE(@CurrentDirectoryPath,'''','''''') + '" -DELEXTENSION "' + @CurrentFileExtension + '" -DELUNIT "' + CAST(DATEDIFF(mi,@CurrentCleanupDate,SYSDATETIME()) + 1 AS nvarchar) + '" -DELUNITTYPE "minutes" -DELUSEAGE'' IF @ReturnCode <> 0 RAISERROR(''Error deleting LiteSpeed backup files.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLBACKUP'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'sqbutility'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.sqbutility 1032, N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''', N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + CASE WHEN @CurrentBackupType = 'FULL' THEN 'D' WHEN @CurrentBackupType = 'DIFF' THEN 'I' WHEN @CurrentBackupType = 'LOG' THEN 'L' END + ''', ''' + CAST(DATEDIFF(hh,@CurrentCleanupDate,SYSDATETIME()) + 1 AS nvarchar) + 'h'', ' + ISNULL('''' + REPLACE(@EncryptionKey,'''','''''') + '''','NULL') + ' IF @ReturnCode <> 0 RAISERROR(''Error deleting SQLBackup backup files.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLSAFE'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_ss_delete'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_ss_delete @filename = N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + '\*.' + @CurrentFileExtension + ''', @age = ''' + CAST(DATEDIFF(mi,@CurrentCleanupDate,SYSDATETIME()) + 1 AS nvarchar) + 'Minutes'' IF @ReturnCode <> 0 RAISERROR(''Error deleting SQLsafe backup files.'', 16, 1)'
          END

          EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput = @Error
          IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput

          UPDATE @CurrentDirectories
          SET CleanupCompleted = 1,
              CleanupOutput = @CurrentCommandOutput
          WHERE ID = @CurrentDirectoryID

          SET @CurrentDirectoryID = NULL
          SET @CurrentDirectoryPath = NULL
          SET @CurrentCleanupDate = NULL

          SET @CurrentDatabaseContext = NULL
          SET @CurrentCommand = NULL
          SET @CurrentCommandOutput = NULL
          SET @CurrentCommandType = NULL
        END
      END

      -- Perform a backup
      IF NOT EXISTS (SELECT * FROM @CurrentDirectories WHERE DirectoryPath <> 'NUL' AND (CreateOutput <> 0 OR CreateOutput IS NULL)) OR @HostPlatform = 'Linux'
      BEGIN
        IF @BackupSoftware IS NULL
        BEGIN
          SET @CurrentDatabaseContext = 'master'

          SELECT @CurrentCommandType = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP_DATABASE'
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP_LOG'
          END

          SELECT @CurrentCommand = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP DATABASE ' + QUOTENAME(@CurrentDatabaseName)
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP LOG ' + QUOTENAME(@CurrentDatabaseName)
          END

          IF @ReadWriteFileGroups = 'Y' AND @CurrentDatabaseName <> 'master' SET @CurrentCommand += ' READ_WRITE_FILEGROUPS'

          SET @CurrentCommand += ' TO'

          SELECT @CurrentCommand += ' ' + [Type] + ' = N''' + REPLACE(FilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) <> @CurrentNumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          WHERE Mirror = 0
          ORDER BY FilePath ASC

          IF EXISTS(SELECT * FROM @CurrentFiles WHERE Mirror = 1)
          BEGIN
            SET @CurrentCommand += ' MIRROR TO'

            SELECT @CurrentCommand += ' ' + [Type] + ' = N''' + REPLACE(FilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) <> @CurrentNumberOfFiles THEN ',' ELSE '' END
            FROM @CurrentFiles
            WHERE Mirror = 1
            ORDER BY FilePath ASC
          END

          SET @CurrentCommand += ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand += 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand += 'NO_CHECKSUM'

          IF @Version >= 10
          BEGIN
            SET @CurrentCommand += CASE WHEN @Compress = 'Y' AND (@CurrentIsEncrypted = 0 OR (@CurrentIsEncrypted = 1 AND (@Version >= 13 OR SERVERPROPERTY('EngineEdition') = 8) AND @CurrentMaxTransferSize >= 65537)) THEN ', COMPRESSION' ELSE ', NO_COMPRESSION' END
          END

          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand += ', DIFFERENTIAL'

          IF EXISTS(SELECT * FROM @CurrentFiles WHERE Mirror = 1)
          BEGIN
            SET @CurrentCommand += ', FORMAT'
          END

          IF @CopyOnly = 'Y' SET @CurrentCommand += ', COPY_ONLY'
          IF @NoRecovery = 'Y' AND @CurrentBackupType = 'LOG' SET @CurrentCommand += ', NORECOVERY'
          IF @Init = 'Y' SET @CurrentCommand += ', INIT'
          IF @Format = 'Y' SET @CurrentCommand += ', FORMAT'
          IF @BlockSize IS NOT NULL SET @CurrentCommand += ', BLOCKSIZE = ' + CAST(@BlockSize AS nvarchar)
          IF @BufferCount IS NOT NULL SET @CurrentCommand += ', BUFFERCOUNT = ' + CAST(@BufferCount AS nvarchar)
          IF @CurrentMaxTransferSize IS NOT NULL SET @CurrentCommand += ', MAXTRANSFERSIZE = ' + CAST(@CurrentMaxTransferSize AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand += ', DESCRIPTION = N''' + REPLACE(@Description,'''','''''') + ''''
          IF @Encrypt = 'Y' SET @CurrentCommand += ', ENCRYPTION (ALGORITHM = ' + UPPER(@EncryptionAlgorithm) + ', '
          IF @Encrypt = 'Y' AND @ServerCertificate IS NOT NULL SET @CurrentCommand += 'SERVER CERTIFICATE = ' + QUOTENAME(@ServerCertificate)
          IF @Encrypt = 'Y' AND @ServerAsymmetricKey IS NOT NULL SET @CurrentCommand += 'SERVER ASYMMETRIC KEY = ' + QUOTENAME(@ServerAsymmetricKey)
          IF @Encrypt = 'Y' SET @CurrentCommand += ')'
          IF @URL IS NOT NULL AND @Credential IS NOT NULL SET @CurrentCommand += ', CREDENTIAL = N''' + REPLACE(@Credential,'''','''''') + ''''
        END

        IF @BackupSoftware = 'LITESPEED'
        BEGIN
          SET @CurrentDatabaseContext = 'master'

          SELECT @CurrentCommandType = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'xp_backup_database'
          WHEN @CurrentBackupType = 'LOG' THEN 'xp_backup_log'
          END

          SELECT @CurrentCommand = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_backup_database @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''
          WHEN @CurrentBackupType = 'LOG' THEN 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_backup_log @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''
          END

          SELECT @CurrentCommand += ', @filename = N''' + REPLACE(FilePath,'''','''''') + ''''
          FROM @CurrentFiles
          WHERE Mirror = 0
          ORDER BY FilePath ASC

          IF EXISTS(SELECT * FROM @CurrentFiles WHERE Mirror = 1)
          BEGIN
            SELECT @CurrentCommand += ', @mirror = N''' + REPLACE(FilePath,'''','''''') + ''''
            FROM @CurrentFiles
            WHERE Mirror = 1
            ORDER BY FilePath ASC
          END

          SET @CurrentCommand += ', @with = '''
          IF @CheckSum = 'Y' SET @CurrentCommand += 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand += 'NO_CHECKSUM'
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand += ', DIFFERENTIAL'
          IF @CopyOnly = 'Y' SET @CurrentCommand += ', COPY_ONLY'
          IF @NoRecovery = 'Y' AND @CurrentBackupType = 'LOG' SET @CurrentCommand += ', NORECOVERY'
          IF @BlockSize IS NOT NULL SET @CurrentCommand += ', BLOCKSIZE = ' + CAST(@BlockSize AS nvarchar)
          SET @CurrentCommand += ''''
          IF @ReadWriteFileGroups = 'Y' AND @CurrentDatabaseName <> 'master' SET @CurrentCommand += ', @read_write_filegroups = 1'
          IF @CompressionLevel IS NOT NULL SET @CurrentCommand += ', @compressionlevel = ' + CAST(@CompressionLevel AS nvarchar)
          IF @AdaptiveCompression IS NOT NULL SET @CurrentCommand += ', @adaptivecompression = ''' + CASE WHEN @AdaptiveCompression = 'SIZE' THEN 'Size' WHEN @AdaptiveCompression = 'SPEED' THEN 'Speed' END + ''''
          IF @BufferCount IS NOT NULL SET @CurrentCommand += ', @buffercount = ' + CAST(@BufferCount AS nvarchar)
          IF @CurrentMaxTransferSize IS NOT NULL SET @CurrentCommand += ', @maxtransfersize = ' + CAST(@CurrentMaxTransferSize AS nvarchar)
          IF @Threads IS NOT NULL SET @CurrentCommand += ', @threads = ' + CAST(@Threads AS nvarchar)
          IF @Init = 'Y' SET @CurrentCommand += ', @init = 1'
          IF @Format = 'Y' SET @CurrentCommand += ', @format = 1'
          IF @Throttle IS NOT NULL SET @CurrentCommand += ', @throttle = ' + CAST(@Throttle AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand += ', @desc = N''' + REPLACE(@Description,'''','''''') + ''''
          IF @ObjectLevelRecoveryMap = 'Y' SET @CurrentCommand += ', @olrmap = 1'

          IF @EncryptionAlgorithm IS NOT NULL SET @CurrentCommand += ', @cryptlevel = ' + CASE
          WHEN @EncryptionAlgorithm = 'RC2_40' THEN '0'
          WHEN @EncryptionAlgorithm = 'RC2_56' THEN '1'
          WHEN @EncryptionAlgorithm = 'RC2_112' THEN '2'
          WHEN @EncryptionAlgorithm = 'RC2_128' THEN '3'
          WHEN @EncryptionAlgorithm = 'TRIPLE_DES_3KEY' THEN '4'
          WHEN @EncryptionAlgorithm = 'RC4_128' THEN '5'
          WHEN @EncryptionAlgorithm = 'AES_128' THEN '6'
          WHEN @EncryptionAlgorithm = 'AES_192' THEN '7'
          WHEN @EncryptionAlgorithm = 'AES_256' THEN '8'
          END

          IF @EncryptionKey IS NOT NULL SET @CurrentCommand += ', @encryptionkey = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''
          SET @CurrentCommand += ' IF @ReturnCode <> 0 RAISERROR(''Error performing LiteSpeed backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'SQLBACKUP'
        BEGIN
          SET @CurrentDatabaseContext = 'master'

          SET @CurrentCommandType = 'sqlbackup'

          SELECT @CurrentCommand = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP DATABASE ' + QUOTENAME(@CurrentDatabaseName)
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP LOG ' + QUOTENAME(@CurrentDatabaseName)
          END

          IF @ReadWriteFileGroups = 'Y' AND @CurrentDatabaseName <> 'master' SET @CurrentCommand += ' READ_WRITE_FILEGROUPS'

          SET @CurrentCommand += ' TO'

          SELECT @CurrentCommand += ' DISK = N''' + REPLACE(FilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) <> @CurrentNumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          WHERE Mirror = 0
          ORDER BY FilePath ASC

          SET @CurrentCommand += ' WITH '

          IF EXISTS(SELECT * FROM @CurrentFiles WHERE Mirror = 1)
          BEGIN
            SET @CurrentCommand += ' MIRRORFILE' + ' = N''' + REPLACE((SELECT FilePath FROM @CurrentFiles WHERE Mirror = 1),'''','''''') + ''', '
          END

          IF @CheckSum = 'Y' SET @CurrentCommand += 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand += 'NO_CHECKSUM'
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand += ', DIFFERENTIAL'
          IF @CopyOnly = 'Y' SET @CurrentCommand += ', COPY_ONLY'
          IF @NoRecovery = 'Y' AND @CurrentBackupType = 'LOG' SET @CurrentCommand += ', NORECOVERY'
          IF @Init = 'Y' SET @CurrentCommand += ', INIT'
          IF @Format = 'Y' SET @CurrentCommand += ', FORMAT'
          IF @CompressionLevel IS NOT NULL SET @CurrentCommand += ', COMPRESSION = ' + CAST(@CompressionLevel AS nvarchar)
          IF @Threads IS NOT NULL SET @CurrentCommand += ', THREADCOUNT = ' + CAST(@Threads AS nvarchar)
          IF @CurrentMaxTransferSize IS NOT NULL SET @CurrentCommand += ', MAXTRANSFERSIZE = ' + CAST(@CurrentMaxTransferSize AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand += ', DESCRIPTION = N''' + REPLACE(@Description,'''','''''') + ''''

          IF @EncryptionAlgorithm IS NOT NULL SET @CurrentCommand += ', KEYSIZE = ' + CASE
          WHEN @EncryptionAlgorithm = 'AES_128' THEN '128'
          WHEN @EncryptionAlgorithm = 'AES_256' THEN '256'
          END

          IF @EncryptionKey IS NOT NULL SET @CurrentCommand += ', PASSWORD = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''
          SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.sqlbackup N''-SQL "' + REPLACE(@CurrentCommand,'''','''''') + '"''' + ' IF @ReturnCode <> 0 RAISERROR(''Error performing SQLBackup backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'SQLSAFE'
        BEGIN
          SET @CurrentDatabaseContext = 'master'

          SET @CurrentCommandType = 'xp_ss_backup'

          SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_ss_backup @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''

          SELECT @CurrentCommand += ', ' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) = 1 THEN '@filename' ELSE '@backupfile' END + ' = N''' + REPLACE(FilePath,'''','''''') + ''''
          FROM @CurrentFiles
          WHERE Mirror = 0
          ORDER BY FilePath ASC

          SELECT @CurrentCommand += ', @mirrorfile = N''' + REPLACE(FilePath,'''','''''') + ''''
          FROM @CurrentFiles
          WHERE Mirror = 1
          ORDER BY FilePath ASC

          SET @CurrentCommand += ', @backuptype = ' + CASE WHEN @CurrentBackupType = 'FULL' THEN '''Full''' WHEN @CurrentBackupType = 'DIFF' THEN '''Differential''' WHEN @CurrentBackupType = 'LOG' THEN '''Log''' END
          IF @ReadWriteFileGroups = 'Y' AND @CurrentDatabaseName <> 'master' SET @CurrentCommand += ', @readwritefilegroups = 1'
          SET @CurrentCommand += ', @checksum = ' + CASE WHEN @CheckSum = 'Y' THEN '1' WHEN @CheckSum = 'N' THEN '0' END
          SET @CurrentCommand += ', @copyonly = ' + CASE WHEN @CopyOnly = 'Y' THEN '1' WHEN @CopyOnly = 'N' THEN '0' END
          IF @CompressionLevel IS NOT NULL SET @CurrentCommand += ', @compressionlevel = ' + CAST(@CompressionLevel AS nvarchar)
          IF @Threads IS NOT NULL SET @CurrentCommand += ', @threads = ' + CAST(@Threads AS nvarchar)
          IF @Init = 'Y' SET @CurrentCommand += ', @overwrite = 1'
          IF @Description IS NOT NULL SET @CurrentCommand += ', @desc = N''' + REPLACE(@Description,'''','''''') + ''''

          IF @EncryptionAlgorithm IS NOT NULL SET @CurrentCommand += ', @encryptiontype = N''' + CASE
          WHEN @EncryptionAlgorithm = 'AES_128' THEN 'AES128'
          WHEN @EncryptionAlgorithm = 'AES_256' THEN 'AES256'
          END + ''''

          IF @EncryptionKey IS NOT NULL SET @CurrentCommand += ', @encryptedbackuppassword = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''
          SET @CurrentCommand += ' IF @ReturnCode <> 0 RAISERROR(''Error performing SQLsafe backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'DATA_DOMAIN_BOOST'
        BEGIN
          SET @CurrentDatabaseContext = 'master'

          SET @CurrentCommandType = 'emc_run_backup'

          SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.emc_run_backup '''

          SET @CurrentCommand += ' -c ' + CASE WHEN @CurrentAvailabilityGroup IS NOT NULL THEN @Cluster ELSE CAST(SERVERPROPERTY('MachineName') AS nvarchar) END

          SET @CurrentCommand += ' -l ' + CASE
          WHEN @CurrentBackupType = 'FULL' THEN 'full'
          WHEN @CurrentBackupType = 'DIFF' THEN 'diff'
          WHEN @CurrentBackupType = 'LOG' THEN 'incr'
          END

          IF @NoRecovery = 'Y' SET @CurrentCommand += ' -H'

          IF @CleanupTime IS NOT NULL SET @CurrentCommand += ' -y +' + CAST(@CleanupTime/24 + CASE WHEN @CleanupTime%24 > 0 THEN 1 ELSE 0 END AS nvarchar) + 'd'

          IF @CheckSum = 'Y' SET @CurrentCommand += ' -k'

          SET @CurrentCommand += ' -S ' + CAST(@CurrentNumberOfFiles AS nvarchar)

          IF @Description IS NOT NULL SET @CurrentCommand += ' -b "' + REPLACE(@Description,'''','''''') + '"'

          IF @BufferCount IS NOT NULL SET @CurrentCommand += ' -O "BUFFERCOUNT=' + CAST(@BufferCount AS nvarchar) + '"'

          IF @ReadWriteFileGroups = 'Y' AND @CurrentDatabaseName <> 'master' SET @CurrentCommand += ' -O "READ_WRITE_FILEGROUPS"'

          IF @DataDomainBoostHost IS NOT NULL SET @CurrentCommand += ' -a "NSR_DFA_SI_DD_HOST=' + REPLACE(@DataDomainBoostHost,'''','''''') + '"'
          IF @DataDomainBoostUser IS NOT NULL SET @CurrentCommand += ' -a "NSR_DFA_SI_DD_USER=' + REPLACE(@DataDomainBoostUser,'''','''''') + '"'
          IF @DataDomainBoostDevicePath IS NOT NULL SET @CurrentCommand += ' -a "NSR_DFA_SI_DEVICE_PATH=' + REPLACE(@DataDomainBoostDevicePath,'''','''''') + '"'
          IF @DataDomainBoostLockboxPath IS NOT NULL SET @CurrentCommand += ' -a "NSR_DFA_SI_DD_LOCKBOX_PATH=' + REPLACE(@DataDomainBoostLockboxPath,'''','''''') + '"'
          SET @CurrentCommand += ' -a "NSR_SKIP_NON_BACKUPABLE_STATE_DB=TRUE"'
          SET @CurrentCommand += ' -a "BACKUP_PROMOTION=NONE"'
          IF @CopyOnly = 'Y' SET @CurrentCommand += ' -a "NSR_COPY_ONLY=TRUE"'

          IF SERVERPROPERTY('InstanceName') IS NULL SET @CurrentCommand += ' "MSSQL' + ':' + REPLACE(REPLACE(@CurrentDatabaseName,'''',''''''),'.','\.') + '"'
          IF SERVERPROPERTY('InstanceName') IS NOT NULL SET @CurrentCommand += ' "MSSQL$' + CAST(SERVERPROPERTY('InstanceName') AS nvarchar) + ':' + REPLACE(REPLACE(@CurrentDatabaseName,'''',''''''),'.','\.') + '"'

          SET @CurrentCommand += ''''

          SET @CurrentCommand += ' IF @ReturnCode <> 0 RAISERROR(''Error performing Data Domain Boost backup.'', 16, 1)'
        END

        EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput = @Error
        IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
        SET @CurrentBackupOutput = @CurrentCommandOutput
      END

      -- Verify the backup
      IF @CurrentBackupOutput = 0 AND @Verify = 'Y'
      BEGIN
        WHILE (1 = 1)
        BEGIN
          SELECT TOP 1 @CurrentBackupSetID = ID,
                       @CurrentIsMirror = Mirror
          FROM @CurrentBackupSet
          WHERE VerifyCompleted = 0
          ORDER BY ID ASC

          IF @@ROWCOUNT = 0
          BEGIN
            BREAK
          END

          IF @BackupSoftware IS NULL
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'RESTORE_VERIFYONLY'

            SET @CurrentCommand = 'RESTORE VERIFYONLY FROM'

            SELECT @CurrentCommand += ' ' + [Type] + ' = N''' + REPLACE(FilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) <> @CurrentNumberOfFiles THEN ',' ELSE '' END
            FROM @CurrentFiles
            WHERE Mirror = @CurrentIsMirror
            ORDER BY FilePath ASC

            SET @CurrentCommand += ' WITH '
            IF @CheckSum = 'Y' SET @CurrentCommand += 'CHECKSUM'
            IF @CheckSum = 'N' SET @CurrentCommand += 'NO_CHECKSUM'
            IF @URL IS NOT NULL AND @Credential IS NOT NULL SET @CurrentCommand += ', CREDENTIAL = N''' + REPLACE(@Credential,'''','''''') + ''''
          END

          IF @BackupSoftware = 'LITESPEED'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_restore_verifyonly'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_restore_verifyonly'

            SELECT @CurrentCommand += ' @filename = N''' + REPLACE(FilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) <> @CurrentNumberOfFiles THEN ',' ELSE '' END
            FROM @CurrentFiles
            WHERE Mirror = @CurrentIsMirror
            ORDER BY FilePath ASC

            SET @CurrentCommand += ', @with = '''
            IF @CheckSum = 'Y' SET @CurrentCommand += 'CHECKSUM'
            IF @CheckSum = 'N' SET @CurrentCommand += 'NO_CHECKSUM'
            SET @CurrentCommand += ''''
            IF @EncryptionKey IS NOT NULL SET @CurrentCommand += ', @encryptionkey = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''

            SET @CurrentCommand += ' IF @ReturnCode <> 0 RAISERROR(''Error verifying LiteSpeed backup.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLBACKUP'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'sqlbackup'

            SET @CurrentCommand = 'RESTORE VERIFYONLY FROM'

            SELECT @CurrentCommand += ' DISK = N''' + REPLACE(FilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) <> @CurrentNumberOfFiles THEN ',' ELSE '' END
            FROM @CurrentFiles
            WHERE Mirror = @CurrentIsMirror
            ORDER BY FilePath ASC

            SET @CurrentCommand += ' WITH '
            IF @CheckSum = 'Y' SET @CurrentCommand += 'CHECKSUM'
            IF @CheckSum = 'N' SET @CurrentCommand += 'NO_CHECKSUM'
            IF @EncryptionKey IS NOT NULL SET @CurrentCommand += ', PASSWORD = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.sqlbackup N''-SQL "' + REPLACE(@CurrentCommand,'''','''''') + '"''' + ' IF @ReturnCode <> 0 RAISERROR(''Error verifying SQLBackup backup.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLSAFE'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_ss_verify'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_ss_verify @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''

            SELECT @CurrentCommand += ', ' + CASE WHEN ROW_NUMBER() OVER (ORDER BY FilePath ASC) = 1 THEN '@filename' ELSE '@backupfile' END + ' = N''' + REPLACE(FilePath,'''','''''') + ''''
            FROM @CurrentFiles
            WHERE Mirror = @CurrentIsMirror
            ORDER BY FilePath ASC

            SET @CurrentCommand += ' IF @ReturnCode <> 0 RAISERROR(''Error verifying SQLsafe backup.'', 16, 1)'
          END

          EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput = @Error
          IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput

          UPDATE @CurrentBackupSet
          SET VerifyCompleted = 1,
              VerifyOutput = @CurrentCommandOutput
          WHERE ID = @CurrentBackupSetID

          SET @CurrentBackupSetID = NULL
          SET @CurrentIsMirror = NULL

          SET @CurrentDatabaseContext = NULL
          SET @CurrentCommand = NULL
          SET @CurrentCommandOutput = NULL
          SET @CurrentCommandType = NULL
        END
      END

      IF @CleanupMode = 'AFTER_BACKUP'
      BEGIN
        INSERT INTO @CurrentCleanupDates (CleanupDate, Mirror)
        SELECT DATEADD(hh,-(@CleanupTime),SYSDATETIME()), 0

        IF NOT EXISTS(SELECT * FROM @CurrentCleanupDates WHERE (Mirror = 0 OR Mirror IS NULL) AND CleanupDate IS NULL)
        BEGIN
          UPDATE @CurrentDirectories
          SET CleanupDate = (SELECT MIN(CleanupDate)
                             FROM @CurrentCleanupDates
                             WHERE (Mirror = 0 OR Mirror IS NULL)),
              CleanupMode = 'AFTER_BACKUP'
          WHERE Mirror = 0
        END
      END

      IF @MirrorCleanupMode = 'AFTER_BACKUP'
      BEGIN
        INSERT INTO @CurrentCleanupDates (CleanupDate, Mirror)
        SELECT DATEADD(hh,-(@MirrorCleanupTime),SYSDATETIME()), 1

        IF NOT EXISTS(SELECT * FROM @CurrentCleanupDates WHERE (Mirror = 1 OR Mirror IS NULL) AND CleanupDate IS NULL)
        BEGIN
          UPDATE @CurrentDirectories
          SET CleanupDate = (SELECT MIN(CleanupDate)
                             FROM @CurrentCleanupDates
                             WHERE (Mirror = 1 OR Mirror IS NULL)),
              CleanupMode = 'AFTER_BACKUP'
          WHERE Mirror = 1
        END
      END

      -- Delete old backup files, after backup
      IF ((@CurrentBackupOutput = 0 AND @Verify = 'N')
      OR (@CurrentBackupOutput = 0 AND @Verify = 'Y' AND NOT EXISTS (SELECT * FROM @CurrentBackupSet WHERE VerifyOutput <> 0 OR VerifyOutput IS NULL)))
      AND (@BackupSoftware <> 'DATA_DOMAIN_BOOST' OR @BackupSoftware IS NULL)
      AND @CurrentBackupType = @BackupType
      BEGIN
        WHILE (1 = 1)
        BEGIN
          SELECT TOP 1 @CurrentDirectoryID = ID,
                       @CurrentDirectoryPath = DirectoryPath,
                       @CurrentCleanupDate = CleanupDate
          FROM @CurrentDirectories
          WHERE CleanupDate IS NOT NULL
          AND CleanupMode = 'AFTER_BACKUP'
          AND CleanupCompleted = 0
          ORDER BY ID ASC

          IF @@ROWCOUNT = 0
          BEGIN
            BREAK
          END

          IF @BackupSoftware IS NULL
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_delete_file'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_delete_file 0, N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + @CurrentFileExtension + ''', ''' + CONVERT(nvarchar(19),@CurrentCleanupDate,126) + ''' IF @ReturnCode <> 0 RAISERROR(''Error deleting files.'', 16, 1)'
          END

          IF @BackupSoftware = 'LITESPEED'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_slssqlmaint'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_slssqlmaint N''-MAINTDEL -DELFOLDER "' + REPLACE(@CurrentDirectoryPath,'''','''''') + '" -DELEXTENSION "' + @CurrentFileExtension + '" -DELUNIT "' + CAST(DATEDIFF(mi,@CurrentCleanupDate,SYSDATETIME()) + 1 AS nvarchar) + '" -DELUNITTYPE "minutes" -DELUSEAGE'' IF @ReturnCode <> 0 RAISERROR(''Error deleting LiteSpeed backup files.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLBACKUP'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'sqbutility'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.sqbutility 1032, N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''', N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + CASE WHEN @CurrentBackupType = 'FULL' THEN 'D' WHEN @CurrentBackupType = 'DIFF' THEN 'I' WHEN @CurrentBackupType = 'LOG' THEN 'L' END + ''', ''' + CAST(DATEDIFF(hh,@CurrentCleanupDate,SYSDATETIME()) + 1 AS nvarchar) + 'h'', ' + ISNULL('''' + REPLACE(@EncryptionKey,'''','''''') + '''','NULL') + ' IF @ReturnCode <> 0 RAISERROR(''Error deleting SQLBackup backup files.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLSAFE'
          BEGIN
            SET @CurrentDatabaseContext = 'master'

            SET @CurrentCommandType = 'xp_ss_delete'

            SET @CurrentCommand = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = dbo.xp_ss_delete @filename = N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + '\*.' + @CurrentFileExtension + ''', @age = ''' + CAST(DATEDIFF(mi,@CurrentCleanupDate,SYSDATETIME()) + 1 AS nvarchar) + 'Minutes'' IF @ReturnCode <> 0 RAISERROR(''Error deleting SQLsafe backup files.'', 16, 1)'
          END

          EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput = @Error
          IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput

          UPDATE @CurrentDirectories
          SET CleanupCompleted = 1,
              CleanupOutput = @CurrentCommandOutput
          WHERE ID = @CurrentDirectoryID

          SET @CurrentDirectoryID = NULL
          SET @CurrentDirectoryPath = NULL
          SET @CurrentCleanupDate = NULL

          SET @CurrentDatabaseContext = NULL
          SET @CurrentCommand = NULL
          SET @CurrentCommandOutput = NULL
          SET @CurrentCommandType = NULL
        END
      END
    END

    IF @CurrentDatabaseState = 'SUSPECT'
    BEGIN
      SET @ErrorMessage = 'The database ' + QUOTENAME(@CurrentDatabaseName) + ' is in a SUSPECT state.'
      RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT
      SET @Error = @@ERROR
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
    END

    -- Update that the database is completed
    IF @DatabasesInParallel = 'Y'
    BEGIN
      UPDATE dbo.QueueDatabase
      SET DatabaseEndTime = SYSDATETIME()
      WHERE QueueID = @QueueID
      AND DatabaseName = @CurrentDatabaseName
    END
    ELSE
    BEGIN
      UPDATE @tmpDatabases
      SET Completed = 1
      WHERE Selected = 1
      AND Completed = 0
      AND ID = @CurrentDBID
    END

    -- Clear variables
    SET @CurrentDBID = NULL
    SET @CurrentDatabaseName = NULL

    SET @CurrentDatabase_sp_executesql = NULL

    SET @CurrentUserAccess = NULL
    SET @CurrentIsReadOnly = NULL
    SET @CurrentDatabaseState = NULL
    SET @CurrentInStandby = NULL
    SET @CurrentRecoveryModel = NULL
    SET @CurrentIsEncrypted = NULL
    SET @CurrentDatabaseSize = NULL

    SET @CurrentBackupType = NULL
    SET @CurrentMaxTransferSize = NULL
    SET @CurrentNumberOfFiles = NULL
    SET @CurrentFileExtension = NULL
    SET @CurrentFileNumber = NULL
    SET @CurrentDifferentialBaseLSN = NULL
    SET @CurrentDifferentialBaseIsSnapshot = NULL
    SET @CurrentLogLSN = NULL
    SET @CurrentLatestBackup = NULL
    SET @CurrentDatabaseNameFS = NULL
    SET @CurrentDirectoryStructure = NULL
    SET @CurrentDatabaseFileName = NULL
    SET @CurrentMaxFilePathLength = NULL
    SET @CurrentDate = NULL
    SET @CurrentCleanupDate = NULL
    SET @CurrentIsDatabaseAccessible = NULL
    SET @CurrentReplicaID = NULL
    SET @CurrentAvailabilityGroupID = NULL
    SET @CurrentAvailabilityGroup = NULL
    SET @CurrentAvailabilityGroupRole = NULL
    SET @CurrentAvailabilityGroupBackupPreference = NULL
    SET @CurrentIsPreferredBackupReplica = NULL
    SET @CurrentDatabaseMirroringRole = NULL
    SET @CurrentLogShippingRole = NULL
    SET @CurrentLastLogBackup = NULL
    SET @CurrentLogSizeSinceLastLogBackup = NULL
    SET @CurrentAllocatedExtentPageCount = NULL
    SET @CurrentModifiedExtentPageCount = NULL

    SET @CurrentDatabaseContext = NULL
    SET @CurrentCommand = NULL
    SET @CurrentCommandOutput = NULL
    SET @CurrentCommandType = NULL

    SET @CurrentBackupOutput = NULL

    DELETE FROM @CurrentDirectories
    DELETE FROM @CurrentURLs
    DELETE FROM @CurrentFiles
    DELETE FROM @CurrentCleanupDates
    DELETE FROM @CurrentBackupSet

  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  Logging:
  SET @EndMessage = 'Date and time: ' + CONVERT(nvarchar,SYSDATETIME(),120)
  RAISERROR('%s',10,1,@EndMessage) WITH NOWAIT

  RAISERROR(@EmptyLine,10,1) WITH NOWAIT

  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END
GO

ALTER AUTHORIZATION ON [dbo].[DatabaseBackup] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[DatabaseBackup] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[DatabaseIntegrityCheck]    Script Date: 10/13/2021 12:39:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DatabaseIntegrityCheck]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[DatabaseIntegrityCheck] AS' 
END
GO

ALTER PROCEDURE [dbo].[DatabaseIntegrityCheck]

@Databases nvarchar(max) = NULL,
@CheckCommands nvarchar(max) = 'CHECKDB',
@PhysicalOnly nvarchar(max) = 'N',
@DataPurity nvarchar(max) = 'N',
@NoIndex nvarchar(max) = 'N',
@ExtendedLogicalChecks nvarchar(max) = 'N',
@TabLock nvarchar(max) = 'N',
@FileGroups nvarchar(max) = NULL,
@Objects nvarchar(max) = NULL,
@MaxDOP int = NULL,
@AvailabilityGroups nvarchar(max) = NULL,
@AvailabilityGroupReplicas nvarchar(max) = 'ALL',
@Updateability nvarchar(max) = 'ALL',
@TimeLimit int = NULL,
@LockTimeout int = NULL,
@LockMessageSeverity int = 16,
@StringDelimiter nvarchar(max) = ',',
@DatabaseOrder nvarchar(max) = NULL,
@DatabasesInParallel nvarchar(max) = 'N',
@LogToTable nvarchar(max) = 'N',
@Execute nvarchar(max) = 'Y'

AS

BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source:  https://ola.hallengren.com                                                        //--
  --// License: https://ola.hallengren.com/license.html                                           //--
  --// GitHub:  https://github.com/olahallengren/sql-server-maintenance-solution                  //--
  --// Version: 2020-12-06 00:32:13                                                               //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @DatabaseMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)
  DECLARE @Severity int

  DECLARE @StartTime datetime2 = SYSDATETIME()
  DECLARE @SchemaName nvarchar(max) = OBJECT_SCHEMA_NAME(@@PROCID)
  DECLARE @ObjectName nvarchar(max) = OBJECT_NAME(@@PROCID)
  DECLARE @VersionTimestamp nvarchar(max) = SUBSTRING(OBJECT_DEFINITION(@@PROCID),CHARINDEX('--// Version: ',OBJECT_DEFINITION(@@PROCID)) + LEN('--// Version: ') + 1, 19)
  DECLARE @Parameters nvarchar(max)

  DECLARE @HostPlatform nvarchar(max)

  DECLARE @QueueID int
  DECLARE @QueueStartTime datetime2

  DECLARE @CurrentDBID int
  DECLARE @CurrentDatabaseName nvarchar(max)

  DECLARE @CurrentDatabase_sp_executesql nvarchar(max)

  DECLARE @CurrentUserAccess nvarchar(max)
  DECLARE @CurrentIsReadOnly bit
  DECLARE @CurrentDatabaseState nvarchar(max)
  DECLARE @CurrentInStandby bit
  DECLARE @CurrentRecoveryModel nvarchar(max)

  DECLARE @CurrentIsDatabaseAccessible bit
  DECLARE @CurrentReplicaID uniqueidentifier
  DECLARE @CurrentAvailabilityGroupID uniqueidentifier
  DECLARE @CurrentAvailabilityGroup nvarchar(max)
  DECLARE @CurrentAvailabilityGroupRole nvarchar(max)
  DECLARE @CurrentAvailabilityGroupBackupPreference nvarchar(max)
  DECLARE @CurrentSecondaryRoleAllowConnections nvarchar(max)
  DECLARE @CurrentIsPreferredBackupReplica bit
  DECLARE @CurrentDatabaseMirroringRole nvarchar(max)

  DECLARE @CurrentFGID int
  DECLARE @CurrentFileGroupID int
  DECLARE @CurrentFileGroupName nvarchar(max)
  DECLARE @CurrentFileGroupExists bit

  DECLARE @CurrentOID int
  DECLARE @CurrentSchemaID int
  DECLARE @CurrentSchemaName nvarchar(max)
  DECLARE @CurrentObjectID int
  DECLARE @CurrentObjectName nvarchar(max)
  DECLARE @CurrentObjectType nvarchar(max)
  DECLARE @CurrentObjectExists bit

  DECLARE @CurrentDatabaseContext nvarchar(max)
  DECLARE @CurrentCommand nvarchar(max)
  DECLARE @CurrentCommandOutput int
  DECLARE @CurrentCommandType nvarchar(max)

  DECLARE @Errors TABLE (ID int IDENTITY PRIMARY KEY,
                         [Message] nvarchar(max) NOT NULL,
                         Severity int NOT NULL,
                         [State] int)

  DECLARE @CurrentMessage nvarchar(max)
  DECLARE @CurrentSeverity int
  DECLARE @CurrentState int

  DECLARE @tmpDatabases TABLE (ID int IDENTITY,
                               DatabaseName nvarchar(max),
                               DatabaseType nvarchar(max),
                               AvailabilityGroup bit,
                               [Snapshot] bit,
                               StartPosition int,
                               LastCommandTime datetime2,
                               DatabaseSize bigint,
                               LastGoodCheckDbTime datetime2,
                               [Order] int,
                               Selected bit,
                               Completed bit,
                               PRIMARY KEY(Selected, Completed, [Order], ID))

  DECLARE @tmpAvailabilityGroups TABLE (ID int IDENTITY PRIMARY KEY,
                                        AvailabilityGroupName nvarchar(max),
                                        StartPosition int,
                                        Selected bit)

  DECLARE @tmpDatabasesAvailabilityGroups TABLE (DatabaseName nvarchar(max),
                                                 AvailabilityGroupName nvarchar(max))

  DECLARE @tmpFileGroups TABLE (ID int IDENTITY,
                                FileGroupID int,
                                FileGroupName nvarchar(max),
                                StartPosition int,
                                [Order] int,
                                Selected bit,
                                Completed bit,
                                PRIMARY KEY(Selected, Completed, [Order], ID))

  DECLARE @tmpObjects TABLE (ID int IDENTITY,
                             SchemaID int,
                             SchemaName nvarchar(max),
                             ObjectID int,
                             ObjectName nvarchar(max),
                             ObjectType nvarchar(max),
                             StartPosition int,
                             [Order] int,
                             Selected bit,
                             Completed bit,
                             PRIMARY KEY(Selected, Completed, [Order], ID))

  DECLARE @SelectedDatabases TABLE (DatabaseName nvarchar(max),
                                    DatabaseType nvarchar(max),
                                    AvailabilityGroup nvarchar(max),
                                    StartPosition int,
                                    Selected bit)

  DECLARE @SelectedAvailabilityGroups TABLE (AvailabilityGroupName nvarchar(max),
                                             StartPosition int,
                                             Selected bit)

  DECLARE @SelectedFileGroups TABLE (DatabaseName nvarchar(max),
                                     FileGroupName nvarchar(max),
                                     StartPosition int,
                                     Selected bit)

  DECLARE @SelectedObjects TABLE (DatabaseName nvarchar(max),
                                  SchemaName nvarchar(max),
                                  ObjectName nvarchar(max),
                                  StartPosition int,
                                  Selected bit)

  DECLARE @SelectedCheckCommands TABLE (CheckCommand nvarchar(max))

  DECLARE @Error int = 0
  DECLARE @ReturnCode int = 0

  DECLARE @EmptyLine nvarchar(max) = CHAR(9)

  DECLARE @Version numeric(18,10) = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

  IF @Version >= 14
  BEGIN
    SELECT @HostPlatform = host_platform
    FROM sys.dm_os_host_info
  END
  ELSE
  BEGIN
    SET @HostPlatform = 'Windows'
  END

  DECLARE @AmazonRDS bit = CASE WHEN DB_ID('rdsadmin') IS NOT NULL AND SUSER_SNAME(0x01) = 'rdsa' THEN 1 ELSE 0 END

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------

  SET @Parameters = '@Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
  SET @Parameters += ', @CheckCommands = ' + ISNULL('''' + REPLACE(@CheckCommands,'''','''''') + '''','NULL')
  SET @Parameters += ', @PhysicalOnly = ' + ISNULL('''' + REPLACE(@PhysicalOnly,'''','''''') + '''','NULL')
  SET @Parameters += ', @DataPurity = ' + ISNULL('''' + REPLACE(@DataPurity,'''','''''') + '''','NULL')
  SET @Parameters += ', @NoIndex = ' + ISNULL('''' + REPLACE(@NoIndex,'''','''''') + '''','NULL')
  SET @Parameters += ', @ExtendedLogicalChecks = ' + ISNULL('''' + REPLACE(@ExtendedLogicalChecks,'''','''''') + '''','NULL')
  SET @Parameters += ', @TabLock = ' + ISNULL('''' + REPLACE(@TabLock,'''','''''') + '''','NULL')
  SET @Parameters += ', @FileGroups = ' + ISNULL('''' + REPLACE(@FileGroups,'''','''''') + '''','NULL')
  SET @Parameters += ', @Objects = ' + ISNULL('''' + REPLACE(@Objects,'''','''''') + '''','NULL')
  SET @Parameters += ', @MaxDOP = ' + ISNULL(CAST(@MaxDOP AS nvarchar),'NULL')
  SET @Parameters += ', @AvailabilityGroups = ' + ISNULL('''' + REPLACE(@AvailabilityGroups,'''','''''') + '''','NULL')
  SET @Parameters += ', @AvailabilityGroupReplicas = ' + ISNULL('''' + REPLACE(@AvailabilityGroupReplicas,'''','''''') + '''','NULL')
  SET @Parameters += ', @Updateability = ' + ISNULL('''' + REPLACE(@Updateability,'''','''''') + '''','NULL')
  SET @Parameters += ', @TimeLimit = ' + ISNULL(CAST(@TimeLimit AS nvarchar),'NULL')
  SET @Parameters += ', @LockTimeout = ' + ISNULL(CAST(@LockTimeout AS nvarchar),'NULL')
  SET @Parameters += ', @LockMessageSeverity = ' + ISNULL(CAST(@LockMessageSeverity AS nvarchar),'NULL')
  SET @Parameters += ', @StringDelimiter = ' + ISNULL('''' + REPLACE(@StringDelimiter,'''','''''') + '''','NULL')
  SET @Parameters += ', @DatabaseOrder = ' + ISNULL('''' + REPLACE(@DatabaseOrder,'''','''''') + '''','NULL')
  SET @Parameters += ', @DatabasesInParallel = ' + ISNULL('''' + REPLACE(@DatabasesInParallel,'''','''''') + '''','NULL')
  SET @Parameters += ', @LogToTable = ' + ISNULL('''' + REPLACE(@LogToTable,'''','''''') + '''','NULL')
  SET @Parameters += ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL')

  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,@StartTime,120)
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Platform: ' + @HostPlatform
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName)
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Parameters: ' + @Parameters
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Version: ' + @VersionTimestamp
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Source: https://ola.hallengren.com'
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  RAISERROR(@EmptyLine,10,1) WITH NOWAIT

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF NOT (SELECT [compatibility_level] FROM sys.databases WHERE database_id = DB_ID()) >= 90
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT  'The database ' + QUOTENAME(DB_NAME(DB_ID())) + ' has to be in compatibility level 90 or higher.', 16, 1
  END

  IF NOT (SELECT uses_ansi_nulls FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'ANSI_NULLS has to be set to ON for the stored procedure.', 16, 1
  END

  IF NOT (SELECT uses_quoted_identifier FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'QUOTED_IDENTIFIER has to be set to ON for the stored procedure.', 16, 1
  END

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure CommandExecute is missing. Download https://ola.hallengren.com/scripts/CommandExecute.sql.', 16, 1
  END

  IF EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute' AND OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@DatabaseContext%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure CommandExecute needs to be updated. Download https://ola.hallengren.com/scripts/CommandExecute.sql.', 16, 1
  END

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table CommandLog is missing. Download https://ola.hallengren.com/scripts/CommandLog.sql.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'Queue')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table Queue is missing. Download https://ola.hallengren.com/scripts/Queue.sql.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'QueueDatabase')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table QueueDatabase is missing. Download https://ola.hallengren.com/scripts/QueueDatabase.sql.', 16, 1
  END

  IF @@TRANCOUNT <> 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The transaction count is not 0.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select databases                                                                           //--
  ----------------------------------------------------------------------------------------------------

  SET @Databases = REPLACE(@Databases, CHAR(10), '')
  SET @Databases = REPLACE(@Databases, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @Databases) > 0 SET @Databases = REPLACE(@Databases, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @Databases) > 0 SET @Databases = REPLACE(@Databases, ' ' + @StringDelimiter, @StringDelimiter)

  SET @Databases = LTRIM(RTRIM(@Databases));

  WITH Databases1 (StartPosition, EndPosition, DatabaseItem) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, 1), 0), LEN(@Databases) + 1) AS EndPosition,
         SUBSTRING(@Databases, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, 1), 0), LEN(@Databases) + 1) - 1) AS DatabaseItem
  WHERE @Databases IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) AS EndPosition,
         SUBSTRING(@Databases, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) - EndPosition - 1) AS DatabaseItem
  FROM Databases1
  WHERE EndPosition < LEN(@Databases) + 1
  ),
  Databases2 (DatabaseItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem LIKE '-%' THEN RIGHT(DatabaseItem,LEN(DatabaseItem) - 1) ELSE DatabaseItem END AS DatabaseItem,
         StartPosition,
         CASE WHEN DatabaseItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Databases1
  ),
  Databases3 (DatabaseItem, DatabaseType, AvailabilityGroup, StartPosition, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem IN('ALL_DATABASES','SYSTEM_DATABASES','USER_DATABASES','AVAILABILITY_GROUP_DATABASES') THEN '%' ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem = 'SYSTEM_DATABASES' THEN 'S' WHEN DatabaseItem = 'USER_DATABASES' THEN 'U' ELSE NULL END AS DatabaseType,
         CASE WHEN DatabaseItem = 'AVAILABILITY_GROUP_DATABASES' THEN 1 ELSE NULL END AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases2
  ),
  Databases4 (DatabaseName, DatabaseType, AvailabilityGroup, StartPosition, Selected) AS
  (
  SELECT CASE WHEN LEFT(DatabaseItem,1) = '[' AND RIGHT(DatabaseItem,1) = ']' THEN PARSENAME(DatabaseItem,1) ELSE DatabaseItem END AS DatabaseItem,
         DatabaseType,
         AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases3
  )
  INSERT INTO @SelectedDatabases (DatabaseName, DatabaseType, AvailabilityGroup, StartPosition, Selected)
  SELECT DatabaseName,
         DatabaseType,
         AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases4
  OPTION (MAXRECURSION 0)

  IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN
    INSERT INTO @tmpAvailabilityGroups (AvailabilityGroupName, Selected)
    SELECT name AS AvailabilityGroupName,
           0 AS Selected
    FROM sys.availability_groups

    INSERT INTO @tmpDatabasesAvailabilityGroups (DatabaseName, AvailabilityGroupName)
    SELECT databases.name,
           availability_groups.name
    FROM sys.databases databases
    INNER JOIN sys.availability_replicas availability_replicas ON databases.replica_id = availability_replicas.replica_id
    INNER JOIN sys.availability_groups availability_groups ON availability_replicas.group_id = availability_groups.group_id
  END

  INSERT INTO @tmpDatabases (DatabaseName, DatabaseType, AvailabilityGroup, [Snapshot], [Order], Selected, Completed)
  SELECT [name] AS DatabaseName,
         CASE WHEN name IN('master','msdb','model') OR is_distributor = 1 THEN 'S' ELSE 'U' END AS DatabaseType,
         NULL AS AvailabilityGroup,
         CASE WHEN source_database_id IS NOT NULL THEN 1 ELSE 0 END AS [Snapshot],
         0 AS [Order],
         0 AS Selected,
         0 AS Completed
  FROM sys.databases
  ORDER BY [name] ASC

  UPDATE tmpDatabases
  SET AvailabilityGroup = CASE WHEN EXISTS (SELECT * FROM @tmpDatabasesAvailabilityGroups WHERE DatabaseName = tmpDatabases.DatabaseName) THEN 1 ELSE 0 END
  FROM @tmpDatabases tmpDatabases

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
  AND NOT ((tmpDatabases.DatabaseName = 'tempdb' OR tmpDatabases.[Snapshot] = 1) AND tmpDatabases.DatabaseName <> SelectedDatabases.DatabaseName)
  WHERE SelectedDatabases.Selected = 1

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
  AND NOT ((tmpDatabases.DatabaseName = 'tempdb' OR tmpDatabases.[Snapshot] = 1) AND tmpDatabases.DatabaseName <> SelectedDatabases.DatabaseName)
  WHERE SelectedDatabases.Selected = 0

  UPDATE tmpDatabases
  SET tmpDatabases.StartPosition = SelectedDatabases2.StartPosition
  FROM @tmpDatabases tmpDatabases
  INNER JOIN (SELECT tmpDatabases.DatabaseName, MIN(SelectedDatabases.StartPosition) AS StartPosition
              FROM @tmpDatabases tmpDatabases
              INNER JOIN @SelectedDatabases SelectedDatabases
              ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
              AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
              AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
              WHERE SelectedDatabases.Selected = 1
              GROUP BY tmpDatabases.DatabaseName) SelectedDatabases2
  ON tmpDatabases.DatabaseName = SelectedDatabases2.DatabaseName

  IF @Databases IS NOT NULL AND (NOT EXISTS(SELECT * FROM @SelectedDatabases) OR EXISTS(SELECT * FROM @SelectedDatabases WHERE DatabaseName IS NULL OR DatabaseName = ''))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Databases is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select availability groups                                                                 //--
  ----------------------------------------------------------------------------------------------------

  IF @AvailabilityGroups IS NOT NULL AND @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN

    SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, CHAR(10), '')
    SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, CHAR(13), '')

    WHILE CHARINDEX(@StringDelimiter + ' ', @AvailabilityGroups) > 0 SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, @StringDelimiter + ' ', @StringDelimiter)
    WHILE CHARINDEX(' ' + @StringDelimiter, @AvailabilityGroups) > 0 SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, ' ' + @StringDelimiter, @StringDelimiter)

    SET @AvailabilityGroups = LTRIM(RTRIM(@AvailabilityGroups));

    WITH AvailabilityGroups1 (StartPosition, EndPosition, AvailabilityGroupItem) AS
    (
    SELECT 1 AS StartPosition,
           ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, 1), 0), LEN(@AvailabilityGroups) + 1) AS EndPosition,
           SUBSTRING(@AvailabilityGroups, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, 1), 0), LEN(@AvailabilityGroups) + 1) - 1) AS AvailabilityGroupItem
    WHERE @AvailabilityGroups IS NOT NULL
    UNION ALL
    SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
           ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, EndPosition + 1), 0), LEN(@AvailabilityGroups) + 1) AS EndPosition,
           SUBSTRING(@AvailabilityGroups, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, EndPosition + 1), 0), LEN(@AvailabilityGroups) + 1) - EndPosition - 1) AS AvailabilityGroupItem
    FROM AvailabilityGroups1
    WHERE EndPosition < LEN(@AvailabilityGroups) + 1
    ),
    AvailabilityGroups2 (AvailabilityGroupItem, StartPosition, Selected) AS
    (
    SELECT CASE WHEN AvailabilityGroupItem LIKE '-%' THEN RIGHT(AvailabilityGroupItem,LEN(AvailabilityGroupItem) - 1) ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           CASE WHEN AvailabilityGroupItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
    FROM AvailabilityGroups1
    ),
    AvailabilityGroups3 (AvailabilityGroupItem, StartPosition, Selected) AS
    (
    SELECT CASE WHEN AvailabilityGroupItem = 'ALL_AVAILABILITY_GROUPS' THEN '%' ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           Selected
    FROM AvailabilityGroups2
    ),
    AvailabilityGroups4 (AvailabilityGroupName, StartPosition, Selected) AS
    (
    SELECT CASE WHEN LEFT(AvailabilityGroupItem,1) = '[' AND RIGHT(AvailabilityGroupItem,1) = ']' THEN PARSENAME(AvailabilityGroupItem,1) ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           Selected
    FROM AvailabilityGroups3
    )
    INSERT INTO @SelectedAvailabilityGroups (AvailabilityGroupName, StartPosition, Selected)
    SELECT AvailabilityGroupName, StartPosition, Selected
    FROM AvailabilityGroups4
    OPTION (MAXRECURSION 0)

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.Selected = SelectedAvailabilityGroups.Selected
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
    ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
    WHERE SelectedAvailabilityGroups.Selected = 1

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.Selected = SelectedAvailabilityGroups.Selected
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
    ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
    WHERE SelectedAvailabilityGroups.Selected = 0

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.StartPosition = SelectedAvailabilityGroups2.StartPosition
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN (SELECT tmpAvailabilityGroups.AvailabilityGroupName, MIN(SelectedAvailabilityGroups.StartPosition) AS StartPosition
                FROM @tmpAvailabilityGroups tmpAvailabilityGroups
                INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
                ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
                WHERE SelectedAvailabilityGroups.Selected = 1
                GROUP BY tmpAvailabilityGroups.AvailabilityGroupName) SelectedAvailabilityGroups2
    ON tmpAvailabilityGroups.AvailabilityGroupName = SelectedAvailabilityGroups2.AvailabilityGroupName

    UPDATE tmpDatabases
    SET tmpDatabases.StartPosition = tmpAvailabilityGroups.StartPosition,
        tmpDatabases.Selected = 1
    FROM @tmpDatabases tmpDatabases
    INNER JOIN @tmpDatabasesAvailabilityGroups tmpDatabasesAvailabilityGroups ON tmpDatabases.DatabaseName = tmpDatabasesAvailabilityGroups.DatabaseName
    INNER JOIN @tmpAvailabilityGroups tmpAvailabilityGroups ON tmpDatabasesAvailabilityGroups.AvailabilityGroupName = tmpAvailabilityGroups.AvailabilityGroupName
    WHERE tmpAvailabilityGroups.Selected = 1

  END

  IF @AvailabilityGroups IS NOT NULL AND (NOT EXISTS(SELECT * FROM @SelectedAvailabilityGroups) OR EXISTS(SELECT * FROM @SelectedAvailabilityGroups WHERE AvailabilityGroupName IS NULL OR AvailabilityGroupName = '') OR @Version < 11 OR SERVERPROPERTY('IsHadrEnabled') = 0)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroups is not supported.', 16, 1
  END

  IF (@Databases IS NULL AND @AvailabilityGroups IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You need to specify one of the parameters @Databases and @AvailabilityGroups.', 16, 2
  END

  IF (@Databases IS NOT NULL AND @AvailabilityGroups IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You can only specify one of the parameters @Databases and @AvailabilityGroups.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------
  --// Select filegroups                                                                          //--
  ----------------------------------------------------------------------------------------------------

  SET @FileGroups = REPLACE(@FileGroups, CHAR(10), '')
  SET @FileGroups = REPLACE(@FileGroups, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @FileGroups) > 0 SET @FileGroups = REPLACE(@FileGroups, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @FileGroups) > 0 SET @FileGroups = REPLACE(@FileGroups, ' ' + @StringDelimiter, @StringDelimiter)

  SET @FileGroups = LTRIM(RTRIM(@FileGroups));

  WITH FileGroups1 (StartPosition, EndPosition, FileGroupItem) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FileGroups, 1), 0), LEN(@FileGroups) + 1) AS EndPosition,
         SUBSTRING(@FileGroups, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FileGroups, 1), 0), LEN(@FileGroups) + 1) - 1) AS FileGroupItem
  WHERE @FileGroups IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FileGroups, EndPosition + 1), 0), LEN(@FileGroups) + 1) AS EndPosition,
         SUBSTRING(@FileGroups, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FileGroups, EndPosition + 1), 0), LEN(@FileGroups) + 1) - EndPosition - 1) AS FileGroupItem
  FROM FileGroups1
  WHERE EndPosition < LEN(@FileGroups) + 1
  ),
  FileGroups2 (FileGroupItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN FileGroupItem LIKE '-%' THEN RIGHT(FileGroupItem,LEN(FileGroupItem) - 1) ELSE FileGroupItem END AS FileGroupItem,
         StartPosition,
         CASE WHEN FileGroupItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM FileGroups1
  ),
  FileGroups3 (FileGroupItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN FileGroupItem = 'ALL_FILEGROUPS' THEN '%.%' ELSE FileGroupItem END AS FileGroupItem,
         StartPosition,
         Selected
  FROM FileGroups2
  ),
  FileGroups4 (DatabaseName, FileGroupName, StartPosition, Selected) AS
  (
  SELECT CASE WHEN PARSENAME(FileGroupItem,4) IS NULL AND PARSENAME(FileGroupItem,3) IS NULL THEN PARSENAME(FileGroupItem,2) ELSE NULL END AS DatabaseName,
         CASE WHEN PARSENAME(FileGroupItem,4) IS NULL AND PARSENAME(FileGroupItem,3) IS NULL THEN PARSENAME(FileGroupItem,1) ELSE NULL END AS FileGroupName,
         StartPosition,
         Selected
  FROM FileGroups3
  )
  INSERT INTO @SelectedFileGroups (DatabaseName, FileGroupName, StartPosition, Selected)
  SELECT DatabaseName, FileGroupName, StartPosition, Selected
  FROM FileGroups4
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Select objects                                                                             //--
  ----------------------------------------------------------------------------------------------------

  SET @Objects = REPLACE(@Objects, CHAR(10), '')
  SET @Objects = REPLACE(@Objects, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @Objects) > 0 SET @Objects = REPLACE(@Objects, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @Objects) > 0 SET @Objects = REPLACE(@Objects, ' ' + @StringDelimiter, @StringDelimiter)

  SET @Objects = LTRIM(RTRIM(@Objects));

  WITH Objects1 (StartPosition, EndPosition, ObjectItem) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Objects, 1), 0), LEN(@Objects) + 1) AS EndPosition,
         SUBSTRING(@Objects, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Objects, 1), 0), LEN(@Objects) + 1) - 1) AS ObjectItem
  WHERE @Objects IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Objects, EndPosition + 1), 0), LEN(@Objects) + 1) AS EndPosition,
         SUBSTRING(@Objects, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Objects, EndPosition + 1), 0), LEN(@Objects) + 1) - EndPosition - 1) AS ObjectItem
  FROM Objects1
  WHERE EndPosition < LEN(@Objects) + 1
  ),
  Objects2 (ObjectItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN ObjectItem LIKE '-%' THEN RIGHT(ObjectItem,LEN(ObjectItem) - 1) ELSE ObjectItem END AS ObjectItem,
          StartPosition,
         CASE WHEN ObjectItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Objects1
  ),
  Objects3 (ObjectItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN ObjectItem = 'ALL_OBJECTS' THEN '%.%.%' ELSE ObjectItem END AS ObjectItem,
         StartPosition,
         Selected
  FROM Objects2
  ),
  Objects4 (DatabaseName, SchemaName, ObjectName, StartPosition, Selected) AS
  (
  SELECT CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,3) ELSE NULL END AS DatabaseName,
         CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,2) ELSE NULL END AS SchemaName,
         CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,1) ELSE NULL END AS ObjectName,
         StartPosition,
         Selected
  FROM Objects3
  )
  INSERT INTO @SelectedObjects (DatabaseName, SchemaName, ObjectName, StartPosition, Selected)
  SELECT DatabaseName, SchemaName, ObjectName, StartPosition, Selected
  FROM Objects4
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Select check commands                                                                      //--
  ----------------------------------------------------------------------------------------------------

  SET @CheckCommands = REPLACE(@CheckCommands, @StringDelimiter + ' ', @StringDelimiter);

  WITH CheckCommands (StartPosition, EndPosition, CheckCommand) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @CheckCommands, 1), 0), LEN(@CheckCommands) + 1) AS EndPosition,
         SUBSTRING(@CheckCommands, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @CheckCommands, 1), 0), LEN(@CheckCommands) + 1) - 1) AS CheckCommand
  WHERE @CheckCommands IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @CheckCommands, EndPosition + 1), 0), LEN(@CheckCommands) + 1) AS EndPosition,
         SUBSTRING(@CheckCommands, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @CheckCommands, EndPosition + 1), 0), LEN(@CheckCommands) + 1) - EndPosition - 1) AS CheckCommand
  FROM CheckCommands
  WHERE EndPosition < LEN(@CheckCommands) + 1
  )
  INSERT INTO @SelectedCheckCommands (CheckCommand)
  SELECT CheckCommand
  FROM CheckCommands
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand NOT IN('CHECKDB','CHECKFILEGROUP','CHECKALLOC','CHECKTABLE','CHECKCATALOG'))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CheckCommands is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @SelectedCheckCommands GROUP BY CheckCommand HAVING COUNT(*) > 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CheckCommands is not supported.', 16, 2
  END

  IF NOT EXISTS (SELECT * FROM @SelectedCheckCommands)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CheckCommands is not supported.' , 16, 3
  END

  IF EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKDB')) AND EXISTS (SELECT CheckCommand FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKFILEGROUP','CHECKALLOC','CHECKTABLE','CHECKCATALOG'))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CheckCommands is not supported.', 16, 4
  END

  IF EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKFILEGROUP')) AND EXISTS (SELECT CheckCommand FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKALLOC','CHECKTABLE'))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @CheckCommands is not supported.', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF @PhysicalOnly NOT IN ('Y','N') OR @PhysicalOnly IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @PhysicalOnly is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @DataPurity NOT IN ('Y','N') OR @DataPurity IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DataPurity is not supported.', 16, 1
  END

  IF @PhysicalOnly = 'Y' AND @DataPurity = 'Y'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameters @PhysicalOnly and @DataPurity cannot be used together.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @NoIndex NOT IN ('Y','N') OR @NoIndex IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @NoIndex is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @ExtendedLogicalChecks NOT IN ('Y','N') OR @ExtendedLogicalChecks IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ExtendedLogicalChecks is not supported.', 16, 1
  END

  IF @PhysicalOnly = 'Y' AND @ExtendedLogicalChecks = 'Y'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameters @PhysicalOnly and @ExtendedLogicalChecks cannot be used together.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @TabLock NOT IN ('Y','N') OR @TabLock IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @TabLock is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @SelectedFileGroups WHERE DatabaseName IS NULL OR FileGroupName IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileGroups is not supported.', 16, 1
  END

  IF @FileGroups IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedFileGroups)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileGroups is not supported.', 16, 2
  END

  IF @FileGroups IS NOT NULL AND NOT EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKFILEGROUP')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FileGroups is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @SelectedObjects WHERE DatabaseName IS NULL OR SchemaName IS NULL OR ObjectName IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Objects is not supported.', 16, 1
  END

  IF (@Objects IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedObjects))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Objects is not supported.', 16, 2
  END

  IF (@Objects IS NOT NULL AND NOT EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKTABLE'))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Objects is not supported.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @MaxDOP < 0 OR @MaxDOP > 64
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxDOP is not supported.', 16, 1
  END

  IF @MaxDOP IS NOT NULL AND NOT (@Version >= 12.050000 OR SERVERPROPERTY('EngineEdition') IN (5, 8))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxDOP is not supported. MAXDOP is not available in this version of SQL Server.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @AvailabilityGroupReplicas NOT IN('ALL','PRIMARY','SECONDARY','PREFERRED_BACKUP_REPLICA') OR @AvailabilityGroupReplicas IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroupReplicas is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Updateability NOT IN('READ_ONLY','READ_WRITE','ALL') OR @Updateability IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Updateability is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @TimeLimit < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @TimeLimit is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @LockTimeout < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LockTimeout is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @LockMessageSeverity NOT IN(10, 16)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LockMessageSeverity is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @StringDelimiter IS NULL OR LEN(@StringDelimiter) > 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StringDelimiter is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @DatabaseOrder NOT IN('DATABASE_NAME_ASC','DATABASE_NAME_DESC','DATABASE_SIZE_ASC','DATABASE_SIZE_DESC','DATABASE_LAST_GOOD_CHECK_ASC','DATABASE_LAST_GOOD_CHECK_DESC','REPLICA_LAST_GOOD_CHECK_ASC','REPLICA_LAST_GOOD_CHECK_DESC')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported.', 16, 1
  END

  IF @DatabaseOrder IN('DATABASE_LAST_GOOD_CHECK_ASC','DATABASE_LAST_GOOD_CHECK_DESC') AND NOT ((@Version >= 12.06024 AND @Version < 13) OR (@Version >= 13.05026 AND @Version < 14) OR @Version >= 14.0302916)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported. DATABASEPROPERTYEX(''DatabaseName'', ''LastGoodCheckDbTime'') is not available in this version of SQL Server.', 16, 2
  END

  IF @DatabaseOrder IN('REPLICA_LAST_GOOD_CHECK_ASC','REPLICA_LAST_GOOD_CHECK_DESC') AND @LogToTable = 'N'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported. You need to provide the parameter @LogToTable = ''Y''.', 16, 3
  END

  IF @DatabaseOrder IN('DATABASE_LAST_GOOD_CHECK_ASC','DATABASE_LAST_GOOD_CHECK_DESC','REPLICA_LAST_GOOD_CHECK_ASC','REPLICA_LAST_GOOD_CHECK_DESC') AND @CheckCommands <> 'CHECKDB'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported. You need to provide the parameter @CheckCommands = ''CHECKDB''.', 16, 4
  END

  IF @DatabaseOrder IS NOT NULL AND SERVERPROPERTY('EngineEdition') = 5
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported. This parameter is not supported in Azure SQL Database.', 16, 5
  END

  ----------------------------------------------------------------------------------------------------

  IF @DatabasesInParallel NOT IN('Y','N') OR @DatabasesInParallel IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabasesInParallel is not supported.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND SERVERPROPERTY('EngineEdition') = 5
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabasesInParallel is not supported. This parameter is not supported in Azure SQL Database.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LogToTable is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Execute is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @Errors)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The documentation is available at https://ola.hallengren.com/sql-server-integrity-check.html.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Check that selected databases and availability groups exist                                //--
  ----------------------------------------------------------------------------------------------------

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedDatabases
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases in the @Databases parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedFileGroups
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases in the @FileGroups parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedObjects
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases in the @Objects parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(AvailabilityGroupName) + ', '
  FROM @SelectedAvailabilityGroups
  WHERE AvailabilityGroupName NOT LIKE '%[%]%'
  AND AvailabilityGroupName NOT IN (SELECT AvailabilityGroupName FROM @tmpAvailabilityGroups)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following availability groups do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedFileGroups
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName IN (SELECT DatabaseName FROM @tmpDatabases)
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases WHERE Selected = 1)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases have been selected in the @FileGroups parameter, but not in the @Databases or @AvailabilityGroups parameters: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedObjects
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName IN (SELECT DatabaseName FROM @tmpDatabases)
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases WHERE Selected = 1)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases have been selected in the @Objects parameter, but not in the @Databases or @AvailabilityGroups parameters: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Check @@SERVERNAME                                                                         //--
  ----------------------------------------------------------------------------------------------------

  IF @@SERVERNAME <> CAST(SERVERPROPERTY('ServerName') AS nvarchar(max)) AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The @@SERVERNAME does not match SERVERPROPERTY(''ServerName''). See ' + CASE WHEN SERVERPROPERTY('IsClustered') = 0 THEN 'https://docs.microsoft.com/en-us/sql/database-engine/install-windows/rename-a-computer-that-hosts-a-stand-alone-instance-of-sql-server' WHEN SERVERPROPERTY('IsClustered') = 1 THEN 'https://docs.microsoft.com/en-us/sql/sql-server/failover-clusters/install/rename-a-sql-server-failover-cluster-instance' END + '.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Raise errors                                                                               //--
  ----------------------------------------------------------------------------------------------------

  DECLARE ErrorCursor CURSOR FAST_FORWARD FOR SELECT [Message], Severity, [State] FROM @Errors ORDER BY [ID] ASC

  OPEN ErrorCursor

  FETCH ErrorCursor INTO @CurrentMessage, @CurrentSeverity, @CurrentState

  WHILE @@FETCH_STATUS = 0
  BEGIN
    RAISERROR('%s', @CurrentSeverity, @CurrentState, @CurrentMessage) WITH NOWAIT
    RAISERROR(@EmptyLine, 10, 1) WITH NOWAIT

    FETCH NEXT FROM ErrorCursor INTO @CurrentMessage, @CurrentSeverity, @CurrentState
  END

  CLOSE ErrorCursor

  DEALLOCATE ErrorCursor

  IF EXISTS (SELECT * FROM @Errors WHERE Severity >= 16)
  BEGIN
    SET @ReturnCode = 50000
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Update database order                                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @DatabaseOrder IN('DATABASE_SIZE_ASC','DATABASE_SIZE_DESC')
  BEGIN
    UPDATE tmpDatabases
    SET DatabaseSize = (SELECT SUM(CAST(size AS bigint)) FROM sys.master_files WHERE [type] = 0 AND database_id = DB_ID(tmpDatabases.DatabaseName))
    FROM @tmpDatabases tmpDatabases
  END

  IF @DatabaseOrder IN('DATABASE_LAST_GOOD_CHECK_ASC','DATABASE_LAST_GOOD_CHECK_DESC')
  BEGIN
    UPDATE tmpDatabases
    SET LastGoodCheckDbTime = NULLIF(CAST(DATABASEPROPERTYEX (DatabaseName,'LastGoodCheckDbTime') AS datetime2),'1900-01-01 00:00:00.000')
    FROM @tmpDatabases tmpDatabases
  END

  IF @DatabaseOrder IN('REPLICA_LAST_GOOD_CHECK_ASC','REPLICA_LAST_GOOD_CHECK_DESC')
  BEGIN
    UPDATE tmpDatabases
    SET LastCommandTime = MaxStartTime
    FROM @tmpDatabases tmpDatabases
    INNER JOIN (SELECT DatabaseName, MAX(StartTime) AS MaxStartTime
                FROM dbo.CommandLog
                WHERE CommandType = 'DBCC_CHECKDB'
                AND ErrorNumber = 0
                GROUP BY DatabaseName) CommandLog
    ON tmpDatabases.DatabaseName = CommandLog.DatabaseName COLLATE DATABASE_DEFAULT
  END

  IF @DatabaseOrder IS NULL
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY StartPosition ASC, DatabaseName ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_NAME_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseName ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_NAME_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseName DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_SIZE_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseSize ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_SIZE_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseSize DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_LAST_GOOD_CHECK_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY LastGoodCheckDbTime ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_LAST_GOOD_CHECK_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY LastGoodCheckDbTime DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'REPLICA_LAST_GOOD_CHECK_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY LastCommandTime ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'REPLICA_LAST_GOOD_CHECK_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY LastCommandTime DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END

  ----------------------------------------------------------------------------------------------------
  --// Update the queue                                                                           //--
  ----------------------------------------------------------------------------------------------------

  IF @DatabasesInParallel = 'Y'
  BEGIN

    BEGIN TRY

      SELECT @QueueID = QueueID
      FROM dbo.[Queue]
      WHERE SchemaName = @SchemaName
      AND ObjectName = @ObjectName
      AND [Parameters] = @Parameters

      IF @QueueID IS NULL
      BEGIN
        BEGIN TRANSACTION

        SELECT @QueueID = QueueID
        FROM dbo.[Queue] WITH (UPDLOCK, HOLDLOCK)
        WHERE SchemaName = @SchemaName
        AND ObjectName = @ObjectName
        AND [Parameters] = @Parameters

        IF @QueueID IS NULL
        BEGIN
          INSERT INTO dbo.[Queue] (SchemaName, ObjectName, [Parameters])
          SELECT @SchemaName, @ObjectName, @Parameters

          SET @QueueID = SCOPE_IDENTITY()
        END

        COMMIT TRANSACTION
      END

      BEGIN TRANSACTION

      UPDATE [Queue]
      SET QueueStartTime = SYSDATETIME(),
          SessionID = @@SPID,
          RequestID = (SELECT request_id FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          RequestStartTime = (SELECT start_time FROM sys.dm_exec_requests WHERE session_id = @@SPID)
      FROM dbo.[Queue] [Queue]
      WHERE QueueID = @QueueID
      AND NOT EXISTS (SELECT *
                      FROM sys.dm_exec_requests
                      WHERE session_id = [Queue].SessionID
                      AND request_id = [Queue].RequestID
                      AND start_time = [Queue].RequestStartTime)
      AND NOT EXISTS (SELECT *
                      FROM dbo.QueueDatabase QueueDatabase
                      INNER JOIN sys.dm_exec_requests ON QueueDatabase.SessionID = session_id AND QueueDatabase.RequestID = request_id AND QueueDatabase.RequestStartTime = start_time
                      WHERE QueueDatabase.QueueID = @QueueID)

      IF @@ROWCOUNT = 1
      BEGIN
        INSERT INTO dbo.QueueDatabase (QueueID, DatabaseName)
        SELECT @QueueID AS QueueID,
               DatabaseName
        FROM @tmpDatabases tmpDatabases
        WHERE Selected = 1
        AND NOT EXISTS (SELECT * FROM dbo.QueueDatabase WHERE DatabaseName = tmpDatabases.DatabaseName AND QueueID = @QueueID)

        DELETE QueueDatabase
        FROM dbo.QueueDatabase QueueDatabase
        WHERE QueueID = @QueueID
        AND NOT EXISTS (SELECT * FROM @tmpDatabases tmpDatabases WHERE DatabaseName = QueueDatabase.DatabaseName AND Selected = 1)

        UPDATE QueueDatabase
        SET DatabaseOrder = tmpDatabases.[Order]
        FROM dbo.QueueDatabase QueueDatabase
        INNER JOIN @tmpDatabases tmpDatabases ON QueueDatabase.DatabaseName = tmpDatabases.DatabaseName
        WHERE QueueID = @QueueID
      END

      COMMIT TRANSACTION

      SELECT @QueueStartTime = QueueStartTime
      FROM dbo.[Queue]
      WHERE QueueID = @QueueID

    END TRY

    BEGIN CATCH
      IF XACT_STATE() <> 0
      BEGIN
        ROLLBACK TRANSACTION
      END
      SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'')
      RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
      SET @ReturnCode = ERROR_NUMBER()
      GOTO Logging
    END CATCH

  END

  ----------------------------------------------------------------------------------------------------
  --// Execute commands                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WHILE (1 = 1)
  BEGIN

    IF @DatabasesInParallel = 'Y'
    BEGIN
      UPDATE QueueDatabase
      SET DatabaseStartTime = NULL,
          SessionID = NULL,
          RequestID = NULL,
          RequestStartTime = NULL
      FROM dbo.QueueDatabase QueueDatabase
      WHERE QueueID = @QueueID
      AND DatabaseStartTime IS NOT NULL
      AND DatabaseEndTime IS NULL
      AND NOT EXISTS (SELECT * FROM sys.dm_exec_requests WHERE session_id = QueueDatabase.SessionID AND request_id = QueueDatabase.RequestID AND start_time = QueueDatabase.RequestStartTime)

      UPDATE QueueDatabase
      SET DatabaseStartTime = SYSDATETIME(),
          DatabaseEndTime = NULL,
          SessionID = @@SPID,
          RequestID = (SELECT request_id FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          RequestStartTime = (SELECT start_time FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          @CurrentDatabaseName = DatabaseName
      FROM (SELECT TOP 1 DatabaseStartTime,
                         DatabaseEndTime,
                         SessionID,
                         RequestID,
                         RequestStartTime,
                         DatabaseName
            FROM dbo.QueueDatabase
            WHERE QueueID = @QueueID
            AND (DatabaseStartTime < @QueueStartTime OR DatabaseStartTime IS NULL)
            AND NOT (DatabaseStartTime IS NOT NULL AND DatabaseEndTime IS NULL)
            ORDER BY DatabaseOrder ASC
            ) QueueDatabase
    END
    ELSE
    BEGIN
      SELECT TOP 1 @CurrentDBID = ID,
                   @CurrentDatabaseName = DatabaseName
      FROM @tmpDatabases
      WHERE Selected = 1
      AND Completed = 0
      ORDER BY [Order] ASC
    END

    IF @@ROWCOUNT = 0
    BEGIN
     BREAK
    END

    SET @CurrentDatabase_sp_executesql = QUOTENAME(@CurrentDatabaseName) + '.sys.sp_executesql'

    BEGIN
      SET @DatabaseMessage = 'Date and time: ' + CONVERT(nvarchar,SYSDATETIME(),120)
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Database: ' + QUOTENAME(@CurrentDatabaseName)
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    SELECT @CurrentUserAccess = user_access_desc,
           @CurrentIsReadOnly = is_read_only,
           @CurrentDatabaseState = state_desc,
           @CurrentInStandby = is_in_standby,
           @CurrentRecoveryModel = recovery_model_desc
    FROM sys.databases
    WHERE [name] = @CurrentDatabaseName

    BEGIN
      SET @DatabaseMessage = 'State: ' + @CurrentDatabaseState
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Standby: ' + CASE WHEN @CurrentInStandby = 1 THEN 'Yes' ELSE 'No' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Updateability: ' + CASE WHEN @CurrentIsReadOnly = 1 THEN 'READ_ONLY' WHEN  @CurrentIsReadOnly = 0 THEN 'READ_WRITE' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'User access: ' + @CurrentUserAccess
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Recovery model: ' + @CurrentRecoveryModel
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentDatabaseState = 'ONLINE' AND SERVERPROPERTY('EngineEdition') <> 5
    BEGIN
      IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = DB_ID(@CurrentDatabaseName) AND database_guid IS NOT NULL)
      BEGIN
        SET @CurrentIsDatabaseAccessible = 1
      END
      ELSE
      BEGIN
        SET @CurrentIsDatabaseAccessible = 0
      END
    END

    IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
    BEGIN
      SELECT @CurrentReplicaID = databases.replica_id
      FROM sys.databases databases
      INNER JOIN sys.availability_replicas availability_replicas ON databases.replica_id = availability_replicas.replica_id
      WHERE databases.[name] = @CurrentDatabaseName

      SELECT @CurrentAvailabilityGroupID = group_id,
             @CurrentSecondaryRoleAllowConnections = secondary_role_allow_connections_desc
      FROM sys.availability_replicas
      WHERE replica_id = @CurrentReplicaID

      SELECT @CurrentAvailabilityGroupRole = role_desc
      FROM sys.dm_hadr_availability_replica_states
      WHERE replica_id = @CurrentReplicaID

      SELECT @CurrentAvailabilityGroup = [name],
             @CurrentAvailabilityGroupBackupPreference = UPPER(automated_backup_preference_desc)
      FROM sys.availability_groups
      WHERE group_id = @CurrentAvailabilityGroupID
    END

    IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1 AND @CurrentAvailabilityGroup IS NOT NULL AND @AvailabilityGroupReplicas = 'PREFERRED_BACKUP_REPLICA'
    BEGIN
      SELECT @CurrentIsPreferredBackupReplica = sys.fn_hadr_backup_is_preferred_replica(@CurrentDatabaseName)
    END

    IF SERVERPROPERTY('EngineEdition') <> 5
    BEGIN
      SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
      FROM sys.database_mirroring
      WHERE database_id = DB_ID(@CurrentDatabaseName)
    END

    IF @CurrentIsDatabaseAccessible IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentAvailabilityGroup IS NOT NULL
    BEGIN
      SET @DatabaseMessage =  'Availability group: ' + ISNULL(@CurrentAvailabilityGroup,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Availability group role: ' + ISNULL(@CurrentAvailabilityGroupRole,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      IF @CurrentAvailabilityGroupRole = 'SECONDARY'
      BEGIN
        SET @DatabaseMessage =  'Readable Secondary: ' + ISNULL(@CurrentSecondaryRoleAllowConnections,'N/A')
        RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
      END

      IF @AvailabilityGroupReplicas = 'PREFERRED_BACKUP_REPLICA'
      BEGIN
        SET @DatabaseMessage = 'Availability group backup preference: ' + ISNULL(@CurrentAvailabilityGroupBackupPreference,'N/A')
        RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

        SET @DatabaseMessage = 'Is preferred backup replica: ' + CASE WHEN @CurrentIsPreferredBackupReplica = 1 THEN 'Yes' WHEN @CurrentIsPreferredBackupReplica = 0 THEN 'No' ELSE 'N/A' END
        RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
      END
    END

    IF @CurrentDatabaseMirroringRole IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Database mirroring role: ' + @CurrentDatabaseMirroringRole
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    RAISERROR(@EmptyLine,10,1) WITH NOWAIT

    IF @CurrentDatabaseState = 'ONLINE'
    AND NOT (@CurrentUserAccess = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)
    AND (@CurrentAvailabilityGroupRole = 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL OR SERVERPROPERTY('EngineEdition') = 3)
    AND ((@AvailabilityGroupReplicas = 'PRIMARY' AND @CurrentAvailabilityGroupRole = 'PRIMARY') OR (@AvailabilityGroupReplicas = 'SECONDARY' AND @CurrentAvailabilityGroupRole = 'SECONDARY') OR (@AvailabilityGroupReplicas = 'PREFERRED_BACKUP_REPLICA' AND @CurrentIsPreferredBackupReplica = 1) OR @AvailabilityGroupReplicas = 'ALL' OR @CurrentAvailabilityGroupRole IS NULL)
    AND NOT (@CurrentIsReadOnly = 1 AND @Updateability = 'READ_WRITE')
    AND NOT (@CurrentIsReadOnly = 0 AND @Updateability = 'READ_ONLY')
    BEGIN

      -- Check database
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKDB') AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SET @CurrentDatabaseContext = CASE WHEN SERVERPROPERTY('EngineEdition') = 5 THEN @CurrentDatabaseName ELSE 'master' END

        SET @CurrentCommandType = 'DBCC_CHECKDB'

        SET @CurrentCommand = ''
        IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
        SET @CurrentCommand += 'DBCC CHECKDB (' + QUOTENAME(@CurrentDatabaseName)
        IF @NoIndex = 'Y' SET @CurrentCommand += ', NOINDEX'
        SET @CurrentCommand += ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
        IF @DataPurity = 'Y' SET @CurrentCommand += ', DATA_PURITY'
        IF @PhysicalOnly = 'Y' SET @CurrentCommand += ', PHYSICAL_ONLY'
        IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand += ', EXTENDED_LOGICAL_CHECKS'
        IF @TabLock = 'Y' SET @CurrentCommand += ', TABLOCK'
        IF @MaxDOP IS NOT NULL SET @CurrentCommand += ', MAXDOP = ' + CAST(@MaxDOP AS nvarchar)

        EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput = @Error
        IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
      END

      -- Check filegroups
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKFILEGROUP')
      AND (@CurrentAvailabilityGroupRole = 'PRIMARY' OR (@CurrentAvailabilityGroupRole = 'SECONDARY' AND @CurrentSecondaryRoleAllowConnections = 'ALL') OR @CurrentAvailabilityGroupRole IS NULL)
      AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SET @CurrentCommand = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT data_space_id AS FileGroupID, name AS FileGroupName, 0 AS [Order], 0 AS Selected, 0 AS Completed FROM sys.filegroups filegroups WHERE [type] <> ''FX'' ORDER BY CASE WHEN filegroups.name = ''PRIMARY'' THEN 1 ELSE 0 END DESC, filegroups.name ASC'

        INSERT INTO @tmpFileGroups (FileGroupID, FileGroupName, [Order], Selected, Completed)
        EXECUTE @CurrentDatabase_sp_executesql  @stmt = @CurrentCommand
        SET @Error = @@ERROR
        IF @Error <> 0 SET @ReturnCode = @Error

        IF @FileGroups IS NULL
        BEGIN
          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = 1
          FROM @tmpFileGroups tmpFileGroups
        END
        ELSE
        BEGIN
          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = SelectedFileGroups.Selected
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN @SelectedFileGroups SelectedFileGroups
          ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
          WHERE SelectedFileGroups.Selected = 1

          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = SelectedFileGroups.Selected
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN @SelectedFileGroups SelectedFileGroups
          ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
          WHERE SelectedFileGroups.Selected = 0

          UPDATE tmpFileGroups
          SET tmpFileGroups.StartPosition = SelectedFileGroups2.StartPosition
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN (SELECT tmpFileGroups.FileGroupName, MIN(SelectedFileGroups.StartPosition) AS StartPosition
                      FROM @tmpFileGroups tmpFileGroups
                      INNER JOIN @SelectedFileGroups SelectedFileGroups
                      ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
                      WHERE SelectedFileGroups.Selected = 1
                      GROUP BY tmpFileGroups.FileGroupName) SelectedFileGroups2
          ON tmpFileGroups.FileGroupName = SelectedFileGroups2.FileGroupName
        END;

        WITH tmpFileGroups AS (
        SELECT FileGroupName, [Order], ROW_NUMBER() OVER (ORDER BY StartPosition ASC, FileGroupName ASC) AS RowNumber
        FROM @tmpFileGroups tmpFileGroups
        WHERE Selected = 1
        )
        UPDATE tmpFileGroups
        SET [Order] = RowNumber

        SET @ErrorMessage = ''
        SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + '.' + QUOTENAME(FileGroupName) + ', '
        FROM @SelectedFileGroups SelectedFileGroups
        WHERE DatabaseName = @CurrentDatabaseName
        AND FileGroupName NOT LIKE '%[%]%'
        AND NOT EXISTS (SELECT * FROM @tmpFileGroups WHERE FileGroupName = SelectedFileGroups.FileGroupName)
        IF @@ROWCOUNT > 0
        BEGIN
          SET @ErrorMessage = 'The following file groups do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.'
          RAISERROR('%s',10,1,@ErrorMessage) WITH NOWAIT
          SET @Error = @@ERROR
          RAISERROR(@EmptyLine,10,1) WITH NOWAIT
        END

        WHILE (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
        BEGIN
          SELECT TOP 1 @CurrentFGID = ID,
                       @CurrentFileGroupID = FileGroupID,
                       @CurrentFileGroupName = FileGroupName
          FROM @tmpFileGroups
          WHERE Selected = 1
          AND Completed = 0
          ORDER BY [Order] ASC

          IF @@ROWCOUNT = 0
          BEGIN
            BREAK
          END

          -- Does the filegroup exist?
          SET @CurrentCommand = ''
          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
          SET @CurrentCommand += 'IF EXISTS(SELECT * FROM sys.filegroups filegroups WHERE [type] <> ''FX'' AND filegroups.data_space_id = @ParamFileGroupID AND filegroups.[name] = @ParamFileGroupName) BEGIN SET @ParamFileGroupExists = 1 END'

          BEGIN TRY
            EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamFileGroupID int, @ParamFileGroupName sysname, @ParamFileGroupExists bit OUTPUT', @ParamFileGroupID = @CurrentFileGroupID, @ParamFileGroupName = @CurrentFileGroupName, @ParamFileGroupExists = @CurrentFileGroupExists OUTPUT

            IF @CurrentFileGroupExists IS NULL SET @CurrentFileGroupExists = 0
          END TRY
          BEGIN CATCH
            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'') + CASE WHEN ERROR_NUMBER() = 1222 THEN ', ' + ' The file group ' + QUOTENAME(@CurrentFileGroupName) + ' in the database ' + QUOTENAME(@CurrentDatabaseName) + ' is locked. It could not be checked if the filegroup exists.' ELSE '' END
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR('%s',@Severity,1,@ErrorMessage) WITH NOWAIT
            RAISERROR(@EmptyLine,10,1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
              SET @ReturnCode = ERROR_NUMBER()
            END
          END CATCH

          IF @CurrentFileGroupExists = 1
          BEGIN
            SET @CurrentDatabaseContext = @CurrentDatabaseName

            SET @CurrentCommandType = 'DBCC_CHECKFILEGROUP'

            SET @CurrentCommand = ''
            IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
            SET @CurrentCommand += 'DBCC CHECKFILEGROUP (' + QUOTENAME(@CurrentFileGroupName)
            IF @NoIndex = 'Y' SET @CurrentCommand += ', NOINDEX'
            SET @CurrentCommand += ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
            IF @PhysicalOnly = 'Y' SET @CurrentCommand += ', PHYSICAL_ONLY'
            IF @TabLock = 'Y' SET @CurrentCommand += ', TABLOCK'
            IF @MaxDOP IS NOT NULL SET @CurrentCommand += ', MAXDOP = ' + CAST(@MaxDOP AS nvarchar)

            EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
            SET @Error = @@ERROR
            IF @Error <> 0 SET @CurrentCommandOutput = @Error
            IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
          END

          UPDATE @tmpFileGroups
          SET Completed = 1
          WHERE Selected = 1
          AND Completed = 0
          AND ID = @CurrentFGID

          SET @CurrentFGID = NULL
          SET @CurrentFileGroupID = NULL
          SET @CurrentFileGroupName = NULL
          SET @CurrentFileGroupExists = NULL

          SET @CurrentDatabaseContext = NULL
          SET @CurrentCommand = NULL
          SET @CurrentCommandOutput = NULL
          SET @CurrentCommandType = NULL
        END
      END

      -- Check disk space allocation structures
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKALLOC') AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SET @CurrentDatabaseContext = CASE WHEN SERVERPROPERTY('EngineEdition') = 5 THEN @CurrentDatabaseName ELSE 'master' END

        SET @CurrentCommandType = 'DBCC_CHECKALLOC'

        SET @CurrentCommand = ''
        IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
        SET @CurrentCommand += 'DBCC CHECKALLOC (' + QUOTENAME(@CurrentDatabaseName)
        SET @CurrentCommand += ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
        IF @TabLock = 'Y' SET @CurrentCommand += ', TABLOCK'

        EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput = @Error
        IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
      END

      -- Check objects
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKTABLE')
      AND (@CurrentAvailabilityGroupRole = 'PRIMARY' OR (@CurrentAvailabilityGroupRole = 'SECONDARY' AND @CurrentSecondaryRoleAllowConnections = 'ALL') OR @CurrentAvailabilityGroupRole IS NULL)
      AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SET @CurrentCommand = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, 0 AS [Order], 0 AS Selected, 0 AS Completed FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.schema_id = schemas.schema_id LEFT OUTER JOIN sys.tables tables ON objects.object_id = tables.object_id WHERE objects.[type] IN(''U'',''V'') AND EXISTS(SELECT * FROM sys.indexes indexes WHERE indexes.object_id = objects.object_id)' + CASE WHEN @Version >= 12 THEN ' AND (tables.is_memory_optimized = 0 OR is_memory_optimized IS NULL)' ELSE '' END + ' ORDER BY schemas.name ASC, objects.name ASC'

        INSERT INTO @tmpObjects (SchemaID, SchemaName, ObjectID, ObjectName, ObjectType, [Order], Selected, Completed)
        EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand
        SET @Error = @@ERROR
        IF @Error <> 0 SET @ReturnCode = @Error

        IF @Objects IS NULL
        BEGIN
          UPDATE tmpObjects
          SET tmpObjects.Selected = 1
          FROM @tmpObjects tmpObjects
        END
        ELSE
        BEGIN
          UPDATE tmpObjects
          SET tmpObjects.Selected = SelectedObjects.Selected
          FROM @tmpObjects tmpObjects
          INNER JOIN @SelectedObjects SelectedObjects
          ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
          WHERE SelectedObjects.Selected = 1

          UPDATE tmpObjects
          SET tmpObjects.Selected = SelectedObjects.Selected
          FROM @tmpObjects tmpObjects
          INNER JOIN @SelectedObjects SelectedObjects
          ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
          WHERE SelectedObjects.Selected = 0

          UPDATE tmpObjects
          SET tmpObjects.StartPosition = SelectedObjects2.StartPosition
          FROM @tmpObjects tmpObjects
          INNER JOIN (SELECT tmpObjects.SchemaName, tmpObjects.ObjectName, MIN(SelectedObjects.StartPosition) AS StartPosition
                      FROM @tmpObjects tmpObjects
                      INNER JOIN @SelectedObjects SelectedObjects
                      ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
                      WHERE SelectedObjects.Selected = 1
                      GROUP BY tmpObjects.SchemaName, tmpObjects.ObjectName) SelectedObjects2
          ON tmpObjects.SchemaName = SelectedObjects2.SchemaName AND tmpObjects.ObjectName = SelectedObjects2.ObjectName
        END;

        WITH tmpObjects AS (
        SELECT SchemaName, ObjectName, [Order], ROW_NUMBER() OVER (ORDER BY StartPosition ASC, SchemaName ASC, ObjectName ASC) AS RowNumber
        FROM @tmpObjects tmpObjects
        WHERE Selected = 1
        )
        UPDATE tmpObjects
        SET [Order] = RowNumber

        SET @ErrorMessage = ''
        SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + '.' + QUOTENAME(SchemaName) + '.' + QUOTENAME(ObjectName) + ', '
        FROM @SelectedObjects SelectedObjects
        WHERE DatabaseName = @CurrentDatabaseName
        AND SchemaName NOT LIKE '%[%]%'
        AND ObjectName NOT LIKE '%[%]%'
        AND NOT EXISTS (SELECT * FROM @tmpObjects WHERE SchemaName = SelectedObjects.SchemaName AND ObjectName = SelectedObjects.ObjectName)
        IF @@ROWCOUNT > 0
        BEGIN
          SET @ErrorMessage = 'The following objects do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.'
          RAISERROR('%s',10,1,@ErrorMessage) WITH NOWAIT
          SET @Error = @@ERROR
          RAISERROR(@EmptyLine,10,1) WITH NOWAIT
        END

        WHILE (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
        BEGIN
          SELECT TOP 1 @CurrentOID = ID,
                       @CurrentSchemaID = SchemaID,
                       @CurrentSchemaName = SchemaName,
                       @CurrentObjectID = ObjectID,
                       @CurrentObjectName = ObjectName,
                       @CurrentObjectType = ObjectType
          FROM @tmpObjects
          WHERE Selected = 1
          AND Completed = 0
          ORDER BY [Order] ASC

          IF @@ROWCOUNT = 0
          BEGIN
            BREAK
          END

          -- Does the object exist?
          SET @CurrentCommand = ''
          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
          SET @CurrentCommand += 'IF EXISTS(SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.schema_id = schemas.schema_id LEFT OUTER JOIN sys.tables tables ON objects.object_id = tables.object_id WHERE objects.[type] IN(''U'',''V'') AND EXISTS(SELECT * FROM sys.indexes indexes WHERE indexes.object_id = objects.object_id)' + CASE WHEN @Version >= 12 THEN ' AND (tables.is_memory_optimized = 0 OR is_memory_optimized IS NULL)' ELSE '' END + ' AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType) BEGIN SET @ParamObjectExists = 1 END'

          BEGIN TRY
            EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamObjectExists bit OUTPUT', @ParamSchemaID = @CurrentSchemaID, @ParamSchemaName = @CurrentSchemaName, @ParamObjectID = @CurrentObjectID, @ParamObjectName = @CurrentObjectName, @ParamObjectType = @CurrentObjectType, @ParamObjectExists = @CurrentObjectExists OUTPUT

            IF @CurrentObjectExists IS NULL SET @CurrentObjectExists = 0
          END TRY
          BEGIN CATCH
            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'') + CASE WHEN ERROR_NUMBER() = 1222 THEN ', ' + 'The object ' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' is locked. It could not be checked if the object exists.' ELSE '' END
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR('%s',@Severity,1,@ErrorMessage) WITH NOWAIT
            RAISERROR(@EmptyLine,10,1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
              SET @ReturnCode = ERROR_NUMBER()
            END
          END CATCH

          IF @CurrentObjectExists = 1
          BEGIN
            SET @CurrentDatabaseContext = @CurrentDatabaseName

            SET @CurrentCommandType = 'DBCC_CHECKTABLE'

            SET @CurrentCommand = ''
            IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
            SET @CurrentCommand += 'DBCC CHECKTABLE (''' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ''''
            IF @NoIndex = 'Y' SET @CurrentCommand += ', NOINDEX'
            SET @CurrentCommand += ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
            IF @DataPurity = 'Y' SET @CurrentCommand += ', DATA_PURITY'
            IF @PhysicalOnly = 'Y' SET @CurrentCommand += ', PHYSICAL_ONLY'
            IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand += ', EXTENDED_LOGICAL_CHECKS'
            IF @TabLock = 'Y' SET @CurrentCommand += ', TABLOCK'
            IF @MaxDOP IS NOT NULL SET @CurrentCommand += ', MAXDOP = ' + CAST(@MaxDOP AS nvarchar)

            EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @SchemaName = @CurrentSchemaName, @ObjectName = @CurrentObjectName, @ObjectType = @CurrentObjectType, @LogToTable = @LogToTable, @Execute = @Execute
            SET @Error = @@ERROR
            IF @Error <> 0 SET @CurrentCommandOutput = @Error
            IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
          END

          UPDATE @tmpObjects
          SET Completed = 1
          WHERE Selected = 1
          AND Completed = 0
          AND ID = @CurrentOID

          SET @CurrentOID = NULL
          SET @CurrentSchemaID = NULL
          SET @CurrentSchemaName = NULL
          SET @CurrentObjectID = NULL
          SET @CurrentObjectName = NULL
          SET @CurrentObjectType = NULL
          SET @CurrentObjectExists = NULL

          SET @CurrentDatabaseContext = NULL
          SET @CurrentCommand = NULL
          SET @CurrentCommandOutput = NULL
          SET @CurrentCommandType = NULL
        END
      END

      -- Check catalog
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKCATALOG') AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SET @CurrentDatabaseContext = CASE WHEN SERVERPROPERTY('EngineEdition') = 5 THEN @CurrentDatabaseName ELSE 'master' END

        SET @CurrentCommandType = 'DBCC_CHECKCATALOG'

        SET @CurrentCommand = ''
        IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
        SET @CurrentCommand += 'DBCC CHECKCATALOG (' + QUOTENAME(@CurrentDatabaseName)
        SET @CurrentCommand += ') WITH NO_INFOMSGS'

        EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseContext, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput = @Error
        IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
      END

    END

    IF @CurrentDatabaseState = 'SUSPECT'
    BEGIN
      SET @ErrorMessage = 'The database ' + QUOTENAME(@CurrentDatabaseName) + ' is in a SUSPECT state.'
      RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT
      SET @Error = @@ERROR
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
    END

    -- Update that the database is completed
    IF @DatabasesInParallel = 'Y'
    BEGIN
      UPDATE dbo.QueueDatabase
      SET DatabaseEndTime = SYSDATETIME()
      WHERE QueueID = @QueueID
      AND DatabaseName = @CurrentDatabaseName
    END
    ELSE
    BEGIN
      UPDATE @tmpDatabases
      SET Completed = 1
      WHERE Selected = 1
      AND Completed = 0
      AND ID = @CurrentDBID
    END

    -- Clear variables
    SET @CurrentDBID = NULL
    SET @CurrentDatabaseName = NULL

    SET @CurrentDatabase_sp_executesql = NULL

    SET @CurrentUserAccess = NULL
    SET @CurrentIsReadOnly = NULL
    SET @CurrentDatabaseState = NULL
    SET @CurrentInStandby = NULL
    SET @CurrentRecoveryModel = NULL

    SET @CurrentIsDatabaseAccessible = NULL
    SET @CurrentReplicaID = NULL
    SET @CurrentAvailabilityGroupID = NULL
    SET @CurrentAvailabilityGroup = NULL
    SET @CurrentAvailabilityGroupRole = NULL
    SET @CurrentAvailabilityGroupBackupPreference = NULL
    SET @CurrentSecondaryRoleAllowConnections = NULL
    SET @CurrentIsPreferredBackupReplica = NULL
    SET @CurrentDatabaseMirroringRole = NULL

    SET @CurrentDatabaseContext = NULL
    SET @CurrentCommand = NULL
    SET @CurrentCommandOutput = NULL
    SET @CurrentCommandType = NULL

    DELETE FROM @tmpFileGroups
    DELETE FROM @tmpObjects

  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  Logging:
  SET @EndMessage = 'Date and time: ' + CONVERT(nvarchar,SYSDATETIME(),120)
  RAISERROR('%s',10,1,@EndMessage) WITH NOWAIT

  RAISERROR(@EmptyLine,10,1) WITH NOWAIT

  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END

GO

ALTER AUTHORIZATION ON [dbo].[DatabaseIntegrityCheck] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[DatabaseIntegrityCheck] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[dba_CopyLogins]    Script Date: 10/13/2021 12:39:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dba_CopyLogins]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[dba_CopyLogins] AS' 
END
GO


ALTER Procedure [dbo].[dba_CopyLogins]
	@PartnerServer sysname,
	@Debug bit = 0
As

Declare @MaxID int,
	@CurrID int,
	@SQL nvarchar(max),
	@LoginName sysname,
	@IsDisabled int,
	@Type char(1),
	@SID varbinary(85),
	@SIDString nvarchar(100),
	@PasswordHash varbinary(256),
	@PasswordHashString nvarchar(300),
	@RoleName sysname,
	@Machine sysname,
	@PermState nvarchar(60),
	@PermName sysname,
	@Class tinyint,
	@MajorID int,
	@ErrNumber int,
	@ErrSeverity int,
	@ErrState int,
	@ErrProcedure sysname,
	@ErrLine int,
	@ErrMsg nvarchar(2048)
Declare @Logins Table (LoginID int identity(1, 1) not null primary key,
						[Name] sysname not null,
						[SID] varbinary(85) not null,
						IsDisabled int not null,
						[Type] char(1) not null,
						PasswordHash varbinary(256) null)
Declare @Roles Table (RoleID int identity(1, 1) not null primary key,
					RoleName sysname not null,
					LoginName sysname not null)
Declare @Perms Table (PermID int identity(1, 1) not null primary key,
					LoginName sysname not null,
					PermState nvarchar(60) not null,
					PermName sysname not null,
					Class tinyint not null,
					ClassDesc nvarchar(60) not null,
					MajorID int not null,
					SubLoginName sysname null,
					SubEndPointName sysname null)

Set NoCount On;

If CharIndex('\', @PartnerServer) > 0
  Begin
	Set @Machine = LEFT(@PartnerServer, CharIndex('\', @PartnerServer) - 1);
  End
Else
  Begin
	Set @Machine = @PartnerServer;
  End

-- Get all Windows logins from principal server
Set @SQL = 'Select P.name, P.sid, P.is_disabled, P.type, L.password_hash' + CHAR(10) +
		'From ' + QUOTENAME(@PartnerServer) + '.master.sys.server_principals P' + CHAR(10) +
		'Left Join ' + QUOTENAME(@PartnerServer) + '.master.sys.sql_logins L On L.principal_id = P.principal_id' + CHAR(10) +
		'Where P.type In (''U'', ''G'', ''S'')' + CHAR(10) +
		'And P.name <> ''sa''' + CHAR(10) +
		'And P.name Not Like ''##%''' + CHAR(10) +
		'And CharIndex(''' + @Machine + '\'', P.name) = 0;';

Insert Into @Logins (Name, SID, IsDisabled, Type, PasswordHash)
Exec sp_executesql @SQL;

-- Get all roles from principal server
Set @SQL = 'Select RoleP.name, LoginP.name' + CHAR(10) +
		'From ' + QUOTENAME(@PartnerServer) + '.master.sys.server_role_members RM' + CHAR(10) +
		'Inner Join ' + QUOTENAME(@PartnerServer) + '.master.sys.server_principals RoleP' +
		CHAR(10) + char(9) + 'On RoleP.principal_id = RM.role_principal_id' + CHAR(10) +
		'Inner Join ' + QUOTENAME(@PartnerServer) + '.master.sys.server_principals LoginP' +
		CHAR(10) + char(9) + 'On LoginP.principal_id = RM.member_principal_id' + CHAR(10) +
		'Where LoginP.type In (''U'', ''G'', ''S'')' + CHAR(10) +
		'And LoginP.name <> ''sa''' + CHAR(10) +
		'And LoginP.name Not Like ''##%''' + CHAR(10) +
		'And RoleP.type = ''R''' + CHAR(10) +
		'And CharIndex(''' + @Machine + '\'', LoginP.name) = 0;';

Insert Into @Roles (RoleName, LoginName)
Exec sp_executesql @SQL;

-- Get all explicitly granted permissions
Set @SQL = 'Select P.name Collate database_default,' + CHAR(10) +
		'	SP.state_desc, SP.permission_name, SP.class, SP.class_desc, SP.major_id,' + CHAR(10) +
		'	SubP.name Collate database_default,' + CHAR(10) +
		'	SubEP.name Collate database_default' + CHAR(10) +
		'From ' + QUOTENAME(@PartnerServer) + '.master.sys.server_principals P' + CHAR(10) +
		'Inner Join ' + QUOTENAME(@PartnerServer) + '.master.sys.server_permissions SP' + CHAR(10) +
		CHAR(9) + 'On SP.grantee_principal_id = P.principal_id' + CHAR(10) +
		'Left Join ' + QUOTENAME(@PartnerServer) + '.master.sys.server_principals SubP' + CHAR(10) +
		CHAR(9) + 'On SubP.principal_id = SP.major_id And SP.class = 101' + CHAR(10) +
		'Left Join ' + QUOTENAME(@PartnerServer) + '.master.sys.endpoints SubEP' + CHAR(10) +
		CHAR(9) + 'On SubEP.endpoint_id = SP.major_id And SP.class = 105' + CHAR(10) +
		'Where P.type In (''U'', ''G'', ''S'')' + CHAR(10) +
		'And P.name <> ''sa''' + CHAR(10) +
		'And P.name Not Like ''##%''' + CHAR(10) +
		'And CharIndex(''' + @Machine + '\'', P.name) = 0;'

Insert Into @Perms (LoginName, PermState, PermName, Class, ClassDesc, MajorID, SubLoginName, SubEndPointName)
Exec sp_executesql @SQL;

Select @MaxID = Max(LoginID), @CurrID = 1
From @Logins;

While @CurrID <= @MaxID
  Begin
	Select @LoginName = Name,
		@IsDisabled = IsDisabled,
		@Type = [Type],
		@SID = [SID],
		@PasswordHash = PasswordHash
	From @Logins
	Where LoginID = @CurrID;
	
	If Not Exists (Select 1 From sys.server_principals
				Where name = @LoginName)
	  Begin
		Set @SQL = 'Create Login ' + quotename(@LoginName)
		If @Type In ('U', 'G')
		  Begin
			Set @SQL = @SQL + ' From Windows;'
		  End
		Else
		  Begin
			Set @PasswordHashString = '0x' +
				Cast('' As XML).value('xs:hexBinary(sql:variable("@PasswordHash"))', 'nvarchar(300)');
			
			Set @SQL = @SQL + ' With Password = ' + @PasswordHashString + ' HASHED, ';
			
			Set @SIDString = '0x' +
				Cast('' As XML).value('xs:hexBinary(sql:variable("@SID"))', 'nvarchar(100)');
			Set @SQL = @SQL + 'SID = ' + @SIDString + ';';
		  End

		If @Debug = 0
		  Begin
			Begin Try
				Exec sp_executesql @SQL;
			End Try
			Begin Catch
				Set @ErrNumber = ERROR_NUMBER();
				Set @ErrSeverity = ERROR_SEVERITY();
				Set @ErrState = ERROR_STATE();
				Set @ErrProcedure = ERROR_PROCEDURE();
				Set @ErrLine = ERROR_LINE();
				Set @ErrMsg = ERROR_MESSAGE();
				RaisError(@ErrMsg, 1, 1);
			End Catch
		  End
		Else
		  Begin
			Print @SQL;
		  End
		
		If @IsDisabled = 1
		  Begin
			Set @SQL = 'Alter Login ' + quotename(@LoginName) + ' Disable;'
			If @Debug = 0
			  Begin
				Begin Try
					Exec sp_executesql @SQL;
				End Try
				Begin Catch
					Set @ErrNumber = ERROR_NUMBER();
					Set @ErrSeverity = ERROR_SEVERITY();
					Set @ErrState = ERROR_STATE();
					Set @ErrProcedure = ERROR_PROCEDURE();
					Set @ErrLine = ERROR_LINE();
					Set @ErrMsg = ERROR_MESSAGE();
					RaisError(@ErrMsg, 1, 1);
				End Catch
			  End
			Else
			  Begin
				Print @SQL;
			  End
		  End
		End
	Set @CurrID = @CurrID + 1;
  End

Select @MaxID = Max(RoleID), @CurrID = 1
From @Roles;

While @CurrID <= @MaxID
  Begin
	Select @LoginName = LoginName,
		@RoleName = RoleName
	From @Roles
	Where RoleID = @CurrID;

	If Not Exists (Select 1 From sys.server_role_members RM
				Inner Join sys.server_principals RoleP
					On RoleP.principal_id = RM.role_principal_id
				Inner Join sys.server_principals LoginP
					On LoginP.principal_id = RM.member_principal_id
				Where LoginP.type In ('U', 'G', 'S')
				And RoleP.type = 'R'
				And RoleP.name = @RoleName
				And LoginP.name = @LoginName)
	  Begin
		If @Debug = 0
		  Begin
			Exec sp_addsrvrolemember @rolename = @RoleName,
							@loginame = @LoginName;
		  End
		Else
		  Begin
			Print 'Exec sp_addsrvrolemember @rolename = ''' + @RoleName + ''',';
			Print '		@loginame = ''' + @LoginName + ''';';
		  End
	  End

	Set @CurrID = @CurrID + 1;
  End

Select @MaxID = Max(PermID), @CurrID = 1
From @Perms;

While @CurrID <= @MaxID
  Begin
	Select @PermState = PermState,
		@PermName = PermName,
		@Class = Class,
		@LoginName = LoginName,
		@MajorID = MajorID,
		@SQL = PermState + space(1) + PermName + SPACE(1) +
			Case Class When 101 Then 'On Login::' + QUOTENAME(SubLoginName)
					When 105 Then 'On ' + ClassDesc + '::' + QUOTENAME(SubEndPointName)
					Else '' End +
			' To ' + QUOTENAME(LoginName) + ';'
	From @Perms
	Where PermID = @CurrID;
	
	If Not Exists (Select 1 From sys.server_principals P
				Inner Join sys.server_permissions SP On SP.grantee_principal_id = P.principal_id
				Where SP.state_desc = @PermState
				And SP.permission_name = @PermName
				And SP.class = @Class
				And P.name = @LoginName
				And SP.major_id = @MajorID)
	  Begin
		If @Debug = 0
		  Begin
			Begin Try
				Exec sp_executesql @SQL;
			End Try
			Begin Catch
				Set @ErrNumber = ERROR_NUMBER();
				Set @ErrSeverity = ERROR_SEVERITY();
				Set @ErrState = ERROR_STATE();
				Set @ErrProcedure = ERROR_PROCEDURE();
				Set @ErrLine = ERROR_LINE();
				Set @ErrMsg = ERROR_MESSAGE();
				RaisError(@ErrMsg, 1, 1);
			End Catch
		  End
		Else
		  Begin
			Print @SQL;
		  End
	  End

	Set @CurrID = @CurrID + 1;
  End

Set NoCount Off;
GO

ALTER AUTHORIZATION ON [dbo].[dba_CopyLogins] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[dba_CopyLogins] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[dba_ManageLinkedServer]    Script Date: 10/13/2021 12:39:03 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[dba_ManageLinkedServer]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[dba_ManageLinkedServer] AS' 
END
GO

ALTER Procedure [dbo].[dba_ManageLinkedServer]
	@ServerName sysname,
	@Action varchar(10) = 'create'
As
If @ServerName = @@ServerName
	Return

If @Action = 'create'
 Begin
	If Not Exists (Select 1 From sys.servers 
					Where name = @ServerName
					And is_linked = 1)
	  Begin
		EXEC master.dbo.sp_addlinkedserver @server = @ServerName,
									@srvproduct = N'SQL Server';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'collation compatible',
									@optvalue = N'false';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'data access',
									@optvalue = N'true';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'dist',
									@optvalue = N'false';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'pub',
									@optvalue = N'false';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'rpc',
									@optvalue = N'true';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'rpc out',
									@optvalue = N'true';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'sub',
									@optvalue = N'false';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'connect timeout',
									@optvalue = N'0';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'collation name',
									@optvalue = null;
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'lazy schema validation',
									@optvalue = N'false';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'query timeout',
									@optvalue = N'0';
		EXEC master.dbo.sp_serveroption @server = @ServerName,
									@optname = N'use remote collation',
									@optvalue = N'true';
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @ServerName,
									@locallogin = NULL ,
									@useself = N'True';
	  End
  End
Else If @Action = 'drop'
 Begin
	If Exists (Select 1 From sys.servers 
				Where name = @ServerName
				And is_linked = 1)
	  Begin
		Exec master.dbo.sp_dropserver @server = @ServerName,
									@droplogins = Null
	  End
  End
GO

ALTER AUTHORIZATION ON [dbo].[dba_ManageLinkedServer] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[dba_ManageLinkedServer] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[emc_run_backup]    Script Date: 10/13/2021 12:39:03 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[emc_run_backup]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[emc_run_backup] AS' 
END
GO

ALTER PROCEDURE [dbo].[emc_run_backup]
	@cmdText [nvarchar](max)
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ddbmaSQLCLR].[ddbmaSQLCLRLib.DDBMASQL].[RunBackup]
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_backup] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_backup] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[emc_run_delete]    Script Date: 10/13/2021 12:39:03 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[emc_run_delete]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[emc_run_delete] AS' 
END
GO

ALTER PROCEDURE [dbo].[emc_run_delete]
	@cmdText [nvarchar](max)
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ddbmaSQLCLR].[ddbmaSQLCLRLib.DDBMASQL].[RunDelete]
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_delete] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_delete] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[emc_run_restore]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[emc_run_restore]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[emc_run_restore] AS' 
END
GO

ALTER PROCEDURE [dbo].[emc_run_restore]
	@cmdText [nvarchar](max)
WITH EXECUTE AS CALLER
AS
EXTERNAL NAME [ddbmaSQLCLR].[ddbmaSQLCLRLib.DDBMASQL].[RunRestore]
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_restore] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[emc_run_restore] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[IndexOptimize]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IndexOptimize]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[IndexOptimize] AS' 
END
GO

ALTER PROCEDURE [dbo].[IndexOptimize]

@Databases nvarchar(max) = NULL,
@FragmentationLow nvarchar(max) = NULL,
@FragmentationMedium nvarchar(max) = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh nvarchar(max) = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 int = 5,
@FragmentationLevel2 int = 30,
@MinNumberOfPages int = 1000,
@MaxNumberOfPages int = NULL,
@SortInTempdb nvarchar(max) = 'N',
@MaxDOP int = NULL,
@FillFactor int = NULL,
@PadIndex nvarchar(max) = NULL,
@LOBCompaction nvarchar(max) = 'Y',
@UpdateStatistics nvarchar(max) = NULL,
@OnlyModifiedStatistics nvarchar(max) = 'N',
@StatisticsModificationLevel int = NULL,
@StatisticsSample int = NULL,
@StatisticsResample nvarchar(max) = 'N',
@PartitionLevel nvarchar(max) = 'Y',
@MSShippedObjects nvarchar(max) = 'N',
@Indexes nvarchar(max) = NULL,
@TimeLimit int = NULL,
@Delay int = NULL,
@WaitAtLowPriorityMaxDuration int = NULL,
@WaitAtLowPriorityAbortAfterWait nvarchar(max) = NULL,
@Resumable nvarchar(max) = 'N',
@AvailabilityGroups nvarchar(max) = NULL,
@LockTimeout int = NULL,
@LockMessageSeverity int = 16,
@StringDelimiter nvarchar(max) = ',',
@DatabaseOrder nvarchar(max) = NULL,
@DatabasesInParallel nvarchar(max) = 'N',
@ExecuteAsUser nvarchar(max) = NULL,
@LogToTable nvarchar(max) = 'N',
@Execute nvarchar(max) = 'Y'

AS

BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source:  https://ola.hallengren.com                                                        //--
  --// License: https://ola.hallengren.com/license.html                                           //--
  --// GitHub:  https://github.com/olahallengren/sql-server-maintenance-solution                  //--
  --// Version: 2020-12-06 00:32:13                                                               //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  SET ARITHABORT ON

  SET NUMERIC_ROUNDABORT OFF

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @DatabaseMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)
  DECLARE @Severity int

  DECLARE @StartTime datetime2 = SYSDATETIME()
  DECLARE @SchemaName nvarchar(max) = OBJECT_SCHEMA_NAME(@@PROCID)
  DECLARE @ObjectName nvarchar(max) = OBJECT_NAME(@@PROCID)
  DECLARE @VersionTimestamp nvarchar(max) = SUBSTRING(OBJECT_DEFINITION(@@PROCID),CHARINDEX('--// Version: ',OBJECT_DEFINITION(@@PROCID)) + LEN('--// Version: ') + 1, 19)
  DECLARE @Parameters nvarchar(max)

  DECLARE @HostPlatform nvarchar(max)

  DECLARE @PartitionLevelStatistics bit

  DECLARE @QueueID int
  DECLARE @QueueStartTime datetime2

  DECLARE @CurrentDBID int
  DECLARE @CurrentDatabaseName nvarchar(max)

  DECLARE @CurrentDatabase_sp_executesql nvarchar(max)

  DECLARE @CurrentExecuteAsUserExists bit
  DECLARE @CurrentUserAccess nvarchar(max)
  DECLARE @CurrentIsReadOnly bit
  DECLARE @CurrentDatabaseState nvarchar(max)
  DECLARE @CurrentInStandby bit
  DECLARE @CurrentRecoveryModel nvarchar(max)

  DECLARE @CurrentIsDatabaseAccessible bit
  DECLARE @CurrentReplicaID uniqueidentifier
  DECLARE @CurrentAvailabilityGroupID uniqueidentifier
  DECLARE @CurrentAvailabilityGroup nvarchar(max)
  DECLARE @CurrentAvailabilityGroupRole nvarchar(max)
  DECLARE @CurrentDatabaseMirroringRole nvarchar(max)

  DECLARE @CurrentDatabaseContext nvarchar(max)
  DECLARE @CurrentCommand nvarchar(max)
  DECLARE @CurrentCommandOutput int
  DECLARE @CurrentCommandType nvarchar(max)
  DECLARE @CurrentComment nvarchar(max)
  DECLARE @CurrentExtendedInfo xml

  DECLARE @Errors TABLE (ID int IDENTITY PRIMARY KEY,
                         [Message] nvarchar(max) NOT NULL,
                         Severity int NOT NULL,
                         [State] int)

  DECLARE @CurrentMessage nvarchar(max)
  DECLARE @CurrentSeverity int
  DECLARE @CurrentState int

  DECLARE @CurrentIxID int
  DECLARE @CurrentIxOrder int
  DECLARE @CurrentSchemaID int
  DECLARE @CurrentSchemaName nvarchar(max)
  DECLARE @CurrentObjectID int
  DECLARE @CurrentObjectName nvarchar(max)
  DECLARE @CurrentObjectType nvarchar(max)
  DECLARE @CurrentIsMemoryOptimized bit
  DECLARE @CurrentIndexID int
  DECLARE @CurrentIndexName nvarchar(max)
  DECLARE @CurrentIndexType int
  DECLARE @CurrentStatisticsID int
  DECLARE @CurrentStatisticsName nvarchar(max)
  DECLARE @CurrentPartitionID bigint
  DECLARE @CurrentPartitionNumber int
  DECLARE @CurrentPartitionCount int
  DECLARE @CurrentIsPartition bit
  DECLARE @CurrentIndexExists bit
  DECLARE @CurrentStatisticsExists bit
  DECLARE @CurrentIsImageText bit
  DECLARE @CurrentIsNewLOB bit
  DECLARE @CurrentIsFileStream bit
  DECLARE @CurrentIsColumnStore bit
  DECLARE @CurrentIsComputed bit
  DECLARE @CurrentIsTimestamp bit
  DECLARE @CurrentAllowPageLocks bit
  DECLARE @CurrentNoRecompute bit
  DECLARE @CurrentIsIncremental bit
  DECLARE @CurrentRowCount bigint
  DECLARE @CurrentModificationCounter bigint
  DECLARE @CurrentOnReadOnlyFileGroup bit
  DECLARE @CurrentResumableIndexOperation bit
  DECLARE @CurrentFragmentationLevel float
  DECLARE @CurrentPageCount bigint
  DECLARE @CurrentFragmentationGroup nvarchar(max)
  DECLARE @CurrentAction nvarchar(max)
  DECLARE @CurrentMaxDOP int
  DECLARE @CurrentUpdateStatistics nvarchar(max)
  DECLARE @CurrentStatisticsSample int
  DECLARE @CurrentStatisticsResample nvarchar(max)
  DECLARE @CurrentDelay datetime

  DECLARE @tmpDatabases TABLE (ID int IDENTITY,
                               DatabaseName nvarchar(max),
                               DatabaseType nvarchar(max),
                               AvailabilityGroup bit,
                               StartPosition int,
                               DatabaseSize bigint,
                               [Order] int,
                               Selected bit,
                               Completed bit,
                               PRIMARY KEY(Selected, Completed, [Order], ID))

  DECLARE @tmpAvailabilityGroups TABLE (ID int IDENTITY PRIMARY KEY,
                                        AvailabilityGroupName nvarchar(max),
                                        StartPosition int,
                                        Selected bit)

  DECLARE @tmpDatabasesAvailabilityGroups TABLE (DatabaseName nvarchar(max),
                                                 AvailabilityGroupName nvarchar(max))

  DECLARE @tmpIndexesStatistics TABLE (ID int IDENTITY,
                                       SchemaID int,
                                       SchemaName nvarchar(max),
                                       ObjectID int,
                                       ObjectName nvarchar(max),
                                       ObjectType nvarchar(max),
                                       IsMemoryOptimized bit,
                                       IndexID int,
                                       IndexName nvarchar(max),
                                       IndexType int,
                                       AllowPageLocks bit,
                                       IsImageText bit,
                                       IsNewLOB bit,
                                       IsFileStream bit,
                                       IsColumnStore bit,
                                       IsComputed bit,
                                       IsTimestamp bit,
                                       OnReadOnlyFileGroup bit,
                                       ResumableIndexOperation bit,
                                       StatisticsID int,
                                       StatisticsName nvarchar(max),
                                       [NoRecompute] bit,
                                       IsIncremental bit,
                                       PartitionID bigint,
                                       PartitionNumber int,
                                       PartitionCount int,
                                       StartPosition int,
                                       [Order] int,
                                       Selected bit,
                                       Completed bit,
                                       PRIMARY KEY(Selected, Completed, [Order], ID))

  DECLARE @SelectedDatabases TABLE (DatabaseName nvarchar(max),
                                    DatabaseType nvarchar(max),
                                    AvailabilityGroup nvarchar(max),
                                    StartPosition int,
                                    Selected bit)

  DECLARE @SelectedAvailabilityGroups TABLE (AvailabilityGroupName nvarchar(max),
                                             StartPosition int,
                                             Selected bit)

  DECLARE @SelectedIndexes TABLE (DatabaseName nvarchar(max),
                                  SchemaName nvarchar(max),
                                  ObjectName nvarchar(max),
                                  IndexName nvarchar(max),
                                  StartPosition int,
                                  Selected bit)

  DECLARE @Actions TABLE ([Action] nvarchar(max))

  INSERT INTO @Actions([Action]) VALUES('INDEX_REBUILD_ONLINE')
  INSERT INTO @Actions([Action]) VALUES('INDEX_REBUILD_OFFLINE')
  INSERT INTO @Actions([Action]) VALUES('INDEX_REORGANIZE')

  DECLARE @ActionsPreferred TABLE (FragmentationGroup nvarchar(max),
                                   [Priority] int,
                                   [Action] nvarchar(max))

  DECLARE @CurrentActionsAllowed TABLE ([Action] nvarchar(max))

  DECLARE @CurrentAlterIndexWithClauseArguments TABLE (ID int IDENTITY,
                                                       Argument nvarchar(max),
                                                       Added bit DEFAULT 0)

  DECLARE @CurrentAlterIndexArgumentID int
  DECLARE @CurrentAlterIndexArgument nvarchar(max)
  DECLARE @CurrentAlterIndexWithClause nvarchar(max)

  DECLARE @CurrentUpdateStatisticsWithClauseArguments TABLE (ID int IDENTITY,
                                                             Argument nvarchar(max),
                                                             Added bit DEFAULT 0)

  DECLARE @CurrentUpdateStatisticsArgumentID int
  DECLARE @CurrentUpdateStatisticsArgument nvarchar(max)
  DECLARE @CurrentUpdateStatisticsWithClause nvarchar(max)

  DECLARE @Error int = 0
  DECLARE @ReturnCode int = 0

  DECLARE @EmptyLine nvarchar(max) = CHAR(9)

  DECLARE @Version numeric(18,10) = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

  IF @Version >= 14
  BEGIN
    SELECT @HostPlatform = host_platform
    FROM sys.dm_os_host_info
  END
  ELSE
  BEGIN
    SET @HostPlatform = 'Windows'
  END

  DECLARE @AmazonRDS bit = CASE WHEN DB_ID('rdsadmin') IS NOT NULL AND SUSER_SNAME(0x01) = 'rdsa' THEN 1 ELSE 0 END

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------

  SET @Parameters = '@Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
  SET @Parameters += ', @FragmentationLow = ' + ISNULL('''' + REPLACE(@FragmentationLow,'''','''''') + '''','NULL')
  SET @Parameters += ', @FragmentationMedium = ' + ISNULL('''' + REPLACE(@FragmentationMedium,'''','''''') + '''','NULL')
  SET @Parameters += ', @FragmentationHigh = ' + ISNULL('''' + REPLACE(@FragmentationHigh,'''','''''') + '''','NULL')
  SET @Parameters += ', @FragmentationLevel1 = ' + ISNULL(CAST(@FragmentationLevel1 AS nvarchar),'NULL')
  SET @Parameters += ', @FragmentationLevel2 = ' + ISNULL(CAST(@FragmentationLevel2 AS nvarchar),'NULL')
  SET @Parameters += ', @MinNumberOfPages = ' + ISNULL(CAST(@MinNumberOfPages AS nvarchar),'NULL')
  SET @Parameters += ', @MaxNumberOfPages = ' + ISNULL(CAST(@MaxNumberOfPages AS nvarchar),'NULL')
  SET @Parameters += ', @SortInTempdb = ' + ISNULL('''' + REPLACE(@SortInTempdb,'''','''''') + '''','NULL')
  SET @Parameters += ', @MaxDOP = ' + ISNULL(CAST(@MaxDOP AS nvarchar),'NULL')
  SET @Parameters += ', @FillFactor = ' + ISNULL(CAST(@FillFactor AS nvarchar),'NULL')
  SET @Parameters += ', @PadIndex = ' + ISNULL('''' + REPLACE(@PadIndex,'''','''''') + '''','NULL')
  SET @Parameters += ', @LOBCompaction = ' + ISNULL('''' + REPLACE(@LOBCompaction,'''','''''') + '''','NULL')
  SET @Parameters += ', @UpdateStatistics = ' + ISNULL('''' + REPLACE(@UpdateStatistics,'''','''''') + '''','NULL')
  SET @Parameters += ', @OnlyModifiedStatistics = ' + ISNULL('''' + REPLACE(@OnlyModifiedStatistics,'''','''''') + '''','NULL')
  SET @Parameters += ', @StatisticsModificationLevel = ' + ISNULL(CAST(@StatisticsModificationLevel AS nvarchar),'NULL')
  SET @Parameters += ', @StatisticsSample = ' + ISNULL(CAST(@StatisticsSample AS nvarchar),'NULL')
  SET @Parameters += ', @StatisticsResample = ' + ISNULL('''' + REPLACE(@StatisticsResample,'''','''''') + '''','NULL')
  SET @Parameters += ', @PartitionLevel = ' + ISNULL('''' + REPLACE(@PartitionLevel,'''','''''') + '''','NULL')
  SET @Parameters += ', @MSShippedObjects = ' + ISNULL('''' + REPLACE(@MSShippedObjects,'''','''''') + '''','NULL')
  SET @Parameters += ', @Indexes = ' + ISNULL('''' + REPLACE(@Indexes,'''','''''') + '''','NULL')
  SET @Parameters += ', @TimeLimit = ' + ISNULL(CAST(@TimeLimit AS nvarchar),'NULL')
  SET @Parameters += ', @Delay = ' + ISNULL(CAST(@Delay AS nvarchar),'NULL')
  SET @Parameters += ', @WaitAtLowPriorityMaxDuration = ' + ISNULL(CAST(@WaitAtLowPriorityMaxDuration AS nvarchar),'NULL')
  SET @Parameters += ', @WaitAtLowPriorityAbortAfterWait = ' + ISNULL('''' + REPLACE(@WaitAtLowPriorityAbortAfterWait,'''','''''') + '''','NULL')
  SET @Parameters += ', @Resumable = ' + ISNULL('''' + REPLACE(@Resumable,'''','''''') + '''','NULL')
  SET @Parameters += ', @AvailabilityGroups = ' + ISNULL('''' + REPLACE(@AvailabilityGroups,'''','''''') + '''','NULL')
  SET @Parameters += ', @LockTimeout = ' + ISNULL(CAST(@LockTimeout AS nvarchar),'NULL')
  SET @Parameters += ', @LockMessageSeverity = ' + ISNULL(CAST(@LockMessageSeverity AS nvarchar),'NULL')
  SET @Parameters += ', @StringDelimiter = ' + ISNULL('''' + REPLACE(@StringDelimiter,'''','''''') + '''','NULL')
  SET @Parameters += ', @DatabaseOrder = ' + ISNULL('''' + REPLACE(@DatabaseOrder,'''','''''') + '''','NULL')
  SET @Parameters += ', @DatabasesInParallel = ' + ISNULL('''' + REPLACE(@DatabasesInParallel,'''','''''') + '''','NULL')
  SET @Parameters += ', @ExecuteAsUser = ' + ISNULL('''' + REPLACE(@ExecuteAsUser,'''','''''') + '''','NULL')
  SET @Parameters += ', @LogToTable = ' + ISNULL('''' + REPLACE(@LogToTable,'''','''''') + '''','NULL')
  SET @Parameters += ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL')

  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,@StartTime,120)
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar(max))
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Platform: ' + @HostPlatform
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ObjectName)
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Parameters: ' + @Parameters
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Version: ' + @VersionTimestamp
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  SET @StartMessage = 'Source: https://ola.hallengren.com'
  RAISERROR('%s',10,1,@StartMessage) WITH NOWAIT

  RAISERROR(@EmptyLine,10,1) WITH NOWAIT

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF NOT (SELECT [compatibility_level] FROM sys.databases WHERE database_id = DB_ID()) >= 90
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The database ' + QUOTENAME(DB_NAME(DB_ID())) + ' has to be in compatibility level 90 or higher.', 16, 1
  END

  IF NOT (SELECT uses_ansi_nulls FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'ANSI_NULLS has to be set to ON for the stored procedure.', 16, 1
  END

  IF NOT (SELECT uses_quoted_identifier FROM sys.sql_modules WHERE [object_id] = @@PROCID) = 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'QUOTED_IDENTIFIER has to be set to ON for the stored procedure.', 16, 1
  END

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure CommandExecute is missing. Download https://ola.hallengren.com/scripts/CommandExecute.sql.', 16, 1
  END

  IF EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute' AND OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@DatabaseContext%')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The stored procedure CommandExecute needs to be updated. Download https://ola.hallengren.com/scripts/CommandExecute.sql.', 16, 1
  END

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table CommandLog is missing. Download https://ola.hallengren.com/scripts/CommandLog.sql.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'Queue')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table Queue is missing. Download https://ola.hallengren.com/scripts/Queue.sql.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'QueueDatabase')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The table QueueDatabase is missing. Download https://ola.hallengren.com/scripts/QueueDatabase.sql.', 16, 1
  END

  IF @@TRANCOUNT <> 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The transaction count is not 0.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select databases                                                                           //--
  ----------------------------------------------------------------------------------------------------

  SET @Databases = REPLACE(@Databases, CHAR(10), '')
  SET @Databases = REPLACE(@Databases, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @Databases) > 0 SET @Databases = REPLACE(@Databases, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @Databases) > 0 SET @Databases = REPLACE(@Databases, ' ' + @StringDelimiter, @StringDelimiter)

  SET @Databases = LTRIM(RTRIM(@Databases));

  WITH Databases1 (StartPosition, EndPosition, DatabaseItem) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, 1), 0), LEN(@Databases) + 1) AS EndPosition,
         SUBSTRING(@Databases, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, 1), 0), LEN(@Databases) + 1) - 1) AS DatabaseItem
  WHERE @Databases IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) AS EndPosition,
         SUBSTRING(@Databases, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Databases, EndPosition + 1), 0), LEN(@Databases) + 1) - EndPosition - 1) AS DatabaseItem
  FROM Databases1
  WHERE EndPosition < LEN(@Databases) + 1
  ),
  Databases2 (DatabaseItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem LIKE '-%' THEN RIGHT(DatabaseItem,LEN(DatabaseItem) - 1) ELSE DatabaseItem END AS DatabaseItem,
         StartPosition,
         CASE WHEN DatabaseItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Databases1
  ),
  Databases3 (DatabaseItem, DatabaseType, AvailabilityGroup, StartPosition, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem IN('ALL_DATABASES','SYSTEM_DATABASES','USER_DATABASES','AVAILABILITY_GROUP_DATABASES') THEN '%' ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem = 'SYSTEM_DATABASES' THEN 'S' WHEN DatabaseItem = 'USER_DATABASES' THEN 'U' ELSE NULL END AS DatabaseType,
         CASE WHEN DatabaseItem = 'AVAILABILITY_GROUP_DATABASES' THEN 1 ELSE NULL END AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases2
  ),
  Databases4 (DatabaseName, DatabaseType, AvailabilityGroup, StartPosition, Selected) AS
  (
  SELECT CASE WHEN LEFT(DatabaseItem,1) = '[' AND RIGHT(DatabaseItem,1) = ']' THEN PARSENAME(DatabaseItem,1) ELSE DatabaseItem END AS DatabaseItem,
         DatabaseType,
         AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases3
  )
  INSERT INTO @SelectedDatabases (DatabaseName, DatabaseType, AvailabilityGroup, StartPosition, Selected)
  SELECT DatabaseName,
         DatabaseType,
         AvailabilityGroup,
         StartPosition,
         Selected
  FROM Databases4
  OPTION (MAXRECURSION 0)

  IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN
    INSERT INTO @tmpAvailabilityGroups (AvailabilityGroupName, Selected)
    SELECT name AS AvailabilityGroupName,
           0 AS Selected
    FROM sys.availability_groups

    INSERT INTO @tmpDatabasesAvailabilityGroups (DatabaseName, AvailabilityGroupName)
    SELECT databases.name,
           availability_groups.name
    FROM sys.databases databases
    INNER JOIN sys.availability_replicas availability_replicas ON databases.replica_id = availability_replicas.replica_id
    INNER JOIN sys.availability_groups availability_groups ON availability_replicas.group_id = availability_groups.group_id
  END

  INSERT INTO @tmpDatabases (DatabaseName, DatabaseType, AvailabilityGroup, [Order], Selected, Completed)
  SELECT [name] AS DatabaseName,
         CASE WHEN name IN('master','msdb','model') OR is_distributor = 1 THEN 'S' ELSE 'U' END AS DatabaseType,
         NULL AS AvailabilityGroup,
         0 AS [Order],
         0 AS Selected,
         0 AS Completed
  FROM sys.databases
  WHERE [name] <> 'tempdb'
  AND source_database_id IS NULL
  ORDER BY [name] ASC

  UPDATE tmpDatabases
  SET AvailabilityGroup = CASE WHEN EXISTS (SELECT * FROM @tmpDatabasesAvailabilityGroups WHERE DatabaseName = tmpDatabases.DatabaseName) THEN 1 ELSE 0 END
  FROM @tmpDatabases tmpDatabases

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
  WHERE SelectedDatabases.Selected = 1

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
  WHERE SelectedDatabases.Selected = 0

  UPDATE tmpDatabases
  SET tmpDatabases.StartPosition = SelectedDatabases2.StartPosition
  FROM @tmpDatabases tmpDatabases
  INNER JOIN (SELECT tmpDatabases.DatabaseName, MIN(SelectedDatabases.StartPosition) AS StartPosition
              FROM @tmpDatabases tmpDatabases
              INNER JOIN @SelectedDatabases SelectedDatabases
              ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
              AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
              AND (tmpDatabases.AvailabilityGroup = SelectedDatabases.AvailabilityGroup OR SelectedDatabases.AvailabilityGroup IS NULL)
              WHERE SelectedDatabases.Selected = 1
              GROUP BY tmpDatabases.DatabaseName) SelectedDatabases2
  ON tmpDatabases.DatabaseName = SelectedDatabases2.DatabaseName

  IF @Databases IS NOT NULL AND (NOT EXISTS(SELECT * FROM @SelectedDatabases) OR EXISTS(SELECT * FROM @SelectedDatabases WHERE DatabaseName IS NULL OR DatabaseName = ''))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Databases is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Select availability groups                                                                 //--
  ----------------------------------------------------------------------------------------------------

  IF @AvailabilityGroups IS NOT NULL AND @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
  BEGIN

    SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, CHAR(10), '')
    SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, CHAR(13), '')

    WHILE CHARINDEX(@StringDelimiter + ' ', @AvailabilityGroups) > 0 SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, @StringDelimiter + ' ', @StringDelimiter)
    WHILE CHARINDEX(' ' + @StringDelimiter, @AvailabilityGroups) > 0 SET @AvailabilityGroups = REPLACE(@AvailabilityGroups, ' ' + @StringDelimiter, @StringDelimiter)

    SET @AvailabilityGroups = LTRIM(RTRIM(@AvailabilityGroups));

    WITH AvailabilityGroups1 (StartPosition, EndPosition, AvailabilityGroupItem) AS
    (
    SELECT 1 AS StartPosition,
           ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, 1), 0), LEN(@AvailabilityGroups) + 1) AS EndPosition,
           SUBSTRING(@AvailabilityGroups, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, 1), 0), LEN(@AvailabilityGroups) + 1) - 1) AS AvailabilityGroupItem
    WHERE @AvailabilityGroups IS NOT NULL
    UNION ALL
    SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
           ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, EndPosition + 1), 0), LEN(@AvailabilityGroups) + 1) AS EndPosition,
           SUBSTRING(@AvailabilityGroups, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @AvailabilityGroups, EndPosition + 1), 0), LEN(@AvailabilityGroups) + 1) - EndPosition - 1) AS AvailabilityGroupItem
    FROM AvailabilityGroups1
    WHERE EndPosition < LEN(@AvailabilityGroups) + 1
    ),
    AvailabilityGroups2 (AvailabilityGroupItem, StartPosition, Selected) AS
    (
    SELECT CASE WHEN AvailabilityGroupItem LIKE '-%' THEN RIGHT(AvailabilityGroupItem,LEN(AvailabilityGroupItem) - 1) ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           CASE WHEN AvailabilityGroupItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
    FROM AvailabilityGroups1
    ),
    AvailabilityGroups3 (AvailabilityGroupItem, StartPosition, Selected) AS
    (
    SELECT CASE WHEN AvailabilityGroupItem = 'ALL_AVAILABILITY_GROUPS' THEN '%' ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           Selected
    FROM AvailabilityGroups2
    ),
    AvailabilityGroups4 (AvailabilityGroupName, StartPosition, Selected) AS
    (
    SELECT CASE WHEN LEFT(AvailabilityGroupItem,1) = '[' AND RIGHT(AvailabilityGroupItem,1) = ']' THEN PARSENAME(AvailabilityGroupItem,1) ELSE AvailabilityGroupItem END AS AvailabilityGroupItem,
           StartPosition,
           Selected
    FROM AvailabilityGroups3
    )
    INSERT INTO @SelectedAvailabilityGroups (AvailabilityGroupName, StartPosition, Selected)
    SELECT AvailabilityGroupName, StartPosition, Selected
    FROM AvailabilityGroups4
    OPTION (MAXRECURSION 0)

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.Selected = SelectedAvailabilityGroups.Selected
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
    ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
    WHERE SelectedAvailabilityGroups.Selected = 1

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.Selected = SelectedAvailabilityGroups.Selected
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
    ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
    WHERE SelectedAvailabilityGroups.Selected = 0

    UPDATE tmpAvailabilityGroups
    SET tmpAvailabilityGroups.StartPosition = SelectedAvailabilityGroups2.StartPosition
    FROM @tmpAvailabilityGroups tmpAvailabilityGroups
    INNER JOIN (SELECT tmpAvailabilityGroups.AvailabilityGroupName, MIN(SelectedAvailabilityGroups.StartPosition) AS StartPosition
                FROM @tmpAvailabilityGroups tmpAvailabilityGroups
                INNER JOIN @SelectedAvailabilityGroups SelectedAvailabilityGroups
                ON tmpAvailabilityGroups.AvailabilityGroupName LIKE REPLACE(SelectedAvailabilityGroups.AvailabilityGroupName,'_','[_]')
                WHERE SelectedAvailabilityGroups.Selected = 1
                GROUP BY tmpAvailabilityGroups.AvailabilityGroupName) SelectedAvailabilityGroups2
    ON tmpAvailabilityGroups.AvailabilityGroupName = SelectedAvailabilityGroups2.AvailabilityGroupName

    UPDATE tmpDatabases
    SET tmpDatabases.StartPosition = tmpAvailabilityGroups.StartPosition,
        tmpDatabases.Selected = 1
    FROM @tmpDatabases tmpDatabases
    INNER JOIN @tmpDatabasesAvailabilityGroups tmpDatabasesAvailabilityGroups ON tmpDatabases.DatabaseName = tmpDatabasesAvailabilityGroups.DatabaseName
    INNER JOIN @tmpAvailabilityGroups tmpAvailabilityGroups ON tmpDatabasesAvailabilityGroups.AvailabilityGroupName = tmpAvailabilityGroups.AvailabilityGroupName
    WHERE tmpAvailabilityGroups.Selected = 1

  END

  IF @AvailabilityGroups IS NOT NULL AND (NOT EXISTS(SELECT * FROM @SelectedAvailabilityGroups) OR EXISTS(SELECT * FROM @SelectedAvailabilityGroups WHERE AvailabilityGroupName IS NULL OR AvailabilityGroupName = '') OR @Version < 11 OR SERVERPROPERTY('IsHadrEnabled') = 0)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @AvailabilityGroups is not supported.', 16, 1
  END

  IF (@Databases IS NULL AND @AvailabilityGroups IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You need to specify one of the parameters @Databases and @AvailabilityGroups.', 16, 2
  END

  IF (@Databases IS NOT NULL AND @AvailabilityGroups IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You can only specify one of the parameters @Databases and @AvailabilityGroups.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------
  --// Select indexes                                                                             //--
  ----------------------------------------------------------------------------------------------------

  SET @Indexes = REPLACE(@Indexes, CHAR(10), '')
  SET @Indexes = REPLACE(@Indexes, CHAR(13), '')

  WHILE CHARINDEX(@StringDelimiter + ' ', @Indexes) > 0 SET @Indexes = REPLACE(@Indexes, @StringDelimiter + ' ', @StringDelimiter)
  WHILE CHARINDEX(' ' + @StringDelimiter, @Indexes) > 0 SET @Indexes = REPLACE(@Indexes, ' ' + @StringDelimiter, @StringDelimiter)

  SET @Indexes = LTRIM(RTRIM(@Indexes));

  WITH Indexes1 (StartPosition, EndPosition, IndexItem) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Indexes, 1), 0), LEN(@Indexes) + 1) AS EndPosition,
         SUBSTRING(@Indexes, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Indexes, 1), 0), LEN(@Indexes) + 1) - 1) AS IndexItem
  WHERE @Indexes IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Indexes, EndPosition + 1), 0), LEN(@Indexes) + 1) AS EndPosition,
         SUBSTRING(@Indexes, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @Indexes, EndPosition + 1), 0), LEN(@Indexes) + 1) - EndPosition - 1) AS IndexItem
  FROM Indexes1
  WHERE EndPosition < LEN(@Indexes) + 1
  ),
  Indexes2 (IndexItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN IndexItem LIKE '-%' THEN RIGHT(IndexItem,LEN(IndexItem) - 1) ELSE IndexItem END AS IndexItem,
         StartPosition,
         CASE WHEN IndexItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Indexes1
  ),
  Indexes3 (IndexItem, StartPosition, Selected) AS
  (
  SELECT CASE WHEN IndexItem = 'ALL_INDEXES' THEN '%.%.%.%' ELSE IndexItem END AS IndexItem,
         StartPosition,
         Selected
  FROM Indexes2
  ),
  Indexes4 (DatabaseName, SchemaName, ObjectName, IndexName, StartPosition, Selected) AS
  (
  SELECT CASE WHEN PARSENAME(IndexItem,4) IS NULL THEN PARSENAME(IndexItem,3) ELSE PARSENAME(IndexItem,4) END AS DatabaseName,
         CASE WHEN PARSENAME(IndexItem,4) IS NULL THEN PARSENAME(IndexItem,2) ELSE PARSENAME(IndexItem,3) END AS SchemaName,
         CASE WHEN PARSENAME(IndexItem,4) IS NULL THEN PARSENAME(IndexItem,1) ELSE PARSENAME(IndexItem,2) END AS ObjectName,
         CASE WHEN PARSENAME(IndexItem,4) IS NULL THEN '%' ELSE PARSENAME(IndexItem,1) END AS IndexName,
         StartPosition,
         Selected
  FROM Indexes3
  )
  INSERT INTO @SelectedIndexes (DatabaseName, SchemaName, ObjectName, IndexName, StartPosition, Selected)
  SELECT DatabaseName, SchemaName, ObjectName, IndexName, StartPosition, Selected
  FROM Indexes4
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Select actions                                                                             //--
  ----------------------------------------------------------------------------------------------------

  SET @FragmentationLow = REPLACE(@FragmentationLow, @StringDelimiter + ' ', @StringDelimiter);

  WITH FragmentationLow (StartPosition, EndPosition, [Action]) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationLow, 1), 0), LEN(@FragmentationLow) + 1) AS EndPosition,
         SUBSTRING(@FragmentationLow, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationLow, 1), 0), LEN(@FragmentationLow) + 1) - 1) AS [Action]
  WHERE @FragmentationLow IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationLow, EndPosition + 1), 0), LEN(@FragmentationLow) + 1) AS EndPosition,
         SUBSTRING(@FragmentationLow, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationLow, EndPosition + 1), 0), LEN(@FragmentationLow) + 1) - EndPosition - 1) AS [Action]
  FROM FragmentationLow
  WHERE EndPosition < LEN(@FragmentationLow) + 1
  )
  INSERT INTO @ActionsPreferred(FragmentationGroup, [Priority], [Action])
  SELECT 'Low' AS FragmentationGroup,
         ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS [Priority],
         [Action]
  FROM FragmentationLow
  OPTION (MAXRECURSION 0)

  SET @FragmentationMedium = REPLACE(@FragmentationMedium, @StringDelimiter + ' ', @StringDelimiter);

  WITH FragmentationMedium (StartPosition, EndPosition, [Action]) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationMedium, 1), 0), LEN(@FragmentationMedium) + 1) AS EndPosition,
         SUBSTRING(@FragmentationMedium, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationMedium, 1), 0), LEN(@FragmentationMedium) + 1) - 1) AS [Action]
  WHERE @FragmentationMedium IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationMedium, EndPosition + 1), 0), LEN(@FragmentationMedium) + 1) AS EndPosition,
         SUBSTRING(@FragmentationMedium, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationMedium, EndPosition + 1), 0), LEN(@FragmentationMedium) + 1) - EndPosition - 1) AS [Action]
  FROM FragmentationMedium
  WHERE EndPosition < LEN(@FragmentationMedium) + 1
  )
  INSERT INTO @ActionsPreferred(FragmentationGroup, [Priority], [Action])
  SELECT 'Medium' AS FragmentationGroup,
         ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS [Priority],
         [Action]
  FROM FragmentationMedium
  OPTION (MAXRECURSION 0)

  SET @FragmentationHigh = REPLACE(@FragmentationHigh, @StringDelimiter + ' ', @StringDelimiter);

  WITH FragmentationHigh (StartPosition, EndPosition, [Action]) AS
  (
  SELECT 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationHigh, 1), 0), LEN(@FragmentationHigh) + 1) AS EndPosition,
         SUBSTRING(@FragmentationHigh, 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationHigh, 1), 0), LEN(@FragmentationHigh) + 1) - 1) AS [Action]
  WHERE @FragmentationHigh IS NOT NULL
  UNION ALL
  SELECT CAST(EndPosition AS int) + 1 AS StartPosition,
         ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationHigh, EndPosition + 1), 0), LEN(@FragmentationHigh) + 1) AS EndPosition,
         SUBSTRING(@FragmentationHigh, EndPosition + 1, ISNULL(NULLIF(CHARINDEX(@StringDelimiter, @FragmentationHigh, EndPosition + 1), 0), LEN(@FragmentationHigh) + 1) - EndPosition - 1) AS [Action]
  FROM FragmentationHigh
  WHERE EndPosition < LEN(@FragmentationHigh) + 1
  )
  INSERT INTO @ActionsPreferred(FragmentationGroup, [Priority], [Action])
  SELECT 'High' AS FragmentationGroup,
         ROW_NUMBER() OVER(ORDER BY StartPosition ASC) AS [Priority],
         [Action]
  FROM FragmentationHigh
  OPTION (MAXRECURSION 0)

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT [Action] FROM @ActionsPreferred WHERE FragmentationGroup = 'Low' AND [Action] NOT IN(SELECT * FROM @Actions))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationLow is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @ActionsPreferred WHERE FragmentationGroup = 'Low' GROUP BY [Action] HAVING COUNT(*) > 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationLow is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT [Action] FROM @ActionsPreferred WHERE FragmentationGroup = 'Medium' AND [Action] NOT IN(SELECT * FROM @Actions))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationMedium is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @ActionsPreferred WHERE FragmentationGroup = 'Medium' GROUP BY [Action] HAVING COUNT(*) > 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationMedium is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT [Action] FROM @ActionsPreferred WHERE FragmentationGroup = 'High' AND [Action] NOT IN(SELECT * FROM @Actions))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationHigh is not supported.', 16, 1
  END

  IF EXISTS (SELECT * FROM @ActionsPreferred WHERE FragmentationGroup = 'High' GROUP BY [Action] HAVING COUNT(*) > 1)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationHigh is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @FragmentationLevel1 <= 0 OR @FragmentationLevel1 >= 100 OR @FragmentationLevel1 IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationLevel1 is not supported.', 16, 1
  END

  IF @FragmentationLevel1 >= @FragmentationLevel2
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationLevel1 is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @FragmentationLevel2 <= 0 OR @FragmentationLevel2 >= 100 OR @FragmentationLevel2 IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationLevel2 is not supported.', 16, 1
  END

  IF @FragmentationLevel2 <= @FragmentationLevel1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FragmentationLevel2 is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @MinNumberOfPages < 0 OR @MinNumberOfPages IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MinNumberOfPages is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @MaxNumberOfPages < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxNumberOfPages is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @SortInTempdb NOT IN('Y','N') OR @SortInTempdb IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @SortInTempdb is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @MaxDOP < 0 OR @MaxDOP > 64
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MaxDOP is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @FillFactor <= 0 OR @FillFactor > 100
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @FillFactor is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @PadIndex NOT IN('Y','N')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @PadIndex is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @LOBCompaction NOT IN('Y','N') OR @LOBCompaction IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LOBCompaction is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @UpdateStatistics NOT IN('ALL','COLUMNS','INDEX')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @UpdateStatistics is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @OnlyModifiedStatistics NOT IN('Y','N') OR @OnlyModifiedStatistics IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @OnlyModifiedStatistics is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @StatisticsModificationLevel <= 0 OR @StatisticsModificationLevel > 100
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StatisticsModificationLevel is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @OnlyModifiedStatistics = 'Y' AND @StatisticsModificationLevel IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You can only specify one of the parameters @OnlyModifiedStatistics and @StatisticsModificationLevel.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @StatisticsSample <= 0 OR @StatisticsSample  > 100
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StatisticsSample is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @StatisticsResample NOT IN('Y','N') OR @StatisticsResample IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StatisticsResample is not supported.', 16, 1
  END

  IF @StatisticsResample = 'Y' AND @StatisticsSample IS NOT NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StatisticsResample is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @PartitionLevel NOT IN('Y','N') OR @PartitionLevel IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @PartitionLevel is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @MSShippedObjects NOT IN('Y','N') OR @MSShippedObjects IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @MSShippedObjects is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @SelectedIndexes WHERE DatabaseName IS NULL OR SchemaName IS NULL OR ObjectName IS NULL OR IndexName IS NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Indexes is not supported.', 16, 1
  END

  IF @Indexes IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedIndexes)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Indexes is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @TimeLimit < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @TimeLimit is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Delay < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Delay is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @WaitAtLowPriorityMaxDuration < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @WaitAtLowPriorityMaxDuration is not supported.', 16, 1
  END

  IF @WaitAtLowPriorityMaxDuration IS NOT NULL AND @Version < 12
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @WaitAtLowPriorityMaxDuration is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @WaitAtLowPriorityAbortAfterWait NOT IN('NONE','SELF','BLOCKERS')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @WaitAtLowPriorityAbortAfterWait is not supported.', 16, 1
  END

  IF @WaitAtLowPriorityAbortAfterWait IS NOT NULL AND @Version < 12
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @WaitAtLowPriorityAbortAfterWait is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF (@WaitAtLowPriorityAbortAfterWait IS NOT NULL AND @WaitAtLowPriorityMaxDuration IS NULL) OR (@WaitAtLowPriorityAbortAfterWait IS NULL AND @WaitAtLowPriorityMaxDuration IS NOT NULL)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The parameters @WaitAtLowPriorityMaxDuration and @WaitAtLowPriorityAbortAfterWait can only be used together.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Resumable NOT IN('Y','N') OR @Resumable IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Resumable is not supported.', 16, 1
  END

  IF @Resumable = 'Y' AND NOT (@Version >= 14 OR SERVERPROPERTY('EngineEdition') IN (5, 8))
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Resumable is not supported.', 16, 2
  END

  IF @Resumable = 'Y' AND @SortInTempdb = 'Y'
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'You can only specify one of the parameters @Resumable and @SortInTempdb.', 16, 3
  END

  ----------------------------------------------------------------------------------------------------

  IF @LockTimeout < 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LockTimeout is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @LockMessageSeverity NOT IN(10, 16)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LockMessageSeverity is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @StringDelimiter IS NULL OR LEN(@StringDelimiter) > 1
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @StringDelimiter is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @DatabaseOrder NOT IN('DATABASE_NAME_ASC','DATABASE_NAME_DESC','DATABASE_SIZE_ASC','DATABASE_SIZE_DESC')
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported.', 16, 1
  END

  IF @DatabaseOrder IS NOT NULL AND SERVERPROPERTY('EngineEdition') = 5
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabaseOrder is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF @DatabasesInParallel NOT IN('Y','N') OR @DatabasesInParallel IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabasesInParallel is not supported.', 16, 1
  END

  IF @DatabasesInParallel = 'Y' AND SERVERPROPERTY('EngineEdition') = 5
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @DatabasesInParallel is not supported.', 16, 2
  END

  ----------------------------------------------------------------------------------------------------

  IF LEN(@ExecuteAsUser) > 128
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @ExecuteAsUser is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @LogToTable is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The value for the parameter @Execute is not supported.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @Errors)
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The documentation is available at https://ola.hallengren.com/sql-server-index-and-statistics-maintenance.html.', 16, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Check that selected databases and availability groups exist                                //--
  ----------------------------------------------------------------------------------------------------

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedDatabases
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases in the @Databases parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedIndexes
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases in the @Indexes parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(AvailabilityGroupName) + ', '
  FROM @SelectedAvailabilityGroups
  WHERE AvailabilityGroupName NOT LIKE '%[%]%'
  AND AvailabilityGroupName NOT IN (SELECT AvailabilityGroupName FROM @tmpAvailabilityGroups)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following availability groups do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @SelectedIndexes
  WHERE DatabaseName NOT LIKE '%[%]%'
  AND DatabaseName IN (SELECT DatabaseName FROM @tmpDatabases)
  AND DatabaseName NOT IN (SELECT DatabaseName FROM @tmpDatabases WHERE Selected = 1)
  IF @@ROWCOUNT > 0
  BEGIN
    INSERT INTO @Errors ([Message], Severity, [State])
    SELECT 'The following databases have been selected in the @Indexes parameter, but not in the @Databases or @AvailabilityGroups parameters: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.', 10, 1
  END

  ----------------------------------------------------------------------------------------------------
  --// Raise errors                                                                               //--
  ----------------------------------------------------------------------------------------------------

  DECLARE ErrorCursor CURSOR FAST_FORWARD FOR SELECT [Message], Severity, [State] FROM @Errors ORDER BY [ID] ASC

  OPEN ErrorCursor

  FETCH ErrorCursor INTO @CurrentMessage, @CurrentSeverity, @CurrentState

  WHILE @@FETCH_STATUS = 0
  BEGIN
    RAISERROR('%s', @CurrentSeverity, @CurrentState, @CurrentMessage) WITH NOWAIT
    RAISERROR(@EmptyLine, 10, 1) WITH NOWAIT

    FETCH NEXT FROM ErrorCursor INTO @CurrentMessage, @CurrentSeverity, @CurrentState
  END

  CLOSE ErrorCursor

  DEALLOCATE ErrorCursor

  IF EXISTS (SELECT * FROM @Errors WHERE Severity >= 16)
  BEGIN
    SET @ReturnCode = 50000
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Should statistics be updated on the partition level?                                       //--
  ----------------------------------------------------------------------------------------------------

  SET @PartitionLevelStatistics = CASE WHEN @PartitionLevel = 'Y' AND ((@Version >= 12.05 AND @Version < 13) OR @Version >= 13.04422 OR SERVERPROPERTY('EngineEdition') IN (5,8)) THEN 1 ELSE 0 END

  ----------------------------------------------------------------------------------------------------
  --// Update database order                                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @DatabaseOrder IN('DATABASE_SIZE_ASC','DATABASE_SIZE_DESC')
  BEGIN
    UPDATE tmpDatabases
    SET DatabaseSize = (SELECT SUM(CAST(size AS bigint)) FROM sys.master_files WHERE [type] = 0 AND database_id = DB_ID(tmpDatabases.DatabaseName))
    FROM @tmpDatabases tmpDatabases
  END

  IF @DatabaseOrder IS NULL
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY StartPosition ASC, DatabaseName ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_NAME_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseName ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_NAME_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseName DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_SIZE_ASC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseSize ASC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END
  ELSE
  IF @DatabaseOrder = 'DATABASE_SIZE_DESC'
  BEGIN
    WITH tmpDatabases AS (
    SELECT DatabaseName, [Order], ROW_NUMBER() OVER (ORDER BY DatabaseSize DESC) AS RowNumber
    FROM @tmpDatabases tmpDatabases
    WHERE Selected = 1
    )
    UPDATE tmpDatabases
    SET [Order] = RowNumber
  END

  ----------------------------------------------------------------------------------------------------
  --// Update the queue                                                                           //--
  ----------------------------------------------------------------------------------------------------

  IF @DatabasesInParallel = 'Y'
  BEGIN

    BEGIN TRY

      SELECT @QueueID = QueueID
      FROM dbo.[Queue]
      WHERE SchemaName = @SchemaName
      AND ObjectName = @ObjectName
      AND [Parameters] = @Parameters

      IF @QueueID IS NULL
      BEGIN
        BEGIN TRANSACTION

        SELECT @QueueID = QueueID
        FROM dbo.[Queue] WITH (UPDLOCK, HOLDLOCK)
        WHERE SchemaName = @SchemaName
        AND ObjectName = @ObjectName
        AND [Parameters] = @Parameters

        IF @QueueID IS NULL
        BEGIN
          INSERT INTO dbo.[Queue] (SchemaName, ObjectName, [Parameters])
          SELECT @SchemaName, @ObjectName, @Parameters

          SET @QueueID = SCOPE_IDENTITY()
        END

        COMMIT TRANSACTION
      END

      BEGIN TRANSACTION

      UPDATE [Queue]
      SET QueueStartTime = SYSDATETIME(),
          SessionID = @@SPID,
          RequestID = (SELECT request_id FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          RequestStartTime = (SELECT start_time FROM sys.dm_exec_requests WHERE session_id = @@SPID)
      FROM dbo.[Queue] [Queue]
      WHERE QueueID = @QueueID
      AND NOT EXISTS (SELECT *
                      FROM sys.dm_exec_requests
                      WHERE session_id = [Queue].SessionID
                      AND request_id = [Queue].RequestID
                      AND start_time = [Queue].RequestStartTime)
      AND NOT EXISTS (SELECT *
                      FROM dbo.QueueDatabase QueueDatabase
                      INNER JOIN sys.dm_exec_requests ON QueueDatabase.SessionID = session_id AND QueueDatabase.RequestID = request_id AND QueueDatabase.RequestStartTime = start_time
                      WHERE QueueDatabase.QueueID = @QueueID)

      IF @@ROWCOUNT = 1
      BEGIN
        INSERT INTO dbo.QueueDatabase (QueueID, DatabaseName)
        SELECT @QueueID AS QueueID,
               DatabaseName
        FROM @tmpDatabases tmpDatabases
        WHERE Selected = 1
        AND NOT EXISTS (SELECT * FROM dbo.QueueDatabase WHERE DatabaseName = tmpDatabases.DatabaseName AND QueueID = @QueueID)

        DELETE QueueDatabase
        FROM dbo.QueueDatabase QueueDatabase
        WHERE QueueID = @QueueID
        AND NOT EXISTS (SELECT * FROM @tmpDatabases tmpDatabases WHERE DatabaseName = QueueDatabase.DatabaseName AND Selected = 1)

        UPDATE QueueDatabase
        SET DatabaseOrder = tmpDatabases.[Order]
        FROM dbo.QueueDatabase QueueDatabase
        INNER JOIN @tmpDatabases tmpDatabases ON QueueDatabase.DatabaseName = tmpDatabases.DatabaseName
        WHERE QueueID = @QueueID
      END

      COMMIT TRANSACTION

      SELECT @QueueStartTime = QueueStartTime
      FROM dbo.[Queue]
      WHERE QueueID = @QueueID

    END TRY

    BEGIN CATCH
      IF XACT_STATE() <> 0
      BEGIN
        ROLLBACK TRANSACTION
      END
      SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'')
      RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
      SET @ReturnCode = ERROR_NUMBER()
      GOTO Logging
    END CATCH

  END

  ----------------------------------------------------------------------------------------------------
  --// Execute commands                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WHILE (1 = 1)
  BEGIN

    IF @DatabasesInParallel = 'Y'
    BEGIN
      UPDATE QueueDatabase
      SET DatabaseStartTime = NULL,
          SessionID = NULL,
          RequestID = NULL,
          RequestStartTime = NULL
      FROM dbo.QueueDatabase QueueDatabase
      WHERE QueueID = @QueueID
      AND DatabaseStartTime IS NOT NULL
      AND DatabaseEndTime IS NULL
      AND NOT EXISTS (SELECT * FROM sys.dm_exec_requests WHERE session_id = QueueDatabase.SessionID AND request_id = QueueDatabase.RequestID AND start_time = QueueDatabase.RequestStartTime)

      UPDATE QueueDatabase
      SET DatabaseStartTime = SYSDATETIME(),
          DatabaseEndTime = NULL,
          SessionID = @@SPID,
          RequestID = (SELECT request_id FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          RequestStartTime = (SELECT start_time FROM sys.dm_exec_requests WHERE session_id = @@SPID),
          @CurrentDatabaseName = DatabaseName
      FROM (SELECT TOP 1 DatabaseStartTime,
                         DatabaseEndTime,
                         SessionID,
                         RequestID,
                         RequestStartTime,
                         DatabaseName
            FROM dbo.QueueDatabase
            WHERE QueueID = @QueueID
            AND (DatabaseStartTime < @QueueStartTime OR DatabaseStartTime IS NULL)
            AND NOT (DatabaseStartTime IS NOT NULL AND DatabaseEndTime IS NULL)
            ORDER BY DatabaseOrder ASC
            ) QueueDatabase
    END
    ELSE
    BEGIN
      SELECT TOP 1 @CurrentDBID = ID,
                   @CurrentDatabaseName = DatabaseName
      FROM @tmpDatabases
      WHERE Selected = 1
      AND Completed = 0
      ORDER BY [Order] ASC
    END

    IF @@ROWCOUNT = 0
    BEGIN
      BREAK
    END

    SET @CurrentDatabase_sp_executesql = QUOTENAME(@CurrentDatabaseName) + '.sys.sp_executesql'

    IF @ExecuteAsUser IS NOT NULL
    BEGIN
      SET @CurrentCommand = ''
      SET @CurrentCommand += 'IF EXISTS(SELECT * FROM sys.database_principals database_principals WHERE database_principals.[name] = @ParamExecuteAsUser) BEGIN SET @ParamExecuteAsUserExists = 1 END ELSE BEGIN SET @ParamExecuteAsUserExists = 0 END'

      EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamExecuteAsUser sysname, @ParamExecuteAsUserExists bit OUTPUT', @ParamExecuteAsUser = @ExecuteAsUser, @ParamExecuteAsUserExists = @CurrentExecuteAsUserExists OUTPUT
    END

    BEGIN
      SET @DatabaseMessage = 'Date and time: ' + CONVERT(nvarchar,SYSDATETIME(),120)
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Database: ' + QUOTENAME(@CurrentDatabaseName)
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    SELECT @CurrentUserAccess = user_access_desc,
           @CurrentIsReadOnly = is_read_only,
           @CurrentDatabaseState = state_desc,
           @CurrentInStandby = is_in_standby,
           @CurrentRecoveryModel = recovery_model_desc
    FROM sys.databases
    WHERE [name] = @CurrentDatabaseName

    BEGIN
      SET @DatabaseMessage = 'State: ' + @CurrentDatabaseState
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Standby: ' + CASE WHEN @CurrentInStandby = 1 THEN 'Yes' ELSE 'No' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Updateability: ' + CASE WHEN @CurrentIsReadOnly = 1 THEN 'READ_ONLY' WHEN  @CurrentIsReadOnly = 0 THEN 'READ_WRITE' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'User access: ' + @CurrentUserAccess
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Recovery model: ' + @CurrentRecoveryModel
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentDatabaseState = 'ONLINE' AND SERVERPROPERTY('EngineEdition') <> 5
    BEGIN
      IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = DB_ID(@CurrentDatabaseName) AND database_guid IS NOT NULL)
      BEGIN
        SET @CurrentIsDatabaseAccessible = 1
      END
      ELSE
      BEGIN
        SET @CurrentIsDatabaseAccessible = 0
      END
    END

    IF @Version >= 11 AND SERVERPROPERTY('IsHadrEnabled') = 1
    BEGIN
      SELECT @CurrentReplicaID = databases.replica_id
      FROM sys.databases databases
      INNER JOIN sys.availability_replicas availability_replicas ON databases.replica_id = availability_replicas.replica_id
      WHERE databases.[name] = @CurrentDatabaseName

      SELECT @CurrentAvailabilityGroupID = group_id
      FROM sys.availability_replicas
      WHERE replica_id = @CurrentReplicaID

      SELECT @CurrentAvailabilityGroupRole = role_desc
      FROM sys.dm_hadr_availability_replica_states
      WHERE replica_id = @CurrentReplicaID

      SELECT @CurrentAvailabilityGroup = [name]
      FROM sys.availability_groups
      WHERE group_id = @CurrentAvailabilityGroupID
    END

    IF SERVERPROPERTY('EngineEdition') <> 5
    BEGIN
      SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
      FROM sys.database_mirroring
      WHERE database_id = DB_ID(@CurrentDatabaseName)
    END

    IF @CurrentIsDatabaseAccessible IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentAvailabilityGroup IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Availability group: ' + ISNULL(@CurrentAvailabilityGroup,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT

      SET @DatabaseMessage = 'Availability group role: ' + ISNULL(@CurrentAvailabilityGroupRole,'N/A')
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    IF @CurrentDatabaseMirroringRole IS NOT NULL
    BEGIN
      SET @DatabaseMessage = 'Database mirroring role: ' + @CurrentDatabaseMirroringRole
      RAISERROR('%s',10,1,@DatabaseMessage) WITH NOWAIT
    END

    RAISERROR(@EmptyLine,10,1) WITH NOWAIT

    IF @CurrentExecuteAsUserExists = 0
    BEGIN
      SET @DatabaseMessage = 'The user ' + QUOTENAME(@ExecuteAsUser) + ' does not exist in the database ' + QUOTENAME(@CurrentDatabaseName) + '.'
      RAISERROR('%s',16,1,@DatabaseMessage) WITH NOWAIT
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
    END

    IF @CurrentDatabaseState = 'ONLINE'
    AND NOT (@CurrentUserAccess = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)
    AND DATABASEPROPERTYEX(@CurrentDatabaseName,'Updateability') = 'READ_WRITE'
    AND (@CurrentExecuteAsUserExists = 1 OR @CurrentExecuteAsUserExists IS NULL)
    BEGIN

      -- Select indexes in the current database
      IF (EXISTS(SELECT * FROM @ActionsPreferred) OR @UpdateStatistics IS NOT NULL) AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SET @CurrentCommand = 'SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;'
                              + ' SELECT SchemaID, SchemaName, ObjectID, ObjectName, ObjectType, IsMemoryOptimized, IndexID, IndexName, IndexType, AllowPageLocks, IsImageText, IsNewLOB, IsFileStream, IsColumnStore, IsComputed, IsTimestamp, OnReadOnlyFileGroup, ResumableIndexOperation, StatisticsID, StatisticsName, NoRecompute, IsIncremental, PartitionID, PartitionNumber, PartitionCount, [Order], Selected, Completed'
                              + ' FROM ('

        IF EXISTS(SELECT * FROM @ActionsPreferred) OR @UpdateStatistics IN('ALL','INDEX')
        BEGIN
          SET @CurrentCommand = @CurrentCommand + 'SELECT schemas.[schema_id] AS SchemaID'
                                                    + ', schemas.[name] AS SchemaName'
                                                    + ', objects.[object_id] AS ObjectID'
                                                    + ', objects.[name] AS ObjectName'
                                                    + ', RTRIM(objects.[type]) AS ObjectType'
                                                    + ', ' + CASE WHEN @Version >= 12 THEN 'tables.is_memory_optimized' ELSE '0' END + ' AS IsMemoryOptimized'
                                                    + ', indexes.index_id AS IndexID'
                                                    + ', indexes.[name] AS IndexName'
                                                    + ', indexes.[type] AS IndexType'
                                                    + ', indexes.allow_page_locks AS AllowPageLocks'

                                                    + ', CASE WHEN indexes.[type] = 1 AND EXISTS(SELECT * FROM sys.columns columns INNER JOIN sys.types types ON columns.system_type_id = types.user_type_id WHERE columns.[object_id] = objects.object_id AND types.name IN(''image'',''text'',''ntext'')) THEN 1 ELSE 0 END AS IsImageText'

                                                    + ', CASE WHEN indexes.[type] = 1 AND EXISTS(SELECT * FROM sys.columns columns INNER JOIN sys.types types ON columns.system_type_id = types.user_type_id OR (columns.user_type_id = types.user_type_id AND types.is_assembly_type = 1) WHERE columns.[object_id] = objects.object_id AND (types.name IN(''xml'') OR (types.name IN(''varchar'',''nvarchar'',''varbinary'') AND columns.max_length = -1) OR (types.is_assembly_type = 1 AND columns.max_length = -1))) THEN 1'
                                                    + ' WHEN indexes.[type] = 2 AND EXISTS(SELECT * FROM sys.index_columns index_columns INNER JOIN sys.columns columns ON index_columns.[object_id] = columns.[object_id] AND index_columns.column_id = columns.column_id INNER JOIN sys.types types ON columns.system_type_id = types.user_type_id OR (columns.user_type_id = types.user_type_id AND types.is_assembly_type = 1) WHERE index_columns.[object_id] = objects.object_id AND index_columns.index_id = indexes.index_id AND (types.[name] IN(''xml'') OR (types.[name] IN(''varchar'',''nvarchar'',''varbinary'') AND columns.max_length = -1) OR (types.is_assembly_type = 1 AND columns.max_length = -1))) THEN 1 ELSE 0 END AS IsNewLOB'

                                                    + ', CASE WHEN indexes.[type] = 1 AND EXISTS(SELECT * FROM sys.columns columns WHERE columns.[object_id] = objects.object_id  AND columns.is_filestream = 1) THEN 1 ELSE 0 END AS IsFileStream'

                                                    + ', CASE WHEN EXISTS(SELECT * FROM sys.indexes indexes WHERE indexes.[object_id] = objects.object_id AND [type] IN(5,6)) THEN 1 ELSE 0 END AS IsColumnStore'

                                                    + ', CASE WHEN EXISTS(SELECT * FROM sys.index_columns index_columns INNER JOIN sys.columns columns ON index_columns.object_id = columns.object_id AND index_columns.column_id = columns.column_id WHERE (index_columns.key_ordinal > 0 OR index_columns.partition_ordinal > 0) AND columns.is_computed = 1 AND index_columns.object_id = indexes.object_id AND index_columns.index_id = indexes.index_id) THEN 1 ELSE 0 END AS IsComputed'

                                                    + ', CASE WHEN EXISTS(SELECT * FROM sys.index_columns index_columns INNER JOIN sys.columns columns ON index_columns.[object_id] = columns.[object_id] AND index_columns.column_id = columns.column_id INNER JOIN sys.types types ON columns.system_type_id = types.system_type_id WHERE index_columns.[object_id] = objects.object_id AND index_columns.index_id = indexes.index_id AND types.[name] = ''timestamp'') THEN 1 ELSE 0 END AS IsTimestamp'

                                                    + ', CASE WHEN EXISTS (SELECT * FROM sys.indexes indexes2 INNER JOIN sys.destination_data_spaces destination_data_spaces ON indexes.data_space_id = destination_data_spaces.partition_scheme_id INNER JOIN sys.filegroups filegroups ON destination_data_spaces.data_space_id = filegroups.data_space_id WHERE filegroups.is_read_only = 1 AND indexes2.[object_id] = indexes.[object_id] AND indexes2.[index_id] = indexes.index_id' + CASE WHEN @PartitionLevel = 'Y' THEN ' AND destination_data_spaces.destination_id = partitions.partition_number' ELSE '' END + ') THEN 1'
                                                    + ' WHEN EXISTS (SELECT * FROM sys.indexes indexes2 INNER JOIN sys.filegroups filegroups ON indexes.data_space_id = filegroups.data_space_id WHERE filegroups.is_read_only = 1 AND indexes.[object_id] = indexes2.[object_id] AND indexes.[index_id] = indexes2.index_id) THEN 1'
                                                    + ' WHEN indexes.[type] = 1 AND EXISTS (SELECT * FROM sys.tables tables INNER JOIN sys.filegroups filegroups ON tables.lob_data_space_id = filegroups.data_space_id WHERE filegroups.is_read_only = 1 AND tables.[object_id] = objects.[object_id]) THEN 1 ELSE 0 END AS OnReadOnlyFileGroup'

                                                    + ', ' + CASE WHEN @Version >= 14 THEN 'CASE WHEN EXISTS(SELECT * FROM sys.index_resumable_operations index_resumable_operations WHERE state_desc = ''PAUSED'' AND index_resumable_operations.object_id = indexes.object_id AND index_resumable_operations.index_id = indexes.index_id AND (index_resumable_operations.partition_number = partitions.partition_number OR index_resumable_operations.partition_number IS NULL)) THEN 1 ELSE 0 END' ELSE '0' END + ' AS ResumableIndexOperation'

                                                    + ', stats.stats_id AS StatisticsID'
                                                    + ', stats.name AS StatisticsName'
                                                    + ', stats.no_recompute AS NoRecompute'
                                                    + ', ' + CASE WHEN @Version >= 12 THEN 'stats.is_incremental' ELSE '0' END + ' AS IsIncremental'
                                                    + ', ' + CASE WHEN @PartitionLevel = 'Y' THEN 'partitions.partition_id AS PartitionID' WHEN @PartitionLevel = 'N' THEN 'NULL AS PartitionID' END
                                                    + ', ' + CASE WHEN @PartitionLevel = 'Y' THEN 'partitions.partition_number AS PartitionNumber' WHEN @PartitionLevel = 'N' THEN 'NULL AS PartitionNumber' END
                                                    + ', ' + CASE WHEN @PartitionLevel = 'Y' THEN 'IndexPartitions.partition_count AS PartitionCount' WHEN @PartitionLevel = 'N' THEN 'NULL AS PartitionCount' END
                                                    + ', 0 AS [Order]'
                                                    + ', 0 AS Selected'
                                                    + ', 0 AS Completed'
                                                    + ' FROM sys.indexes indexes'
                                                    + ' INNER JOIN sys.objects objects ON indexes.[object_id] = objects.[object_id]'
                                                    + ' INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id]'
                                                    + ' LEFT OUTER JOIN sys.tables tables ON objects.[object_id] = tables.[object_id]'
                                                    + ' LEFT OUTER JOIN sys.stats stats ON indexes.[object_id] = stats.[object_id] AND indexes.[index_id] = stats.[stats_id]'
          IF @PartitionLevel = 'Y'
          BEGIN
            SET @CurrentCommand = @CurrentCommand + ' LEFT OUTER JOIN sys.partitions partitions ON indexes.[object_id] = partitions.[object_id] AND indexes.index_id = partitions.index_id'
                                                      + ' LEFT OUTER JOIN (SELECT partitions.[object_id], partitions.index_id, COUNT(DISTINCT partitions.partition_number) AS partition_count FROM sys.partitions partitions GROUP BY partitions.[object_id], partitions.index_id) IndexPartitions ON partitions.[object_id] = IndexPartitions.[object_id] AND partitions.[index_id] = IndexPartitions.[index_id]'
          END

          SET @CurrentCommand = @CurrentCommand + ' WHERE objects.[type] IN(''U'',''V'')'
                                                    + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END
                                                    + ' AND indexes.[type] IN(1,2,3,4,5,6,7)'
                                                    + ' AND indexes.is_disabled = 0 AND indexes.is_hypothetical = 0'
        END

        IF (EXISTS(SELECT * FROM @ActionsPreferred) AND @UpdateStatistics = 'COLUMNS') OR @UpdateStatistics = 'ALL'
        BEGIN
          SET @CurrentCommand = @CurrentCommand + ' UNION '
        END

        IF @UpdateStatistics IN('ALL','COLUMNS')
        BEGIN
          SET @CurrentCommand = @CurrentCommand + 'SELECT schemas.[schema_id] AS SchemaID'
                                                    + ', schemas.[name] AS SchemaName'
                                                    + ', objects.[object_id] AS ObjectID'
                                                    + ', objects.[name] AS ObjectName'
                                                    + ', RTRIM(objects.[type]) AS ObjectType'
                                                    + ', ' + CASE WHEN @Version >= 12 THEN 'tables.is_memory_optimized' ELSE '0' END + ' AS IsMemoryOptimized'
                                                    + ', NULL AS IndexID, NULL AS IndexName'
                                                    + ', NULL AS IndexType'
                                                    + ', NULL AS AllowPageLocks'
                                                    + ', NULL AS IsImageText'
                                                    + ', NULL AS IsNewLOB'
                                                    + ', NULL AS IsFileStream'
                                                    + ', NULL AS IsColumnStore'
                                                    + ', NULL AS IsComputed'
                                                    + ', NULL AS IsTimestamp'
                                                    + ', NULL AS OnReadOnlyFileGroup'
                                                    + ', NULL AS ResumableIndexOperation'
                                                    + ', stats.stats_id AS StatisticsID'
                                                    + ', stats.name AS StatisticsName'
                                                    + ', stats.no_recompute AS NoRecompute'
                                                    + ', ' + CASE WHEN @Version >= 12 THEN 'stats.is_incremental' ELSE '0' END + ' AS IsIncremental'
                                                    + ', NULL AS PartitionID'
                                                    + ', ' + CASE WHEN @PartitionLevelStatistics = 1 THEN 'dm_db_incremental_stats_properties.partition_number' ELSE 'NULL' END + ' AS PartitionNumber'
                                                    + ', NULL AS PartitionCount'
                                                    + ', 0 AS [Order]'
                                                    + ', 0 AS Selected'
                                                    + ', 0 AS Completed'
                                                    + ' FROM sys.stats stats'
                                                    + ' INNER JOIN sys.objects objects ON stats.[object_id] = objects.[object_id]'
                                                    + ' INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id]'
                                                    + ' LEFT OUTER JOIN sys.tables tables ON objects.[object_id] = tables.[object_id]'

          IF @PartitionLevelStatistics = 1
          BEGIN
            SET @CurrentCommand = @CurrentCommand + ' OUTER APPLY sys.dm_db_incremental_stats_properties(stats.object_id, stats.stats_id) dm_db_incremental_stats_properties'
          END

          SET @CurrentCommand = @CurrentCommand + ' WHERE objects.[type] IN(''U'',''V'')'
                                                    + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END
                                                    + ' AND NOT EXISTS(SELECT * FROM sys.indexes indexes WHERE indexes.[object_id] = stats.[object_id] AND indexes.index_id = stats.stats_id)'
        END

        SET @CurrentCommand = @CurrentCommand + ') IndexesStatistics'

        INSERT INTO @tmpIndexesStatistics (SchemaID, SchemaName, ObjectID, ObjectName, ObjectType, IsMemoryOptimized, IndexID, IndexName, IndexType, AllowPageLocks, IsImageText, IsNewLOB, IsFileStream, IsColumnStore, IsComputed, IsTimestamp, OnReadOnlyFileGroup, ResumableIndexOperation, StatisticsID, StatisticsName, [NoRecompute], IsIncremental, PartitionID, PartitionNumber, PartitionCount, [Order], Selected, Completed)
        EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand
        SET @Error = @@ERROR
        IF @Error <> 0
        BEGIN
          SET @ReturnCode = @Error
        END
      END

      IF @Indexes IS NULL
      BEGIN
        UPDATE tmpIndexesStatistics
        SET tmpIndexesStatistics.Selected = 1
        FROM @tmpIndexesStatistics tmpIndexesStatistics
      END
      ELSE
      BEGIN
        UPDATE tmpIndexesStatistics
        SET tmpIndexesStatistics.Selected = SelectedIndexes.Selected
        FROM @tmpIndexesStatistics tmpIndexesStatistics
        INNER JOIN @SelectedIndexes SelectedIndexes
        ON @CurrentDatabaseName LIKE REPLACE(SelectedIndexes.DatabaseName,'_','[_]') AND tmpIndexesStatistics.SchemaName LIKE REPLACE(SelectedIndexes.SchemaName,'_','[_]') AND tmpIndexesStatistics.ObjectName LIKE REPLACE(SelectedIndexes.ObjectName,'_','[_]') AND COALESCE(tmpIndexesStatistics.IndexName,tmpIndexesStatistics.StatisticsName) LIKE REPLACE(SelectedIndexes.IndexName,'_','[_]')
        WHERE SelectedIndexes.Selected = 1

        UPDATE tmpIndexesStatistics
        SET tmpIndexesStatistics.Selected = SelectedIndexes.Selected
        FROM @tmpIndexesStatistics tmpIndexesStatistics
        INNER JOIN @SelectedIndexes SelectedIndexes
        ON @CurrentDatabaseName LIKE REPLACE(SelectedIndexes.DatabaseName,'_','[_]') AND tmpIndexesStatistics.SchemaName LIKE REPLACE(SelectedIndexes.SchemaName,'_','[_]') AND tmpIndexesStatistics.ObjectName LIKE REPLACE(SelectedIndexes.ObjectName,'_','[_]') AND COALESCE(tmpIndexesStatistics.IndexName,tmpIndexesStatistics.StatisticsName) LIKE REPLACE(SelectedIndexes.IndexName,'_','[_]')
        WHERE SelectedIndexes.Selected = 0

        UPDATE tmpIndexesStatistics
        SET tmpIndexesStatistics.StartPosition = SelectedIndexes2.StartPosition
        FROM @tmpIndexesStatistics tmpIndexesStatistics
        INNER JOIN (SELECT tmpIndexesStatistics.SchemaName, tmpIndexesStatistics.ObjectName, tmpIndexesStatistics.IndexName, tmpIndexesStatistics.StatisticsName, MIN(SelectedIndexes.StartPosition) AS StartPosition
                    FROM @tmpIndexesStatistics tmpIndexesStatistics
                    INNER JOIN @SelectedIndexes SelectedIndexes
                    ON @CurrentDatabaseName LIKE REPLACE(SelectedIndexes.DatabaseName,'_','[_]') AND tmpIndexesStatistics.SchemaName LIKE REPLACE(SelectedIndexes.SchemaName,'_','[_]') AND tmpIndexesStatistics.ObjectName LIKE REPLACE(SelectedIndexes.ObjectName,'_','[_]') AND COALESCE(tmpIndexesStatistics.IndexName,tmpIndexesStatistics.StatisticsName) LIKE REPLACE(SelectedIndexes.IndexName,'_','[_]')
                    WHERE SelectedIndexes.Selected = 1
                    GROUP BY tmpIndexesStatistics.SchemaName, tmpIndexesStatistics.ObjectName, tmpIndexesStatistics.IndexName, tmpIndexesStatistics.StatisticsName) SelectedIndexes2
        ON tmpIndexesStatistics.SchemaName = SelectedIndexes2.SchemaName
        AND tmpIndexesStatistics.ObjectName = SelectedIndexes2.ObjectName
        AND (tmpIndexesStatistics.IndexName = SelectedIndexes2.IndexName OR tmpIndexesStatistics.IndexName IS NULL)
        AND (tmpIndexesStatistics.StatisticsName = SelectedIndexes2.StatisticsName OR tmpIndexesStatistics.StatisticsName IS NULL)
      END;

      WITH tmpIndexesStatistics AS (
      SELECT SchemaName, ObjectName, [Order], ROW_NUMBER() OVER (ORDER BY ISNULL(ResumableIndexOperation,0) DESC, StartPosition ASC, SchemaName ASC, ObjectName ASC, CASE WHEN IndexType IS NULL THEN 1 ELSE 0 END ASC, IndexType ASC, IndexName ASC, StatisticsName ASC, PartitionNumber ASC) AS RowNumber
      FROM @tmpIndexesStatistics tmpIndexesStatistics
      WHERE Selected = 1
      )
      UPDATE tmpIndexesStatistics
      SET [Order] = RowNumber

      SET @ErrorMessage = ''
      SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + '.' + QUOTENAME(SchemaName) + '.' + QUOTENAME(ObjectName) + ', '
      FROM @SelectedIndexes SelectedIndexes
      WHERE DatabaseName = @CurrentDatabaseName
      AND SchemaName NOT LIKE '%[%]%'
      AND ObjectName NOT LIKE '%[%]%'
      AND IndexName LIKE '%[%]%'
      AND NOT EXISTS (SELECT * FROM @tmpIndexesStatistics WHERE SchemaName = SelectedIndexes.SchemaName AND ObjectName = SelectedIndexes.ObjectName)
      IF @@ROWCOUNT > 0
      BEGIN
        SET @ErrorMessage = 'The following objects in the @Indexes parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.'
        RAISERROR('%s',10,1,@ErrorMessage) WITH NOWAIT
        SET @Error = @@ERROR
        RAISERROR(@EmptyLine,10,1) WITH NOWAIT
      END

      SET @ErrorMessage = ''
      SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + QUOTENAME(SchemaName) + '.' + QUOTENAME(ObjectName) + '.' + QUOTENAME(IndexName) + ', '
      FROM @SelectedIndexes SelectedIndexes
      WHERE DatabaseName = @CurrentDatabaseName
      AND SchemaName NOT LIKE '%[%]%'
      AND ObjectName NOT LIKE '%[%]%'
      AND IndexName NOT LIKE '%[%]%'
      AND NOT EXISTS (SELECT * FROM @tmpIndexesStatistics WHERE SchemaName = SelectedIndexes.SchemaName AND ObjectName = SelectedIndexes.ObjectName AND IndexName = SelectedIndexes.IndexName)
      IF @@ROWCOUNT > 0
      BEGIN
        SET @ErrorMessage = 'The following indexes in the @Indexes parameter do not exist: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.'
        RAISERROR('%s',10,1,@ErrorMessage) WITH NOWAIT
        SET @Error = @@ERROR
        RAISERROR(@EmptyLine,10,1) WITH NOWAIT
      END

      WHILE (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
      BEGIN
        SELECT TOP 1 @CurrentIxID = ID,
                     @CurrentIxOrder = [Order],
                     @CurrentSchemaID = SchemaID,
                     @CurrentSchemaName = SchemaName,
                     @CurrentObjectID = ObjectID,
                     @CurrentObjectName = ObjectName,
                     @CurrentObjectType = ObjectType,
                     @CurrentIsMemoryOptimized = IsMemoryOptimized,
                     @CurrentIndexID = IndexID,
                     @CurrentIndexName = IndexName,
                     @CurrentIndexType = IndexType,
                     @CurrentAllowPageLocks = AllowPageLocks,
                     @CurrentIsImageText = IsImageText,
                     @CurrentIsNewLOB = IsNewLOB,
                     @CurrentIsFileStream = IsFileStream,
                     @CurrentIsColumnStore = IsColumnStore,
                     @CurrentIsComputed = IsComputed,
                     @CurrentIsTimestamp = IsTimestamp,
                     @CurrentOnReadOnlyFileGroup = OnReadOnlyFileGroup,
                     @CurrentResumableIndexOperation = ResumableIndexOperation,
                     @CurrentStatisticsID = StatisticsID,
                     @CurrentStatisticsName = StatisticsName,
                     @CurrentNoRecompute = [NoRecompute],
                     @CurrentIsIncremental = IsIncremental,
                     @CurrentPartitionID = PartitionID,
                     @CurrentPartitionNumber = PartitionNumber,
                     @CurrentPartitionCount = PartitionCount
        FROM @tmpIndexesStatistics
        WHERE Selected = 1
        AND Completed = 0
        ORDER BY [Order] ASC

        IF @@ROWCOUNT = 0
        BEGIN
          BREAK
        END

        -- Is the index a partition?
        IF @CurrentPartitionNumber IS NULL OR @CurrentPartitionCount = 1 BEGIN SET @CurrentIsPartition = 0 END ELSE BEGIN SET @CurrentIsPartition = 1 END

        -- Does the index exist?
        IF @CurrentIndexID IS NOT NULL AND EXISTS(SELECT * FROM @ActionsPreferred)
        BEGIN
          SET @CurrentCommand = ''

          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '

          IF @CurrentIsPartition = 0 SET @CurrentCommand += 'IF EXISTS(SELECT * FROM sys.indexes indexes INNER JOIN sys.objects objects ON indexes.[object_id] = objects.[object_id] INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] IN(''U'',''V'') AND indexes.[type] IN(1,2,3,4,5,6,7) AND indexes.is_disabled = 0 AND indexes.is_hypothetical = 0 AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType AND indexes.index_id = @ParamIndexID AND indexes.[name] = @ParamIndexName AND indexes.[type] = @ParamIndexType) BEGIN SET @ParamIndexExists = 1 END'
          IF @CurrentIsPartition = 1 SET @CurrentCommand += 'IF EXISTS(SELECT * FROM sys.indexes indexes INNER JOIN sys.objects objects ON indexes.[object_id] = objects.[object_id] INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] INNER JOIN sys.partitions partitions ON indexes.[object_id] = partitions.[object_id] AND indexes.index_id = partitions.index_id WHERE objects.[type] IN(''U'',''V'') AND indexes.[type] IN(1,2,3,4,5,6,7) AND indexes.is_disabled = 0 AND indexes.is_hypothetical = 0 AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType AND indexes.index_id = @ParamIndexID AND indexes.[name] = @ParamIndexName AND indexes.[type] = @ParamIndexType AND partitions.partition_id = @ParamPartitionID AND partitions.partition_number = @ParamPartitionNumber) BEGIN SET @ParamIndexExists = 1 END'

          BEGIN TRY
            EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamIndexID int, @ParamIndexName sysname, @ParamIndexType int, @ParamPartitionID bigint, @ParamPartitionNumber int, @ParamIndexExists bit OUTPUT', @ParamSchemaID = @CurrentSchemaID, @ParamSchemaName = @CurrentSchemaName, @ParamObjectID = @CurrentObjectID, @ParamObjectName = @CurrentObjectName, @ParamObjectType = @CurrentObjectType, @ParamIndexID = @CurrentIndexID, @ParamIndexName = @CurrentIndexName, @ParamIndexType = @CurrentIndexType, @ParamPartitionID = @CurrentPartitionID, @ParamPartitionNumber = @CurrentPartitionNumber, @ParamIndexExists = @CurrentIndexExists OUTPUT

            IF @CurrentIndexExists IS NULL
            BEGIN
              SET @CurrentIndexExists = 0
              GOTO NoAction
            END
          END TRY
          BEGIN CATCH
            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'') + CASE WHEN ERROR_NUMBER() = 1222 THEN ' The index ' + QUOTENAME(@CurrentIndexName) + ' on the object ' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' is locked. It could not be checked if the index exists.' ELSE '' END
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR('%s',@Severity,1,@ErrorMessage) WITH NOWAIT
            RAISERROR(@EmptyLine,10,1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
              SET @ReturnCode = ERROR_NUMBER()
            END

            GOTO NoAction
          END CATCH
        END

        -- Does the statistics exist?
        IF @CurrentStatisticsID IS NOT NULL AND @UpdateStatistics IS NOT NULL
        BEGIN
          SET @CurrentCommand = ''

          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '

          SET @CurrentCommand += 'IF EXISTS(SELECT * FROM sys.stats stats INNER JOIN sys.objects objects ON stats.[object_id] = objects.[object_id] INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] IN(''U'',''V'')' + CASE WHEN @MSShippedObjects = 'N' THEN ' AND objects.is_ms_shipped = 0' ELSE '' END + ' AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType AND stats.stats_id = @ParamStatisticsID AND stats.[name] = @ParamStatisticsName) BEGIN SET @ParamStatisticsExists = 1 END'

          BEGIN TRY
            EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamStatisticsID int, @ParamStatisticsName sysname, @ParamStatisticsExists bit OUTPUT', @ParamSchemaID = @CurrentSchemaID, @ParamSchemaName = @CurrentSchemaName, @ParamObjectID = @CurrentObjectID, @ParamObjectName = @CurrentObjectName, @ParamObjectType = @CurrentObjectType, @ParamStatisticsID = @CurrentStatisticsID, @ParamStatisticsName = @CurrentStatisticsName, @ParamStatisticsExists = @CurrentStatisticsExists OUTPUT

            IF @CurrentStatisticsExists IS NULL
            BEGIN
              SET @CurrentStatisticsExists = 0
              GOTO NoAction
            END
          END TRY
          BEGIN CATCH
            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'') + CASE WHEN ERROR_NUMBER() = 1222 THEN ' The statistics ' + QUOTENAME(@CurrentStatisticsName) + ' on the object ' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' is locked. It could not be checked if the statistics exists.' ELSE '' END
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR('%s',@Severity,1,@ErrorMessage) WITH NOWAIT
            RAISERROR(@EmptyLine,10,1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
              SET @ReturnCode = ERROR_NUMBER()
            END

            GOTO NoAction
          END CATCH
        END

        -- Has the data in the statistics been modified since the statistics was last updated?
        IF @CurrentStatisticsID IS NOT NULL AND @UpdateStatistics IS NOT NULL
        BEGIN
          SET @CurrentCommand = ''

          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '

          IF @PartitionLevelStatistics = 1 AND @CurrentIsIncremental = 1
          BEGIN
            SET @CurrentCommand += 'SELECT @ParamRowCount = [rows], @ParamModificationCounter = modification_counter FROM sys.dm_db_incremental_stats_properties (@ParamObjectID, @ParamStatisticsID) WHERE partition_number = @ParamPartitionNumber'
          END
          ELSE
          IF (@Version >= 10.504000 AND @Version < 11) OR @Version >= 11.03000
          BEGIN
            SET @CurrentCommand += 'SELECT @ParamRowCount = [rows], @ParamModificationCounter = modification_counter FROM sys.dm_db_stats_properties (@ParamObjectID, @ParamStatisticsID)'
          END
          ELSE
          BEGIN
            SET @CurrentCommand += 'SELECT @ParamRowCount = rowcnt, @ParamModificationCounter = rowmodctr FROM sys.sysindexes sysindexes WHERE sysindexes.[id] = @ParamObjectID AND sysindexes.[indid] = @ParamStatisticsID'
          END

          BEGIN TRY
            EXECUTE @CurrentDatabase_sp_executesql @stmt = @CurrentCommand, @params = N'@ParamObjectID int, @ParamStatisticsID int, @ParamPartitionNumber int, @ParamRowCount bigint OUTPUT, @ParamModificationCounter bigint OUTPUT', @ParamObjectID = @CurrentObjectID, @ParamStatisticsID = @CurrentStatisticsID, @ParamPartitionNumber = @CurrentPartitionNumber, @ParamRowCount = @CurrentRowCount OUTPUT, @ParamModificationCounter = @CurrentModificationCounter OUTPUT

            IF @CurrentRowCount IS NULL SET @CurrentRowCount = 0
            IF @CurrentModificationCounter IS NULL SET @CurrentModificationCounter = 0
          END TRY
          BEGIN CATCH
            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'') + CASE WHEN ERROR_NUMBER() = 1222 THEN ' The statistics ' + QUOTENAME(@CurrentStatisticsName) + ' on the object ' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' is locked. The rows and modification_counter could not be checked.' ELSE '' END
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR('%s',@Severity,1,@ErrorMessage) WITH NOWAIT
            RAISERROR(@EmptyLine,10,1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
              SET @ReturnCode = ERROR_NUMBER()
            END

            GOTO NoAction
          END CATCH
        END

        -- Is the index fragmented?
        IF @CurrentIndexID IS NOT NULL
        AND @CurrentOnReadOnlyFileGroup = 0
        AND EXISTS(SELECT * FROM @ActionsPreferred)
        AND (EXISTS(SELECT [Priority], [Action], COUNT(*) FROM @ActionsPreferred GROUP BY [Priority], [Action] HAVING COUNT(*) <> 3) OR @MinNumberOfPages > 0 OR @MaxNumberOfPages IS NOT NULL)
        BEGIN
          SET @CurrentCommand = ''

          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '

          SET @CurrentCommand += 'SELECT @ParamFragmentationLevel = MAX(avg_fragmentation_in_percent), @ParamPageCount = SUM(page_count) FROM sys.dm_db_index_physical_stats(DB_ID(@ParamDatabaseName), @ParamObjectID, @ParamIndexID, @ParamPartitionNumber, ''LIMITED'') WHERE alloc_unit_type_desc = ''IN_ROW_DATA'' AND index_level = 0'

          BEGIN TRY
            EXECUTE sp_executesql @stmt = @CurrentCommand, @params = N'@ParamDatabaseName nvarchar(max), @ParamObjectID int, @ParamIndexID int, @ParamPartitionNumber int, @ParamFragmentationLevel float OUTPUT, @ParamPageCount bigint OUTPUT', @ParamDatabaseName = @CurrentDatabaseName, @ParamObjectID = @CurrentObjectID, @ParamIndexID = @CurrentIndexID, @ParamPartitionNumber = @CurrentPartitionNumber, @ParamFragmentationLevel = @CurrentFragmentationLevel OUTPUT, @ParamPageCount = @CurrentPageCount OUTPUT
          END TRY
          BEGIN CATCH
            SET @ErrorMessage = 'Msg ' + CAST(ERROR_NUMBER() AS nvarchar) + ', ' + ISNULL(ERROR_MESSAGE(),'') + CASE WHEN ERROR_NUMBER() = 1222 THEN ' The index ' + QUOTENAME(@CurrentIndexName) + ' on the object ' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' is locked. The page_count and avg_fragmentation_in_percent could not be checked.' ELSE '' END
            SET @Severity = CASE WHEN ERROR_NUMBER() IN(1205,1222) THEN @LockMessageSeverity ELSE 16 END
            RAISERROR('%s',@Severity,1,@ErrorMessage) WITH NOWAIT
            RAISERROR(@EmptyLine,10,1) WITH NOWAIT

            IF NOT (ERROR_NUMBER() IN(1205,1222) AND @LockMessageSeverity = 10)
            BEGIN
              SET @ReturnCode = ERROR_NUMBER()
            END

            GOTO NoAction
          END CATCH
        END

        -- Select fragmentation group
        IF @CurrentIndexID IS NOT NULL AND @CurrentOnReadOnlyFileGroup = 0 AND EXISTS(SELECT * FROM @ActionsPreferred)
        BEGIN
          SET @CurrentFragmentationGroup = CASE
          WHEN @CurrentFragmentationLevel >= @FragmentationLevel2 THEN 'High'
          WHEN @CurrentFragmentationLevel >= @FragmentationLevel1 AND @CurrentFragmentationLevel < @FragmentationLevel2 THEN 'Medium'
          WHEN @CurrentFragmentationLevel < @FragmentationLevel1 THEN 'Low'
          END
        END

        -- Which actions are allowed?
        IF @CurrentIndexID IS NOT NULL AND EXISTS(SELECT * FROM @ActionsPreferred)
        BEGIN
          IF @CurrentOnReadOnlyFileGroup = 0 AND @CurrentIndexType IN (1,2,3,4,5) AND (@CurrentIsMemoryOptimized = 0 OR @CurrentIsMemoryOptimized IS NULL) AND (@CurrentAllowPageLocks = 1 OR @CurrentIndexType = 5)
          BEGIN
            INSERT INTO @CurrentActionsAllowed ([Action])
            VALUES ('INDEX_REORGANIZE')
          END
          IF @CurrentOnReadOnlyFileGroup = 0 AND @CurrentIndexType IN (1,2,3,4,5) AND (@CurrentIsMemoryOptimized = 0 OR @CurrentIsMemoryOptimized IS NULL)
          BEGIN
            INSERT INTO @CurrentActionsAllowed ([Action])
            VALUES ('INDEX_REBUILD_OFFLINE')
          END
          IF @CurrentOnReadOnlyFileGroup = 0
          AND (@CurrentIsMemoryOptimized = 0 OR @CurrentIsMemoryOptimized IS NULL)
          AND (@CurrentIsPartition = 0 OR @Version >= 12)
          AND ((@CurrentIndexType = 1 AND @CurrentIsImageText = 0 AND @CurrentIsNewLOB = 0)
          OR (@CurrentIndexType = 2 AND @CurrentIsNewLOB = 0)
          OR (@CurrentIndexType = 1 AND @CurrentIsImageText = 0 AND @CurrentIsFileStream = 0 AND @Version >= 11)
          OR (@CurrentIndexType = 2 AND @Version >= 11))
          AND (@CurrentIsColumnStore = 0 OR @Version < 11)
          AND SERVERPROPERTY('EngineEdition') IN (3,5,8)
          BEGIN
            INSERT INTO @CurrentActionsAllowed ([Action])
            VALUES ('INDEX_REBUILD_ONLINE')
          END
        END

        -- Decide action
        IF @CurrentIndexID IS NOT NULL
        AND EXISTS(SELECT * FROM @ActionsPreferred)
        AND (@CurrentPageCount >= @MinNumberOfPages OR @MinNumberOfPages = 0)
        AND (@CurrentPageCount <= @MaxNumberOfPages OR @MaxNumberOfPages IS NULL)
        AND @CurrentResumableIndexOperation = 0
        BEGIN
          IF EXISTS(SELECT [Priority], [Action], COUNT(*) FROM @ActionsPreferred GROUP BY [Priority], [Action] HAVING COUNT(*) <> 3)
          BEGIN
            SELECT @CurrentAction = [Action]
            FROM @ActionsPreferred
            WHERE FragmentationGroup = @CurrentFragmentationGroup
            AND [Priority] = (SELECT MIN([Priority])
                              FROM @ActionsPreferred
                              WHERE FragmentationGroup = @CurrentFragmentationGroup
                              AND [Action] IN (SELECT [Action] FROM @CurrentActionsAllowed))
          END
          ELSE
          BEGIN
            SELECT @CurrentAction = [Action]
            FROM @ActionsPreferred
            WHERE [Priority] = (SELECT MIN([Priority])
                                FROM @ActionsPreferred
                                WHERE [Action] IN (SELECT [Action] FROM @CurrentActionsAllowed))
          END
        END

        IF @CurrentResumableIndexOperation = 1
        BEGIN
          SET @CurrentAction = 'INDEX_REBUILD_ONLINE'
        END

        -- Workaround for limitation in SQL Server, http://support.microsoft.com/kb/2292737
        IF @CurrentIndexID IS NOT NULL
        BEGIN
          SET @CurrentMaxDOP = @MaxDOP

          IF @CurrentAction = 'INDEX_REBUILD_ONLINE' AND @CurrentAllowPageLocks = 0
          BEGIN
            SET @CurrentMaxDOP = 1
          END
        END

        -- Update statistics?
        IF @CurrentStatisticsID IS NOT NULL
        AND ((@UpdateStatistics = 'ALL' AND (@CurrentIndexType IN (1,2,3,4,7) OR @CurrentIndexID IS NULL)) OR (@UpdateStatistics = 'INDEX' AND @CurrentIndexID IS NOT NULL AND @CurrentIndexType IN (1,2,3,4,7)) OR (@UpdateStatistics = 'COLUMNS' AND @CurrentIndexID IS NULL))
        AND ((@OnlyModifiedStatistics = 'N' AND @StatisticsModificationLevel IS NULL) OR (@OnlyModifiedStatistics = 'Y' AND @CurrentModificationCounter > 0) OR ((@CurrentModificationCounter * 1. / NULLIF(@CurrentRowCount,0)) * 100 >= @StatisticsModificationLevel) OR (@StatisticsModificationLevel IS NOT NULL AND @CurrentModificationCounter > 0 AND (@CurrentModificationCounter >= SQRT(@CurrentRowCount * 1000))) OR (@CurrentIsMemoryOptimized = 1 AND NOT (@Version >= 13 OR SERVERPROPERTY('EngineEdition') IN (5,8))))
        AND ((@CurrentIsPartition = 0 AND (@CurrentAction NOT IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') OR @CurrentAction IS NULL)) OR (@CurrentIsPartition = 1 AND (@CurrentPartitionNumber = @CurrentPartitionCount OR (@PartitionLevelStatistics = 1 AND @CurrentIsIncremental = 1))))
        BEGIN
          SET @CurrentUpdateStatistics = 'Y'
        END
        ELSE
        BEGIN
          SET @CurrentUpdateStatistics = 'N'
        END

        SET @CurrentStatisticsSample = @StatisticsSample
        SET @CurrentStatisticsResample = @StatisticsResample

        -- Memory-optimized tables only supports FULLSCAN and RESAMPLE in SQL Server 2014
        IF @CurrentIsMemoryOptimized = 1 AND NOT (@Version >= 13 OR SERVERPROPERTY('EngineEdition') IN (5,8)) AND (@CurrentStatisticsSample <> 100 OR @CurrentStatisticsSample IS NULL)
        BEGIN
          SET @CurrentStatisticsSample = NULL
          SET @CurrentStatisticsResample = 'Y'
        END

        -- Incremental statistics only supports RESAMPLE
        IF @PartitionLevelStatistics = 1 AND @CurrentIsIncremental = 1
        BEGIN
          SET @CurrentStatisticsSample = NULL
          SET @CurrentStatisticsResample = 'Y'
        END

        -- Create index comment
        IF @CurrentIndexID IS NOT NULL
        BEGIN
          SET @CurrentComment = 'ObjectType: ' + CASE WHEN @CurrentObjectType = 'U' THEN 'Table' WHEN @CurrentObjectType = 'V' THEN 'View' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'IndexType: ' + CASE WHEN @CurrentIndexType = 1 THEN 'Clustered' WHEN @CurrentIndexType = 2 THEN 'NonClustered' WHEN @CurrentIndexType = 3 THEN 'XML' WHEN @CurrentIndexType = 4 THEN 'Spatial' WHEN @CurrentIndexType = 5 THEN 'Clustered Columnstore' WHEN @CurrentIndexType = 6 THEN 'NonClustered Columnstore' WHEN @CurrentIndexType = 7 THEN 'NonClustered Hash' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'ImageText: ' + CASE WHEN @CurrentIsImageText = 1 THEN 'Yes' WHEN @CurrentIsImageText = 0 THEN 'No' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'NewLOB: ' + CASE WHEN @CurrentIsNewLOB = 1 THEN 'Yes' WHEN @CurrentIsNewLOB = 0 THEN 'No' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'FileStream: ' + CASE WHEN @CurrentIsFileStream = 1 THEN 'Yes' WHEN @CurrentIsFileStream = 0 THEN 'No' ELSE 'N/A' END + ', '
          IF @Version >= 11 SET @CurrentComment += 'ColumnStore: ' + CASE WHEN @CurrentIsColumnStore = 1 THEN 'Yes' WHEN @CurrentIsColumnStore = 0 THEN 'No' ELSE 'N/A' END + ', '
          IF @Version >= 14 AND @Resumable = 'Y' SET @CurrentComment += 'Computed: ' + CASE WHEN @CurrentIsComputed = 1 THEN 'Yes' WHEN @CurrentIsComputed = 0 THEN 'No' ELSE 'N/A' END + ', '
          IF @Version >= 14 AND @Resumable = 'Y' SET @CurrentComment += 'Timestamp: ' + CASE WHEN @CurrentIsTimestamp = 1 THEN 'Yes' WHEN @CurrentIsTimestamp = 0 THEN 'No' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'AllowPageLocks: ' + CASE WHEN @CurrentAllowPageLocks = 1 THEN 'Yes' WHEN @CurrentAllowPageLocks = 0 THEN 'No' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'PageCount: ' + ISNULL(CAST(@CurrentPageCount AS nvarchar),'N/A') + ', '
          SET @CurrentComment += 'Fragmentation: ' + ISNULL(CAST(@CurrentFragmentationLevel AS nvarchar),'N/A')
        END

        IF @CurrentIndexID IS NOT NULL AND (@CurrentPageCount IS NOT NULL OR @CurrentFragmentationLevel IS NOT NULL)
        BEGIN
        SET @CurrentExtendedInfo = (SELECT *
                                    FROM (SELECT CAST(@CurrentPageCount AS nvarchar) AS [PageCount],
                                                 CAST(@CurrentFragmentationLevel AS nvarchar) AS Fragmentation
                                    ) ExtendedInfo FOR XML RAW('ExtendedInfo'), ELEMENTS)
        END

        IF @CurrentIndexID IS NOT NULL AND @CurrentAction IS NOT NULL AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
        BEGIN
          SET @CurrentDatabaseContext = @CurrentDatabaseName

          SET @CurrentCommandType = 'ALTER_INDEX'

          SET @CurrentCommand = ''
          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
          SET @CurrentCommand += 'ALTER INDEX ' + QUOTENAME(@CurrentIndexName) + ' ON ' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName)
          IF @CurrentResumableIndexOperation = 1 SET @CurrentCommand += ' RESUME'
          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') AND @CurrentResumableIndexOperation = 0 SET @CurrentCommand += ' REBUILD'
          IF @CurrentAction IN('INDEX_REORGANIZE') AND @CurrentResumableIndexOperation = 0 SET @CurrentCommand += ' REORGANIZE'
          IF @CurrentIsPartition = 1 AND @CurrentResumableIndexOperation = 0 SET @CurrentCommand += ' PARTITION = ' + CAST(@CurrentPartitionNumber AS nvarchar)

          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') AND @SortInTempdb = 'Y' AND @CurrentIndexType IN(1,2,3,4) AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'SORT_IN_TEMPDB = ON'
          END

          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') AND @SortInTempdb = 'N' AND @CurrentIndexType IN(1,2,3,4) AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'SORT_IN_TEMPDB = OFF'
          END

          IF @CurrentAction = 'INDEX_REBUILD_ONLINE' AND (@CurrentIsPartition = 0 OR @Version >= 12) AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'ONLINE = ON' + CASE WHEN @WaitAtLowPriorityMaxDuration IS NOT NULL THEN ' (WAIT_AT_LOW_PRIORITY (MAX_DURATION = ' + CAST(@WaitAtLowPriorityMaxDuration AS nvarchar) + ', ABORT_AFTER_WAIT = ' + UPPER(@WaitAtLowPriorityAbortAfterWait) + '))' ELSE '' END
          END

          IF @CurrentAction = 'INDEX_REBUILD_OFFLINE' AND (@CurrentIsPartition = 0 OR @Version >= 12) AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'ONLINE = OFF'
          END

          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') AND @CurrentMaxDOP IS NOT NULL
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'MAXDOP = ' + CAST(@CurrentMaxDOP AS nvarchar)
          END

          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') AND @FillFactor IS NOT NULL AND @CurrentIsPartition = 0 AND @CurrentIndexType IN(1,2,3,4) AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'FILLFACTOR = ' + CAST(@FillFactor AS nvarchar)
          END

          IF @CurrentAction IN('INDEX_REBUILD_ONLINE','INDEX_REBUILD_OFFLINE') AND @PadIndex = 'Y' AND @CurrentIsPartition = 0 AND @CurrentIndexType IN(1,2,3,4) AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'PAD_INDEX = ON'
          END

          IF (@Version >= 14 OR SERVERPROPERTY('EngineEdition') IN (5,8)) AND @CurrentAction = 'INDEX_REBUILD_ONLINE' AND @CurrentResumableIndexOperation = 0
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT CASE WHEN @Resumable = 'Y' AND @CurrentIndexType IN(1,2) AND @CurrentIsComputed = 0 AND @CurrentIsTimestamp = 0 THEN 'RESUMABLE = ON' ELSE 'RESUMABLE = OFF' END
          END

          IF (@Version >= 14 OR SERVERPROPERTY('EngineEdition') IN (5,8)) AND @CurrentAction = 'INDEX_REBUILD_ONLINE' AND @CurrentResumableIndexOperation = 0 AND @Resumable = 'Y'  AND @CurrentIndexType IN(1,2) AND @CurrentIsComputed = 0 AND @CurrentIsTimestamp = 0 AND @TimeLimit IS NOT NULL
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'MAX_DURATION = ' + CAST(DATEDIFF(MINUTE,SYSDATETIME(),DATEADD(SECOND,@TimeLimit,@StartTime)) AS nvarchar(max))
          END

          IF @CurrentAction IN('INDEX_REORGANIZE') AND @LOBCompaction = 'Y'
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'LOB_COMPACTION = ON'
          END

          IF @CurrentAction IN('INDEX_REORGANIZE') AND @LOBCompaction = 'N'
          BEGIN
            INSERT INTO @CurrentAlterIndexWithClauseArguments (Argument)
            SELECT 'LOB_COMPACTION = OFF'
          END

          IF EXISTS (SELECT * FROM @CurrentAlterIndexWithClauseArguments)
          BEGIN
            SET @CurrentAlterIndexWithClause = ' WITH ('

            WHILE (1 = 1)
            BEGIN
              SELECT TOP 1 @CurrentAlterIndexArgumentID = ID,
                           @CurrentAlterIndexArgument = Argument
              FROM @CurrentAlterIndexWithClauseArguments
              WHERE Added = 0
              ORDER BY ID ASC

              IF @@ROWCOUNT = 0
              BEGIN
                BREAK
              END

              SET @CurrentAlterIndexWithClause += @CurrentAlterIndexArgument + ', '

              UPDATE @CurrentAlterIndexWithClauseArguments
              SET Added = 1
              WHERE [ID] = @CurrentAlterIndexArgumentID
            END

            SET @CurrentAlterIndexWithClause = RTRIM(@CurrentAlterIndexWithClause)

            SET @CurrentAlterIndexWithClause = LEFT(@CurrentAlterIndexWithClause,LEN(@CurrentAlterIndexWithClause) - 1)

            SET @CurrentAlterIndexWithClause = @CurrentAlterIndexWithClause + ')'
          END

          IF @CurrentAlterIndexWithClause IS NOT NULL SET @CurrentCommand += @CurrentAlterIndexWithClause

          EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseName, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 2, @Comment = @CurrentComment, @DatabaseName = @CurrentDatabaseName, @SchemaName = @CurrentSchemaName, @ObjectName = @CurrentObjectName, @ObjectType = @CurrentObjectType, @IndexName = @CurrentIndexName, @IndexType = @CurrentIndexType, @PartitionNumber = @CurrentPartitionNumber, @ExtendedInfo = @CurrentExtendedInfo, @LockMessageSeverity = @LockMessageSeverity, @ExecuteAsUser = @ExecuteAsUser, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput = @Error
          IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput

          IF @Delay > 0
          BEGIN
            SET @CurrentDelay = DATEADD(ss,@Delay,'1900-01-01')
            WAITFOR DELAY @CurrentDelay
          END
        END

        SET @CurrentMaxDOP = @MaxDOP

        -- Create statistics comment
        IF @CurrentStatisticsID IS NOT NULL
        BEGIN
          SET @CurrentComment = 'ObjectType: ' + CASE WHEN @CurrentObjectType = 'U' THEN 'Table' WHEN @CurrentObjectType = 'V' THEN 'View' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'IndexType: ' + CASE WHEN @CurrentIndexID IS NOT NULL THEN 'Index' ELSE 'Column' END + ', '
          IF @CurrentIndexID IS NOT NULL SET @CurrentComment += 'IndexType: ' + CASE WHEN @CurrentIndexType = 1 THEN 'Clustered' WHEN @CurrentIndexType = 2 THEN 'NonClustered' WHEN @CurrentIndexType = 3 THEN 'XML' WHEN @CurrentIndexType = 4 THEN 'Spatial' WHEN @CurrentIndexType = 5 THEN 'Clustered Columnstore' WHEN @CurrentIndexType = 6 THEN 'NonClustered Columnstore' WHEN @CurrentIndexType = 7 THEN 'NonClustered Hash' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'Incremental: ' + CASE WHEN @CurrentIsIncremental = 1 THEN 'Y' WHEN @CurrentIsIncremental = 0 THEN 'N' ELSE 'N/A' END + ', '
          SET @CurrentComment += 'RowCount: ' + ISNULL(CAST(@CurrentRowCount AS nvarchar),'N/A') + ', '
          SET @CurrentComment += 'ModificationCounter: ' + ISNULL(CAST(@CurrentModificationCounter AS nvarchar),'N/A')
        END

        IF @CurrentStatisticsID IS NOT NULL AND (@CurrentRowCount IS NOT NULL OR @CurrentModificationCounter IS NOT NULL)
        BEGIN
        SET @CurrentExtendedInfo = (SELECT *
                                    FROM (SELECT CAST(@CurrentRowCount AS nvarchar) AS [RowCount],
                                                 CAST(@CurrentModificationCounter AS nvarchar) AS ModificationCounter
                                    ) ExtendedInfo FOR XML RAW('ExtendedInfo'), ELEMENTS)
        END

        IF @CurrentStatisticsID IS NOT NULL AND @CurrentUpdateStatistics = 'Y' AND (SYSDATETIME() < DATEADD(SECOND,@TimeLimit,@StartTime) OR @TimeLimit IS NULL)
        BEGIN
          SET @CurrentDatabaseContext = @CurrentDatabaseName

          SET @CurrentCommandType = 'UPDATE_STATISTICS'

          SET @CurrentCommand = ''
          IF @LockTimeout IS NOT NULL SET @CurrentCommand = 'SET LOCK_TIMEOUT ' + CAST(@LockTimeout * 1000 AS nvarchar) + '; '
          SET @CurrentCommand += 'UPDATE STATISTICS ' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ' ' + QUOTENAME(@CurrentStatisticsName)

          IF @CurrentMaxDOP IS NOT NULL AND ((@Version >= 12.06024 AND @Version < 13) OR (@Version >= 13.05026 AND @Version < 14) OR @Version >= 14.030154)
          BEGIN
            INSERT INTO @CurrentUpdateStatisticsWithClauseArguments (Argument)
            SELECT 'MAXDOP = ' + CAST(@CurrentMaxDOP AS nvarchar)
          END

          IF @CurrentStatisticsSample = 100
          BEGIN
            INSERT INTO @CurrentUpdateStatisticsWithClauseArguments (Argument)
            SELECT 'FULLSCAN'
          END

          IF @CurrentStatisticsSample IS NOT NULL AND @CurrentStatisticsSample <> 100
          BEGIN
            INSERT INTO @CurrentUpdateStatisticsWithClauseArguments (Argument)
            SELECT 'SAMPLE ' + CAST(@CurrentStatisticsSample AS nvarchar) + ' PERCENT'
          END

          IF @CurrentStatisticsResample = 'Y'
          BEGIN
            INSERT INTO @CurrentUpdateStatisticsWithClauseArguments (Argument)
            SELECT 'RESAMPLE'
          END

          IF @CurrentNoRecompute = 1
          BEGIN
            INSERT INTO @CurrentUpdateStatisticsWithClauseArguments (Argument)
            SELECT 'NORECOMPUTE'
          END

          IF EXISTS (SELECT * FROM @CurrentUpdateStatisticsWithClauseArguments)
          BEGIN
            SET @CurrentUpdateStatisticsWithClause = ' WITH'

            WHILE (1 = 1)
            BEGIN
              SELECT TOP 1 @CurrentUpdateStatisticsArgumentID = ID,
                           @CurrentUpdateStatisticsArgument = Argument
              FROM @CurrentUpdateStatisticsWithClauseArguments
              WHERE Added = 0
              ORDER BY ID ASC

              IF @@ROWCOUNT = 0
              BEGIN
                BREAK
              END

              SET @CurrentUpdateStatisticsWithClause = @CurrentUpdateStatisticsWithClause + ' ' + @CurrentUpdateStatisticsArgument + ','

              UPDATE @CurrentUpdateStatisticsWithClauseArguments
              SET Added = 1
              WHERE [ID] = @CurrentUpdateStatisticsArgumentID
            END

            SET @CurrentUpdateStatisticsWithClause = LEFT(@CurrentUpdateStatisticsWithClause,LEN(@CurrentUpdateStatisticsWithClause) - 1)
          END

          IF @CurrentUpdateStatisticsWithClause IS NOT NULL SET @CurrentCommand += @CurrentUpdateStatisticsWithClause

          IF @PartitionLevelStatistics = 1 AND @CurrentIsIncremental = 1 AND @CurrentPartitionNumber IS NOT NULL SET @CurrentCommand += ' ON PARTITIONS(' + CAST(@CurrentPartitionNumber AS nvarchar(max)) + ')'

          EXECUTE @CurrentCommandOutput = dbo.CommandExecute @DatabaseContext = @CurrentDatabaseName, @Command = @CurrentCommand, @CommandType = @CurrentCommandType, @Mode = 2, @Comment = @CurrentComment, @DatabaseName = @CurrentDatabaseName, @SchemaName = @CurrentSchemaName, @ObjectName = @CurrentObjectName, @ObjectType = @CurrentObjectType, @IndexName = @CurrentIndexName, @IndexType = @CurrentIndexType, @StatisticsName = @CurrentStatisticsName, @ExtendedInfo = @CurrentExtendedInfo, @LockMessageSeverity = @LockMessageSeverity, @ExecuteAsUser = @ExecuteAsUser, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput = @Error
          IF @CurrentCommandOutput <> 0 SET @ReturnCode = @CurrentCommandOutput
        END

        NoAction:

        -- Update that the index or statistics is completed
        UPDATE @tmpIndexesStatistics
        SET Completed = 1
        WHERE Selected = 1
        AND Completed = 0
        AND [Order] = @CurrentIxOrder
        AND ID = @CurrentIxID

        -- Clear variables
        SET @CurrentDatabaseContext = NULL

        SET @CurrentCommand = NULL
        SET @CurrentCommandOutput = NULL
        SET @CurrentCommandType = NULL
        SET @CurrentComment = NULL
        SET @CurrentExtendedInfo = NULL

        SET @CurrentIxID = NULL
        SET @CurrentIxOrder = NULL
        SET @CurrentSchemaID = NULL
        SET @CurrentSchemaName = NULL
        SET @CurrentObjectID = NULL
        SET @CurrentObjectName = NULL
        SET @CurrentObjectType = NULL
        SET @CurrentIsMemoryOptimized = NULL
        SET @CurrentIndexID = NULL
        SET @CurrentIndexName = NULL
        SET @CurrentIndexType = NULL
        SET @CurrentStatisticsID = NULL
        SET @CurrentStatisticsName = NULL
        SET @CurrentPartitionID = NULL
        SET @CurrentPartitionNumber = NULL
        SET @CurrentPartitionCount = NULL
        SET @CurrentIsPartition = NULL
        SET @CurrentIndexExists = NULL
        SET @CurrentStatisticsExists = NULL
        SET @CurrentIsImageText = NULL
        SET @CurrentIsNewLOB = NULL
        SET @CurrentIsFileStream = NULL
        SET @CurrentIsColumnStore = NULL
        SET @CurrentIsComputed = NULL
        SET @CurrentIsTimestamp = NULL
        SET @CurrentAllowPageLocks = NULL
        SET @CurrentNoRecompute = NULL
        SET @CurrentIsIncremental = NULL
        SET @CurrentRowCount = NULL
        SET @CurrentModificationCounter = NULL
        SET @CurrentOnReadOnlyFileGroup = NULL
        SET @CurrentResumableIndexOperation = NULL
        SET @CurrentFragmentationLevel = NULL
        SET @CurrentPageCount = NULL
        SET @CurrentFragmentationGroup = NULL
        SET @CurrentAction = NULL
        SET @CurrentMaxDOP = NULL
        SET @CurrentUpdateStatistics = NULL
        SET @CurrentStatisticsSample = NULL
        SET @CurrentStatisticsResample = NULL
        SET @CurrentAlterIndexArgumentID = NULL
        SET @CurrentAlterIndexArgument = NULL
        SET @CurrentAlterIndexWithClause = NULL
        SET @CurrentUpdateStatisticsArgumentID = NULL
        SET @CurrentUpdateStatisticsArgument = NULL
        SET @CurrentUpdateStatisticsWithClause = NULL

        DELETE FROM @CurrentActionsAllowed
        DELETE FROM @CurrentAlterIndexWithClauseArguments
        DELETE FROM @CurrentUpdateStatisticsWithClauseArguments

      END

    END

    IF @CurrentDatabaseState = 'SUSPECT'
    BEGIN
      SET @ErrorMessage = 'The database ' + QUOTENAME(@CurrentDatabaseName) + ' is in a SUSPECT state.'
      RAISERROR('%s',16,1,@ErrorMessage) WITH NOWAIT
      RAISERROR(@EmptyLine,10,1) WITH NOWAIT
      SET @Error = @@ERROR
    END

    -- Update that the database is completed
    IF @DatabasesInParallel = 'Y'
    BEGIN
      UPDATE dbo.QueueDatabase
      SET DatabaseEndTime = SYSDATETIME()
      WHERE QueueID = @QueueID
      AND DatabaseName = @CurrentDatabaseName
    END
    ELSE
    BEGIN
      UPDATE @tmpDatabases
      SET Completed = 1
      WHERE Selected = 1
      AND Completed = 0
      AND ID = @CurrentDBID
    END

    -- Clear variables
    SET @CurrentDBID = NULL
    SET @CurrentDatabaseName = NULL

    SET @CurrentDatabase_sp_executesql = NULL

    SET @CurrentExecuteAsUserExists = NULL
    SET @CurrentUserAccess = NULL
    SET @CurrentIsReadOnly = NULL
    SET @CurrentDatabaseState = NULL
    SET @CurrentInStandby = NULL
    SET @CurrentRecoveryModel = NULL

    SET @CurrentIsDatabaseAccessible = NULL
    SET @CurrentReplicaID = NULL
    SET @CurrentAvailabilityGroupID = NULL
    SET @CurrentAvailabilityGroup = NULL
    SET @CurrentAvailabilityGroupRole = NULL
    SET @CurrentDatabaseMirroringRole = NULL

    SET @CurrentCommand = NULL

    DELETE FROM @tmpIndexesStatistics

  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  Logging:
  SET @EndMessage = 'Date and time: ' + CONVERT(nvarchar,SYSDATETIME(),120)
  RAISERROR('%s',10,1,@EndMessage) WITH NOWAIT

  RAISERROR(@EmptyLine,10,1) WITH NOWAIT

  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END

GO

ALTER AUTHORIZATION ON [dbo].[IndexOptimize] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[IndexOptimize] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[pgetrouteprogrameventworkorders]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pgetrouteprogrameventworkorders]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[pgetrouteprogrameventworkorders] AS' 
END
GO


/***************************************************************************\
*                                                                          *
* MODULE:         pgetrouteprogrameventworkorders                          *
*                                                                          *
* APPLICATION:    ServSuite                                                *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
*                                                                          *
* AUTHOR:         Dejan Karafilov                             *
*                                                                          *
* CHANGE HISTORY:                                                          *
*                 08/07/2017 -- Created                                    *
*				08/13/2018  -- JKD tfs 101788 OrkinCanada columns          *
*                                                                          *
\***************************************************************************/
ALTER PROCEDURE [dbo].[pgetrouteprogrameventworkorders] 
	@pathtoprogram NVARCHAR(250)
	,@localeID INT
	,@languageid INT
	,@companyid INT
	,@loginid INT
	,@servicecenterid INT
	,@startdate NVARCHAR(80)
	,@enddate NVARCHAR(80)
	,@propertytypeid INT
	,@sortby NVARCHAR(256)
	,@workpool INT
	,@dateformat NVARCHAR(50)
	,@addformat NVARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON

	SELECT (vreportlogin.branchname) AS branchname
		,ISNULL(troute.routename, 'NULL Route') AS routename
		,(tworkorderheader.woheaderid) AS woheaderid
		,dbo.FormatDateByLocale(tworkorderheader.scheduledate, @dateformat) AS scheduledate
		,dbo.FormatDateByLocale(tworkorderheader.printeddate, @dateformat) AS printeddate
		,dbo.FormatDateByLocale(tprogram.saledate, @dateformat) AS saledate
		,(taccount.accountnum) AS accountnum
		,(tvs.eventname) AS Event
		,prg.programname
		,tevent.measurement
		,tsite.mapcode
		,MAX(SUBSTRING(tworkorderevent.jobinstructions, 1, 400)) AS jobinstructions
		,CASE tcontact.businessname
			WHEN ''
				THEN tcontact.lastname + ', ' + tcontact.firstname
			ELSE tcontact.businessname
			END AS Name
		,taddress.streetnumber
		,taddress.predirection
		,taddress.streetname
		,taddress.streetsuffix
		,taddress.postdirection
		,taddress.state
		,taddress.city
		,taddress.postalcode
		,taddress.postalcodeex
		,dbo.GetSingleLineAddFormat(taddress.streetnumber, taddress.predirection, taddress.streetname, taddress.streetsuffix, NULL, NULL, taddress.city, taddress.STATE, taddress.postalcode, taddress.postalcodeex, 0, 0, NULL, @addformat) AS serviceaddress
		,streetinfo = taddress.streetnumber + ' ' + taddress.predirection + ' ' + taddress.streetname
		,tcontactphonenumber.phonenumber
		,CASE tcontactphonenumber.phonetype
			WHEN 1
				THEN 'H'
			WHEN 2
				THEN 'W'
			WHEN 3
				THEN 'w'
			WHEN 4
				THEN 'F'
			ELSE 'H'
			END AS phonetype
		,CAST(SUM(tworkorderevent.prodamount) AS DECIMAL(8, 2)) AS prodamount
		,lastsvcdate = (
			SELECT dbo.FormatDateByLocale(MAX(completeddate), @dateformat) AS lastdate
			FROM tworkorderevent woe
			WHERE woe.baseeventid = tevent.eventid
			)
			,max(tworkorderevent.duration) as woduration
----tfs 101788
			,tsite.siteid
			,technicianname  = (
				select top 1 
				case isnull(labcont.lastname,'') when '' then isnull(labcont.firstname,'') else
				isnull(labcont.lastname,'') + ', ' + isnull(labcont.firstname,'') end  
				from tworkorderevent woe
				inner join tworkorderlabor wolab on wolab.woeventid = woe.woeventid  and wolab.isprimary = 1
				left outer join temployee labemp on labemp.employeeid = wolab.employeeid
				left outer join tcontact labcont on labcont.contactid = labemp.contactid
				where woe.baseeventid =   tevent.eventid)
	FROM dbo.taccount
	INNER JOIN dbo.testimate ON dbo.taccount.accountid = dbo.testimate.accountid
	INNER JOIN dbo.tprogram ON dbo.testimate.estimateid = dbo.tprogram.estimateid
	INNER JOIN dbo.tsite ON dbo.testimate.siteid = dbo.tsite.siteid
	INNER JOIN dbo.taddress ON dbo.tsite.addressid = dbo.taddress.addressid
	INNER JOIN dbo.tcontact ON dbo.tsite.primarycontactid = dbo.tcontact.contactid
	LEFT JOIN dbo.tcontactphonenumber ON dbo.tcontact.primaryphoneid = dbo.tcontactphonenumber.phoneid
	INNER JOIN dbo.tprogramsetup ON dbo.tprogram.programtypeid = dbo.tprogramsetup.programtypeid
	INNER JOIN dbo.tprogramsetupname000 prg ON dbo.tprogramsetup.programtypeid = prg.programtypeid
	INNER JOIN dbo.tevent ON dbo.tprogram.programid = dbo.tevent.programid
	INNER JOIN dbo.teventsetup ON dbo.teventsetup.eventtypeid = dbo.tevent.eventtypeid
	INNER JOIN dbo.teventsetupname000 tvs ON tevent.eventtypeid = tvs.eventtypeid
	INNER JOIN dbo.tworkorderevent ON dbo.tevent.eventid = dbo.tworkorderevent.baseeventid
	INNER JOIN dbo.tworkorderheader ON dbo.tworkorderevent.headerid = dbo.tworkorderheader.woheaderid
	LEFT JOIN dbo.troute ON dbo.tworkorderheader.assignedto = dbo.troute.routeid
	INNER JOIN dbo.tbranch ON dbo.tworkorderevent.servicecenterid = dbo.tbranch.branchid
	INNER JOIN vreportlogin ON tworkorderevent.servicecenterid = vreportlogin.branchid
	INNER JOIN ttempkeyid temproute ON troute.routeid = temproute.keyid
		AND temproute.typeid = 3
		AND temproute.loginid = @loginid
	INNER JOIN ttempkeyid tempevent ON tevent.eventtypeid = tempevent.keyid
		AND tempevent.typeid = 7
		AND tempevent.loginid = @loginid
	INNER JOIN ttempkeyid tempprog ON tprogram.programtypeid = tempprog.keyid
		AND tempprog.typeid = 6
		AND tempprog.loginid = @loginid
	WHERE taccount.financialhold = 0
		AND (tworkorderevent.deleteddate IS NULL)
		AND (
			dbo.tworkorderevent.wotype = 0
			OR dbo.teventsetup.eventtypeid = 489
			)
		AND (dbo.tworkorderevent.skippeddate IS NULL)
		AND tworkorderevent.completeddate IS NULL
		AND (
			dbo.tprogram.canceldate IS NULL
			OR tevent.canceldate IS NULL
			)
		AND (
			(
				dbo.tworkorderheader.scheduledate BETWEEN @startdate AND @enddate
				)
			)
		AND dbo.vreportlogin.companyid = @companyid
		AND dbo.vreportlogin.loginid = @loginid
		AND (
			(
				@propertytypeid != - 999
				AND tsite.propertytype = @propertytypeid
				)
			OR (@propertytypeid = - 999)
			)
		AND (
			(
				@servicecenterid != - 999
				AND tworkorderevent.servicecenterid = @servicecenterid
				)
			OR (@servicecenterid = - 999)
			)
		AND (
			(
				@workpool = 1
				AND tworkorderheader.workpool = 0
				)
			OR (
				@workpool = 2
				AND tworkorderheader.workpool = 1
				)
			OR (
				@workpool != 1
				AND @workpool != 2
				)
			)
	GROUP BY routename
		,tworkorderheader.scheduledate
		,accountnum
		,tvs.eventname
		,woheaderid
		,vreportlogin.branchname
		,phonetype
		,businessname
		,tevent.measurement
		,mapcode
		----tfs 101788
		,tsite.siteid
		,tprogram.saledate
		,tevent.eventid
		,printeddate
		,prodamount
		,firstname
		,lastname
		,prg.programname
		,streetnumber
		,predirection
		,streetname
		,streetsuffix
		,postdirection
		,state
		,city
		,postalcode
		,postalcodeex
		,phonenumber
	ORDER BY CASE 
			WHEN @sortby = 'accountnum'
				THEN accountnum
			END
		,CASE 
			WHEN @sortby = 'Name'
				THEN CASE tcontact.businessname
						WHEN ''
							THEN tcontact.lastname + ', ' + tcontact.firstname
						ELSE tcontact.businessname
						END
			END
		,CASE 
			WHEN @sortby = 'postalcode'
				THEN postalcode
			END
		,CASE 
			WHEN @sortby = 'mapcode'
				THEN mapcode
			END

	SET NOCOUNT OFF
END
GO

ALTER AUTHORIZATION ON [dbo].[pgetrouteprogrameventworkorders] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[pgetrouteprogrameventworkorders] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[pquickpostinggetlist]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pquickpostinggetlist]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[pquickpostinggetlist] AS' 
END
GO


/***************************************************************************\
	APPLICATION:    BOSS                     
	SUBSYSTEM:      Data Database / Core WebSite                      
	PURPOSE:        Gets available QuickPost (QP) spreadsheets
****************************************************************************
	CHANGE HISTORY:                               
 
	06/10/2018	jkd - Created          	

\***************************************************************************/

-----&* add IF EXISTS
ALTER PROCEDURE [dbo].[pquickpostinggetlist]
	@companyid int,
	@branchid int,
	@smonth	int,
	@syear int,
	@bybillingcenter int,
	@day int
AS
BEGIN

set 		@companyid = 1
set 		@branchid = 23
set 		@smonth = 5
set 		@syear = 2018
set 		@bybillingcenter = 0
set 		@day = 6

exec pcbgetbillinglist	@companyid=@companyid, @branchid=@branchid, 
						@smonth=@smonth, @day=@day, @syear=@syear, @bybillingcenter=@bybillingcenter
END
GO

ALTER AUTHORIZATION ON [dbo].[pquickpostinggetlist] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[pquickpostinggetlist] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[preport_accountgroupsummary_OC]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[preport_accountgroupsummary_OC]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[preport_accountgroupsummary_OC] AS' 
END
GO


/***************************************************************************\
*                                                                          *
* MODULE:         preport_accountgroupsummary_oc                           *
*                                                                          *
* APPLICATION:    ServSuite                                                *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
* CHANGE HISTORY:                                                          *
*   08/13/2018 jkd --- tfs 101393 OrkinCanada columns to export            *
*                                                                          *
\***************************************************************************/



ALTER PROCEDURE [dbo].[preport_accountgroupsummary_OC]

	 @accountgroupname as nvarchar(200),
	 @month as int,
	 @year as int,
	 @loginid int,
	 @languageid int,
	 @companyid int=-1,
	 @sortby nvarchar(100)

as 
begin

declare @startdate datetime = cast(cast(@month as nvarchar(10))+'/'+'01'+'/'+cast(@year as nvarchar(10)) as datetime)
declare @asofdate datetime = dateadd(s,-1,dateadd(mm, datediff(m,0,@startdate)+1,0))
declare @beginningofyear datetime = (cast(cast(@year as nvarchar) + '-01-01' as datetime))

if @companyid = -1
begin
	select top 1 @companyid=companyid from taccount
end

declare @addformat nvarchar(100)
set @addformat='[1] [2] [3] [4] [5] [6] [7] [8]'

declare @branchid int
set @branchid = -999


---------------------get branches
SELECT branchid
INTO #accountgroupbranches
FROM fnGetBranchesByUser(@branchID , @loginid, @companyid) 


--------------------process account groups
declare @accountgroupnamesplit varchar(100)
declare @comma int


select @accountgroupname = upper(@accountgroupname)
if @accountgroupname = '-999'
begin
	select @accountgroupnamesplit = @accountgroupname
end
else
begin
	select @comma = charindex('-', @accountgroupname)
	select @accountgroupnamesplit = ltrim(substring(@accountgroupname,@comma + 1,999))
end




---------------------get accounts
create table #accountgrouptmpaccounts (accountid integer, accountgroupname varchar(200))

if @accountgroupname <> '-999'
begin
	insert into #accountgrouptmpaccounts	
	select ag.accountid, ag.attributevalue as accountgroupname from taccountsettings ag
	WHERE 
		(@accountgroupnamesplit =  ag.attributevalue and ag.attributename = 'AccountGroupName')
end 

create index ix_tmpaccounts_accountid on #accountgrouptmpaccounts(accountid)


---------------------get programs
--Due to duplicate woeventids pointing to the same invoice, we need to only grab the distinct set of records
select distinct
	acct.companyid
	,tbr.branchid
	,acct.accountid
	,est.siteid
	,prog.programid
	,prog.programtypeid
	,prog.saledate
	,prog.canceldate
	,woh.woheaderid
	,woe.woeventid
	,woe.completeddate
	,(ii.SubTotal + ii.FedTax + ii.StateTax) as billamount
into #tmpprograms
from tinvoice inv
INNER JOIN
	(
	SELECT 
		ii.invoiceid,
		SUM(ii.subtotalregular) AS SubTotal,
		SUM(ii.fedtaxregular) AS FedTax, 
		SUM(ii.statetaxregular) AS StateTax,
		SUM(ii.localtaxregular) AS LocalTax
	FROM 
		tinvoiceitem ii 
	WHERE ii.itemtype != 1 --We do not want to record material cost (0 - production, 1 - material, 2 - labor). material cost go into a separate bucket.
	GROUP BY 
		ii.invoiceid
	) ii ON inv.invoiceid = ii.invoiceid AND (inv.invoiceDate >= @startdate AND inv.invoiceDate <= @asofdate)
inner join tprogram prog on inv.programid = prog.programid
inner join testimate est on est.estimateid = prog.estimateid
inner join taccount acct on acct.accountid = est.accountid and acct.companyid = @companyId
inner join #accountgroupbranches tbr on tbr.branchid = est.servicecenter
left join #accountgrouptmpaccounts ta on ta.accountid = acct.accountid
inner join	taccountsettings agname	on agname.accountid = acct.accountid
	and agname.attributename = 'AccountGroupName'
	and agname.attributevalue <> ''
left join tworkorderheader woh on woh.programid = prog.programid and woh.woheaderid = inv.referenceid and inv.itemtype = 0
left join tworkorderevent woe on woe.headerid = woh.woheaderid
where
		prog.canceldate is null 
		and
		(@accountgroupname = '-999' or est.accountid = ta.accountid)

create index ix_tmpprograms_programid on #tmpprograms(programid)

---------------------get program counts
select tp.programid, max(pse.visitsperyear) visitsperyear
into #tmprecurringprograms
from  #tmpprograms					tp
left  join tevent					e		on e.programid			= tp.programid
left  join tprogramsetupevent		pse		on pse.programtypeid	= tp.programtypeid 
											and pse.eventtypeid		= e.eventtypeid
group by tp.programid

create index ix_tmprecurringprograms_programid on #tmprecurringprograms(programid)

---------------------get MATERIAL counts
create table #tmpmaterialamount (programid int, woheaderid int, materialamount float)

insert into #tmpmaterialamount
--Due to duplicate woeventids pointing to the same invoice, we need to only grab the distinct set of records
select distinct data.programid, data.woheaderid, data.materialamount
from
(
	select prog.programid, woh.woheaderid,(ii.SubTotal + ii.FedTax + ii.StateTax) materialamount
	from tinvoice inv
	INNER JOIN
		(
		SELECT 
			ii.invoiceid,
			SUM(ii.subtotalregular) AS SubTotal,
			SUM(ii.fedtaxregular) AS FedTax,
			SUM(ii.statetaxregular) AS StateTax,
			SUM(ii.localtaxregular) AS LocalTax
		FROM 
			tinvoiceitem ii
		WHERE ii.itemtype = 1 --We only want to record material cost (0 - production, 1 - material, 2 - labor). All other cost go into a separate bucket.
		GROUP BY 
			ii.invoiceid
		) ii ON inv.invoiceid = ii.invoiceid AND (inv.invoiceDate >= @startdate AND inv.invoiceDate <= @asofdate)
	inner join tprogram prog on inv.programid = prog.programid
	inner join testimate est on est.estimateid = prog.estimateid
	inner join taccount acct on acct.accountid = est.accountid and acct.companyid = @companyId
	inner join #accountgroupbranches tbr on tbr.branchid = est.servicecenter
	left join #accountgrouptmpaccounts ta on ta.accountid = acct.accountid
	inner join	taccountsettings agname	on agname.accountid = acct.accountid
		and agname.attributename = 'AccountGroupName'
		and agname.attributevalue <> ''
	left join tworkorderheader woh on woh.programid = prog.programid and woh.woheaderid = inv.referenceid and inv.itemtype = 0
	left join tworkorderevent woe on woe.headerid = woh.woheaderid
	inner join tworkordermaterial wom on wom.woeventid = woe.woeventid
	where wom.invoiceamount > 0
		and prog.canceldate is null 
		and (@accountgroupname = '-999' or est.accountid = ta.accountid)
) as data

create index ix_tmpmaterial_programid on #tmpmaterialamount(programid)

---------------------------Get distinct programs

select distinct programid,accountid, siteid into #tmpdistinctprograms from #tmpprograms

---------------------------Get recurring work order count

select
	ProgramID								= tmpprog.programid
	,WorkOrderNumber						= tmpprog.woheaderid
	,WorkOrderAmount						= sum(tmpprog.billamount)

into		#tmprecurringworkorders
from		#tmpprograms			tmpprog
inner join	#tmprecurringprograms	trecprog			on trecprog.programid		= tmpprog.programid
														and trecprog.visitsperyear > 0
group by tmpprog.programid, tmpprog.woheaderid

create index ix_tmprecurringworkorders_programid on #tmprecurringworkorders(programid)

---------------------------Get ODD JOB count

select
	ProgramID								= tmpprog.programid
	,WorkOrderNumber						= tmpprog.woheaderid
	,WorkOrderAmount						= sum(tmpprog.billamount)

into		#tmpoddjobworkorders
from		#tmpprograms			tmpprog
inner join	#tmprecurringprograms	trecprog			on trecprog.programid		= tmpprog.programid
														and trecprog.visitsperyear  = 0
group by tmpprog.programid, tmpprog.woheaderid

create index ix_tmpoddjobworkorders_programid on #tmpoddjobworkorders(programid)


---------------------------Get CALLBACK count

Declare @callbackeventtypeid int
select TOP 1 @callbackeventtypeid = eventtypeid from teventsetupname where upper(eventname) = 'CALLBACK'

select
	ProgramID								= tmpprog.programid
	,WorkOrderNumber						= tmpprog.woheaderid

into		#tmpcallbackworkorders
from		#tmpprograms		tmpprog
inner join  tworkorderevent		woe		on woe.headerid				= tmpprog.woheaderid
inner join	tevent				ev		on ev.eventid				= woe.baseeventid
										and ev.eventtypeid			= @callbackeventtypeid

group by tmpprog.programid, tmpprog.woheaderid

create index ix_tmpcallbackworkorders_programid on #tmpcallbackworkorders(programid)

---------------------------Get Adjustments
create table #tmpallcreditamounts (programid integer, creditamount money)

---------------------------Get TAX credits
insert into #tmpallcreditamounts (programid, creditamount)
select 
	programid		= tprog.programid
	,creditamount	=sum(tpi.amount)
	
from #tmpprograms tprog
inner join	tpaymentitem		tpi			on tpi.programid			= tprog.programid
											and tpi.istaxcredit			= 1

inner join	tpayment			tp			on tp.paymentid				= tpi.headerid
											and tp.datereceived between @startdate and @asofdate
group by tprog.programid	

---------------------------Get COMMON credits
insert into #tmpallcreditamounts (programid, creditamount)
select 
	programid		= tprog.programid
	,creditamount	=sum(tpi.amount)

from #tmpprograms tprog

inner join	tpaymentitem		tpi			on tpi.programid			= tprog.programid

inner join	tpayment			tp			on tp.paymentid				= tpi.headerid
											-----GIVE ALL CREDITS  ---and tp.datereceived between @startdate and @asofdate
where tp.rectype = 2 
group by tprog.programid

---------------------------Get DISCOUNTS(1), PAYMENT REVESALS(-1), NSF(-3) and REFUND (-4) credits
insert into #tmpallcreditamounts (programid, creditamount)
select 
	programid		= tprog.programid
	,creditamount	=sum(tpi.amount)

from #tmpprograms tprog

inner join	tpaymentitem		tpi			on tpi.programid			= tprog.programid

inner join	tpayment			tp			on tp.paymentid				= tpi.headerid
											-----GIVE ALL CREDITS  ---and tp.datereceived between @startdate and @asofdate
where tp.rectype in (1, -1, -3) and tpi.istaxcredit = 0 
group by tprog.programid

create index ix_tmpallcreditamounts_programid on #tmpallcreditamounts(programid)


---------------------------COMBINE the credits
select programid, sum(creditamount) creditamount into #tmpprogramcreditamounts from #tmpallcreditamounts
group by programid
create index ix_tmpprogramcreditamounts_programid on #tmpprogramcreditamounts(programid)

---------------------------Get the NEW contracts
select distinct
	AccountGroupCode						= cast (isnull(agcode.attributevalue,'') as varchar(250))
	,AccountGroupName						= cast (isnull(agname.attributevalue,'') as varchar(250))
	,programid								= tmpprog.programid
	,billamount								= (ii.SubTotal + ii.FedTax + ii.StateTax)
into #tmpnewbusiness
from tinvoice inv
INNER JOIN
	(
	SELECT 
		ii.invoiceid,
		SUM(ii.subtotalregular) AS SubTotal,
		SUM(ii.fedtaxregular) AS FedTax, 
		SUM(ii.statetaxregular) AS StateTax,
		SUM(ii.localtaxregular) AS LocalTax
	FROM 
		tinvoiceitem ii
	WHERE ii.itemtype != 1
	GROUP BY 
		ii.invoiceid
	) ii ON inv.invoiceid = ii.invoiceid AND (inv.invoiceDate >= @startdate AND inv.invoiceDate <= @asofdate)
inner join #tmpprograms tmpprog on inv.programid = tmpprog.programid
left join taccountsettings agcode on agcode.accountid = tmpprog.accountid
	and agcode.attributename	= 'AccountGroupCode'
left join taccountsettings agname on agname.accountid = tmpprog.accountid
	and agname.attributename	= 'AccountGroupName'
left join tworkorderheader woh on woh.programid = tmpprog.programid and woh.woheaderid = inv.referenceid and inv.itemtype = 0
left join tworkorderevent woe on woe.headerid = woh.woheaderid
where
	   woe.completeddate IS NOT NULL
	   and woe.completeddate between @startdate AND @asofdate
	   and woe.billamount <> 0

create index ix_tmpnewbusiness_programid on #tmpnewbusiness(accountgroupcode, accountgroupname)
---------------------------Get price adjustments by program
select 
	tmpprog.programid
	,effectivedate=evh.effectivedate
	,annualvalue=isnull(evh.annualvalue,0)
into #tmppriceadjustments
from #tmpprograms tmpprog
inner join eventvaluehistory evh	on	evh.programid = tmpprog.programid
where isnull(evh.annualvalue,0) <> isnull(evh.oldannualvalue,0)
and isnull(evh.oldannualvalue,0) <> 0
and evh.effectivedate between @startdate and @asofdate

---------------------------Combine new contract and price adjustments
select
	tnb.AccountGroupCode
	,tnb.AccountGroupName
	,tnb.programid
	,tnb.billamount
	,annualvalue	=
				(select top 1 annualvalue from #tmppriceadjustments tadj
				where tadj.programid = tnb.programid
				order by tadj.effectivedate desc)
into #tmpcontractandpriceadjustments
from #tmpnewbusiness tnb

create index ix_tmpcontractandprice_accountgroup on #tmpcontractandpriceadjustments(accountgroupcode, accountgroupname)

---------------------------Combine NEW contracts by ACCOUNT CODE and NAME
select 
	tcpadj.AccountGroupCode
	,tcpadj.AccountGroupName
	,billamount								= sum(tcpadj.billamount)
	,annualvalue							= sum(tcpadj.annualvalue)
into #tmpcontractandpriceadjaccountgroups
from #tmpcontractandpriceadjustments tcpadj
group by tcpadj.accountgroupcode, tcpadj.accountgroupname


create index ix_tmpcontractandpriceadjaccountgroups_accountgroup on #tmpcontractandpriceadjaccountgroups(accountgroupcode, accountgroupname)
---------------------------
---------------------------

---------------------------Combine everything


select 
	AccountGroupCode						= isnull(agcode.attributevalue,'') 
	,AccountGroupName						= isnull(agname.attributevalue,'')
	,IsNationalAccount						= case when isnull(natacct.attributevalue, '0') = '1' then 'True' else 'False' end
	,CustomerSettingsProfileCode			= isnull(ascode.attributevalue,'')
	,SiteNumber								= tmpprog.siteid
	,ProgramID								= tmpprog.programid
	,RecurringProgramID						= trecprog.programid
	,RecurringWorkOrderNumber				= trecwo.workordernumber
	,RecurringWorkOrderAmount				= isnull(trecwo.workorderamount,0)
	,OddJobWorkOrderNumber					= tojwo.workordernumber
	,OddJobWorkOrderAmount					= isnull(tojwo.workorderamount,0)
	,CallbackWorkOrderNumber				= tcbwo.workordernumber
	,CreditAmount							= isnull(tcredits.creditamount,0)

into		#tmpcounts
from		#tmpdistinctprograms	tmpprog

left join	#tmprecurringprograms	trecprog			on trecprog.programid		= tmpprog.programid
														and trecprog.visitsperyear > 0

left join	#tmprecurringworkorders trecwo				on trecwo.programid			= tmpprog.programid
left join	#tmpoddjobworkorders	tojwo				on tojwo.programid			= tmpprog.programid
left join	#tmpcallbackworkorders	tcbwo				on tcbwo.programid			= tmpprog.programid
left join	#tmpprogramcreditamounts tcredits			on tcredits.programid		= tmpprog.programid

left join	taccountsettings		ascode				on ascode.accountid			= tmpprog.accountid
														and ascode.attributename	= 'CustomerSettingsProfileCode'

left join	taccountsettings		asname				on asname.accountid			= tmpprog.accountid
														and asname.attributename	= 'CustomerSettingsProfileName'

left join	taccountsettings		agcode				on agcode.accountid			= tmpprog.accountid
														and agcode.attributename	= 'AccountGroupCode'

left join	taccountsettings		agname				on agname.accountid			= tmpprog.accountid
														and agname.attributename	= 'AccountGroupName'

left join	taccountsettings		natacct				on natacct.accountid		= tmpprog.accountid
														and natacct.AttributeName	='IsNationalAccountCustomer'


create table #tmpnewbusinessrpt
	(Date datetime, RegionCode nvarchar(max), branchname nvarchar(max), programsalesrep nvarchar(max), routeid nvarchar(max)
	,CategoryType nvarchar(max), ProgramName nvarchar(max), SaleDate datetime, programsalevalue decimal(38,2), AnnualValue decimal(38,2)
	,accountnum int, siteid int, BusinessName nvarchar(max), siteaddress nvarchar(max), AccountGroupName nvarchar(max)
	,CustomerSettingsProfileName nvarchar(max),IsNationalAccount nvarchar(max), NoOfMonthServiced int, propertytypename nvarchar(max)
	,ChangedBy nvarchar(max))

insert into #tmpnewbusinessrpt
Exec preport_pcnewbusiness_oc @companyid, @accountgroupname, @beginningofyear, @asofdate, @loginid, @languageid

---------------------------COMPLETE THE REPORT - add reference names


select

	AccountGroupCode						= tc.accountgroupcode
	,AccountGroupName						= tc.accountgroupname
	,IsNationalAccount						= max(tc.isnationalaccount)
	,CustomerSettingsProfileCodeCount		= count(distinct tc.customersettingsprofilecode) ---br7
	,SiteCount								= count(distinct tc.sitenumber)                 ---br8
	,ActiveProgramCount						= count(distinct tc.programid)                  ---br9
	,RecurringServiceCount					= count(distinct tc.recurringprogramid)         ---br10

	,WorkOrderCount							= count(distinct tc.recurringworkordernumber)   ---br11
	,WorkOrderTotalAmount					= sum(tc.recurringworkorderamount)

	,OddJobCount							= count(distinct tc.oddjobworkordernumber)  ----br13
	,OddJobTotalAmount						= sum(tc.oddjobworkorderamount)

	,ProductSalesCount						= (select count(*) from #tmpmaterialamount)
	,ProductSalesAmount						= isnull((select sum(materialamount) from #tmpmaterialamount),0)
	,CreditsTotal							= sum(tc.creditamount)

	,NewBusinessWorkOrderCount				= (select count(*) from #tmpnewbusinessrpt where AnnualValue != 0 and NoOfMonthServiced >=6)
	,NewBusinessTotalAmount					= isnull(cast((select sum(AnnualValue / NoOfMonthServiced * MonthDifference) from (select AnnualValue, NoOfMonthServiced, (month(@startdate) - month(SaleDate) + 1) as MonthDifference from #tmpnewbusinessrpt where AnnualValue != 0 and NoOfMonthServiced >=6) as data) as decimal(38,2)),0)

	,CallBackCount							= count(distinct tc.callbackworkordernumber)
	,CallBackRecurringCount					= 0
	,InvoiceTotalAmount						= sum(tc.oddjobworkorderamount) + sum(tc.recurringworkorderamount) + isnull((select sum(materialamount) from #tmpmaterialamount),0)


from #tmpcounts								tc

left join  #tmpcontractandpriceadjaccountgroups
											tcpadj
												on tcpadj.accountgroupcode		= tc.accountgroupcode
												and tcpadj.accountgroupname		= tc.accountgroupname

group by tc.AccountGroupCode, tc.AccountGroupName
order by tc.AccountGroupCode, tc.AccountGroupName

drop table #tmpnewbusinessrpt

end
GO

ALTER AUTHORIZATION ON [dbo].[preport_accountgroupsummary_OC] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[preport_accountgroupsummary_OC] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[preport_payrollcommissionaccrual_OC]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[preport_payrollcommissionaccrual_OC]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[preport_payrollcommissionaccrual_OC] AS' 
END
GO


/***************************************************************************\
*                                                                          *
* MODULE:         preport_payrollcommissionaccrual_OC                      *
*                                                                          *
* APPLICATION:    ServSuite                                                *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
* CHANGE HISTORY:                                                          *
*   09/20/2018 jkd --- tfs 110921 OrkinCanada columns to export            *
*                                                                          *
\***************************************************************************/

ALTER PROCEDURE [dbo].[preport_payrollcommissionaccrual_OC]
 @pmonth int,
 @pyear  int,
 @ploginid int,
 @pcompanyid int,
 @planguageid int


AS BEGIN



declare @startDate Date
declare @tempDateString varchar(20)

set @tempDateString = cast(@pmonth as varchar) + '/01/' + cast(@pyear as varchar)
select @startDate  = @tempDateString

declare @operationalperiodid int
select	@OperationalPeriodID = OperationalPeriodID 
from	OperationalElements.OperationalPeriod 
where	startdate = @startDate


-----------------------------------------
select    
	branchnumber					= zc.ZenithBranchNum 
	,employeenumber					= zc.EmployeeNum
	,ProductionAmount				= ROUND(zc.PaidProduction,2)
    ,SalesAmount					= ROUND(zc.PaidProductSalesCommission,2) + ROUND(zc.TotalPaidSales ,2)
										+ ROUND(zc.PaidLeads,2) + ROUND(zc.TotalManualAdjustments,2)
	,TotalAmount					= ROUND(zc.TotalCommissionPaid,2)
	,TotalManualAdjustments			= ROUND(zc.TotalManualAdjustments,2)
into  #tmpEmpCommissions
from 
	[ZenithCommissionsIntegrated].[dbo].[CommissionReport]   zc

where
	zc.OperationalPeriodID = @OperationalPeriodID

-----------------------------------------
-----------------------------------------


select
	count(*) count
	,BranchNumber
	,SalesAmount=sum(tec.salesamount)
	,ProductionAmount=sum(tec.ProductionAmount)
into #tmpTotalCommissions
from  #tmpEmpCommissions tec
group by 
	tec.branchnumber



declare @currentDate datetime
declare @glcode varchar(4)
declare @companycode varchar(02)
declare @branchnumber varchar(03)

set @currentDate = getdate()

CREATE TABLE #tmpResults
(
	PostingDate datetime,
	Comment Nvarchar(50) Default('Commission Accrual'),
	AccountKey Nvarchar(50),
	DebitAmount Nvarchar(50) Default(''),
	CreditAmount Nvarchar(50) Default ('')
)

select top 1  @companycode=lobId.Value from  servsuitedata.tcompany company
inner join servsuitedata.entityattribute brandId on company.oplocEntityId = brandId.entityId AND attributeTypeId = 199
inner join servsuitedata.entityattribute lobId on brandId.Value = lobId.EntityId AND lobId.attributeTypeId = 4003
where company.companyid = @pcompanyid

------------------------- 001 TOTAL GL Production Credit
set @glcode = '2302'
select @companycode = isnull(@companycode, '10')
set @branchnumber = '000'

insert into #tmpResults
(PostingDate, Comment, AccountKey, DebitAmount, CreditAmount)
select
	PostingDate=@currentDate 
	,Comment='Commission Accrual'
	,AccountKey=@glcode + @companycode + @branchnumber ----2302 02 000
	,DebitAmount=''
	,CreditAmount=sum(tc.ProductionAmount)
from #tmpTotalCommissions tc


------------------------- 002 TOTAL GL Sales Credit
set @glcode = '2301'
select @companycode = isnull(@companycode, '10')
set @branchnumber = '000'

insert into #tmpResults
(PostingDate, Comment, AccountKey, DebitAmount, CreditAmount)
select
	PostingDate=@currentDate 
	,Comment='Commission Accrual'
	,AccountKey=@glcode + @companycode + @branchnumber ----2301 02 000
	,DebitAmount=''
	,CreditAmount=sum(tc.SalesAmount)
from #tmpTotalCommissions tc

------------------------- 003 branch GL Production Debit
set @glcode = '8020'
select @companycode = isnull(@companycode, '10')
set @branchnumber = 'xxx'

insert into #tmpResults
(PostingDate, Comment, AccountKey, DebitAmount, CreditAmount)
select
	PostingDate=@currentDate 
	,Comment='Commission Accrual'
	,AccountKey=@glcode + @companycode + tc.BranchNumber ----8020 02 xxx
	,DebitAmount=sum(tc.ProductionAmount)
	,CreditAmount=''
from #tmpTotalCommissions tc
group by tc.BranchNumber


------------------------- 004 branch GL Sales Debit
set @glcode = '8021'
select @companycode = isnull(@companycode, '10')
set @branchnumber = 'xxx'

insert into #tmpResults
(PostingDate, Comment, AccountKey, DebitAmount, CreditAmount)
select
	PostingDate=convert(varchar,@currentDate ,111)
	,Comment='Commission Accrual'
	,AccountKey=@glcode + @companycode + tc.BranchNumber ----8021 02 xxx
	,DebitAmount=sum(tc.SalesAmount)
	,CreditAmount=''
from #tmpTotalCommissions tc
group by tc.BranchNumber



select 
	PostingDate=convert(varchar, tr.PostingDate, 101)
	,tr.Comment 
	,tr.AccountKey
	,tr.DebitAmount
	,tr.CreditAmount
from 
	#tmpResults tr


END
GO

ALTER AUTHORIZATION ON [dbo].[preport_payrollcommissionaccrual_OC] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[preport_payrollcommissionaccrual_OC] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[psearchaccountsadvancednew]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[psearchaccountsadvancednew]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[psearchaccountsadvancednew] AS' 
END
GO

/***************************************************************************\
*                                                                          *
* MODULE:         psearchaccountsadvanced                                  *
*                                                                          *
* APPLICATION:    ServSuite                                                *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
*                                                                          *
* AUTHOR:         Generated by SQLScriptingLib                             *
*                                                                          *
* CHANGE HISTORY:                                                          *
*                 12/2/2014 -- Created                                     *
*                                                                          *
*					June 29, 2015 - Robert Frey TFS 34488				   *
\***************************************************************************/
--exec psearchaccountsadvancednew @loginid=9131,@companyid=1,@showaccount=1,@showsite=1,@branchType=1,@BranchIndex=23,@lastname='smith'--,@lastname='tesh'--@lastname='tesh'--,  
ALTER PROCEDURE [dbo].[psearchaccountsadvancednew]
	@loginid INT,
	@companyid INT,
	@streetnumber nvarchar(50) = NULL,
	@streetname nvarchar(50) = NULL,
	@address2 nvarchar(50) = NULL,
	@city nvarchar(50) = NULL,
	@zip nvarchar(50) = NULL,
	@lastname nvarchar(50) = NULL,
	@firstname nvarchar(50) = NULL,
	@companyname nvarchar(50) = NULL,
	@builder nvarchar(50) = NULL,
	@lotnumber nvarchar(50) = NULL,
	@subdivision nvarchar(50) = NULL,
	@showaccount bit,
	@showsite bit,
	@activeonly bit = NULL,
	@branchType int,
	@BranchIndex int,
	@prgAllProgramStatus bit = NULL,
	@prgActive bit = NULL,
	@prgCancel bit = NULL,
	@prgPendingCancel bit = NULL,
	@siteNational bit = NULL,
	@siteResidential bit = NULL,
	@siteCommercial bit = NULL,
	@prgPC bit = NULL,
	@prgTCTB bit = NULL,
	@prgPCTCTB bit = NULL

AS
BEGIN
DECLARE @sql        nvarchar(MAX),                               
        @paramlist  nvarchar(4000)

		CREATE TABLE #temp 
		(
			accountid INT INDEX tmpaccountid
			,siteid INT INDEX siteid
			,contactid INT INDEX contactid
			,phoneid INT INDEX phoneid
			,addressid INT INDEX addressid
			,haspc BIT
			,hastctb BIT
			,branchid INT INDEX branchid
       )

	    CREATE TABLE #tmpAccountsToKeep 
		(
			accountid INT 
		)

		SELECT @sql = 
		N' SET NOCOUNT ON 

		Create table #tmpContacts
			(
				contactid int,
				primaryphoneid int
			)
'

	  --TFS 57516 - prefetch contacts when last name, first name or company name is searched
	  IF ((@firstname is not null) or (@lastname is not null) or (@companyname is not null))
	  BEGIN
		Select @sql = @sql + '
			
			insert into #tmpContacts
			Select
				contactid,
				primaryphoneid
			From tcontact WHERE 1=1 '

			if (@firstname is not null)
			begin
				set @sql = @sql + '
					AND upper(tcontact.firstname) LIKE  @firstname + ''%'''
			end
			if (@lastname is not null)
			begin
				set @sql = @sql + '
					AND upper(tcontact.lastname) LIKE  @lastname + ''%'''
			end
			if (@companyname is not null)
			begin
				set @sql = @sql + '
					AND upper(tcontact.businessname) LIKE  @companyname + ''%'''
			end
	  END
	  
	  Select @sql = @sql + '
	  IF @showaccount=1 BEGIN 
	     INSERT INTO #temp (accountid,siteid,contactid,phoneid,addressid,branchid) 
		 SELECT distinct taccount.accountid, isnull(taccountsite.siteid,0), tc.contactid, 
		    tcontactphonenumber.phoneid,taddress.addressid, taccount.billingcenterid
	     FROM taddress  with (nolock)  INNER JOIN 
		 taccount  with (nolock) ON taddress.addressid = taccount.billingaddressid INNER JOIN 
		 tlogincompanybranch ON taccount.billingcenterid = tlogincompanybranch.branchid  INNER JOIN '

		 if ((@lastname is not null) or (@firstname is not null) or (@companyname is not null))
		 begin
			Select @sql = @sql + '
			#tmpContacts tc on taccount.primarycontactid = tc.contactid
			LEFT JOIN
			tcontactphonenumber ON tcontactphonenumber.phoneid = tc.primaryphoneid
			'
		end
		else
		begin
			Select @sql = @sql + '		 
		 tcontact tc ON taccount.primarycontactid = tc.contactid  
		 LEFT JOIN 
		 tcontactphonenumber  ON tcontactphonenumber.phoneid = tc.primaryphoneid  
		 '
		end

		-- Also pull in the new IsNationalAccountCustomer account setting.  This is only relevant when 'UseCustomerAccountGroups' set to true, but should work when tAccountSettings is empty as well
		select @sql = @sql + '
	    LEFT JOIN taccountsite ON taccountsite.accountid = taccount.accountid 
		LEFT JOIN tsite ON taccountsite.siteid = tsite.siteid
		LEFT JOIN dbo.tAccountSettings tActSetIsNational ON taccount.accountid = tActSetIsNational.AccountID AND tActSetIsNational.AttributeName = ''IsNationalAccountCustomer'' AND tActSetIsNational.AttributeValue=''1''
		'
		 
		 if (@builder is not null) or (@lotnumber is not null) or (@subdivision is not null)
		 begin
		     SELECT @sql = @sql + ' LEFT JOIN tbuilder on tsite.builderid = tbuilder.builderid  
			                        LEFT JOIN tcontact bc ON tbuilder.primarycontactid = bc.contactid '
		 end
		 if @branchType = 1
		 begin
			SELECT @sql = @sql + ' INNER JOIN testimate est ON est.siteid = tsite.siteid 
			                        INNER JOIN tlogincompanybranch svccenterbranch on est.servicecenter=svccenterbranch.branchid and svccenterbranch.loginid = @loginid  '
		 end
		 SELECT @sql = @sql + ' WHERE taccount.companyid = @companyid and tlogincompanybranch.loginid=@loginid  '

		 if @branchType = 1 and @branchIndex <> 0
		 begin
		    SELECT @sql = @sql + ' AND est.servicecenter = @branchIndex '
		 end
		 
		 if @activeonly is not null
		 begin
		    SELECT @sql = @sql + ' AND taccount.isactive <> 0 '
		 end

		 /*if @lastname is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tc.lastname) LIKE  @lastname + ''%'''
			--SELECT @sql = @sql + ' AND upper(tcontact.lastname) LIKE  N' + quotename(@lastname + '%', '''') 
		 end

		 if @firstname is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tc.firstname) LIKE @firstname + ''%'''
		 end

		 if @companyname is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tc.businessname) LIKE @companyname + ''%'''
		 end*/

		 if @streetnumber is not null
		 begin
		    SELECT @sql = @sql + ' AND taddress.streetnumber = @streetnumber '
		 end

		 if @streetname is not null 
		 begin
		    SELECT @sql = @sql + ' AND upper(taddress.streetname) LIKE @streetname + ''%'''
		 end

		 if @address2 is not null 
		 begin
		    SELECT @sql = @sql + ' AND upper(taddress.secondaryaddress) LIKE @address2 + ''%'''
		 end

		 if @city is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(taddress.city) LIKE @city + ''%'''
		 end

		 if @zip is not null
		 begin
		    SELECT @sql = @sql + ' AND taddress.postalcode LIKE @zip + ''%'''
		 end

		 if @builder is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(bc.businessname) LIKE ''%'' + @builder + ''%'''
		 end

		 if @lotnumber is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tsite.lotnumber) LIKE @lotnumber '
		 end

		 if @subdivision is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tsite.subdivision) LIKE @subdivision + ''%'''
		 end

		 if (@siteNational is not null) or (@siteResidential is not null) or (@siteCommercial is not null)
		 begin
		    SELECT @sql = @sql + ' AND ( '
		    if @siteResidential is not null
			begin
			   SELECT @sql = @sql + ' tsite.propertytype = 1 '
			end

			if @siteCommercial is not null
			begin
			  if (@siteCommercial is not null) and (@siteResidential is not null)
			  begin
			     SELECT @sql = @sql + ' OR tsite.propertytype = 2 '
			  end
			  else
			  begin
			     SELECT @sql = @sql + ' tsite.propertytype = 2 '
			  end
			end

			if @siteNational is not null
			begin
			   if (@siteNational is not null) and ((@siteResidential is not null) or (@siteCommercial is not null))
			   begin
			      SELECT @sql = @sql + ' OR tsite.propertytype = 5 OR tActSetIsNational.AttributeValue=''1'' '
			   end
			   else
			   begin
			      SELECT @sql = @sql + ' tsite.propertytype = 5 OR tActSetIsNational.AttributeValue=''1'' '
			   end
			end
			SELECT @sql = @sql + ' ) '
		 end

		 if @branchType = 2
		 begin
		     SELECT @sql = @sql + ' AND taccount.billingcenterid = @BranchIndex '
		 end

		 SELECT @sql = @sql + ' END '

		 SELECT @sql = @sql + ' IF @showsite = 1 BEGIN 
		                        INSERT INTO #temp (accountid,siteid,contactid,phoneid,addressid, branchid) 
								SELECT distinct taccountsite.accountid,tsite.siteid,tsite.primarycontactid, 
								isnull(tcontactphonenumber.phoneid, 0),taddress.addressid,0 
								FROM taccountsite INNER JOIN 
								taccount a on a.accountid=taccountsite.accountid INNER JOIN 
								tlogincompanybranch on a.billingcenterid=tlogincompanybranch.branchid INNER JOIN 
								tsite  with (nolock)  ON taccountsite.siteid = tsite.siteid INNER JOIN 
								taddress  with (nolock)  ON tsite.addressid = taddress.addressid INNER JOIN 
								'
								if ((@lastname is not null) or (@firstname is not null) or (@companyname is not null))
								begin
									select @sql = @sql + '
									#tmpContacts tc on tsite.primarycontactid = tc.contactid LEFT JOIN
									tcontactphonenumber ON tc.primaryphoneid = tcontactphonenumber.phoneid'
								end
								else
								begin
									select @sql = @sql + '
									tcontact tc ON tsite.primarycontactid = tc.contactid LEFT JOIN 
									tcontactphonenumber ON tc.primaryphoneid = tcontactphonenumber.phoneid '
								end


								

		 if @builder is not null
		 begin
		    SELECT @sql = @sql + ' LEFT JOIN tbuilder ON tsite.builderid = tbuilder.builderid 
			                       LEFT JOIN tcontact bc ON tbuilder.primarycontactid = bc.contactid '
		 end

		 if @branchType = 1
		 begin
		    SELECT @sql = @sql + ' INNER JOIN testimate est ON est.siteid = tsite.siteid 
			                       INNER JOIN tlogincompanybranch svccenterbranch on est.servicecenter=svccenterbranch.branchid and svccenterbranch.loginid = @loginid '
		 end

		-- Also pull in the new IsNationalAccountCustomer account setting.  This is only relevant when 'UseCustomerAccountGroups' set to true, but should work when tAccountSettings is empty as well
		 SELECT @sql = @sql + ' LEFT JOIN dbo.tAccountSettings tActSetIsNational ON a.accountid = tActSetIsNational.AccountID AND tActSetIsNational.AttributeName = ''IsNationalAccountCustomer'' AND tActSetIsNational.AttributeValue = ''1'' '

		 SELECT @sql = @sql + ' WHERE taddress.companyid = @companyid and tlogincompanybranch.loginid=@loginid  '

		 if  @activeonly is not null
		 begin
		    SELECT @sql = @sql + ' AND a.isactive <> 0 '
		 end

		 /*if @lastname is not null
		 begin 
		    SELECT @sql = @sql + ' AND upper(tc.lastname) LIKE  @lastname + ''%'''
		    --SELECT @sql = @sql + ' AND upper(tcontact.lastname) LIKE  N' + quotename(@lastname + '%', '''') 
		 end*/
		 
		 if @branchType = 1 and @branchIndex <> 0
		 begin
		    SELECT @sql = @sql + ' AND est.servicecenter = @branchIndex '
		 end

		 
		 /*if @firstname is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tc.firstname) LIKE @firstname + ''%'''
		 end

		 if @companyname is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tc.businessname) LIKE @companyname + ''%'''
		 end*/

		 if @streetnumber is not null 
		 begin
		    SELECT @sql = @sql + ' AND taddress.streetnumber = @streetnumber '
		 end

		 if @streetname is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(taddress.streetname) LIKE @streetname + ''%'''
		 end

		 if @address2 is not null 
		 begin
		    SELECT @sql = @sql + ' AND upper(taddress.secondaryaddress) LIKE @address2 + ''%'''
		 end

		 if @city is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(taddress.city) LIKE @city + ''%'''
		 end

		 if @zip is not null
		 begin
		    SELECT @sql = @sql + ' AND taddress.postalcode LIKE @zip + ''%'''
		 end

		 if @builder is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(bc.businessname) LIKE ''%'' + @builder + ''%'''
		 end

		 if @lotnumber is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tsite.lotnumber) LIKE @lotnumber '
		 end

		 if @subdivision is not null
		 begin
		    SELECT @sql = @sql + ' AND upper(tsite.subdivision) LIKE @subdivision + ''%'''
		 end

		 if (@siteNational is not null) or (@siteResidential is not null) or (@siteCommercial is not null)
		 begin
		    SELECT @sql = @sql + ' AND ( '
		    if @siteResidential is not null
			begin
			   SELECT @sql = @sql + ' tsite.propertytype = 1 '
			end

			if @siteCommercial is not null
			begin
			  if (@siteCommercial is not null) and (@siteResidential is not null)
			  begin
			     SELECT @sql = @sql + ' OR tsite.propertytype = 2 '
			  end
			  else
			  begin
			     SELECT @sql = @sql + ' tsite.propertytype = 2 '
			  end
			end

			if @siteNational is not null
			begin
			   if (@siteNational is not null) and ((@siteResidential is not null) or (@siteCommercial is not null))
			   begin
			      SELECT @sql = @sql + ' OR tsite.propertytype = 5  OR tActSetIsNational.AttributeValue=''1'' '
			   end
			   else
			   begin
			      SELECT @sql = @sql + ' tsite.propertytype = 5  OR tActSetIsNational.AttributeValue=''1'' '
			   end
			end
			SELECT @sql = @sql + ' ) '
		 end

		 if @branchType = 2
		 begin
		     SELECT @sql = @sql + ' AND taccount.billingcenterid = @BranchIndex '
		 end

		 SELECT @sql = @sql + ' END '

		 if (@prgActive is not null) or (@prgCancel is not null) or (@prgPendingCancel is not null) or (@prgAllProgramStatus is not null)
		 begin
		    
			if ((@prgActive is not null) or (@prgAllProgramStatus is not null))
					begin
						Select @sql = @sql + 'Insert into #tmpAccountsToKeep select tmp.accountid from #temp tmp
									left join testimate e on e.siteid = tmp.siteid 
									left join tprogram p on p.estimateid = e.estimateid
									where p.programid is not null and p.canceldate is null AND p.pendingcanceldate is null '
					end
			
				if ((@prgCancel is not null) or (@prgAllProgramStatus is not null))
					begin
						Select @sql = @sql + 'Insert into #tmpAccountsToKeep select tmp.accountid from #temp tmp
									left join testimate e on e.siteid = tmp.siteid 
									left join tprogram p on p.estimateid = e.estimateid
									where p.programid is not null and p.canceldate is not null '
					end

				if ((@prgPendingCancel is not null) or (@prgAllProgramStatus is not null))
					begin
						Select @sql = @sql + 'Insert into #tmpAccountsToKeep select tmp.accountid from #temp tmp
									left join testimate e on e.siteid = tmp.siteid 
									left join tprogram p on p.estimateid = e.estimateid
									where p.programid is not null and p.pendingcanceldate is not null and p.canceldate is null'
					end

				  SELECT @sql = @sql + ' delete tmp 
			                       from #temp tmp 
								   left join testimate e on e.siteid = tmp.siteid 
								   left join tprogram p on p.estimateid = e.estimateid 
								   where tmp.accountid not in 
								   (Select distinct accountid from #tmpAccountsToKeep) '
		 end

		 SELECT @sql = @sql + ' ;WITH counts AS 
		                        ( 
								    SELECT 
									      tmp.accountid, 
									      pccount = SUM(CASE WHEN ps.reportcategory = 1 THEN 1 ELSE 0 END), 
										  tctbcount = SUM(CASE WHEN ps.reportcategory = 3 THEN 1 ELSE 0 END) 
								    FROM
									     #temp tmp 
										 INNER JOIN testimate e ON e.siteid = tmp.siteid 
										 INNER JOIN tprogram p ON p.estimateid = e.estimateid 
										 INNER JOIN tprogramsetup ps ON ps.programtypeid = p.programtypeid 
								     GROUP BY tmp.accountid 
								) 
								UPDATE #temp 
								SET haspc = CASE WHEN c.pccount > 0 THEN 1 ELSE 0 END, 
								    hastctb = CASE WHEN c.tctbcount > 0 THEN 1 ELSE 0 END 
								FROM #temp tmp 
								     INNER JOIN counts c ON c.accountid = tmp.accountid '

		if (@prgPC is not null) or (@prgTCTB is not null) or (@prgPCTCTB is not null)
		begin
		    SELECT @sql = @sql + ' DELETE 
			                       FROM #temp 
								   WHERE (haspc = 0 AND hastctb = 0) OR (haspc IS NULL OR hastctb IS NULL) '

			if @prgPC is null
			begin
			   SELECT @sql = @sql + ' OR (haspc = 1 AND hastctb = 0)'
			end

			if @prgTCTB is null
			begin
			   SELECT @sql = @sql + ' OR (haspc = 0 AND hastctb = 1)'
			end

			if @prgPCTCTB is null
			begin
			   SELECT @sql = @sql + ' OR (haspc = 1 AND hastctb = 1)'
			end

		end

		SELECT @sql = @sql + ' IF @showaccount=1 AND @showsite = 0 BEGIN 
		                       
							   SELECT DISTINCT  taccount.accountnum,taccount.isactive, b.branchname, 0 as siteid, isnull(max(tcontact.firstname),'''') as firstname,isnull(max(tcontact.lastname),'''') as lastname, 
							         isnull(max(tcontact.businessname),'''') as businessname,max(taddress.streetnumber) as streetnumber,
									 max(taddress.predirection) as predirection ,isnull(max(taddress.streetname),'''') as streetname,max(taddress.streetsuffix) as streetsuffix,max(taddress.postdirection) as postdirection, 
									 isnull(max(taddress.city),'''') as city,isnull(max(taddress.state),'''') as state,max(taddress.postalcode) as postalcode,isnull(taccount.mysearch,'''') as mysearch,taccount.accountid, 
									 isnull(max(tsite.lotnumber),'''') as lotnumber, haspc=CONVERT(BIT,ISNULL(haspc,0)), hastctb=CONVERT(BIT,ISNULL(hastctb,0)), taccount.jdeaccountid
							   FROM #temp INNER JOIN taccount ON #temp.accountid = taccount.accountid 
							   LEFT JOIN tcontact ON #temp.contactid = tcontact.contactid 
							   LEFT JOIN taddress ON #temp.addressid = taddress.addressid 
							   LEFT JOIN taccountsite ON taccountsite.accountid=taccount.accountid 
							   LEFT JOIN tsite ON (taccountsite.siteid = tsite.siteid and tsite.addressid=taddress.addressid ) 
							   LEFT JOIN tbranch b ON (taccount.billingcenterid = b.branchid) 
							   '
		if @branchType = 1
		begin
		   SELECT @sql = @sql + ' LEFT JOIN testimate est ON est.accountid = taccount.accountid '

		   if @BranchIndex <> 0
		   begin
		      SELECT @sql = @sql + ' AND est.servicecenter = @BranchIndex '
		   end

		   SELECT @sql = @sql + ' GROUP BY  taccount.accountnum, #temp.siteid, tcontact.firstname, tcontact.lastname,
		                                     tcontact.businessname, taddress.streetnumber, taddress.predirection, taddress.streetname, taddress.streetsuffix, taddress.postdirection, taddress.city, taddress.state, taddress.postalcode, taccount.mysearch, taccount.accountid, taccount.isactive, haspc, hastctb, b.branchname, taccount.jdeaccountid  
											 HAVING count(est.servicecenter) > 0  '
		end
		else
		begin
		   if @branchType = 2
		   begin
		      SELECT @sql = @sql + ' WHERE taccount.billingcenterid = @BranchIndex '
		   end
		   
		   SELECT @sql = @sql + ' GROUP BY taccount.accountid, taccount.isactive,taccount.accountnum,taccount.mysearch, haspc, hastctb,b.branchname, taccount.jdeaccountid  '

		   SELECT @sql = @sql + ' ORDER BY taccount.accountnum '
		end

		SELECT @sql = @sql + ' END ELSE BEGIN 
		
		            SELECT DISTINCT  taccount.accountnum,taccount.isactive, case when billingbranch.branchname is not null and @showaccount = 1 then billingbranch.branchname else isnull(b.branchname,'''') end as branchname, case when #temp.branchid = 0 then #temp.siteid else 0 end as siteid, isnull(tcontact.firstname,'''') as firstname,isnull(tcontact.lastname,'''') as lastname, 
					        isnull(tcontact.businessname,'''') as businessname,taddress.streetnumber, 
							taddress.predirection,isnull(taddress.streetname,'''') as streetname,taddress.streetsuffix,taddress.postdirection,
							isnull(taddress.city,'''') as city,isnull(taddress.state,'''') as state,taddress.postalcode,isnull(taccount.mysearch,'''') as mysearch,taccount.accountid, 
							isnull(max(tsite.lotnumber),'''') as lotnumber, haspc=CONVERT(BIT,ISNULL(haspc,0)), hastctb=CONVERT(BIT,ISNULL(hastctb,0)), taccount.jdeaccountid
					FROM #temp INNER JOIN taccount ON #temp.accountid = taccount.accountid 
					LEFT JOIN tcontact ON #temp.contactid = tcontact.contactid 
					LEFT JOIN taddress ON #temp.addressid = taddress.addressid 
					LEFT JOIN taccountsite ON taccountsite.accountid=taccount.accountid 
					LEFT JOIN tsite ON (taccountsite.siteid = tsite.siteid and tsite.addressid=taddress.addressid ) 
					LEFT JOIN testimate est ON est.siteid = tsite.siteid 
					LEFT JOIN tbranch b ON (est.servicecenter = b.branchid) 
					LEFT JOIN tbranch billingbranch ON (#temp.branchid = billingbranch.branchid) 
					'
        if @branchType = 1
		begin
		   if @BranchIndex <> 0
		   begin
		      SELECT @sql = @sql + ' AND est.servicecenter = @BranchIndex '
		   end

		   SELECT @sql = @sql + ' GROUP BY  taccount.accountnum,taccount.isactive, #temp.siteid, tcontact.firstname, tcontact.lastname,tcontact.businessname, taddress.streetnumber, 
		                                    taddress.predirection,taddress.streetname, taddress.streetsuffix,taddress.postdirection,taddress.city, taddress.state, taddress.postalcode,taccount.mysearch, taccount.accountid, haspc, hastctb, b.branchname, billingbranch.branchname, #temp.branchid, taccount.jdeaccountid  
											HAVING (count(est.servicecenter) > 0 or billingbranch.branchname is not null)  '
		end
		else
		begin
		   if @branchType = 2
		   begin
		      SELECT @sql = @sql + ' WHERE taccount.billingcenterid = @BranchIndex '
		   end

		   SELECT @sql = @sql + ' GROUP BY taccount.accountid, taccount.isactive,taccount.accountnum,  tcontact.firstname, tcontact.lastname, 
		                                   tcontact.businessname, #temp.siteid, 
										   taddress.streetnumber, taddress.predirection, taddress.streetname, 
										   taddress.streetsuffix, taddress.postdirection,taddress.city, taddress.state, 
										   taddress.postalcode,taddress.postalcodeex,taccount.mysearch, haspc, hastctb, b.branchname, billingbranch.branchname, #temp.branchid, taccount.jdeaccountid '
		end

		SELECT @sql = @sql + ' ORDER BY taccount.accountnum 
		
		 END  
		 
		 SET NOCOUNT OFF '

		 SELECT @paramlist = N'  @loginid INT,
								@companyid INT,
								@streetnumber nvarchar(100),
								@streetname nvarchar(50),
								@address2 nvarchar(50),
								@city nvarchar(50),
								@zip nvarchar(50),
								@lastname nvarchar(50),
								@firstname nvarchar(50),
								@companyname nvarchar(50),
								@builder nvarchar(50),
								@lotnumber nvarchar(50),
								@subdivision nvarchar(50),
								@showaccount bit,
								@showsite bit,
								@activeonly bit,
								@branchType int,
								@BranchIndex int,
								@prgActive bit,
								@prgCancel bit,
								@prgPendingCancel bit,
								@siteNational bit,
								@siteResidential bit,
								@siteCommercial bit,
								@prgPC bit,
								@prgTCTB bit,
								@prgPCTCTB bit '

		                                                                   
       EXEC sp_executesql @sql, @paramlist,
		                   @loginid, @companyid, @streetnumber, @streetname, @address2, @city, @zip, @lastname, @firstname, @companyname, @builder,
						   @lotnumber, @subdivision, @showaccount, @showsite, @activeonly, @branchType, @BranchIndex, @prgActive,
						   @prgCancel,@prgPendingCancel, @siteNational, @siteResidential, @siteCommercial, @prgPC, @prgTCTB, @prgPCTCTB

END
GO

ALTER AUTHORIZATION ON [dbo].[psearchaccountsadvancednew] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[psearchaccountsadvancednew] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[psitegetpage]    Script Date: 10/13/2021 12:39:04 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[psitegetpage]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[psitegetpage] AS' 
END
GO

/***************************************************************************\
*                                                                          *
* MODULE:         psitegetpage                                      *
*                                                                          *
* APPLICATION:    ServSuite                                                *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
*                                                                          *
* AUTHOR:         Generated by SQLScriptingLib                             *
*                                                                          *
* CHANGE HISTORY:                                                          *
*                 12/2/2012 -- Created                                     *
*                                                                          *
\***************************************************************************/




ALTER PROCEDURE [dbo].[psitegetpage] 

@accountid int,
@siteid int,
@programserver nvarchar(100),
@programdb nvarchar(100),
@companyid int,
@languageid int

AS

set nocount on
--Displays the account info on the left side of the screen 0
EXEC paccountgetaddress @accountid

--Main site info query 1
EXEC psiteget @siteid

--Site address control info 2
EXEC paddressgetbysite @siteid, @programserver, @programdb, @languageid

--Site contact control info 3
EXEC pcontactgetbysite @siteid

--Dropdowns  4,5
EXEC ppropertytypegetlist @companyid, @languageid
EXEC ptaxtypegetlist @companyid, @languageid


--BUILDER LIST  6
EXEC pbuildergetlist @companyid

--Default values?
--EXEC pcontactgetbyaccount @accountid

select foundationtype, frametype, sidingtype, gradestatus, builderalliancecode, parcelid, acquisitioncode from tsiteoption where siteid = @siteid

-- bugzilla #2040  Get the default tax type of the billing center 1/26/2007 GC
-- default tax type 8
SELECT tbranch.defaulttaxtypeid
FROM taccount INNER JOIN tbranch ON taccount.billingcenterid=tbranch.branchid
WHERE taccount.accountid=@accountid

set nocount off
GO

ALTER AUTHORIZATION ON [dbo].[psitegetpage] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[psitegetpage] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[pupdateinvoiceurchaseorder]    Script Date: 10/13/2021 12:39:05 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[pupdateinvoiceurchaseorder]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[pupdateinvoiceurchaseorder] AS' 
END
GO

/***************************************************************************\
*                                                                          *
* MODULE:         pupdateinvoiceurchaseorder                                    *
*                                                                          *
* APPLICATION:    ServSuite                                                *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
*                                                                          *
* AUTHOR:         Lazar Atanasov                             *
*                                                                          *
* CHANGE HISTORY:                                                          *
*                 04/10/2017 -- Created                                     *
*                                                                          *
\***************************************************************************/

ALTER PROCEDURE [dbo].[pupdateinvoiceurchaseorder]
@invoiceid int
AS
BEGIN

SET NOCOUNT ON

	DECLARE @programid int
	DECLARE @purchaseorder nvarchar(50)
	DECLARE @programpo nvarchar(50)

	SET @programid = isnull((select top 1 invitem.programid from tinvoice inv inner join tinvoiceitem invitem on inv.invoiceid = invitem.invoiceid  where invitem.invoiceid = @invoiceid),0)
	SET @programpo = isnull(
		(
		SELECT TOP 1 LEFT(tprogramponumber.PONumber, 50)
		FROM tprogramponumber
		JOIN tinvoiceitem ON tprogramponumber.programid = tinvoiceitem.programid
		JOIN tinvoice ON tinvoiceitem.invoiceid = tinvoice.invoiceid
		WHERE tinvoiceitem.invoiceid = @invoiceid
		AND tinvoice.invoicedate BETWEEN tprogramponumber.effectivedate AND tprogramponumber.expirationdate
		),
		''
	)

	IF (@programpo <> '' AND @invoiceid > 0)
	BEGIN
		UPDATE tprogram
		SET purchaseorder = @programpo
		WHERE programid = @programid
	END

	IF (@invoiceid > 0)
	BEGIN		
		SET @purchaseorder = isnull((select isnull(purchaseorder,'') from tprogram where programid = @programid),'')

		UPDATE tinvoice
		SET purchaseorder = @purchaseorder
		WHERE invoiceid = @invoiceid
	END

SET NOCOUNT OFF

END
GO

ALTER AUTHORIZATION ON [dbo].[pupdateinvoiceurchaseorder] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[pupdateinvoiceurchaseorder] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[rpt_ITEnhancedBillingDetailsInDateRange]    Script Date: 10/13/2021 12:39:05 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[rpt_ITEnhancedBillingDetailsInDateRange]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[rpt_ITEnhancedBillingDetailsInDateRange] AS' 
END
GO

/***************************************************************************\
*                                                                          *
* MODULE:         rpt_ITEnhancedBillingDetailsInDateRange                  *
*                                                                          *
* APPLICATION:    BOSS                                                     *
*                                                                          *
* SUBSYSTEM:      Database                                                 *
*                                                                          *
* PURPOSE:        Stored Procedure                                         *
*                                                                          *
* AUTHOR:                                                  *
*                                                                          *
* CHANGE HISTORY:                                                          *
*                                                       *
*                                                                          *
\***************************************************************************/
ALTER procedure [dbo].[rpt_ITEnhancedBillingDetailsInDateRange]
(

	@pStartDate datetime ,
	@pEndDate datetime 
)
AS
BEGIN

declare @StartDate datetime
declare @EndDate datetime
set @StartDate = @pStartDate
set @EndDate = @pEndDate
--Build a table to hold all the invoices with invoice date 
--between the start and end date provided
create table #AllInvoicesInDateRange
(
	invoiceid int,
	wasAutoProcessed bit,
	wasManualProcessed bit
)

--get all invoices for the date range into this table
insert into #AllInvoicesInDateRange (invoiceid,wasAutoProcessed,wasManualProcessed)
select invoiceid,0,0 from tinvoice where invoicedate between @StartDate and @EndDate


--Now Get a list of all the automated billing job run dates and start/end times
--We use this to determine if any invoice print/processed date falls within a job run
--anything processed by the automated job will have a print/processed date set during the job run
--There could be multiple job run times on the same day so lets get the earliest start time and latest end time for that day. We need to do this...
--to avoid a "subquery returns more than 1 result" type error when we try to get these results for an invoice date.
SELECT AutomatedBillingRunDate = Convert(DATE, utcscheduletime)
	,AutomatedBillingJobUTCStartTime = MIN(UTCScheduletime)
	,AutomatedBillingJobUTCEndTime = MAX(UTCLastUpdated)
INTO #AutomatedBillingJobRuns
FROM Rollinsbackgroundjobs.dbo.tjobstatus
WHERE jobname = 'EnhancedBilling'
GROUP BY Convert(DATE, utcscheduletime)


--Now get a list of any invoices that are simply not marked processed
select
	*
into #NotMarkedProcessed
from 
	tinvoice i
where
	i.printdate is null
	and i.invoicedate between @StartDate and @EndDate

--Now get a list where the invoice print date
--is not inside an automated job run
select 
	distinct i.invoiceid
into #InvoicesCurrentPrintDateNotFromAuditedJob
from 
	tinvoice i
where
	i.printdate is not null
	and i.invoicedate between @StartDate and @EndDate
	and DateAdd(hour,5,i.printdate) not between (select AutomatedBillingJobUTCStartTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))
	                    and (select AutomatedBillingJobUTCEndTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))

--Now get a list where no audited print date is within an automated job
select
	distinct i.invoiceid
into #InvoicesNoAuditedPrintDateFromAutomatedJob
from 
	ServSuiteLog.dbo.audit_tinvoice i
where
	i.printdate is not null
	and i.invoicedate between @StartDate and @EndDate
	and DateAdd(hour,5,i.printdate) not between (select AutomatedBillingJobUTCStartTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))
	                    and (select AutomatedBillingJobUTCEndTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))

--Now get a list of all invoices processed by an automated job
select
	ebaudit.invoiceid
into #AutomatedJobProcessedInvoices
from
	tEnhancedBillingProcessedAudit ebaudit
where
	--ebaudit.printdate is not null
	ebaudit.invoicedate between @StartDate and @EndDate
	
--Get all invoices that show no automated job processed them into a single list
select
	distinct invoiceid
into #AllInvoicesNoJobProcessed
from
(
	select invoiceid from #InvoicesCurrentPrintDateNotFromAuditedJob
	union all
	select invoiceid from #InvoicesNoAuditedPrintDateFromAutomatedJob
)x

--Now get a listing of all invoices and all timestamps for marking processed 
--that are not part of an automated job run
--Table to hold all Marked as ProcessedDates that are not
--from an automated billing job run
create table #InvoiceMarkedProcessedDatesNotFromAutomatedJob
(
	invoiceid int,
	markedprocessedDateTime datetime
)


--First insert any marked processed timestamps from current
--invoice table that do not fall within a job run
insert into #InvoiceMarkedProcessedDatesNotFromAutomatedJob (invoiceid,markedprocessedDateTime)
select invoiceid,printdate from tinvoice i
where
	i.printdate is not null
	and i.invoicedate between @StartDate and @EndDate
	and DateAdd(hour,5,i.printdate) not between (select AutomatedBillingJobUTCStartTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))
	                    and (select AutomatedBillingJobUTCEndTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))


--Now get any audit tracked mark processed timestamps that are not in an automated billing job
--and also not already tracked
insert into #InvoiceMarkedProcessedDatesNotFromAutomatedJob (invoiceid,markedprocessedDateTime)
select invoiceid,printdate from ServSuiteLog.dbo.audit_tinvoice i
where
	i.printdate is not null
	and i.invoicedate between @StartDate and @EndDate
	and DateAdd(hour,5,i.printdate) not between (select AutomatedBillingJobUTCStartTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))
	                    and (select AutomatedBillingJobUTCEndTime from #AutomatedBillingJobRuns where AutomatedBillingRunDate = Convert(Date,i.printdate))

--Update our tracking table and flag invoices that were processed by an automated job run
update #AllInvoicesInDateRange set wasAutoProcessed = 1 where invoiceid in (select invoiceid from #AutomatedJobProcessedInvoices)

--Update our tracking table and flag invoices that were processed manually
update #AllInvoicesInDateRange set wasManualProcessed = 1 where invoiceid in (select invoiceid from #AllInvoicesNoJobProcessed)

--Select our output
select
	AccountId = a.accountid,
	invoiceId = i.invoiceid,
	invoiceNum = i.invoicenum,
	invoiceDate = i.invoicedate,
	InvoiceOriginalDue = vo.Originaldue,
	InvoiceTotalPaid = vo.totalpaid,
	InvoiceLastPayment = vo.datereceived,
	InvoiceRemaingingDue = vo.totaldue,
	currentProcessedDate = i.printdate,
	currentHowIsBillProcessed = (select description1 from tsetupdescriptor where setuptypeid = 96 and languageid = 0 and referenceid = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'HowIsBillProcessed')),
	currentWhenIsBillProcessed = (select description1 from tsetupdescriptor where setuptypeid = 95 and languageid = 0 and referenceid = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'WhenIsBillProcessed')),
	currentSendPaidInvoices = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'SendBillForPaidInvoices'),
	currentInvoiceGroupName = ig.invoicegroupname,
	currentInvoiceGroupHowIsBillProcessed = (select description1 from tsetupdescriptor where setuptypeid = 96 and languageid = 0 and referenceid = ig.HowisBillProcessed),
	currentInvoiceGroupWhenIsBillProcessed = (select description1 from tsetupdescriptor where setuptypeid = 95 and languageid = 0 and referenceid = ig.WhenIsBillProcessed),
	AutomatedBillingJobProcessedDate = jr.AutomatedBillingRunDate,
	AutomatedBillingJobUTCStartTime  = jr.AutomatedBillingJobUTCStartTime,
	AutomatedBillingJobUTCEndTime = jr.AutomatedBillingJobUTCEndTime,
	NumberOfTimesMarkedProcessedManually = (select count(*) from #InvoiceMarkedProcessedDatesNotFromAutomatedJob where invoiceid = i.invoiceid),
	EarliestManualMarkedProcessed = (select min(markedprocessedDateTime) from #InvoiceMarkedProcessedDatesNotFromAutomatedJob where invoiceid = i.invoiceid) ,
	LatestManualMarkedProcessed = (select max(markedprocessedDateTime) from #InvoiceMarkedProcessedDatesNotFromAutomatedJob where invoiceid = i.invoiceid) ,
	AutoBilledSummaryInvoiceID = aj.summaryId,
	AutoBilledWhenIsBillProcessed = (select description1 from tsetupdescriptor where setuptypeid = 95 and languageid = 0 and referenceid = aj.WhenIsBillProcessed),
	AutoBilledHowIsBillProcessed = (select description1 from tsetupdescriptor where setuptypeid = 96 and languageid = 0 and referenceid = aj.HowIsBillProcessed),
	AutoBilledTemplateUsed = (select templateName from tenhancedBillingTemplate where billingSettingsTemplateId = aj.invoicesDueTemplate and languageid = 0),
	AutoBilledSpecificDayOfMonth = aj.billProcessingDay,
	AutoBilledUTCMarkedProcesseddate = aj.utcMarkedPrinted,
	AutoBilledAttachPDFtoEmail = aj.attachPdfToEmail,
	AutoBilledIncludeInvoiceItemReport = aj.includeInvoiceItemReport,
	AutoBilledIncludeServiceTickets = aj.includeServiceTickets,
	AutoBilledeMailRecipients = aj.billingRecipients,
	AutoBilledInvSubTotal = aj.invSubtotal,
	AutoBilledInvFedTax  = aj.invFedTax,
	AutoBilledStateProvtax = aj.invStateTax,
	AutoBilledInvLocalTax = aj.invLocalTax,
	AutoBilledInvPaid = aj.invPaid,
	AutoBilledInvBalance = aj.invBalance,
	AutoBilledProcessedByProcedure = aj.processedBy,
	summaryInvoiceId = i.summaryinvoiceid,
	summaryInvoiceFrom = si.SummaryInvoiceFrom,
	summaryInvoiceLevel = si.ReferenceType,
	summaryInvoiceLevelId = si.ReferenceKey,
	SummaryInvoiceTemplateUsed = (select templateName from tenhancedBillingTemplate where billingSettingsTemplateId = si.TemplateUsed and languageid = 0),
	SummaryInvoiceUTCDateGenerated = si.UTcDateGenerated,
	SummaryInvoiceUTCCurrentPrintProcessedDate = si.UTCDateProcessed,
	SummaryInvoiceDateOnPDF = si.PDFDate,
	SummaryInvoiceCreatedBy = si.createdBy,
	SummaryInvoicelastchangedby = si.lastchangedby,
	SummaryInvoiceUTCLastChanged = si.UTCLastChanged,
	BusinessName = case when isnull(ac.businessname,'') = '' then ac.firstname + ' ' + ac.lastname else ac.businessname end,
	SiteId = s.siteid,
	LocationName = case when isnull(sc.businessname,'') = '' then sc.firstname + ' ' + sc.lastname else sc.businessname end,
	LotNumber = s.lotnumber,
	BranchName = b.branchname,
	BranchNumber = b.glprefix,
	ServiceAddress = (select addresslinesearch from taddress where addressid = s.addressid),
	ServiceEmail = sc.emailaddress,
	ServicePhoneNumber = scp.phonenumber,
	ProgramId = p.programid,
	ProgramName = psn.programname,
	currentAccountGroupCode = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'AccountGroupCode'),
	currentAccountGroupName = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'AccountGroupName'),
	currentNationalAccountFlag = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'IsNationalAccountCustomer'),
	currentSettingsProfileCode = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'CustomerSettingsProfileCode'),
	currentSettingsProfileName = (select attributevalue from tsitesettings where siteid = s.siteid and attributename = 'CustomerSettingsProfileName')
from
	#AllInvoicesInDateRange ai
	join tinvoice i
	on i.invoiceid = ai.invoiceid
	left join vinvoiceowed vo
	on vo.invoiceid = i.invoiceid
	left join tsummaryinvoice si
	on si.summaryinvoiceid = i.SummaryInvoiceID
	left join tEnhancedBillingProcessedAudit aj
	on aj.invoiceid = ai.invoiceid
	left join #AutomatedBillingJobRuns jr
	on aj.utcMarkedPrinted between jr.AutomatedBillingJobUTCStartTime and jr.AutomatedBillingJobUTCEndTime
	left join tprogram p
	on p.programid = i.programid
	left join tprogramsetupname psn
	on psn.programtypeid = p.programtypeid
	and psn.languageid = 0
	left join testimate e
	on p.estimateid = e.estimateid
	left join taccountinvoicegroup ig
	on ig.invoicegroupid = p.invoicegroupid
	left join tsite s
	on s.siteid = e.siteid
	left join tcontact sc
	on sc.contactid = s.primarycontactid
	left join tcontactphonenumber scp
	on scp.phoneid = sc.primaryphoneid
	left join tbranch b
	on b.branchid = e.servicecenter
	left join taccount a
	on a.accountid = i.accountid
	left join tcontact ac
	on ac.contactid = a.primarycontactid

--all manual processed dates by invoice
--select * from #InvoiceMarkedProcessedDatesNotFromAutomatedJob

--drop our temp tables
drop table #AutomatedBillingJobRuns
drop table #InvoicesCurrentPrintDateNotFromAuditedJob
drop table #InvoicesNoAuditedPrintDateFromAutomatedJob
drop table #AutomatedJobProcessedInvoices
drop table #AllInvoicesNoJobProcessed
drop table #NotMarkedProcessed
drop table #AllInvoicesInDateRange
drop table #InvoiceMarkedProcessedDatesNotFromAutomatedJob

END
GO

ALTER AUTHORIZATION ON [dbo].[rpt_ITEnhancedBillingDetailsInDateRange] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[rpt_ITEnhancedBillingDetailsInDateRange] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[sp_help_revlogin]    Script Date: 10/13/2021 12:39:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_help_revlogin]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_help_revlogin] AS' 
END
GO

  ALTER PROCEDURE [dbo].[sp_help_revlogin]   
  (
      @login_name sysname = NULL 
  )
  AS
  BEGIN
      DECLARE @name                     SYSNAME
      DECLARE @type                     VARCHAR (1)
      DECLARE @hasaccess                INT
      DECLARE @denylogin                INT
      DECLARE @is_disabled              INT
      DECLARE @PWD_varbinary            VARBINARY (256)
      DECLARE @PWD_string               VARCHAR (514)
      DECLARE @SID_varbinary            VARBINARY (85)
      DECLARE @SID_string               VARCHAR (514)
      DECLARE @tmpstr                   VARCHAR (1024)
      DECLARE @is_policy_checked        VARCHAR (3)
      DECLARE @is_expiration_checked    VARCHAR (3)
      Declare @Prefix                   VARCHAR(255)
      DECLARE @defaultdb                SYSNAME
      DECLARE @tmpstrRole               VARCHAR (1024)

  IF (@login_name IS NULL)
  BEGIN
      DECLARE login_curs CURSOR 
      FOR 
          SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin 
          FROM  sys.server_principals p 
          LEFT JOIN sys.syslogins     l ON ( l.name = p.name ) 
          WHERE p.type IN ( 'S', 'G', 'U' ) 
            AND p.name <> 'sa'
          ORDER BY p.name
  END
  ELSE
          DECLARE login_curs CURSOR 
          FOR 
              SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin 
              FROM  sys.server_principals p 
              LEFT JOIN sys.syslogins        l ON ( l.name = p.name ) 
              WHERE p.type IN ( 'S', 'G', 'U' ) 
                AND p.name = @login_name
              ORDER BY p.name

          OPEN login_curs 
          FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
          IF (@@fetch_status = -1)
          BEGIN
                PRINT 'No login(s) found.'
                CLOSE login_curs
                DEALLOCATE login_curs
                RETURN -1
          END

          SET @tmpstr = '/* sp_help_revlogin script '
          PRINT @tmpstr

          SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'

          PRINT @tmpstr
          PRINT ''

          WHILE (@@fetch_status <> -1)
          BEGIN
            IF (@@fetch_status <> -2)
            BEGIN
                  PRINT ''

                  SET @tmpstr = '-- Login: ' + @name

                  PRINT @tmpstr

                  SET @tmpstr='IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'''+@name+''')
                  BEGIN'
                  Print @tmpstr 

                  IF (@type IN ( 'G', 'U'))
                  BEGIN -- NT authenticated account/group 
                    SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
                  END
                  ELSE 
                  BEGIN -- SQL Server authentication
                          -- obtain password and sid
                          SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )

                          EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
                          EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT

                          -- obtain password policy state
                          SELECT @is_policy_checked     = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END 
                          FROM sys.sql_logins 
                          WHERE name = @name

                          SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END 
                          FROM sys.sql_logins 
                          WHERE name = @name

                          SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' 
                                          + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

                          IF ( @is_policy_checked IS NOT NULL )
                          BEGIN
                            SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
                          END

                          IF ( @is_expiration_checked IS NOT NULL )
                          BEGIN
                            SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
                          END
          END

          IF (@denylogin = 1)
          BEGIN -- login is denied access
              SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
          END
          ELSE IF (@hasaccess = 0)
          BEGIN -- login exists but does not have access
              SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
          END
          IF (@is_disabled = 1)
          BEGIN -- login is disabled
              SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
          END 

          Set @Prefix = '
          exec master.dbo.sp_addsrvrolemember @loginame='''

          Set @tmpstrRole=''

          Select @tmpstrRole = @tmpstrRole
              + Case When sysadmin        = 1 Then @Prefix + [LoginName] + ''', @rolename=''sysadmin'''        Else '' End
              + Case When securityadmin   = 1 Then @Prefix + [LoginName] + ''', @rolename=''securityadmin'''   Else '' End
              + Case When serveradmin     = 1 Then @Prefix + [LoginName] + ''', @rolename=''serveradmin'''     Else '' End
              + Case When setupadmin      = 1 Then @Prefix + [LoginName] + ''', @rolename=''setupadmin'''      Else '' End
              + Case When processadmin    = 1 Then @Prefix + [LoginName] + ''', @rolename=''processadmin'''    Else '' End
              + Case When diskadmin       = 1 Then @Prefix + [LoginName] + ''', @rolename=''diskadmin'''       Else '' End
              + Case When dbcreator       = 1 Then @Prefix + [LoginName] + ''', @rolename=''dbcreator'''       Else '' End
              + Case When bulkadmin       = 1 Then @Prefix + [LoginName] + ''', @rolename=''bulkadmin'''       Else '' End
            From (
                      select convert(varchar(100),suser_sname(sid)) as [LoginName],
                              sysadmin,
                              securityadmin,
                              serveradmin,
                              setupadmin,
                              processadmin,
                              diskadmin,
                              dbcreator,
                              bulkadmin
                      from sys.syslogins
                      where (       sysadmin<>0
                              or    securityadmin<>0
                              or    serveradmin<>0
                              or    setupadmin <>0
                              or    processadmin <>0
                              or    diskadmin<>0
                              or    dbcreator<>0
                              or    bulkadmin<>0
                          ) 
                          and name=@name 
                ) L 

              PRINT @tmpstr
              Print @tmpstrRole
              Print 'END'
          END 
          FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin 
      END
      CLOSE login_curs
      DEALLOCATE login_curs
      RETURN 0
  END
GO

ALTER AUTHORIZATION ON [dbo].[sp_help_revlogin] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[sp_help_revlogin] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[sp_hexadecimal]    Script Date: 10/13/2021 12:39:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_hexadecimal]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_hexadecimal] AS' 
END
GO

  ALTER PROCEDURE [dbo].[sp_hexadecimal]
  (
      @binvalue varbinary(256),
      @hexvalue varchar (514) OUTPUT
  )
  AS
  BEGIN
      DECLARE @charvalue varchar (514)
      DECLARE @i int
      DECLARE @length int
      DECLARE @hexstring char(16)
      SELECT @charvalue = '0x'
      SELECT @i = 1
      SELECT @length = DATALENGTH (@binvalue)
      SELECT @hexstring = '0123456789ABCDEF'

      WHILE (@i <= @length)
      BEGIN
            DECLARE @tempint int
            DECLARE @firstint int
            DECLARE @secondint int

            SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
            SELECT @firstint = FLOOR(@tempint/16)
            SELECT @secondint = @tempint - (@firstint*16)
            SELECT @charvalue = @charvalue + SUBSTRING(@hexstring, @firstint+1, 1) + SUBSTRING(@hexstring, @secondint+1, 1)

            SELECT @i = @i + 1
      END 
      SELECT @hexvalue = @charvalue
  END

GO

ALTER AUTHORIZATION ON [dbo].[sp_hexadecimal] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[sp_hexadecimal] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[sp_who3]    Script Date: 10/13/2021 12:39:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_who3]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_who3] AS' 
END
GO

ALTER PROCEDURE [dbo].[sp_who3] @x NVARCHAR(128) = NULL 
WITH RECOMPILE
AS
/****************************************************************************************** 
   This is a current activity query used to identify what processes are currently running 
   on the processors.  Use to first view the current system load and to identify a session 
   of interest such as blocking, waiting and granted memory.  You should execute the query 
   several times to identify if a query is increasing it's I/O, CPU time or memory granted.
   
   *Revision History
   - 31-Jul-2011 (Rodrigo): Initial development
   - 12-Apr-2012 (Rodrigo): Enhanced sql_text, object_name outputs;
								  Added NOLOCK hints and RECOMPILE option;
								  Added BlkBy column;
								  Removed dead-code.
   - 03-Nov-2014 (Rodrigo): Added program_name and open_transaction_count	column
   - 10-Nov-2014 (Rodrigo): Added granted_memory_GB
   - 03-Nov-2015 (Rodrigo): Added parameters to show memory and cpu information
   - 12-Nov-2015 (Rodrigo): Added query to get IO info
   - 17-Nov-2015 (Rodrigo): Changed the logic and addedd new parameters
   - 18-Nov-2015 (Rodrigo): Added help content
*******************************************************************************************/
BEGIN
	SET NOCOUNT ON;
	IF @x IS NULL
		BEGIN
			SELECT r.session_id, se.host_name, se.login_name, Db_name(r.database_id) AS dbname, r.status, r.command,
				   CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
					+ CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
					+ CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
				   r.blocking_session_id AS BlkBy, r.open_transaction_count AS NoOfOpenTran, r.wait_type,
				   CAST(ROUND((r.granted_query_memory / 128.0)  / 1024,2) AS NUMERIC(10,2))AS granted_memory_GB,
				   object_name = OBJECT_SCHEMA_NAME(s.objectid,s.dbid) + '.' + OBJECT_NAME(s.objectid, s.dbid),
 				   program_name = se.program_name, p.query_plan AS query_plan,
				   sql_text = SUBSTRING	(s.text,r.statement_start_offset/2,
						(CASE WHEN r.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX), s.text)) * 2
							ELSE r.statement_end_offset	END - r.statement_start_offset)/2),
					r.cpu_time,	start_time, percent_complete,		
					CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
					+ CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
					+ CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
					dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time
			FROM   sys.dm_exec_requests r WITH (NOLOCK) 
			JOIN sys.dm_exec_sessions se WITH (NOLOCK)
				ON r.session_id = se.session_id 
			OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) s 
			OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) p 
			WHERE  r.session_id <> @@SPID AND se.is_user_process = 1;
		END
	ELSE IF @x = '1'  OR @x = 'memory'
		BEGIN
			-- who is consuming the memory
			SELECT session_id, granted_memory_kb FROM sys.dm_exec_query_memory_grants WITH (NOLOCK) ORDER BY 1 DESC;
		END
	ELSE IF @x = '2'  OR @x = 'cpu'
		BEGIN
			-- who has cached plans that consumed the most cumulative CPU (top 10)
			SELECT TOP 10 DatabaseName = DB_Name(t.dbid),
							sql_text = SUBSTRING (t.text, qs.statement_start_offset/2,
										(CASE WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(nvarchar(MAX), t.text)) * 2
										ELSE qs.statement_end_offset END - qs.statement_start_offset)/2),
							ObjectName = OBJECT_SCHEMA_NAME(t.objectid,t.dbid) + '.' + OBJECT_NAME(t.objectid, t.dbid),
							qs.execution_count AS [Executions], qs.total_worker_time AS [Total CPU Time],
							qs.total_physical_reads AS [Disk Reads (worst reads)],	qs.total_elapsed_time AS [Duration], 
							qs.total_worker_time/qs.execution_count AS [Avg CPU Time],qs.plan_generation_num,
								qs.creation_time AS [Data Cached], qp.query_plan
			FROM sys.dm_exec_query_stats qs WITH(NOLOCK) 
			CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS t
			CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
			ORDER BY DatabaseName, qs.total_worker_time DESC;
		END
	ELSE IF @x = '3'  OR @x = 'count'
		BEGIN
			-- who is connected and how many sessions it has 
			SELECT login_name, [program_name],No_of_Connections = COUNT(session_id)
			FROM sys.dm_exec_sessions WITH (NOLOCK)
			WHERE session_id > 50 GROUP BY login_name, [program_name] ORDER BY COUNT(session_id) DESC
		END
	ELSE IF @x = '4'  OR @x = 'idle'
		BEGIN
			-- who is idle that have open transactions
			SELECT s.session_id, login_name, login_time, host_name, host_process_id, status FROM sys.dm_exec_sessions AS s WITH (NOLOCK)
			WHERE EXISTS (SELECT * FROM sys.dm_tran_session_transactions AS t WHERE t.session_id = s.session_id)
			AND NOT EXISTS (SELECT * FROM sys.dm_exec_requests AS r WHERE r.session_id = s.session_id)
		END
	ELSE IF @x = '5' OR @x = 'tempdb'
		BEGIN
			-- who is running tasks that use tempdb (top 5)
			SELECT TOP 5 session_id, request_id,  user_objects_alloc_page_count + internal_objects_alloc_page_count as task_alloc
			FROM    tempdb.sys.dm_db_task_space_usage  WITH (NOLOCK)
			WHERE   session_id > 50 ORDER BY user_objects_alloc_page_count + internal_objects_alloc_page_count DESC
		END
	ELSE IF @x = '6' OR @x = 'block'
		BEGIN
			-- who is blocking
			SELECT DB_NAME(lok.resource_database_id) as db_name,lok.resource_description,lok.request_type,lok.request_status,lok.request_owner_type
			,wat.session_id as wait_session_id,wat.wait_duration_ms,wat.wait_type,wat.blocking_session_id
			FROM  sys.dm_tran_locks lok WITH (NOLOCK) JOIN sys.dm_os_waiting_tasks wat WITH (NOLOCK) ON lok.lock_owner_address = wat.resource_address 
		END
	ELSE IF @x = '0' OR @x = 'help'
		BEGIN
			DECLARE @text NVARCHAR(4000);
			DECLARE @NewLineChar AS CHAR(2) = CHAR(13) + CHAR(10);
			SET @text = N'Synopsis:' + @NewLineChar +
						N'Who is currently running on my system?'  + @NewLineChar +
						N'-------------------------------------------------------------------------------------------------------------------------------------'  + @NewLineChar +
						N'Description:'  + @NewLineChar +
						N'The first area to look at on a system running SQL Server is the utilization of hardware resources, the core of which are memory,' + @NewLineChar +
						N'storage, CPU and long blockings. Use sp_who3 to first view the current system load and to identify a session of interest.' + @NewLineChar +
						N'You should execute the query several times to identify which session id is most consuming teh system resources.' + @NewLineChar +
						N'-------------------------------------------------------------------------------------------------------------------------------------' + @NewLineChar +
						N'Parameters:'  + @NewLineChar +
						N'sp_who3 null				- who is active;' + @NewLineChar +
						N'sp_who3 1 or ''memory''  	- who is consuming the memory;' + @NewLineChar +
						N'sp_who3 2 or ''cpu''  	- who has cached plans that consumed the most cumulative CPU (top 10);'+ @NewLineChar +
						N'sp_who3 3 or ''count''  	- who is connected and how many sessions it has;'+ @NewLineChar +
						N'sp_who3 4 or ''idle'' 	- who is idle that has open transactions;'+ @NewLineChar +
						N'sp_who3 5 or ''tempdb'' 	- who is running tasks that use tempdb (top 5); and,'+ @NewLineChar +
						N'sp_who3 6 or ''block'' 	- who is blocking.'
			PRINT @text;
		END
END;
GO

ALTER AUTHORIZATION ON [dbo].[sp_who3] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[sp_who3] TO  SCHEMA OWNER 
GO

/****** Object:  StoredProcedure [dbo].[sp_WhoIsActive]    Script Date: 10/13/2021 12:39:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_WhoIsActive]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_WhoIsActive] AS' 
END
GO


/*********************************************************************************************
Who Is Active? v11.17 (2016-10-18)
(C) 2007-2016, Adam Machanic

Feedback: mailto:amachanic@gmail.com
Updates: http://whoisactive.com

License: 
	Who is Active? is free to download and use for personal, educational, and internal 
	corporate purposes, provided that this header is preserved. Redistribution or sale 
	of Who is Active?, in whole or in part, is prohibited without the author's express 
	written consent.
*********************************************************************************************/
ALTER PROC [dbo].[sp_WhoIsActive]
(
--~
	--Filters--Both inclusive and exclusive
	--Set either filter to '' to disable
	--Valid filter types are: session, program, database, login, and host
	--Session is a session ID, and either 0 or '' can be used to indicate "all" sessions
	--All other filter types support % or _ as wildcards
	@filter sysname = '',
	@filter_type VARCHAR(10) = 'session',
	@not_filter sysname = '',
	@not_filter_type VARCHAR(10) = 'session',

	--Retrieve data about the calling session?
	@show_own_spid BIT = 0,

	--Retrieve data about system sessions?
	@show_system_spids BIT = 0,

	--Controls how sleeping SPIDs are handled, based on the idea of levels of interest
	--0 does not pull any sleeping SPIDs
	--1 pulls only those sleeping SPIDs that also have an open transaction
	--2 pulls all sleeping SPIDs
	@show_sleeping_spids TINYINT = 1,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@get_full_inner_text BIT = 0,

	--Get associated query plans for running tasks, if available
	--If @get_plans = 1, gets the plan based on the request's statement offset
	--If @get_plans = 2, gets the entire plan based on the request's plan_handle
	@get_plans TINYINT = 0,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@get_outer_command BIT = 0,

	--Enables pulling transaction log write info and transaction duration
	@get_transaction_info BIT = 0,

	--Get information on active tasks, based on three interest levels
	--Level 0 does not pull any task-related information
	--Level 1 is a lightweight mode that pulls the top non-CXPACKET wait, giving preference to blockers
	--Level 2 pulls all available task-based metrics, including: 
	--number of active tasks, current wait stats, physical I/O, context switches, and blocker information
	@get_task_info TINYINT = 1,

	--Gets associated locks for each request, aggregated in an XML format
	@get_locks BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@get_avg_time BIT = 0,

	--Get additional non-performance-related information about the session or request
	--text_size, language, date_format, date_first, quoted_identifier, arithabort, ansi_null_dflt_on, 
	--ansi_defaults, ansi_warnings, ansi_padding, ansi_nulls, concat_null_yields_null, 
	--transaction_isolation_level, lock_timeout, deadlock_priority, row_count, command_type
	--
	--If a SQL Agent job is running, an subnode called agent_info will be populated with some or all of
	--the following: job_id, job_name, step_id, step_name, msdb_query_error (in the event of an error)
	--
	--If @get_task_info is set to 2 and a lock wait is detected, a subnode called block_info will be
	--populated with some or all of the following: lock_type, database_name, object_id, file_id, hobt_id, 
	--applock_hash, metadata_resource, metadata_class_id, object_name, schema_name
	@get_additional_info BIT = 0,

	--Walk the blocking chain and count the number of 
	--total SPIDs blocked all the way down by a given session
	--Also enables task_info Level 1, if @get_task_info is set to 0
	@find_block_leaders BIT = 0,

	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@delta_interval TINYINT = 0,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@output_column_list VARCHAR(8000) = '[dd%][session_id][sql_text][sql_command][login_name][wait_info][tasks][tran_log%][cpu%][temp%][block%][reads%][writes%][context%][physical%][query_plan][locks][%]',

	--Column(s) by which to sort output, optionally with sort directions. 
		--Valid column choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_allocations,
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, 
		--reads_delta, physical_reads_delta, writes_delta, tempdb_allocations_delta, 
		--tempdb_current_delta, CPU_delta, context_switches_delta, used_memory_delta, 
		--tasks, tran_start_time, open_tran_count, blocking_session_id, blocked_session_count,
		--percent_complete, host_name, login_name, database_name, start_time, login_time
		--
		--Note that column names in the list must be bracket-delimited. Commas and/or white
		--space are not required. 
	@sort_order VARCHAR(500) = '[start_time] ASC',

	--Formats some of the output columns in a more "human readable" form
	--0 disables outfput format
	--1 formats the output for variable-width fonts
	--2 formats the output for fixed-width fonts
	@format_output TINYINT = 1,

	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@destination_table VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @schema parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@return_schema BIT = 0,
	@schema VARCHAR(MAX) = NULL OUTPUT,

	--Help! What do I do?
	@help BIT = 0
--~
)
/*
OUTPUT COLUMNS
--------------
Formatted/Non:	[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time since the last batch completed

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @get_avg_time option)
	How much time has the active portion of the query taken in the past, on average?

Formatted:		[physical_io] [varchar](30) NULL
Non-Formatted:	[physical_io] [bigint] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](30) NULL
Non-Formatted:	[reads] [bigint] NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](30) NULL
Non-Formatted:	[physical_reads] [bigint] NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](30) NULL
Non-Formatted:	[writes] [bigint] NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_allocations] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations] [bigint] NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](30) NULL
Non-Formatted:	[tempdb_current] [bigint] NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](30) NULL
Non-Formatted:	[CPU] [int] NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](30) NULL
Non-Formatted:	[context_switches] [bigint] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](30) NOT NULL
Non-Formatted:	[used_memory] [bigint] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](30) NULL
Non-Formatted:	[physical_io_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](30) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](30) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](30) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_allocations_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_allocations_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](30) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the number of allocated TempDB pages reported on the first and second 
	collections. If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](30) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @delta_interval option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](30) NULL
Non-Formatted:	[context_switches_delta] [bigint] NULL
	(Requires @delta_interval option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](30) NULL
Non-Formatted:	[used_memory_delta] [bigint] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[tasks] [varchar](30) NULL
Non-Formatted:	[tasks] [smallint] NULL
	Number of worker tasks currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)

Formatted/Non:	[wait_info] [nvarchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting tasks currently waiting on resource type E. B/C/D are wait
	times, in milliseconds. If only one thread is waiting, its wait time will be shown as B.
	If two tasks are waiting, each of their wait times will be shown (B/C). If three or more 
	tasks are waiting, the minimum, average, and maximum wait times will be shown (B/C/D).
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), 
	the page type will be identified.
	If wait type E is CXPACKET, the nodeId from the query plan will be identified

Formatted/Non:	[locks] [xml] NULL
	(Requires @get_locks option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @get_transaction_info option)
	Date and time that the first transaction opened by a session caused a transaction log 
	write to occur.

Formatted/Non:	[tran_log_writes] [nvarchar](4000) NULL
	(Requires @get_transaction_info option)
	Aggregates transaction log write information, in the following format:
	A:wB (C kB)
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction
	C is the number of log kilobytes consumed by the log records

Formatted:		[open_tran_count] [varchar](30) NULL
Non-Formatted:	[open_tran_count] [smallint] NULL
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [nvarchar](max) NULL
	(Requires @get_outer_command option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, 
	if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [nvarchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @get_full_inner_text option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.
	If the query text is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @get_plans option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />
	If an error occurs, an error message will be sent, in the following format:
		<error message="message" />

Formatted/Non:	[blocking_session_id] [smallint] NULL
	When applicable, shows the blocking SPID

Formatted:		[blocked_session_count] [varchar](30) NULL
Non-Formatted:	[blocked_session_count] [smallint] NULL
	(Requires @find_block_leaders option)
	The total number of SPIDs blocked by this session,
	all the way down the blocking chain.

Formatted:		[percent_complete] [varchar](30) NULL
Non-Formatted:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [sysname] NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [sysname] NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [sysname] NULL
	Shows the connected database

Formatted/Non:	[program_name] [sysname] NULL
	Shows the reported program/application name

Formatted/Non:	[additional_info] [xml] NULL
	(Requires @get_additional_info option)
	Returns additional non-performance-related session/request information
	If the script finds a SQL Agent job running, the name of the job and job step will be reported
	If @get_task_info = 2 and the script finds a lock wait, the locked object will be reported

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the last batch completed

Formatted/Non:	[login_time] [datetime] NOT NULL
	Shows the time that the session connected

Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN;
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	SET QUOTED_IDENTIFIER ON;
	SET ANSI_PADDING ON;
	SET CONCAT_NULL_YIELDS_NULL ON;
	SET ANSI_WARNINGS ON;
	SET NUMERIC_ROUNDABORT OFF;
	SET ARITHABORT ON;

	IF
		@filter IS NULL
		OR @filter_type IS NULL
		OR @not_filter IS NULL
		OR @not_filter_type IS NULL
		OR @show_own_spid IS NULL
		OR @show_system_spids IS NULL
		OR @show_sleeping_spids IS NULL
		OR @get_full_inner_text IS NULL
		OR @get_plans IS NULL
		OR @get_outer_command IS NULL
		OR @get_transaction_info IS NULL
		OR @get_task_info IS NULL
		OR @get_locks IS NULL
		OR @get_avg_time IS NULL
		OR @get_additional_info IS NULL
		OR @find_block_leaders IS NULL
		OR @delta_interval IS NULL
		OR @format_output IS NULL
		OR @output_column_list IS NULL
		OR @sort_order IS NULL
		OR @return_schema IS NULL
		OR @destination_table IS NULL
		OR @help IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;
	
	IF @filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @filter_type = 'session' AND @filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type NOT IN ('session', 'program', 'database', 'login', 'host')
	BEGIN;
		RAISERROR('Valid filter types are: session, program, database, login, host', 16, 1);
		RETURN;
	END;
	
	IF @not_filter_type = 'session' AND @not_filter LIKE '%[^0123456789]%'
	BEGIN;
		RAISERROR('Session filters must be valid integers', 16, 1);
		RETURN;
	END;
	
	IF @show_sleeping_spids NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @show_sleeping_spids are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @get_plans NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_plans are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @get_task_info NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @get_task_info are: 0, 1, or 2', 16, 1);
		RETURN;
	END;

	IF @format_output NOT IN (0, 1, 2)
	BEGIN;
		RAISERROR('Valid values for @format_output are: 0, 1, or 2', 16, 1);
		RETURN;
	END;
	
	IF @help = 1
	BEGIN;
		DECLARE 
			@header VARCHAR(MAX),
			@params VARCHAR(MAX),
			@outputs VARCHAR(MAX);

		SELECT 
			@header =
				REPLACE
				(
					REPLACE
					(
						CONVERT
						(
							VARCHAR(MAX),
							SUBSTRING
							(
								t.text, 
								CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94,
								CHARINDEX(REPLICATE('*', 93) + '/', t.text) - (CHARINDEX('/' + REPLICATE('*', 93), t.text) + 94)
							)
						),
						CHAR(13)+CHAR(10),
						CHAR(13)
					),
					'	',
					''
				),
			@params =
				CHAR(13) +
					REPLACE
					(
						REPLACE
						(
							CONVERT
							(
								VARCHAR(MAX),
								SUBSTRING
								(
									t.text, 
									CHARINDEX('--~', t.text) + 5, 
									CHARINDEX('--~', t.text, CHARINDEX('--~', t.text) + 5) - (CHARINDEX('--~', t.text) + 5)
								)
							),
							CHAR(13)+CHAR(10),
							CHAR(13)
						),
						'	',
						''
					),
				@outputs = 
					CHAR(13) +
						REPLACE
						(
							REPLACE
							(
								REPLACE
								(
									CONVERT
									(
										VARCHAR(MAX),
										SUBSTRING
										(
											t.text, 
											CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32,
											CHARINDEX('*/', t.text, CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32) - (CHARINDEX('OUTPUT COLUMNS'+CHAR(13)+CHAR(10)+'--------------', t.text) + 32)
										)
									),
									CHAR(9),
									CHAR(255)
								),
								CHAR(13)+CHAR(10),
								CHAR(13)
							),
							'	',
							''
						) +
						CHAR(13)
		FROM sys.dm_exec_requests AS r
		CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS t
		WHERE
			r.session_id = @@SPID;

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@header) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		)
		SELECT
			RTRIM(LTRIM(
				SUBSTRING
				(
					@header,
					number + 1,
					CHARINDEX(CHAR(13), @header, number + 1) - number - 1
				)
			)) AS [------header---------------------------------------------------------------------------------------------------------------]
		FROM numbers
		WHERE
			SUBSTRING(@header, number, 1) = CHAR(13);

		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@params) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@params,
						number + 1,
						CHARINDEX(CHAR(13), @params, number + 1) - number - 1
					)
				)) AS token,
				number,
				CASE
					WHEN SUBSTRING(@params, number + 1, 1) = CHAR(13) THEN number
					ELSE COALESCE(NULLIF(CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number), 0), LEN(@params)) 
				END AS param_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY
						CHARINDEX(',' + CHAR(13) + CHAR(13), @params, number),
						SUBSTRING(@params, number+1, 1)
					ORDER BY 
						number
				) AS group_order
			FROM numbers
			WHERE
				SUBSTRING(@params, number, 1) = CHAR(13)
		),
		parsed_tokens AS
		(
			SELECT
				MIN
				(
					CASE
						WHEN token LIKE '@%' THEN token
						ELSE NULL
					END
				) AS parameter,
				MIN
				(
					CASE
						WHEN token LIKE '--%' THEN RIGHT(token, LEN(token) - 2)
						ELSE NULL
					END
				) AS description,
				param_group,
				group_order
			FROM tokens
			WHERE
				NOT 
				(
					token = '' 
					AND group_order > 1
				)
			GROUP BY
				param_group,
				group_order
		)
		SELECT
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '-------------------------------------------------------------------------'
				WHEN param_group = MAX(param_group) OVER() THEN parameter
				ELSE COALESCE(LEFT(parameter, LEN(parameter) - 1), '')
			END AS [------parameter----------------------------------------------------------],
			CASE
				WHEN description IS NULL AND parameter IS NULL THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE COALESCE(description, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM parsed_tokens
		ORDER BY
			param_group, 
			group_order;
		
		WITH
		a0 AS
		(SELECT 1 AS n UNION ALL SELECT 1),
		a1 AS
		(SELECT 1 AS n FROM a0 AS a, a0 AS b),
		a2 AS
		(SELECT 1 AS n FROM a1 AS a, a1 AS b),
		a3 AS
		(SELECT 1 AS n FROM a2 AS a, a2 AS b),
		a4 AS
		(SELECT 1 AS n FROM a3 AS a, a3 AS b),
		numbers AS
		(
			SELECT TOP(LEN(@outputs) - 1)
				ROW_NUMBER() OVER
				(
					ORDER BY (SELECT NULL)
				) AS number
			FROM a4
			ORDER BY
				number
		),
		tokens AS
		(
			SELECT 
				RTRIM(LTRIM(
					SUBSTRING
					(
						@outputs,
						number + 1,
						CASE
							WHEN 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) < 
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs))
								THEN COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) - number - 1
							ELSE
								COALESCE(NULLIF(CHARINDEX(CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2, @outputs, number + 1), 0), LEN(@outputs)) - number - 1
						END
					)
				)) AS token,
				number,
				COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs)) AS output_group,
				ROW_NUMBER() OVER
				(
					PARTITION BY 
						COALESCE(NULLIF(CHARINDEX(CHAR(13) + 'Formatted', @outputs, number + 1), 0), LEN(@outputs))
					ORDER BY
						number
				) AS output_group_order
			FROM numbers
			WHERE
				SUBSTRING(@outputs, number, 10) = CHAR(13) + 'Formatted'
				OR SUBSTRING(@outputs, number, 2) = CHAR(13) + CHAR(255) COLLATE Latin1_General_Bin2
		),
		output_tokens AS
		(
			SELECT 
				*,
				CASE output_group_order
					WHEN 2 THEN MAX(CASE output_group_order WHEN 1 THEN token ELSE NULL END) OVER (PARTITION BY output_group)
					ELSE ''
				END COLLATE Latin1_General_Bin2 AS column_info
			FROM tokens
		)
		SELECT
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)+2) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info)-1)
					END
				ELSE ''
			END AS formatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '-----------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, LEN(column_info))
						ELSE
							SUBSTRING(column_info, CHARINDEX(']', column_info)+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
					END
				ELSE ''
			END AS formatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX('>', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
								ELSE
									SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, CHARINDEX(']', column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1) - CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info)))
							END
					END
				ELSE ''
			END AS unformatted_column_name,
			CASE output_group_order
				WHEN 1 THEN '---------------------------------------'
				WHEN 2 THEN 
					CASE
						WHEN CHARINDEX('Formatted/Non:', column_info) = 1 THEN ''
						ELSE
							CASE
								WHEN SUBSTRING(column_info, CHARINDEX(CHAR(255) COLLATE Latin1_General_Bin2, column_info, CHARINDEX('Non-Formatted:', column_info))+1, 1) = '<' THEN ''
								ELSE
									SUBSTRING(column_info, CHARINDEX(']', column_info, CHARINDEX('Non-Formatted:', column_info))+2, CHARINDEX('Non-Formatted:', column_info, CHARINDEX(']', column_info)+2) - CHARINDEX(']', column_info)-3)
							END
					END
				ELSE ''
			END AS unformatted_column_type,
			CASE output_group_order
				WHEN 1 THEN '----------------------------------------------------------------------------------------------------------------------'
				ELSE REPLACE(token, CHAR(255) COLLATE Latin1_General_Bin2, '')
			END AS [------description-----------------------------------------------------------------------------------------------------]
		FROM output_tokens
		WHERE
			NOT 
			(
				output_group_order = 1 
				AND output_group = LEN(@outputs)
			)
		ORDER BY
			output_group,
			CASE output_group_order
				WHEN 1 THEN 99
				ELSE output_group_order
			END;

		RETURN;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@output_column_list))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@output_column_list,
					number + 1,
					CHARINDEX(']', @output_column_list, number) - number - 1
				) + '|]' AS token,
			number
		FROM numbers
		WHERE
			SUBSTRING(@output_column_list, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number,
					x.default_order
			) AS r,
			ROW_NUMBER() OVER
			(
				ORDER BY
					tokens.number,
					x.default_order
			) AS s
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name, 1 AS default_order
			UNION ALL
			SELECT '[dd hh:mm:ss.mss]', 2
			WHERE
				@format_output IN (1, 2)
			UNION ALL
			SELECT '[dd hh:mm:ss.mss (avg)]', 3
			WHERE
				@format_output IN (1, 2)
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[avg_elapsed_time]', 4
			WHERE
				@format_output = 0
				AND @get_avg_time = 1
			UNION ALL
			SELECT '[physical_io]', 5
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[reads]', 6
			UNION ALL
			SELECT '[physical_reads]', 7
			UNION ALL
			SELECT '[writes]', 8
			UNION ALL
			SELECT '[tempdb_allocations]', 9
			UNION ALL
			SELECT '[tempdb_current]', 10
			UNION ALL
			SELECT '[CPU]', 11
			UNION ALL
			SELECT '[context_switches]', 12
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[used_memory]', 13
			UNION ALL
			SELECT '[physical_io_delta]', 14
			WHERE
				@delta_interval > 0	
				AND @get_task_info = 2
			UNION ALL
			SELECT '[reads_delta]', 15
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[physical_reads_delta]', 16
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[writes_delta]', 17
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_allocations_delta]', 18
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tempdb_current_delta]', 19
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[CPU_delta]', 20
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[context_switches_delta]', 21
			WHERE
				@delta_interval > 0
				AND @get_task_info = 2
			UNION ALL
			SELECT '[used_memory_delta]', 22
			WHERE
				@delta_interval > 0
			UNION ALL
			SELECT '[tasks]', 23
			WHERE
				@get_task_info = 2
			UNION ALL
			SELECT '[status]', 24
			UNION ALL
			SELECT '[wait_info]', 25
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[locks]', 26
			WHERE
				@get_locks = 1
			UNION ALL
			SELECT '[tran_start_time]', 27
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[tran_log_writes]', 28
			WHERE
				@get_transaction_info = 1
			UNION ALL
			SELECT '[open_tran_count]', 29
			UNION ALL
			SELECT '[sql_command]', 30
			WHERE
				@get_outer_command = 1
			UNION ALL
			SELECT '[sql_text]', 31
			UNION ALL
			SELECT '[query_plan]', 32
			WHERE
				@get_plans >= 1
			UNION ALL
			SELECT '[blocking_session_id]', 33
			WHERE
				@get_task_info > 0
				OR @find_block_leaders = 1
			UNION ALL
			SELECT '[blocked_session_count]', 34
			WHERE
				@find_block_leaders = 1
			UNION ALL
			SELECT '[percent_complete]', 35
			UNION ALL
			SELECT '[host_name]', 36
			UNION ALL
			SELECT '[login_name]', 37
			UNION ALL
			SELECT '[database_name]', 38
			UNION ALL
			SELECT '[program_name]', 39
			UNION ALL
			SELECT '[additional_info]', 40
			WHERE
				@get_additional_info = 1
			UNION ALL
			SELECT '[start_time]', 41
			UNION ALL
			SELECT '[login_time]', 42
			UNION ALL
			SELECT '[request_id]', 43
			UNION ALL
			SELECT '[collection_time]', 44
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@output_column_list =
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						s
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			);
	
	IF COALESCE(RTRIM(@output_column_list), '') = ''
	BEGIN;
		RAISERROR('No valid column matches found in @output_column_list or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @destination_table <> ''
	BEGIN;
		SET @destination_table = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@destination_table, 1)), '');
			
		IF COALESCE(RTRIM(@destination_table), '') = ''
		BEGIN;
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	WITH
	a0 AS
	(SELECT 1 AS n UNION ALL SELECT 1),
	a1 AS
	(SELECT 1 AS n FROM a0 AS a, a0 AS b),
	a2 AS
	(SELECT 1 AS n FROM a1 AS a, a1 AS b),
	a3 AS
	(SELECT 1 AS n FROM a2 AS a, a2 AS b),
	a4 AS
	(SELECT 1 AS n FROM a3 AS a, a3 AS b),
	numbers AS
	(
		SELECT TOP(LEN(@sort_order))
			ROW_NUMBER() OVER
			(
				ORDER BY (SELECT NULL)
			) AS number
		FROM a4
		ORDER BY
			number
	),
	tokens AS
	(
		SELECT 
			'|[' +
				SUBSTRING
				(
					@sort_order,
					number + 1,
					CHARINDEX(']', @sort_order, number) - number - 1
				) + '|]' AS token,
			SUBSTRING
			(
				@sort_order,
				CHARINDEX(']', @sort_order, number) + 1,
				COALESCE(NULLIF(CHARINDEX('[', @sort_order, CHARINDEX(']', @sort_order, number)), 0), LEN(@sort_order)) - CHARINDEX(']', @sort_order, number)
			) AS next_chunk,
			number
		FROM numbers
		WHERE
			SUBSTRING(@sort_order, number, 1) = '['
	),
	ordered_columns AS
	(
		SELECT
			x.column_name +
				CASE
					WHEN tokens.next_chunk LIKE '%asc%' THEN ' ASC'
					WHEN tokens.next_chunk LIKE '%desc%' THEN ' DESC'
					ELSE ''
				END AS column_name,
			ROW_NUMBER() OVER
			(
				PARTITION BY
					x.column_name
				ORDER BY
					tokens.number
			) AS r,
			tokens.number
		FROM tokens
		JOIN
		(
			SELECT '[session_id]' AS column_name
			UNION ALL
			SELECT '[physical_io]'
			UNION ALL
			SELECT '[reads]'
			UNION ALL
			SELECT '[physical_reads]'
			UNION ALL
			SELECT '[writes]'
			UNION ALL
			SELECT '[tempdb_allocations]'
			UNION ALL
			SELECT '[tempdb_current]'
			UNION ALL
			SELECT '[CPU]'
			UNION ALL
			SELECT '[context_switches]'
			UNION ALL
			SELECT '[used_memory]'
			UNION ALL
			SELECT '[physical_io_delta]'
			UNION ALL
			SELECT '[reads_delta]'
			UNION ALL
			SELECT '[physical_reads_delta]'
			UNION ALL
			SELECT '[writes_delta]'
			UNION ALL
			SELECT '[tempdb_allocations_delta]'
			UNION ALL
			SELECT '[tempdb_current_delta]'
			UNION ALL
			SELECT '[CPU_delta]'
			UNION ALL
			SELECT '[context_switches_delta]'
			UNION ALL
			SELECT '[used_memory_delta]'
			UNION ALL
			SELECT '[tasks]'
			UNION ALL
			SELECT '[tran_start_time]'
			UNION ALL
			SELECT '[open_tran_count]'
			UNION ALL
			SELECT '[blocking_session_id]'
			UNION ALL
			SELECT '[blocked_session_count]'
			UNION ALL
			SELECT '[percent_complete]'
			UNION ALL
			SELECT '[host_name]'
			UNION ALL
			SELECT '[login_name]'
			UNION ALL
			SELECT '[database_name]'
			UNION ALL
			SELECT '[start_time]'
			UNION ALL
			SELECT '[login_time]'
		) AS x ON 
			x.column_name LIKE token ESCAPE '|'
	)
	SELECT
		@sort_order = COALESCE(z.sort_order, '')
	FROM
	(
		SELECT
			STUFF
			(
				(
					SELECT
						',' + column_name as [text()]
					FROM ordered_columns
					WHERE
						r = 1
					ORDER BY
						number
					FOR XML
						PATH('')
				),
				1,
				1,
				''
			) AS sort_order
	) AS z;

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NOT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io BIGINT NULL,
		reads BIGINT NULL,
		physical_reads BIGINT NULL,
		writes BIGINT NULL,
		tempdb_allocations BIGINT NULL,
		tempdb_current BIGINT NULL,
		CPU INT NULL,
		thread_CPU_snapshot BIGINT NULL,
		context_switches BIGINT NULL,
		used_memory BIGINT NOT NULL, 
		tasks SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info NVARCHAR(4000) NULL,
		locks XML NULL,
		transaction_id BIGINT NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes NVARCHAR(4000) NULL,
		open_tran_count SMALLINT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		blocked_session_count SMALLINT NULL,
		percent_complete REAL NULL,
		host_name sysname NULL,
		login_name sysname NOT NULL,
		database_name sysname NULL,
		program_name sysname NULL,
		additional_info XML NULL,
		start_time DATETIME NOT NULL,
		login_time DATETIME NULL,
		last_request_start_time DATETIME NULL,
		PRIMARY KEY CLUSTERED (session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON),
		UNIQUE NONCLUSTERED (transaction_id, session_id, request_id, recursion) WITH (IGNORE_DUP_KEY = ON)
	);

	IF @return_schema = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_transaction_id ON #sessions (transaction_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @delta_interval
				WHEN 0 THEN 1
				ELSE -1
			END;

		DECLARE @first_collection_ms_ticks BIGINT;
		DECLARE @last_collection_start DATETIME;

		--Used for the delta pull
		REDO:;
		
		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.database_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				s.request_id,
				s.start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name,
				CONVERT(NVARCHAR(2048), NULL) AS query_error
			INTO #locks
			FROM
			(
				SELECT
					sp.spid AS session_id,
					CASE sp.status
						WHEN 'sleeping' THEN CONVERT(INT, 0)
						ELSE sp.request_id
					END AS request_id,
					CASE sp.status
						WHEN 'sleeping' THEN sp.last_batch
						ELSE COALESCE(req.start_time, sp.last_batch)
					END AS start_time,
					sp.dbid
				FROM sys.sysprocesses AS sp
				OUTER APPLY
				(
					SELECT TOP(1)
						CASE
							WHEN 
							(
								sp.hostprocess > ''
								OR r.total_elapsed_time < 0
							) THEN
								r.start_time
							ELSE
								DATEADD
								(
									ms, 
									1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())), 
									DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
								)
						END AS start_time
					FROM sys.dm_exec_requests AS r
					WHERE
						r.session_id = sp.spid
						AND r.request_id = sp.request_id
				) AS req
				WHERE
					--Process inclusive filter
					1 =
						CASE
							WHEN @filter <> '' THEN
								CASE @filter_type
									WHEN 'session' THEN
										CASE
											WHEN
												CONVERT(SMALLINT, @filter) = 0
												OR sp.spid = CONVERT(SMALLINT, @filter)
													THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 1
						END
					--Process exclusive filter
					AND 0 =
						CASE
							WHEN @not_filter <> '' THEN
								CASE @not_filter_type
									WHEN 'session' THEN
										CASE
											WHEN sp.spid = CONVERT(SMALLINT, @not_filter) THEN 1
											ELSE 0
										END
									WHEN 'program' THEN
										CASE
											WHEN sp.program_name LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'login' THEN
										CASE
											WHEN sp.loginame LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'host' THEN
										CASE
											WHEN sp.hostname LIKE @not_filter THEN 1
											ELSE 0
										END
									WHEN 'database' THEN
										CASE
											WHEN DB_NAME(sp.dbid) LIKE @not_filter THEN 1
											ELSE 0
										END
									ELSE 0
								END
							ELSE 0
						END
					AND 
					(
						@show_own_spid = 1
						OR sp.spid <> @@SPID
					)
					AND 
					(
						@show_system_spids = 1
						OR sp.hostprocess > ''
					)
					AND sp.ecid = 0
			) AS s
			INNER HASH JOIN
			(
				SELECT
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR (x.page_no - 1) % 511232 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR (x.page_no - 6) % 511232 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR (x.page_no - 7) % 511232 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type +
							CASE
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), N'(null)') AS database_name,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('object_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('object_id = ', tl.resource_description) + 12),
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('object_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description)
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END
						) AS page_no,
						CASE
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('index_id or stats_id = ', tl.resource_description) + 23)
										)
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('schema_id = ', tl.resource_description) + 12), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('schema_id = ', tl.resource_description) + 12), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('schema_id = ', tl.resource_description) + 12)
										)
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SUBSTRING
										(
											tl.resource_description, 
											(CHARINDEX('principal_id = ', tl.resource_description) + 15), 
											COALESCE
											(
												NULLIF
												(
													CHARINDEX(',', tl.resource_description, CHARINDEX('principal_id = ', tl.resource_description) + 15), 
													0
												), 
												DATALENGTH(tl.resource_description)+1
											) - (CHARINDEX('principal_id = ', tl.resource_description) + 15)
										)
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,

						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM 
					(
						SELECT 
							request_session_id,
							CONVERT(VARCHAR(120), resource_type) COLLATE Latin1_General_Bin2 AS resource_type,
							CONVERT(VARCHAR(120), resource_subtype) COLLATE Latin1_General_Bin2 AS resource_subtype,
							resource_database_id,
							CONVERT(VARCHAR(512), resource_description) COLLATE Latin1_General_Bin2 AS resource_description,
							resource_associated_entity_id,
							CONVERT(VARCHAR(120), request_mode) COLLATE Latin1_General_Bin2 AS request_mode,
							CONVERT(VARCHAR(120), request_status) COLLATE Latin1_General_Bin2 AS request_status,
							request_request_id
						FROM sys.dm_tran_locks
					) AS tl
				) AS x
				GROUP BY
					x.resource_type,
					x.database_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR (x.page_no - 1) % 511232 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR (x.page_no - 6) % 511232 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR (x.page_no - 7) % 511232 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) AS y ON
				y.session_id = s.session_id
				AND y.request_id = s.request_id
			OPTION (HASH GROUP);

			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_database_name ON #locks (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE 
			@sql VARCHAR(MAX), 
			@sql_n NVARCHAR(MAX);

		SET @sql = 
			CONVERT(VARCHAR(MAX), '') +
			'DECLARE @blocker BIT;
			SET @blocker = 0;
			DECLARE @i INT;
			SET @i = 2147483647;

			DECLARE @sessions TABLE
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				login_time DATETIME,
				last_request_end_time DATETIME,
				status VARCHAR(30),
				statement_start_offset INT,
				statement_end_offset INT,
				sql_handle BINARY(20),
				host_name NVARCHAR(128),
				login_name NVARCHAR(128),
				program_name NVARCHAR(128),
				database_id SMALLINT,
				memory_usage INT,
				open_tran_count SMALLINT, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0 
						OR @find_block_leaders = 1 
					) THEN
						'wait_type NVARCHAR(32),
						wait_resource NVARCHAR(256),
						wait_time BIGINT, 
						'
					ELSE 
						''
				END +
				'blocked SMALLINT,
				is_user_process BIT,
				cmd VARCHAR(32),
				PRIMARY KEY CLUSTERED (session_id, request_id) WITH (IGNORE_DUP_KEY = ON)
			);

			DECLARE @blockers TABLE
			(
				session_id INT NOT NULL PRIMARY KEY WITH (IGNORE_DUP_KEY = ON)
			);

			BLOCKERS:;

			INSERT @sessions
			(
				session_id,
				request_id,
				login_time,
				last_request_end_time,
				status,
				statement_start_offset,
				statement_end_offset,
				sql_handle,
				host_name,
				login_name,
				program_name,
				database_id,
				memory_usage,
				open_tran_count, 
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0
						OR @find_block_leaders = 1 
					) THEN
						'wait_type,
						wait_resource,
						wait_time, 
						'
					ELSE
						''
				END +
				'blocked,
				is_user_process,
				cmd 
			)
			SELECT TOP(@i)
				spy.session_id,
				spy.request_id,
				spy.login_time,
				spy.last_request_end_time,
				spy.status,
				spy.statement_start_offset,
				spy.statement_end_offset,
				spy.sql_handle,
				spy.host_name,
				spy.login_name,
				spy.program_name,
				spy.database_id,
				spy.memory_usage,
				spy.open_tran_count,
				' +
				CASE
					WHEN 
					(
						@get_task_info <> 0  
						OR @find_block_leaders = 1 
					) THEN
						'spy.wait_type,
						CASE
							WHEN
								spy.wait_type LIKE N''PAGE%LATCH_%''
								OR spy.wait_type = N''CXPACKET''
								OR spy.wait_type LIKE N''LATCH[_]%''
								OR spy.wait_type = N''OLEDB'' THEN
									spy.wait_resource
							ELSE
								NULL
						END AS wait_resource,
						spy.wait_time, 
						'
					ELSE
						''
				END +
				'spy.blocked,
				spy.is_user_process,
				spy.cmd
			FROM
			(
				SELECT TOP(@i)
					spx.*, 
					' +
					CASE
						WHEN 
						(
							@get_task_info <> 0 
							OR @find_block_leaders = 1 
						) THEN
							'ROW_NUMBER() OVER
							(
								PARTITION BY
									spx.session_id,
									spx.request_id
								ORDER BY
									CASE
										WHEN spx.wait_type LIKE N''LCK[_]%'' THEN 
											1
										ELSE
											99
									END,
									spx.wait_time DESC,
									spx.blocked DESC
							) AS r 
							'
						ELSE 
							'1 AS r 
							'
					END +
				'FROM
				(
					SELECT TOP(@i)
						sp0.session_id,
						sp0.request_id,
						sp0.login_time,
						sp0.last_request_end_time,
						LOWER(sp0.status) AS status,
						CASE
							WHEN sp0.cmd = ''CREATE INDEX'' THEN
								0
							ELSE
								sp0.stmt_start
						END AS statement_start_offset,
						CASE
							WHEN sp0.cmd = N''CREATE INDEX'' THEN
								-1
							ELSE
								COALESCE(NULLIF(sp0.stmt_end, 0), -1)
						END AS statement_end_offset,
						sp0.sql_handle,
						sp0.host_name,
						sp0.login_name,
						sp0.program_name,
						sp0.database_id,
						sp0.memory_usage,
						sp0.open_tran_count, 
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0 
								OR @find_block_leaders = 1 
							) THEN
								'CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_type
									ELSE
										NULL
								END AS wait_type,
								CASE
									WHEN sp0.wait_time > 0 AND sp0.wait_type <> N''CXPACKET'' THEN 
										sp0.wait_resource
									ELSE
										NULL
								END AS wait_resource,
								CASE
									WHEN sp0.wait_type <> N''CXPACKET'' THEN
										sp0.wait_time
									ELSE
										0
								END AS wait_time, 
								'
							ELSE
								''
						END +
						'sp0.blocked,
						sp0.is_user_process,
						sp0.cmd
					FROM
					(
						SELECT TOP(@i)
							sp1.session_id,
							sp1.request_id,
							sp1.login_time,
							sp1.last_request_end_time,
							sp1.status,
							sp1.cmd,
							sp1.stmt_start,
							sp1.stmt_end,
							MAX(NULLIF(sp1.sql_handle, 0x00)) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS sql_handle,
							sp1.host_name,
							MAX(sp1.login_name) OVER (PARTITION BY sp1.session_id, sp1.request_id) AS login_name,
							sp1.program_name,
							sp1.database_id,
							MAX(sp1.memory_usage)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS memory_usage,
							MAX(sp1.open_tran_count)  OVER (PARTITION BY sp1.session_id, sp1.request_id) AS open_tran_count,
							sp1.wait_type,
							sp1.wait_resource,
							sp1.wait_time,
							sp1.blocked,
							sp1.hostprocess,
							sp1.is_user_process
						FROM
						(
							SELECT TOP(@i)
								sp2.spid AS session_id,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END AS request_id,
								MAX(sp2.login_time) AS login_time,
								MAX(sp2.last_batch) AS last_request_end_time,
								MAX(CONVERT(VARCHAR(30), RTRIM(sp2.status)) COLLATE Latin1_General_Bin2) AS status,
								MAX(CONVERT(VARCHAR(32), RTRIM(sp2.cmd)) COLLATE Latin1_General_Bin2) AS cmd,
								MAX(sp2.stmt_start) AS stmt_start,
								MAX(sp2.stmt_end) AS stmt_end,
								MAX(sp2.sql_handle) AS sql_handle,
								MAX(CONVERT(sysname, RTRIM(sp2.hostname)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS host_name,
								MAX(CONVERT(sysname, RTRIM(sp2.loginame)) COLLATE SQL_Latin1_General_CP1_CI_AS) AS login_name,
								MAX
								(
									CASE
										WHEN blk.queue_id IS NOT NULL THEN
											N''Service Broker
												database_id: '' + CONVERT(NVARCHAR, blk.database_id) +
												N'' queue_id: '' + CONVERT(NVARCHAR, blk.queue_id)
										ELSE
											CONVERT
											(
												sysname,
												RTRIM(sp2.program_name)
											)
									END COLLATE SQL_Latin1_General_CP1_CI_AS
								) AS program_name,
								MAX(sp2.dbid) AS database_id,
								MAX(sp2.memusage) AS memory_usage,
								MAX(sp2.open_tran) AS open_tran_count,
								RTRIM(sp2.lastwaittype) AS wait_type,
								RTRIM(sp2.waitresource) AS wait_resource,
								MAX(sp2.waittime) AS wait_time,
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0) AS blocked,
								MAX
								(
									CASE
										WHEN blk.session_id = sp2.spid THEN
											''blocker''
										ELSE
											RTRIM(sp2.hostprocess)
									END
								) AS hostprocess,
								CONVERT
								(
									BIT,
									MAX
									(
										CASE
											WHEN sp2.hostprocess > '''' THEN
												1
											ELSE
												0
										END
									)
								) AS is_user_process
							FROM
							(
								SELECT TOP(@i)
									session_id,
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								FROM @blockers

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, 0),
									CONVERT(INT, NULL) AS queue_id,
									CONVERT(INT, NULL) AS database_id
								WHERE
									@blocker = 0

								UNION ALL

								SELECT TOP(@i)
									CONVERT(SMALLINT, spid),
									queue_id,
									database_id
								FROM sys.dm_broker_activated_tasks
								WHERE
									@blocker = 0
							) AS blk
							INNER JOIN sys.sysprocesses AS sp2 ON
								sp2.spid = blk.session_id
								OR
								(
									blk.session_id = 0
									AND @blocker = 0
								)
							' +
							CASE 
								WHEN 
								(
									@get_task_info = 0 
									AND @find_block_leaders = 0
								) THEN
									'WHERE
										sp2.ecid = 0 
									' 
								ELSE
									''
							END +
							'GROUP BY
								sp2.spid,
								CASE sp2.status
									WHEN ''sleeping'' THEN
										CONVERT(INT, 0)
									ELSE
										sp2.request_id
								END,
								RTRIM(sp2.lastwaittype),
								RTRIM(sp2.waitresource),
								COALESCE(NULLIF(sp2.blocked, sp2.spid), 0)
						) AS sp1
					) AS sp0
					WHERE
						@blocker = 1
						OR
						(1=1 
						' +
							--inclusive filter
							CASE
								WHEN @filter <> '' THEN
									CASE @filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @filter) <> 0 THEN
													'AND sp0.session_id = CONVERT(SMALLINT, @filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name LIKE @filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name LIKE @filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name LIKE @filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) LIKE @filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							--exclusive filter
							CASE
								WHEN @not_filter <> '' THEN
									CASE @not_filter_type
										WHEN 'session' THEN
											CASE
												WHEN CONVERT(SMALLINT, @not_filter) <> 0 THEN
													'AND sp0.session_id <> CONVERT(SMALLINT, @not_filter) 
													'
												ELSE
													''
											END
										WHEN 'program' THEN
											'AND sp0.program_name NOT LIKE @not_filter 
											'
										WHEN 'login' THEN
											'AND sp0.login_name NOT LIKE @not_filter 
											'
										WHEN 'host' THEN
											'AND sp0.host_name NOT LIKE @not_filter 
											'
										WHEN 'database' THEN
											'AND DB_NAME(sp0.database_id) NOT LIKE @not_filter 
											'
										ELSE
											''
									END
								ELSE
									''
							END +
							CASE @show_own_spid
								WHEN 1 THEN
									''
								ELSE
									'AND sp0.session_id <> @@spid 
									'
							END +
							CASE 
								WHEN @show_system_spids = 0 THEN
									'AND sp0.hostprocess > '''' 
									' 
								ELSE
									''
							END +
							CASE @show_sleeping_spids
								WHEN 0 THEN
									'AND sp0.status <> ''sleeping'' 
									'
								WHEN 1 THEN
									'AND
									(
										sp0.status <> ''sleeping''
										OR sp0.open_tran_count > 0
									)
									'
								ELSE
									''
							END +
						')
				) AS spx
			) AS spy
			WHERE
				spy.r = 1; 
			' + 
			CASE @recursion
				WHEN 1 THEN 
					'IF @@ROWCOUNT > 0
					BEGIN;
						INSERT @blockers
						(
							session_id
						)
						SELECT TOP(@i)
							blocked
						FROM @sessions
						WHERE
							NULLIF(blocked, 0) IS NOT NULL

						EXCEPT

						SELECT TOP(@i)
							session_id
						FROM @sessions; 
						' +

						CASE
							WHEN
							(
								@get_task_info > 0
								OR @find_block_leaders = 1
							) THEN
								'IF @@ROWCOUNT > 0
								BEGIN;
									SET @blocker = 1;
									GOTO BLOCKERS;
								END; 
								'
							ELSE 
								''
						END +
					'END; 
					'
				ELSE 
					''
			END +
			'SELECT TOP(@i)
				@recursion AS recursion,
				x.session_id,
				x.request_id,
				DENSE_RANK() OVER
				(
					ORDER BY
						x.session_id
				) AS session_number,
				' +
				CASE
					WHEN @output_column_list LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 
						'x.elapsed_time '
					ELSE 
						'0 '
				END + 
					'AS elapsed_time, 
					' +
				CASE
					WHEN
						(
							@output_column_list LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
							@output_column_list LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.avg_elapsed_time / 1000 '
					ELSE 
						'NULL '
				END + 
					'AS avg_elapsed_time, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_io|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_io_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_io '
					ELSE 
						'NULL '
				END + 
					'AS physical_io, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[reads_delta|]%' ESCAPE '|'
							THEN 
								'x.reads '
					ELSE 
						'0 '
				END + 
					'AS reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[physical_reads|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
							THEN 
								'x.physical_reads '
					ELSE 
						'0 '
				END + 
					'AS physical_reads, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[writes|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[writes_delta|]%' ESCAPE '|'
							THEN 
								'x.writes '
					ELSE 
						'0 '
				END + 
					'AS writes, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_allocations|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_allocations_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_allocations '
					ELSE 
						'0 '
				END + 
					'AS tempdb_allocations, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tempdb_current|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
							THEN 
								'x.tempdb_current '
					ELSE 
						'0 '
				END + 
					'AS tempdb_current, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
							THEN
								'x.CPU '
					ELSE
						'0 '
				END + 
					'AS CPU, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
						AND @get_task_info = 2
							THEN 
								'x.thread_CPU_snapshot '
					ELSE 
						'0 '
				END + 
					'AS thread_CPU_snapshot, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[context_switches|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[context_switches_delta|]%' ESCAPE '|'
							THEN 
								'x.context_switches '
					ELSE 
						'NULL '
				END + 
					'AS context_switches, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[used_memory|]%' ESCAPE '|'
						OR @output_column_list LIKE '%|[used_memory_delta|]%' ESCAPE '|'
							THEN 
								'x.used_memory '
					ELSE 
						'0 '
				END + 
					'AS used_memory, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[tasks|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.tasks '
					ELSE 
						'NULL '
				END + 
					'AS tasks, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[status|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 
								'x.status '
					ELSE 
						''''' '
				END + 
					'AS status, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[wait_info|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								CASE @get_task_info
									WHEN 2 THEN
										'COALESCE(x.task_wait_info, x.sys_wait_info) '
									ELSE
										'x.sys_wait_info '
								END
					ELSE 
						'NULL '
				END + 
					'AS wait_info, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.transaction_id '
					ELSE 
						'NULL '
				END + 
					'AS transaction_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[open_tran_count|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.open_tran_count '
					ELSE 
						'NULL '
				END + 
					'AS open_tran_count, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.sql_handle '
					ELSE 
						'NULL '
				END + 
					'AS sql_handle, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_start_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_start_offset, 
					' +
				CASE
					WHEN 
						(
							@output_column_list LIKE '%|[sql_text|]%' ESCAPE '|' 
							OR @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						)
						AND @recursion = 1
							THEN 
								'x.statement_end_offset '
					ELSE 
						'NULL '
				END + 
					'AS statement_end_offset, 
					' +
				'NULL AS sql_text, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[query_plan|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.plan_handle '
					ELSE 
						'NULL '
				END + 
					'AS plan_handle, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'NULLIF(x.blocking_session_id, 0) '
					ELSE 
						'NULL '
				END + 
					'AS blocking_session_id, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[percent_complete|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 
								'x.percent_complete '
					ELSE 
						'NULL '
				END + 
					'AS percent_complete, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[host_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.host_name '
					ELSE 
						''''' '
				END + 
					'AS host_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[login_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.login_name '
					ELSE 
						''''' '
				END + 
					'AS login_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[database_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'DB_NAME(x.database_id) '
					ELSE 
						'NULL '
				END + 
					'AS database_name, 
					' +
				CASE
					WHEN 
						@output_column_list LIKE '%|[program_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
								'x.program_name '
					ELSE 
						''''' '
				END + 
					'AS program_name, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'(
									SELECT TOP(@i)
										x.text_size,
										x.language,
										x.date_format,
										x.date_first,
										CASE x.quoted_identifier
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS quoted_identifier,
										CASE x.arithabort
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS arithabort,
										CASE x.ansi_null_dflt_on
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_null_dflt_on,
										CASE x.ansi_defaults
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_defaults,
										CASE x.ansi_warnings
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_warnings,
										CASE x.ansi_padding
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_padding,
										CASE ansi_nulls
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS ansi_nulls,
										CASE x.concat_null_yields_null
											WHEN 0 THEN ''OFF''
											WHEN 1 THEN ''ON''
										END AS concat_null_yields_null,
										CASE x.transaction_isolation_level
											WHEN 0 THEN ''Unspecified''
											WHEN 1 THEN ''ReadUncomitted''
											WHEN 2 THEN ''ReadCommitted''
											WHEN 3 THEN ''Repeatable''
											WHEN 4 THEN ''Serializable''
											WHEN 5 THEN ''Snapshot''
										END AS transaction_isolation_level,
										x.lock_timeout,
										x.deadlock_priority,
										x.row_count,
										x.command_type, 
										master.dbo.fn_varbintohexstr(x.sql_handle) AS sql_handle,
										master.dbo.fn_varbintohexstr(x.plan_handle) AS plan_handle,
										' +
										CASE
											WHEN @output_column_list LIKE '%|[program_name|]%' ESCAPE '|' THEN
												'(
													SELECT TOP(1)
														CONVERT(uniqueidentifier, CONVERT(XML, '''').value(''xs:hexBinary( substring(sql:column("agent_info.job_id_string"), 0) )'', ''binary(16)'')) AS job_id,
														agent_info.step_id,
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''job_name''),
																TYPE
														),
														(
															SELECT TOP(1)
																NULL
															FOR XML
																PATH(''step_name''),
																TYPE
														)
													FROM
													(
														SELECT TOP(1)
															SUBSTRING(x.program_name, CHARINDEX(''0x'', x.program_name) + 2, 32) AS job_id_string,
															SUBSTRING(x.program_name, CHARINDEX('': Step '', x.program_name) + 7, CHARINDEX('')'', x.program_name, CHARINDEX('': Step '', x.program_name)) - (CHARINDEX('': Step '', x.program_name) + 7)) AS step_id
														WHERE
															x.program_name LIKE N''SQLAgent - TSQL JobStep (Job 0x%''
													) AS agent_info
													FOR XML
														PATH(''agent_job_info''),
														TYPE
												),
												'
											ELSE ''
										END +
										CASE
											WHEN @get_task_info = 2 THEN
												'CONVERT(XML, x.block_info) AS block_info, 
												'
											ELSE
												''
										END +
										'x.host_process_id 
									FOR XML
										PATH(''additional_info''),
										TYPE
								) '
					ELSE
						'NULL '
				END + 
					'AS additional_info, 
				x.start_time, 
					' +
				CASE
					WHEN
						@output_column_list LIKE '%|[login_time|]%' ESCAPE '|'
						AND @recursion = 1
							THEN
								'x.login_time '
					ELSE 
						'NULL '
				END + 
					'AS login_time, 
				x.last_request_start_time
			FROM
			(
				SELECT TOP(@i)
					y.*,
					CASE
						WHEN DATEDIFF(hour, y.start_time, GETDATE()) > 576 THEN
							DATEDIFF(second, GETDATE(), y.start_time)
						ELSE DATEDIFF(ms, y.start_time, GETDATE())
					END AS elapsed_time,
					COALESCE(tempdb_info.tempdb_allocations, 0) AS tempdb_allocations,
					COALESCE
					(
						CASE
							WHEN tempdb_info.tempdb_current < 0 THEN 0
							ELSE tempdb_info.tempdb_current
						END,
						0
					) AS tempdb_current, 
					' +
					CASE
						WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1
							) THEN
								'N''('' + CONVERT(NVARCHAR, y.wait_duration_ms) + N''ms)'' +
									y.wait_type +
										CASE
											WHEN y.wait_type LIKE N''PAGE%LATCH_%'' THEN
												N'':'' +
												COALESCE(DB_NAME(CONVERT(INT, LEFT(y.resource_description, CHARINDEX(N'':'', y.resource_description) - 1))), N''(null)'') +
												N'':'' +
												SUBSTRING(y.resource_description, CHARINDEX(N'':'', y.resource_description) + 1, LEN(y.resource_description) - CHARINDEX(N'':'', REVERSE(y.resource_description)) - CHARINDEX(N'':'', y.resource_description)) +
												N''('' +
													CASE
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 1 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 8088 = 0
																THEN 
																	N''PFS''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 2 OR
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) % 511232 = 0
																THEN 
																	N''GAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 3 OR
															(CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) - 1) % 511232 = 0
																THEN
																	N''SGAM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 6 OR
															(CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) - 6) % 511232 = 0 
																THEN 
																	N''DCM''
														WHEN
															CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) = 7 OR
															(CONVERT(INT, RIGHT(y.resource_description, CHARINDEX(N'':'', REVERSE(y.resource_description)) - 1)) - 7) % 511232 = 0 
																THEN 
																	N''BCM''
														ELSE 
															N''*''
													END +
												N'')''
											WHEN y.wait_type = N''CXPACKET'' THEN
												N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''nodeId'', y.resource_description) + 7, 4)
											WHEN y.wait_type LIKE N''LATCH[_]%'' THEN
												N'' ['' + LEFT(y.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', y.resource_description), 0), LEN(y.resource_description) + 1) - 1) + N'']''
											WHEN
												y.wait_type = N''OLEDB''
												AND y.resource_description LIKE N''%(SPID=%)'' THEN
													N''['' + LEFT(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) - 2) +
														N'':'' + SUBSTRING(y.resource_description, CHARINDEX(N''(SPID='', y.resource_description) + 6, CHARINDEX(N'')'', y.resource_description, (CHARINDEX(N''(SPID='', y.resource_description) + 6)) - (CHARINDEX(N''(SPID='', y.resource_description) + 6)) + '']''
											ELSE
												N''''
										END COLLATE Latin1_General_Bin2 AS sys_wait_info, 
										'
							ELSE
								''
						END +
						CASE
							WHEN @get_task_info = 2 THEN
								'tasks.physical_io,
								tasks.context_switches,
								tasks.tasks,
								tasks.block_info,
								tasks.wait_info AS task_wait_info,
								tasks.thread_CPU_snapshot,
								'
							ELSE
								'' 
					END +
					CASE 
						WHEN NOT (@get_avg_time = 1 AND @recursion = 1) THEN
							'CONVERT(INT, NULL) '
						ELSE 
							'qs.total_elapsed_time / qs.execution_count '
					END + 
						'AS avg_elapsed_time 
				FROM
				(
					SELECT TOP(@i)
						sp.session_id,
						sp.request_id,
						COALESCE(r.logical_reads, s.logical_reads) AS reads,
						COALESCE(r.reads, s.reads) AS physical_reads,
						COALESCE(r.writes, s.writes) AS writes,
						COALESCE(r.CPU_time, s.CPU_time) AS CPU,
						sp.memory_usage + COALESCE(r.granted_query_memory, 0) AS used_memory,
						LOWER(sp.status) AS status,
						COALESCE(r.sql_handle, sp.sql_handle) AS sql_handle,
						COALESCE(r.statement_start_offset, sp.statement_start_offset) AS statement_start_offset,
						COALESCE(r.statement_end_offset, sp.statement_end_offset) AS statement_end_offset,
						' +
						CASE
							WHEN 
							(
								@get_task_info <> 0
								OR @find_block_leaders = 1 
							) THEN
								'sp.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
								sp.wait_resource COLLATE Latin1_General_Bin2 AS resource_description,
								sp.wait_time AS wait_duration_ms, 
								'
							ELSE
								''
						END +
						'NULLIF(sp.blocked, 0) AS blocking_session_id,
						r.plan_handle,
						NULLIF(r.percent_complete, 0) AS percent_complete,
						sp.host_name,
						sp.login_name,
						sp.program_name,
						s.host_process_id,
						COALESCE(r.text_size, s.text_size) AS text_size,
						COALESCE(r.language, s.language) AS language,
						COALESCE(r.date_format, s.date_format) AS date_format,
						COALESCE(r.date_first, s.date_first) AS date_first,
						COALESCE(r.quoted_identifier, s.quoted_identifier) AS quoted_identifier,
						COALESCE(r.arithabort, s.arithabort) AS arithabort,
						COALESCE(r.ansi_null_dflt_on, s.ansi_null_dflt_on) AS ansi_null_dflt_on,
						COALESCE(r.ansi_defaults, s.ansi_defaults) AS ansi_defaults,
						COALESCE(r.ansi_warnings, s.ansi_warnings) AS ansi_warnings,
						COALESCE(r.ansi_padding, s.ansi_padding) AS ansi_padding,
						COALESCE(r.ansi_nulls, s.ansi_nulls) AS ansi_nulls,
						COALESCE(r.concat_null_yields_null, s.concat_null_yields_null) AS concat_null_yields_null,
						COALESCE(r.transaction_isolation_level, s.transaction_isolation_level) AS transaction_isolation_level,
						COALESCE(r.lock_timeout, s.lock_timeout) AS lock_timeout,
						COALESCE(r.deadlock_priority, s.deadlock_priority) AS deadlock_priority,
						COALESCE(r.row_count, s.row_count) AS row_count,
						COALESCE(r.command, sp.cmd) AS command_type,
						COALESCE
						(
							CASE
								WHEN
								(
									s.is_user_process = 0
									AND r.total_elapsed_time >= 0
								) THEN
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									)
							END,
							NULLIF(COALESCE(r.start_time, sp.last_request_end_time), CONVERT(DATETIME, ''19000101'', 112)),
							(
								SELECT TOP(1)
									DATEADD(second, -(ms_ticks / 1000), GETDATE())
								FROM sys.dm_os_sys_info
							)
						) AS start_time,
						sp.login_time,
						CASE
							WHEN s.is_user_process = 1 THEN
								s.last_request_start_time
							ELSE
								COALESCE
								(
									DATEADD
									(
										ms,
										1000 * (DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())) / 500) - DATEPART(ms, DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())),
										DATEADD(second, -(r.total_elapsed_time / 1000), GETDATE())
									),
									s.last_request_start_time
								)
						END AS last_request_start_time,
						r.transaction_id,
						sp.database_id,
						sp.open_tran_count
					FROM @sessions AS sp
					LEFT OUTER LOOP JOIN sys.dm_exec_sessions AS s ON
						s.session_id = sp.session_id
						AND s.login_time = sp.login_time
					LEFT OUTER LOOP JOIN sys.dm_exec_requests AS r ON
						sp.status <> ''sleeping''
						AND r.session_id = sp.session_id
						AND r.request_id = sp.request_id
						AND
						(
							(
								s.is_user_process = 0
								AND sp.is_user_process = 0
							)
							OR
							(
								r.start_time = s.last_request_start_time
								AND s.last_request_end_time <= sp.last_request_end_time
							)
						)
				) AS y
				' + 
				CASE 
					WHEN @get_task_info = 2 THEN
						CONVERT(VARCHAR(MAX), '') +
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								task_nodes.task_node.value(''(session_id/text())[1]'', ''SMALLINT'') AS session_id,
								task_nodes.task_node.value(''(request_id/text())[1]'', ''INT'') AS request_id,
								task_nodes.task_node.value(''(physical_io/text())[1]'', ''BIGINT'') AS physical_io,
								task_nodes.task_node.value(''(context_switches/text())[1]'', ''BIGINT'') AS context_switches,
								task_nodes.task_node.value(''(tasks/text())[1]'', ''INT'') AS tasks,
								task_nodes.task_node.value(''(block_info/text())[1]'', ''NVARCHAR(4000)'') AS block_info,
								task_nodes.task_node.value(''(waits/text())[1]'', ''NVARCHAR(4000)'') AS wait_info,
								task_nodes.task_node.value(''(thread_CPU_snapshot/text())[1]'', ''BIGINT'') AS thread_CPU_snapshot
							FROM
							(
								SELECT TOP(@i)
									CONVERT
									(
										XML,
										REPLACE
										(
											CONVERT(NVARCHAR(MAX), tasks_raw.task_xml_raw) COLLATE Latin1_General_Bin2,
											N''</waits></tasks><tasks><waits>'',
											N'', ''
										)
									) AS task_xml
								FROM
								(
									SELECT TOP(@i)
										CASE waits.r
											WHEN 1 THEN
												waits.session_id
											ELSE
												NULL
										END AS [session_id],
										CASE waits.r
											WHEN 1 THEN
												waits.request_id
											ELSE
												NULL
										END AS [request_id],											
										CASE waits.r
											WHEN 1 THEN
												waits.physical_io
											ELSE
												NULL
										END AS [physical_io],
										CASE waits.r
											WHEN 1 THEN
												waits.context_switches
											ELSE
												NULL
										END AS [context_switches],
										CASE waits.r
											WHEN 1 THEN
												waits.thread_CPU_snapshot
											ELSE
												NULL
										END AS [thread_CPU_snapshot],
										CASE waits.r
											WHEN 1 THEN
												waits.tasks
											ELSE
												NULL
										END AS [tasks],
										CASE waits.r
											WHEN 1 THEN
												waits.block_info
											ELSE
												NULL
										END AS [block_info],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													NVARCHAR(MAX),
													N''('' +
														CONVERT(NVARCHAR, num_waits) + N''x: '' +
														CASE num_waits
															WHEN 1 THEN
																CONVERT(NVARCHAR, min_wait_time) + N''ms''
															WHEN 2 THEN
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
															ELSE
																CASE
																	WHEN min_wait_time <> max_wait_time THEN
																		CONVERT(NVARCHAR, min_wait_time) + N''/'' + CONVERT(NVARCHAR, avg_wait_time) + N''/'' + CONVERT(NVARCHAR, max_wait_time) + N''ms''
																	ELSE 
																		CONVERT(NVARCHAR, max_wait_time) + N''ms''
																END
														END +
													N'')'' + wait_type COLLATE Latin1_General_Bin2
												),
												NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
												NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
												NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
											NCHAR(0),
											N''''
										) AS [waits]
									FROM
									(
										SELECT TOP(@i)
											w1.*,
											ROW_NUMBER() OVER
											(
												PARTITION BY
													w1.session_id,
													w1.request_id
												ORDER BY
													w1.block_info DESC,
													w1.num_waits DESC,
													w1.wait_type
											) AS r
										FROM
										(
											SELECT TOP(@i)
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks AS tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END AS wait_type,
												NULLIF(COUNT(COALESCE(task_info.runnable_time, wt2.waiting_task_address)), 0) AS num_waits,
												MIN(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS min_wait_time,
												AVG(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS avg_wait_time,
												MAX(COALESCE(task_info.runnable_time, wt2.wait_duration_ms)) AS max_wait_time,
												MAX(wt2.block_info) AS block_info
											FROM
											(
												SELECT TOP(@i)
													t.session_id,
													t.request_id,
													SUM(CONVERT(BIGINT, t.pending_io_count)) OVER (PARTITION BY t.session_id, t.request_id) AS physical_io,
													SUM(CONVERT(BIGINT, t.context_switches_count)) OVER (PARTITION BY t.session_id, t.request_id) AS context_switches, 
													' +
													CASE
														WHEN @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
															THEN
																'SUM(tr.usermode_time + tr.kernel_time) OVER (PARTITION BY t.session_id, t.request_id) '
														ELSE
															'CONVERT(BIGINT, NULL) '
													END + 
														' AS thread_CPU_snapshot, 
													COUNT(*) OVER (PARTITION BY t.session_id, t.request_id) AS num_tasks,
													t.task_address,
													t.task_state,
													CASE
														WHEN
															t.task_state = ''RUNNABLE''
															AND w.runnable_time > 0 THEN
																w.runnable_time
														ELSE
															NULL
													END AS runnable_time
												FROM sys.dm_os_tasks AS t
												CROSS APPLY
												(
													SELECT TOP(1)
														sp2.session_id
													FROM @sessions AS sp2
													WHERE
														sp2.session_id = t.session_id
														AND sp2.request_id = t.request_id
														AND sp2.status <> ''sleeping''
												) AS sp20
												LEFT OUTER HASH JOIN
												(
													SELECT TOP(@i)
														(
															SELECT TOP(@i)
																ms_ticks
															FROM sys.dm_os_sys_info
														) -
															w0.wait_resumed_ms_ticks AS runnable_time,
														w0.worker_address,
														w0.thread_address,
														w0.task_bound_ms_ticks
													FROM sys.dm_os_workers AS w0
													WHERE
														w0.state = ''RUNNABLE''
														OR @first_collection_ms_ticks >= w0.task_bound_ms_ticks
												) AS w ON
													w.worker_address = t.worker_address 
												' +
												CASE
													WHEN @output_column_list LIKE '%|[CPU_delta|]%' ESCAPE '|'
														THEN
															'LEFT OUTER HASH JOIN sys.dm_os_threads AS tr ON
																tr.thread_address = w.thread_address
																AND @first_collection_ms_ticks >= w.task_bound_ms_ticks
															'
													ELSE
														''
												END +
											') AS task_info
											LEFT OUTER HASH JOIN
											(
												SELECT TOP(@i)
													wt1.wait_type,
													wt1.waiting_task_address,
													MAX(wt1.wait_duration_ms) AS wait_duration_ms,
													MAX(wt1.block_info) AS block_info
												FROM
												(
													SELECT DISTINCT TOP(@i)
														wt.wait_type +
															CASE
																WHEN wt.wait_type LIKE N''PAGE%LATCH_%'' THEN
																	'':'' +
																	COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) - 1))), N''(null)'') +
																	N'':'' +
																	SUBSTRING(wt.resource_description, CHARINDEX(N'':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX(N'':'', REVERSE(wt.resource_description)) - CHARINDEX(N'':'', wt.resource_description)) +
																	N''('' +
																		CASE
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 1 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0
																					THEN 
																						N''PFS''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 2 OR
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 
																					THEN 
																						N''GAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 3 OR
																				(CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) - 1) % 511232 = 0 
																					THEN 
																						N''SGAM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 6 OR
																				(CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) - 6) % 511232 = 0 
																					THEN 
																						N''DCM''
																			WHEN
																				CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) = 7 OR
																				(CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX(N'':'', REVERSE(wt.resource_description)) - 1)) - 7) % 511232 = 0
																					THEN 
																						N''BCM''
																			ELSE
																				N''*''
																		END +
																	N'')''
																WHEN wt.wait_type = N''CXPACKET'' THEN
																	N'':'' + SUBSTRING(wt.resource_description, CHARINDEX(N''nodeId'', wt.resource_description) + 7, 4)
																WHEN wt.wait_type LIKE N''LATCH[_]%'' THEN
																	N'' ['' + LEFT(wt.resource_description, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 1) + N'']''
																ELSE 
																	N''''
															END COLLATE Latin1_General_Bin2 AS wait_type,
														CASE
															WHEN
															(
																wt.blocking_session_id IS NOT NULL
																AND wt.wait_type LIKE N''LCK[_]%''
															) THEN
																(
																	SELECT TOP(@i)
																		x.lock_type,
																		REPLACE
																		(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																			REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
																				DB_NAME
																				(
																					CONVERT
																					(
																						INT,
																						SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''dbid='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''dbid='', wt.resource_description) + 5), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''dbid='', wt.resource_description) - 5)
																					)
																				),
																				NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''),
																				NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''),
																				NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''),
																			NCHAR(0),
																			N''''
																		) AS database_name,
																		CASE x.lock_type
																			WHEN N''objectlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''objid='', wt.resource_description), 0) + 6, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''objid='', wt.resource_description) + 6), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''objid='', wt.resource_description) - 6)
																			ELSE
																				NULL
																		END AS object_id,
																		CASE x.lock_type
																			WHEN N''filelock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''fileid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''fileid='', wt.resource_description) + 7), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''fileid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS file_id,
																		CASE
																			WHEN x.lock_type in (N''pagelock'', N''extentlock'', N''ridlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''associatedObjectId='', wt.resource_description), 0) + 19, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''associatedObjectId='', wt.resource_description) + 19), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''associatedObjectId='', wt.resource_description) - 19)
																			WHEN x.lock_type in (N''keylock'', N''hobtlock'', N''allocunitlock'') THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hobtid='', wt.resource_description), 0) + 7, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hobtid='', wt.resource_description) + 7), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''hobtid='', wt.resource_description) - 7)
																			ELSE
																				NULL
																		END AS hobt_id,
																		CASE x.lock_type
																			WHEN N''applicationlock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''hash='', wt.resource_description), 0) + 5, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''hash='', wt.resource_description) + 5), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''hash='', wt.resource_description) - 5)
																			ELSE
																				NULL
																		END AS applock_hash,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''subresource='', wt.resource_description), 0) + 12, COALESCE(NULLIF(CHARINDEX(N'' '', wt.resource_description, CHARINDEX(N''subresource='', wt.resource_description) + 12), 0), LEN(wt.resource_description) + 1) - CHARINDEX(N''subresource='', wt.resource_description) - 12)
																			ELSE
																				NULL
																		END AS metadata_resource,
																		CASE x.lock_type
																			WHEN N''metadatalock'' THEN
																				SUBSTRING(wt.resource_description, NULLIF(CHARINDEX(N''classid='', wt.resource_description), 0) + 8, COALESCE(NULLIF(CHARINDEX(N'' dbid='', wt.resource_description) - CHARINDEX(N''classid='', wt.resource_description), 0), LEN(wt.resource_description) + 1) - 8)
																			ELSE
																				NULL
																		END AS metadata_class_id
																	FROM
																	(
																		SELECT TOP(1)
																			LEFT(wt.resource_description, CHARINDEX(N'' '', wt.resource_description) - 1) COLLATE Latin1_General_Bin2 AS lock_type
																	) AS x
																	FOR XML
																		PATH('''')
																)
															ELSE NULL
														END AS block_info,
														wt.wait_duration_ms,
														wt.waiting_task_address
													FROM
													(
														SELECT TOP(@i)
															wt0.wait_type COLLATE Latin1_General_Bin2 AS wait_type,
															wt0.resource_description COLLATE Latin1_General_Bin2 AS resource_description,
															wt0.wait_duration_ms,
															wt0.waiting_task_address,
															CASE
																WHEN wt0.blocking_session_id = p.blocked THEN
																	wt0.blocking_session_id
																ELSE
																	NULL
															END AS blocking_session_id
														FROM sys.dm_os_waiting_tasks AS wt0
														CROSS APPLY
														(
															SELECT TOP(1)
																s0.blocked
															FROM @sessions AS s0
															WHERE
																s0.session_id = wt0.session_id
																AND COALESCE(s0.wait_type, N'''') <> N''OLEDB''
																AND wt0.wait_type <> N''OLEDB''
														) AS p
													) AS wt
												) AS wt1
												GROUP BY
													wt1.wait_type,
													wt1.waiting_task_address
											) AS wt2 ON
												wt2.waiting_task_address = task_info.task_address
												AND wt2.wait_duration_ms > 0
												AND task_info.runnable_time IS NULL
											GROUP BY
												task_info.session_id,
												task_info.request_id,
												task_info.physical_io,
												task_info.context_switches,
												task_info.thread_CPU_snapshot,
												task_info.num_tasks,
												CASE
													WHEN task_info.runnable_time IS NOT NULL THEN
														''RUNNABLE''
													ELSE
														wt2.wait_type
												END
										) AS w1
									) AS waits
									ORDER BY
										waits.session_id,
										waits.request_id,
										waits.r
									FOR XML
										PATH(N''tasks''),
										TYPE
								) AS tasks_raw (task_xml_raw)
							) AS tasks_final
							CROSS APPLY tasks_final.task_xml.nodes(N''/tasks'') AS task_nodes (task_node)
							WHERE
								task_nodes.task_node.exist(N''session_id'') = 1
						) AS tasks ON
							tasks.session_id = y.session_id
							AND tasks.request_id = y.request_id 
						'
					ELSE
						''
				END +
				'LEFT OUTER HASH JOIN
				(
					SELECT TOP(@i)
						t_info.session_id,
						COALESCE(t_info.request_id, -1) AS request_id,
						SUM(t_info.tempdb_allocations) AS tempdb_allocations,
						SUM(t_info.tempdb_current) AS tempdb_current
					FROM
					(
						SELECT TOP(@i)
							tsu.session_id,
							tsu.request_id,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count AS tempdb_allocations,
							tsu.user_objects_alloc_page_count +
								tsu.internal_objects_alloc_page_count -
								tsu.user_objects_dealloc_page_count -
								tsu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_task_space_usage AS tsu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = tsu.session_id
						) AS p

						UNION ALL

						SELECT TOP(@i)
							ssu.session_id,
							NULL AS request_id,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count AS tempdb_allocations,
							ssu.user_objects_alloc_page_count +
								ssu.internal_objects_alloc_page_count -
								ssu.user_objects_dealloc_page_count -
								ssu.internal_objects_dealloc_page_count AS tempdb_current
						FROM sys.dm_db_session_space_usage AS ssu
						CROSS APPLY
						(
							SELECT TOP(1)
								s0.session_id
							FROM @sessions AS s0
							WHERE
								s0.session_id = ssu.session_id
						) AS p
					) AS t_info
					GROUP BY
						t_info.session_id,
						COALESCE(t_info.request_id, -1)
				) AS tempdb_info ON
					tempdb_info.session_id = y.session_id
					AND tempdb_info.request_id =
						CASE
							WHEN y.status = N''sleeping'' THEN
								-1
							ELSE
								y.request_id
						END
				' +
				CASE 
					WHEN 
						NOT 
						(
							@get_avg_time = 1 
							AND @recursion = 1
						) THEN 
							''
					ELSE
						'LEFT OUTER HASH JOIN
						(
							SELECT TOP(@i)
								*
							FROM sys.dm_exec_query_stats
						) AS qs ON
							qs.sql_handle = y.sql_handle
							AND qs.plan_handle = y.plan_handle
							AND qs.statement_start_offset = y.statement_start_offset
							AND qs.statement_end_offset = y.statement_end_offset
						'
				END + 
			') AS x
			OPTION (KEEPFIXED PLAN, OPTIMIZE FOR (@i = 1)); ';

		SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

		SET @last_collection_start = GETDATE();

		IF @recursion = -1
		BEGIN;
			SELECT
				@first_collection_ms_ticks = ms_ticks
			FROM sys.dm_os_sys_info;
		END;

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_allocations,
			tempdb_current,
			CPU,
			thread_CPU_snapshot,
			context_switches,
			used_memory,
			tasks,
			status,
			wait_info,
			transaction_id,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			program_name,
			additional_info,
			start_time,
			login_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql_n,
			N'@recursion SMALLINT, @filter sysname, @not_filter sysname, @first_collection_ms_ticks BIGINT',
			@recursion, @filter, @not_filter, @first_collection_ms_ticks;

		--Collect transaction information?
		IF
			@recursion = 1
			AND
			(
				@output_column_list LIKE '%|[tran_start_time|]%' ESCAPE '|'
				OR @output_column_list LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
			)
		BEGIN;	
			DECLARE @i INT;
			SET @i = 2147483647;

			UPDATE s
			SET
				tran_start_time =
					CONVERT
					(
						DATETIME,
						LEFT
						(
							x.trans_info,
							NULLIF(CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info) - 1, -1)
						),
						121
					),
				tran_log_writes =
					RIGHT
					(
						x.trans_info,
						LEN(x.trans_info) - CHARINDEX(NCHAR(254) COLLATE Latin1_General_Bin2, x.trans_info)
					)
			FROM
			(
				SELECT TOP(@i)
					trans_nodes.trans_node.value('(session_id/text())[1]', 'SMALLINT') AS session_id,
					COALESCE(trans_nodes.trans_node.value('(request_id/text())[1]', 'INT'), 0) AS request_id,
					trans_nodes.trans_node.value('(trans_info/text())[1]', 'NVARCHAR(4000)') AS trans_info				
				FROM
				(
					SELECT TOP(@i)
						CONVERT
						(
							XML,
							REPLACE
							(
								CONVERT(NVARCHAR(MAX), trans_raw.trans_xml_raw) COLLATE Latin1_General_Bin2, 
								N'</trans_info></trans><trans><trans_info>', N''
							)
						)
					FROM
					(
						SELECT TOP(@i)
							CASE u_trans.r
								WHEN 1 THEN u_trans.session_id
								ELSE NULL
							END AS [session_id],
							CASE u_trans.r
								WHEN 1 THEN u_trans.request_id
								ELSE NULL
							END AS [request_id],
							CONVERT
							(
								NVARCHAR(MAX),
								CASE
									WHEN u_trans.database_id IS NOT NULL THEN
										CASE u_trans.r
											WHEN 1 THEN COALESCE(CONVERT(NVARCHAR, u_trans.transaction_start_time, 121) + NCHAR(254), N'')
											ELSE N''
										END + 
											REPLACE
											(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
													CONVERT(VARCHAR(128), COALESCE(DB_NAME(u_trans.database_id), N'(null)')),
													NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
													NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
													NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
												NCHAR(0),
												N'?'
											) +
											N': ' +
										CONVERT(NVARCHAR, u_trans.log_record_count) + N' (' + CONVERT(NVARCHAR, u_trans.log_kb_used) + N' kB)' +
										N','
									ELSE
										N'N/A,'
								END COLLATE Latin1_General_Bin2
							) AS [trans_info]
						FROM
						(
							SELECT TOP(@i)
								trans.*,
								ROW_NUMBER() OVER
								(
									PARTITION BY
										trans.session_id,
										trans.request_id
									ORDER BY
										trans.transaction_start_time DESC
								) AS r
							FROM
							(
								SELECT TOP(@i)
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id,
									COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count,
									COALESCE(SUM(s_tran.database_transaction_log_bytes_used), 0) / 1024 AS log_kb_used,
									MIN(s_tran.database_transaction_begin_time) AS transaction_start_time
								FROM
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_active_transactions
									WHERE
										transaction_begin_time <= @last_collection_start
								) AS a_tran
								INNER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_database_transactions
									WHERE
										database_id < 32767
								) AS s_tran ON
									s_tran.transaction_id = a_tran.transaction_id
								LEFT OUTER HASH JOIN
								(
									SELECT TOP(@i)
										*
									FROM sys.dm_tran_session_transactions
								) AS tst ON
									s_tran.transaction_id = tst.transaction_id
								CROSS APPLY
								(
									SELECT TOP(1)
										s3.session_id,
										s3.request_id
									FROM
									(
										SELECT TOP(1)
											s1.session_id,
											s1.request_id
										FROM #sessions AS s1
										WHERE
											s1.transaction_id = s_tran.transaction_id
											AND s1.recursion = 1
											
										UNION ALL
									
										SELECT TOP(1)
											s2.session_id,
											s2.request_id
										FROM #sessions AS s2
										WHERE
											s2.session_id = tst.session_id
											AND s2.recursion = 1
									) AS s3
									ORDER BY
										s3.request_id
								) AS session_tran_map
								GROUP BY
									session_tran_map.session_id,
									session_tran_map.request_id,
									s_tran.database_id
							) AS trans
						) AS u_trans
						FOR XML
							PATH('trans'),
							TYPE
					) AS trans_raw (trans_xml_raw)
				) AS trans_final (trans_xml)
				CROSS APPLY trans_final.trans_xml.nodes('/trans') AS trans_nodes (trans_node)
			) AS x
			INNER HASH JOIN #sessions AS s ON
				s.session_id = x.session_id
				AND s.request_id = x.request_id
			OPTION (OPTIMIZE FOR (@i = 1));
		END;

		--Variables for text and plan collection
		DECLARE	
			@session_id SMALLINT,
			@request_id INT,
			@sql_handle VARBINARY(64),
			@plan_handle VARBINARY(64),
			@statement_start_offset INT,
			@statement_end_offset INT,
			@start_time DATETIME,
			@database_name sysname;

		IF 
			@recursion = 1
			AND @output_column_list LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN;
			DECLARE sql_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					request_id,
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND sql_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@session_id,
				@request_id,
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										N'--' + NCHAR(13) + NCHAR(10) +
										CASE 
											WHEN @get_full_inner_text = 1 THEN est.text
											WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN est.text
											WHEN SUBSTRING(est.text, (@statement_start_offset/2), 2) LIKE N'[a-zA-Z0-9][a-zA-Z0-9]' THEN est.text
											ELSE
												CASE
													WHEN @statement_start_offset > 0 THEN
														SUBSTRING
														(
															est.text,
															((@statement_start_offset/2) + 1),
															(
																CASE
																	WHEN @statement_end_offset = -1 THEN 2147483647
																	ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																END
															)
														)
													ELSE RTRIM(LTRIM(est.text))
												END
										END +
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2,
										NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
										NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
										NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
									NCHAR(0),
									N''
								) AS [processing-instruction(query)]
							FOR XML
								PATH(''),
								TYPE
						),
						s.statement_start_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN 0
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN 0
								ELSE @statement_start_offset
							END,
						s.statement_end_offset = 
							CASE 
								WHEN LEN(est.text) < (@statement_end_offset / 2) + 1 THEN -1
								WHEN SUBSTRING(CONVERT(VARCHAR(MAX), est.text), (@statement_start_offset/2), 2) LIKE '[a-zA-Z0-9][a-zA-Z0-9]' THEN -1
								ELSE @statement_end_offset
							END
					FROM 
						#sessions AS s,
						(
							SELECT TOP(1)
								text
							FROM
							(
								SELECT 
									text, 
									0 AS row_num
								FROM sys.dm_exec_sql_text(@sql_handle)
								
								UNION ALL
								
								SELECT 
									NULL,
									1 AS row_num
							) AS est0
							ORDER BY
								row_num
						) AS est
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = 
							CASE ERROR_NUMBER() 
								WHEN 1222 THEN '<timeout_exceeded />'
								ELSE '<error message="' + ERROR_MESSAGE() + '" />'
							END
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@session_id,
					@request_id,
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@get_outer_command = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo NVARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id SMALLINT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results AS br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX),
									N'--' + NCHAR(13) + NCHAR(10) + br.EventInfo + NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [processing-instruction(query)]
					FROM @buffer_results AS br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								s.request_id = 0
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions AS s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@get_plans >= 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE plan_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					session_id,
					request_id,
					plan_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
					AND plan_handle IS NOT NULL
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@session_id,
				@request_id,
				@plan_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.query_plan =
						(
							SELECT
								CONVERT(xml, query_plan)
							FROM sys.dm_exec_text_query_plan
							(
								@plan_handle, 
								CASE @get_plans
									WHEN 1 THEN
										@statement_start_offset
									ELSE
										0
								END, 
								CASE @get_plans
									WHEN 1 THEN
										@statement_end_offset
									ELSE
										-1
								END
							)
						)
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.request_id = @request_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					IF ERROR_NUMBER() = 6335
					BEGIN;
						UPDATE s
						SET
							s.query_plan =
							(
								SELECT
									N'--' + NCHAR(13) + NCHAR(10) + 
									N'-- Could not render showplan due to XML data type limitations. ' + NCHAR(13) + NCHAR(10) + 
									N'-- To see the graphical plan save the XML below as a .SQLPLAN file and re-open in SSMS.' + NCHAR(13) + NCHAR(10) +
									N'--' + NCHAR(13) + NCHAR(10) +
										REPLACE(qp.query_plan, N'<RelOp', NCHAR(13)+NCHAR(10)+N'<RelOp') + 
										NCHAR(13) + NCHAR(10) + N'--' COLLATE Latin1_General_Bin2 AS [processing-instruction(query_plan)]
								FROM sys.dm_exec_text_query_plan
								(
									@plan_handle, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_start_offset
										ELSE
											0
									END, 
									CASE @get_plans
										WHEN 1 THEN
											@statement_end_offset
										ELSE
											-1
									END
								) AS qp
								FOR XML
									PATH(''),
									TYPE
							)
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
					ELSE
					BEGIN;
						UPDATE s
						SET
							s.query_plan = 
								CASE ERROR_NUMBER() 
									WHEN 1222 THEN '<timeout_exceeded />'
									ELSE '<error message="' + ERROR_MESSAGE() + '" />'
								END
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
							AND s.request_id = @request_id
							AND s.recursion = 1
						OPTION (KEEPFIXED PLAN);
					END;
				END CATCH;

				FETCH NEXT FROM plan_cursor
				INTO
					@session_id,
					@request_id,
					@plan_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@get_locks = 1 
			AND @recursion = 1
			AND @output_column_list LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					database_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions AS s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND database_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT FROM locks_cursor
			INTO 
				@database_name;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'index_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'i.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'principal_name = ' + 
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'dp.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #locks AS l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.allocation_units AS au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.indexes AS i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.database_principals AS dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.database_name = @database_name ' +
						'OPTION (KEEPFIXED PLAN); ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE 
						database_name = @database_name
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM locks_cursor
				INTO
					@database_name;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, database_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									NVARCHAR(MAX), 
									l1.database_name COLLATE Latin1_General_Bin2
								),
								NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
								NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
								NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
							NCHAR(0),
							N''
						) AS [Database/@name],
						MIN(l1.query_error) AS [Database/@query_error],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status],
								COUNT(*) AS [Lock/@request_count]
							FROM #locks AS l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.database_name = l1.database_name
								AND l2.resource_type = 'DATABASE'
							GROUP BY
								l2.request_mode,
								l2.request_status
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										l4.index_name AS [Lock/@index_name],
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END AS [Lock/@schema_name],
										l4.principal_name AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks AS l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.database_name = l4.database_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML
										PATH(''),
										TYPE
								) AS [Object/Locks]
							FROM #locks AS l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.database_name = l1.database_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.database_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML
								PATH(''),
								TYPE
						) AS [Database/Objects]
					FROM #locks AS l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = s.request_id
						AND l1.start_time IN (s.start_time, s.last_request_start_time)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.database_name
					FOR XML
						PATH(''),
						TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;

		IF 
			@find_block_leaders = 1
			AND @recursion = 1
			AND @output_column_list LIKE '%|[blocked_session_count|]%' ESCAPE '|'
		BEGIN;
			WITH
			blockers AS
			(
				SELECT
					session_id,
					session_id AS top_level_session_id,
					CONVERT(VARCHAR(8000), '.' + CONVERT(VARCHAR(8000), session_id) + '.') AS the_path
				FROM #sessions
				WHERE
					recursion = 1

				UNION ALL

				SELECT
					s.session_id,
					b.top_level_session_id,
					CONVERT(VARCHAR(8000), b.the_path + CONVERT(VARCHAR(8000), s.session_id) + '.') AS the_path
				FROM blockers AS b
				JOIN #sessions AS s ON
					s.blocking_session_id = b.session_id
					AND s.recursion = 1
					AND b.the_path NOT LIKE '%.' + CONVERT(VARCHAR(8000), s.session_id) + '.%' COLLATE Latin1_General_Bin2
			)
			UPDATE s
			SET
				s.blocked_session_count = x.blocked_session_count
			FROM #sessions AS s
			JOIN
			(
				SELECT
					b.top_level_session_id AS session_id,
					COUNT(*) - 1 AS blocked_session_count
				FROM blockers AS b
				GROUP BY
					b.top_level_session_id
			) x ON
				s.session_id = x.session_id
			WHERE
				s.recursion = 1;
		END;

		IF
			@get_task_info = 2
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			CREATE TABLE #blocked_requests
			(
				session_id SMALLINT NOT NULL,
				request_id INT NOT NULL,
				database_name sysname NOT NULL,
				object_id INT,
				hobt_id BIGINT,
				schema_id INT,
				schema_name sysname NULL,
				object_name sysname NULL,
				query_error NVARCHAR(2048),
				PRIMARY KEY (database_name, session_id, request_id)
			);

			CREATE STATISTICS s_database_name ON #blocked_requests (database_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #blocked_requests (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #blocked_requests (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_query_error ON #blocked_requests (query_error)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		
			INSERT #blocked_requests
			(
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				schema_id
			)
			SELECT
				session_id,
				request_id,
				database_name,
				object_id,
				hobt_id,
				CONVERT(INT, SUBSTRING(schema_node, CHARINDEX(' = ', schema_node) + 3, LEN(schema_node))) AS schema_id
			FROM
			(
				SELECT
					session_id,
					request_id,
					agent_nodes.agent_node.value('(database_name/text())[1]', 'sysname') AS database_name,
					agent_nodes.agent_node.value('(object_id/text())[1]', 'int') AS object_id,
					agent_nodes.agent_node.value('(hobt_id/text())[1]', 'bigint') AS hobt_id,
					agent_nodes.agent_node.value('(metadata_resource/text()[.="SCHEMA"]/../../metadata_class_id/text())[1]', 'varchar(100)') AS schema_node
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//block_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			) AS t
			WHERE
				t.database_name IS NOT NULL
				AND
				(
					t.object_id IS NOT NULL
					OR t.hobt_id IS NOT NULL
					OR t.schema_node IS NOT NULL
				);
			
			DECLARE blocks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR
				SELECT DISTINCT
					database_name
				FROM #blocked_requests;
				
			OPEN blocks_cursor;
			
			FETCH NEXT FROM blocks_cursor
			INTO 
				@database_name;
			
			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql_n = 
						CONVERT(NVARCHAR(MAX), '') +
						'UPDATE b ' +
						'SET ' +
							'b.schema_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										's.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								'), ' +
							'b.object_name = ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'o.name COLLATE Latin1_General_Bin2, ' +
										'NCHAR(31),N''?''),NCHAR(30),N''?''),NCHAR(29),N''?''),NCHAR(28),N''?''),NCHAR(27),N''?''),NCHAR(26),N''?''),NCHAR(25),N''?''),NCHAR(24),N''?''),NCHAR(23),N''?''),NCHAR(22),N''?''), ' +
										'NCHAR(21),N''?''),NCHAR(20),N''?''),NCHAR(19),N''?''),NCHAR(18),N''?''),NCHAR(17),N''?''),NCHAR(16),N''?''),NCHAR(15),N''?''),NCHAR(14),N''?''),NCHAR(12),N''?''), ' +
										'NCHAR(11),N''?''),NCHAR(8),N''?''),NCHAR(7),N''?''),NCHAR(6),N''?''),NCHAR(5),N''?''),NCHAR(4),N''?''),NCHAR(3),N''?''),NCHAR(2),N''?''),NCHAR(1),N''?''), ' +
									'NCHAR(0), ' +
									N''''' ' +
								') ' +
						'FROM #blocked_requests AS b ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.partitions AS p ON ' +
							'p.hobt_id = b.hobt_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.objects AS o ON ' +
							'o.object_id = COALESCE(p.object_id, b.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@database_name) + '.sys.schemas AS s ON ' +
							's.schema_id = COALESCE(o.schema_id, b.schema_id) ' +
						'WHERE ' +
							'b.database_name = @database_name; ';
					
					EXEC sp_executesql
						@sql_n,
						N'@database_name sysname',
						@database_name;
				END TRY
				BEGIN CATCH;
					UPDATE #blocked_requests
					SET
						query_error = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									CONVERT
									(
										NVARCHAR(MAX), 
										ERROR_MESSAGE() COLLATE Latin1_General_Bin2
									),
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N''
							)
					WHERE
						database_name = @database_name;
				END CATCH;

				FETCH NEXT FROM blocks_cursor
				INTO
					@database_name;
			END;
			
			CLOSE blocks_cursor;
			DEALLOCATE blocks_cursor;
			
			UPDATE s
			SET
				additional_info.modify
				('
					insert <schema_name>{sql:column("b.schema_name")}</schema_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.schema_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <object_name>{sql:column("b.object_name")}</object_name>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.object_name IS NOT NULL;

			UPDATE s
			SET
				additional_info.modify
				('
					insert <query_error>{sql:column("b.query_error")}</query_error>
					as last
					into (/additional_info/block_info)[1]
				')
			FROM #sessions AS s
			INNER JOIN #blocked_requests AS b ON
				b.session_id = s.session_id
				AND b.request_id = s.request_id
				AND s.recursion = 1
			WHERE
				b.query_error IS NOT NULL;
		END;

		IF
			@output_column_list LIKE '%|[program_name|]%' ESCAPE '|'
			AND @output_column_list LIKE '%|[additional_info|]%' ESCAPE '|'
			AND @recursion = 1
		BEGIN;
			DECLARE @job_id UNIQUEIDENTIFIER;
			DECLARE @step_id INT;

			DECLARE agent_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT
					s.session_id,
					agent_nodes.agent_node.value('(job_id/text())[1]', 'uniqueidentifier') AS job_id,
					agent_nodes.agent_node.value('(step_id/text())[1]', 'int') AS step_id
				FROM #sessions AS s
				CROSS APPLY s.additional_info.nodes('//agent_job_info') AS agent_nodes (agent_node)
				WHERE
					s.recursion = 1
			OPTION (KEEPFIXED PLAN);
			
			OPEN agent_cursor;

			FETCH NEXT FROM agent_cursor
			INTO 
				@session_id,
				@job_id,
				@step_id;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					DECLARE @job_name sysname;
					SET @job_name = NULL;
					DECLARE @step_name sysname;
					SET @step_name = NULL;
					
					SELECT
						@job_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									j.name,
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N'?'
							),
						@step_name = 
							REPLACE
							(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									s.step_name,
									NCHAR(31),N'?'),NCHAR(30),N'?'),NCHAR(29),N'?'),NCHAR(28),N'?'),NCHAR(27),N'?'),NCHAR(26),N'?'),NCHAR(25),N'?'),NCHAR(24),N'?'),NCHAR(23),N'?'),NCHAR(22),N'?'),
									NCHAR(21),N'?'),NCHAR(20),N'?'),NCHAR(19),N'?'),NCHAR(18),N'?'),NCHAR(17),N'?'),NCHAR(16),N'?'),NCHAR(15),N'?'),NCHAR(14),N'?'),NCHAR(12),N'?'),
									NCHAR(11),N'?'),NCHAR(8),N'?'),NCHAR(7),N'?'),NCHAR(6),N'?'),NCHAR(5),N'?'),NCHAR(4),N'?'),NCHAR(3),N'?'),NCHAR(2),N'?'),NCHAR(1),N'?'),
								NCHAR(0),
								N'?'
							)
					FROM msdb.dbo.sysjobs AS j
					INNER JOIN msdb..sysjobsteps AS s ON
						j.job_id = s.job_id
					WHERE
						j.job_id = @job_id
						AND s.step_id = @step_id;

					IF @job_name IS NOT NULL
					BEGIN;
						UPDATE s
						SET
							additional_info.modify
							('
								insert text{sql:variable("@job_name")}
								into (/additional_info/agent_job_info/job_name)[1]
							')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
						OPTION (KEEPFIXED PLAN);
						
						UPDATE s
						SET
							additional_info.modify
							('
								insert text{sql:variable("@step_name")}
								into (/additional_info/agent_job_info/step_name)[1]
							')
						FROM #sessions AS s
						WHERE 
							s.session_id = @session_id
						OPTION (KEEPFIXED PLAN);
					END;
				END TRY
				BEGIN CATCH;
					DECLARE @msdb_error_message NVARCHAR(256);
					SET @msdb_error_message = ERROR_MESSAGE();
				
					UPDATE s
					SET
						additional_info.modify
						('
							insert <msdb_query_error>{sql:variable("@msdb_error_message")}</msdb_query_error>
							as last
							into (/additional_info/agent_job_info)[1]
						')
					FROM #sessions AS s
					WHERE 
						s.session_id = @session_id
						AND s.recursion = 1
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM agent_cursor
				INTO 
					@session_id,
					@job_id,
					@step_id;
			END;

			CLOSE agent_cursor;
			DEALLOCATE agent_cursor;
		END; 
		
		IF 
			@delta_interval > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @delta_interval, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = 
		--Outer column list
		CONVERT
		(
			VARCHAR(MAX),
			CASE
				WHEN 
					@destination_table <> '' 
					AND @return_schema = 0 
						THEN 'INSERT ' + @destination_table + ' '
				ELSE ''
			END +
			'SELECT ' +
				@output_column_list + ' ' +
			CASE @return_schema
				WHEN 1 THEN 'INTO #session_schema '
				ELSE ''
			END
		--End outer column list
		) + 
		--Inner column list
		CONVERT
		(
			VARCHAR(MAX),
			'FROM ' +
			'( ' +
				'SELECT ' +
					'session_id, ' +
					--[dd hh:mm:ss.mss]
					CASE
						WHEN @format_output IN (1, 2) THEN
							'CASE ' +
								'WHEN elapsed_time < 0 THEN ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
											'9 ' +
										') + ' +
										'''.000'' ' +
								'ELSE ' +
									'RIGHT ' +
									'( ' +
										'REPLICATE(''0'', max_elapsed_length) + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
										'max_elapsed_length ' +
									') + ' +
										'RIGHT ' +
										'( ' +
											'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
											'9 ' +
										') + ' +
										'''.'' + ' + 
										'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
							'END AS [dd hh:mm:ss.mss], '
						ELSE
							''
					END +
					--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
					CASE 
						WHEN  @format_output IN (1, 2) THEN 
							'RIGHT ' +
							'( ' +
								'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
								'2 ' +
							') + ' +
								'RIGHT ' +
								'( ' +
									'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
									'9 ' +
								') + ' +
								'''.'' + ' +
								'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
						ELSE
							'avg_elapsed_time, '
					END +
					--physical_io
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io))) OVER() - LEN(CONVERT(VARCHAR, physical_io))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io), 1), 19)) AS '
						ELSE ''
					END + 'physical_io, ' +
					--reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads))) OVER() - LEN(CONVERT(VARCHAR, reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads), 1), 19)) AS '
						ELSE ''
					END + 'reads, ' +
					--physical_reads
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads))) OVER() - LEN(CONVERT(VARCHAR, physical_reads))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads), 1), 19)) AS '
						ELSE ''
					END + 'physical_reads, ' +
					--writes
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes))) OVER() - LEN(CONVERT(VARCHAR, writes))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes), 1), 19)) AS '
						ELSE ''
					END + 'writes, ' +
					--tempdb_allocations
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_allocations, ' +
					--tempdb_current
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current), 1), 19)) AS '
						ELSE ''
					END + 'tempdb_current, ' +
					--CPU
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CPU))) OVER() - LEN(CONVERT(VARCHAR, CPU))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU), 1), 19)) AS '
						ELSE ''
					END + 'CPU, ' +
					--context_switches
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches))) OVER() - LEN(CONVERT(VARCHAR, context_switches))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches), 1), 19)) AS '
						ELSE ''
					END + 'context_switches, ' +
					--used_memory
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory))) OVER() - LEN(CONVERT(VARCHAR, used_memory))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory), 1), 19)) AS '
						ELSE ''
					END + 'used_memory, ' +
					CASE
						WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
							--physical_io_delta			
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_io_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_io_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_io_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) ' 
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_io_delta), 1), 19)) '
											ELSE 'physical_io_delta '
										END +
								'ELSE NULL ' +
							'END AS physical_io_delta, ' +
							--reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, reads_delta))) OVER() - LEN(CONVERT(VARCHAR, reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, reads_delta), 1), 19)) '
											ELSE 'reads_delta '
										END +
								'ELSE NULL ' +
							'END AS reads_delta, ' +
							--physical_reads_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND physical_reads_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, physical_reads_delta))) OVER() - LEN(CONVERT(VARCHAR, physical_reads_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, physical_reads_delta), 1), 19)) '
											ELSE 'physical_reads_delta '
										END + 
								'ELSE NULL ' +
							'END AS physical_reads_delta, ' +
							--writes_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND writes_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, writes_delta))) OVER() - LEN(CONVERT(VARCHAR, writes_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, writes_delta), 1), 19)) '
											ELSE 'writes_delta '
										END + 
								'ELSE NULL ' +
							'END AS writes_delta, ' +
							--tempdb_allocations_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND tempdb_allocations_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_allocations_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_allocations_delta), 1), 19)) '
											ELSE 'tempdb_allocations_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_allocations_delta, ' +
							--tempdb_current_delta
							--this is the only one that can (legitimately) go negative 
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tempdb_current_delta))) OVER() - LEN(CONVERT(VARCHAR, tempdb_current_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tempdb_current_delta), 1), 19)) '
											ELSE 'tempdb_current_delta '
										END + 
								'ELSE NULL ' +
							'END AS tempdb_current_delta, ' +
							--CPU_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
										'THEN ' +
											'CASE ' +
												'WHEN ' +
													'thread_CPU_delta > CPU_delta ' +
													'AND thread_CPU_delta > 0 ' +
														'THEN ' +
															CASE @format_output
																WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, thread_CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, thread_CPU_delta), 1), 19)) '
																ELSE 'thread_CPU_delta '
															END + 
												'WHEN CPU_delta >= 0 THEN ' +
													CASE @format_output
														WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, thread_CPU_delta + CPU_delta))) OVER() - LEN(CONVERT(VARCHAR, CPU_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, CPU_delta), 1), 19)) '
														ELSE 'CPU_delta '
													END + 
												'ELSE NULL ' +
											'END ' +
								'ELSE ' +
									'NULL ' +
							'END AS CPU_delta, ' +
							--context_switches_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND context_switches_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, context_switches_delta))) OVER() - LEN(CONVERT(VARCHAR, context_switches_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, context_switches_delta), 1), 19)) '
											ELSE 'context_switches_delta '
										END + 
								'ELSE NULL ' +
							'END AS context_switches_delta, ' +
							--used_memory_delta
							'CASE ' +
								'WHEN ' +
									'first_request_start_time = last_request_start_time ' + 
									'AND num_events = 2 ' +
									'AND used_memory_delta >= 0 ' +
										'THEN ' +
										CASE @format_output
											WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, used_memory_delta))) OVER() - LEN(CONVERT(VARCHAR, used_memory_delta))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, used_memory_delta), 1), 19)) '
											ELSE 'used_memory_delta '
										END + 
								'ELSE NULL ' +
							'END AS used_memory_delta, '
						ELSE ''
					END +
					--tasks
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, tasks))) OVER() - LEN(CONVERT(VARCHAR, tasks))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, tasks), 1), 19)) '
						ELSE ''
					END + 'tasks, ' +
					'status, ' +
					'wait_info, ' +
					'locks, ' +
					'tran_start_time, ' +
					'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
					--open_tran_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, open_tran_count))) OVER() - LEN(CONVERT(VARCHAR, open_tran_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, open_tran_count), 1), 19)) AS '
						ELSE ''
					END + 'open_tran_count, ' +
					--sql_command
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_command, ' +
					--sql_text
					CASE @format_output 
						WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(NVARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
						ELSE ''
					END + 'sql_text, ' +
					'query_plan, ' +
					'blocking_session_id, ' +
					--blocked_session_count
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, blocked_session_count))) OVER() - LEN(CONVERT(VARCHAR, blocked_session_count))) + LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, LEFT(CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1), 19)) AS '
						ELSE ''
					END + 'blocked_session_count, ' +
					--percent_complete
					CASE @format_output
						WHEN 1 THEN 'CONVERT(VARCHAR, SPACE(MAX(LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) OVER() - LEN(CONVERT(VARCHAR, CONVERT(MONEY, percent_complete), 2))) + CONVERT(CHAR(22), CONVERT(MONEY, percent_complete), 2)) AS '
						WHEN 2 THEN 'CONVERT(VARCHAR, CONVERT(CHAR(22), CONVERT(MONEY, blocked_session_count), 1)) AS '
						ELSE ''
					END + 'percent_complete, ' +
					'host_name, ' +
					'login_name, ' +
					'database_name, ' +
					'program_name, ' +
					'additional_info, ' +
					'start_time, ' +
					'login_time, ' +
					'CASE ' +
						'WHEN status = N''sleeping'' THEN NULL ' +
						'ELSE request_id ' +
					'END AS request_id, ' +
					'GETDATE() AS collection_time '
		--End inner column list
		) +
		--Derived table and INSERT specification
		CONVERT
		(
			VARCHAR(MAX),
				'FROM ' +
				'( ' +
					'SELECT TOP(2147483647) ' +
						'*, ' +
						'CASE ' +
							'MAX ' +
							'( ' +
								'LEN ' +
								'( ' +
									'CONVERT ' +
									'( ' +
										'VARCHAR, ' +
										'CASE ' +
											'WHEN elapsed_time < 0 THEN ' +
												'(-1 * elapsed_time) / 86400 ' +
											'ELSE ' +
												'elapsed_time / 86400000 ' +
										'END ' +
									') ' +
								') ' +
							') OVER () ' +
								'WHEN 1 THEN 2 ' +
								'ELSE ' +
									'MAX ' +
									'( ' +
										'LEN ' +
										'( ' +
											'CONVERT ' +
											'( ' +
												'VARCHAR, ' +
												'CASE ' +
													'WHEN elapsed_time < 0 THEN ' +
														'(-1 * elapsed_time) / 86400 ' +
													'ELSE ' +
														'elapsed_time / 86400000 ' +
												'END ' +
											') ' +
										') ' +
									') OVER () ' +
						'END AS max_elapsed_length, ' +
						CASE
							WHEN @output_column_list LIKE '%|_delta|]%' ESCAPE '|' THEN
								'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
								'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
								'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
								'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
								'MAX(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_allocations * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_allocations_delta, ' +
								'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
								'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
								'MAX(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(thread_CPU_snapshot * recursion) OVER (PARTITION BY session_id, request_id) AS thread_CPU_delta, ' +
								'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
								'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
									'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
								'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, '
							ELSE ''
						END +
						'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
					'FROM #sessions AS s1 ' +
					CASE 
						WHEN @sort_order = '' THEN ''
						ELSE
							'ORDER BY ' +
								@sort_order
					END +
				') AS s ' +
				'WHERE ' +
					's.recursion = 1 ' +
			') x ' +
			'OPTION (KEEPFIXED PLAN); ' +
			'' +
			CASE @return_schema
				WHEN 1 THEN
					'SET @schema = ' +
						'''CREATE TABLE <table_name> ( '' + ' +
							'STUFF ' +
							'( ' +
								'( ' +
									'SELECT ' +
										''','' + ' +
										'QUOTENAME(COLUMN_NAME) + '' '' + ' +
										'DATA_TYPE + ' + 
										'CASE ' +
											'WHEN DATA_TYPE LIKE ''%char'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
											'ELSE '' '' ' +
										'END + ' +
										'CASE IS_NULLABLE ' +
											'WHEN ''NO'' THEN ''NOT '' ' +
											'ELSE '''' ' +
										'END + ''NULL'' AS [text()] ' +
									'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
									'WHERE ' +
										'TABLE_NAME = (SELECT name FROM tempdb.sys.objects WHERE object_id = OBJECT_ID(''tempdb..#session_schema'')) ' +
										'ORDER BY ' +
											'ORDINAL_POSITION ' +
									'FOR XML ' +
										'PATH('''') ' +
								'), + ' +
								'1, ' +
								'1, ' +
								''''' ' +
							') + ' +
						''')''; ' 
				ELSE ''
			END
		--End derived table and INSERT specification
		);

	SET @sql_n = CONVERT(NVARCHAR(MAX), @sql);

	EXEC sp_executesql
		@sql_n,
		N'@schema VARCHAR(MAX) OUTPUT',
		@schema OUTPUT;
END;
GO

ALTER AUTHORIZATION ON [dbo].[sp_WhoIsActive] TO  SCHEMA OWNER 
GO

ALTER AUTHORIZATION ON [dbo].[sp_WhoIsActive] TO  SCHEMA OWNER 
GO


