using CRPlasticoWeb.BussinesLayer;
using CRPlasticoWeb.BussinesLayer.Classes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Services;

namespace CRPlasticoWeb
{
    /// <summary>
    /// Summary description for CRPlasticoSrv
    /// </summary>
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.ComponentModel.ToolboxItem(false)]
    // To allow this Web Service to be called from script, using ASP.NET AJAX, uncomment the following line. 
    // [System.Web.Script.Services.ScriptService]
    public class CRPlasticoSrv : System.Web.Services.WebService
    {

        [WebMethod]
        public CRPlastico Activacion(string CodigoBarras, string Acceso)
        {
            return new CRPlasticoBS().CRPlasticoActualiza(CodigoBarras, Acceso);
        }

        [WebMethod]
        public CRPlastico Saldo(string CodigoBarras, string NIP) {
            return new CRPlasticoBS().CRPlasticoSaldo(CodigoBarras,NIP);
        }

		//2018021800(1)
		//Agregar método para redimir puntos de CR plásticos
		[WebMethod]
		public MsgResult Redencion(string IdPedido, string IdCliente, CRPagoGcom[] CRPagoGcomArray)
		{
		
			return new CRPlasticoBS().CRPlasticoRedencion(IdPedido, IdCliente, CRPagoGcomArray);
		}

		/*
		//2018051600(1)
		//Agregar método para obtener CR plásticos con saldo indicado
		[WebMethod]
		public MsgResult CRGcom(SecurityInfo Acceso, int Cantidad, decimal Importe, string Referencia)
		{

			return new CRPlasticoBS().CRPlasticoGcom(Acceso, Cantidad, Importe, Referencia);
		}
		*/
	}
}
