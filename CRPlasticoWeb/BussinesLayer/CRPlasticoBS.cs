using CRPlasticoWeb.BussinesLayer.Classes;
using CRPlasticoWeb.DAL;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Reflection;
using System.Configuration;
using System.Linq;
using System.Web;

namespace CRPlasticoWeb.BussinesLayer
{
	public class CRPlasticoBS
	{
		public CRPlastico CRPlasticoSaldo(string codigoBarras, string nip)
		{
			ResultSQL objResult = new ResultSQL();
			List<SqlParameter> lstParameters = new List<SqlParameter>();

			CRPlastico crInfo = new CRPlastico();

			//Parametros de entrada
			lstParameters.Add(new SqlParameter("@CR", codigoBarras));
			lstParameters.Add(new SqlParameter("@NIP", nip));

			//Parametros de salida
			SqlParameter idErrorP = new SqlParameter("@IdError", SqlDbType.Int)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(idErrorP);

			SqlParameter saldoP = new SqlParameter("@Saldo", SqlDbType.Money)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(saldoP);

			SqlParameter mensajeP = new SqlParameter("@Mensaje", SqlDbType.VarChar, 100)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(mensajeP);

			//Obtener la cadena de conexion para la BD Vales (ConnString)
			string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString"].ConnectionString;

			objResult = ExecuteSQL.execSP("CRPlasticoSaldoSPS", lstParameters, Connectionstring);//, false);

			crInfo.IdError = Convert.ToInt32(idErrorP.Value.ToString());
			crInfo.Saldo = Convert.ToDouble(saldoP.Value.ToString());
			crInfo.Mensaje = mensajeP.Value.ToString();

			return crInfo;

		}

		public CRPlastico CRPlasticoActualiza(string codigoBarras, string acceso)
		{
			ResultSQL objResult = new ResultSQL();
			List<SqlParameter> lstParameters = new List<SqlParameter>();

			CRPlastico crInfo = new CRPlastico();

			//Parametros de entrada
			lstParameters.Add(new SqlParameter("@CR", codigoBarras));
			lstParameters.Add(new SqlParameter("@Acceso", acceso));

			//Parametros de salida
			SqlParameter idErrorP = new SqlParameter("@IdError", SqlDbType.Int)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(idErrorP);

			SqlParameter saldoP = new SqlParameter("@Saldo", SqlDbType.Money)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(saldoP);

			SqlParameter mensajeP = new SqlParameter("@Mensaje", SqlDbType.VarChar, 100)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(mensajeP);

			//Obtener la cadena de conexion para la BD Vales (ConnString)
			string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString"].ConnectionString;

			objResult = ExecuteSQL.execSP("CRPlasticoActualizaSPU", lstParameters, Connectionstring);//, false);

			crInfo.IdError = Convert.ToInt32(idErrorP.Value.ToString());
			crInfo.Saldo = Convert.ToDouble(saldoP.Value.ToString());
			crInfo.Mensaje = mensajeP.Value.ToString();

			return crInfo;

		}

		//2018021800(1)
		public MsgResult CRPlasticoRedencion(string idPedido, string idCliente, CRPagoGcom[] CRPagoGcomArray)//string codigoBarras, string nip, decimal saldoRedimir)
		{
			//Pasar datos del objeto OrderDetailInfo a un DataTable
			DataTable dtCRPagoGcom = new DataTable();
			dtCRPagoGcom = GetDataTableFromObjects(CRPagoGcomArray);

			string strTipoTarjeta = string.Empty;

			MsgResult msgInfo = ValidaCRPagoGcom(dtCRPagoGcom, idPedido, idCliente, ref strTipoTarjeta);
			
			if (msgInfo.IdMensaje == 1)
			{				
				//msgInfo.Mensaje += "-Ok-";
				msgInfo = RedimeCRPagoGcom(dtCRPagoGcom, idPedido, idCliente, strTipoTarjeta);								
			}

			return msgInfo;
		}

