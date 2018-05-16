IF OBJECT_ID('dbo.CRPlasticoRedimeGcomSPI') IS NOT NULL
    DROP PROCEDURE dbo.CRPlasticoRedimeGcomSPI
GO

CREATE Procedure CRPlasticoRedimeGcomSPI
(
   @CRPagoGcom CRPagoGComType Readonly,
   @TipoTarjeta	 Varchar(50),
   @IdPedido	 Varchar(50),
   @IdCliente	 Varchar(20),
   @IdMessage	 Int OUTPUT,    
   @Message      VarChar(255) OUTPUT,
   @Saldo		 Decimal(18,2) OUTPUT
)
As
BEGIN
/*
	Objeto:		CRPlasticoRedimeGcomSPI
	Fecha:		12 de marzo de 2018
	Autor:		Armando AS
	Proyecto:	Quitar caja GCOM
	App/Ver.:	CRPlasticoVCR 2001
	Objetivo:	Redimir saldo a tarjetas CR y Monedero Electrónico desde página gandhi com
	Consideraciones:
			Vive en la BD Gandhi, y se conecta por medio Linked server a Vales.
			Nota: Toma el LINKED server de la tabla ValesCfg
			Recibe: 
				CR, Nip, Saldo a redimir 
			Regresa:
				Id del resultado y su mensaje en las variables de salida @IdMessage y @Message respectivamente
					  1. Redención exitosa
					  Del -3 al 0 se validan en el SP que precede a este (CRPlasticoValidaGcomSPS).
						 0. Saldo insuficiente. El Saldo del CR es menor al que se intenta redimir.
						-1. Dato incorrecto. [Descripción del dato incorrecto]. Favor de verificar.
						-2. No se pudo realizar el movimiento. [Estatus del CR]. Favor de verificar.
						-3. Las formas de pago son diferentes, deben ser del mismo tipo para realizar el movimiento de redención.
					-4. No se pudo realizar el movimiento. [Mensaje de Intelisis].
					-99. Error del sistema: [Descripción del error].
	
	Ejemplo:
		------------------------------------------------------
		DECLARE	@IdPedido Varchar(50) = '001588130',--'12345012',
		@TipoTarjeta varchar(50) = 'CERTIFICADO PLASTICO', 		
		@IdCliente Int = 500,
		@IdMessage INT,@Message VARCHAR(255),
		@Saldo		 Decimal(18,2)

		DECLARE @CRPagoGcom dbo.CRPagoGcomType
		INSERT INTO @CRPagoGcom values(N'3300022430890','6441','1')

		EXEC CRPlasticoRedimeGcomSPI @CRPagoGcom,@TipoTarjeta,@IdPedido,@IdCliente,@IdMessage Out, @Message Out, @Saldo Out
		SELECT @IdMessage as IdMessage, @Message as Message, @Saldo as Saldo
		---------------------------
		Select * from GandhiDesarrollo.dbo.BitacoraRedimeCRGcom	order by Id desc	

		---------------------------
		SELECT c.Id, c.CodigoBarras, c.NIP, ISNull(v.Importe, 0), c.Id,  v.Status
		FROM CRPlastico c Left join Vales v on c.Id = v.Id WHERE c.CodigoBarras = '3300000005218'

		DECLARE @Saldo money 
		SELECT @Saldo = GandhiDesarrollo.dbo.fnVerSaldoVale ('3300000005218')
		select @Saldo

		Select * from GandhiDesarrollo.dbo.EncuestaCfg
		sp_helptext CRPlasticoRedimeGcomSPI	

		en Vales
		----------------------------
		Select * from ValesCfg			
		
		En Gandhi
		----------------------------
		Select * from GandhiCfgCom
		Select * from MovCfgCom
		--Revisión
		Select * from BitacoraRedimeCRGcom	order by Id desc	
		Select Estatus, * from CXC Where Mov = 'Anticipo Saldo' and Referencia = '500-001588135' --and FechaEmision >= getdate()-1
		Select * from TarjetaSerieMov Where Modulo = 'CXC' and Id = 1416330
		Select * from CRSincronizacion
		Select * from ValesDesarrollo.dbo.CRSincronizacion Where Envio = 0

		Select top 10 * from ValeSerie where Tipo = 'Certificado de Regalo' and Estatus = 'CIRCULACION'
		order by FechaEmision desc

		Select top 10 * from ValeSerie where Serie = '3300000000848'

		Select * from ValesDesarrollo.dbo.CRPLastico Where CodigoBarras Collate Modern_Spanish_CI_AS
		in (
			Select Serie from ValeSerie where Tipo = 'Certificado de Regalo' and Estatus = 'CIRCULACION'
			--order by FechaEmision desc
		)
		--= '3300000007915' 2215 $100 OK

		Select top 100 * from ValesDesarrollo.dbo.CRPLastico Where CodigoBarras Collate Modern_Spanish_CI_AS
		in (
			Select Serie from ValeSerie where Tipo = 'Monedero Electronico' and Estatus = 'CIRCULACION'
			--order by FechaEmision desc
		)
		--= '6600012897953' 5489 $956 OK

		--insert Into BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,Message,Fecha)
		Select IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,Message,Fecha from ValesDesarrollo.dbo.BitacoraRedimeCRGcom		


		}
		Select * from BitacoraRedimeCRGcom		
		--ValeTipo	
		---------------------------
		--TO DO:		
		--Validar qué tipo de tarjeta es (CR o ME) para poner su descripción el el campo FormaCobro1,2.. de CXC
		--Tomar el tipo de anticipo del la configuraciópn (Select Mov from MovCfgCom)
		---------------------------

		sp_HelpText CRPlasticoRedimeGcomSPI

*/

	BEGIN TRY

		DECLARE @MessageBitacora varchar(250)
		DECLARE @SaldoActual money
		/*DECLARE @Base NVARCHAR(100)	
		DECLARE @SQLString NVARCHAR(800)
		DECLARE @ParmDefinition NVARCHAR(500)*/
		DECLARE @IdClienteInt INT = -1
		DECLARE @Referencia VARCHAR(50) = ''
		DECLARE @Mov Varchar(50) = ''

		--Select @Base = BaseDatos from ValesCfg

		SET @IdMessage = 1
		SET @Message = ''
		SET @Saldo = 0

		SET @IdClienteInt = Cast(@IdCliente as INT)
		SET @Referencia = Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
		
		--REDIMIR SALDO		
		--Tabla que almacenará las tarjetas agrupadas, por si envía la misma tarjeta mas de una vez
		Declare @CRPagoGcomTable Table (	CodigoBarras varchar(50),
											NIP varchar(10),
											SaldoRedimir Money)
		Insert Into @CRPagoGcomTable (CodigoBarras,NIP,SaldoRedimir) 
		Select CodigoBarras,NIP,Sum(SaldoRedimir) As SaldoRedimir
		From @CRPagoGcom
		Group By CodigoBarras,NIP--, SaldoRedimir 

		DECLARE @ModuloCfg Varchar(50), @ConceptoCfg Varchar(50), @ObservacionesCfg Varchar(100), @ClienteGComCfg Varchar(10), 
				@Ok Int, @OkRef varchar(200), @DefCtaDinero VarChar(10),@IdCXC INT, @UsuarioGCom Varchar(10),
				@SaldoRedimir Money

		SET @UsuarioGCom = 'GCOM'
		--Obtener valores de configuración(MovCfgCom) para el mov que se va generar
		SELECT @Mov = Mov, @ModuloCfg = Modulo, @ConceptoCfg = Concepto, @ObservacionesCfg = Observaciones From MovCfgCom WHERE Id = 1 --Mov = 'Anticipo Saldo'
		IF @Mov <> ''
		BEGIN
			--Obtener valores de configuración(GandhiCfgCom) para el mov Anticipo Saldo
			SELECT @ClienteGComCfg = Cliente From GandhiCfgCom WHERE Empresa = 'GANDH'
			--Obtener valores del Usuario GCOM (Tabla Usuario) para el mov Anticipo Saldo
			SELECT @DefCtaDinero = DefCtaDinero From Usuario WHERE usuario = @UsuarioGCom
			--Obtiene el total de saldo a redimir
			Select @SaldoRedimir = SUM(SaldoRedimir) From @CRPagoGcomTable

			SET @IdCXC = 0
			--Agrega Movimiento en CXC
			DECLARE @fecSinHra Date
			Select @fecSinHra = dbo.fnFechaSinHora(GETDATE())		
			
			/*
			declare @strSQL varchar(300) = '';
			SET @strSQL = 'INICIO. @fecSinHra=' + COALESCE(CONVERT(varchar(30),@fecSinHra),'')+' @ConceptoCfg='+COALESCE(@UsuarioGCom,'')+' @Referencia='+COALESCE(@Referencia,'')+' @ObservacionesCfg='+COALESCE(@ObservacionesCfg,'')+' @ClienteGComCfg='+COALESCE(@ClienteGComCfg,'')+' @DefCtaDinero='+COALESCE(@DefCtaDinero,'')+' @SaldoRedimir='+COALESCE(CONVERT(varchar(10),@SaldoRedimir),'')+' @TipoTarjeta='+COALESCE(@TipoTarjeta,'')+' @SaldoRedimir='+COALESCE(CONVERT(varchar(10),@SaldoRedimir),'')+' @UsuarioGCom='+COALESCE(@UsuarioGCom,'')+' @DefCtaDinero='+COALESCE(@DefCtaDinero,'')+'. FIN'
			Select @strSQL			
			*/
				
			
			INSERT INTO CXC (Empresa,Mov,FechaEmision,Concepto,Moneda,TipoCambio,Usuario,Referencia,Observaciones,Cliente,ClienteMoneda,ClienteTipoCambio,CtaDinero,Importe,Impuestos,ConDesglose,FormaCobro1,Importe1,Sucursal,Cajero,DineroCtaDinero,SucursalOrigen,SucursalDestino,Estatus) 
			VALUES('GANDH',@Mov,@fecSinHra,@ConceptoCfg,'Pesos',1,@UsuarioGCom,@Referencia,@ObservacionesCfg,@ClienteGComCfg,'Pesos',1,@DefCtaDinero,@SaldoRedimir,0.0,1,@TipoTarjeta,@SaldoRedimir,11,@UsuarioGCom,@DefCtaDinero,11,11,'SINAFECTAR')			
			SET @IdCXC=SCOPE_IDENTITY();
			
			--Agregar Tarjetas en TarjetaSerieMov 
			IF(COALESCE(@IdCXC,0) > 0)
			BEGIN				
				--Afectar Mov generado (Anticipo Saldo)
				--Sucursal = 0 ?
				INSERT INTO TarjetaSerieMov (Empresa, Modulo, ID, Serie, Importe, Sucursal, GandhiAcumular)
				SELECT 'GANDH','CXC',@IdCXC,CodigoBarras, SaldoRedimir,0,0 FROM @CRPagoGcomTable
				--VALUES ('GANDH','CXC',@IdCXC,@CR,@SaldoRedimir,0,0)

				--Afectar el Mov CXC
				EXEC GandhiDesarrollo.dbo.spAfectar 'CXC', @IdCXC, 'AFECTAR', 'Todo', NULL, 'INTELISIS', @EnSilencio = 1, @Ok = @Ok OUTPUT, @OkRef = @OkRef OUTPUT

				--SET @OK = 999
				--IF (@OK is null)
				IF (COALESCE(@OK,0) > 0)
				BEGIN
					SET @IdMessage = 1
					SET @Message = 'Redención exitosa.'
					--Registra redención ok															
			
				END
				ELSE
				BEGIN
					--Registra el mensaje de Intelisis, por lo que no se pudo hacer la disminución
					SET @IdMessage = -4
					SET @Message = 'No se pudo realizar el movimiento. Intelisis dice | @Ok=' + CONVERT(Varchar(10),COALESCE(@Ok,0)) + ' - @OkRef=' + @OkRef + '|'
					SET @MessageBitacora = @Message + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
					--INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
					--VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
				END

			END
			ELSE
			BEGIN
				--Registra el error, no se pudo completar el movimiento
				SET @IdMessage = -4
				SET @Message = 'No se pudo realizar el movimiento. Error al tratar generar el mov. ' + @Mov + '. Intente nuevamente.'
				SET @MessageBitacora = @Message + ' Se produjo al intentar insertar en la tabla dbo.CXC. Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
				--INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				--VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
			END
			
		END
		ELSE
		BEGIN
			SET @IdMessage = -99 --Error (en la configuración: tabla MovCfgCom)
			SET @Message = 'Error del sistema. No obtuvo el movimiento contable para CXC (Revisar tabla de configuración MovCfgCom)'  
			SET @MessageBitacora = @Message + ' Ref. ' + @Referencia 			
			--INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			--VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)							
		END

		
		--Cursor para registrar resultao del proceso enla bitácora
		DECLARE @CR Varchar(50), @Nip Varchar(10), @SaldoRedimirCur Money
		DECLARE CRCur CURSOR FOR
		SELECT COALESCE(CodigoBarras,''), COALESCE(NIP,''), COALESCE(SaldoRedimir,0) 
		FROM @CRPagoGcomTable
		OPEN CRCur
		FETCH CRCur INTO @CR ,@NIP ,@SaldoRedimirCur
		WHILE (@@FETCH_STATUS = 0 )
		BEGIN					
			IF (@IdMessage = 1)
			BEGIN
				SET @SaldoActual = -1
				SELECT @SaldoActual = GandhiDesarrollo.dbo.fnVerSaldoVale (@CR)												
				IF (@SaldoActual = -1)
				BEGIN
					SET @MessageBitacora = @Message + ' Saldo actual: -No se pudo obtener el saldo-' + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido					
				END
				ELSE
				BEGIN
					SET @Saldo = @Saldo + @SaldoActual
					SET @MessageBitacora = @Message + ' Saldo actual $' + Convert(varchar(10),@SaldoActual) + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido					
				END
			END
			IF (@TipoTarjeta <> '')
			BEGIN
				SET @MessageBitacora = @MessageBitacora + ' Tipo tarjeta ' + @TipoTarjeta
			END
			INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimirCur,@IdMessage,@MessageBitacora)
			
			FETCH CRCur INTO @CR ,@NIP ,@SaldoRedimirCur
		END
		CLOSE CRCur
		DEALLOCATE CRCur
			


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
		INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
		VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)							
			
	END CATCH	

END
