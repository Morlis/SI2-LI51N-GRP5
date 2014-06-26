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
* Nivel de isolamento READ COMMITTED
* Exemplo:
* DECLARE @OcorID int
* Exec ReportarOcorrencia 'trivial', 501510184, 1, 1, 'A', @OcorID OUT
**/
CREATE PROCEDURE ReportarOcorrencia @tipo char(7), @empresa int, @codInst int, @piso int, @zona char(1), @id int OUT AS
BEGIN
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
	BEGIN TRANSACTION
	BEGIN TRY
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
* So cancela Ocorrencias em estado 'inicial' ou 'em processamento'
* Exemplo:
* Exec CancelarOcorrencia 3
**/
CREATE PROCEDURE CancelarOcorrencia @id int AS
BEGIN
	UPDATE Ocorrencia SET estado='cancelado' WHERE id=@id AND (estado='inicial' OR estado='em processamento')
END
```
e. Dar início à resolução de uma ocorrência em processamento. ***EM CURSO: CM***
```sql
/**
* Necessita transação (Read Committed? - Evitar actualizaçãoes aos criterios de eleição dos coordenadores de área).
* O estado em resolução indica que foram atribuídos funcionários para coordenarem cada uma 
* das áreas de intervenção associadas à ocorrência. Para cada área de intervenção da ocorrência, é atribuído um 
* coordenador (a responsabilidade é atribuída automaticamente ao funcionário que tiver menos ocorrências em resolução).
* Parametros: Id da Ocorrencia;  
* Exemplo:
* Exec ResolverOcorrencia 3
**/

```

f. Assinalar a finalização da prestação de serviço numa área de intervenção de uma dada ocorrência. ***testar***
```sql
/************************************************
* ALINEA 2.f
************************************************/
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

CREATE TRIGGER conclusãoTrabalhoAreaIntervencao ON Trabalho AFTER UPDATE
AS
BEGIN
	DECLARE @idOcorr int, @numTrabalhosEmCurso int, @concluido bit
	SET @idOcorr = SELECT(idOcorr from inserted)
	SET @numTrabalhosEmCurso = numTrabalhosEmCursoPorOcorrencia(@idOcorr)
	IF (UPDATE(concluido) AND @numTrabalhosEmCurso == 0) 
	BEGIN
		UPDATE Ocorrencia SET estado = 'concluido' WHERE id = @idOcorr
	END
END
```

g. Apresentar, para cada empresa, o número total de ocorrências organizadas por tipo. 
```sql
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC ListarTotalOcorrenciaDasEmpresas
**/
CREATE PROCEDURE ListarTotalOcorrenciaDasEmpresas AS
BEGIN
	SELECT oc.empresa, oc.tipo, COUNT(oc.tipo) AS nrOcorrTipo FROM Ocorrencia AS oc
		INNER JOIN Empresa e
			ON oc.empresa = e.nipc
		GROUP BY oc.tipo, oc.empresa
END
```

h. Listar as ocorrências em situação de incumprimento face ao prazo estabelecido para a sua resolução. 
```sql
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC ListarOcorrenciasEmIncumprimento
**/
CREATE PROCEDURE ListarOcorrenciasEmIncumprimento AS
BEGIN
	DECLARE @ocorrenciaTipo48h as varchar(7), @ocorrenciaTipo12h as varchar(7)
	SET @ocorrenciaTipo48h = 'urgente'
	SET @ocorrenciaTipo12h = 'crítico'

	SELECT *,  (DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao)) AS HOURa FROM Ocorrencia oc
		WHERE (oc.tipo = @ocorrenciaTipo48h AND DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao) > 48) OR 
			(oc.tipo = @ocorrenciaTipo12h AND DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao) > 12)
END
```

i. Indicar, para uma determinada área de intervenção, qual a empresa com maior número de ocorrências do tipo 
“crítico” que reportou ocorrências nessa área. 
```sql
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao 'Manutenção Extintores'
**/
CREATE PROCEDURE ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao  @areaIntervencao varchar(50) AS
BEGIN
	DECLARE @ocorrenciaTipo as varchar(7)
	SET @ocorrenciaTipo = 'crítico'
	SELECT MAX(e.designacao) AS EmpresaMaiorNrOcorrencias FROM AreaIntervencao ai
		INNER JOIN Trabalho AS t
			ON t.areaInt = ai.cod
		INNER JOIN Ocorrencia AS oc
			ON oc.id = t.idOcorr AND oc.tipo = @ocorrenciaTipo AND ai.designacao = @areaIntervencao
		INNER JOIN Empresa e
			ON e.nipc = oc.empresa
END
```

i. Versão 2 (Contempla empates, isto é, empresa com o mesmo número de ocorrências (máximas))
```sql
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencaoV2 'Manutenção Extintores'
**/
CREATE PROCEDURE ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencaoV2 @areaIntervencao VARCHAR(50) AS
BEGIN
	DECLARE @ocorrenciaTipo AS VARCHAR(7)
	SET @ocorrenciaTipo = 'crítico'

	SELECT e.designacao
		FROM (SELECT COUNT(idOcorr) AS countOC, oc.empresa AS Empresa
			FROM Trabalho T 
				INNER JOIN Ocorrencia OC ON oc.id=T.idOcorr AND oc.tipo = @ocorrenciaTipo 
				INNER JOIN AreaIntervencao ai ON ai.cod = T.areaInt AND ai.designacao = @areaIntervencao
			GROUP BY oc.empresa) AS myCount
				INNER JOIN Empresa e ON e.nipc = myCount.Empresa
					GROUP BY myCount.countOC, e.designacao 
					HAVING countOC = (SELECT MAX(MC.count1) 
										FROM (SELECT COUNT(idOcorr) count1, oc.empresa
												FROM Trabalho T 
													INNER JOIN Ocorrencia OC ON oc.id=T.idOcorr AND oc.tipo = 'crítico' 
													INNER JOIN AreaIntervencao ai ON ai.cod=T.areaInt AND ai.designacao = @areaIntervencao
												GROUP BY oc.empresa
												) AS MC
										)
END
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
