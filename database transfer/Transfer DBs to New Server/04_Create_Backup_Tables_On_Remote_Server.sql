------------------------------------------------------------------------------------------------------------------------------------------------
--	This script creates the backup tables targeted in the script to preserve DEV logins and other data
--	Do a global FIND and REPLACE of the string OWSSDDBO247 with the desired lsitener name
--  Connect to server OWSSCDDBO201 and execute
------------------------------------------------------------------------------------------------------------------------------------------------
USE [LoginRoleRestoreTest]
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteDatathocreports]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteDatathocreports]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports](
	[reportid] [int] NOT NULL,
	[reportname] [nvarchar](max) NOT NULL,
	[reportitempath] [nvarchar](max) NOT NULL,
	[subscriptionid] [uniqueidentifier] NULL,
	[daytorunafterhoc] [int] NOT NULL,
	[renderformat] [nvarchar](100) NULL,
	[commandtext] [nvarchar](max) NULL,
	[matchdata] [nvarchar](max) NULL,
	[parameters] [nvarchar](max) NULL,
	[fieldlist] [nvarchar](max) NULL,
	[utclastchanged] [datetime] NOT NULL,
	[lastchangedby] [nvarchar](250) NULL,
	[scheduledtime] [time](7) NOT NULL,
	[nextrun] [datetime] NULL,
	[timeout] [int] NULL,
	[istimeoutinitialized] [bit] NOT NULL,
	[isfilenamechanged] [bit] NOT NULL,
	[emailreport] [bit] NOT NULL,
 CONSTRAINT [PK_OWSSDDBO247ServSuiteDatathocreports             thocreports] PRIMARY KEY CLUSTERED 
(
	[reportid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteDatathocreports] TO  SCHEMA OWNER 
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteDatatlogincompany]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteDatatlogincompany]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteDatatlogincompany](
	[loginid] [int] NOT NULL,
	[companyid] [int] NOT NULL,
	[utctimestamp] [datetime] NOT NULL,
	[utclastchanged] [datetime] NULL,
	[lastchangedby] [nvarchar](50) NOT NULL,
	[createdby] [nvarchar](50) NOT NULL
) ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteDatatlogincompany] TO  SCHEMA OWNER 
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteDatatlogincompanybranch]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteDatatlogincompanybranch]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteDatatlogincompanybranch](
	[loginbranchid] [int] NOT NULL,
	[companyid] [int] NOT NULL,
	[branchid] [int] NOT NULL,
	[loginid] [int] NOT NULL,
	[utctimestamp] [datetime] NOT NULL,
	[utclastchanged] [datetime] NULL,
	[lastchangedby] [nvarchar](50) NOT NULL
) ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteDatatlogincompanybranch] TO  SCHEMA OWNER 
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteDatatlogincurrentcompany]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteDatatlogincurrentcompany]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteDatatlogincurrentcompany](
	[loginid] [int] NOT NULL,
	[companyid] [int] NOT NULL,
	[utctimestamp] [datetime] NOT NULL,
	[utclastchanged] [datetime] NULL,
	[lastchangedby] [nvarchar](50) NOT NULL
) ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteDatatlogincurrentcompany] TO  SCHEMA OWNER 
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteDatatloginrole]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteDatatloginrole]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteDatatloginrole](
	[loginid] [int] NOT NULL,
	[roleid] [int] NOT NULL,
	[utctimestamp] [datetime] NOT NULL,
	[createdby] [nvarchar](50) NOT NULL,
	[utclastchanged] [datetime] NOT NULL,
	[lastchangedby] [nvarchar](50) NOT NULL,
	[loginstart] [nvarchar](20) NOT NULL,
	[loginend] [nvarchar](20) NOT NULL,
	[loginsun] [bit] NOT NULL,
	[loginmon] [bit] NOT NULL,
	[logintue] [bit] NOT NULL,
	[loginwed] [bit] NOT NULL,
	[loginthu] [bit] NOT NULL,
	[loginfri] [bit] NOT NULL,
	[loginsat] [bit] NOT NULL,
	[loginmobile] [bit] NOT NULL,
	[issupportuser] [bit] NOT NULL,
	[canlogout] [bit] NOT NULL,
	[isservsaleuser] [bit] NOT NULL,
	[servsaleroleid] [int] NOT NULL,
	[companyid] [int] NOT NULL,
	[ismobileuser] [bit] NOT NULL,
	[mobileroleid] [int] NOT NULL
) ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteDatatloginrole] TO  SCHEMA OWNER 
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteWBUsertdatabase]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteWBUsertdatabase]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteWBUsertdatabase](
	[databaseid] [int] NOT NULL,
	[dbtype] [tinyint] NOT NULL,
	[programserver] [nvarchar](250) NOT NULL,
	[programserverssl] [bit] NOT NULL,
	[programdb] [nvarchar](250) NOT NULL,
	[dataserver] [nvarchar](250) NOT NULL,
	[dataserverssl] [bit] NOT NULL,
	[datadb] [nvarchar](250) NOT NULL,
	[logserver] [nvarchar](250) NOT NULL,
	[logserverssl] [bit] NOT NULL,
	[logserverinternal] [nvarchar](250) NOT NULL,
	[logserverinternalssl] [bit] NOT NULL,
	[logdb] [nvarchar](250) NOT NULL,
	[helpserver] [nvarchar](250) NOT NULL,
	[helpserverssl] [bit] NOT NULL,
	[helpdb] [nvarchar](250) NOT NULL,
	[userid] [nvarchar](150) NOT NULL,
	[pwd] [nvarchar](150) NOT NULL,
	[available] [bit] NOT NULL,
	[netlib] [smallint] NOT NULL,
	[prgpwd] [nvarchar](250) NOT NULL,
	[prguid] [nvarchar](250) NOT NULL,
	[useaddressval] [smallint] NOT NULL,
	[addressvalloc] [nvarchar](250) NOT NULL,
	[allowcwp] [bit] NOT NULL,
	[allownextel] [bit] NOT NULL,
	[allowsqllog] [bit] NOT NULL,
	[dbversion] [nvarchar](20) NOT NULL,
	[checkload] [bit] NOT NULL,
	[singlefilelimit] [int] NOT NULL,
	[totalfilelimit] [int] NOT NULL,
	[sentriconversion] [nvarchar](10) NULL,
	[backupdataserver] [nvarchar](250) NOT NULL,
	[backuplogserver] [nvarchar](250) NOT NULL,
	[backupuserid] [nvarchar](150) NOT NULL,
	[backuppwd] [nvarchar](150) NOT NULL,
	[redirect] [nvarchar](50) NOT NULL,
	[registeredusers] [bigint] NOT NULL,
	[masteracctsvcexternal] [bit] NOT NULL,
	[masteracctsvcaddress] [nvarchar](250) NOT NULL,
	[apiurl] [nvarchar](50) NOT NULL,
	[replicateserver] [nvarchar](250) NOT NULL,
	[replicatedata] [nvarchar](250) NOT NULL,
	[replicateuserid] [nvarchar](150) NOT NULL,
	[replicatepwd] [nvarchar](150) NOT NULL
) ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteWBUsertdatabase] TO  SCHEMA OWNER 
GO

