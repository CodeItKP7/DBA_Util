
--CREATE PROCEDURE dbo.spGetReadStats 
--				 @Server nvarchar(50), 
--				 @table nvarchar(50)
--AS
--BEGIN

	DECLARE @DB nvarchar(50),
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

	SET @table = 'tdocumentdata';

	SET @count = 2;

	SET @delay = '00:01:00';

	SET @DB =
	(
		SELECT CASE
			   WHEN @@servername IN ('RWBDBAGH211', 'RWBDBDAGH212\REPLICA01', 'RWBDBAGH213\MOBILE01') THEN 'prodServSuiteData'	
			   WHEN @@servername in ('RWBCDBAGH201', 'RWBCDBAGH202', 'RWSBDBH201', 'RWSBDBH202') THEN 'ServSuiteData'
			   END
	);

	SET @ServerAlias =
	(
		SELECT CASE
			   WHEN @@servername = 'RWBDBAGH211' THEN 'RWBDBAGH211 - BOSS Live Cluster'
			   WHEN @@servername = 'RWBDBDAGH212\REPLICA01' THEN 'RWBDBH212 - BOSS Replica1 Cluster'
			   WHEN @@servername = 'RWBDBAGH213\MOBILE01' THEN 'RWBDBH213 - BOSS Replica2 Mobile'
			   WHEN @@servername = 'RWBCDBAGH201' THEN 'RWBDBAGH201 - CRM Live'
			   WHEN @@servername = 'RWBCDBAGH202' THEN 'RWBDBAGH202 - CRM REPLICA'
			   WHEN @@servername = 'RWSBDBH201' THEN 'RWBDBAGH201 - SB NODE1'
			   WHEN @@servername = 'RWSBDBH202' THEN 'RWBDBAGH202 - SB NODE2'
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
		PRINT 'Counter is now ' + CONVERT(varchar(20), @count);
		PRINT 'Reads = ' + CONVERT(varchar(20), @reads);
		SET @readstotal = @readsEnd - @ReadsBegin;

		IF @count > 1
		BEGIN
			WAITFOR DELAY @delay;
		END;
		IF @count <= 1
		BEGIN
			SET @readsmin = @readstotal;
			SET @readshr = @readsmin * 60;
			SET @readsday = @readshr * 24;
			SET @readsMnth = @readsHr * 730;
			SET @readsYr = @readsMnth * 12;

			SELECT @ServerAlias AS 'ServerID', @table AS 'Table', @readsmin AS 'Reads/Minute', @readshr AS 'Reads/Hour', @readsday AS 'Reads/Day', @readsMnth AS 'Read/Month', @readsYr AS 'Reads/Year', @starttime AS 'BeginTime', GETDATE() AS 'EndTime';

		END;
		SET @count = @count - 1;
--	END;
END;