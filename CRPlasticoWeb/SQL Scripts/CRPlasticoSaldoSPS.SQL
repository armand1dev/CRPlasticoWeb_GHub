IF OBJECT_ID('dbo.CRPlasticoSaldoSPS') IS NOT NULL
    DROP PROCEDURE dbo.CRPlasticoSaldoSPS
GO

SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF
GO

Create Procedure dbo.CRPlasticoSaldoSPS
(
   @CR			Varchar(13),
   @NIP			Char(4) = '',
   @IdError     INT OUTPUT,    
   @Saldo       Money OUTPUT,
   @Mensaje     VarChar(100) OUTPUT	
)
As
BEGIN
/*
	Objeto:		CRPlasticoSaldoSPS
	Fecha:		12 de octubre de 2017
	Autor:		Alma Bárcenas
	Proyecto:	SW CRPlasticoWeb
	Objetivo:	Consulta de Saldo del CR disminuyendo lo que se ha utilizado en los pedidos de GCOM
	Base Datos: Vales
	
	---------------------MODIFICACIONES-------------------------------------------------------	
		Referencia: 2018021800(1)
		Fecha	  : 22 marzo 2018
		Modificó  : Armando AS
		Motivo    : Se omite la resta de saldo retenido por movimientos pendientes, 
					esto porque ya se hará la redencion de saldo del CR desde Gandhi com
					(con el nuevo método "Redención" del sw CRPlasticoSRV).
	-----------------------------------------
		Referencia: 2017110600(01)
		Fecha	  : 6 nov 2017
		Modificó  : Alma Bárcenas
		Motivo    : Muestra mensaje confuso cuando el CR no tiene saldo
	-----------------------------------------




	Ejemplo:
		DECLARE @IdError     INT , @Saldo       Money, @Mensaje     VarChar(100)
		EXEC CRPlasticoSaldoSPS '3303810796567', '3951', @IdError OUT, @Saldo out, @Mensaje out
		SELECT @IdError, @Saldo, @Mensaje

		DECLARE @IdError     INT , @Saldo       Money, @Mensaje     VarChar(100)
		EXEC CRPlasticoSaldoSPS '3317899859150', '4295', @IdError OUT, @Saldo out, @Mensaje out
		SELECT @IdError, @Saldo, @Mensaje

		DECLARE @IdError     INT , @Saldo       Money, @Mensaje     VarChar(100)
		EXEC CRPlasticoSaldoSPS '3309343173004', '1753', @IdError OUT, @Saldo out, @Mensaje out
		SELECT @IdError, @Saldo, @Mensaje

	---------------------------------------------------------------------------------------------
	Comprobación

		Select c.CodigoBarras, c.NIP, v.Importe 
		from CRPlastico c
		join Vales v on c.Id = v.Id
		where c.CodigoBarras = '3303810796567'

		Select Sum(gt.Importe) 
		from GandhiDesarrollo.dbo.GandhiComTarjetaSerieMov gt
		join GandhiDesarrollo.dbo.Venta v on gt.Id = v.Id 
		where 
		v.Estatus = 'PENDIENTE'
		and gt.FormaCobro = 'CERTIFICADO DE REGALO'
		and	gt.Serie = '3303810796567'


IdError="-4" Saldo="0" Mensaje="El NIP debe ser un valor numérico."
IdError="-3" Saldo="0" Mensaje="Ingrese el NIP."
IdError="-2" Saldo="0" Mensaje="El código de barras debe ser de 13 caracteres."
IdError="-1" Saldo="0" Mensaje="Ingrese el código de barras."
IdError="0" Saldo="166.00" Mensaje="Consulta de saldo exitosa."
IdError="1" Saldo="0" Mensaje="Ingrese un código de barras válido."
IdError="2" Saldo="0" Mensaje="Certificado sin registro de venta."
IdError="3" Saldo="0" Mensaje="El NIP es incorrecto."
IdError="4" Saldo="0" Mensaje="El certificado esta cancelado."
IdError="5" Saldo="0" Mensaje="El certificado esta inactivo."
IdError="6" Saldo="0" Mensaje="El certificado ya fue utilizado totalmente."

*/

	DECLARE 
		@Id       int,
		@strNIP   Char(4),    
		@tnyStatus tinyint

	SET @IdError = 0
	SET @Saldo = 0
	SET @Mensaje = 'Consulta de saldo exitosa.'
	
	If (IsNULL(@NIP, '') = '')
	BEGIN
		SET @IDError = -4
		SET @Mensaje = 'Ingrese el NIP.'
		RETURN
	END

	If (IsNumeric(@NIP) = 0) 
	BEGIN
		SET @IDError = -3
		SET @Mensaje = 'El NIP debe ser un valor numérico.'
		RETURN
	END
	
	IF Len(@CR) <> 13
	BEGIN
		IF Len(@CR) = 0
		BEGIN
			SET @IDError = -1
			SET @Mensaje = 'Ingrese el código de barras.'
			RETURN
		END
		ELSE
		BEGIN
			SET @IDError = -2
			SET @Mensaje = 'El código de barras debe ser de 13 caracteres.'
			RETURN
		END 
	END

	SELECT @strNIP = c.NIP, @Saldo = ISNull(v.Importe, 0), @Id = c.Id, @tnyStatus = v.Status
	from CRPlastico c
	Left join Vales v on c.Id = v.Id
	where
		c.CodigoBarras = @CR 

	-- SELECT  @CR	,   @NIP, @strNIP, @Saldo, @Id, @tnyStatus

	If (IsNULL(@strNIP, '') = '')
	BEGIN
			SET @IDError = 1
			SET @Mensaje = 'Ingrese un código de barras válido.'
			RETURN
	END

	If (IsNULL(@Id, '') = '')
	BEGIN
			SET @IDError = 2
			SET @Mensaje = 'Certificado sin registro de venta.'
			RETURN
	END
	If (@strNIP <> @NIP)
	BEGIN
			SET @IDError = 3
			SET @Mensaje = 'El NIP es incorrecto.'
			RETURN
	END

	If (@tnyStatus = 2)
	BEGIN
			SET @IDError = 4
			SET @Mensaje = 'El certificado está cancelado.'
			RETURN
	END

	If (@tnyStatus = 3)
	BEGIN
			SET @IDError = 5
			SET @Mensaje = 'El certificado esta inactivo.'
			RETURN
	END

	If (@Saldo = 0 and @tnyStatus = 0) -- 2017110600(01)
	BEGIN
			SET @IDError = 6
			SET @Mensaje = 'El certificado ya fue utilizado totalmente.'
			RETURN
	END

	DECLARE @strCB NVARCHAR(13);
	DECLARE @SQLString NVARCHAR(500);
	DECLARE @ParmDefinition NVARCHAR(500);
	DECLARE @Base NVARCHAR(100);
	DECLARE @RetenidoOut Money;

	Select @Base = BaseDatos from ValesCfg

	--2018021800(1) Se omite la resta del saldo retenido (se comenta el siguiente código)
	/*-- Consulta
	SET @SQLString = 
		N'SELECT @Retenido = Sum(gt.Importe) FROM ' + @Base + '.dbo.GandhiComTarjetaSerieMov gt ' +
		 'Join ' + @Base + '.dbo.Venta v on gt.Id = v.Id ' +
		 'where v.Estatus = ''PENDIENTE'' and gt.FormaCobro = ''CERTIFICADO DE REGALO'' and	gt.Serie = @Serie '

	-- Select @SQLString

	-- Variables
	SET @ParmDefinition = N'@Serie Varchar(20), @Retenido money output';

	-- Ejecución

	EXECUTE sp_executesql @SQLString, @ParmDefinition,
							@Serie = @CR,
							@Retenido = @RetenidoOut output;

	SET @Saldo = @Saldo - IsNull(@RetenidoOut, 0)
	*/

END
