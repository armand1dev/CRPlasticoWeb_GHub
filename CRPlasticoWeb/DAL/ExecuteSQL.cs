using System;
using System.Collections.Generic;
//using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace CRPlasticoWeb.DAL
{
    public class ExecuteSQL
	{
		//2018021800(1) se modifica para que tome la conexión desde el parámetro Connectionstring, ya que ahora hay SPs de la BD de Vales y de Gandhi
		//Se ejecuta en la BD Vales para Saldo (CRPlasticoSaldo) y Activación (CRPlasticoActualiza)
		public static ResultSQL execSP(string strCommand, List<SqlParameter> lstParameter, string Connectionstring)//, bool outputParams)
        {

            ResultSQL objResult = new ResultSQL();
            objResult.Error = string.Empty;
            //string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString"].ConnectionString;
            SqlConnection con = new SqlConnection(Connectionstring);
		
            try
            {


                using (SqlCommand command = new SqlCommand(strCommand, con)
                {
                    CommandType = CommandType.StoredProcedure
                })
                {
                    //Se asignan los parametros pasados a la lista
                    foreach (SqlParameter p in lstParameter)
                    {
                        command.Parameters.Add(p);
                    }

                    /*//Si se indicó que tendrá parámetros de salida estos se crean y se agregan a la lista
                    if (outputParams)
                    {
                        command.Parameters.Add(new SqlParameter("@AFFECTEDROWS", 0));
                        command.Parameters.Add(new SqlParameter("@ERROR", SqlDbType.VarChar, 5000));
                        command.Parameters.Add(new SqlParameter("@RESULT", SqlDbType.Int));
                    }*/

                    con.Open();

                    /*//Se inidica que los nuevos parametros serán de salida
                    if (outputParams)
                    {
                        command.Parameters["@AFFECTEDROWS"].Direction = ParameterDirection.Output;
                        command.Parameters["@ERROR"].Direction = ParameterDirection.Output;
                        command.Parameters["@RESULT"].Direction = ParameterDirection.Output;
                    }*/

					SqlDataAdapter da = new SqlDataAdapter(command);
                    objResult.TblResult = new DataTable();
                    da.Fill(objResult.TblResult);

                    /*//Se asigna los valores devueltos a los parámetros
                    if (outputParams)
                    {
                        objResult.Error = command.Parameters["@ERROR"].Value.ToString();
                        objResult.result = Convert.ToInt32(command.Parameters["@RESULT"].Value);
                        objResult.AffectedRows = Convert.ToInt32(command.Parameters["@AFFECTEDROWS"].Value);
                    }*/

					con.Close();
                    da.Dispose();
                    command.Dispose();
                }
            }
            catch (Exception ex)
            {
                con.Close();
                objResult.Error = string.Format(ex.Message);
                throw;
            }
            finally
            {
                con.Close();
            }

            return objResult;
        }

		/*
		//Se ejecuta en la BD Vales, para validación de tajetas (ValidaCRPagoGcom)		
		public static ResultSQL execSPVales(string strCommand, List<SqlParameter> lstParameter)
		{

			ResultSQL objResult = new ResultSQL();
			objResult.Error = string.Empty;
			string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString"].ConnectionString;
			SqlConnection con = new SqlConnection(Connectionstring);
			
			try
			{
				using (SqlCommand command = new SqlCommand(strCommand, con)
				{
					CommandType = CommandType.StoredProcedure
				})
				{				
					//Se asignan los parametros pasados a la lista
					foreach (SqlParameter p in lstParameter)
					{
						command.Parameters.Add(p);
					}										
					con.Open();
					SqlDataAdapter da = new SqlDataAdapter(command);
					objResult.TblResult = new DataTable();
					da.Fill(objResult.TblResult);					
					con.Close();
					da.Dispose();
					command.Dispose();
				}
			}
			catch (Exception ex)
			{
				con.Close();
				objResult.Error = string.Format(ex.Message);
				throw;
			}
			finally
			{
				con.Close();
			}

			return objResult;
		}

		//Se ejecuta en la BD Gandhi, para redimir saldo de tarjetas (RedimeCRPagoGcom)
		public static ResultSQL execSPGandhi(string strCommand, List<SqlParameter> lstParameter)
		{

			ResultSQL objResult = new ResultSQL();
			objResult.Error = string.Empty;
			string Connectionstring = ConfigurationManager.ConnectionStrings["ConnString2"].ConnectionString;
			SqlConnection con = new SqlConnection(Connectionstring);

			try
			{

				using (SqlCommand command = new SqlCommand(strCommand, con)
				{
					CommandType = CommandType.StoredProcedure
				})
				{
					//Se asignan los parametros pasados a la lista
					foreach (SqlParameter p in lstParameter)
					{
						command.Parameters.Add(p);
					}
					
					con.Open();
					
					SqlDataAdapter da = new SqlDataAdapter(command);
					objResult.TblResult = new DataTable();
					da.Fill(objResult.TblResult);
					
					con.Close();
					da.Dispose();
					command.Dispose();
				}
			}
			catch (Exception ex)
			{
				con.Close();
				objResult.Error = string.Format(ex.Message);
				throw;
			}
			finally
			{
				con.Close();
			}

			return objResult;
		}*/
	}
}