USE  ServSuiteData ;

GO

GRANT CONNECT TO testservsuiteapp ;

SELECT 
programserver ,
logserver,
helpserver,
userid ,
pwd,
replicateserver,
replicateuserid ,
replicatepwd 
  FROM [ServSuiteWBUser].[dbo].[tdatabase];

  /*
  UPDATE [ServSuiteWBUser].[dbo].[tdatabase]
SET 
--programserver = '',
--logserver = '',
--helpserver = '',
--userid = '0x7a781806d281310c4b5d57c260e59ba6eb12b705910e364f',
--pwd = '',
replicateserver = '0xbebda90b55bef3f471e43b4482284933'
--,replicateuserid = '0x7a781806d281310c4b5d57c260e59ba6eb12b705910e364f'
--,
--replicatepwd = ''
GO

*/