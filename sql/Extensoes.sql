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

--draft
/************************************************
* ALINEA 2.g
************************************************/
select oc.empresa, oc.tipo, count(oc.tipo) as nrOcorrTipo from Ocorrencia as oc
		inner join Empresa e
			on oc.empresa = e.nipc
		group by oc.tipo, oc.empresa

/************************************************
* ALINEA 2.h
************************************************/
	select *,  (DATEDIFF(second, oc.dhEntrada, oc.dhAlteracao) / 60 / 60) as hours from Ocorrencia oc
		where (oc.tipo = 'urgente' and (DATEDIFF(second, oc.dhEntrada, oc.dhAlteracao) / 60 / 60) > 48) or 
			(oc.tipo = 'crítico' and (DATEDIFF(second, oc.dhEntrada, oc.dhAlteracao) / 60 / 60) > 12)
			
/************************************************
* ALINEA 2.i
************************************************/
	declare @areaInt as varchar(50)
	set @areaInt = 'Manutenção Extintores'
	select max(e.designacao) as nrOcorr from AreaIntervencao ai
		inner join Trabalho as t
			on t.areaInt = ai.cod
		inner join Ocorrencia as oc
			on oc.id = t.idOcorr and oc.tipo = 'crítico' and ai.designacao = @areaInt
		inner join Empresa e
			on e.nipc = oc.empresa

/************************************************
* ALINEA 2.j
************************************************/
select fu.nome from Funcionario fu 
	left join
	(select f.num, f.nome, oc.tipo, count(oc.tipo) as NrOcorrencias from Ocorrencia oc 
		inner join Trabalho t
			on t.idOcorr = oc.id and oc.tipo = 'crítico'
		inner join Funcionario f
			on f.num = t.coordenador
		group by f.num, f.nome, oc.tipo
		having count(oc.tipo) > 0
	) as Oco
		on oco.num = fu.num 
	where oco.NrOcorrencias is null
