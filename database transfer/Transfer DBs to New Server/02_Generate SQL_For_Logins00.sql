USE MASTER
GO
EXEC sp_help_revlogin --Copy results on Messages tab
GO
DECLARE @command varchar(1000) 
SELECT @command = 'USE ?  
SELECT CASE WHEN DP2.name NOT LIKE ''ROLLINS%'' THEN
''USE [''+ db_name() +'']
GO
EXEC sp_change_users_login ''''Report''''
GO
ALTER ROLE [''+DP1.name+''] ADD MEMBER ''+DP2.name+''''+
 ''
EXEC sp_change_users_login ''''Auto_Fix'''',''''''+DP2.name+''''''
GO'' 
ELSE ''USE [''+ db_name() +'']
GO
ALTER ROLE [db_owner] ADD MEMBER ''+
CASE WHEN DP2.name LIKE''ROLLINS%''
THEN ''[''+DP2.name+'']'' 
ELSE DP2.name END+''
GO''
END
 --  isnull (DP2.name, ''No members'') AS DatabaseUserName   
 FROM sys.database_role_members AS DRM  
 RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = ''R''
AND DP1.name  =''db_owner''
AND ISNULL (DP2.name, ''No members'') <>''dbo''
AND DP2.name IS NOT NULL
ORDER BY DP2.name,DP1.name;' 
--PRINT  @command 
EXEC sp_MSforeachdb @command -- Append output of Results tab to on Messages tab