/****** Object:  Table [dbo].[OWSSDDBO247ServSuiteWBUsertlogin]    Script Date: 9/29/2021 8:56:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[OWSSDDBO247ServSuiteWBUsertlogin]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[OWSSDDBO247ServSuiteWBUsertlogin](
	[orgid] [int] NOT NULL,
	[loginid] [int] NOT NULL,
	[logindescription] [nvarchar](50) NOT NULL,
	[isactive] [bit] NOT NULL,
	[loginuid] [nvarchar](50) NOT NULL,
	[loginpwd] [varbinary](50) NOT NULL,
	[databaseid] [int] NOT NULL,
	[lcid] [int] NOT NULL,
	[languageid] [int] NOT NULL,
	[role] [int] NOT NULL,
	[accountid] [int] NOT NULL,
	[utcoffset] [int] NOT NULL,
	[utctimestamp] [datetime] NOT NULL,
	[utclastchanged] [datetime] NULL,
	[lastchangedby] [nvarchar](50) NOT NULL,
	[loginpwdexpires] [datetime] NULL,
	[usedst] [bit] NOT NULL,
	[useralias] [nvarchar](50) NOT NULL,
	[usertype] [tinyint] NOT NULL,
	[adusername] [nvarchar](128) NOT NULL,
	[syncrouteid] [int] NOT NULL,
	[syncemployeeid] [int] NOT NULL,
	[ismobileuser] [bit] NOT NULL,
	[mobileroleid] [int] NOT NULL,
	[isservsaleuser] [bit] NOT NULL,
	[servsaleroleid] [int] NOT NULL,
	[glympseagentid] [int] NOT NULL
) ON [PRIMARY]
END
GO

ALTER AUTHORIZATION ON [dbo].[OWSSDDBO247ServSuiteWBUsertlogin] TO  SCHEMA OWNER 
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__repor__7897ECEC]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [reportname]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__repor__798C1125]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [reportitempath]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__rende__7A80355E]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [renderformat]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__comma__7B745997]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [commandtext]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__match__7C687DD0]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [matchdata]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__param__7D5CA209]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [parameters]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__field__7E50C642]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [fieldlist]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__lastc__7F44EA7B]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('') FOR [lastchangedby]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__sched__00390EB4]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ('00:00:00') FOR [scheduledtime]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__istim__012D32ED]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ((0)) FOR [istimeoutinitialized]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__isfil__02215726]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ((0)) FOR [isfilenamechanged]
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__OWSSDVDBA__email__03157B5F]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[OWSSDDBO247ServSuiteDatathocreports] ADD  DEFAULT ((0)) FOR [emailreport]
END
GO


