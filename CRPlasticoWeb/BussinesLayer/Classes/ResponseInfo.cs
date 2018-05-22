using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace CRPlasticoWeb.BussinesLayer.Classes
{
	public class ResponseInfo
	{

		private int pintId;
		private string pstrMessage;
		private string pstrNotaGCom;
		private string pstrVentaPerdida;
		//private NotaGComDetailInfo[] pobjNotaGcomD;

		public ResponseInfo()
		{
			pintId = 0;
			pstrMessage = string.Empty;
			//Arreglo de CRs
		}

		public int Id
		{
			set { pintId = value; }
			get { return pintId; }
		}

		public string Mensaje
		{
			set { pstrMessage = value; }
			get { return pstrMessage; }
		}

		public string NotaGcom
		{
			set { pstrNotaGCom = value; }
			get { return pstrNotaGCom; }
		}

		public string VentaPerdida
		{
			set { pstrVentaPerdida = value; }
			get { return pstrVentaPerdida; }
		}

		/*
		public NotaGComDetailInfo[] NotaGcomD
		{
			set { pobjNotaGcomD = value; }
			get { return pobjNotaGcomD; }
		}
		*/

	}
}