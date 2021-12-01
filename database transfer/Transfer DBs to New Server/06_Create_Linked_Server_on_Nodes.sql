:connect <__Listener Name__>

IF NOT EXISTS (SELECT * FROM sys.servers where name = N'<__Listener Name__>')
BEGIN
    EXEC master.dbo.sp_addlinkedserver @server = N'<__Listener Name__>';  
END

ALTER AVAILABILITY GROUP BOSS_AG1

   SET (

      DTC_SUPPORT = PER_DB 

      );