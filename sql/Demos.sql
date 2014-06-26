/************************************************
* Demos
************************************************/
Use SI2_1314v_TP;

/************************************************
* ALINEA 2.a
************************************************/
EXEC InserirEmpresa 600016234, 'Instituto Superior de Engenharia de Lisboa', 'Rua Conselheiro Emídio Navarro 1, 1959-007 Lisboa'

DECLARE @AreaID int
EXEC InserirAreaIntervencao @AreaID OUT, 'Assistência Técnica'

/************************************************
* ALINEA 2.b
************************************************/
EXEC EditarEmpresa 600016234, 'Instituto Superior de Engenharia de Lisboa', 'Rua Conselheiro Emídio Navarro 1, 1959-007 Lisboa'

/************************************************
* ALINEA 2.c
************************************************/
/* Verificar disparo do gatilho (Ocorrencia_alterada) quando uma Ocorrencia e alterada */
DECLARE @OcorID int
EXEC ReportarOcorrencia 'trivial', 501510184, 1, 1, 'A', @OcorID OUT

/************************************************
* ALINEA 2.d
************************************************/
EXEC CancelarOcorrencia 3

/************************************************
* ALINEA 2.e
************************************************/
TODO (CM)

/************************************************
* ALINEA 2.f
************************************************/
TODO (CM)

/************************************************
* ALINEA 2.g
************************************************/
EXEC ListarTotalOcorrenciaDasEmpresas

/************************************************
* ALINEA 2.h
************************************************/
EXEC ListarOcorrenciasEmIncumprimento

/************************************************
* ALINEA 2.i
************************************************/
EXEC ListarEmpresaMaiorNrOcorrenciasCriticasParaCertaAreaIntervencao 'Manutenção Extintores'

/************************************************
* ALINEA 2.j
************************************************/
EXEC ListarFuncionariosCoordenadoresSemOcorrenciasCriticas

/************************************************
* ALINEA 2.k
************************************************/
