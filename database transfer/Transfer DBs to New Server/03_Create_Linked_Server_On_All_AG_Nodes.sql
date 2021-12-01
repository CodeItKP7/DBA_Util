USE [master]
GO

/****** Object:  LinkedServer [OWSSCDDBO201]    Script Date: 11/4/2021 4:16:56 PM ******/
IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = N'OWSSCDDBO201')EXEC master.dbo.sp_dropserver @server=N'OWSSCDDBO201', @droplogins='droplogins'
GO

/****** Object:  LinkedServer [OWSSCDDBO201]    Script Date: 11/4/2021 4:16:56 PM ******/
EXEC master.dbo.sp_addlinkedserver @server = N'OWSSCDDBO201', @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'OWSSCDDBO201',@useself=N'False',@locallogin=NULL,@rmtuser=N'LinkedServer',@rmtpassword='LinkedServer'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'rpc', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'rpc out', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'collation name', @optvalue=null
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'OWSSCDDBO201', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO


