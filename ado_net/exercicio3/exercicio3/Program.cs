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
        enum TipoOcorrencia { urgente, crítico, trivial };

        enum EstadoOcorrencia { inicial, em_processamento, em_resolução, recusado, cancelado, concluído };

        public static void WriteMenu()
        {
            Console.WriteLine("Escolha uma operação:");
            Console.WriteLine("a - Actualizar os dados de uma empresa");
            Console.WriteLine("b - Registar uma ocorrência");
            Console.WriteLine("c - Aceitação de uma ocorrência");
            Console.WriteLine("d - Determinar ocorrências em incumprimento");
            Console.WriteLine("e - Listar ocorrências concluídas");
            Console.WriteLine("f - Iniciar resolução de ocorrência");
            Console.WriteLine("g - Finalizar pretação de serviço");
            Console.WriteLine("h - Consultar informação de uma ocorrência");
            Console.WriteLine("i - Carregar ocorrências por XML");
            Console.WriteLine("0 - Exit application");
        }

        static void Main(string[] args)
        {
            var operation = -1;
            while (!operation.Equals(0))
            {
                switch (operation)
                {
                    case 'a':
                        //Testar alinea a)
                        a(600016234, "Instituto Superior de Engenharia de Lisboa", "Rua Conselheiro Emídio Navarro 1_, 1959-007 Lisboa");
                        operation = -1;
                        break;
                    case 'b':
                        //Testar alinea b)
                        b(DateTime.Today, DateTime.Today, TipoOcorrencia.trivial, 1, 1, "A", 501510184);
                        operation = -1;
                        break;
                    case 'c':
                        //Testar alinea c)
                        c(21);
                        operation = -1;
                        break;
                    case 'd':
                        //Testar alinea d)    

                        //       b(new DateTime(2014,03,25,10,20,30,00) , DateTime.Today, TipoOcorrencia.crítico, 1, 1, "A", 501510184);
                        //       b(DateTime.Now, DateTime.Now, TipoOcorrencia.crítico, 1, 1, "A", 501510184);  
                        //       d();
                        operation = -1;
                        break;
                    case 'e':
                        e();
                        operation = -1;
                        break;
                    case 'f':
                        f();
                        operation = -1;
                        break;
                    case 'g':
                        g();
                        operation = -1;
                        break;
                    case 'h':
                        h();
                        operation = -1;
                        break;
                    case 'i':
                        i();
                        operation = -1;
                        break;
                    case '0':
                        return;
                    default:
                        WriteMenu();
                        operation = Convert.ToChar(Console.ReadLine());
                        break;
                }
            }

        }


        /************************************************
        * ALINEA 3.a  - Actualizar os dados de uma empresa
        ************************************************/
        /**
         * Por simplificação, admitimos que a empresa com o nipc indicado existe.
         **/
        static void a(int nipc, string designacao, string morada)
        {
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities())
            {

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
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities())
            {

                if (ctx.Empresas.Find(empresa) != null)
                {
                    var occurr = new Ocorrencia
                    {
                        dhEntrada = dhEntrada,
                        dhAlteracao = dhAlteracao,
                        tipo = tipo.ToString(),
                        estado = EstadoOcorrencia.inicial.ToString(),
                        codInst = codInst,
                        piso = piso,
                        zona = zona,
                        empresa = empresa
                    };

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
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities())
            {

                try
                {
                    var occurr = ctx.Ocorrencias.First(o => o.id == idOccurr);
                    if (occurr.estado == EstadoOcorrencia.inicial.ToString())
                    {
                        occurr.estado = "em processamento";
                        //  occurr.estado = EstadoOcorrencia.em_processamento.ToString();
                        ctx.SaveChanges();
                    }
                    else
                    {
                        Console.WriteLine("A Ocorrencia com o id {0} já se encontra no estado {1}.", idOccurr, occurr.estado);
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
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities())
            {

                foreach (var o in ctx.Ocorrencias)
                {
                    if (o.tipo.Equals(TipoOcorrencia.crítico.ToString())
                        &&
                          (
                            (!o.estado.Equals(EstadoOcorrencia.cancelado.ToString())) &&
                            (!o.estado.Equals(EstadoOcorrencia.concluído.ToString())) &&
                            (!o.estado.Equals(EstadoOcorrencia.recusado.ToString()))
                          )
                        &&
                          (o.dhEntrada.AddHours(12) < DateTime.Now)
                      )
                    {
                        Console.WriteLine("A Ocorrencia de tipo crítico {0} encontra-se em incumprimento", o.id);
                        Console.WriteLine("Centro de intervenção responsável: {0}", ctx.Empresas.First(e => e.nipc == o.empresa).designacao);
                    }
                    else
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

        static void e()
        {
           
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities())
            {
                Console.WriteLine("Data de início (yyyy-mm-dd hh:m:ss.mmm)? ");
                var beginDate = Convert.ToDateTime(Console.ReadLine());
                Console.WriteLine("Data de fim (yyyy-mm-dd hh:m:ss.mmm)? ");
                var endDate = Convert.ToDateTime(Console.ReadLine());
                var ocorrencias = ctx.Ocorrencias.Where(o => o.estado.Equals(EstadoOcorrencia.concluído.ToString()) &&
                    o.dhAlteracao.CompareTo(beginDate) >= 0
                                 &&
                    o.dhAlteracao.CompareTo(endDate) <= 0)
                                 .ToList();

                if (ocorrencias.Count == 0)
                {
                    Console.WriteLine("Não foram encontrados registos");
                    Console.WriteLine("Prima uma tecla para continuar");
                    Console.ReadKey();
                    return;
                }

                Console.WriteLine("Ocorrências concluídas no período de {0} a {1}:", beginDate, endDate);
                var i = 1;
                foreach (var o in ocorrencias)
                {
                    Console.WriteLine("{0} {1} {2} {3} {4} {5} {6} {7} {8}", i,
                        o.id, o.dhEntrada, o.dhAlteracao, o.tipo, o.codInst, o.piso, o.zona, o.empresa);
                    if (i % 10 == 0)
                    {
                        Console.WriteLine("Prima uma tecla para continuar");
                        Console.ReadKey();
                    }
                    i++;
                }

            }
            Console.WriteLine("Prima uma tecla para continuar");
            Console.ReadKey();

        }
        static void f()
        {

        }

        static void g()
        {

        }

        static void h()
        {
            using (SI2_1314v_TPEntities ctx = new SI2_1314v_TPEntities())
            {
                Console.WriteLine("Qual o id da ocorrência? ");
                var ocorrenciaId = Convert.ToInt32(Console.ReadLine());
                var ocorrencias = ctx.Ocorrencias
                    .Join(ctx.Instalacaos, 
                        o => o.empresa,
                        i => i.empresa,
                        (o, i) => new { o, i})
                    .Join(ctx.Localizacaos,
                        e => e.i.cod,
                        l => l.id,
                        (e, l) => new {e = e, l = l})
                    .Join(ctx.Sectors,
                        o => o.e.o.codInst,
                        s => s.codInst,
                        (o, s) => new { o = o, s = s}
                        )
                        .Where(o => o.o.e.o.id.Equals(ocorrenciaId))
                    .ToList();

                if (ocorrencias.Count == 0)
                {
                    Console.WriteLine("Não foram encontrados registos");
                    Console.WriteLine("Prima uma tecla para continuar");
                    Console.ReadKey();
                    return;
                }

                Console.WriteLine("Informações sobre a ocorrência {0}:", ocorrenciaId);
                var k = 1;
                foreach (var o in ocorrencias)
                {
                    Console.WriteLine("Localização\n\tMorada : {0}\n\tCoordenadas : {1} ",
                        o.o.l.morada, o.o.l.coordenadas);
                    Console.WriteLine("Sector\n\tPiso : {0}\n\tZona : {1}\n\tDescrição : {2}\n\tExtintor : {3} ",
                        o.s.piso, o.s.zona, o.s.descrição, o.s.extintor);
                    if (k % 10 == 0)
                    {
                        Console.WriteLine("Prima uma tecla para continuar");
                        Console.ReadKey();
                    }
                    k++;
                }

            }
            Console.WriteLine("Prima uma tecla para continuar");
            Console.ReadKey();

        }

        static void i()
        {

        }
    }
}
