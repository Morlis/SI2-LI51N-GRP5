/************************************************
* Extensões a modelo inícial
* - Sequências
* - Vistas
* - Funções
* - Procedimentos armazenados
* - Gatilhos
************************************************/
Use SI2_1314v_TP;

if(OBJECT_ID('FuncionarioCod') is not null) DROP SEQUENCE FuncionarioCod;

-- Sequencia para Funcionario campo [num]
CREATE SEQUENCE dbo.FuncionarioCod
	AS int
	START WITH 1
	INCREMENT BY 1;
