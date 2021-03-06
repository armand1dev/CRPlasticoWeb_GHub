USE [GandhiDesarrollo]
GO
/****** Object:  StoredProcedure [dbo].[CRPlasticoRedimeGcomSPI]    Script Date: 17/04/2018 03:06:15 p. m. ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Procedure [dbo].[CRPlasticoRedimeGcomSPI]
(
   @CR			 Varchar(50),
   @Nip			 Varchar(10),
   @SaldoRedimir Money,
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
	Objetivo:	Redimir saldo a tarjetas CR desde página gandhi com
	Consideraciones:
			Vive en la BD Gandhi, y se conecta por medio Linked server a Vales.
			Nota: Toma el LINKED server de la tabla ValesCfg
			Recibe: 
				CR, Nip, Saldo a redimir 
			Regresa:
				Id del resultado en la variable de salida @IdMessage
					  1. Redención exitosa
					  Del -3 al 0 se validan en CRPlasticoValidaGcomSPS
						 0. Saldo insuficiente. El Saldo del CR es menor al que se intenta redimir.
						-1. Dato incorrecto. [Descripción del dato incorrecto]. Favor de verificar.
						-2. No se pudo realizar el movimiento. [Estatus del CR]. Favor de verificar.	
						-3. Las formas de pago son diferentes, deben ser del mismo tipo para realizar el movimiento de redención.	
					 -4. No se pudo realizar el movimiento. [Mensaje de Intelisis].	
					-99. Error del sistema: [Descripción del error].

				Mensaje asociado al Id del resultado obtenido, se obtiene en la variable de salida @Message
						
			Nota: Ref. EncuestaCRSaldoSPI.sql
	
	Ejemplo:
		DECLARE @CR			 Varchar(20) = '3300000005218',
				@Nip		 Varchar(10) = '2860',
				@SaldoRedimir Money = 5,
				@IdPedido Varchar(50) = '12345012',
				@IdCliente Int = 500
		DECLARE @IdMessage INT,@Message VARCHAR(255)
		EXEC CRPlasticoRedimeGcomSPI @CR, @Nip, @SaldoRedimir,@IdPedido,@IdCliente,@IdMessage Out, @Message Out
		SELECT @IdMessage, @Message

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
		Select * from BitacoraRedimeCRGcom		

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

		--Select @Base = BaseDatos from ValesCfg

		SET @IdMessage = 1
		SET @Message = ''
		SET @Saldo = 0

		SET @IdClienteInt = Cast(@IdCliente as INT)
		SET @Referencia = Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
		
		--REDIMIR SALDO
		--Generar Mov Anticipo Saldo
		
		DECLARE @ModuloCfg Varchar(50), @ConceptoCfg Varchar(50), @ObservacionesCfg Varchar(100), @ClienteGComCfg Varchar(10), 
				@Ok Int, @OkRef varchar(200), @DefCtaDinero VarChar(10),@IdCXC INT, @UsuarioGCom Varchar(10)
		SET @UsuarioGCom = 'GCOM'
		--Obtener valores de configuración(MovCfgCom) para el mov Anticipo Saldo
		SELECT @ModuloCfg = Modulo, @ConceptoCfg = Concepto, @ObservacionesCfg = Observaciones From MovCfgCom WHERE Mov = 'Anticipo Saldo'
		/*SET @SQLString = 
		N'SELECT @ModuloCfgOut = Modulo, @ConceptoCfgOut = Concepto, @ObservacionesCfgOut = Observaciones FROM ' + @Base +  '.dbo.MovCfgCom WHERE Mov = ''Anticipo Saldo''' 
		SET @ParmDefinition = N'@ModuloCfgOut Varchar(50) output, @ConceptoCfgOut Varchar(50) output, @ObservacionesCfgOut Varchar(100) output';
		EXECUTE sp_executesql @SQLString, @ParmDefinition,								
							@ModuloCfgOut = @ModuloCfg Output,
							@ConceptoCfgOut = @ConceptoCfg Output,							
							@ObservacionesCfgOut = @ObservacionesCfg output;
		*/
		
		--Obtener valores de configuración(GandhiCfgCom) para el mov Anticipo Saldo
		SELECT @ClienteGComCfg = Cliente From GandhiCfgCom WHERE Empresa = 'GANDH'
		/*SET @SQLString = 
		N'SELECT @ClienteGComCfgOut = Cliente FROM ' + @Base +  '.dbo.GandhiCfgCom WHERE Empresa = ''GANDH'''
		SET @ParmDefinition = N'@ClienteGComCfgOut Varchar(10) output';
		EXECUTE sp_executesql @SQLString, @ParmDefinition,							
							@ClienteGComCfgOut = @ClienteGComCfg Output;
		*/

		--Obtener valores del Usuario GCOM (Tabla Usuario) para el mov Anticipo Saldo
		SELECT @DefCtaDinero = DefCtaDinero From Usuario WHERE usuario = @UsuarioGCom
		/*SET @SQLString = 
		N'SELECT @DefCtaDineroOout = DefCtaDinero FROM ' + @Base +  '.dbo.Usuario WHERE usuario = @Usuario'
		SET @ParmDefinition = N'@Usuario Varchar(10), @DefCtaDineroOout Varchar(10) output';
		EXECUTE sp_executesql @SQLString, @ParmDefinition,							
							@Usuario = @UsuarioGCom,
							@DefCtaDineroOout = @DefCtaDinero Output;
		*/
		
		--Insertar en CX el mov Anticipo Saldo		
		--ESTATUS? -> SINAFECTAR
		--VENCIMIENTO?
		--'CERTIFICADO DE REGALO' FormaCobro1 -> Obtener descripción de la tarjeta 'MONEDERO ELECTRONICO' o 'CERTIFICADO DE REGALO' --ValeTipo
		-- FormaCobro1 -> el Anticipo podrá ser por varias tarjetas? :. Cambiaría la form de solicitar los datos
		--Poliza?
		--PolizaID?
		--Ejercicio?
		--Periodo?
		--DineroID?
		--DineroCtaDinero -- 'GACOM098' Ok	

		DECLARE @fecSinHra Date
		Select @fecSinHra = dbo.fnFechaSinHora(GETDATE())
		--Select @fecSinHra
		INSERT INTO CXC (Empresa,Mov,FechaEmision,Concepto,Moneda,TipoCambio,Usuario,Referencia,Observaciones,Cliente,ClienteMoneda,ClienteTipoCambio,CtaDinero,Importe,Impuestos,ConDesglose,FormaCobro1,Importe1,Sucursal,Cajero,DineroCtaDinero,SucursalOrigen,SucursalDestino,Estatus) 
		VALUES('GANDH','Anticipo Saldo', @fecSinHra,@ConceptoCfg,'Pesos',1,@UsuarioGCom,@Referencia,@ObservacionesCfg,@ClienteGComCfg,'Pesos',1,@DefCtaDinero,@SaldoRedimir,0.0,1,'CERTIFICADO DE REGALO',@SaldoRedimir,11,@UsuarioGCom,@DefCtaDinero,11,11,'SINAFECTAR')
		/*SET @SQLString = 
		N'DECLARE @fecSinHra Date
		Select @fecSinHra = ' + @Base + '.dbo.fnFechaSinHora(GETDATE())'  --GandhiDesarrollo.dbo.fnFechaSinHora(GETDATE())
		+ 'Select @fecSinHra
		INSERT INTO ' + @Base +  '.dbo.CXC (Empresa,Mov,FechaEmision,Concepto,Moneda,TipoCambio,Usuario,Referencia,Observaciones,Cliente,ClienteMoneda,ClienteTipoCambio,CtaDinero,Importe,Impuestos,ConDesglose,FormaCobro1,Importe1,Sucursal,Cajero,DineroCtaDinero,SucursalOrigen,SucursalDestino,Estatus)
		VALUES(''GANDH'',''Anticipo Saldo'',@fecSinHra,@ConceptoI,''Pesos'',1,@UsuarioGComI,@ReferenciaI,@ObservacionesI,@ClienteGComI,''Pesos'',1,@DefCtaDineroI, @SaldoRedimirI,0.0,1,''CERTIFICADO DE REGALO'',@SaldoRedimirI, 11, @UsuarioGComI, @DefCtaDineroI, 11, 11,''SINAFECTAR'')
		SET @IdCXCOut=SCOPE_IDENTITY()'				
		SET @ParmDefinition = N'@ConceptoI Varchar(50),@UsuarioGComI Varchar(10),@ReferenciaI Varchar(50),@ObservacionesI Varchar(100),@ClienteGComI Varchar(10),@DefCtaDineroI Varchar(10),@SaldoRedimirI Money, @IDCXCOut Int output';
		EXECUTE sp_executesql @SQLString, @ParmDefinition,							
							@ConceptoI = @ConceptoCfg,
							@UsuarioGComI = @UsuarioGCom,
							@ReferenciaI = @Referencia,
							@ObservacionesI = @ObservacionesCfg,
							@ClienteGComI = @ClienteGComCfg,
							@DefCtaDineroI = @DefCtaDinero,
							@SaldoRedimirI = @SaldoRedimir,
							@IdCXCOut = @IdCXC output; 
		*/

		--Select  * from CXC Where Id = 1416299
		--Select dbo.fnFechaSinHora(GETDATE())
		--Select * from MovCfgCom
		--Select * from GandhiCfgCom
		--Select DefCtaDinero, * from Usuario Where usuario = 'GCOM'

		/*Test para ver que regresar el 'INSERT' de CXC 
			SET @IdMessage = 10 --Test
				SET @Message = 'Test para obtener resultado de Intelisis al insertar en CX. | @Ok = ' + CONVERT(Varchar(10),COALESCE(@IdCXC,0)) + '| @ConceptoCfg = ' + COALESCE(@ConceptoCfg,'NULL') + '|'
				SET @MessageBitacora = @Message + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
				INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
		*/

		IF(COALESCE(@IdCXC,0) > 0)
		BEGIN
			--Insertar en TarjetaSerieMov y
			--Afectar Mov generado (Anticipo Saldo)
			INSERT INTO TarjetaSerieMov (Empresa, Modulo, ID, Serie, Importe, Sucursal, GandhiAcumular)
			VALUES ('GANDH','CXC',@IdCXC,@CR,@SaldoRedimir,0,0)
			EXEC GandhiDesarrollo.dbo.spAfectar 'CXC', @IdCXC, 'AFECTAR', 'Todo', NULL, 'INTELISIS', @EnSilencio = 1, @Ok = @Ok OUTPUT, @OkRef = @OkRef OUTPUT
			/*SET @SQLString = 
			N'INSERT INTO ' + @Base +  '.dbo.TarjetaSerieMov (Empresa, Modulo, ID, Serie, Importe, Sucursal, GandhiAcumular)
			VALUES(''GANDH'',''CXC'',@IdCXCI,@CRI,@SaldoRedimirI,0,0)			
			EXEC ' + @Base + '.dbo.spAfectar ''CXC'', @IdCXCI, ''AFECTAR'', ''Todo'', NULL, ''INTELISIS'', @EnSilencio = 1, @Ok = @OkOut OUTPUT, @OkRef = @OkRefOut OUTPUT'
			SET @ParmDefinition = N'@IdCXCI Int,@CRI Varchar(20),@SaldoRedimirI Money, @OkOut int output, @OkRefOut varchar(200) output';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,							
								@IdCXCI = @IdCXC,
								@CRI = @CR,							
								@SaldoRedimirI = @SaldoRedimir,
								@OkOut = @Ok output,
								@OkRefOut = @OkRef output;
			*/
			--Select * from TarjetaSerieMov where Id = 1416299 and Modulo= 'CXC'

			/*--Test para ver que regresar el 'Afectar' de Intelisis
			SET @IdMessage = 10 --Test
				SET @Message = 'Test para obtener resultado de Intelisis al Afectar. | @Ok = ' + CONVERT(Varchar(10),COALESCE(@Ok,0)) + '| @OkRef = ' + COALESCE(@OkRef,'NULL') + '|'
				SET @MessageBitacora = @Message + ' Ref. ' + @Referencia 
				INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
			*/

			--SET @OK = 999
			--IF (@OK is null)
			IF (COALESCE(@OK,0) > 0)
			BEGIN
				SET @IdMessage = 1
				SET @Message = 'Redención exitosa.'
				--Registra redención ok						
				
				SELECT @SaldoActual = GandhiDesarrollo.dbo.fnVerSaldoVale (@CR)							
				SET @SaldoActual = -1
				/*SET @SQLString = 
				N'SELECT @SaldoOut = ' + @Base +  '.dbo.fnVerSaldoVale(@SerieCR)'
				SET @ParmDefinition = N'@SerieCR varchar(50), @SaldoOut money output';
				EXECUTE sp_executesql @SQLString, @ParmDefinition,
								@SerieCR = @CR,
								@SaldoOut = @SaldoActual output;			
				*/
				IF (@SaldoActual = -1)
				BEGIN
					SET @MessageBitacora = @Message + ' Saldo actual: -No se pudo obtener el saldo-' + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
					INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
					VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)				

				END
				ELSE
				BEGIN
					SET @Saldo = @SaldoActual
					SET @MessageBitacora = @Message + ' Saldo actual $' + Convert(varchar(10),@SaldoActual) + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
					INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
					VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
				END
			
			END
			ELSE
			BEGIN
				--Registra el mensaje de Intelisis, por lo que no se pudo hacer la disminución
				SET @IdMessage = -4
				SET @Message = 'No se pudo realizar el movimiento. Intelisis dice | @Ok=' + CONVERT(Varchar(10),COALESCE(@Ok,0)) + ' - @OkRef=' + @OkRef + '|'
				SET @MessageBitacora = @Message + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
				INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
			END


		END
		ELSE
		BEGIN
			--Registra el error, no se pudo completar el movimiento
			SET @IdMessage = -4
			SET @Message = 'No se pudo realizar el movimiento. Error al tratar generar Anticipo Saldo. Intente nuevamente.'
			SET @MessageBitacora = @Message + ' Se produjo al intentar insertar en la tabla dbo.CXC. Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
			INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
		END

		/*
		DECLARE 
		@Empresa			VARCHAR(5) = 'GANDH', 
		@Sucursal			int = 11,
		@IdVale				int = 0,	
		@MovRedencion		VarChar(20) = 'Disminucion Ticket',		
		@Observaciones		VarChar(50) = 'Ref. ' + @Referencia, --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido,
		@Usuario            VARCHAR(10) = 'INTELISIS',
		@Ok					Int,
		@OkRef				Varchar(200)

		/*INSERT INTO GandhiDesarrollo.dbo.Vale (
		   Empresa, Mov,  FechaEmision, 
		   Moneda, TipoCambio, Usuario,  Observaciones,
		   Estatus, Sucursal, SucursalOrigen
		)
		VALUES(
			@Empresa, @MovRedencion, GETDATE(), 'Pesos', '1', @Usuario, @Observaciones, 'SINAFECTAR', @Sucursal, @Sucursal
		)
		SET @IdVale=SCOPE_IDENTITY()
		*/		
		SET @SQLString = 
		N'INSERT INTO ' + @Base +  '.dbo.Vale (
		   Empresa, Mov,  FechaEmision, 
		   Moneda, TipoCambio, Usuario,  Observaciones,
		   Estatus, Sucursal, SucursalOrigen
		)
		VALUES(
			@EmpresaCR, @MovRedencionCR, GETDATE(), ''Pesos'', ''1'', @UsuarioCR, @ObservacionesCR, ''SINAFECTAR'', @SucursalCR, @SucursalCR
		)
		SET @IdValeOut=SCOPE_IDENTITY()'				
		SET @ParmDefinition = N'@EmpresaCR varchar(5), @MovRedencionCR varchar(20), @UsuarioCR varchar(10), @ObservacionesCR varchar(50), @SucursalCR int, @IdValeOut int output';
		EXECUTE sp_executesql @SQLString, @ParmDefinition,
							@EmpresaCR = @Empresa,
							@MovRedencionCR = @MovRedencion,
							@UsuarioCR = @Usuario,
							@ObservacionesCR = @Observaciones,
							@SucursalCR = @Sucursal,
							@IdValeOut = @IdVale output;	
		
		IF (@IdVale > 0 )
		BEGIN
			--Registrando el detalle
			/*INSERT INTO GandhiDesarrollo.dbo.ValeD (ID, Serie, Sucursal, SucursalOrigen, Importe)
			VALUES (@IdVale, @CR, @Sucursal, @Sucursal, @SaldoRedimir)		
			EXEC GandhiDesarrollo.dbo.spAfectar 'VALE', @IdVale, 'AFECTAR', 'Todo', NULL, @Usuario, @EnSilencio = 1, @Ok = @Ok OUTPUT, @OkRef = @OkRef OUTPUT
			*/
			SET @SQLString = 
			N'INSERT INTO ' + @Base + '.dbo.ValeD (ID, Serie, Sucursal, SucursalOrigen, Importe)
			VALUES (@IdValeCR, @SerieCR, @SucursalCR, @SucursalCR, @SaldoRedimirCR)		
			EXEC ' + @Base + '.dbo.spAfectar ''VALE'', @IdValeCR, ''AFECTAR'', ''Todo'', NULL, @UsuarioCR, @EnSilencio = 1, @Ok = @OkOut OUTPUT, @OkRef = @OkRefOut OUTPUT'
			SET @ParmDefinition = N'@IdValeCR int, @SerieCR varchar(50), @SucursalCR int, @SaldoRedimirCR money, @UsuarioCR varchar(10),  @OkOut int output, @OkRefOut varchar(200) output';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,
								@IdValeCR = @IdVale,
								@SerieCR = @CR,
								@SucursalCR = @Sucursal,
								@SaldoRedimirCR = @SaldoRedimir,
								@UsuarioCR = @Usuario,
								@OkOut = @Ok output,
								@OkRefOut = @OkRef output;

			IF (@OK is null)
			BEGIN
				SET @IdMessage = 1
				SET @Message = 'Redención exitosa.'
				--Registra redención ok						
				/*
				SELECT @SaldoActual = GandhiDesarrollo.dbo.fnVerSaldoVale (@CR)			
				*/
				SET @SaldoActual = -1
				SET @SQLString = 
				N'SELECT @SaldoOut = ' + @Base +  '.dbo.fnVerSaldoVale(@SerieCR)'
				SET @ParmDefinition = N'@SerieCR varchar(50), @SaldoOut money output';
				EXECUTE sp_executesql @SQLString, @ParmDefinition,
								@SerieCR = @CR,
								@SaldoOut = @SaldoActual output;			

				IF (@SaldoActual = -1)
				BEGIN
					SET @MessageBitacora = @Message + ' Saldo actual: -No se pudo obtener el saldo-' + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
					INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
					VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)				

				END
				ELSE
				BEGIN
					SET @Saldo = @SaldoActual
					SET @MessageBitacora = @Message + ' Saldo actual $' + Convert(varchar(10),@SaldoActual) + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
					INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
					VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
				END
			
			END
			ELSE
			BEGIN
				--Registra el mensaje de Intelisis, por lo que no se pudo hacer la disminución
				SET @IdMessage = -4
				SET @Message = 'No se pudo realizar el movimiento. Intelisis dice |' + @OkRef + '|'
				SET @MessageBitacora = @Message + ' Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
				INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
			END
		
		END
		ELSE
		BEGIN
			--Registra el error, no se pudo completar el movimiento
			SET @IdMessage = -4
			SET @Message = 'No se pudo realizar el movimiento. Error al tratar de obtener IdVale. Intente nuevamente.'
			SET @MessageBitacora = @Message + ' Se produjo al intentar insertar en la tabla ' + @Base + 'dbo.Vale. Ref. ' + @Referencia --Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
			INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
		END
		*/		

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
		INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
		VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)							
			
	END CATCH	

END
