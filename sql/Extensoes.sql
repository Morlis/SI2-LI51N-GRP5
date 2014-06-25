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
if(OBJECT_ID('ListarTotalOcorrenciaDasEmpresas', 'P') is not null) DROP PROCEDURE ListarTotalOcorrenciaDasEmpresas
if(OBJECT_ID('ListarOcorrenciasEmIncumprimento', 'P') is not null) DROP PROCEDURE ListarOcorrenciasEmIncumprimento
if(OBJECT_ID('ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao', 'P') is not null) DROP PROCEDURE ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao
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

/************************************************
* ALINEA 2.d
************************************************/
/**
* Não necessita de uma transação.
* So cancela Ocourrencias em estado 'inicial' ou 'em processamento'
* Exemplo:
* Exec CancelarOcorrencia 3
**/
CREATE PROCEDURE CancelarOcorrencia @id int AS
BEGIN
	UPDATE Ocorrencia SET estado='cancelado' WHERE id=@id AND (estado='inicial' OR estado='em processamento')
END
GO

-- VALIDAR


/************************************************
* ALINEA 2.g
************************************************/
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
GO

/************************************************
* ALINEA 2.h
************************************************/
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

	SELECT *,  (DATEDIFF(SECOND, oc.dhEntrada, oc.dhAlteracao) / 60 / 60) AS HOURS FROM Ocorrencia oc
		WHERE (oc.tipo = 'urgente' AND (DATEDIFF(SECOND, oc.dhEntrada, oc.dhAlteracao) / 60 / 60) > 48) OR 
			(oc.tipo = 'crítico' AND (DATEDIFF(SECOND, oc.dhEntrada, oc.dhAlteracao) / 60 / 60) > 12)
END
GO
			
/************************************************
* ALINEA 2.i
************************************************/
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
