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
    
    public partial class Localizacao
    {
        public Localizacao()
        {
            this.Instalacaos = new HashSet<Instalacao>();
        }
    
        public int id { get; set; }
        public string morada { get; set; }
        public string coordenadas { get; set; }
    
        public virtual ICollection<Instalacao> Instalacaos { get; set; }
    }
}