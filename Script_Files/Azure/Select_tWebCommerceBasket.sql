USE [prodServSuiteData];
GO
select * from [prodServSuiteData].[dbo].[tWebCommerceBasket]
GO
/*
SELECT
       i.basketid,
       w.accountid,
       i.siteid,
       p.programid,
       i.companyid, i.primarycontactid, i.basketpaymentid,
       i.basketstatus, i.processingsummary, i.utclastchanged,
       i.lastchangedby, i.languageid, i.campaignid
FROM
       [prodServSuiteData].[dbo].[tWebCommerceBasket] w
        INNER JOIN [prodServSuiteData].[dbo].[tWebCommerceBasketLineItem] i
              ON i.basketid = w.basketid
        INNER JOIN [prodServSuiteData].[dbo].[tsite] s
              ON s.siteid = i.siteid
        INNER JOIN [prodServSuiteData].[dbo].[testimate] e
              ON e.siteid = s.siteid
        INNER JOIN [prodServSuiteData].[dbo].[tprogram] p
              ON p.estimateid = e.estimateid
GO
*/