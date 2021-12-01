BEGIN
	SET NOCOUNT ON;

	DECLARE
		@max INT,
		@min INT,
		@sql NVARCHAR(4000),
		@svr_name VARCHAR(256),
		@database_name  VARCHAR(256)
	;
 
	SELECT @svr_name = @@SERVERNAME;

	IF (SELECT OBJECT_ID('tempdb..#results')) IS NOT NULL
	BEGIN
		DROP TABLE #results;
	END
 
	CREATE TABLE #results
	(
		[database_id] [int] NULL,
		[file_id] [int] NULL,
		[type_desc] [varchar](120) NULL,
		[logical_name] [varchar](256) NULL,
		[physical_name] [varchar](520) NULL,
		[state_desc] [varchar](120) NULL,
		[size] [int] NULL,
		[max_size] [int] NULL,
		[growth] [int] NULL,
		[is_read_only] [bit] NULL,
		[is_percent_growth] [bit] NULL,
		[svr_name] [varchar](256),
		[database_name] [varchar](256) NULL
	);

	SELECT @sql = 'select database_id, file_id, type_desc, name as logical_name, physical_name, state_desc, size, max_size, growth, is_read_only, is_percent_growth, ''' + @svr_name + ''' as svr_name, db_name(database_id) as database_name from sys.master_files order by database_id, file_id asc';
	INSERT #results([database_id] , [file_id], [type_desc], [logical_name], [physical_name], [state_desc], [size], [max_size], [growth], [is_read_only], [is_percent_growth], [svr_name], [database_name])
	EXEC (@sql);

	--UPDATE  #results
	--   SET 	[svr_name] = @svr_name, [database_name] = @database_name;
 
	SELECT * FROM #results
 
	DROP TABLE #results
END
