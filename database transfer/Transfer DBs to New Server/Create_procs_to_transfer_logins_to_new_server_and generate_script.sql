USE [master]
  GO
  IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
  GO
  CREATE PROCEDURE [dbo].[sp_hexadecimal]
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
  go
  IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
  GO
  CREATE PROCEDURE [dbo].[sp_help_revlogin]   
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
GO
