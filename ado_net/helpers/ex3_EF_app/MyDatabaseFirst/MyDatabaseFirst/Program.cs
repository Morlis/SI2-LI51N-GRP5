using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace MyDatabaseFirst
{
    class Program
    {
        public static void WriteMenu()
        {
            Console.WriteLine("Select an operation:");
            Console.WriteLine("1 - Add Accounts");
            Console.WriteLine("2 - Update client name");
            Console.WriteLine("3 - Update account balance");
            Console.WriteLine("4 - Add account for existing client");
            Console.WriteLine("5 - Delete account");
            Console.WriteLine("0 - Exit application");
        }

        static void Main(string[] args)
        {


            WriteMenu();
            var operation = Convert.ToInt32(Console.ReadLine());
            while (!operation.Equals(0))
            {
                switch (operation)
                {
                    case 1:
                        AddContas();
                        break;
                    case 2:
                        UpdateClienteName("Pedro");
                        break;
                    case 3:
                        UpdateSaldoConta(3000, 2000);
                        break;
                    case 4:
                        AddContaExistingCliente(1);
                        break;
                    case 5:
                        DeleteConta(3000);
                        break;
                    case 0:
                        return;
                }
                WriteMenu();
                operation = Convert.ToInt32(Console.ReadLine());
            }
            
           
           
/*
 *
 * 
Nota: devem usar blocos
using
! E devem criar um método para cada exercício.
a.
Exercício 1 : Adicionar ao ContasContex um novo cli
ente e uma nova conta para esse
cliente
b.
Exercício 2 : Alterar o nome de um cliente da BD
c.
Exercício 3: Alterar o saldo de uma conta
d.
Exercício 4: Adicionar uma nova conta para um cliente que já exista.
e.
Exercício 5: Apagar uma conta e/ou um cliente da BD Neste momento é possível trabalhar com o ContasContext e usar as instâncias das
entidades do Modelo. 

 * Nota 
 * */

            // var c = new Cliente() {nome = "novo cliente"};
            // c.Contas.Add(new Conta() {id = 3000, saldo = 1000});

            /*
         * (TPC) Testar cenários de concorrência entre actuali
zações via Entity Framework e actualizações
directamente na BD (com Management Studio).
Pergunta: Como detectar que os valores da BD foram
alterados? E como gerir os conflitos
         */



        }

        #region Adicionar ao ContasContex um novo cliente e uma nova conta para esse cliente
        /// <summary>
        /// Adicionar ao ContasContex um novo cliente e uma nova conta para esse cliente
        /// </summary>
        public static void AddContas()
        {
            using (var ctx = new ContasContext())
            {
                var cl = new Cliente();//{name = "António"};
                var co = new Conta();//{id = 3000, saldo = 1000};
                Console.WriteLine("Creating new account... ");
                Console.WriteLine("Write owner name : ");
                cl.name = Console.ReadLine();

                Console.WriteLine("Write account id : ");
                co.id = Convert.ToInt32(Console.ReadLine());

                Console.WriteLine("Write balance : ");
                co.saldo = Convert.ToDecimal(Console.ReadLine());

                
                
                cl.Contas.Add(co);
                ctx.Clientes.Add(cl);
                ctx.SaveChanges();

            }
        }
        #endregion

        #region Alterar o nome de um cliente da BD
        /// <summary>
        /// Alterar o nome de um cliente da BD
        /// </summary>
        public static void UpdateClienteName(string cliName)
        {
            using (var ctx = new ContasContext())
            {
                Console.WriteLine("Updating cliente name... ");
                Console.WriteLine("Write owner name : ");
                cliName = Console.ReadLine();
                Console.WriteLine("Write account id : ");
                var contaId =  Convert.ToInt32(Console.ReadLine());
               
                var cli = (from c in ctx.Clientes
                               where c.id == contaId
                               select c).SingleOrDefault();

                if (cli == null) return;
                cli.name = cliName;

                //ctx.Clientes.Add(cli);
                ctx.SaveChanges();
            }
        }
        #endregion


        #region Alterar o saldo de uma conta
        /// <summary>
        /// Alterar o saldo de uma conta
        /// </summary>
        public static void UpdateSaldoConta(int contaId, decimal novoSaldo)
        {
            using (var ctx = new ContasContext())
            {
                Console.WriteLine("Updating account balance... ");
                Console.WriteLine("Write balance : ");
                novoSaldo = Convert.ToDecimal(Console.ReadLine());
                Console.WriteLine("Write account id : ");
                contaId = Convert.ToInt32(Console.ReadLine());
                var conta = (from c in ctx.Contas
                               where c.id == contaId
                               select c).SingleOrDefault();

                if (conta == null) return;
                conta.saldo = novoSaldo;

                //ctx.Clientes.Add(cli);
                ctx.SaveChanges();
            }
        }
        #endregion


        #region Adicionar uma nova conta para um cliente que já exista.
        /// <summary>
        /// Adicionar uma nova conta para um cliente que já exista.
        /// </summary>
        public static void AddContaExistingCliente(int clienteId)
        {
            using (var ctx = new ContasContext())
            {
                Console.WriteLine("Add new account to existing client... ");
                Console.WriteLine("Write account id : ");
                var contaId = Convert.ToInt32(Console.ReadLine());

                Console.WriteLine("Write owner id : ");
                clienteId = Convert.ToInt32(Console.ReadLine());
                Console.WriteLine("Write balance : ");
                var novoSaldo = Convert.ToDecimal(Console.ReadLine());
                

                var cliente = (from c in ctx.Clientes
                             where c.id == clienteId
                               select c).SingleOrDefault();

                if (cliente == null) return;
                cliente.Contas.Add(new Conta { id = contaId, saldo = novoSaldo });

                ctx.SaveChanges();
            }
        }
        #endregion

        
      #region Apagar uma conta e/ou um cliente da BD Neste momento é possível trabalhar com o ContasContext e usar as instâncias das entidades do Modelo. 
        /// <summary>
        /// Apagar uma conta e/ou um cliente da BD Neste momento é possível trabalhar com o ContasContext e usar as instâncias das entidades do Modelo. 
        /// </summary>
        public static void DeleteConta(int contaId)
        {
            using (var ctx = new ContasContext())
            {
                Console.WriteLine("Delete account... ");
                Console.WriteLine("Write account id : ");
                contaId = Convert.ToInt32(Console.ReadLine());

                var conta = (from c in ctx.Contas
                               where c.id == contaId
                               select c).SingleOrDefault();

                if (conta == null) return;
                ctx.Contas.Remove(conta);

                //ctx.Clientes.Add(cli);
                ctx.SaveChanges();
            }
        }
        #endregion
    }
}
