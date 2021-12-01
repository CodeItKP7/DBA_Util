USE [DBA]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TableSizeGrowth_new](
	[table_name] [nvarchar](256) NULL,
	[table_rows] [bigint] NULL,
	[reserved_space] [bigint] NULL,
	[data_space] [bigint] NULL,
	[index_space] [bigint] NULL,
	[unused_space] [bigint] NULL,
	[table_schema] [nvarchar](256) NULL,
	[svr_name] [nvarchar](256) NULL,
	[database_name] [nvarchar](256) NULL,
	[createdate] [datetime] NULL,
	[id] [bigint] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_TableSizeGrowth_new] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[TableSizeGrowth_new] ADD  CONSTRAINT [DF_TableSizeGrowth_date1]  DEFAULT (dateadd(day,(0),datediff(day,(0),getdate()))) FOR [createdate]
GO