		//2018021800(1)
		private MsgResult ValidaCRPagoGcom(DataTable dtCRPagoGcom, string idPedido, string idCliente, ref string strTipoTarjeta)
		{
			ResultSQL objResult = new ResultSQL();
			List<SqlParameter> lstParameters = new List<SqlParameter>();

			MsgResult msgInfo = new MsgResult();

			//Parametros de entrada
			lstParameters.Add(new SqlParameter("@CRPagoGcom", dtCRPagoGcom));
			lstParameters.Add(new SqlParameter("@IdPedido", idPedido));
			lstParameters.Add(new SqlParameter("@IdCliente", idCliente));
			/*lstParameters.Add(new SqlParameter("@CR", codigoBarras));
			lstParameters.Add(new SqlParameter("@Nip", nip));
			lstParameters.Add(new SqlParameter("@SaldoRedimir", saldoRedimir));*/

			//Parametros de salida
			SqlParameter idMessageP = new SqlParameter("@IdMessage", SqlDbType.Int)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(idMessageP);
			SqlParameter messageP = new SqlParameter("@Message", SqlDbType.VarChar, 255)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(messageP);
			SqlParameter saldoP = new SqlParameter("@Saldo", SqlDbType.Decimal)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(saldoP);
			SqlParameter tipoTarjetaP = new SqlParameter("@TipoTarjeta", SqlDbType.VarChar, 50)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(tipoTarjetaP);

			//Obtener la cadena de conexion para la BD Vales (ConnString)
			string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString"].ConnectionString;

			//Se ejecuta en la BD de Vales
			objResult = ExecuteSQL.execSP("CRPlasticoValidaGcomSPS", lstParameters, Connectionstring);
			//objResult = ExecuteSQL.execSPVales("CRPlasticoValidaGcomSPS", lstParameters);
			//objResult = ExecuteSQL.execSP("CRPlasticoRedimeGcomSPI", lstParameters, false);

			msgInfo.IdMensaje = Convert.ToInt32(idMessageP.Value.ToString());
			msgInfo.Mensaje = messageP.Value.ToString();
			msgInfo.Saldo = Convert.ToDecimal(saldoP.Value.ToString());
			strTipoTarjeta = tipoTarjetaP.Value.ToString();

			return msgInfo;
		}

		//2018021800(1)
		private MsgResult RedimeCRPagoGcom(DataTable dtCRPagoGcom, string idPedido, string idCliente, string tipoTarjeta)
		{
			ResultSQL objResult = new ResultSQL();
			List<SqlParameter> lstParameters = new List<SqlParameter>();

			MsgResult msgInfo = new MsgResult();

			//Parametros de entrada
			lstParameters.Add(new SqlParameter("@CRPagoGcom", dtCRPagoGcom));
			lstParameters.Add(new SqlParameter("@IdPedido", idPedido));
			lstParameters.Add(new SqlParameter("@IdCliente", idCliente));
			lstParameters.Add(new SqlParameter("@TipoTarjeta", tipoTarjeta));

			//Parametros de salida
			SqlParameter idMessageP = new SqlParameter("@IdMessage", SqlDbType.Int)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(idMessageP);
			SqlParameter messageP = new SqlParameter("@Message", SqlDbType.VarChar, 255)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(messageP);
			SqlParameter saldoP = new SqlParameter("@Saldo", SqlDbType.Decimal)
			{
				Direction = ParameterDirection.Output
			};
			lstParameters.Add(saldoP);

			//Obtener la cadena de conexion para la BD Gandhi (ConnString2)
			string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString2"].ConnectionString;

			//Se ejecuta en la BD Gandhi
			objResult = ExecuteSQL.execSP("CRPlasticoRedimeGcomSPI", lstParameters, Connectionstring);		

			msgInfo.IdMensaje = Convert.ToInt32(idMessageP.Value.ToString());
			msgInfo.Mensaje = messageP.Value.ToString();
			msgInfo.Saldo = Convert.ToDecimal(saldoP.Value.ToString());

			return msgInfo;
		}

		//2018021800(1) Método para convertir un objeto en DataTable
		public static DataTable GetDataTableFromObjects(object[] objects)
		{
			try
			{
				if (objects != null && objects.Length > 0)
				{
					Type t = objects[0].GetType();
					DataTable dt = new DataTable(t.Name);
					foreach (PropertyInfo pi in t.GetProperties())
					{
						dt.Columns.Add(new DataColumn(pi.Name));
					}
					foreach (var o in objects)
					{
						DataRow dr = dt.NewRow();
						foreach (DataColumn dc in dt.Columns)
						{
							dr[dc.ColumnName] = o.GetType().GetProperty(dc.ColumnName).GetValue(o, null);
						}
						dt.Rows.Add(dr);
					}
					return dt;
				}
				return null;
			}
			catch (Exception ex)
			{
				throw ex;
			}
		}
	}
}