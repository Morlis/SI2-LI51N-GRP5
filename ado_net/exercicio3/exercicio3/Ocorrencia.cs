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
    
    public partial class Ocorrencia
    {
        public Ocorrencia()
        {
            this.Trabalhoes = new HashSet<Trabalho>();
        }
    
        public int id { get; set; }
        public System.DateTime dhEntrada { get; set; }
        public System.DateTime dhAlteracao { get; set; }
        public string tipo { get; set; }
        public string estado { get; set; }
        public int codInst { get; set; }
        public int piso { get; set; }
        public string zona { get; set; }
        public int empresa { get; set; }
    
        public virtual Empresa Empresa1 { get; set; }
        public virtual Sector Sector { get; set; }
        public virtual ICollection<Trabalho> Trabalhoes { get; set; }
    }
}
