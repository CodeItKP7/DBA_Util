----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
--	Need to separate Index space usage
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID (N'tempdb..#tabletemp', 'U') IS NOT NULL
DROP TABLE #tabletemp;

SELECT 
--@@SERVERNAME servername,
FORMAT (getdate(), 'MMM dd yyyy') as date,
db_name() db_name,
   s.Name +'.'+ t.NAME AS TableName,
    p.rows ,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
INTO #tabletemp
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    1=2
GROUP BY 
 t.Name, s.Name, p.Rows;
EXEC sp_MSforeachdb N'
IF N''?'' NOT IN(N''master'',N''model'',N''tempdb'',N''msdb'',N''SSISDB'')
BEGIN
USE [?];
INSERT INTO #tabletemp
	SELECT 
--@@SERVERNAME,
FORMAT (getdate(), ''MMM dd yyyy'') as date,
db_name() db_name,
   s.Name +''.''+ t.NAME AS TableName,
    p.rows ,
    SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
FROM 
    sys.tables t
INNER JOIN      
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN 
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN 
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN 
    sys.schemas s ON t.schema_id = s.schema_id
WHERE 
    t.NAME NOT LIKE ''dt%'' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
GROUP BY 
 t.Name, s.Name, p.Rows;
 END;';

 SELECT * FROM #tabletemp
 ORDER BY 6 desc;

IF OBJECT_ID (N'tempdb..#tabletemp', 'U') IS NOT NULL
DROP TABLE #tabletemp;