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
    
    public partial class Empresa
    {
        public Empresa()
        {
            this.Instalacaos = new HashSet<Instalacao>();
            this.Ocorrencias = new HashSet<Ocorrencia>();
        }
    
        public int nipc { get; set; }
        public string designacao { get; set; }
        public string morada { get; set; }
    
        public virtual ICollection<Instalacao> Instalacaos { get; set; }
        public virtual ICollection<Ocorrencia> Ocorrencias { get; set; }
    }
}
