SI2-LI51N-GRP5
==============

Sistemas de Informação II - Trabalho Prático 3 - Grupo 5

##### Utilizar ficheiros de SQL
Ordem de execução dos ficheiros
* Modelo_incial.sql
* Extensoes.sql
* Dados.sql

##### Questão 1 - Restrições de integridade adicionadas ao modelo inícial

Valor inícial e conjunto de valores
```sql
ALTER TABLE [dbo].[Ocorrencia] ADD  DEFAULT ('inicial') FOR [estado]
ALTER TABLE [dbo].[Ocorrencia] ADD DEFAULT GETDATE() FOR dhEntrada
ALTER TABLE [dbo].[Ocorrencia] ADD DEFAULT GETDATE() FOR dhAlteracao
ALTER TABLE [dbo].[Ocorrencia]
  WITH CHECK ADD CHECK
    (([estado]='concluído' OR [estado]='cancelado' OR [estado]='recusado' OR [estado]='em resolução' OR [estado]='em processamento' OR [estado]='inicial'))
ALTER TABLE [dbo].[Ocorrencia]
  WITH CHECK ADD CHECK
    (([tipo]='trivial' OR [tipo]='crítico' OR [tipo]='urgente'))
ALTER TABLE [dbo].[Ocorrencia] ADD DEFAULT GETDATE() FOR dhEntrada

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

##### Questão 2 - Código T-SQL (e respectivas extensões, vistas, funções, procedimentos armazenados e gatilhos)

a. Inserir uma nova empresa ou área de intervenção.
```sql
/**
* Não necessita de uma transação.
* "An INSERT statement always acquires an exclusive (X) lock on the table it modifies, 
* and holds that lock until the transaction completes. With an exclusive (X) lock, 
* no other transactions can modify data."
* Exemplo:
* EXEC InserirEmpresa 600016234, 'Instituto Superior de Engenharia de Lisboa', 'Rua Conselheiro Emídio Navarro 1, 1959-007 Lisboa'
**/
CREATE PROCEDURE InserirEmpresa @nipc int, @designacao varchar(50), @morada varchar(255) AS
BEGIN
	INSERT INTO Empresa VALUES(@nipc, @designacao, @morada)
END
GO

/**
* Não necessita de uma transação.
* Devolve o identity gerado pelo INSERT na variavel @id o parametro @descricao e opcional
* Exemplo:
* DECLARE @AreaID int
* EXEC InserirAreaIntervencao @AreaID OUT, 'Assistência Técnica'
**/
CREATE PROCEDURE InserirAreaIntervencao @id int OUT, @designacao varchar(50), @descricao varchar(250) = null AS
BEGIN
	INSERT INTO AreaIntervencao VALUES(@designacao, @descricao)
	SET @id = SCOPE_IDENTITY()
END
GO
```

b. Actualizar os dados de uma empresa.
```sql
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC EditarEmpresa 600016234, 'Instituto Superior de Engenharia de Lisboa', 'Rua Conselheiro Emídio Navarro 1, 1959-007 Lisboa'
**/
CREATE PROCEDURE EditarEmpresa @nipc int, @designacao varchar(50), @morada varchar(255) AS
BEGIN
	UPDATE Empresa SET designacao=@designacao, morada=@morada WHERE nipc=@nipc
END
GO
```

c. Reportar uma ocorrência. 
```sql
/**
* Gatilho para actualizar a data de alteracao de uma ocorrencia (dhAlteracao) automaticamente.
**/
CREATE TRIGGER Ocorrencia_alterada ON Ocorrencia
FOR UPDATE /* Dispara este gatilho quando uma Ocorrencia e alterada */
AS BEGIN
	UPDATE Ocorrencia SET dhAlteracao = GETDATE()
	FROM INSERTED
	WHERE INSERTED.id=Ocorrencia.id
END
GO

/**
* Nivel de isolamento REPEATABLE READ
* Exemplo:
* DECLARE @OcorID int
* Exec ReportarOcorrencia 'trivial', 501510184, 1, 1, 'A', @OcorID OUT
**/
CREATE PROCEDURE ReportarOcorrencia @tipo char(7), @empresa int, @codInst int, @piso int, @zona char(1), @id int OUT AS
BEGIN
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	BEGIN TRY
		/* RI: empresa tem que corresponder à empresa da instalacao da ocorrencia */
		SELECT Empresa.nipc from Instalacao 
			INNER JOIN Empresa ON Empresa.nipc = Instalacao.empresa
			INNER JOIN Sector ON Sector.codInst = Instalacao.cod
			WHERE Empresa.nipc = @empresa AND Instalacao.cod=@codInst AND piso=@piso AND zona=@zona
		IF @@ROWCOUNT > 0
		BEGIN
			INSERT INTO Ocorrencia (tipo, empresa, codInst, piso, zona) VALUES (@tipo, @empresa, @codInst, @piso, @zona)
			SET @id = SCOPE_IDENTITY()
		END
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
	END CATCH
