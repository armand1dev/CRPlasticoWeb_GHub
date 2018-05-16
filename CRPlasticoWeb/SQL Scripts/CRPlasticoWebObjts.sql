
/*
	PROYECTO SW CRPlasticoWeb
	Objetos para la configuraciones de conexión con la base de Intelisis
	CRPlasticoWebObjts.sql
*/

	USE ValesDesarrollo

	IF OBJECT_ID('dbo.ValesCfg') IS NOT NULL
		DROP TABLE dbo.ValesCfg
	GO
	
	-- Crear tabla EncuestaCfg de parámetros configurables.
		Create Table dbo.ValesCfg (Empresa VARCHAR(5),
							  BaseDatos VarChar(50),
							  Usuario   VarChar(50), 
							  Password  VarChar(100))
	Insert into ValesCfg values ('GANDH' , 'GandhiDesarrollo', 'interfase', '1n73rf453')

	-- Select * from ValesCfg

