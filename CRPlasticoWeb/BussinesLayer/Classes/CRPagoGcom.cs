using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CRPlasticoWeb.BussinesLayer.Classes
{
	//2018021800(1) Clase para los datos de las tarjetas CR plastico y Monedero electrónico
	public class CRPagoGcom
	{
		private string pstrCodigoBarras;
		private string pstrNIP;
		private decimal pdecSaldoRedimir;

		public CRPagoGcom()
		{
			pstrCodigoBarras = string.Empty;
			pstrNIP = string.Empty;
			pdecSaldoRedimir = 0;
		}

		public string CodigoBarras
		{
			set { pstrCodigoBarras = value; }
			get { return pstrCodigoBarras; }
		}

		public string NIP
		{
			set { pstrNIP = value; }
			get { return pstrNIP; }
		}

		public decimal SaldoRedimir
		{
			set { pdecSaldoRedimir = value; }
			get { return pdecSaldoRedimir; }
		}
	}
}