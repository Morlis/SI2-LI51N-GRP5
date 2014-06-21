SI2-LI51N-GRP5
==============

Sistemas de Informação II - Trabalho Prático 3 - Grupo 5

##### Utilizar ficheiros de SQL
Ordem de execução dos ficheiros
* Modelo_incial.sql
* Extensoes.sql
* Dados.sql

##### Restrições de integridade adicionadas ao modelo inícial

Valor inícial e conjunto de valores
```sql
ALTER TABLE [dbo].[Ocorrencia] ADD  DEFAULT ('inicial') FOR [estado]
ALTER TABLE [dbo].[Ocorrencia]
  WITH CHECK ADD CHECK
    (([estado]='concluído' OR [estado]='cancelado' OR [estado]='recusado' OR [estado]='em resolução' OR [estado]='em processamento' OR [estado]='inicial'))
ALTER TABLE [dbo].[Ocorrencia]
  WITH CHECK ADD CHECK
    (([tipo]='trivial' OR [tipo]='crítico' OR [tipo]='urgente'))
```
[Sequência](http://msdn.microsoft.com/en-us/library/ff878058.aspx) para o campo **num** da tabela Funcionario
```sql
CREATE SEQUENCE dbo.FuncionarioCod AS int START WITH 1 INCREMENT BY 1

CREATE TABLE Funcionario(
  num int primary key DEFAULT (NEXT VALUE FOR FuncionarioCod),
  nome varchar(250) not null,
  dataNasc date not null
)
```
[Sequência](http://msdn.microsoft.com/en-us/library/ff878058.aspx) para o campo **cod** da tabela Instalacao
```sql
CREATE SEQUENCE dbo.InstalacaoCod AS int START WITH 1 INCREMENT BY 1

create table Instalacao(
  cod int primary key DEFAULT (NEXT VALUE FOR InstalacaoCod),
  descricao varchar (150) not null,
  empresa int references Empresa not null,
  localizacao int references Localizacao not null
)
```