END
GO
```

d. Cancelar uma ocorrência
```sql
/**
* Não necessita de uma transação.
* So cancela Ocourrencias em estado 'inicial' ou 'em processamento'
* Exemplo:
* EXEC CancelarOcorrencia 3
**/
CREATE PROCEDURE CancelarOcorrencia @id int AS
BEGIN
	UPDATE Ocorrencia SET estado='cancelado' WHERE id=@id AND (estado='inicial' OR estado='em processamento')
END
GO
```
e. Dar início à resolução de uma ocorrência em processamento. ***EM CURSO: CM***
```sql
/** 
* Função para obter o funcionário que tiver menos ocorrências em resolução
* e que seja cordenador de uma area de intervencao
**/
CREATE FUNCTION dbo.FuncionarioComMenosOcorrenciasActivas(@areaID INT) RETURNS INT AS
BEGIN
	DECLARE @num INT

	SELECT TOP(1) @num=num FROM Funcionario 
		INNER JOIN Afecto ON Afecto.numFunc=Funcionario.num AND Afecto.éCoordenador=1 AND Afecto.areaInt=@areaID
		INNER JOIN AreaIntervencao ON AreaIntervencao.cod=Afecto.numFunc
		LEFT OUTER JOIN (
			SELECT coordenador, COUNT(coordenador) as cnt FROM Trabalho 
				INNER JOIN 
					(SELECT id FROM Ocorrencia WHERE estado='em resolução') AS Ocorr ON Trabalho.idOcorr=Ocorr.id
			GROUP BY coordenador) as Afc ON Afc.coordenador=Funcionario.num
	ORDER BY Afc.cnt ASC
	RETURN @num
END
GO

/**
* Nivel de isolamento REPEATABLE READ
* Exemplo:
* EXEC AssignarOcorrencia 3
**/
CREATE PROCEDURE AssignarOcorrencia @id int AS
BEGIN
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @emProcessamento int
		DECLARE @funcionario int

		-- Verificar se a Ocorrencia esta no estado 'em processamento' e obter o lock para a ocorrencia
		SELECT @emProcessamento=count(*) FROM Ocorrencia WHERE id=@id AND estado='em processamento'
		IF @emProcessamento > 0 
		BEGIN
			BEGIN
				-- Assignar um coordenador a todos os trabalhos desta Ocorrencia
				UPDATE Trabalho SET coordenador=dbo.FuncionarioComMenosOcorrenciasActivas(areaInt) WHERE Trabalho.idOcorr=@id
				UPDATE Ocorrencia SET estado='em resolução' WHERE id=@id
			END
		END
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
	END CATCH
END
GO
```

f. Assinalar a finalização da prestação de serviço numa área de intervenção de uma dada ocorrência. ***CM: testar***
```sql
/**
* Necessita transação (discuss)
* O estado de uma ocorrência transita para concluído logo que estejam terminados os trabalhos em todas as áreas de intervenção.
* Pretendemos assinalar a conclusão de prestação de serviço para uma área de intervenção, o que significa criar um trigger para 
* alterações ao campo "concluido" da  tabela "Trabalho". A acção despoletada passa por verificar se TODOS os registos da tabela 
* Trabalho que estão relacionados com a presente ocorrencia se encontram no estado "concluido", e se for esse o caso, actualiza a 
* tabela "Ocorrencia", alterando o estado para "concluido".
**/
CREATE FUNCTION	numTrabalhosEmCursoPorOcorrencia(@idOcorr int) RETURNS int
AS
BEGIN
	RETURN (SELECT COUNT(*) FROM Trabalho WHERE idOcorr = @idOcorr AND concluido = 0)
END
GO 

CREATE TRIGGER conclusãoTrabalhoAreaIntervencao ON Trabalho AFTER UPDATE
AS
BEGIN
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @idOcorr int, @numTrabalhosEmCurso int, @concluido bit
		SET @idOcorr = (SELECT idOcorr from inserted)
		SET @numTrabalhosEmCurso = dbo.numTrabalhosEmCursoPorOcorrencia(@idOcorr)
		IF (UPDATE(concluido) AND @numTrabalhosEmCurso = 0) 
			UPDATE Ocorrencia SET estado = 'concluído' WHERE id = @idOcorr
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
	END CATCH
END
GO
```

g. Apresentar, para cada empresa, o número total de ocorrências organizadas por tipo. 
```sql
/**
* Exemplo:
* SELECT * FROM TotalOcorrenciaPorEmpresaPorTipo WHERE nrOcorrTipo > 2
**/
CREATE VIEW TotalOcorrenciaPorEmpresaPorTipo AS
	SELECT oc.empresa, oc.tipo, COUNT(oc.tipo) AS nrOcorrTipo FROM Ocorrencia AS oc
		INNER JOIN Empresa e
			ON oc.empresa = e.nipc
		GROUP BY oc.tipo, oc.empresa
