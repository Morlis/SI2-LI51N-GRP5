//------------------------------------------------------------------------------
// <auto-generated>
//    This code was generated from a template.
//
//    Manual changes to this file may cause unexpected behavior in your application.
//    Manual changes to this file will be overwritten if the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

namespace exercicio3
{
    using System;
    using System.Collections.Generic;
    
    public partial class Instalacao
    {
        public Instalacao()
        {
            this.Sectors = new HashSet<Sector>();
        }
    
        public int cod { get; set; }
        public string descricao { get; set; }
        public int empresa { get; set; }
        public int localizacao { get; set; }
    
        public virtual Empresa Empresa1 { get; set; }
        public virtual Localizacao Localizacao1 { get; set; }
        public virtual ICollection<Sector> Sectors { get; set; }
    }
}
