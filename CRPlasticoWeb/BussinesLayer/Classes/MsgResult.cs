using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace CRPlasticoWeb.BussinesLayer.Classes
{
	public class MsgResult
	{
		[XmlAttribute]
		public int IdMensaje { get; set; }

		[XmlAttribute]
		public string Mensaje { get; set; }

		[XmlAttribute]
		public Decimal Saldo { get; set; }

	}
}