GO
```

h. Listar as ocorrências em situação de incumprimento face ao prazo estabelecido para a sua resolução. 
```sql
/**
* Exemplo:
* SELECT * FROM OcorrenciasEmIncumprimento
**/
CREATE VIEW OcorrenciasEmIncumprimento AS
	SELECT *,  (DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao)) AS HOURa FROM Ocorrencia oc
		WHERE ((oc.tipo = 'urgente' AND DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao) > 48) OR 
			(oc.tipo = 'crítico' AND DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao) > 12)) AND
			(oc.estado NOT IN ('recusado', 'cancelado', 'concluído'))
GO
```

i. Indicar, para uma determinada área de intervenção, qual a empresa com maior número de ocorrências do tipo 
“crítico” que reportou ocorrências nessa área. 
```sql
/**
* Exemplo:
* SELECT * FROM ObterEmpresaComMaxCritoOcorrPorAreaInt(2)
**/
CREATE FUNCTION dbo.ObterEmpresaComMaxCritoOcorrPorAreaInt(@areaInt int)
RETURNS @maxTable TABLE
(
    empresa int PRIMARY KEY NOT NULL, 
	Ocurrencias int
) AS
BEGIN
	INSERT INTO @maxTable 
		SELECT empresa, COUNT(empresa) as cnt FROM Trabalho INNER JOIN Ocorrencia ON Ocorrencia.id = Trabalho.idOcorr AND Ocorrencia.tipo='crítico'
				WHERE Trabalho.areaInt=@areaInt GROUP BY empresa 		
		HAVING COUNT(empresa) = 
			(SELECT TOP(1) MAX(cnt) as maxCnt FROM 
				(SELECT empresa, COUNT(empresa) as cnt FROM Trabalho INNER JOIN Ocorrencia ON Ocorrencia.id = Trabalho.idOcorr AND Ocorrencia.tipo='crítico'
					WHERE Trabalho.areaInt=@areaInt GROUP BY empresa) as x2 GROUP BY empresa)
	RETURN
END
GO
```

j. Listar os funcionários que nunca tenham tido a coordenação de uma ocorrência do tipo “crítico”. 
```sql
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC ListarFuncionariosCoordenadoresSemOcorrenciasCriticas
**/
CREATE PROCEDURE ListarFuncionariosCoordenadoresSemOcorrenciasCriticas AS
BEGIN
	DECLARE @ocorrenciaTipo as varchar(7)
	SET @ocorrenciaTipo = 'crítico'

	SELECT fu.nome FROM Funcionario fu 
		LEFT JOIN
		(SELECT f.num, f.nome, oc.tipo, COUNT(oc.tipo) AS NrOcorrencias FROM Ocorrencia oc 
			INNER JOIN Trabalho t
				ON t.idOcorr = oc.id AND oc.tipo = @ocorrenciaTipo
			INNER JOIN Funcionario f
				ON f.num = t.coordenador
			GROUP BY f.num, f.nome, oc.tipo
			HAVING COUNT(oc.tipo) > 0
		) AS Oco
			ON oco.num = fu.num 
		WHERE oco.NrOcorrencias IS NULL
END
GO
```

k. Criar um processo que permita em determinado momento no tempo, para todas as ocorrências que estejam em 
incumprimento, registar um ponto (de crédito) a cada empresa visada. Estes pontos serão um dia mais tarde 
convertidos em cheques-bónus (fora do âmbito deste projecto). Para tal deve: 
 i. Criar as tabelas auxiliares necessárias ao registo de pontos por empresa;


 ii. Garantir que, uma empresa não recebe vários pontos pela mesma ocorrência, mesmo que o processo se execute várias vezes com a mesma ocorrência ainda em incumprimento; 


 iii. Manter registo de todas as ocorrências que deram origem a pontos, e a sua data de processamento; 


##### Questão 3 - Aplicação ADO.NET, Entity Framework:

a. Actualizar os dados de uma empresa;

b. Registar uma ocorrência; 

c. Aceitação de uma ocorrência (i.e. atribuição do estado em processamento); 

d. Determinar quais as ocorrências que se encontram em situação de incumprimento e quais os centros de 
intervenção responsáveis pelo incumprimento; 

e. Listar todas as ocorrências que tenham sido concluídas num determinado período de tempo; 

f. Dar início, na sua área de intervenção específica, à resolução de uma ocorrência em processamento; 

g. Assinalar a finalização da prestação de serviço numa área de intervenção de uma dada ocorrência; 

h. Obter informação sobre o sector e morada da instalação de uma dada ocorrência


##### Questão 4 - XML - Criação de de Schemas XSD para validação, habilitar a aplicação para o carregamento de dados a partir de ficheiros XML:

a. Crie um schema xml (XSD) que permita validar a estrutura de um documento xml que contenha informação 
sobre o registo de um conjunto de ocorrências, com o seu respectivo detalhe; 

b. Apresente exemplos de documentos xml para carregamento; 

c. Crie uma aplicação (ou integre na aplicação realizada na alínea anterior) a funcionalidade de carregar o ficheiro xml, inserindo a respectiva informação na base de dados; 
