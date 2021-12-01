USE [prodServSuiteData];
GO
SELECT	Utctimestamp, Utcprocessed, processed AS [SentToMarketo], CompanyId, recId AS [MarketoPersonId], msg AS [RemediationReason]
FROM	dbo.tssmarketingprocessqueue mpq 
WHERE	jobtype = 3
ORDER BY mpq.utctimestamp ASC;
GO

/*
USE [prodServSuiteData];
GO
SELECT	Utctimestamp, Utcprocessed, processed AS [SentToMarketo], CompanyId, recId AS [MarketoPersonId], msg AS [RemediationReason]
FROM	dbo.tssmarketingprocessqueue  
WHERE	jobtype = 3

UNION ALL

SELECT	getdate() as Utctimestamp, 1 as Utcprocessed, 123 AS [SentToMarketo], 1 as CompanyId, 12345 AS [MarketoPersonId], 'Test Message' AS [RemediationReason]
ORDER BY utctimestamp ASC;
GO
*/