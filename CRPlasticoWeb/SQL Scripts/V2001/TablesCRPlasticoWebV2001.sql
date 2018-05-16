USE [GandhiDesarrollo]
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


-----------------------------------------------------------------------------------------------------
USE [GandhiDesarrollo]
GO

/****** Object:  Table [dbo].[MovCfgCom]    Script Date: 12/04/2018 05:45:17 p. m. ******/
--DROP TABLE MovCfgCom
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MovCfgCom](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Mov] [varchar](20) NOT NULL,
	[Modulo] [varchar](50) NOT NULL,
	[Concepto] [varchar](50) NOT NULL,
	[Observaciones] [varchar](100) NOT NULL,
	[Activo] [int] NOT NULL,
 CONSTRAINT [PK_MovCfgCom] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[MovCfgCom] ADD  CONSTRAINT [DF_MovCfgCom_Activo]  DEFAULT ((1)) FOR [Activo]
GO

--Llenado de la tabla MovCfgCom
Insert Into MovCfgCom (Mov,Modulo,Concepto,Observaciones) Values ('Anticipo Saldo','CXC','Anticipo de Clientes','Anticipo automático - Pedidos GCOM')

--Select * from MovCfgCom

---------------------------------------------------------------------------------
--2017121300(4)
--Script para crear el tipo CRPlasticoGcomType para recibir los CRs y MEs en el SW CRPlasticoWeb.RedimeSaldo
--Nota: Se necesita crear en las dos bases, Vales y Gandhi

--DROP TYPE [dbo].[CRPlasticoGcomType]
/****** Object:  [CRPlasticoGcomType] [dbo].[PedidoType]    Script Date: 01/02/2018 12:39:42 p. m. ******/

USE [ValesDesarrollo]
GO
CREATE TYPE [dbo].[CRPagoGComType] AS TABLE(
	CodigoBarras varchar(50) NULL,
	NIP varchar(10) NULL,
	SaldoRedimir Money NULL
)
GO

USE [GandhiDesarrollo]
GO
CREATE TYPE [dbo].[CRPagoGComType] AS TABLE(
	CodigoBarras varchar(50) NULL,
	NIP varchar(10) NULL,
	SaldoRedimir Money NULL
)
GO

----------------------------------------------------------------------------------------------------------
