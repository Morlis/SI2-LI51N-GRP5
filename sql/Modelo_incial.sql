/* Estrutura do Modelo F�sico 
 * das tabelas, para o Trabalho Pr�tico
 * do Sem Ver�o 13/14
 *
 * nota: outras restri��es de integridade que
 * os alunos considerem necess�rio implementar
 * na forma declarativa, devem ser adicionadas
 * ao modelo, e descritas no Relat�rio
 */

use SI2_1314v_TP

if(OBJECT_ID('Trabalho') is not null) drop table Trabalho
if(OBJECT_ID('Ocorrencia') is not null) drop table Ocorrencia
if(OBJECT_ID('Afecto') is not null) drop table Afecto
if(OBJECT_ID('Funcionario') is not null) drop table Funcionario
if(OBJECT_ID('FuncionarioCod') is not null) DROP SEQUENCE FuncionarioCod;
if(OBJECT_ID('AreaIntervencao') is not null) drop table AreaIntervencao
if(OBJECT_ID('Sector') is not null) drop table Sector
if(OBJECT_ID('Instalacao') is not null) drop table Instalacao
if(OBJECT_ID('InstalacaoCod') is not null) DROP SEQUENCE InstalacaoCod;
if(OBJECT_ID('Localizacao') is not null) drop table Localizacao
if(OBJECT_ID('Empresa') is not null) drop table Empresa


create table Empresa(
nipc int primary key,
designacao varchar(50) not null,
morada varchar(255) not null
)

create table Localizacao(
id int identity(1,1) primary key,
morada varchar(250) unique not null,
coordenadas varchar(15) not null
)

CREATE SEQUENCE dbo.InstalacaoCod AS int START WITH 1 INCREMENT BY 1

create table Instalacao(
  cod int primary key DEFAULT (NEXT VALUE FOR InstalacaoCod),
  descricao varchar (150) not null,
  empresa int references Empresa not null,
  localizacao int references Localizacao not null
)

create table Sector(
codInst int references Instalacao,
piso int,
zona char(1),
descri��o varchar(250),
extintor bit not null,
primary key (codInst,piso,zona)
)

create table AreaIntervencao(
cod int identity(1,1) primary key,
designacao varchar(50)unique not null,
descricao varchar(250)
)

-- Sequencia para Funcionario campo [num]
CREATE SEQUENCE dbo.FuncionarioCod
	AS int
	START WITH 1
	INCREMENT BY 1;

create table Funcionario(
num int primary key DEFAULT (NEXT VALUE FOR FuncionarioCod),
nome varchar(250) not null,
dataNasc date not null
)

create table Afecto(
areaInt int references AreaIntervencao,
numFunc int references Funcionario,
dataHabilArea date not null,
�Coordenador bit not null,
primary key (areaInt,numFunc)
)

create table Ocorrencia(
id int identity(1,1) primary key,
dhEntrada datetime not null DEFAULT GETDATE(),
dhAlteracao datetime not null DEFAULT GETDATE(),
tipo char(7) not null CHECK (tipo IN ('urgente', 'cr�tico', 'trivial')), 
estado varchar(16) not null CHECK (estado IN ('inicial', 'em processamento', 'em resolu��o', 'recusado', 'cancelado', 'conclu�do')) DEFAULT('inicial'), 
codInst int not null,
piso int not null,
zona char(1) not null,
empresa int not null references Empresa, 
-- RI: empresa tem que corresponder � empresa da instalacao da ocorrencia
foreign key (codInst,piso,zona) references Sector
)

create table Trabalho(
idOcorr int references Ocorrencia,
areaInt int references AreaIntervencao,
concluido bit not null,
coordenador int not null references Funcionario,
-- RI: funcionario com credencial de coordenador para a area
primary key(idOcorr,areaInt)
)

