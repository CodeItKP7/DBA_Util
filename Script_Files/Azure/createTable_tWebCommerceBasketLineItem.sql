SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[tWebCommerceBasketLineItem](
	[basketid] [int] NOT NULL,
	[lineitemid] [int] NOT NULL,
	[addressid] [int] NULL,
	[siteid] [int] NULL,
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
 CONSTRAINT [PK_tWebCommerceBasketLineItem] PRIMARY KEY CLUSTERED 
(
	[basketid] ASC,
	[lineitemid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((0)) FOR [servicecenterid]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((0)) FOR [leadtypeid]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((0)) FOR [primarytargetid]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT (getdate()) FOR [firstservicedate]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ('n') FOR [applyeasypay]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((0)) FOR [priceoverride]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((0)) FOR [leadonly]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ('0') FOR [branchnumber]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((5)) FOR [createdsource]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] ADD  DEFAULT ((19)) FOR [sourceid]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_taddress] FOREIGN KEY([addressid])
REFERENCES [dbo].[taddress] ([addressid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_taddress]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH NOCHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_tbranch] FOREIGN KEY([servicecenterid])
REFERENCES [dbo].[tbranch] ([branchid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] NOCHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_tbranch]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_testimatesetup] FOREIGN KEY([leadtypeid])
REFERENCES [dbo].[testimatesetup] ([estimatetypeid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_testimatesetup]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_tprogramsetup] FOREIGN KEY([programtypeid])
REFERENCES [dbo].[tprogramsetup] ([programtypeid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_tprogramsetup]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_tsite] FOREIGN KEY([siteid])
REFERENCES [dbo].[tsite] ([siteid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_tsite]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_ttargetsetup] FOREIGN KEY([primarytargetid])
REFERENCES [dbo].[ttargetsetup] ([targettypeid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_ttargetsetup]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_ttimeoptionsetup] FOREIGN KEY([timeoptionid])
REFERENCES [dbo].[ttimeoptionsetup] ([timeoptionid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_ttimeoptionsetup]
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem]  WITH CHECK ADD  CONSTRAINT [FK_tWebCommerceBasketLineItem_tWebCommerceBasket] FOREIGN KEY([basketid])
REFERENCES [dbo].[tWebCommerceBasket] ([basketid])
GO

ALTER TABLE [dbo].[tWebCommerceBasketLineItem] CHECK CONSTRAINT [FK_tWebCommerceBasketLineItem_tWebCommerceBasket]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingAddress' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_taddress'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsAddressInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_taddress'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingBranch' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tbranch'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsBranchInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tbranch'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingEstimateSetup' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_testimatesetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsEstimateSetupInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_testimatesetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingProgramType' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tprogramsetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsProgramTypeInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tprogramsetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingSite' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tsite'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsSiteInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tsite'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingTargetSetup' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_ttargetsetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsTargetInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_ttargetsetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsTargetingTimeOptionSetup' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_ttimeoptionsetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'IsTimeOptionSetupInWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_ttimeoptionsetup'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'IsLineItemForWebBasket' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tWebCommerceBasket'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DescriptionTo', @value=N'HasLineItems' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'tWebCommerceBasketLineItem', @level2type=N'CONSTRAINT',@level2name=N'FK_tWebCommerceBasketLineItem_tWebCommerceBasket'
GO


