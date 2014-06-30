using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;


namespace app
{
    class Program
    {

        // alineas a
        internal static SqlConnection CreateConnection()
        {
            //SqlConnection MyConnection = new SqlConnection("server=(local)\\PM-PC;database=Si_2_sandbox;Integrated Security=SSPI;");
            return new SqlConnection("Data Source=PM-PC;Database=si_2_sandbox;Integrated Security=true;");
        }

        // alineas b
        internal static bool TestConnetion()
        {
            SqlConnection conn = CreateConnection();

            try
            {
                conn.Open();
                Console.WriteLine("Ligação com o servidor de SQLServer efectuada!");
                conn.Close();
            }
            catch (Exception)
            {

                return false;
            }

            return true;
        }

        // alinea c)
        internal static int ExecuteInsertCommand(SqlConnection conn)
        {
            SqlCommand cmd = conn.CreateCommand();
            cmd.CommandType = CommandType.Text;
            cmd.CommandText = "INSERT INTO Carta (id, nome, valor) values(4, 'carta4', 200)";
           
            conn.Open();
            var res = cmd.ExecuteNonQuery();
            conn.Close();

            return res;
        }

        // alinea d)
        static SqlDataReader ExecuteSelectCommand(SqlConnection conn)
        {
            SqlCommand cmd = conn.CreateCommand();
            cmd.CommandType = CommandType.Text;
            cmd.CommandText = "SELECT id, nome, valor FROM Carta";
            
           
            var res = cmd.ExecuteReader();
            
            
            return res;
        }

        // alinea d)
        static void ListResultSet(SqlDataReader rs)
        {
            while (rs.Read())
            {
                Console.Write("id:" + rs.GetInt32(0));
                Console.Write(" ,");
                Console.WriteLine("Nome:" + rs.GetString(1));
                Console.Write(" ,");
                Console.WriteLine("Valor:" + rs.GetInt32(2));
            }
        }

        // alinea e)
        static int ExecuteInsertInputParameters(SqlConnection conn, Int32 id, String nome, Int32 valor)
        {
            SqlCommand cmd = conn.CreateCommand();
            cmd.CommandType = CommandType.Text;
            cmd.CommandText = "INSERT INTO Carta (id, nome, valor) values(@id, @nome, @valor)";
            
            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@nome", nome);
            cmd.Parameters.AddWithValue("@valor", valor);

            conn.Open();
            var res = cmd.ExecuteNonQuery();
            conn.Close();

            return res;
        }

        // alinea e) iii)
        static int ExecuteInsertInputNullParameter(SqlConnection conn, Int32 id, Int32 nome, DBNull valor)
        {
            SqlCommand cmd = conn.CreateCommand();
            cmd.CommandType = CommandType.Text;
            cmd.CommandText = "INSERT INTO T (id, value, design) values(@id, @value, @design)";

            //SqlParameter p = new SqlParameter("@id", SqlDbType.Int);

            cmd.Parameters.AddWithValue("@id", id);
            cmd.Parameters.AddWithValue("@value", nome);
            cmd.Parameters.AddWithValue("@design", valor);

            conn.Open();
            var res = cmd.ExecuteNonQuery();
            conn.Close();

            return res;
        }


        void oldMain()
        {
            //// alinea a) e b) --> estabelecer uma ligação à base de dados
            //TestConnetion();

            //// alinea c) --> executar um comando insert
            //Console.WriteLine("Número de linhas inseridas: {0}", ExecuteInsertCommand(CreateConnection()));

            //// alinea d) --> executar um comando que retorna um ResulSet --> imprimir linhas na consola
            //SqlConnection conn = CreateConnection();
            //conn.Open();
            //ListResultSet(ExecuteSelectCommand(conn));
            //conn.Close();

            //// alinea e) --> criar um comando com parameters
            //Console.WriteLine("Número de linhas inseridas: {0}", ExecuteInsertInputParameters(CreateConnection(), 5, "carta5", 500));

            //// alinea e) iii)--> criar um comando com parameters que inser um NULL na tabela
            //Console.WriteLine("Número de linhas inseridas: {0}", ExecuteInsertInputNullParameter(CreateConnection(), 5, 5, DBNull.Value));

            //// alinea f) --> criar um comando com parameters
        }

