/************************************************
* Inserir um coordenador dummy. Isto é necessário se, quando é registada uma ocorrência, 
* é adicionada também a indicação das áreas de intervenção (inicialmente o trabalho 
* não terá coordenador associado). Alínea 3-b)
*************************************************/
Use SI2_1314v_TP;

insert into Funcionario (nome, dataNasc) values ('Dummy coordenador', '1980-1-1')

insert into Afecto values (2, 10, '2009', 1)