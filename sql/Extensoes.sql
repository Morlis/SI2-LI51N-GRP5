/************************************************
* Extensões a modelo inícial
* - Vistas
* - Funções
* - Procedimentos armazenados
* - Gatilhos
************************************************/
Use SI2_1314v_TP;

if(OBJECTPROPERTY(OBJECT_ID('CheckMaxAreasIntPorOcorrencia'), 'IsTrigger') = 1) DROP TRIGGER CheckMaxAreasIntPorOcorrencia
if(OBJECT_ID('InserirEmpresa', 'P') is not null) DROP PROCEDURE InserirEmpresa
if(OBJECT_ID('EditarEmpresa', 'P') is not null) DROP PROCEDURE EditarEmpresa
if(OBJECT_ID('InserirAreaIntervencao', 'P') is not null) DROP PROCEDURE InserirAreaIntervencao
if(OBJECTPROPERTY(OBJECT_ID('Ocorrencia_alterada'), 'IsTrigger') = 1) DROP TRIGGER Ocorrencia_alterada
if(OBJECT_ID('ReportarOcorrencia', 'P') is not null) DROP PROCEDURE ReportarOcorrencia
if(OBJECT_ID('CancelarOcorrencia', 'P') is not null) DROP PROCEDURE CancelarOcorrencia
if(OBJECT_ID('AssignarOcorrencia', 'P') is not null) DROP PROCEDURE AssignarOcorrencia
if(OBJECT_ID('numTrabalhosEmCursoPorOcorrencia') is not null) DROP FUNCTION numTrabalhosEmCursoPorOcorrencia
if(OBJECTPROPERTY(OBJECT_ID('conclusãoTrabalhoAreaIntervencao'), 'IsTrigger') = 1) DROP TRIGGER conclusãoTrabalhoAreaIntervencao
if OBJECT_ID('FuncionarioComMenosOcorrenciasActivas') IS NOT NULL DROP FUNCTION FuncionarioComMenosOcorrenciasActivas
if(OBJECT_ID('TotalOcorrenciaPorEmpresaPorTipo', 'V') is not null) DROP VIEW TotalOcorrenciaPorEmpresaPorTipo
if(OBJECT_ID('OcorrenciasEmIncumprimento', 'V') is not null) DROP VIEW OcorrenciasEmIncumprimento
if OBJECT_ID('ObterEmpresaComMaxCritoOcorrPorAreaInt') IS NOT NULL DROP FUNCTION ObterEmpresaComMaxCritoOcorrPorAreaInt
if(OBJECT_ID('ListarFuncionariosCoordenadoresSemOcorrenciasCriticas', 'P') is not null) DROP PROCEDURE ListarFuncionariosCoordenadoresSemOcorrenciasCriticas
IF(OBJECT_ID('processarPontosPorIncumprimento', 'P') IS NOT NULL) DROP PROCEDURE processarPontosPorIncumprimento
IF(OBJECT_ID('obterPontosPorEmpresa') IS NOT NULL) DROP FUNCTION obterPontosPorEmpresa
IF(OBJECT_ID('registoIncumprimento') IS NOT NULL) DROP TABLE registoIncumprimento



GO

/************************************************
* Garante que não haverá mais do que 3 Areas de Intervenção por Ocorrencia
************************************************/
CREATE TRIGGER CheckMaxAreasIntPorOcorrencia ON Trabalho INSTEAD OF INSERT
AS
BEGIN
	SET XACT_ABORT ON
	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @NumAreas INT, @idOcorr INT		
		SET @idOcorr = (SELECT idOcorr from inserted)
		SELECT @NumAreas = (SELECT COUNT(*) FROM Trabalho WHERE idOcorr = @idOcorr)
		IF @NumAreas = 3 
		BEGIN
			RAISERROR ('MAXIMO DE 3 ÁREAS DE INTERVENÇÃO POR OCORRENCIA',16 ,1)
		END 
		INSERT INTO Trabalho SELECT * FROM inserted
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
	END CATCH
END
GO

/************************************************
* ALINEA 2.a
************************************************/
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

/************************************************
* ALINEA 2.b
************************************************/
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

/************************************************
* ALINEA 2.c
************************************************/
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

/************************************************
* ALINEA 2.d
************************************************/
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

/************************************************
* ALINEA 2.e
************************************************/
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
				-- Assignar um coordenador a todos os trabalhos desta Ocorrencia
				UPDATE Trabalho SET coordenador=dbo.FuncionarioComMenosOcorrenciasActivas(areaInt) WHERE Trabalho.idOcorr=@id
				UPDATE Ocorrencia SET estado='em resolução' WHERE id=@id
			END
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
	END CATCH
END
GO

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

/************************************************
* ALINEA 2.g
************************************************/
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

/************************************************
* ALINEA 2.h
************************************************/
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
			
/************************************************
* ALINEA 2.i
************************************************/
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

/************************************************
* ALINEA 2.j
************************************************/
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

/************************************************
* ALINEA 2.k
************************************************/
/**
* Transação: A discutir
* Usa a View criada na alinea 2.h (ocorrenciasEmIncumprimento)
* Estratégia: Se não exisitr, criar tabela de registos de Ocorrencias em Incumprimento, e inserir registos conforme o estado das ocorrencias, 
* desde que não exista duplicação
* O procedimento processarPontosPorIncumprimento realiza o processo indicado na linha acima.
* A Função obterPontosPorEmpresa permite obter o numero de pontos por empresa.
* Exemplo:
* EXEC processarPontosPorIncumprimento
**/

CREATE PROCEDURE processarPontosPorIncumprimento AS 
BEGIN
	IF(OBJECT_ID('registoIncumprimento') is null) 
		CREATE TABLE registoIncumprimento(
		idOcorr int references Ocorrencia,
		dhProcessamento datetime not null DEFAULT GETDATE()
		)
	INSERT INTO registoIncumprimento(idOcorr)
		SELECT id FROM OcorrenciasEmIncumprimento WHERE id NOT IN (SELECT idOcorr FROM registoIncumprimento)
END
GO

CREATE FUNCTION dbo.obterPontosPorEmpresa(@empresa INT) RETURNS int AS
BEGIN
	RETURN (SELECT COUNT(*) 
		FROM registoIncumprimento INNER JOIN Ocorrencia
		ON registoIncumprimento.idOcorr = Ocorrencia.id
		WHERE Ocorrencia.empresa = @empresa)
END
GO

