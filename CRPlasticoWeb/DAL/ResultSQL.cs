using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web;

namespace CRPlasticoWeb.DAL
{
    public class ResultSQL
    {
        public DataTable TblResult { get; set; }
        public string Error { get; set; }
        public int AffectedRows { get; set; }
        public int result { get; set; }
    }
}