        /// <summary>
        /// Data Adapter
        /// </summary>
        /// <param name="args"></param>
        static void Main(string[] args)
        {

           


            // Data Adapter-------------------------------------------
            SqlConnection conn = CreateConnection();
            //conn.Open();
            String selectStr = "SELECT id, nome, valor FROM Carta";


       //     CreateDataAdapter(conn, selectStr);
        //    FillDataSetWithDatatable();
         //   ShowDatatableContent();

            ReadXmlToDataset();
            conn.Close();


          }

        private static void CreateDataAdapter(SqlConnection conn, string selectStr)
        {
            SqlDataAdapter da = new SqlDataAdapter(selectStr, conn);
            //DataTable dt = new DataTable();
            DataSet ds = new DataSet();
            //da.Fill(dt);
            da.Fill(ds, "T3"); // Versão 1 da tabela Carta
            
            da.Fill(ds, "T2"); // Versão 2 da tabela Carta

            da.Fill(ds);
            
            // DataSet colecção de datatables

            //foreach (DataRow row in dt.Rows)
            //    Console.WriteLine("{0} {1} {2}", row[0], row["nome"], row["valor"]);


            
            da.Fill(ds, "T"); //Versão 3 da tabela Carta mas com nome T no dataset
          

            Console.WriteLine("Número de tabelas no DataSet {0}", ds.Tables.Count);

            foreach (DataTable t in ds.Tables)
            {
                Console.WriteLine("Nome da tabela {0}", t.TableName);
            }
            //Console.WriteLine("Nome da tabela {0}", ds.Tables[0].TableName);
            //Console.WriteLine("Nome da tabela {0}", ds.Tables[1].TableName);
            foreach (DataRow row in ds.Tables["T"].Rows)
                Console.WriteLine("{0} {1} {2}", row[0], row[1], row[2]);


            // Alterar valor na datatable

            SqlDataAdapter daUpdate = new SqlDataAdapter();
            daUpdate.SelectCommand = new SqlCommand("SELECT id, tipo FROM T1", conn);
           // daUpdate.UpdateCommand = new SqlCommand("update carta set valor = 33 where id = 3", conn);
            SqlCommandBuilder builder = new SqlCommandBuilder(daUpdate);
            DataSet ds2 = new DataSet();

            ITableMapping tm = daUpdate.TableMappings.Add("T1", "T3");
            tm.ColumnMappings.Add("id", "novoId");
            tm.ColumnMappings.
            //da.Fill(dt);
            daUpdate.Fill(ds2, "T1"); // Versão 1 da tabela Carta

            // ...

            //builder.GetUpdateCommand();
            
            Console.WriteLine("name before change: {0}", ds2.Tables["T1"].Rows[1]["tipo"]);
            ds2.Tables["T1"].Rows[1]["tipo"] = "F";
            daUpdate.UpdateCommand = builder.GetUpdateCommand(); // Tabela tem de ter chave
            daUpdate.Update(ds2, "T1");
            
            Console.WriteLine("name after change: {0}", ds2.Tables["T1"].Rows[1]["tipo"]);
           

            // Converter para XML (Mapping)

            string xmlDS = ds.GetXml();

            // ds.WriteXml("T1.xml", XmlWriteMode.WriteSchema); escreve o esquema XSD
            ds.WriteXml("T1.xml", XmlWriteMode.IgnoreSchema);
        }

        private static void ReadXmlToDataset()
        {
            DataSet ds2 = new DataSet();
            using (StreamReader xmlDoc = new StreamReader("T1.xml"))
            {
                //Escrevendo no documento
                ds2.ReadXml(xmlDoc);

                foreach (DataRow row in ds2.Tables["T3"].Rows)
                    Console.WriteLine("{0} {1} {2}", row[0], row[1], row[2]);
            }
        }
    }
}
