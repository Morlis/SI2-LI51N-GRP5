/************************************************
* Dados inciais para popular as tabelas
*************************************************/
Use SI2_1314v_TP;

insert into Empresa 
	select 600016234, 'Instituto Superior de Engenharia de Lisboa', 'Rua Conselheiro Emídio Navarro 1, 1959-007 Lisboa' union all
	select 501510184, 'Instituto Superior de Cienc. do Trab. e da Empresa', '1649-026 Lisboa' union all
	select 508899141, 'Instituto Superior Técnico', 'Avenida Rovisco Pais 1, 1049-001 Lisboa' union all
	select 502488603, 'Instituto Superior de Economia e Gestão', '1200-781 Lisboa' union all
	select 502855967, 'Idmec - Instituto de Engenharia Mecanica', '1049-001 Lisboa' union all
	select 509061168, 'Ite - Inst. de Ensino Sup. Cient. e Tec., SA', '1200-066 Lisboa'
	
insert into Localizacao
	select 'Av das Forças Armadas, 1649-026 Lisboa', '38.7478,-9.1534' union all
	select 'Rua do Quelhas 6, 1200-781 Lisboa', '38.7105,-9.1572' union all
	select 'Av. Rovisco Pais 1, 1049-001 Lisboa', '38.7374,-9.1373' union all
	select 'Av. Rovisco Pais 2, 1049-001 Lisboa', '38.7367,-9.139' union all
	select 'R. da Boavista, S 67-A a 67-D e 69 a 69-B', '38.7088,-9.1495' union all
	select 'R. Conselheiro Emídio Navarro 1, 1959-007 Lisboa', '38.7567,-9.1166'

insert into Instalacao (descricao, empresa, localizacao)
	select 'Anfitiatro Sul', 501510184, 1 union all
	select 'Auditório Alves dos Reis', 502488603, 2 union all
	select 'Oficina 21', 502855967, 3 union all
	select 'Salão Nobre', 508899141, 4 union all
	select 'Anfitiatro Norte', 509061168, 5 union all
	select 'Cantina', 600016234, 6

insert into Sector
	select 1, 1, 'A', '250 m^2', 1 union all
	select 2, -1, 'A', '500 m^2', 0 union all
	select 3, 0, 'C', '800 m^2', 1 union all
	select 4, 3, 'D', '1500 m^2', 1 union all
	select 5, -2, 'B', '50 m^2', 0 union all
	select 6, 1, 'E', '300 m^2', 0

insert into AreaIntervencao (designacao)
	select 'Assistência Técnica' union all
	select 'Manutenção Extintores' union all
	select 'Assistência de Elevadores' union all
	select 'Manutenção AVAC'

insert into Funcionario (nome, dataNasc)
	select 'Alves Redol', '1974-4-1' union all
	select 'Alves dos Reis', '1978-4-1' union all
	select 'Helder Conduto', '1979-4-1' union all
	select 'Jorge Prestrelo', '1978-4-1' union all
	select 'João Antunes', '1982-4-1' union all
	select 'Celso Conceição', '1980-4-1' union all
	select 'Rui António', '1981-4-1' union all
	select 'Marco Abrantes', '1981-4-1' union all
	select 'Toni Machado', '1983-4-1'

insert into Afecto
	select 1, 1, '1994', 1 union all
	select 2, 2, '1998', 1 union all
	select 3, 3, '1999', 1 union all
	select 4, 4, '1998', 1 union all
	select 1, 5, '2002', 0 union all
	select 2, 6, '2000', 0 union all
	select 3, 7, '2000', 0 union all
	select 4, 8, '2001', 0 union all
	select 4, 9, '2002', 0



insert into Ocorrencia (dhEntrada, dhAlteracao, tipo, codInst, piso, zona, empresa)
	select '2014-1-1 12:00:00', '2014-1-1 12:00:00', 'urgente', 1, 1, 'A', 501510184 union all
	select '2014-2-1 13:00:00', '2014-2-1 13:00:00', 'crítico', 2, -1, 'A', 502488603 union all
	select '2014-3-1 14:00:00', '2014-3-1 14:00:00', 'trivial', 3, 0, 'C', 502855967