cls;
import-module SQLServer;

#Destination Information
$dstsrv = "RWSQLMGMTH202"

$dstdb = "DBA"

$DBlist1 = ('RWBDBAGH211', 'RWBDBAGH212\REPLICA01');

$srvList = Get-content 'C:\PowerSh\Rollins\DBA_Admin\ServerListCoreCRMSB.txt' 

$TabList = Get-Content 'C:\PowerSh\Rollins\DBA_Admin\TableListCoreCRMSB.txt'

write-host $srvList

foreach($srcsrv in $srvList )
    {if ($srcsrv -in $DBlist1)
        {
            $srcdb = 'prodServSuiteData'
        }
        else
        {
            $srcdb = 'ServSuiteData'
        }

    foreach($srctab in $TabList)
    {
        




$SQL = "USE [$srcdb];"
$SQL = $SQL +"`n DECLARE @DB nvarchar(50),
	@table nvarchar(50),
	@reads int, 
	@readsMin int, 
	@readsHr int, 
	@readsDay int, 
	@readsMnth int, 
	@readsYr int, 
	@ReadsBegin int, 
	@readsEnd int, 
	@readstotal int, 
	@delay nvarchar(10), 
	@count int, 
	@starttime datetime, 
	@serverAlias nvarchar(50);

	SET @table = '$srctab';

	SET @count = 2;

	SET @delay = '00:00:20';

	SET @DB =
	(
		SELECT CASE
			   WHEN '$srcsrv' IN ('RWBDBAGH211', 'RWBDBAGH212\REPLICA01') THEN 'prodServSuiteData'	
			   --WHEN '$srcsrv' IN ('RWBCDBAGH201', 'RWBCDBAGH202\REPLICA01','RWSBDBH201') THEN 'ServSuiteData'
               ELSE 'ServSuiteData' 
			   END
	);

	SET @ServerAlias =
	(
		SELECT CASE
			   WHEN '$srcsrv' =  'RWBDBAGH211' THEN 'RWBDBAGH211 - BOSS Live Cluster'
			   WHEN '$srcsrv' =  'RWBDBAGH212\REPLICA01' THEN 'RWBDBH212 - BOSS Replica 1 Cluster'
			   WHEN '$srcsrv' =  'RWBCDBAGH201' THEN 'RWBCDBAGH201 - CRM Live'
			   WHEN '$srcsrv' =  'RWSBDBH201' THEN 'RWSBDBH201 - SB NODE1'
               ELSE @@servername
			   END
	);
	

	SET @starttime = GETDATE();

	--Initialize Values
	SET @reads = 0;
	SET @readsEnd = 0;
	SET @ReadsBegin = 0;
	SET @ReadsTotal = 0;
	SET @readsMin = 0;
	SET @readsHr = 0;
	SET @readsDay = 0;
	SET @readsMnth = 0;
	SET @readsYr = 0;

	WHILE @count > 0
	BEGIN
		SET @reads =
		(
			SELECT CASE
				   WHEN SUM(User_Updates + User_Seeks + User_Scans + User_Lookups) = 0 THEN NULL
				   ELSE CAST(SUM(User_Seeks + User_Scans + User_Lookups) AS decimal)
				   END
			FROM sys.dm_db_Index_Usage_Stats AS UStat
				 JOIN
				 Sys.Indexes AS I
				 ON UStat.object_id = I.object_id AND 
					UStat.index_Id = I.index_Id
				 JOIN
				 sys.tables AS T
				 ON T.object_id = UStat.object_id
			WHERE t.name = @table
			GROUP BY UStat.object_id
		);

		SET @Readsbegin = IIF(@count = 2, @reads, @Readsbegin);
		SET @readsEnd = IIF(@count = 1, @reads, @Readsbegin);
		SET @readstotal = @readsEnd - @ReadsBegin;

		IF @count > 1
		BEGIN
			WAITFOR DELAY @delay;
		END;
		IF @count <= 1
		BEGIN
			SET @readsmin = @readstotal * 3;
			SET @readshr = @readsmin * 60;
			SET @readsday = @readshr * 24;
			SET @readsMnth = @readsHr * 730;
			SET @readsYr = @readsMnth * 12;

			SELECT @ServerAlias AS 'ServerID', @table AS 'Table', @readsmin AS 'Reads/Minute', @readshr AS 'Reads/Hour', @readsday AS 'Reads/Day', @readsMnth AS 'Read/Month', @readsYr AS 'Reads/Year', @starttime AS 'BeginTime', GETDATE() AS 'EndTime';

		END;
		SET @count = @count - 1;
END;"
write-host @SQL

$Results =  invoke-sqlcmd -ServerInstance $srcsrv -Database $srcdb -query $SQL -As DataTables
   

Write-SqlTableData -ServerInstance $dstsrv -DatabaseName $dstdb -SchemaName dbo -TableName ReadActivitybyServerandTable -InputData $Results;
    }
}