IF OBJECT_ID('dbo.CRPlasticoValidaGcomSPS') IS NOT NULL
    DROP PROCEDURE dbo.CRPlasticoValidaGcomSPS
GO

CREATE Procedure CRPlasticoValidaGcomSPS
(
   @CRPagoGcom CRPagoGComType Readonly,
   @IdPedido	 Varchar(50),
   @IdCliente	 Varchar(20),
   @IdMessage	 Int OUTPUT,    
   @Message      VarChar(255) OUTPUT,
   @Saldo		 Decimal(18,2) OUTPUT,
   @TipoTarjeta Varchar(50) OUTPUT
)
As
BEGIN
/*
	Objeto:		CRPlasticoValidaGcomSPS
	Fecha:		16 de Abril de 2018
	Autor:		Armando AS
	Proyecto:	Quitar caja GCOM
	App/Ver.:	CRPlasticoVCR 2001
	Objetivo:	Valida CR y ME antes del proceso de Redención de saldo a tarjetas CR desde página gandhi com
	Consideraciones:
			Vive en la BD de Vales			
			Recibe: 
				CR, Nip, Saldo a redimir 
			Regresa:
				Id del resultado en la variable de salida @IdMessage
					  1. Validación exitosa
					  0. Saldo insuficiente. El Saldo del CR es menor al que se intenta redimir.
					 -1. Dato incorrecto. [Descripción del dato incorrecto]. Favor de verificar.
					 -2. No se pudo realizar el movimiento. [Estatus del CR]. Favor de verificar.						 
					 -3. Las formas de pago son diferentes, deben ser del mismo tipo para realizar el movimiento de redención.	
					-99. Error del sistema: [Descripción del error].

				Mensaje asociado al Id del resultado obtenido, se obtiene en la variable de salida @Message							
	
	Ejemplo:

		-----------------------------------------------------------
		DECLARE	@IdPedido Varchar(50) = '001588126',--'12345012',
				@IdCliente Int = 500,
				@IdMessage INT,@Message VARCHAR(255),
				@Saldo		 Decimal(18,2),
				@TipoTarjeta Varchar(50)

		DECLARE @CRPagoGcom dbo.CRPagoGcomType
		INSERT INTO @CRPagoGcom values(N'330002243089','6441','2')

		EXEC CRPlasticoValidaGcomSPS @CRPagoGcom,@IdPedido,@IdCliente,@IdMessage Out, @Message Out, @Saldo Out, @TipoTarjeta Out
		SELECT @IdMessage as IdMessage, @Message as Message, @Saldo as Saldo, @TipoTarjeta as TipoTarjeta
		---------------------------
		Select * from GandhiDesarrollo.dbo.BitacoraRedimeCRGcom	order by Id desc	


		SELECT c.Id, c.CodigoBarras, c.NIP, ISNull(v.Importe, 0), c.Id,  v.Status
		FROM CRPlastico c Left join Vales v on c.Id = v.Id WHERE c.CodigoBarras = '3300000005218'

		DECLARE @Saldo money 
		SELECT @Saldo = GandhiDesarrollo.dbo.fnVerSaldoVale ('3300000005218')
		select @Saldo

		Select * from GandhiDesarrollo.dbo.EncuestaCfg
		sp_helptext CRPlasticoRedimeGcomSPI	

		Select * from ValesCfg	
		Select * from GandhiCfgCom
		Select * from MovCfgCom

		Select * from GandhiDesarrollo.dbo.BitacoraRedimeCRGcom	order by Id desc	
		Where IdPedido = '001588126'

		--ValeTipo	
		---------------------------
		--TO DO:	
		--Cambiar conexión para Redimir Saldo -> Ok
		--Dividir el SP en 2, uno para Validar y otrop para Redimir -> Ok
		--Permitir más de un CR o Monedero electrónico (arreglo de objetos para recibir varias tarjetas) -> Ok
		--Validar que sea solo CRs o Solo ME, no mezclar formas de pago -> Ok
		--Obtener TipoTarjeta para pasarla a CRPlasticoRedimeGcomSPI como parámetro
		En CRPlasticoRedimeGcomSPI
		--Validar qué tipo de tarjeta es (CR o ME) para poner su descripción el el campo FormaCobro1,2.. de CXC-- Ya no,se pasará como parámetro --OK
		--Tomar el tipo de anticipo del la configuración (Select Mov from MovCfgCom) --OK
		---------------------------

		sp_HelpText CRPlasticoValidaGcomSPS

*/

	BEGIN TRY

		DECLARE @MessageBitacora varchar(250)
		DECLARE @Base NVARCHAR(100)	
		DECLARE @SQLString NVARCHAR(800)
		DECLARE @ParmDefinition NVARCHAR(500)
		DECLARE @IdClienteInt INT = -1
		DECLARE @Referencia VARCHAR(50) = ''

		SET @TipoTarjeta = ''

		Select @Base = BaseDatos from ValesCfg

		SET @IdMessage = 1
		SET @Message = ''
		SET @Saldo = 0

		--Validar Id de pedido y cliente de Gcom
		If (IsNULL(@IdPedido, '') = '') 
		BEGIN
			SET @IdMessage = -1
			SET @Message = 'Ingresar IdPedido.'
		END

		If (IsNULL(@IdCliente, '') = '') And (@IdMessage > 0)
		BEGIN
			SET @IdMessage = -1
			SET @Message = 'Ingresar IdCliente.'
		END	

		If (IsNumeric(@IdCliente) = 0) And (@IdMessage > 0)
		BEGIN
			SET @IdMessage = -1
			SET @Message = 'IdCliente debe ser numérico.'
		END
		ELSE
		BEGIN
			SET @IdClienteInt = Cast(@IdCliente as INT)
		END

		IF (@IdMessage > 0)
		BEGIN		

			--Tabla que almacenará las tarjetas agrupadas, por si envía la misma tarjeta mas de una vez
			Declare @CRPagoGcomTable Table (	CodigoBarras varchar(50),
												NIP varchar(10),
												SaldoRedimir Money)
			Insert Into @CRPagoGcomTable (CodigoBarras,NIP,SaldoRedimir) 
			Select CodigoBarras,NIP,Sum(SaldoRedimir) As SaldoRedimir
			From @CRPagoGcom
			Group By CodigoBarras,NIP--, SaldoRedimir 

			DECLARE @CR Varchar(50), @Nip Varchar(10), @SaldoRedimir Money, @Tipo Varchar(50) = ''--, @Tipo1aTarjeta Varchar(50) = '' 			
			--Obtener el tipo de la primera tarjeta
			Select top 1 @CR = CodigoBarras From @CRPagoGcomTable
			SET @SQLString = 
			N'SELECT @TipoOut = Tipo FROM ' + @Base + '.dbo.ValeSerie Where Serie = @SerieCR '
			SET @ParmDefinition = N'@SerieCR Varchar(50), @TipoOut Varchar(50) output';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,
								@SerieCR = @CR,
								@TipoOut = @TipoTarjeta output;

			DECLARE CRCur CURSOR FOR
			SELECT COALESCE(CodigoBarras,''), COALESCE(NIP,''), COALESCE(SaldoRedimir,0) 
			FROM @CRPagoGcomTable
			OPEN CRCur
			FETCH CRCur INTO @CR ,@NIP ,@SaldoRedimir
			WHILE (@@FETCH_STATUS = 0 )
			BEGIN					
				IF (@IdMessage > 0)
				BEGIN
					--Validar que sea misma forma de pago (CR o ME)					
					--Select @Tipo = Tipo from GandhiDesarrollo.dbo.ValeSerie Where Serie in ('6600000984856','3300022430890')					
					SET @Tipo = ''
					SET @SQLString = 
					N'SELECT @TipoOut = Tipo FROM ' + @Base + '.dbo.ValeSerie Where Serie = @SerieCR '
					SET @ParmDefinition = N'@SerieCR Varchar(50), @TipoOut Varchar(50) output';
					EXECUTE sp_executesql @SQLString, @ParmDefinition,
										@SerieCR = @CR,
										@TipoOut = @Tipo output;
					IF (@Tipo <> @TipoTarjeta) And (@IdMessage > 0)
					BEGIN
						SET @IdMessage = -3
						SET @Message = 'Las formas de pago son diferentes, deben ser del mismo tipo para realizar el movimiento de redención.'
					END

					If (IsNULL(@NIP, '') = '') And (@IdMessage > 0)
					BEGIN
						SET @IdMessage = -1
						SET @Message = 'Ingresar Nip.'
					END
		
					If (IsNumeric(@NIP) = 0) And (@IdMessage > 0)
					BEGIN
						SET @IdMessage = -1
						SET @Message = 'El NIP debe ser un valor numérico.'
					END
		
					IF (Len(@CR) <> 13) And (@IdMessage > 0)
					BEGIN
						IF Len(@CR) = 0
						BEGIN
							SET @IdMessage = -1
							SET @Message = 'Ingresar el código de barras de la tarjeta.'
						END
						ELSE
						BEGIN
							SET @IdMessage = -1
							SET @Message = 'El código de barras de la tarjeta debe ser de 13 caracteres.'
						END 
					END

					If (IsNumeric(@SaldoRedimir) = 0) And (@IdMessage > 0)
					BEGIN
						SET @IdMessage = -1
						SET @Message = 'Saldo a redimir debe ser valor numérico.'
					END

					If (@SaldoRedimir= 0) And (@IdMessage > 0)
					BEGIN
						SET @IdMessage = -1
						SET @Message = 'Saldo a redimir debe ser mayor a cero.'
					END
				END
			
				FETCH CRCur INTO @CR ,@NIP ,@SaldoRedimir
			END
			CLOSE CRCur
			DEALLOCATE CRCur
		
		END		

		IF (@IdMessage > 0)
		BEGIN	
		
			--Busca el Nip (Ref. CRPlasticoSaldoSPS en Vales)
			DECLARE @strNIP Varchar(10), @SaldoActual money, @Id INT, @tnyStatus tinyint
			SELECT @strNIP = ISNULL(c.NIP,''), @SaldoActual = ISNull(v.Importe, 0), @Id = ISNULL(c.Id,0), @tnyStatus = v.Status
			from CRPlastico c
				Left join Vales v on c.Id = v.Id
			where c.CodigoBarras = @CR 

			--Debe tomar el saldo que hay en intelisis	
			--SELECT @SaldoActual = GandhiDesarrollo.dbo.fnVerSaldoVale (@CR)				
			SET @SQLString = 
			N'SELECT @SaldoOut = ' + @Base + '.dbo.fnVerSaldoVale (@SerieCR) '
			SET @ParmDefinition = N'@SerieCR Varchar(50), @SaldoOut money output';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,
								@SerieCR = @CR,
								@SaldoOut = @SaldoActual output;

			SET @Saldo = @SaldoActual
		
			If (IsNULL(@strNIP, '') = '')
			BEGIN
					SET @IdMessage = -1
					SET @Message = 'Código de barras del CR no es válido.'
			END

			If (IsNULL(@Id, '') = '') And (@IdMessage > 0)
			BEGIN
					SET @IdMessage = -2
					SET @Message = 'Certificado sin registro de venta.'
			END

			If (@strNIP <> @Nip) And (@IdMessage > 0)
			BEGIN
					SET @IdMessage = -1
					SET @Message = 'El NIP es incorrecto.'					
			END

			If (@tnyStatus = 2) And (@IdMessage > 0)
			BEGIN
					SET @IdMessage = -2
					SET @Message = 'El certificado está cancelado.'
					RETURN
			END

			If (@tnyStatus = 3) And (@IdMessage > 0)
			BEGIN
					SET @IdMessage = -2
					SET @Message = 'El certificado esta inactivo.'
			END

			If (@SaldoActual = 0 and @tnyStatus = 0) 
			BEGIN
					SET @IdMessage = -2
					SET @Message = 'El certificado ya fue utilizado totalmente.'
			END

			IF (@SaldoActual < @SaldoRedimir) And (@IdMessage > 0)
			BEGIN
					SET @IdMessage = 0
					SET @Message = 'Saldo insuficiente (' + convert(varchar(10),@SaldoActual) + '). El Saldo del CR es menor al que se intenta redimir (' + convert(varchar(10),@SaldoRedimir) + ').'
			END

			IF (@IdMessage = -1) 
			BEGIN
				SET @Message = 'Dato incorrecto. ' + @Message + ' Favor de verificar.'
			END	

			IF (@IdMessage = -2) 
			BEGIN
				SET @Message = 'No se pudo realizar el movimiento. ' + @Message + ' Favor de verificar.'
			END	

		END
		
		--Registra en la bitacora sino se pudo hacer la redencion del CR
		SET @Referencia = Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
		IF @IdMessage <= 0
		BEGIN
			SET @MessageBitacora = @Message + ' Ref. ' + @Referencia
			if (@TipoTarjeta <> '')
			BEGIN
				SET @MessageBitacora = @MessageBitacora + ' Tipo tarjeta ' + @TipoTarjeta
			END
			/*INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)*/
			SET @SQLString = 
			N'INSERT INTO ' + @Base +  '.dbo.BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedidoI,@IdClienteIntI,@CRI,@NipI,@SaldoRedimirI,@IdMessageI,@MessageBitacoraI)'
			SET @ParmDefinition = N'@IdPedidoI Varchar(50),@IdClienteIntI Int,@CRI varchar(50),@NipI varchar(10),@SaldoRedimirI Money,@IdMessageI Int,@MessageBitacoraI Varchar(250)';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,							
								@IdPedidoI = @IdPedido,
								@IdClienteIntI = @IdClienteInt,
								@CRI = @CR,
								@NipI = @Nip,
								@SaldoRedimirI = @SaldoRedimir,
								@IdMessageI = @IdMessage,
								@MessageBitacoraI = @MessageBitacora;
			RETURN
		END
		ELSE
		BEGIN		
			--Validación correcta, puede REDIMIR SALDO
			SET @IdMessage = 1
			SET @Message = 'Validación exitosa.'

			/*------Test------------------------------
			--SET @MessageBitacora = @Message + ' Ref. ' + @Referencia
			SET @SQLString = 
			N'INSERT INTO ' + @Base +  '.dbo.BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedidoI,@IdClienteIntI,@CRI,@NipI,@SaldoRedimirI,@IdMessageI,@MessageBitacoraI)'
			SET @ParmDefinition = N'@IdPedidoI Varchar(50),@IdClienteIntI Int,@CRI varchar(50),@NipI varchar(10),@SaldoRedimirI Money,@IdMessageI Int,@MessageBitacoraI Varchar(250)';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,							
								@IdPedidoI = @IdPedido,
								@IdClienteIntI = @IdClienteInt,
								@CRI = @CR,
								@NipI = @Nip,
								@SaldoRedimirI = @SaldoRedimir,
								@IdMessageI = @IdMessage,
								@MessageBitacoraI = @Message;--@MessageBitacora;
			------Test------------------------------*/

		END
	END TRY
	BEGIN CATCH								
		--Return -99
		DECLARE @Error INT
		DECLARE @MESSAGE_Catch NVARCHAR(500)
		SET @Error = ERROR_NUMBER()  
		SET @MESSAGE_Catch = 'Error Number: ' + CONVERT(VARCHAR(10),@Error) + ' Description: ' + ERROR_MESSAGE()  	
		SET @IdMessage = -99 --Error
		SET @Message = 'Error del sistema. ' + @MESSAGE_Catch
		SET @MessageBitacora = @Message + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
		IF (@TipoTarjeta <> '')
		BEGIN
			SET @MessageBitacora = @MessageBitacora + ' Tipo tarjeta ' + @TipoTarjeta
		END
		/*INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
		VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)	*/
		SET @SQLString = 
			N'INSERT INTO ' + @Base +  '.dbo.BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedidoI,@IdClienteIntI,@CRI,@NipI,@SaldoRedimirI,@IdMessageI,@MessageBitacoraI)'
			SET @ParmDefinition = N'@IdPedidoI Varchar(50),@IdClienteIntI Int,@CRI varchar(50),@NipI varchar(10),@SaldoRedimirI Money,@IdMessageI Int,@MessageBitacoraI Varchar(250)';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,							
								@IdPedidoI = @IdPedido,
								@IdClienteIntI = @IdClienteInt,
								@CRI = @CR,
								@NipI = @Nip,
								@SaldoRedimirI = @SaldoRedimir,
								@IdMessageI = @IdMessage,
								@MessageBitacoraI = @MessageBitacora;
			
	END CATCH	

END
