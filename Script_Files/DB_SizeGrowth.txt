BEGIN
	SET NOCOUNT ON

	DECLARE
		@max INT,
		@min INT,
		@sql NVARCHAR(4000),
		@svr_name VARCHAR(256),
		@database_name  VARCHAR(256)
 
	DECLARE @table TABLE(
		id INT IDENTITY(1,1) PRIMARY KEY,
		table_schema NVARCHAR(256),
		table_name NVARCHAR(256)
		)

	SELECT @svr_name = @@SERVERNAME;

	IF (SELECT OBJECT_ID('tempdb..#results')) IS NOT NULL
	BEGIN
		DROP TABLE #results;
	END
 
	CREATE TABLE #results
	(
	[database_name] [varchar](256) NULL,
	[db_size] [varchar] (30) NULL,
	[owner] [varchar](256) NULL,
	[dbid] [int] NULL,
	[db_created] [datetime] NULL,
	[status] [varchar](600) NULL,
	[compatibility_level] [varchar] (30) NULL,
	[svr_name] [varchar](256) NULL
	);

	SELECT @sql = 'EXEC sp_helpdb ';
	INSERT #results([database_name], [db_size], [owner], [dbid], [db_created], [status], [compatibility_level])
	EXEC (@sql)

	UPDATE  #results
	   SET 	[svr_name] = @svr_name
 
 	--REMOVE "MB" FROM RESULTS
	UPDATE #results SET [db_size] = SUBSTRING(db_size, 1, (LEN(db_size)-3));

	SELECT * FROM #results
 
	DROP TABLE #results
END
