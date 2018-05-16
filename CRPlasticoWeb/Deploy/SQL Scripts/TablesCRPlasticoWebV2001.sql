USE [ValesDesarrollo]
GO

/****** Object:  Table [dbo].[BitacoraRedimeCRGcom]    Script Date: 12/03/2018 06:51:25 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.BitacoraRedimeCRGcom') IS NOT NULL
		DROP TABLE dbo.BitacoraRedimeCRGcom
	GO

CREATE TABLE [dbo].[BitacoraRedimeCRGcom](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[IdPedido] [varchar](50) NULL,
	[IdCliente] [int] NULL,
	[CodigoBarras] [varchar](50) NULL,
	[Nip] [nvarchar](10) NULL,
	[SaldoRedimir] [money] NULL,
	[IdMessage] [int] NOT NULL,
	[Message] [nvarchar](255) NOT NULL,
	[Fecha] [datetime] NOT NULL,
 CONSTRAINT [PK_BitacoraRedimeCRGcom] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[BitacoraRedimeCRGcom] ADD  CONSTRAINT [DF_BitacoraRedimeCRGcom_Fecha]  DEFAULT (getdate()) FOR [Fecha]
GO
