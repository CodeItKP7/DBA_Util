USE [prodServSuiteData];
GO
--select * from [prodServSuiteData].[dbo].[tWebCommerceBasket]
--GO

SELECT
       	i.basketid,
       	w.accountid,
       	i.siteid,
       	p.programid,
	i.lineitemid,
	i.addressid,
	i.programtypeid,
	i.customerdisplayedinitialprice,
	i.customerdisplayedrecurringprice,
	i.utclastchanged,
	i.utcdatecreated,
	i.lastchangedby,
	i.servicecenterid,
	i.leadtypeid,
	i.primarytargetid,
	i.bathroomsnumber,
	i.firstservicedate,
	i.timeoptionid,
	i.customerdisplayedinitialtax,
	i.customerdisplayedrecurringtax,
	i.applyeasypay,
	i.numberofmonthstoservice,
	i.specificmonthstoservice,
	i.couponcode,
	i.discountvaluetype,
	i.discountvalue,
	i.priceoverride,
	i.leadonly,
	i.branchnumber,
	i.createdsource,
	i.sourceid
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
