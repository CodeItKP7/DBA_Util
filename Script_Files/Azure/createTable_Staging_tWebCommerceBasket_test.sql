USE [DBA]
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
DROP TABLE [dbo].[Staging_tWebCommerceBasket_test];
GO
CREATE TABLE [dbo].[Staging_tWebCommerceBasket_test](
	[basketid] [int] NOT NULL,
	[accountid] [int] NULL,
	[siteid] [int] NULL,
	[programid] [int] NOT NULL,
	[lineitemid] [int] NOT NULL,
	[addressid] [int] NULL,
	[programtypeid] [int] NULL,
	[customerdisplayedinitialprice] [money] NULL,
	[customerdisplayedrecurringprice] [money] NULL,
	[utclastchanged] [datetime] NULL,
	[utcdatecreated] [datetime] NULL,
	[lastchangedby] [nvarchar](50) NOT NULL,
	[servicecenterid] [int] NOT NULL,
	[leadtypeid] [int] NOT NULL,
	[primarytargetid] [int] NOT NULL,
	[bathroomsnumber] [decimal](3, 1) NULL,
	[firstservicedate] [date] NOT NULL,
	[timeoptionid] [int] NULL,
	[customerdisplayedinitialtax] [money] NULL,
	[customerdisplayedrecurringtax] [money] NULL,
	[applyeasypay] [nvarchar](1) NOT NULL,
	[numberofmonthstoservice] [int] NULL,
	[specificmonthstoservice] [int] NULL,
	[couponcode] [nvarchar](50) NULL,
	[discountvaluetype] [nvarchar](50) NULL,
	[discountvalue] [money] NULL,
	[priceoverride] [bit] NOT NULL,
	[leadonly] [bit] NOT NULL,
	[branchnumber] [nvarchar](15) NOT NULL,
	[createdsource] [smallint] NOT NULL,
	[sourceid] [int] NOT NULL,
 CONSTRAINT [PK_Staging_tWebCommerceBasket_test] PRIMARY KEY CLUSTERED 
(
	[basketid] ASC,
	[programid] ASC,
	[lineitemid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] --TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((0)) FOR [servicecenterid]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((0)) FOR [leadtypeid]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((0)) FOR [primarytargetid]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT (getdate()) FOR [firstservicedate]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ('n') FOR [applyeasypay]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((0)) FOR [priceoverride]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((0)) FOR [leadonly]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ('0') FOR [branchnumber]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((5)) FOR [createdsource]
GO

ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((19)) FOR [sourceid]
GO

--ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  DEFAULT ((0)) FOR [languageid]
--GO

--ALTER TABLE [dbo].[Staging_tWebCommerceBasket_test] ADD  CONSTRAINT [DF_Staging_tWebCommerceBasket_campaignid_test]  DEFAULT ('') FOR [campaignid]
--GO

--select top 10 * from INFORMATION_SCHEMA.COLUMNS where table_name = 'Staging_tWebCommerceBasket_test'
--select 'i.' + column_name + ',' as ss from INFORMATION_SCHEMA.COLUMNS where table_name = 'Staging_tWebCommerceBasket_test'