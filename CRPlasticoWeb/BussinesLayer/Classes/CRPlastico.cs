using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml.Serialization;

namespace CRPlasticoWeb.BussinesLayer.Classes
{
    public class CRPlastico
    {
        [XmlAttribute]
        public int IdError { get; set; }
        
        [XmlAttribute]
        public double Saldo { get; set; }

        [XmlAttribute]
        public string Mensaje { get; set; }
    }
}