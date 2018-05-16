IF OBJECT_ID('dbo.CRPlasticoActualizaSPU') IS NOT NULL
    DROP PROCEDURE dbo.CRPlasticoActualizaSPU
GO

SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF
GO

Create Procedure dbo.CRPlasticoActualizaSPU
(
   @CR			Varchar(13),
   @Acceso		Char(4) = '',
   @IdError     INT OUTPUT,    
   @Saldo       Money OUTPUT,
   @Mensaje     VarChar(100) OUTPUT	
)
As
BEGIN
/*
	Objeto:		CRPlasticoActualizaSPU
	Fecha:		13 de octubre de 2017
	Autor:		Alma Bárcenas
	Proyecto:	SW CRPlasticoWeb
	Objetivo:	Activación de CR inactivo
	Base Datos: Vales
	
	Ejemplo:
		DECLARE @IdError     INT , @Saldo       Money, @Mensaje     VarChar(100)
		EXEC CRPlasticoActualizaSPU '3308456951295', '1944', @IdError OUT, @Saldo out, @Mensaje out
		SELECT @IdError, @Saldo, @Mensaje

IdError="-6" Saldo="0" Mensaje="El código de activación debe ser un valor numérico."
IdError="-5" Saldo="0" Mensaje="Ingrese el código de activación."
IdError="-2" Saldo="0" Mensaje="El código de barras debe ser de 13 caracteres."
IdError="-1" Saldo="0" Mensaje="Ingrese el código de barras."
IdError="0" Saldo="166.00" Mensaje="Activación exitosa."
IdError="1" Saldo="0" Mensaje="Ingrese un código de barras válido."
IdError="2" Saldo="0" Mensaje="Certificado sin registro de venta."
IdError="4" Saldo="0" Mensaje="El certificado esta cancelado."
IdError="6" Saldo="0" Mensaje="El certificado ya fue utilizado totalmente."
IdError="7" Saldo="100.00" Mensaje="El certificado ya está activo."
IdError="8" Saldo="0" Mensaje="Error en la activación."
IdError="9" Saldo="0" Mensaje="El código de activación es incorrecto."

*/

	DECLARE 
		@Id       int,
		@strAcceso   Char(4),    
		@tnyStatus tinyint

	SET @IdError = 0
	SET @Saldo = 0
	SET @Mensaje = 'Activación exitosa.'

	If (IsNULL(@Acceso, '') = '')
	BEGIN
		SET @IDError = -5
		SET @Mensaje = 'Ingrese el código de activación.'
		RETURN
	END
		
	If (IsNumeric(@Acceso) = 0) 
	BEGIN
		SET @IDError = -6
		SET @Mensaje = 'El código de activación debe ser un valor numérico.'
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

	SELECT @strAcceso = c.Acceso, @Saldo = ISNull(v.Importe, 0), @Id = c.Id, @tnyStatus = v.Status
	from CRPlastico c
	Left join Vales v on c.Id = v.Id
	where
		c.CodigoBarras = @CR 

	-- SELECT  @CR	,   @Acceso, @strAcceso, @Saldo, @Id, @tnyStatus

	If (@strAcceso <> @Acceso)
	BEGIN
			SET @IDError = 9
			SET @Mensaje = 'El código de activación es incorrecto.'
			RETURN
	END

	If (IsNULL(@strAcceso, '') = '')
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
	
	If (@tnyStatus = 4)
	BEGIN
			SET @IDError = 4
			SET @Mensaje = 'El certificado está cancelado.'
			RETURN
	END

	If (@Saldo = 0)
	BEGIN
			SET @IDError = 6
			SET @Mensaje = 'El certificado ya fue utilizado totalmente.'
			RETURN
	END

	If (@tnyStatus = 1)
	BEGIN
			SET @IDError = 8
			SET @Mensaje = 'El certificado está activo.'
			RETURN
	END

	
	
	BEGIN TRY
		UPDATE Vales SET Status = 1 WHERE Id = @Id
	END TRY
	BEGIN CATCH
		SET @IDError = 8
		SET @Mensaje = 'Error en la activación'
	END CATCH;

END
