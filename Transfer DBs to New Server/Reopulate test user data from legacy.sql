
USE ServSuiteData;
--PRINT(N'DELETE FROM ' +@logincompanyTable);
INSERT INTO  logincompany([loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby],[createdby])
	SELECT [loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby],[createdby]
	FROM OWSSTSTDBAGO05.ServSuiteData.dbo.tlogincompany;


USE ServSuiteData;
INSERT INTO  logincompanybranch([loginbranchid],[companyid],[branchid],[loginid],[utctimestamp],[utclastchanged],[lastchangedby])
	SELECT [loginbranchid],[companyid],[branchid],[loginid],[utctimestamp],[utclastchanged],[lastchangedby]
	FROM OWSSTSTDBAGO05.ServSuiteData.dbo.tlogincompanybranch;


USE ServSuiteData;
--PRINT(N'DELETE FROM ' logincurrentcompanyTable);
INSERT INTO  logincurrentcompany([loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby])
	SELECT [loginid],[companyid],[utctimestamp],[utclastchanged],[lastchangedby]
	FROM OWSSTSTDBAGO05.ServSuiteData.dbo.tlogincurrentcompany;

USE ServSuiteData;
--PRINT(N'DELETE FROM ' loginroletable); 
INSERT INTO  loginrole([loginid],[roleid],[utctimestamp],[createdby],[utclastchanged],[lastchangedby],[loginstart],
											[loginend],[loginsun],[loginmon],[logintue],[loginwed],[loginthu],[loginfri],[loginsat],[loginmobile],
											[issupportuser],[canlogout],[isservsaleuser],[servsaleroleid],[companyid],[ismobileuser],[mobileroleid])
	SELECT [loginid],[roleid],[utctimestamp],[createdby],[utclastchanged],[lastchangedby],[loginstart],
		   [loginend],[loginsun],[loginmon],[logintue],[loginwed],[loginthu],[loginfri],[loginsat],[loginmobile],
		   [issupportuser],[canlogout],[isservsaleuser],[servsaleroleid],[companyid],[ismobileuser],[mobileroleid]
	FROM OWSSTSTDBAGO05.ServSuiteData.dbo.tloginrole;

INSERT INTO  thocreports([reportid],[reportname],[reportitempath],[subscriptionid],[daytorunafterhoc],[renderformat],[commandtext],[matchdata],[parameters],[fieldlist]
           ,[utclastchanged],[lastchangedby],[scheduledtime],[nextrun],[timeout],[istimeoutinitialized],[isfilenamechanged],[emailreport])
	SELECT [reportid],[reportname],[reportitempath],[subscriptionid],[daytorunafterhoc],[renderformat],[commandtext],[matchdata],[parameters],[fieldlist]
           ,[utclastchanged],[lastchangedby],[scheduledtime],[nextrun],[timeout],[istimeoutinitialized],[isfilenamechanged],[emailreport]
	FROM OWSSTSTDBAGO05.ServSuiteData.dbo.thocreports;


USE ServSuiteWBUser;
--PRINT(N'DELETE FROM ' tlogintable);
INSERT INTO  tlogin([orgid],[loginid],[logindescription],[isactive],[loginuid],[loginpwd],[databaseid],[lcid],[languageid],
										 [role],[accountid],[utcoffset],[utctimestamp],[utclastchanged],[lastchangedby],[loginpwdexpires],[usedst],
										 [useralias],[usertype],[adusername],[syncrouteid],[syncemployeeid],[ismobileuser],[mobileroleid],[isservsaleuser],
										 [servsaleroleid],[glympseagentid])
	SELECT [orgid],[loginid],[logindescription],[isactive],[loginuid],[loginpwd],[databaseid],[lcid],[languageid],
		   [role],[accountid],[utcoffset],[utctimestamp],[utclastchanged],[lastchangedby],[loginpwdexpires],[usedst],
		   [useralias],[usertype],[adusername],[syncrouteid],[syncemployeeid],[ismobileuser],[mobileroleid],[isservsaleuser],
		   [servsaleroleid],[glympseagentid]
	FROM OWSSTSTDBAGO05.ServSuiteWBUser.dbo.[tlogin]


--INSERT INTO  tdatabase([databaseid],[dbtype],[programserver],[programserverssl],[programdb],[dataserver],[dataserverssl],[datadb],
--											[logserver],[logserverssl],[logserverinternal],[logserverinternalssl],[logdb],[helpserver],[helpserverssl],
--											[helpdb],[userid],[pwd],[available],[netlib],[prgpwd],[prguid],[useaddressval],[addressvalloc],[allowcwp],
--											[allownextel],[allowsqllog],[dbversion],[checkload],[singlefilelimit],[totalfilelimit],[sentriconversion],
--											[backupdataserver],[backuplogserver],[backupuserid],[backuppwd],[redirect],[registeredusers],[masteracctsvcexternal],
--											[masteracctsvcaddress],[apiurl],[replicateserver],[replicatedata],[replicateuserid],[replicatepwd])
--	SELECT [databaseid],[dbtype],[programserver],[programserverssl],[programdb],[dataserver],[dataserverssl],[datadb],
--		   [logserver],[logserverssl],[logserverinternal],[logserverinternalssl],[logdb],[helpserver],[helpserverssl],
--		   [helpdb],[userid],[pwd],[available],[netlib],[prgpwd],[prguid],[useaddressval],[addressvalloc],[allowcwp],
--		   [allownextel],[allowsqllog],[dbversion],[checkload],[singlefilelimit],[totalfilelimit],[sentriconversion],
--		   [backupdataserver],[backuplogserver],[backupuserid],[backuppwd],[redirect],[registeredusers],[masteracctsvcexternal],
--		   [masteracctsvcaddress],[apiurl],[replicateserver],[replicatedata],[replicateuserid],[replicatepwd]
--	FROM OWSSTSTDBAGO05.ServSuiteWBUser.dbo.tdatabase;