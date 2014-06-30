using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace exercicio3
{
    // Entity Container Name: SI2_1314v_TPEntities

    class Program
    {
        enum TipoOcorrencia{ urgente, crítico, trivial };

        enum EstadoOcorrencia { inicial, em_processamento, em_resolução, recusado, cancelado, concluído };

        static void Main(string[] args)
        {
           //Testar alinea a)
     //       a(600016234, "Instituto Superior de Engenharia de Lisboa", "Rua Conselheiro Emídio Navarro 1_, 1959-007 Lisboa");

            //Testar alinea b)
     //       b(DateTime.Today , DateTime.Today, TipoOcorrencia.trivial, 1, 1, "A", 501510184);

            //Testar alinea c)
     //       c(21);


            //Testar alinea d)    
            
     //       b(new DateTime(2014,03,25,10,20,30,00) , DateTime.Today, TipoOcorrencia.crítico, 1, 1, "A", 501510184);
     //       b(DateTime.Now, DateTime.Now, TipoOcorrencia.crítico, 1, 1, "A", 501510184);  
            d();
        }


        /************************************************
        * ALINEA 3.a  - Actualizar os dados de uma empresa
        ************************************************/
        /**
         * Por simplificação, admitimos que a empresa com o nipc indicado existe.
         **/
        static void a(int nipc, string designacao, string morada)
        {
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities()) {

                var emp = (from e in ctx.Empresas
                           where e.nipc == nipc
                           select e).FirstOrDefault();

                emp.designacao = designacao;
                emp.morada = morada;
                ctx.SaveChanges();
            }
        }


        /************************************************
         * ALINEA 3.b  - Registar uma ocorrência
         ************************************************/
        /**
         * É necessário verificar se a empresa existe. 
         * Por simplificação, admitimos que o Sector indicado existe.
         **/
        static void b(System.DateTime dhEntrada, System.DateTime dhAlteracao, TipoOcorrencia tipo, int codInst, int piso, string zona, int empresa) 
        {
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities()){

                if(ctx.Empresas.Find(empresa) != null){
                    var occurr = new Ocorrencia{
                            dhEntrada = dhEntrada, 
                            dhAlteracao = dhAlteracao, 
                            tipo = tipo.ToString(), 
                            estado = EstadoOcorrencia.inicial.ToString(),
                            codInst = codInst,
                            piso = piso,
                            zona = zona,
                            empresa = empresa};

                    ctx.Ocorrencias.Add(occurr);
                    ctx.SaveChanges();
                }
                else
                    Console.WriteLine("A empresa com o nipc {0} não existe no sistema", empresa);
            }    
        }


        /************************************************
         * ALINEA 3.c - Aceitação de uma ocorrência (i.e. atribuição do estado em processamento)
         ************************************************/
        /**
         * É necessário verificar se a Ocorrência existe, e se o seu estado atual é "inicial". Apenas neste estado será
         * possível atribuir o estado "em processamento".
         **/
        static void c(int idOccurr) 
        {
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities()) {

                try
                {
                    var occurr = ctx.Ocorrencias.First(o => o.id == idOccurr);
                    if (occurr.estado == EstadoOcorrencia.inicial.ToString())
                    {
                        occurr.estado = "em processamento";
                    //  occurr.estado = EstadoOcorrencia.em_processamento.ToString();
                        ctx.SaveChanges();
                    }
                    else { 
                        Console.WriteLine("A Ocorrencia com o id {0} já se encontra no estado {1}.", idOccurr,occurr.estado);
                        Console.ReadKey();
                    }

                }
                catch (InvalidOperationException e)
                {
                    Console.WriteLine("A Ocorrencia com o id {0} não existe.", idOccurr);
                    Console.ReadKey();
                }
            
            }
 
        }


        /************************************************
          * ALINEA 3.d - Determinar quais as ocorrências que se encontram em situação de incumprimento 
         * e quais os centros de intervenção responsáveis pelo incumprimento
          ************************************************/
        /**
         * Percorrer todas as ocorrencias e verificar, entre as que não estejam cancelas concluídas ou recusadas,
         * o número de horas decorridas após a entrada. 
         **/
        static void d() 
        {
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities()) {

                foreach (var o in ctx.Ocorrencias) {
                    if (o.tipo.Equals(TipoOcorrencia.crítico.ToString())
                        &&
                          (
                            (!o.estado.Equals(EstadoOcorrencia.cancelado.ToString())) &&
                            (!o.estado.Equals(EstadoOcorrencia.concluído.ToString())) &&
                            (!o.estado.Equals(EstadoOcorrencia.recusado.ToString()))
                          )
                        &&
                          ( o.dhEntrada.AddHours(12) < DateTime.Now)
                      )
                    {
                        Console.WriteLine("A Ocorrencia de tipo crítico {0} encontra-se em incumprimento", o.id);
                        Console.WriteLine("Centro de intervenção responsável: {0}", ctx.Empresas.First(e => e.nipc == o.empresa).designacao);
                    }else
                        if (o.tipo.Equals(TipoOcorrencia.urgente.ToString())
                        &&
                          (
                            (!o.estado.Equals(EstadoOcorrencia.cancelado.ToString())) &&
                            (!o.estado.Equals(EstadoOcorrencia.concluído.ToString())) &&
                            (!o.estado.Equals(EstadoOcorrencia.recusado.ToString()))
                          )
                        &&
                          (o.dhEntrada.AddHours(48) < DateTime.Now)
                      )
                        {
                            Console.WriteLine("A Ocorrencia de tipo urgente {0} encontra-se em incumprimento", o.id);
                            Console.WriteLine("Centro de intervenção responsável: {0}", ctx.Empresas.First(e => e.nipc == o.empresa).designacao);
                        }
                
                }
                Console.ReadKey();
            
            }
 
        }
    }
}
