﻿//------------------------------------------------------------------------------
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
    using System.Data.Entity;
    using System.Data.Entity.Infrastructure;
    
    public partial class SI2_1314v_TPEntities : DbContext
    {
        public SI2_1314v_TPEntities()
            : base("name=SI2_1314v_TPEntities")
        {
        }
    
        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            throw new UnintentionalCodeFirstException();
        }
    
        public DbSet<Afecto> Afectoes { get; set; }
        public DbSet<AreaIntervencao> AreaIntervencaos { get; set; }
        public DbSet<Empresa> Empresas { get; set; }
        public DbSet<Funcionario> Funcionarios { get; set; }
        public DbSet<Instalacao> Instalacaos { get; set; }
        public DbSet<Localizacao> Localizacaos { get; set; }
        public DbSet<Ocorrencia> Ocorrencias { get; set; }
        public DbSet<Sector> Sectors { get; set; }
        public DbSet<Trabalho> Trabalhoes { get; set; }
    }
}
