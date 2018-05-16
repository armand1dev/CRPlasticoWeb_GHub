IF OBJECT_ID('dbo.CRPlasticoRedimeGcomSPI') IS NOT NULL
    DROP PROCEDURE dbo.CRPlasticoRedimeGcomSPI
GO

CREATE Procedure CRPlasticoRedimeGcomSPI
(
   @CR			 Varchar(50),
   @Nip			 Varchar(10),
   @SaldoRedimir Money,
   @IdPedido	 Varchar(50),
   @IdCliente	 Varchar(20),
   @IdMessage	 Int OUTPUT,    
   @Message      VarChar(255) OUTPUT
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
			Vive en la BD de Vales, y se conecta por medio Linked server a Gandhi.
			Nota: Toma el LINKED server de la tabla ValesCfg
			Recibe: 
				CR, Nip, Saldo a redimir 
			Regresa:
				Id del resultado en la variable de salida @IdMessage
					  1. Redención exitosa
					  0. Saldo insuficiente. El Saldo del CR es menor al que se intenta redimir.
					 -1. No se pudo realizar el movimiento. [Estatus del CR]. Favor de verificar.
					 -2. EL CR no esta activo. Verificar CR 
					 -3. Dato incorrecto. [Descripción del dato incorrecto]
					-99. Error del sistema: [Descripción del error]
				Mensaje del resultado obtenido en la variable de salida @Message
						
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

		Select * from ValesCfg	

		Select * from BitacoraRedimeCRGcom		

		sp_helpText CRPlasticoRedimeGcomSPI
		sp_helpText CRPlasticoRedimeGcomSPI
		---------------------------

*/

Begin Try

	DECLARE @MessageBitacora varchar(250)
	DECLARE @Base NVARCHAR(100)	
	DECLARE @SQLString NVARCHAR(500)
	DECLARE @ParmDefinition NVARCHAR(500)
	DECLARE @IdClienteInt INT = -1

	Select @Base = BaseDatos from ValesCfg

	SET @IdMessage = 1
	SET @Message = ''

	If (IsNULL(@IdPedido, '') = '') 
	BEGIN
		SET @IdMessage = -3
		SET @Message = 'Favor de Ingresar IdPedido.'
	END

	If (IsNULL(@IdCliente, '') = '') And (@IdMessage > 0)
	BEGIN
		SET @IdMessage = -3
		SET @Message = 'Favor de Ingresar IdCliente.'
	END	

	If (IsNumeric(@IdCliente) = 0) And (@IdMessage > 0)
	BEGIN
		SET @IdMessage = -3
		SET @Message = 'IdCliente debe ser numérico.'
	END
	ELSE
	BEGIN
		SET @IdClienteInt = Cast(@IdCliente as INT)
	END

	If (IsNULL(@Nip, '') = '') And (@IdMessage > 0)
	BEGIN
		SET @IdMessage = -3
		SET @Message = 'Favor de Ingresar Nip.'
	END
		
	If (IsNumeric(@Nip) = 0) And (@IdMessage > 0)
	BEGIN
		SET @IdMessage = -3
		SET @Message = 'El Nip debe ser un valor numérico.'
	END
		
	IF (Len(@CR) <> 13) And (@IdMessage > 0)
	BEGIN
		IF Len(@CR) = 0
		BEGIN
			SET @IdMessage = -3
			SET @Message = 'Favor de ingresar el código de barras del CR.'
		END
		ELSE
		BEGIN
			SET @IdMessage = -3
			SET @Message = 'El código de barras del CR debe ser de 13 caracteres.'
		END 
	END

	If (IsNumeric(@SaldoRedimir) = 0) And (@IdMessage > 0)
	BEGIN
		SET @IdMessage = -3
		SET @Message = 'Saldo a redimir es cero. Favor de verificar.'
	END

	IF (@IdMessage > 0)
	BEGIN	
		
		--Busca el Nip (Ref. CRPlasticoSaldoSPS en Vales)
		DECLARE @strNIP Varchar(10), @Saldo money, @Id INT, @tnyStatus tinyint
		SELECT @strNIP = ISNULL(c.NIP,''), @Saldo = ISNull(v.Importe, 0), @Id = ISNULL(c.Id,0), @tnyStatus = v.Status
		from CRPlastico c
			Left join Vales v on c.Id = v.Id
		where c.CodigoBarras = @CR 

		--Debe tomar el saldo que hay en intelisis	
		--SELECT @Saldo = GandhiDesarrollo.dbo.fnVerSaldoVale (@CR)				
		SET @SQLString = 
		N'SELECT @SaldoOut = ' + @Base + '.dbo.fnVerSaldoVale (@SerieCR) '
		SET @ParmDefinition = N'@SerieCR Varchar(50), @SaldoOut money output';
		EXECUTE sp_executesql @SQLString, @ParmDefinition,
							@SerieCR = @CR,
							@SaldoOut = @Saldo output;
		
		If (IsNULL(@strNIP, '') = '')
		BEGIN
				SET @IdMessage = -1
				SET @Message = 'Código de barras del CR no es válido.'
		END

		If (IsNULL(@Id, '') = '') And (@IdMessage > 0)
		BEGIN
				SET @IdMessage = -1
				SET @Message = 'Certificado sin registro de venta.'
		END

		If (@strNIP <> @Nip) And (@IdMessage > 0)
		BEGIN
				SET @IdMessage = -3
				SET @Message = 'El NIP es incorrecto.'
		END

		If (@tnyStatus = 2) And (@IdMessage > 0)
		BEGIN
				SET @IdMessage = -1
				SET @Message = 'El certificado está cancelado.'
				RETURN
		END

		If (@tnyStatus = 3) And (@IdMessage > 0)
		BEGIN
				SET @IdMessage = -1
				SET @Message = 'El certificado esta inactivo.'
		END

		If (@Saldo = 0 and @tnyStatus = 0) 
		BEGIN
				SET @IdMessage = -1
				SET @Message = 'El certificado ya fue utilizado totalmente.'
		END

		IF (@Saldo < @SaldoRedimir) And (@IdMessage > 0)
		BEGIN
				SET @IdMessage = 0
				SET @Message = 'Saldo insuficiente (' + convert(varchar(10),@Saldo) + '). El Saldo del CR es menor al que se intenta redimir (' + convert(varchar(10),@SaldoRedimir) + ').'
		END

		IF (@IdMessage = -1) 
		BEGIN
			SET @Message = 'No se pudo realizar el movimiento. ' + @Message + ' Favor de verificar.'
		END	

	END
		
	--Registra en la bitacora sino se pudo hacer la redencion del CR
	IF @IdMessage <= 0
	BEGIN
		SET @MessageBitacora = @Message + ' Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
		INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
		VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
		RETURN
	END
	ELSE
	BEGIN
		
		--REDIMIR SALDO
		DECLARE 
		@Empresa			VARCHAR(5) = 'GANDH', 
		@Sucursal			int = 11,
		@IdVale				int = 0,	
		@MovRedencion		VarChar(20) = 'Disminucion Ticket',		
		@Observaciones		VarChar(50) = 'Redención GCom Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido,
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
		END
		ELSE
		BEGIN
			--Registra el error, no se pudo completar el movimiento
			SET @IdMessage = -1
			SET @Message = 'No se pudo realizar el movimiento. Intelisis no regresó IdVale al intentar insertar en la tabla Vale'
			SET @MessageBitacora = @Message + ' Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
			INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
		END

		

		If (@OK is null)
		BEGIN
			SET @IdMessage = 1
			SET @Message = 'Redención exitosa.'
			--Registra redención ok						
			/*
			SELECT @Saldo = GandhiDesarrollo.dbo.fnVerSaldoVale (@CR)			
			*/
			SET @Saldo = -1
			SET @SQLString = 
			N'SELECT @SaldoOut = ' + @Base +  '.dbo.fnVerSaldoVale(@SerieCR)'
			SET @ParmDefinition = N'@SerieCR varchar(50), @SaldoOut money output';
			EXECUTE sp_executesql @SQLString, @ParmDefinition,
							@SerieCR = @CR,
							@SaldoOut = @Saldo output;

			IF (@Saldo = -1)
			BEGIN
				SET @MessageBitacora = @Message + ' Saldo actual: -No se pudo obtener el saldo-' + ' Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
				INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)				
			END
			ELSE
			BEGIN
				SET @MessageBitacora = @Message + ' Saldo actual $' + Convert(varchar(10),@Saldo) + ' Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
				INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
				VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
			END
			
		END
		ELSE
		BEGIN
			--Registra el mensaje de Intelisis, por lo que no se pudo hacer la disminución
			SET @IdMessage = -1
			SET @Message = 'No se pudo realizar el movimiento. Intelisis dice |' + @OkRef + '|'
			SET @MessageBitacora = @Message + ' Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido	
			INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
			VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)
		END
	END

	End Try
	Begin Catch								
		--Return -99
		DECLARE @Error INT
		DECLARE @MESSAGE_Catch NVARCHAR(500)
		SET @Error = ERROR_NUMBER()  
		SET @MESSAGE_Catch = 'Error Number: ' + CONVERT(VARCHAR(10),@Error) + ' Description: ' + ERROR_MESSAGE()  	
		SET @IdMessage = -99 --Error
		SET @Message = 'Error del sistema. ' + @MESSAGE_Catch
		SET @MessageBitacora = @Message + ' Ref. ' + Convert(varchar(20),@IdClienteInt) + '-' + @IdPedido
		INSERT INTO BitacoraRedimeCRGcom (IdPedido,IdCliente,CodigoBarras,Nip,SaldoRedimir,IdMessage,[Message])
		VALUES (@IdPedido,@IdClienteInt,@CR,@Nip,@SaldoRedimir,@IdMessage,@MessageBitacora)							
			
	End Catch	

END
