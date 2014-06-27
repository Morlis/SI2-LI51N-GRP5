/************************************************
* Extensões a modelo inícial
* - Vistas
* - Funções
* - Procedimentos armazenados
* - Gatilhos
************************************************/
Use SI2_1314v_TP;

if(OBJECT_ID('InserirEmpresa', 'P') is not null) DROP PROCEDURE InserirEmpresa
if(OBJECT_ID('EditarEmpresa', 'P') is not null) DROP PROCEDURE EditarEmpresa
if(OBJECT_ID('InserirAreaIntervencao', 'P') is not null) DROP PROCEDURE InserirAreaIntervencao
if(OBJECTPROPERTY(OBJECT_ID('Ocorrencia_alterada'), 'IsTrigger') = 1) DROP TRIGGER Ocorrencia_alterada
if(OBJECT_ID('ReportarOcorrencia', 'P') is not null) DROP PROCEDURE ReportarOcorrencia
if(OBJECT_ID('CancelarOcorrencia', 'P') is not null) DROP PROCEDURE CancelarOcorrencia
if(OBJECT_ID('AssignarOcorrencia', 'P') is not null) DROP PROCEDURE AssignarOcorrencia
IF OBJECT_ID('FuncionarioComMenosOcorrenciasActivas') IS NOT NULL DROP FUNCTION FuncionarioComMenosOcorrenciasActivas
if(OBJECT_ID('TotalOcorrenciaPorEmpresaPorTipo', 'V') is not null) DROP VIEW TotalOcorrenciaPorEmpresaPorTipo
if(OBJECT_ID('OcorrenciasEmIncumprimento', 'V') is not null) DROP VIEW OcorrenciasEmIncumprimento
if(OBJECT_ID('ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao', 'P') is not null) DROP PROCEDURE ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao
if(OBJECT_ID('ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencaoV2', 'P') is not null) DROP PROCEDURE ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencaoV2
if(OBJECT_ID('ListarFuncionariosCoordenadoresSemOcorrenciasCriticas', 'P') is not null) DROP PROCEDURE ListarFuncionariosCoordenadoresSemOcorrenciasCriticas

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

/************************************************
* ALINEA 2.f
************************************************/

-- EM FALTA

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
		WHERE (oc.tipo = 'urgente' AND DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao) > 48) OR 
			(oc.tipo = 'crítico' AND DATEDIFF(HOUR, oc.dhEntrada, oc.dhAlteracao) > 12)
GO
			
/************************************************
* ALINEA 2.i
************************************************/
/**
* Não necessita de uma transação.
* Exemplo:
* EXEC ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao 'Manutenção Extintores'
**/
CREATE PROCEDURE ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao  @areaIntervencao VARCHAR(50) AS
BEGIN
	DECLARE @ocorrenciaTipo AS VARCHAR(7)
	SET @ocorrenciaTipo = 'crítico'
	SELECT MAX(e.designacao) AS EmpresaMaiorNrOcorrencias FROM AreaIntervencao ai
		INNER JOIN Trabalho AS t
			ON t.areaInt = ai.cod
		INNER JOIN Ocorrencia AS oc
			ON oc.id = t.idOcorr AND oc.tipo = @ocorrenciaTipo AND ai.designacao = @areaIntervencao
		INNER JOIN Empresa e
			ON e.nipc = oc.empresa
END
GO

/************************************************
* ALINEA 2.i (Versão 2)
* Contempla empates, isto é, empresa com o mesmo número de ocorrências (máximas)
************************************************/
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
