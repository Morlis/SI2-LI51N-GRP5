/************************************************
* Inserir um coordenador dummy. Isto � necess�rio se, quando � registada uma ocorr�ncia, 
* � adicionada tamb�m a indica��o das �reas de interven��o (inicialmente o trabalho 
* n�o ter� coordenador associado). Al�nea 3-b)
*************************************************/
Use SI2_1314v_TP;

insert into Funcionario (nome, dataNasc) values ('Dummy coordenador', '1980-1-1')

insert into Afecto values (2, 10, '2009', 1)