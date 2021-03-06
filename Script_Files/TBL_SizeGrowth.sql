BEGIN
	SET NOCOUNT ON

	DECLARE
		@max INT,
		@min INT,
		@table_name NVARCHAR(256),
		@table_schema NVARCHAR(256),
		@sql NVARCHAR(4000),
		@svr_name NVARCHAR(256),
		@database_name  NVARCHAR(256)
 
	DECLARE @table TABLE(
		id INT IDENTITY(1,1) PRIMARY KEY,
		table_schema NVARCHAR(256),
		table_name NVARCHAR(256)
		)

	SELECT @svr_name = @@SERVERNAME, @database_name = db_name();

	IF (SELECT OBJECT_ID('tempdb..#results')) IS NOT NULL
	BEGIN
		DROP TABLE #results
	END
 
	CREATE TABLE #results
	(
	[table_name] [nvarchar](256) NULL,
	[table_rows] [int] NULL,
	[reserved_space] [nvarchar](55) NULL,
	[data_space] [nvarchar](55) NULL,
	[index_space] [nvarchar](55) NULL,
	[unused_space] [nvarchar](55) NULL,
	[table_schema] [nvarchar](256) NULL,
	[svr_name] [nvarchar](256) NULL,
	[database_name] [nvarchar](256) NULL
	)

	INSERT @table (table_schema, table_name)
	SELECT schema_name(schema_id), name from sys.objects where type = 'U' order by name asc

	SELECT @min = 1, @max = (SELECT MAX(id) FROM @table)
 
 	WHILE @min < @max + 1
	BEGIN
		SELECT @table_schema = table_schema, @table_name = table_name FROM @table WHERE id = @min
   
		SELECT @sql = 'EXEC sp_spaceused ''[' + @table_schema + '].[' + @table_name + ']'''
  
  		--INSERT RESULTS FROM SP_SPACEUSED
		INSERT #results(table_name, table_rows, reserved_space, data_space, index_space, unused_space)
		EXEC (@sql)
  
  		--UPDATE SCHEMA NAME
		UPDATE  #results
		   SET 	[table_schema] = @table_schema, [svr_name] = @svr_name, [database_name] = @database_name
	         WHERE  [table_name] = @table_name

		SELECT @min = @min + 1
	 END
 
 	--REMOVE "KB" FROM RESULTS
	UPDATE #results SET data_space = SUBSTRING(data_space, 1, (LEN(data_space)-3))
	UPDATE #results SET reserved_space = SUBSTRING(reserved_space, 1, (LEN(reserved_space)-3))
	UPDATE #results SET index_space = SUBSTRING(index_space, 1, (LEN(index_space)-3))
	UPDATE #results SET unused_space = SUBSTRING(unused_space, 1, (LEN(unused_space)-3))

	SELECT * FROM #results
 
	DROP TABLE #results
END
