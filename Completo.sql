/*
Projeto e Implementação de Banco de Dados
Professora Marcela Xavier

Guilherme Vilar Balduino 743546
Lucas Heidy T. Garcia 743565
*/

/* Esquema Relacional

categoria(id_cat(key), nome)

estabelecimento(cnpj(key), cidade, nome)

cliente(id_c(key), nome, data_nasc, rg, email, preferancia)
	preferancia ref. categoria.id_cat

jogo(id_j(key), preco, tipo, nome, categoria)
	categoria ref. categoria.id_cat
	
compra(id_compra(key), id_jt, id_ct, id_et, valor)
	id_jt ref jogo.id_j
	id_ct ref cliente.id_c
	id_et ref estabelecimento.id_e

trocaPreco(id_j), velho, novo, datat)

trocaPref(id_c), velho, novo, datat)
	
*/


create table Categoria (
ID_Cat integer primary key,
nome varchar(50)
);

create table Cliente (
	ID_C integer primary key,
	nome varchar(50),
	data_nasc date,
	rg integer,
	email varchar(50),
	preferencia integer,
	constraint fkcc foreign key(preferencia) references Categoria(ID_Cat)
);

create table Estabelecimento(
CNPJ integer primary key, 
cidade varchar(50),
nome varchar(50)
);

create table Jogo(
	ID_J integer primary key,
	preco float,	
	tipo varchar(50),
	nome varchar(50),
	categoria integer,
	constraint fkc foreign key (categoria) references Categoria(ID_Cat)
);


create table Compra(
	ID_Compra integer primary key,
	ID_JT integer,
	ID_CT integer,
	ID_ET integer,
	valor float,
	
	constraint fkjt foreign key (ID_JT) references Jogo(ID_J),
	constraint fkct foreign key (ID_CT) references Cliente(ID_C),
	constraint fket foreign key (ID_ET) references Estabelecimento(CNPJ)
);


create table Trocapreco(
	ID_J integer,
	velho float,
	novo float,
	datat timestamp
);

create table Trocapref(
	ID_C integer,
	velho float,
	novo float,
	datat timestamp
	
);

/* Lista todos os jogos*/
create or replace function listaJogos()
	returns text as $$ 
	declare
		saida text default'';
		cjogo JOGO%ROWTYPE;
		cursorJogo cursor for select * from Jogo;
	begin
		open cursorJogo;
		loop
			fetch cursorJogo into cjogo;
			exit when not found;
			saida := saida||', '||cjogo.nome;
		end loop;
		close cursorJogo;
		return saida;
	end; 
$$ LANGUAGE 'plpgsql';

/* Lista todos os clientes*/
create or replace function listaClientes()
	returns text as $$ 
	declare
		saida text default'';
		ccliente Cliente%ROWTYPE;
		cursorCliente cursor for select * from cliente;
	begin
		open cursorCliente;
		loop
			fetch cursorCliente into ccliente;
			exit when not found;
			saida := saida||', '||ccliente.nome;
		end loop;
		close cursorCliente;
		return saida;
	end; 
$$ LANGUAGE 'plpgsql';
	
/* Atualiza preco de um jogo*/
create or replace procedure update_preco(integer, float)
	as $$
	begin
		update jogo
		set preco = $2
		where ID_J = $1;
	end;	
$$ LANGUAGE 'plpgsql';

/* Atualiza preferencia de um cliente*/
create or replace procedure update_pref(integer, integer)
	as $$
	begin
		update cliente
		set preferencia = $2
		where ID_C = $1;
	end;	
$$ LANGUAGE 'plpgsql';

create or replace procedure renomeiaEstabelecimento(integer, varchar(50))

	as $$
	begin
		update estabelecimento
		set nome = $2
		where CNPJ = $1;
	end;
		
$$ LANGUAGE 'plpgsql';

/* Insere uma compra*/
create or replace function InsereCompra(ID_Compra integer,
ID_JT integer, ID_CT integer, ID_ET integer)

      returns void as $$
	  	declare
			descc float;
		begin
			if ncompras_categoria_cliente(ID_CT, jogo_cat(ID_JT)) = 0 or jogo_cat(ID_CT) <> cliente_pref(ID_CT)  then
				descc = 0;
			else 
				if ncompras_categoria_cliente(ID_CT, jogo_cat(ID_JT)) < 20 then
					descc = 0.4 - (0.02 * (20 - ncompras_categoria_cliente(ID_CT, jogo_cat(ID_JT))));
				else
					descc = 0.4;
				end if;
			end if;	

			insert into Compra values (ID_Compra, ID_JT, ID_CT, ID_ET, jogo_preco(ID_JT) * (1 - descc));
      end;
      $$ LANGUAGE 'plpgsql';


/* Coloca em uma tabela a mudanca de preferancia de um cliente*/
create or replace function preflog() returns trigger as $logtrigger$
	begin
		
		insert into trocaPref values(old.ID_C, old.preferencia, new.preferencia, localtimestamp);
		return new;
		end;
		$logtrigger$ language plpgsql;
		
create trigger logpreftrigger
	before update of preferencia on cliente 
	for each row execute procedure preflog();
	
/* Coloca em uma tabela a mudanca de preco de um jogo*/
create or replace function precolog() returns trigger as $logtrigger$
	begin
		
		insert into trocaPreco values(old.ID_J, old.preco, new.preco, localtimestamp);
		return new;
		end;
		$logtrigger$ language plpgsql;
		
create trigger logprecotrigger
	before update of preco on jogo
	for each row execute procedure precolog();


/* Retorna o numero de compras de um cliente em uma categoria*/
create or replace function ncompras_categoria_cliente(integer,integer)
returns integer AS $n$
declare
	n integer;
begin
   select count(*) into n from Compra c join Jogo j on (c.ID_JT = j.ID_J) where ID_CT = $1 AND j.Categoria = $2;
   return n;
end;

$n$ language plpgsql;

/* Retorna o id da categoria do jogo passado*/
create or replace function jogo_cat(integer)
returns integer AS $id_cat$
declare
	id_cat integer;
begin
   select categoria into id_cat from jogo where ID_J = $1;
   return id_cat;
end;
$id_cat$ language plpgsql;

/* Retorna o preco do jogo passado*/
create or replace function jogo_preco(integer)
returns integer AS $j_preco$
declare
	j_preco integer;
begin
   select preco into j_preco from jogo where ID_J = $1;
   return j_preco;
end;
$j_preco$ language plpgsql;

/* Retorna a preferancia do cliente*/
create or replace function cliente_pref(integer)
returns integer AS $c_pref$
declare
	c_pref integer;
begin
   select preferencia into c_pref from Cliente where ID_C = $1;
   return c_pref;
end;
$c_pref$ language plpgsql;

/* Consultas no final do arquivo junto com seus respectivos explain e os drops*/

 insert into categoria values(1, 'Estrategia');
 insert into categoria values(2, 'Corrida');
 insert into categoria values(3, 'RPG');
 insert into categoria values(4, 'Aventura');
 insert into categoria values(5, 'Luta');
 insert into categoria values(6, 'Acao');
 insert into categoria values(7, 'Esporte');
 insert into categoria values(8, 'Tiro');
 insert into categoria values(9, 'Simulacao');
 insert into categoria values(10, 'Plataforma');
 insert into categoria values(11, 'Sandbox');
 insert into categoria values(12, 'Mundo Aberto');
 insert into categoria values(13, 'MOBA');
 insert into categoria values(14, 'Horror');
 insert into categoria values(15, 'Puzzles');
 
 
 insert into estabelecimento values (1, '100', 'Super Heidy Digital');
insert into estabelecimento values (2, '32', 'Super Heidy Reboot');
insert into estabelecimento values (3, '97', 'Super Heidy Remake');
insert into estabelecimento values (4, '14', 'Super Heidy 2');
insert into estabelecimento values (5, '89', 'Super Heidy Jogos');
insert into estabelecimento values (6, '61', 'Super Heidy 3');
insert into estabelecimento values (7, '52', 'Super Heidy 4');
insert into estabelecimento values (8, '58', 'Super Goku Digital');
insert into estabelecimento values (9, '10', 'Super Goku Reboot');
insert into estabelecimento values (10, '78', 'Super Goku Remake');
insert into estabelecimento values (11, '12', 'Super Goku 2');
insert into estabelecimento values (12, '8', 'Super Goku Jogos');
insert into estabelecimento values (13, '70', 'Super Goku 3');
insert into estabelecimento values (14, '63', 'Super Goku 4');
insert into estabelecimento values (15, '87', 'Super Agumon Digital');
insert into estabelecimento values (16, '41', 'Super Agumon Reboot');
insert into estabelecimento values (17, '49', 'Super Agumon Remake');
insert into estabelecimento values (18, '42', 'Super Agumon 2');
insert into estabelecimento values (19, '88', 'Super Agumon Jogos');
insert into estabelecimento values (20, '3', 'Super Agumon 3');
insert into estabelecimento values (21, '37', 'Super Agumon 4');
insert into estabelecimento values (22, '90', 'Super Pikachu Digital');
insert into estabelecimento values (23, '76', 'Super Pikachu Reboot');
insert into estabelecimento values (24, '7', 'Super Pikachu Remake');
insert into estabelecimento values (25, '49', 'Super Pikachu 2');
insert into estabelecimento values (26, '9', 'Super Pikachu Jogos');
insert into estabelecimento values (27, '32', 'Super Pikachu 3');
insert into estabelecimento values (28, '49', 'Super Pikachu 4');
insert into estabelecimento values (29, '24', 'Super Kirito Digital');
insert into estabelecimento values (30, '11', 'Super Kirito Reboot');
insert into estabelecimento values (31, '64', 'Super Kirito Remake');
insert into estabelecimento values (32, '44', 'Super Kirito 2');
insert into estabelecimento values (33, '18', 'Super Kirito Jogos');
insert into estabelecimento values (34, '32', 'Super Kirito 3');
insert into estabelecimento values (35, '83', 'Super Kirito 4');
insert into estabelecimento values (36, '45', 'Incrivel Heidy Digital');
insert into estabelecimento values (37, '16', 'Incrivel Heidy Reboot');
insert into estabelecimento values (38, '74', 'Incrivel Heidy Remake');
insert into estabelecimento values (39, '13', 'Incrivel Heidy 2');
insert into estabelecimento values (40, '56', 'Incrivel Heidy Jogos');
insert into estabelecimento values (41, '10', 'Incrivel Heidy 3');
insert into estabelecimento values (42, '52', 'Incrivel Heidy 4');
insert into estabelecimento values (43, '75', 'Incrivel Goku Digital');
insert into estabelecimento values (44, '1', 'Incrivel Goku Reboot');
insert into estabelecimento values (45, '89', 'Incrivel Goku Remake');
insert into estabelecimento values (46, '82', 'Incrivel Goku 2');
insert into estabelecimento values (47, '39', 'Incrivel Goku Jogos');
insert into estabelecimento values (48, '41', 'Incrivel Goku 3');
insert into estabelecimento values (49, '49', 'Incrivel Goku 4');
insert into estabelecimento values (50, '88', 'Incrivel Agumon Digital');
insert into estabelecimento values (51, '46', 'Incrivel Agumon Reboot');
insert into estabelecimento values (52, '78', 'Incrivel Agumon Remake');
insert into estabelecimento values (53, '37', 'Incrivel Agumon 2');
insert into estabelecimento values (54, '87', 'Incrivel Agumon Jogos');
insert into estabelecimento values (55, '29', 'Incrivel Agumon 3');
insert into estabelecimento values (56, '56', 'Incrivel Agumon 4');
insert into estabelecimento values (57, '99', 'Incrivel Pikachu Digital');
insert into estabelecimento values (58, '90', 'Incrivel Pikachu Reboot');
insert into estabelecimento values (59, '5', 'Incrivel Pikachu Remake');
insert into estabelecimento values (60, '5', 'Incrivel Pikachu 2');
insert into estabelecimento values (61, '41', 'Incrivel Pikachu Jogos');
insert into estabelecimento values (62, '6', 'Incrivel Pikachu 3');
insert into estabelecimento values (63, '11', 'Incrivel Pikachu 4');
insert into estabelecimento values (64, '9', 'Incrivel Kirito Digital');
insert into estabelecimento values (65, '37', 'Incrivel Kirito Reboot');
insert into estabelecimento values (66, '24', 'Incrivel Kirito Remake');
insert into estabelecimento values (67, '99', 'Incrivel Kirito 2');
insert into estabelecimento values (68, '5', 'Incrivel Kirito Jogos');
insert into estabelecimento values (69, '64', 'Incrivel Kirito 3');
insert into estabelecimento values (70, '83', 'Incrivel Kirito 4');
insert into estabelecimento values (71, '84', 'Max Heidy Digital');
insert into estabelecimento values (72, '95', 'Max Heidy Reboot');
insert into estabelecimento values (73, '21', 'Max Heidy Remake');
insert into estabelecimento values (74, '88', 'Max Heidy 2');
insert into estabelecimento values (75, '16', 'Max Heidy Jogos');
insert into estabelecimento values (76, '35', 'Max Heidy 3');
insert into estabelecimento values (77, '93', 'Max Heidy 4');
insert into estabelecimento values (78, '10', 'Max Goku Digital');
insert into estabelecimento values (79, '79', 'Max Goku Reboot');
insert into estabelecimento values (80, '67', 'Max Goku Remake');
insert into estabelecimento values (81, '55', 'Max Goku 2');
insert into estabelecimento values (82, '64', 'Max Goku Jogos');
insert into estabelecimento values (83, '47', 'Max Goku 3');
insert into estabelecimento values (84, '24', 'Max Goku 4');
insert into estabelecimento values (85, '74', 'Max Agumon Digital');
insert into estabelecimento values (86, '20', 'Max Agumon Reboot');
insert into estabelecimento values (87, '87', 'Max Agumon Remake');
insert into estabelecimento values (88, '72', 'Max Agumon 2');
insert into estabelecimento values (89, '93', 'Max Agumon Jogos');
insert into estabelecimento values (90, '90', 'Max Agumon 3');
insert into estabelecimento values (91, '55', 'Max Agumon 4');
insert into estabelecimento values (92, '88', 'Max Pikachu Digital');
insert into estabelecimento values (93, '53', 'Max Pikachu Reboot');
insert into estabelecimento values (94, '46', 'Max Pikachu Remake');
insert into estabelecimento values (95, '34', 'Max Pikachu 2');
insert into estabelecimento values (96, '83', 'Max Pikachu Jogos');
insert into estabelecimento values (97, '76', 'Max Pikachu 3');
insert into estabelecimento values (98, '41', 'Max Pikachu 4');
insert into estabelecimento values (99, '13', 'Max Kirito Digital');
insert into estabelecimento values (100, '65', 'Max Kirito Reboot');
insert into estabelecimento values (101, '48', 'Max Kirito Remake');
insert into estabelecimento values (102, '42', 'Max Kirito 2');
insert into estabelecimento values (103, '99', 'Max Kirito Jogos');
insert into estabelecimento values (104, '7', 'Max Kirito 3');
insert into estabelecimento values (105, '83', 'Max Kirito 4');
insert into estabelecimento values (106, '69', 'Mega Heidy Digital');
insert into estabelecimento values (107, '93', 'Mega Heidy Reboot');
insert into estabelecimento values (108, '94', 'Mega Heidy Remake');
insert into estabelecimento values (109, '61', 'Mega Heidy 2');
insert into estabelecimento values (110, '74', 'Mega Heidy Jogos');
insert into estabelecimento values (111, '21', 'Mega Heidy 3');
insert into estabelecimento values (112, '84', 'Mega Heidy 4');
insert into estabelecimento values (113, '28', 'Mega Goku Digital');
insert into estabelecimento values (114, '42', 'Mega Goku Reboot');
insert into estabelecimento values (115, '62', 'Mega Goku Remake');
insert into estabelecimento values (116, '78', 'Mega Goku 2');
insert into estabelecimento values (117, '86', 'Mega Goku Jogos');
insert into estabelecimento values (118, '17', 'Mega Goku 3');
insert into estabelecimento values (119, '50', 'Mega Goku 4');
insert into estabelecimento values (120, '34', 'Mega Agumon Digital');
insert into estabelecimento values (121, '11', 'Mega Agumon Reboot');
insert into estabelecimento values (122, '1', 'Mega Agumon Remake');
insert into estabelecimento values (123, '69', 'Mega Agumon 2');
insert into estabelecimento values (124, '40', 'Mega Agumon Jogos');
insert into estabelecimento values (125, '21', 'Mega Agumon 3');
insert into estabelecimento values (126, '68', 'Mega Agumon 4');
insert into estabelecimento values (127, '61', 'Mega Pikachu Digital');
insert into estabelecimento values (128, '69', 'Mega Pikachu Reboot');
insert into estabelecimento values (129, '8', 'Mega Pikachu Remake');
insert into estabelecimento values (130, '100', 'Mega Pikachu 2');
insert into estabelecimento values (131, '6', 'Mega Pikachu Jogos');
insert into estabelecimento values (132, '29', 'Mega Pikachu 3');
insert into estabelecimento values (133, '7', 'Mega Pikachu 4');
insert into estabelecimento values (134, '35', 'Mega Kirito Digital');
insert into estabelecimento values (135, '55', 'Mega Kirito Reboot');
insert into estabelecimento values (136, '29', 'Mega Kirito Remake');
insert into estabelecimento values (137, '3', 'Mega Kirito 2');
insert into estabelecimento values (138, '50', 'Mega Kirito Jogos');
insert into estabelecimento values (139, '58', 'Mega Kirito 3');
insert into estabelecimento values (140, '79', 'Mega Kirito 4');
insert into estabelecimento values (141, '23', 'Ultimate Heidy Digital');
insert into estabelecimento values (142, '84', 'Ultimate Heidy Reboot');
insert into estabelecimento values (143, '24', 'Ultimate Heidy Remake');
insert into estabelecimento values (144, '99', 'Ultimate Heidy 2');
insert into estabelecimento values (145, '53', 'Ultimate Heidy Jogos');
insert into estabelecimento values (146, '18', 'Ultimate Heidy 3');
insert into estabelecimento values (147, '11', 'Ultimate Heidy 4');
insert into estabelecimento values (148, '23', 'Ultimate Goku Digital');
insert into estabelecimento values (149, '26', 'Ultimate Goku Reboot');
insert into estabelecimento values (150, '25', 'Ultimate Goku Remake');
insert into estabelecimento values (151, '80', 'Ultimate Goku 2');
insert into estabelecimento values (152, '72', 'Ultimate Goku Jogos');
insert into estabelecimento values (153, '60', 'Ultimate Goku 3');
insert into estabelecimento values (154, '41', 'Ultimate Goku 4');
insert into estabelecimento values (155, '76', 'Ultimate Agumon Digital');
insert into estabelecimento values (156, '66', 'Ultimate Agumon Reboot');
insert into estabelecimento values (157, '8', 'Ultimate Agumon Remake');
insert into estabelecimento values (158, '98', 'Ultimate Agumon 2');
insert into estabelecimento values (159, '29', 'Ultimate Agumon Jogos');
insert into estabelecimento values (160, '1', 'Ultimate Agumon 3');
insert into estabelecimento values (161, '14', 'Ultimate Agumon 4');
insert into estabelecimento values (162, '53', 'Ultimate Pikachu Digital');
insert into estabelecimento values (163, '54', 'Ultimate Pikachu Reboot');
insert into estabelecimento values (164, '63', 'Ultimate Pikachu Remake');
insert into estabelecimento values (165, '80', 'Ultimate Pikachu 2');
insert into estabelecimento values (166, '90', 'Ultimate Pikachu Jogos');
insert into estabelecimento values (167, '72', 'Ultimate Pikachu 3');
insert into estabelecimento values (168, '75', 'Ultimate Pikachu 4');
insert into estabelecimento values (169, '80', 'Ultimate Kirito Digital');
insert into estabelecimento values (170, '37', 'Ultimate Kirito Reboot');
insert into estabelecimento values (171, '96', 'Ultimate Kirito Remake');
insert into estabelecimento values (172, '77', 'Ultimate Kirito 2');
insert into estabelecimento values (173, '91', 'Ultimate Kirito Jogos');
insert into estabelecimento values (174, '65', 'Ultimate Kirito 3');
insert into estabelecimento values (175, '95', 'Ultimate Kirito 4');

 
insert into cliente values (1, 'Guilherme Vilar Balduino', TO_DATE('9/3/98', 'dd/mm/yy'),1, '1@gmail.com', '3');
insert into cliente values (2, 'Guilherme Vilar Chu Ann', TO_DATE('12/6/98', 'dd/mm/yy'),2, '2@gmail.com', '8');
insert into cliente values (3, 'Guilherme Vilar Samara', TO_DATE('9/10/98', 'dd/mm/yy'),3, '3@gmail.com', '6');
insert into cliente values (4, 'Guilherme Vilar Prates', TO_DATE('10/4/98', 'dd/mm/yy'),4, '4@gmail.com', '12');
insert into cliente values (5, 'Guilherme Vilar Villani', TO_DATE('1/5/98', 'dd/mm/yy'),5, '5@gmail.com', '15');
insert into cliente values (6, 'Guilherme Vilar Souza', TO_DATE('3/8/98', 'dd/mm/yy'),6, '6@gmail.com', '5');
insert into cliente values (7, 'Guilherme Heidy Balduino', TO_DATE('11/12/98', 'dd/mm/yy'),7, '7@gmail.com', '12');
insert into cliente values (8, 'Guilherme Heidy Chu Ann', TO_DATE('7/8/98', 'dd/mm/yy'),8, '8@gmail.com', '2');
insert into cliente values (9, 'Guilherme Heidy Samara', TO_DATE('3/6/98', 'dd/mm/yy'),9, '9@gmail.com', '8');
insert into cliente values (10, 'Guilherme Heidy Prates', TO_DATE('12/10/98', 'dd/mm/yy'),10, '10@gmail.com', '7');
insert into cliente values (11, 'Guilherme Heidy Villani', TO_DATE('12/5/98', 'dd/mm/yy'),11, '11@gmail.com', '1');
insert into cliente values (12, 'Guilherme Heidy Souza', TO_DATE('11/11/98', 'dd/mm/yy'),12, '12@gmail.com', '14');
insert into cliente values (13, 'Guilherme Tai Chi Balduino', TO_DATE('2/3/98', 'dd/mm/yy'),13, '13@gmail.com', '8');
insert into cliente values (14, 'Guilherme Tai Chi Chu Ann', TO_DATE('5/8/98', 'dd/mm/yy'),14, '14@gmail.com', '11');
insert into cliente values (15, 'Guilherme Tai Chi Samara', TO_DATE('12/2/98', 'dd/mm/yy'),15, '15@gmail.com', '6');
insert into cliente values (16, 'Guilherme Tai Chi Prates', TO_DATE('12/8/98', 'dd/mm/yy'),16, '16@gmail.com', '11');
insert into cliente values (17, 'Guilherme Tai Chi Villani', TO_DATE('6/6/98', 'dd/mm/yy'),17, '17@gmail.com', '8');
insert into cliente values (18, 'Guilherme Tai Chi Souza', TO_DATE('11/3/98', 'dd/mm/yy'),18, '18@gmail.com', '4');
insert into cliente values (19, 'Guilherme Barros Balduino', TO_DATE('4/12/98', 'dd/mm/yy'),19, '19@gmail.com', '1');
insert into cliente values (20, 'Guilherme Barros Chu Ann', TO_DATE('7/1/98', 'dd/mm/yy'),20, '20@gmail.com', '13');
insert into cliente values (21, 'Guilherme Barros Samara', TO_DATE('7/9/98', 'dd/mm/yy'),21, '21@gmail.com', '15');
insert into cliente values (22, 'Guilherme Barros Prates', TO_DATE('7/10/98', 'dd/mm/yy'),22, '22@gmail.com', '8');
insert into cliente values (23, 'Guilherme Barros Villani', TO_DATE('12/9/98', 'dd/mm/yy'),23, '23@gmail.com', '12');
insert into cliente values (24, 'Guilherme Barros Souza', TO_DATE('8/1/98', 'dd/mm/yy'),24, '24@gmail.com', '12');
insert into cliente values (25, 'Guilherme Leal Balduino', TO_DATE('6/8/98', 'dd/mm/yy'),25, '25@gmail.com', '3');
insert into cliente values (26, 'Guilherme Leal Chu Ann', TO_DATE('10/3/98', 'dd/mm/yy'),26, '26@gmail.com', '8');
insert into cliente values (27, 'Guilherme Leal Samara', TO_DATE('11/11/98', 'dd/mm/yy'),27, '27@gmail.com', '10');
insert into cliente values (28, 'Guilherme Leal Prates', TO_DATE('11/12/98', 'dd/mm/yy'),28, '28@gmail.com', '6');
insert into cliente values (29, 'Guilherme Leal Villani', TO_DATE('9/2/98', 'dd/mm/yy'),29, '29@gmail.com', '7');
insert into cliente values (30, 'Guilherme Leal Souza', TO_DATE('11/10/98', 'dd/mm/yy'),30, '30@gmail.com', '1');
insert into cliente values (31, 'Guilherme Brito Balduino', TO_DATE('1/3/98', 'dd/mm/yy'),31, '31@gmail.com', '11');
insert into cliente values (32, 'Guilherme Brito Chu Ann', TO_DATE('3/10/98', 'dd/mm/yy'),32, '32@gmail.com', '15');
insert into cliente values (33, 'Guilherme Brito Samara', TO_DATE('4/11/98', 'dd/mm/yy'),33, '33@gmail.com', '1');
insert into cliente values (34, 'Guilherme Brito Prates', TO_DATE('8/8/98', 'dd/mm/yy'),34, '34@gmail.com', '8');
insert into cliente values (35, 'Guilherme Brito Villani', TO_DATE('3/12/98', 'dd/mm/yy'),35, '35@gmail.com', '6');
insert into cliente values (36, 'Guilherme Brito Souza', TO_DATE('3/1/98', 'dd/mm/yy'),36, '36@gmail.com', '2');
insert into cliente values (37, 'Lucas Vilar Balduino', TO_DATE('3/2/98', 'dd/mm/yy'),37, '37@gmail.com', '4');
insert into cliente values (38, 'Lucas Vilar Chu Ann', TO_DATE('2/4/98', 'dd/mm/yy'),38, '38@gmail.com', '4');
insert into cliente values (39, 'Lucas Vilar Samara', TO_DATE('5/11/98', 'dd/mm/yy'),39, '39@gmail.com', '5');
insert into cliente values (40, 'Lucas Vilar Prates', TO_DATE('10/6/98', 'dd/mm/yy'),40, '40@gmail.com', '1');
insert into cliente values (41, 'Lucas Vilar Villani', TO_DATE('11/12/98', 'dd/mm/yy'),41, '41@gmail.com', '7');
insert into cliente values (42, 'Lucas Vilar Souza', TO_DATE('12/6/98', 'dd/mm/yy'),42, '42@gmail.com', '14');
insert into cliente values (43, 'Lucas Heidy Balduino', TO_DATE('12/10/98', 'dd/mm/yy'),43, '43@gmail.com', '3');
insert into cliente values (44, 'Lucas Heidy Chu Ann', TO_DATE('5/9/98', 'dd/mm/yy'),44, '44@gmail.com', '5');
insert into cliente values (45, 'Lucas Heidy Samara', TO_DATE('1/12/98', 'dd/mm/yy'),45, '45@gmail.com', '11');
insert into cliente values (46, 'Lucas Heidy Prates', TO_DATE('1/11/98', 'dd/mm/yy'),46, '46@gmail.com', '6');
insert into cliente values (47, 'Lucas Heidy Villani', TO_DATE('10/11/98', 'dd/mm/yy'),47, '47@gmail.com', '4');
insert into cliente values (48, 'Lucas Heidy Souza', TO_DATE('11/8/98', 'dd/mm/yy'),48, '48@gmail.com', '15');
insert into cliente values (49, 'Lucas Tai Chi Balduino', TO_DATE('1/10/98', 'dd/mm/yy'),49, '49@gmail.com', '13');
insert into cliente values (50, 'Lucas Tai Chi Chu Ann', TO_DATE('10/1/98', 'dd/mm/yy'),50, '50@gmail.com', '3');
insert into cliente values (51, 'Lucas Tai Chi Samara', TO_DATE('10/10/98', 'dd/mm/yy'),51, '51@gmail.com', '12');
insert into cliente values (52, 'Lucas Tai Chi Prates', TO_DATE('4/5/98', 'dd/mm/yy'),52, '52@gmail.com', '12');
insert into cliente values (53, 'Lucas Tai Chi Villani', TO_DATE('5/9/98', 'dd/mm/yy'),53, '53@gmail.com', '1');
insert into cliente values (54, 'Lucas Tai Chi Souza', TO_DATE('6/10/98', 'dd/mm/yy'),54, '54@gmail.com', '7');
insert into cliente values (55, 'Lucas Barros Balduino', TO_DATE('5/4/98', 'dd/mm/yy'),55, '55@gmail.com', '3');
insert into cliente values (56, 'Lucas Barros Chu Ann', TO_DATE('11/4/98', 'dd/mm/yy'),56, '56@gmail.com', '13');
insert into cliente values (57, 'Lucas Barros Samara', TO_DATE('8/7/98', 'dd/mm/yy'),57, '57@gmail.com', '10');
insert into cliente values (58, 'Lucas Barros Prates', TO_DATE('5/4/98', 'dd/mm/yy'),58, '58@gmail.com', '8');
insert into cliente values (59, 'Lucas Barros Villani', TO_DATE('11/1/98', 'dd/mm/yy'),59, '59@gmail.com', '5');
insert into cliente values (60, 'Lucas Barros Souza', TO_DATE('6/5/98', 'dd/mm/yy'),60, '60@gmail.com', '5');
insert into cliente values (61, 'Lucas Leal Balduino', TO_DATE('4/3/98', 'dd/mm/yy'),61, '61@gmail.com', '7');
insert into cliente values (62, 'Lucas Leal Chu Ann', TO_DATE('2/10/98', 'dd/mm/yy'),62, '62@gmail.com', '9');
insert into cliente values (63, 'Lucas Leal Samara', TO_DATE('2/3/98', 'dd/mm/yy'),63, '63@gmail.com', '11');
insert into cliente values (64, 'Lucas Leal Prates', TO_DATE('3/7/98', 'dd/mm/yy'),64, '64@gmail.com', '14');
insert into cliente values (65, 'Lucas Leal Villani', TO_DATE('9/11/98', 'dd/mm/yy'),65, '65@gmail.com', '11');
insert into cliente values (66, 'Lucas Leal Souza', TO_DATE('3/11/98', 'dd/mm/yy'),66, '66@gmail.com', '1');
insert into cliente values (67, 'Lucas Brito Balduino', TO_DATE('2/6/98', 'dd/mm/yy'),67, '67@gmail.com', '3');
insert into cliente values (68, 'Lucas Brito Chu Ann', TO_DATE('1/12/98', 'dd/mm/yy'),68, '68@gmail.com', '11');
insert into cliente values (69, 'Lucas Brito Samara', TO_DATE('4/8/98', 'dd/mm/yy'),69, '69@gmail.com', '13');
insert into cliente values (70, 'Lucas Brito Prates', TO_DATE('8/3/98', 'dd/mm/yy'),70, '70@gmail.com', '15');
insert into cliente values (71, 'Lucas Brito Villani', TO_DATE('8/5/98', 'dd/mm/yy'),71, '71@gmail.com', '13');
insert into cliente values (72, 'Lucas Brito Souza', TO_DATE('3/9/98', 'dd/mm/yy'),72, '72@gmail.com', '9');
insert into cliente values (73, 'Roberto Vilar Balduino', TO_DATE('10/2/98', 'dd/mm/yy'),73, '73@gmail.com', '6');
insert into cliente values (74, 'Roberto Vilar Chu Ann', TO_DATE('10/11/98', 'dd/mm/yy'),74, '74@gmail.com', '1');
insert into cliente values (75, 'Roberto Vilar Samara', TO_DATE('10/11/98', 'dd/mm/yy'),75, '75@gmail.com', '12');
insert into cliente values (76, 'Roberto Vilar Prates', TO_DATE('4/12/98', 'dd/mm/yy'),76, '76@gmail.com', '1');
insert into cliente values (77, 'Roberto Vilar Villani', TO_DATE('11/11/98', 'dd/mm/yy'),77, '77@gmail.com', '14');
insert into cliente values (78, 'Roberto Vilar Souza', TO_DATE('11/11/98', 'dd/mm/yy'),78, '78@gmail.com', '6');
insert into cliente values (79, 'Roberto Heidy Balduino', TO_DATE('7/1/98', 'dd/mm/yy'),79, '79@gmail.com', '13');
insert into cliente values (80, 'Roberto Heidy Chu Ann', TO_DATE('6/4/98', 'dd/mm/yy'),80, '80@gmail.com', '4');
insert into cliente values (81, 'Roberto Heidy Samara', TO_DATE('8/12/98', 'dd/mm/yy'),81, '81@gmail.com', '2');
insert into cliente values (82, 'Roberto Heidy Prates', TO_DATE('12/11/98', 'dd/mm/yy'),82, '82@gmail.com', '4');
insert into cliente values (83, 'Roberto Heidy Villani', TO_DATE('12/8/98', 'dd/mm/yy'),83, '83@gmail.com', '9');
insert into cliente values (84, 'Roberto Heidy Souza', TO_DATE('5/10/98', 'dd/mm/yy'),84, '84@gmail.com', '8');
insert into cliente values (85, 'Roberto Tai Chi Balduino', TO_DATE('6/4/98', 'dd/mm/yy'),85, '85@gmail.com', '3');
insert into cliente values (86, 'Roberto Tai Chi Chu Ann', TO_DATE('4/8/98', 'dd/mm/yy'),86, '86@gmail.com', '5');
insert into cliente values (87, 'Roberto Tai Chi Samara', TO_DATE('8/2/98', 'dd/mm/yy'),87, '87@gmail.com', '10');
insert into cliente values (88, 'Roberto Tai Chi Prates', TO_DATE('12/11/98', 'dd/mm/yy'),88, '88@gmail.com', '4');
insert into cliente values (89, 'Roberto Tai Chi Villani', TO_DATE('7/2/98', 'dd/mm/yy'),89, '89@gmail.com', '14');
insert into cliente values (90, 'Roberto Tai Chi Souza', TO_DATE('12/9/98', 'dd/mm/yy'),90, '90@gmail.com', '3');
insert into cliente values (91, 'Roberto Barros Balduino', TO_DATE('7/2/98', 'dd/mm/yy'),91, '91@gmail.com', '5');
insert into cliente values (92, 'Roberto Barros Chu Ann', TO_DATE('11/7/98', 'dd/mm/yy'),92, '92@gmail.com', '2');
insert into cliente values (93, 'Roberto Barros Samara', TO_DATE('7/10/98', 'dd/mm/yy'),93, '93@gmail.com', '15');
insert into cliente values (94, 'Roberto Barros Prates', TO_DATE('11/8/98', 'dd/mm/yy'),94, '94@gmail.com', '2');
insert into cliente values (95, 'Roberto Barros Villani', TO_DATE('4/8/98', 'dd/mm/yy'),95, '95@gmail.com', '8');
insert into cliente values (96, 'Roberto Barros Souza', TO_DATE('8/3/98', 'dd/mm/yy'),96, '96@gmail.com', '13');
insert into cliente values (97, 'Roberto Leal Balduino', TO_DATE('2/10/98', 'dd/mm/yy'),97, '97@gmail.com', '3');
insert into cliente values (98, 'Roberto Leal Chu Ann', TO_DATE('4/11/98', 'dd/mm/yy'),98, '98@gmail.com', '3');
insert into cliente values (99, 'Roberto Leal Samara', TO_DATE('9/9/98', 'dd/mm/yy'),99, '99@gmail.com', '15');
insert into cliente values (100, 'Roberto Leal Prates', TO_DATE('3/6/98', 'dd/mm/yy'),100, '100@gmail.com', '8');
insert into cliente values (101, 'Roberto Leal Villani', TO_DATE('4/8/98', 'dd/mm/yy'),101, '101@gmail.com', '14');
insert into cliente values (102, 'Roberto Leal Souza', TO_DATE('9/9/98', 'dd/mm/yy'),102, '102@gmail.com', '2');
insert into cliente values (103, 'Roberto Brito Balduino', TO_DATE('9/12/98', 'dd/mm/yy'),103, '103@gmail.com', '15');
insert into cliente values (104, 'Roberto Brito Chu Ann', TO_DATE('5/10/98', 'dd/mm/yy'),104, '104@gmail.com', '3');
insert into cliente values (105, 'Roberto Brito Samara', TO_DATE('9/10/98', 'dd/mm/yy'),105, '105@gmail.com', '4');
insert into cliente values (106, 'Roberto Brito Prates', TO_DATE('3/11/98', 'dd/mm/yy'),106, '106@gmail.com', '13');
insert into cliente values (107, 'Roberto Brito Villani', TO_DATE('5/7/98', 'dd/mm/yy'),107, '107@gmail.com', '2');
insert into cliente values (108, 'Roberto Brito Souza', TO_DATE('9/9/98', 'dd/mm/yy'),108, '108@gmail.com', '10');
insert into cliente values (109, 'Bruna Vilar Balduino', TO_DATE('9/10/98', 'dd/mm/yy'),109, '109@gmail.com', '2');
insert into cliente values (110, 'Bruna Vilar Chu Ann', TO_DATE('12/10/98', 'dd/mm/yy'),110, '110@gmail.com', '4');
insert into cliente values (111, 'Bruna Vilar Samara', TO_DATE('10/9/98', 'dd/mm/yy'),111, '111@gmail.com', '6');
insert into cliente values (112, 'Bruna Vilar Prates', TO_DATE('9/8/98', 'dd/mm/yy'),112, '112@gmail.com', '9');
insert into cliente values (113, 'Bruna Vilar Villani', TO_DATE('10/6/98', 'dd/mm/yy'),113, '113@gmail.com', '4');
insert into cliente values (114, 'Bruna Vilar Souza', TO_DATE('6/4/98', 'dd/mm/yy'),114, '114@gmail.com', '6');
insert into cliente values (115, 'Bruna Heidy Balduino', TO_DATE('9/4/98', 'dd/mm/yy'),115, '115@gmail.com', '9');
insert into cliente values (116, 'Bruna Heidy Chu Ann', TO_DATE('11/4/98', 'dd/mm/yy'),116, '116@gmail.com', '1');
insert into cliente values (117, 'Bruna Heidy Samara', TO_DATE('1/9/98', 'dd/mm/yy'),117, '117@gmail.com', '15');
insert into cliente values (118, 'Bruna Heidy Prates', TO_DATE('10/9/98', 'dd/mm/yy'),118, '118@gmail.com', '13');
insert into cliente values (119, 'Bruna Heidy Villani', TO_DATE('3/12/98', 'dd/mm/yy'),119, '119@gmail.com', '14');
insert into cliente values (120, 'Bruna Heidy Souza', TO_DATE('7/1/98', 'dd/mm/yy'),120, '120@gmail.com', '6');
insert into cliente values (121, 'Bruna Tai Chi Balduino', TO_DATE('4/11/98', 'dd/mm/yy'),121, '121@gmail.com', '3');
insert into cliente values (122, 'Bruna Tai Chi Chu Ann', TO_DATE('12/3/98', 'dd/mm/yy'),122, '122@gmail.com', '5');
insert into cliente values (123, 'Bruna Tai Chi Samara', TO_DATE('11/4/98', 'dd/mm/yy'),123, '123@gmail.com', '5');
insert into cliente values (124, 'Bruna Tai Chi Prates', TO_DATE('9/10/98', 'dd/mm/yy'),124, '124@gmail.com', '8');
insert into cliente values (125, 'Bruna Tai Chi Villani', TO_DATE('2/11/98', 'dd/mm/yy'),125, '125@gmail.com', '6');
insert into cliente values (126, 'Bruna Tai Chi Souza', TO_DATE('4/5/98', 'dd/mm/yy'),126, '126@gmail.com', '15');
insert into cliente values (127, 'Bruna Barros Balduino', TO_DATE('2/1/98', 'dd/mm/yy'),127, '127@gmail.com', '15');
insert into cliente values (128, 'Bruna Barros Chu Ann', TO_DATE('2/1/98', 'dd/mm/yy'),128, '128@gmail.com', '7');
insert into cliente values (129, 'Bruna Barros Samara', TO_DATE('6/5/98', 'dd/mm/yy'),129, '129@gmail.com', '2');
insert into cliente values (130, 'Bruna Barros Prates', TO_DATE('7/10/98', 'dd/mm/yy'),130, '130@gmail.com', '9');
insert into cliente values (131, 'Bruna Barros Villani', TO_DATE('10/4/98', 'dd/mm/yy'),131, '131@gmail.com', '2');
insert into cliente values (132, 'Bruna Barros Souza', TO_DATE('2/6/98', 'dd/mm/yy'),132, '132@gmail.com', '8');
insert into cliente values (133, 'Bruna Leal Balduino', TO_DATE('4/2/98', 'dd/mm/yy'),133, '133@gmail.com', '3');
insert into cliente values (134, 'Bruna Leal Chu Ann', TO_DATE('3/4/98', 'dd/mm/yy'),134, '134@gmail.com', '8');
insert into cliente values (135, 'Bruna Leal Samara', TO_DATE('7/2/98', 'dd/mm/yy'),135, '135@gmail.com', '15');
insert into cliente values (136, 'Bruna Leal Prates', TO_DATE('10/7/98', 'dd/mm/yy'),136, '136@gmail.com', '2');
insert into cliente values (137, 'Bruna Leal Villani', TO_DATE('7/8/98', 'dd/mm/yy'),137, '137@gmail.com', '6');
insert into cliente values (138, 'Bruna Leal Souza', TO_DATE('2/2/98', 'dd/mm/yy'),138, '138@gmail.com', '7');
insert into cliente values (139, 'Bruna Brito Balduino', TO_DATE('3/10/98', 'dd/mm/yy'),139, '139@gmail.com', '15');
insert into cliente values (140, 'Bruna Brito Chu Ann', TO_DATE('2/4/98', 'dd/mm/yy'),140, '140@gmail.com', '4');
insert into cliente values (141, 'Bruna Brito Samara', TO_DATE('5/12/98', 'dd/mm/yy'),141, '141@gmail.com', '13');
insert into cliente values (142, 'Bruna Brito Prates', TO_DATE('5/2/98', 'dd/mm/yy'),142, '142@gmail.com', '8');
insert into cliente values (143, 'Bruna Brito Villani', TO_DATE('10/4/98', 'dd/mm/yy'),143, '143@gmail.com', '1');
insert into cliente values (144, 'Bruna Brito Souza', TO_DATE('2/5/98', 'dd/mm/yy'),144, '144@gmail.com', '8');
insert into cliente values (145, 'Isadora Vilar Balduino', TO_DATE('2/3/98', 'dd/mm/yy'),145, '145@gmail.com', '13');
insert into cliente values (146, 'Isadora Vilar Chu Ann', TO_DATE('1/12/98', 'dd/mm/yy'),146, '146@gmail.com', '15');
insert into cliente values (147, 'Isadora Vilar Samara', TO_DATE('4/9/98', 'dd/mm/yy'),147, '147@gmail.com', '13');
insert into cliente values (148, 'Isadora Vilar Prates', TO_DATE('3/12/98', 'dd/mm/yy'),148, '148@gmail.com', '7');
insert into cliente values (149, 'Isadora Vilar Villani', TO_DATE('5/3/98', 'dd/mm/yy'),149, '149@gmail.com', '4');
insert into cliente values (150, 'Isadora Vilar Souza', TO_DATE('11/6/98', 'dd/mm/yy'),150, '150@gmail.com', '13');
insert into cliente values (151, 'Isadora Heidy Balduino', TO_DATE('5/7/98', 'dd/mm/yy'),151, '151@gmail.com', '10');
insert into cliente values (152, 'Isadora Heidy Chu Ann', TO_DATE('11/7/98', 'dd/mm/yy'),152, '152@gmail.com', '14');
insert into cliente values (153, 'Isadora Heidy Samara', TO_DATE('9/12/98', 'dd/mm/yy'),153, '153@gmail.com', '13');
insert into cliente values (154, 'Isadora Heidy Prates', TO_DATE('11/5/98', 'dd/mm/yy'),154, '154@gmail.com', '1');
insert into cliente values (155, 'Isadora Heidy Villani', TO_DATE('4/4/98', 'dd/mm/yy'),155, '155@gmail.com', '7');
insert into cliente values (156, 'Isadora Heidy Souza', TO_DATE('5/11/98', 'dd/mm/yy'),156, '156@gmail.com', '5');
insert into cliente values (157, 'Isadora Tai Chi Balduino', TO_DATE('7/4/98', 'dd/mm/yy'),157, '157@gmail.com', '7');
insert into cliente values (158, 'Isadora Tai Chi Chu Ann', TO_DATE('7/5/98', 'dd/mm/yy'),158, '158@gmail.com', '4');
insert into cliente values (159, 'Isadora Tai Chi Samara', TO_DATE('2/9/98', 'dd/mm/yy'),159, '159@gmail.com', '1');
insert into cliente values (160, 'Isadora Tai Chi Prates', TO_DATE('1/9/98', 'dd/mm/yy'),160, '160@gmail.com', '13');
insert into cliente values (161, 'Isadora Tai Chi Villani', TO_DATE('8/9/98', 'dd/mm/yy'),161, '161@gmail.com', '1');
insert into cliente values (162, 'Isadora Tai Chi Souza', TO_DATE('4/4/98', 'dd/mm/yy'),162, '162@gmail.com', '8');
insert into cliente values (163, 'Isadora Barros Balduino', TO_DATE('6/8/98', 'dd/mm/yy'),163, '163@gmail.com', '1');
insert into cliente values (164, 'Isadora Barros Chu Ann', TO_DATE('10/1/98', 'dd/mm/yy'),164, '164@gmail.com', '13');
insert into cliente values (165, 'Isadora Barros Samara', TO_DATE('10/10/98', 'dd/mm/yy'),165, '165@gmail.com', '13');
insert into cliente values (166, 'Isadora Barros Prates', TO_DATE('12/9/98', 'dd/mm/yy'),166, '166@gmail.com', '1');
insert into cliente values (167, 'Isadora Barros Villani', TO_DATE('4/7/98', 'dd/mm/yy'),167, '167@gmail.com', '3');
insert into cliente values (168, 'Isadora Barros Souza', TO_DATE('6/11/98', 'dd/mm/yy'),168, '168@gmail.com', '8');
insert into cliente values (169, 'Isadora Leal Balduino', TO_DATE('3/9/98', 'dd/mm/yy'),169, '169@gmail.com', '10');
insert into cliente values (170, 'Isadora Leal Chu Ann', TO_DATE('12/9/98', 'dd/mm/yy'),170, '170@gmail.com', '3');
insert into cliente values (171, 'Isadora Leal Samara', TO_DATE('4/6/98', 'dd/mm/yy'),171, '171@gmail.com', '1');
insert into cliente values (172, 'Isadora Leal Prates', TO_DATE('12/8/98', 'dd/mm/yy'),172, '172@gmail.com', '12');
insert into cliente values (173, 'Isadora Leal Villani', TO_DATE('2/1/98', 'dd/mm/yy'),173, '173@gmail.com', '12');
insert into cliente values (174, 'Isadora Leal Souza', TO_DATE('9/1/98', 'dd/mm/yy'),174, '174@gmail.com', '10');
insert into cliente values (175, 'Isadora Brito Balduino', TO_DATE('3/6/98', 'dd/mm/yy'),175, '175@gmail.com', '8');
insert into cliente values (176, 'Isadora Brito Chu Ann', TO_DATE('4/6/98', 'dd/mm/yy'),176, '176@gmail.com', '15');
insert into cliente values (177, 'Isadora Brito Samara', TO_DATE('6/10/98', 'dd/mm/yy'),177, '177@gmail.com', '3');
insert into cliente values (178, 'Isadora Brito Prates', TO_DATE('2/8/98', 'dd/mm/yy'),178, '178@gmail.com', '10');
insert into cliente values (179, 'Isadora Brito Villani', TO_DATE('5/2/98', 'dd/mm/yy'),179, '179@gmail.com', '13');
insert into cliente values (180, 'Isadora Brito Souza', TO_DATE('2/3/98', 'dd/mm/yy'),180, '180@gmail.com', '2');
insert into cliente values (181, 'Jessica Vilar Balduino', TO_DATE('11/9/98', 'dd/mm/yy'),181, '181@gmail.com', '12');
insert into cliente values (182, 'Jessica Vilar Chu Ann', TO_DATE('2/4/98', 'dd/mm/yy'),182, '182@gmail.com', '12');
insert into cliente values (183, 'Jessica Vilar Samara', TO_DATE('5/6/98', 'dd/mm/yy'),183, '183@gmail.com', '10');
insert into cliente values (184, 'Jessica Vilar Prates', TO_DATE('7/5/98', 'dd/mm/yy'),184, '184@gmail.com', '4');
insert into cliente values (185, 'Jessica Vilar Villani', TO_DATE('10/7/98', 'dd/mm/yy'),185, '185@gmail.com', '1');
insert into cliente values (186, 'Jessica Vilar Souza', TO_DATE('2/10/98', 'dd/mm/yy'),186, '186@gmail.com', '5');
insert into cliente values (187, 'Jessica Heidy Balduino', TO_DATE('8/6/98', 'dd/mm/yy'),187, '187@gmail.com', '2');
insert into cliente values (188, 'Jessica Heidy Chu Ann', TO_DATE('12/5/98', 'dd/mm/yy'),188, '188@gmail.com', '10');
insert into cliente values (189, 'Jessica Heidy Samara', TO_DATE('10/1/98', 'dd/mm/yy'),189, '189@gmail.com', '11');
insert into cliente values (190, 'Jessica Heidy Prates', TO_DATE('7/9/98', 'dd/mm/yy'),190, '190@gmail.com', '1');
insert into cliente values (191, 'Jessica Heidy Villani', TO_DATE('7/11/98', 'dd/mm/yy'),191, '191@gmail.com', '1');
insert into cliente values (192, 'Jessica Heidy Souza', TO_DATE('1/6/98', 'dd/mm/yy'),192, '192@gmail.com', '5');
insert into cliente values (193, 'Jessica Tai Chi Balduino', TO_DATE('5/11/98', 'dd/mm/yy'),193, '193@gmail.com', '1');
insert into cliente values (194, 'Jessica Tai Chi Chu Ann', TO_DATE('12/5/98', 'dd/mm/yy'),194, '194@gmail.com', '12');
insert into cliente values (195, 'Jessica Tai Chi Samara', TO_DATE('5/9/98', 'dd/mm/yy'),195, '195@gmail.com', '14');
insert into cliente values (196, 'Jessica Tai Chi Prates', TO_DATE('6/6/98', 'dd/mm/yy'),196, '196@gmail.com', '11');
insert into cliente values (197, 'Jessica Tai Chi Villani', TO_DATE('5/2/98', 'dd/mm/yy'),197, '197@gmail.com', '9');
insert into cliente values (198, 'Jessica Tai Chi Souza', TO_DATE('8/4/98', 'dd/mm/yy'),198, '198@gmail.com', '14');
insert into cliente values (199, 'Jessica Barros Balduino', TO_DATE('7/5/98', 'dd/mm/yy'),199, '199@gmail.com', '6');
insert into cliente values (200, 'Jessica Barros Chu Ann', TO_DATE('5/2/98', 'dd/mm/yy'),200, '200@gmail.com', '5');
insert into cliente values (201, 'Jessica Barros Samara', TO_DATE('12/7/98', 'dd/mm/yy'),201, '201@gmail.com', '9');
insert into cliente values (202, 'Jessica Barros Prates', TO_DATE('4/7/98', 'dd/mm/yy'),202, '202@gmail.com', '1');
insert into cliente values (203, 'Jessica Barros Villani', TO_DATE('4/4/98', 'dd/mm/yy'),203, '203@gmail.com', '8');
insert into cliente values (204, 'Jessica Barros Souza', TO_DATE('8/3/98', 'dd/mm/yy'),204, '204@gmail.com', '11');
insert into cliente values (205, 'Jessica Leal Balduino', TO_DATE('10/5/98', 'dd/mm/yy'),205, '205@gmail.com', '12');
insert into cliente values (206, 'Jessica Leal Chu Ann', TO_DATE('7/1/98', 'dd/mm/yy'),206, '206@gmail.com', '14');
insert into cliente values (207, 'Jessica Leal Samara', TO_DATE('2/12/98', 'dd/mm/yy'),207, '207@gmail.com', '15');
insert into cliente values (208, 'Jessica Leal Prates', TO_DATE('3/9/98', 'dd/mm/yy'),208, '208@gmail.com', '3');
insert into cliente values (209, 'Jessica Leal Villani', TO_DATE('5/7/98', 'dd/mm/yy'),209, '209@gmail.com', '4');
insert into cliente values (210, 'Jessica Leal Souza', TO_DATE('8/10/98', 'dd/mm/yy'),210, '210@gmail.com', '5');
insert into cliente values (211, 'Jessica Brito Balduino', TO_DATE('12/7/98', 'dd/mm/yy'),211, '211@gmail.com', '3');
insert into cliente values (212, 'Jessica Brito Chu Ann', TO_DATE('1/9/98', 'dd/mm/yy'),212, '212@gmail.com', '1');
insert into cliente values (213, 'Jessica Brito Samara', TO_DATE('3/9/98', 'dd/mm/yy'),213, '213@gmail.com', '12');
insert into cliente values (214, 'Jessica Brito Prates', TO_DATE('6/12/98', 'dd/mm/yy'),214, '214@gmail.com', '1');
insert into cliente values (215, 'Jessica Brito Villani', TO_DATE('11/2/98', 'dd/mm/yy'),215, '215@gmail.com', '4');
insert into cliente values (216, 'Jessica Brito Souza', TO_DATE('8/11/98', 'dd/mm/yy'),216, '216@gmail.com', '7');

 
insert into jogo values (1, 1621.15, 'Fisico', 'Crash o ourico 1', 9);
insert into jogo values (2, 1709.74, 'Fisico', 'Crash o ourico 2', 12);
insert into jogo values (3, 7356.26, 'Fisico', 'Crash o ourico Remake', 5);
insert into jogo values (4, 2800.55, 'Fisico', 'Crash o ourico Final Boot', 9);
insert into jogo values (5, 5843.82, 'Fisico', 'Crash o ourico World', 10);
insert into jogo values (6, 7727.84, 'Fisico', 'Crash o ourico Remake', 9);
insert into jogo values (7, 5741.21, 'Digital', 'Crash bros. 1', 15);
insert into jogo values (8, 7720.12, 'Fisico', 'Crash bros. 2', 15);
insert into jogo values (9, 5254.78, 'Fisico', 'Crash bros. Remake', 6);
insert into jogo values (10, 4873.23, 'Digital', 'Crash bros. Final Boot', 8);
insert into jogo values (11, 5397.28, 'Fisico', 'Crash bros. World', 13);
insert into jogo values (12, 2712.52, 'Fisico', 'Crash bros. Remake', 2);
insert into jogo values (13, 4836.64, 'Digital', 'Crash Kart 1', 8);
insert into jogo values (14, 3878.99, 'Digital', 'Crash Kart 2', 10);
insert into jogo values (15, 7123.03, 'Fisico', 'Crash Kart Remake', 2);
insert into jogo values (16, 1904.18, 'Digital', 'Crash Kart Final Boot', 4);
insert into jogo values (17, 5378.48, 'Fisico', 'Crash Kart World', 2);
insert into jogo values (18, 948.25, 'Digital', 'Crash Kart Remake', 12);
insert into jogo values (19, 5149.0, 'Digital', 'Crash Kombat 1', 5);
insert into jogo values (20, 4070.4, 'Digital', 'Crash Kombat 2', 8);
insert into jogo values (21, 7158.84, 'Fisico', 'Crash Kombat Remake', 9);
insert into jogo values (22, 6810.77, 'Digital', 'Crash Kombat Final Boot', 12);
insert into jogo values (23, 7361.09, 'Fisico', 'Crash Kombat World', 8);
insert into jogo values (24, 6690.49, 'Digital', 'Crash Kombat Remake', 3);
insert into jogo values (25, 478.12, 'Digital', 'Crash the hunter 1', 11);
insert into jogo values (26, 6269.25, 'Fisico', 'Crash the hunter 2', 3);
insert into jogo values (27, 3085.92, 'Fisico', 'Crash the hunter Remake', 7);
insert into jogo values (28, 819.1, 'Digital', 'Crash the hunter Final Boot', 15);
insert into jogo values (29, 1167.34, 'Fisico', 'Crash the hunter World', 7);
insert into jogo values (30, 5701.54, 'Digital', 'Crash the hunter Remake', 3);
insert into jogo values (31, 7865.51, 'Fisico', 'Crash god of time1', 10);
insert into jogo values (32, 747.49, 'Digital', 'Crash god of time2', 9);
insert into jogo values (33, 2773.26, 'Digital', 'Crash god of timeRemake', 1);
insert into jogo values (34, 1593.56, 'Fisico', 'Crash god of timeFinal Boot', 8);
insert into jogo values (35, 2166.26, 'Fisico', 'Crash god of timeWorld', 4);
insert into jogo values (36, 1247.33, 'Fisico', 'Crash god of timeRemake', 4);
insert into jogo values (37, 6505.78, 'Fisico', 'Sonic o ourico 1', 14);
insert into jogo values (38, 3597.36, 'Fisico', 'Sonic o ourico 2', 15);
insert into jogo values (39, 2231.75, 'Fisico', 'Sonic o ourico Remake', 9);
insert into jogo values (40, 6815.76, 'Digital', 'Sonic o ourico Final Boot', 5);
insert into jogo values (41, 7361.23, 'Fisico', 'Sonic o ourico World', 1);
insert into jogo values (42, 6044.31, 'Fisico', 'Sonic o ourico Remake', 7);
insert into jogo values (43, 1883.91, 'Digital', 'Sonic bros. 1', 5);
insert into jogo values (44, 7539.23, 'Fisico', 'Sonic bros. 2', 8);
insert into jogo values (45, 7153.05, 'Digital', 'Sonic bros. Remake', 12);
insert into jogo values (46, 6294.4, 'Digital', 'Sonic bros. Final Boot', 6);
insert into jogo values (47, 527.34, 'Digital', 'Sonic bros. World', 6);
insert into jogo values (48, 1396.71, 'Fisico', 'Sonic bros. Remake', 15);
insert into jogo values (49, 2242.67, 'Digital', 'Sonic Kart 1', 2);
insert into jogo values (50, 7895.4, 'Fisico', 'Sonic Kart 2', 10);
insert into jogo values (51, 5692.2, 'Digital', 'Sonic Kart Remake', 14);
insert into jogo values (52, 5607.59, 'Digital', 'Sonic Kart Final Boot', 13);
insert into jogo values (53, 1004.2, 'Fisico', 'Sonic Kart World', 13);
insert into jogo values (54, 4817.86, 'Digital', 'Sonic Kart Remake', 5);
insert into jogo values (55, 2962.75, 'Digital', 'Sonic Kombat 1', 11);
insert into jogo values (56, 4737.85, 'Digital', 'Sonic Kombat 2', 1);
insert into jogo values (57, 6036.02, 'Fisico', 'Sonic Kombat Remake', 10);
insert into jogo values (58, 6901.75, 'Digital', 'Sonic Kombat Final Boot', 9);
insert into jogo values (59, 3520.47, 'Fisico', 'Sonic Kombat World', 10);
insert into jogo values (60, 7636.0, 'Digital', 'Sonic Kombat Remake', 11);
insert into jogo values (61, 2030.16, 'Fisico', 'Sonic the hunter 1', 13);
insert into jogo values (62, 4049.15, 'Digital', 'Sonic the hunter 2', 9);
insert into jogo values (63, 4335.81, 'Fisico', 'Sonic the hunter Remake', 14);
insert into jogo values (64, 2860.83, 'Digital', 'Sonic the hunter Final Boot', 2);
insert into jogo values (65, 4240.07, 'Digital', 'Sonic the hunter World', 8);
insert into jogo values (66, 842.79, 'Fisico', 'Sonic the hunter Remake', 13);
insert into jogo values (67, 5497.26, 'Fisico', 'Sonic god of time1', 8);
insert into jogo values (68, 1323.63, 'Fisico', 'Sonic god of time2', 14);
insert into jogo values (69, 202.89, 'Fisico', 'Sonic god of timeRemake', 14);
insert into jogo values (70, 6943.24, 'Digital', 'Sonic god of timeFinal Boot', 15);
insert into jogo values (71, 7338.57, 'Fisico', 'Sonic god of timeWorld', 13);
insert into jogo values (72, 3402.33, 'Digital', 'Sonic god of timeRemake', 5);
insert into jogo values (73, 2944.55, 'Fisico', 'Mario o ourico 1', 5);
insert into jogo values (74, 5857.33, 'Fisico', 'Mario o ourico 2', 4);
insert into jogo values (75, 93.96, 'Fisico', 'Mario o ourico Remake', 15);
insert into jogo values (76, 1117.83, 'Digital', 'Mario o ourico Final Boot', 12);
insert into jogo values (77, 7382.06, 'Digital', 'Mario o ourico World', 1);
insert into jogo values (78, 842.99, 'Digital', 'Mario o ourico Remake', 10);
insert into jogo values (79, 730.02, 'Digital', 'Mario bros. 1', 9);
insert into jogo values (80, 80.73, 'Digital', 'Mario bros. 2', 1);
insert into jogo values (81, 5692.12, 'Digital', 'Mario bros. Remake', 15);
insert into jogo values (82, 7823.68, 'Fisico', 'Mario bros. Final Boot', 5);
insert into jogo values (83, 7630.19, 'Fisico', 'Mario bros. World', 6);
insert into jogo values (84, 7664.43, 'Fisico', 'Mario bros. Remake', 10);
insert into jogo values (85, 7543.19, 'Fisico', 'Mario Kart 1', 14);
insert into jogo values (86, 4547.26, 'Digital', 'Mario Kart 2', 3);
insert into jogo values (87, 7460.89, 'Fisico', 'Mario Kart Remake', 13);
insert into jogo values (88, 2687.4, 'Fisico', 'Mario Kart Final Boot', 7);
insert into jogo values (89, 3806.35, 'Fisico', 'Mario Kart World', 14);
insert into jogo values (90, 2681.47, 'Digital', 'Mario Kart Remake', 13);
insert into jogo values (91, 6822.85, 'Fisico', 'Mario Kombat 1', 10);
insert into jogo values (92, 3043.83, 'Digital', 'Mario Kombat 2', 11);
insert into jogo values (93, 6730.19, 'Digital', 'Mario Kombat Remake', 12);
insert into jogo values (94, 708.24, 'Digital', 'Mario Kombat Final Boot', 8);
insert into jogo values (95, 5891.0, 'Fisico', 'Mario Kombat World', 9);
insert into jogo values (96, 3098.09, 'Digital', 'Mario Kombat Remake', 10);
insert into jogo values (97, 7517.95, 'Digital', 'Mario the hunter 1', 13);
insert into jogo values (98, 5173.9, 'Digital', 'Mario the hunter 2', 8);
insert into jogo values (99, 6286.27, 'Fisico', 'Mario the hunter Remake', 9);
insert into jogo values (100, 4890.76, 'Digital', 'Mario the hunter Final Boot', 6);
insert into jogo values (101, 1640.75, 'Digital', 'Mario the hunter World', 11);
insert into jogo values (102, 196.2, 'Fisico', 'Mario the hunter Remake', 6);
insert into jogo values (103, 4860.98, 'Digital', 'Mario god of time1', 1);
insert into jogo values (104, 3289.7, 'Digital', 'Mario god of time2', 8);
insert into jogo values (105, 2624.62, 'Fisico', 'Mario god of timeRemake', 15);
insert into jogo values (106, 1422.92, 'Digital', 'Mario god of timeFinal Boot', 6);
insert into jogo values (107, 4981.78, 'Digital', 'Mario god of timeWorld', 11);
insert into jogo values (108, 1633.01, 'Fisico', 'Mario god of timeRemake', 14);
insert into jogo values (109, 6591.27, 'Digital', 'Zelda o ourico 1', 11);
insert into jogo values (110, 3269.73, 'Fisico', 'Zelda o ourico 2', 12);
insert into jogo values (111, 1371.83, 'Digital', 'Zelda o ourico Remake', 12);
insert into jogo values (112, 2423.59, 'Fisico', 'Zelda o ourico Final Boot', 4);
insert into jogo values (113, 29.69, 'Digital', 'Zelda o ourico World', 8);
insert into jogo values (114, 767.97, 'Fisico', 'Zelda o ourico Remake', 5);
insert into jogo values (115, 974.88, 'Fisico', 'Zelda bros. 1', 3);
insert into jogo values (116, 1117.55, 'Fisico', 'Zelda bros. 2', 8);
insert into jogo values (117, 828.66, 'Fisico', 'Zelda bros. Remake', 15);
insert into jogo values (118, 7197.61, 'Fisico', 'Zelda bros. Final Boot', 14);
insert into jogo values (119, 4490.71, 'Fisico', 'Zelda bros. World', 6);
insert into jogo values (120, 7240.47, 'Digital', 'Zelda bros. Remake', 12);
insert into jogo values (121, 7017.88, 'Fisico', 'Zelda Kart 1', 11);
insert into jogo values (122, 2521.43, 'Fisico', 'Zelda Kart 2', 8);
insert into jogo values (123, 5893.5, 'Digital', 'Zelda Kart Remake', 13);
insert into jogo values (124, 5499.38, 'Fisico', 'Zelda Kart Final Boot', 13);
insert into jogo values (125, 6063.57, 'Digital', 'Zelda Kart World', 2);
insert into jogo values (126, 2989.4, 'Fisico', 'Zelda Kart Remake', 5);
insert into jogo values (127, 6477.64, 'Digital', 'Zelda Kombat 1', 12);
insert into jogo values (128, 5257.84, 'Digital', 'Zelda Kombat 2', 4);
insert into jogo values (129, 2776.76, 'Digital', 'Zelda Kombat Remake', 11);
insert into jogo values (130, 5502.51, 'Fisico', 'Zelda Kombat Final Boot', 9);
insert into jogo values (131, 2488.15, 'Fisico', 'Zelda Kombat World', 4);
insert into jogo values (132, 5213.96, 'Digital', 'Zelda Kombat Remake', 8);
insert into jogo values (133, 4391.76, 'Fisico', 'Zelda the hunter 1', 5);
insert into jogo values (134, 5607.75, 'Fisico', 'Zelda the hunter 2', 4);
insert into jogo values (135, 6983.69, 'Digital', 'Zelda the hunter Remake', 7);
insert into jogo values (136, 3160.41, 'Digital', 'Zelda the hunter Final Boot', 7);
insert into jogo values (137, 4061.01, 'Digital', 'Zelda the hunter World', 5);
insert into jogo values (138, 5593.44, 'Digital', 'Zelda the hunter Remake', 1);
insert into jogo values (139, 7329.25, 'Fisico', 'Zelda god of time1', 5);
insert into jogo values (140, 505.28, 'Digital', 'Zelda god of time2', 10);
insert into jogo values (141, 7145.72, 'Digital', 'Zelda god of timeRemake', 11);
insert into jogo values (142, 292.82, 'Fisico', 'Zelda god of timeFinal Boot', 1);
insert into jogo values (143, 2900.58, 'Fisico', 'Zelda god of timeWorld', 13);
insert into jogo values (144, 7405.37, 'Fisico', 'Zelda god of timeRemake', 2);
insert into jogo values (145, 1332.07, 'Fisico', 'Vegeta o ourico 1', 5);
insert into jogo values (146, 2194.59, 'Digital', 'Vegeta o ourico 2', 10);
insert into jogo values (147, 3568.18, 'Fisico', 'Vegeta o ourico Remake', 15);
insert into jogo values (148, 2104.04, 'Fisico', 'Vegeta o ourico Final Boot', 1);
insert into jogo values (149, 6063.31, 'Digital', 'Vegeta o ourico World', 10);
insert into jogo values (150, 7731.44, 'Fisico', 'Vegeta o ourico Remake', 4);
insert into jogo values (151, 7660.7, 'Digital', 'Vegeta bros. 1', 15);
insert into jogo values (152, 1501.35, 'Digital', 'Vegeta bros. 2', 15);
insert into jogo values (153, 6804.41, 'Fisico', 'Vegeta bros. Remake', 5);
insert into jogo values (154, 4044.03, 'Fisico', 'Vegeta bros. Final Boot', 9);
insert into jogo values (155, 5024.04, 'Fisico', 'Vegeta bros. World', 2);
insert into jogo values (156, 7519.51, 'Fisico', 'Vegeta bros. Remake', 11);
insert into jogo values (157, 337.43, 'Digital', 'Vegeta Kart 1', 7);
insert into jogo values (158, 3058.82, 'Digital', 'Vegeta Kart 2', 13);
insert into jogo values (159, 4237.7, 'Digital', 'Vegeta Kart Remake', 10);
insert into jogo values (160, 1701.59, 'Fisico', 'Vegeta Kart Final Boot', 6);
insert into jogo values (161, 2355.26, 'Fisico', 'Vegeta Kart World', 13);
insert into jogo values (162, 2025.34, 'Digital', 'Vegeta Kart Remake', 15);
insert into jogo values (163, 841.31, 'Digital', 'Vegeta Kombat 1', 3);
insert into jogo values (164, 7333.02, 'Digital', 'Vegeta Kombat 2', 1);
insert into jogo values (165, 7787.81, 'Digital', 'Vegeta Kombat Remake', 11);
insert into jogo values (166, 3670.41, 'Fisico', 'Vegeta Kombat Final Boot', 10);
insert into jogo values (167, 2963.16, 'Digital', 'Vegeta Kombat World', 10);
insert into jogo values (168, 4702.0, 'Digital', 'Vegeta Kombat Remake', 12);
insert into jogo values (169, 6664.65, 'Fisico', 'Vegeta the hunter 1', 2);
insert into jogo values (170, 1225.63, 'Fisico', 'Vegeta the hunter 2', 11);
insert into jogo values (171, 6279.45, 'Fisico', 'Vegeta the hunter Remake', 3);
insert into jogo values (172, 6836.1, 'Fisico', 'Vegeta the hunter Final Boot', 8);
insert into jogo values (173, 7565.94, 'Digital', 'Vegeta the hunter World', 12);
insert into jogo values (174, 7779.73, 'Digital', 'Vegeta the hunter Remake', 15);
insert into jogo values (175, 2014.67, 'Digital', 'Vegeta god of time1', 6);
insert into jogo values (176, 4753.77, 'Fisico', 'Vegeta god of time2', 15);
insert into jogo values (177, 2284.3, 'Fisico', 'Vegeta god of timeRemake', 4);
insert into jogo values (178, 5277.33, 'Fisico', 'Vegeta god of timeFinal Boot', 3);
insert into jogo values (179, 644.04, 'Digital', 'Vegeta god of timeWorld', 10);
insert into jogo values (180, 5220.91, 'Digital', 'Vegeta god of timeRemake', 7);
insert into jogo values (181, 3142.39, 'Digital', 'Gokuo ourico 1', 3);
insert into jogo values (182, 1826.66, 'Fisico', 'Gokuo ourico 2', 15);
insert into jogo values (183, 1458.61, 'Fisico', 'Gokuo ourico Remake', 13);
insert into jogo values (184, 115.36, 'Digital', 'Gokuo ourico Final Boot', 3);
insert into jogo values (185, 6305.15, 'Fisico', 'Gokuo ourico World', 8);
insert into jogo values (186, 5429.17, 'Fisico', 'Gokuo ourico Remake', 11);
insert into jogo values (187, 2469.71, 'Fisico', 'Gokubros. 1', 3);
insert into jogo values (188, 1419.49, 'Fisico', 'Gokubros. 2', 15);
insert into jogo values (189, 2458.02, 'Digital', 'Gokubros. Remake', 8);
insert into jogo values (190, 2477.37, 'Digital', 'Gokubros. Final Boot', 7);
insert into jogo values (191, 5995.37, 'Digital', 'Gokubros. World', 4);
insert into jogo values (192, 305.61, 'Fisico', 'Gokubros. Remake', 6);
insert into jogo values (193, 7508.16, 'Fisico', 'GokuKart 1', 14);
insert into jogo values (194, 5926.78, 'Digital', 'GokuKart 2', 9);
insert into jogo values (195, 1858.07, 'Fisico', 'GokuKart Remake', 4);
insert into jogo values (196, 2489.15, 'Digital', 'GokuKart Final Boot', 7);
insert into jogo values (197, 4586.93, 'Digital', 'GokuKart World', 5);
insert into jogo values (198, 5750.44, 'Fisico', 'GokuKart Remake', 3);
insert into jogo values (199, 3183.09, 'Fisico', 'GokuKombat 1', 8);
insert into jogo values (200, 6742.35, 'Fisico', 'GokuKombat 2', 6);
insert into jogo values (201, 3945.58, 'Digital', 'GokuKombat Remake', 10);
insert into jogo values (202, 7072.46, 'Digital', 'GokuKombat Final Boot', 14);
insert into jogo values (203, 6715.09, 'Fisico', 'GokuKombat World', 4);
insert into jogo values (204, 3989.49, 'Digital', 'GokuKombat Remake', 2);
insert into jogo values (205, 6354.37, 'Digital', 'Gokuthe hunter 1', 10);
insert into jogo values (206, 4688.39, 'Digital', 'Gokuthe hunter 2', 14);
insert into jogo values (207, 5187.74, 'Fisico', 'Gokuthe hunter Remake', 9);
insert into jogo values (208, 559.19, 'Digital', 'Gokuthe hunter Final Boot', 2);
insert into jogo values (209, 4178.21, 'Digital', 'Gokuthe hunter World', 14);
insert into jogo values (210, 1518.46, 'Digital', 'Gokuthe hunter Remake', 11);
insert into jogo values (211, 4684.57, 'Digital', 'Gokugod of time1', 5);
insert into jogo values (212, 3531.43, 'Digital', 'Gokugod of time2', 5);
insert into jogo values (213, 1532.56, 'Digital', 'Gokugod of timeRemake', 10);
insert into jogo values (214, 3384.6, 'Digital', 'Gokugod of timeFinal Boot', 15);
insert into jogo values (215, 5817.09, 'Digital', 'Gokugod of timeWorld', 7);
insert into jogo values (216, 381.53, 'Digital', 'Gokugod of timeRemake', 2);

 
select insereCompra(1, 143, 210, 10);
select insereCompra(2, 50, 24, 6);
select insereCompra(3, 17, 11, 154);
select insereCompra(4, 197, 33, 59);
select insereCompra(5, 190, 202, 26);
select insereCompra(6, 156, 184, 63);
select insereCompra(7, 147, 212, 25);
select insereCompra(8, 32, 173, 122);
select insereCompra(9, 172, 93, 39);
select insereCompra(10, 67, 161, 114);
select insereCompra(11, 210, 174, 51);
select insereCompra(12, 6, 160, 152);
select insereCompra(13, 84, 197, 30);
select insereCompra(14, 149, 117, 104);
select insereCompra(15, 78, 18, 146);
select insereCompra(16, 193, 123, 36);
select insereCompra(17, 207, 202, 118);
select insereCompra(18, 67, 82, 11);
select insereCompra(19, 210, 53, 46);
select insereCompra(20, 33, 47, 9);
select insereCompra(21, 40, 111, 154);
select insereCompra(22, 46, 66, 114);
select insereCompra(23, 110, 131, 138);
select insereCompra(24, 140, 140, 146);
select insereCompra(25, 75, 15, 74);
select insereCompra(26, 66, 162, 39);
select insereCompra(27, 131, 214, 171);
select insereCompra(28, 72, 98, 68);
select insereCompra(29, 79, 166, 24);
select insereCompra(30, 137, 138, 151);
select insereCompra(31, 32, 119, 155);
select insereCompra(32, 194, 157, 7);
select insereCompra(33, 187, 66, 140);
select insereCompra(34, 36, 120, 39);
select insereCompra(35, 159, 1, 51);
select insereCompra(36, 22, 125, 95);
select insereCompra(37, 83, 85, 147);
select insereCompra(38, 21, 177, 24);
select insereCompra(39, 158, 93, 147);
select insereCompra(40, 206, 132, 42);
select insereCompra(41, 40, 181, 40);
select insereCompra(42, 57, 17, 126);
select insereCompra(43, 165, 195, 31);
select insereCompra(44, 43, 6, 86);
select insereCompra(45, 59, 98, 148);
select insereCompra(46, 114, 30, 147);
select insereCompra(47, 136, 183, 123);
select insereCompra(48, 133, 146, 8);
select insereCompra(49, 50, 19, 44);
select insereCompra(50, 105, 17, 16);
select insereCompra(51, 166, 14, 169);
select insereCompra(52, 89, 91, 36);
select insereCompra(53, 127, 188, 86);
select insereCompra(54, 140, 79, 94);
select insereCompra(55, 200, 71, 72);
select insereCompra(56, 158, 63, 71);
select insereCompra(57, 16, 176, 170);
select insereCompra(58, 113, 171, 132);
select insereCompra(59, 109, 189, 99);
select insereCompra(60, 85, 3, 124);
select insereCompra(61, 158, 33, 102);
select insereCompra(62, 30, 137, 118);
select insereCompra(63, 110, 40, 162);
select insereCompra(64, 34, 101, 139);
select insereCompra(65, 76, 18, 174);
select insereCompra(66, 66, 42, 105);
select insereCompra(67, 203, 105, 90);
select insereCompra(68, 206, 54, 114);
select insereCompra(69, 189, 158, 105);
select insereCompra(70, 57, 68, 18);
select insereCompra(71, 138, 81, 135);
select insereCompra(72, 47, 180, 123);
select insereCompra(73, 99, 216, 5);
select insereCompra(74, 113, 81, 156);
select insereCompra(75, 155, 183, 98);
select insereCompra(76, 215, 34, 19);
select insereCompra(77, 153, 105, 128);
select insereCompra(78, 215, 171, 133);
select insereCompra(79, 47, 27, 157);
select insereCompra(80, 118, 100, 31);
select insereCompra(81, 152, 101, 145);
select insereCompra(82, 187, 7, 39);
select insereCompra(83, 61, 25, 164);
select insereCompra(84, 112, 102, 115);
select insereCompra(85, 148, 194, 168);
select insereCompra(86, 33, 60, 154);
select insereCompra(87, 133, 153, 29);
select insereCompra(88, 37, 70, 60);
select insereCompra(89, 201, 28, 44);
select insereCompra(90, 170, 154, 36);
select insereCompra(91, 49, 35, 125);
select insereCompra(92, 15, 32, 123);
select insereCompra(93, 216, 20, 147);
select insereCompra(94, 128, 134, 116);
select insereCompra(95, 179, 120, 91);
select insereCompra(96, 176, 88, 86);
select insereCompra(97, 97, 193, 34);
select insereCompra(98, 188, 49, 76);
select insereCompra(99, 101, 109, 35);
select insereCompra(100, 91, 48, 43);
select insereCompra(101, 20, 194, 72);
select insereCompra(102, 87, 211, 130);
select insereCompra(103, 86, 131, 110);
select insereCompra(104, 123, 156, 51);
select insereCompra(105, 31, 80, 41);
select insereCompra(106, 60, 205, 175);
select insereCompra(107, 147, 24, 72);
select insereCompra(108, 10, 113, 160);
select insereCompra(109, 113, 124, 119);
select insereCompra(110, 110, 50, 165);
select insereCompra(111, 84, 163, 129);
select insereCompra(112, 32, 135, 27);
select insereCompra(113, 158, 16, 107);
select insereCompra(114, 142, 79, 1);
select insereCompra(115, 106, 61, 52);
select insereCompra(116, 119, 178, 119);
select insereCompra(117, 18, 172, 164);
select insereCompra(118, 173, 195, 162);
select insereCompra(119, 65, 188, 77);
select insereCompra(120, 145, 97, 30);
select insereCompra(121, 133, 113, 174);
select insereCompra(122, 184, 97, 38);
select insereCompra(123, 124, 93, 128);
select insereCompra(124, 39, 58, 159);
select insereCompra(125, 82, 176, 146);
select insereCompra(126, 124, 103, 51);
select insereCompra(127, 121, 20, 165);
select insereCompra(128, 57, 114, 30);
select insereCompra(129, 158, 123, 41);
select insereCompra(130, 167, 79, 39);
select insereCompra(131, 136, 103, 109);
select insereCompra(132, 150, 104, 34);
select insereCompra(133, 179, 70, 12);
select insereCompra(134, 92, 178, 136);
select insereCompra(135, 147, 107, 160);
select insereCompra(136, 68, 25, 79);
select insereCompra(137, 1, 154, 58);
select insereCompra(138, 105, 32, 167);
select insereCompra(139, 208, 48, 5);
select insereCompra(140, 156, 91, 121);
select insereCompra(141, 11, 194, 97);
select insereCompra(142, 67, 43, 39);
select insereCompra(143, 186, 106, 44);
select insereCompra(144, 6, 71, 89);
select insereCompra(145, 211, 154, 72);
select insereCompra(146, 142, 6, 70);
select insereCompra(147, 209, 41, 25);
select insereCompra(148, 183, 90, 158);
select insereCompra(149, 134, 148, 151);
select insereCompra(150, 157, 94, 47);
select insereCompra(151, 200, 55, 159);
select insereCompra(152, 120, 114, 22);
select insereCompra(153, 142, 28, 60);
select insereCompra(154, 110, 95, 131);
select insereCompra(155, 47, 41, 33);
select insereCompra(156, 180, 136, 11);
select insereCompra(157, 65, 216, 76);
select insereCompra(158, 123, 161, 120);
select insereCompra(159, 158, 35, 37);
select insereCompra(160, 56, 104, 133);
select insereCompra(161, 94, 36, 149);
select insereCompra(162, 74, 82, 151);
select insereCompra(163, 112, 30, 145);
select insereCompra(164, 211, 169, 157);
select insereCompra(165, 171, 118, 154);
select insereCompra(166, 204, 73, 90);
select insereCompra(167, 186, 65, 67);
select insereCompra(168, 75, 210, 168);
select insereCompra(169, 170, 58, 86);
select insereCompra(170, 210, 110, 169);
select insereCompra(171, 48, 72, 45);
select insereCompra(172, 178, 163, 86);
select insereCompra(173, 33, 20, 99);
select insereCompra(174, 72, 164, 15);
select insereCompra(175, 22, 159, 105);
select insereCompra(176, 104, 24, 97);
select insereCompra(177, 49, 141, 111);
select insereCompra(178, 153, 150, 71);
select insereCompra(179, 208, 172, 45);
select insereCompra(180, 75, 155, 19);
select insereCompra(181, 5, 84, 151);
select insereCompra(182, 124, 48, 37);
select insereCompra(183, 104, 189, 125);
select insereCompra(184, 122, 188, 145);
select insereCompra(185, 31, 39, 91);
select insereCompra(186, 155, 69, 29);
select insereCompra(187, 26, 74, 61);
select insereCompra(188, 35, 58, 128);
select insereCompra(189, 167, 75, 33);
select insereCompra(190, 123, 54, 74);
select insereCompra(191, 187, 98, 70);
select insereCompra(192, 132, 197, 66);
select insereCompra(193, 106, 6, 110);
select insereCompra(194, 38, 8, 78);
select insereCompra(195, 134, 151, 39);
select insereCompra(196, 195, 65, 108);
select insereCompra(197, 184, 143, 50);
select insereCompra(198, 193, 205, 31);
select insereCompra(199, 81, 189, 69);
select insereCompra(200, 169, 193, 72);
select insereCompra(201, 135, 76, 146);
select insereCompra(202, 164, 34, 124);
select insereCompra(203, 209, 33, 142);
select insereCompra(204, 7, 109, 104);
select insereCompra(205, 110, 37, 115);
select insereCompra(206, 141, 61, 57);
select insereCompra(207, 7, 35, 136);
select insereCompra(208, 123, 167, 142);
select insereCompra(209, 145, 1, 14);
select insereCompra(210, 177, 79, 126);
select insereCompra(211, 135, 22, 107);
select insereCompra(212, 39, 189, 174);
select insereCompra(213, 41, 158, 22);
select insereCompra(214, 169, 129, 98);
select insereCompra(215, 30, 207, 66);
select insereCompra(216, 26, 3, 157);
select insereCompra(217, 68, 148, 32);
select insereCompra(218, 78, 112, 12);
select insereCompra(219, 125, 150, 91);
select insereCompra(220, 153, 210, 108);
select insereCompra(221, 30, 11, 65);
select insereCompra(222, 159, 34, 76);
select insereCompra(223, 204, 17, 124);
select insereCompra(224, 68, 75, 130);
select insereCompra(225, 13, 59, 143);
select insereCompra(226, 175, 214, 141);
select insereCompra(227, 15, 31, 141);
select insereCompra(228, 13, 23, 54);
select insereCompra(229, 41, 40, 31);
select insereCompra(230, 3, 10, 36);
select insereCompra(231, 164, 204, 85);
select insereCompra(232, 45, 153, 34);
select insereCompra(233, 111, 101, 65);
select insereCompra(234, 215, 180, 85);
select insereCompra(235, 95, 46, 20);
select insereCompra(236, 122, 84, 50);
select insereCompra(237, 168, 118, 65);
select insereCompra(238, 171, 215, 22);
select insereCompra(239, 36, 159, 116);
select insereCompra(240, 87, 93, 147);
select insereCompra(241, 206, 155, 25);
select insereCompra(242, 119, 93, 165);
select insereCompra(243, 79, 165, 71);
select insereCompra(244, 213, 136, 29);
select insereCompra(245, 23, 46, 132);
select insereCompra(246, 115, 25, 43);
select insereCompra(247, 32, 46, 134);
select insereCompra(248, 1, 97, 59);
select insereCompra(249, 143, 161, 39);
select insereCompra(250, 83, 149, 40);
select insereCompra(251, 10, 102, 123);
select insereCompra(252, 5, 108, 136);
select insereCompra(253, 114, 41, 57);
select insereCompra(254, 146, 19, 82);
select insereCompra(255, 26, 193, 101);
select insereCompra(256, 136, 27, 79);
select insereCompra(257, 109, 93, 144);
select insereCompra(258, 141, 190, 14);
select insereCompra(259, 172, 132, 141);
select insereCompra(260, 119, 15, 155);
select insereCompra(261, 94, 200, 30);
select insereCompra(262, 168, 175, 33);
select insereCompra(263, 136, 3, 161);
select insereCompra(264, 152, 195, 71);
select insereCompra(265, 83, 102, 112);
select insereCompra(266, 145, 197, 82);
select insereCompra(267, 10, 193, 46);
select insereCompra(268, 82, 102, 1);
select insereCompra(269, 28, 61, 27);
select insereCompra(270, 164, 77, 172);
select insereCompra(271, 90, 95, 144);
select insereCompra(272, 19, 55, 63);
select insereCompra(273, 113, 212, 34);
select insereCompra(274, 23, 54, 166);
select insereCompra(275, 34, 114, 172);
select insereCompra(276, 177, 99, 54);
select insereCompra(277, 179, 79, 31);
select insereCompra(278, 147, 119, 154);
select insereCompra(279, 216, 132, 61);
select insereCompra(280, 107, 199, 150);
select insereCompra(281, 76, 121, 162);
select insereCompra(282, 192, 106, 35);
select insereCompra(283, 35, 173, 88);
select insereCompra(284, 47, 184, 52);
select insereCompra(285, 15, 127, 160);
select insereCompra(286, 57, 184, 31);
select insereCompra(287, 145, 196, 89);
select insereCompra(288, 87, 171, 130);
select insereCompra(289, 58, 59, 11);
select insereCompra(290, 124, 187, 132);
select insereCompra(291, 70, 160, 143);
select insereCompra(292, 15, 190, 76);
select insereCompra(293, 206, 208, 77);
select insereCompra(294, 167, 29, 148);
select insereCompra(295, 80, 49, 75);
select insereCompra(296, 19, 82, 95);
select insereCompra(297, 74, 39, 108);
select insereCompra(298, 56, 16, 83);
select insereCompra(299, 65, 9, 137);
select insereCompra(300, 210, 49, 132);
select insereCompra(301, 49, 66, 150);
select insereCompra(302, 14, 198, 41);
select insereCompra(303, 132, 147, 10);
select insereCompra(304, 154, 67, 34);
select insereCompra(305, 205, 204, 160);
select insereCompra(306, 124, 108, 158);
select insereCompra(307, 53, 162, 71);
select insereCompra(308, 5, 124, 48);
select insereCompra(309, 112, 12, 54);
select insereCompra(310, 74, 115, 42);
select insereCompra(311, 168, 176, 171);
select insereCompra(312, 36, 79, 117);
select insereCompra(313, 51, 209, 152);
select insereCompra(314, 197, 111, 124);
select insereCompra(315, 19, 90, 172);
select insereCompra(316, 26, 76, 97);
select insereCompra(317, 67, 195, 129);
select insereCompra(318, 21, 100, 40);
select insereCompra(319, 204, 133, 118);
select insereCompra(320, 199, 43, 68);
select insereCompra(321, 21, 96, 136);
select insereCompra(322, 170, 175, 166);
select insereCompra(323, 210, 69, 108);
select insereCompra(324, 87, 164, 12);
select insereCompra(325, 201, 107, 29);
select insereCompra(326, 42, 195, 15);
select insereCompra(327, 26, 66, 80);
select insereCompra(328, 196, 177, 64);
select insereCompra(329, 118, 30, 38);
select insereCompra(330, 136, 53, 46);
select insereCompra(331, 146, 176, 142);
select insereCompra(332, 183, 204, 134);
select insereCompra(333, 130, 14, 58);
select insereCompra(334, 207, 71, 16);
select insereCompra(335, 126, 212, 161);
select insereCompra(336, 99, 203, 57);
select insereCompra(337, 201, 195, 4);
select insereCompra(338, 199, 2, 15);
select insereCompra(339, 72, 124, 120);
select insereCompra(340, 117, 139, 129);
select insereCompra(341, 36, 92, 137);
select insereCompra(342, 6, 171, 171);
select insereCompra(343, 46, 196, 76);
select insereCompra(344, 74, 182, 23);
select insereCompra(345, 210, 64, 54);
select insereCompra(346, 162, 10, 13);
select insereCompra(347, 216, 89, 79);
select insereCompra(348, 173, 152, 134);
select insereCompra(349, 36, 213, 127);
select insereCompra(350, 214, 2, 155);
select insereCompra(351, 6, 196, 170);
select insereCompra(352, 47, 93, 171);
select insereCompra(353, 212, 196, 45);
select insereCompra(354, 48, 194, 28);
select insereCompra(355, 153, 97, 13);
select insereCompra(356, 174, 48, 112);
select insereCompra(357, 70, 26, 109);
select insereCompra(358, 18, 148, 55);
select insereCompra(359, 51, 97, 49);
select insereCompra(360, 18, 64, 17);
select insereCompra(361, 51, 84, 120);
select insereCompra(362, 39, 102, 60);
select insereCompra(363, 25, 67, 154);
select insereCompra(364, 165, 68, 160);
select insereCompra(365, 34, 114, 60);
select insereCompra(366, 58, 20, 119);
select insereCompra(367, 14, 163, 27);
select insereCompra(368, 105, 54, 155);
select insereCompra(369, 84, 62, 10);
select insereCompra(370, 152, 3, 51);
select insereCompra(371, 74, 70, 13);
select insereCompra(372, 157, 109, 94);
select insereCompra(373, 36, 215, 108);
select insereCompra(374, 191, 22, 124);
select insereCompra(375, 171, 205, 149);
select insereCompra(376, 52, 160, 168);
select insereCompra(377, 203, 120, 103);
select insereCompra(378, 44, 66, 75);
select insereCompra(379, 144, 87, 171);
select insereCompra(380, 101, 56, 128);
select insereCompra(381, 13, 75, 70);
select insereCompra(382, 200, 2, 25);
select insereCompra(383, 154, 50, 24);
select insereCompra(384, 123, 212, 102);
select insereCompra(385, 1, 176, 85);
select insereCompra(386, 92, 18, 146);
select insereCompra(387, 215, 79, 73);
select insereCompra(388, 18, 148, 152);
select insereCompra(389, 110, 119, 16);
select insereCompra(390, 77, 15, 65);
select insereCompra(391, 30, 59, 71);
select insereCompra(392, 57, 212, 60);
select insereCompra(393, 83, 96, 91);
select insereCompra(394, 198, 131, 82);
select insereCompra(395, 148, 104, 140);
select insereCompra(396, 95, 40, 113);
select insereCompra(397, 1, 173, 128);
select insereCompra(398, 212, 3, 149);
select insereCompra(399, 180, 207, 151);
select insereCompra(400, 22, 155, 163);
select insereCompra(401, 206, 49, 115);
select insereCompra(402, 201, 169, 129);
select insereCompra(403, 191, 161, 56);
select insereCompra(404, 199, 5, 147);
select insereCompra(405, 156, 6, 11);
select insereCompra(406, 42, 160, 91);
select insereCompra(407, 146, 113, 35);
select insereCompra(408, 117, 102, 84);
select insereCompra(409, 121, 72, 99);
select insereCompra(410, 48, 56, 117);
select insereCompra(411, 36, 49, 59);
select insereCompra(412, 59, 56, 59);
select insereCompra(413, 137, 166, 50);
select insereCompra(414, 12, 25, 65);
select insereCompra(415, 189, 85, 78);
select insereCompra(416, 198, 3, 91);
select insereCompra(417, 116, 141, 5);
select insereCompra(418, 42, 26, 116);
select insereCompra(419, 17, 137, 71);
select insereCompra(420, 80, 67, 121);
select insereCompra(421, 135, 195, 48);
select insereCompra(422, 94, 146, 34);
select insereCompra(423, 187, 97, 91);
select insereCompra(424, 73, 83, 45);
select insereCompra(425, 107, 129, 46);
select insereCompra(426, 113, 158, 14);
select insereCompra(427, 142, 88, 49);
select insereCompra(428, 208, 110, 98);
select insereCompra(429, 105, 109, 123);
select insereCompra(430, 71, 91, 153);
select insereCompra(431, 22, 99, 161);
select insereCompra(432, 190, 20, 100);
select insereCompra(433, 167, 51, 22);
select insereCompra(434, 152, 216, 162);
select insereCompra(435, 71, 109, 54);
select insereCompra(436, 154, 127, 76);
select insereCompra(437, 28, 146, 165);
select insereCompra(438, 180, 157, 160);
select insereCompra(439, 21, 6, 15);
select insereCompra(440, 19, 133, 174);
select insereCompra(441, 119, 62, 106);
select insereCompra(442, 166, 176, 40);
select insereCompra(443, 51, 6, 120);
select insereCompra(444, 63, 160, 108);
select insereCompra(445, 86, 92, 157);
select insereCompra(446, 17, 158, 63);
select insereCompra(447, 59, 115, 89);
select insereCompra(448, 114, 87, 38);
select insereCompra(449, 96, 196, 155);
select insereCompra(450, 84, 2, 34);
select insereCompra(451, 172, 112, 57);
select insereCompra(452, 9, 18, 160);
select insereCompra(453, 70, 96, 37);
select insereCompra(454, 148, 93, 160);
select insereCompra(455, 149, 91, 163);
select insereCompra(456, 31, 10, 145);
select insereCompra(457, 86, 35, 75);
select insereCompra(458, 129, 35, 169);
select insereCompra(459, 47, 47, 121);
select insereCompra(460, 144, 140, 114);
select insereCompra(461, 135, 212, 128);
select insereCompra(462, 49, 141, 67);
select insereCompra(463, 58, 164, 119);
select insereCompra(464, 60, 116, 129);
select insereCompra(465, 191, 131, 169);
select insereCompra(466, 62, 9, 165);
select insereCompra(467, 95, 84, 173);
select insereCompra(468, 197, 209, 128);
select insereCompra(469, 80, 38, 17);
select insereCompra(470, 211, 7, 60);
select insereCompra(471, 211, 143, 98);
select insereCompra(472, 183, 130, 35);
select insereCompra(473, 124, 62, 110);
select insereCompra(474, 203, 19, 110);
select insereCompra(475, 214, 116, 33);
select insereCompra(476, 154, 45, 113);
select insereCompra(477, 191, 3, 60);
select insereCompra(478, 60, 20, 2);
select insereCompra(479, 89, 61, 165);
select insereCompra(480, 61, 12, 32);
select insereCompra(481, 88, 182, 109);
select insereCompra(482, 199, 202, 39);
select insereCompra(483, 63, 42, 21);
select insereCompra(484, 151, 93, 99);
select insereCompra(485, 16, 73, 37);
select insereCompra(486, 35, 188, 69);
select insereCompra(487, 107, 62, 89);
select insereCompra(488, 42, 87, 94);
select insereCompra(489, 84, 10, 31);
select insereCompra(490, 28, 214, 137);
select insereCompra(491, 32, 197, 166);
select insereCompra(492, 113, 69, 14);
select insereCompra(493, 71, 15, 174);
select insereCompra(494, 49, 50, 27);
select insereCompra(495, 39, 46, 42);
select insereCompra(496, 148, 127, 103);
select insereCompra(497, 137, 153, 114);
select insereCompra(498, 132, 124, 133);
select insereCompra(499, 18, 207, 107);
select insereCompra(500, 205, 84, 32);
select insereCompra(501, 29, 53, 18);
select insereCompra(502, 127, 70, 40);
select insereCompra(503, 142, 96, 175);
select insereCompra(504, 197, 74, 8);
select insereCompra(505, 150, 187, 23);
select insereCompra(506, 211, 197, 65);
select insereCompra(507, 49, 216, 163);
select insereCompra(508, 63, 72, 20);
select insereCompra(509, 6, 42, 85);
select insereCompra(510, 85, 212, 20);
select insereCompra(511, 112, 202, 77);
select insereCompra(512, 10, 31, 30);
select insereCompra(513, 71, 33, 69);
select insereCompra(514, 132, 144, 93);
select insereCompra(515, 115, 168, 53);
select insereCompra(516, 58, 125, 160);
select insereCompra(517, 28, 34, 100);
select insereCompra(518, 19, 211, 113);
select insereCompra(519, 147, 91, 122);
select insereCompra(520, 216, 126, 143);
select insereCompra(521, 16, 147, 130);
select insereCompra(522, 53, 163, 143);
select insereCompra(523, 108, 139, 163);
select insereCompra(524, 206, 95, 32);
select insereCompra(525, 72, 188, 11);
select insereCompra(526, 43, 30, 58);
select insereCompra(527, 70, 196, 146);
select insereCompra(528, 102, 113, 7);
select insereCompra(529, 183, 129, 65);
select insereCompra(530, 176, 20, 51);
select insereCompra(531, 141, 56, 100);
select insereCompra(532, 162, 19, 156);
select insereCompra(533, 99, 207, 76);
select insereCompra(534, 12, 105, 57);
select insereCompra(535, 127, 161, 168);
select insereCompra(536, 213, 71, 104);
select insereCompra(537, 88, 21, 34);
select insereCompra(538, 210, 38, 165);
select insereCompra(539, 193, 210, 42);
select insereCompra(540, 210, 183, 76);
select insereCompra(541, 111, 171, 70);
select insereCompra(542, 153, 183, 164);
select insereCompra(543, 185, 61, 92);
select insereCompra(544, 65, 46, 25);
select insereCompra(545, 35, 55, 175);
select insereCompra(546, 115, 113, 175);
select insereCompra(547, 128, 216, 42);
select insereCompra(548, 164, 114, 164);
select insereCompra(549, 170, 15, 144);
select insereCompra(550, 116, 177, 16);
select insereCompra(551, 20, 41, 74);
select insereCompra(552, 64, 78, 64);
select insereCompra(553, 44, 167, 1);
select insereCompra(554, 89, 66, 97);
select insereCompra(555, 38, 88, 128);
select insereCompra(556, 180, 131, 10);
select insereCompra(557, 87, 143, 137);
select insereCompra(558, 144, 135, 27);
select insereCompra(559, 142, 190, 47);
select insereCompra(560, 83, 101, 135);
select insereCompra(561, 144, 187, 18);
select insereCompra(562, 20, 175, 149);
select insereCompra(563, 26, 11, 57);
select insereCompra(564, 34, 147, 27);
select insereCompra(565, 117, 1, 127);
select insereCompra(566, 210, 112, 75);
select insereCompra(567, 137, 191, 54);
select insereCompra(568, 159, 55, 127);
select insereCompra(569, 60, 128, 42);
select insereCompra(570, 172, 109, 4);
select insereCompra(571, 149, 100, 73);
select insereCompra(572, 152, 62, 90);
select insereCompra(573, 110, 17, 139);
select insereCompra(574, 24, 82, 114);
select insereCompra(575, 109, 167, 45);
select insereCompra(576, 117, 21, 78);
select insereCompra(577, 63, 91, 69);
select insereCompra(578, 134, 204, 81);
select insereCompra(579, 52, 113, 138);
select insereCompra(580, 4, 174, 43);
select insereCompra(581, 172, 162, 56);
select insereCompra(582, 17, 130, 34);
select insereCompra(583, 15, 19, 166);
select insereCompra(584, 188, 65, 58);
select insereCompra(585, 96, 96, 99);
select insereCompra(586, 171, 10, 138);
select insereCompra(587, 153, 153, 20);
select insereCompra(588, 184, 64, 89);
select insereCompra(589, 141, 184, 123);
select insereCompra(590, 29, 51, 21);
select insereCompra(591, 49, 39, 77);
select insereCompra(592, 66, 146, 136);
select insereCompra(593, 209, 112, 97);
select insereCompra(594, 193, 181, 11);
select insereCompra(595, 142, 128, 130);
select insereCompra(596, 1, 23, 69);
select insereCompra(597, 13, 178, 140);
select insereCompra(598, 181, 183, 39);
select insereCompra(599, 136, 98, 161);
select insereCompra(600, 26, 7, 39);
select insereCompra(601, 75, 185, 51);
select insereCompra(602, 124, 107, 95);
select insereCompra(603, 203, 80, 7);
select insereCompra(604, 28, 216, 37);
select insereCompra(605, 179, 3, 27);
select insereCompra(606, 215, 94, 98);
select insereCompra(607, 157, 97, 56);
select insereCompra(608, 90, 172, 48);
select insereCompra(609, 160, 88, 150);
select insereCompra(610, 80, 127, 141);
select insereCompra(611, 143, 8, 83);
select insereCompra(612, 112, 27, 112);
select insereCompra(613, 28, 67, 160);
select insereCompra(614, 61, 175, 154);
select insereCompra(615, 36, 138, 74);
select insereCompra(616, 171, 98, 10);
select insereCompra(617, 20, 61, 175);
select insereCompra(618, 174, 179, 89);
select insereCompra(619, 61, 78, 4);
select insereCompra(620, 135, 94, 110);
select insereCompra(621, 215, 151, 28);
select insereCompra(622, 25, 21, 126);
select insereCompra(623, 66, 195, 115);
select insereCompra(624, 4, 161, 167);
select insereCompra(625, 206, 216, 160);
select insereCompra(626, 199, 78, 68);
select insereCompra(627, 190, 51, 139);
select insereCompra(628, 5, 50, 73);
select insereCompra(629, 79, 107, 43);
select insereCompra(630, 200, 37, 100);
select insereCompra(631, 54, 36, 157);
select insereCompra(632, 68, 134, 156);
select insereCompra(633, 107, 187, 120);
select insereCompra(634, 198, 149, 34);
select insereCompra(635, 159, 72, 82);
select insereCompra(636, 82, 17, 26);
select insereCompra(637, 47, 149, 88);
select insereCompra(638, 151, 77, 112);
select insereCompra(639, 31, 71, 156);
select insereCompra(640, 152, 160, 136);
select insereCompra(641, 183, 101, 60);
select insereCompra(642, 2, 115, 73);
select insereCompra(643, 95, 142, 61);
select insereCompra(644, 1, 165, 9);
select insereCompra(645, 200, 125, 155);
select insereCompra(646, 127, 173, 55);
select insereCompra(647, 107, 87, 62);
select insereCompra(648, 55, 24, 113);
select insereCompra(649, 148, 68, 21);
select insereCompra(650, 181, 29, 24);
select insereCompra(651, 64, 143, 164);
select insereCompra(652, 158, 216, 23);
select insereCompra(653, 142, 6, 58);
select insereCompra(654, 117, 182, 84);
select insereCompra(655, 42, 28, 168);
select insereCompra(656, 60, 158, 104);
select insereCompra(657, 96, 34, 36);
select insereCompra(658, 211, 160, 17);
select insereCompra(659, 86, 65, 72);
select insereCompra(660, 57, 108, 150);
select insereCompra(661, 124, 197, 104);
select insereCompra(662, 62, 152, 72);
select insereCompra(663, 111, 7, 97);
select insereCompra(664, 83, 5, 157);
select insereCompra(665, 46, 182, 63);
select insereCompra(666, 182, 57, 109);
select insereCompra(667, 27, 171, 79);
select insereCompra(668, 79, 65, 16);
select insereCompra(669, 160, 139, 32);
select insereCompra(670, 190, 169, 145);
select insereCompra(671, 45, 76, 55);
select insereCompra(672, 39, 67, 142);
select insereCompra(673, 151, 90, 118);
select insereCompra(674, 147, 184, 145);
select insereCompra(675, 205, 80, 159);
select insereCompra(676, 49, 75, 34);
select insereCompra(677, 79, 146, 174);
select insereCompra(678, 116, 2, 100);
select insereCompra(679, 83, 211, 16);
select insereCompra(680, 125, 29, 132);
select insereCompra(681, 106, 1, 159);
select insereCompra(682, 179, 19, 111);
select insereCompra(683, 5, 138, 120);
select insereCompra(684, 114, 47, 101);
select insereCompra(685, 127, 8, 122);
select insereCompra(686, 67, 29, 60);
select insereCompra(687, 189, 170, 19);
select insereCompra(688, 133, 5, 55);
select insereCompra(689, 28, 105, 92);
select insereCompra(690, 189, 68, 85);
select insereCompra(691, 210, 123, 29);
select insereCompra(692, 93, 3, 129);
select insereCompra(693, 180, 150, 171);
select insereCompra(694, 23, 188, 23);
select insereCompra(695, 79, 208, 157);
select insereCompra(696, 12, 137, 10);
select insereCompra(697, 170, 103, 148);
select insereCompra(698, 210, 52, 57);
select insereCompra(699, 215, 107, 135);
select insereCompra(700, 165, 100, 140);
select insereCompra(701, 5, 22, 78);
select insereCompra(702, 136, 169, 118);
select insereCompra(703, 192, 184, 49);
select insereCompra(704, 34, 150, 6);
select insereCompra(705, 113, 75, 16);
select insereCompra(706, 86, 66, 90);
select insereCompra(707, 7, 142, 20);
select insereCompra(708, 59, 162, 28);
select insereCompra(709, 70, 92, 85);
select insereCompra(710, 72, 214, 69);
select insereCompra(711, 47, 193, 61);
select insereCompra(712, 10, 160, 148);
select insereCompra(713, 21, 99, 124);
select insereCompra(714, 211, 13, 21);
select insereCompra(715, 98, 178, 127);
select insereCompra(716, 140, 115, 31);
select insereCompra(717, 166, 207, 146);
select insereCompra(718, 54, 43, 126);
select insereCompra(719, 57, 165, 42);
select insereCompra(720, 166, 56, 60);
select insereCompra(721, 107, 165, 40);
select insereCompra(722, 139, 122, 49);
select insereCompra(723, 198, 34, 139);
select insereCompra(724, 12, 100, 29);
select insereCompra(725, 132, 22, 166);
select insereCompra(726, 40, 186, 17);
select insereCompra(727, 115, 49, 113);
select insereCompra(728, 24, 101, 59);
select insereCompra(729, 7, 3, 147);
select insereCompra(730, 39, 83, 20);
select insereCompra(731, 137, 165, 174);
select insereCompra(732, 63, 21, 119);
select insereCompra(733, 93, 82, 69);
select insereCompra(734, 41, 209, 100);
select insereCompra(735, 191, 129, 107);
select insereCompra(736, 17, 33, 156);
select insereCompra(737, 143, 60, 92);
select insereCompra(738, 94, 94, 15);
select insereCompra(739, 69, 42, 136);
select insereCompra(740, 201, 8, 145);
select insereCompra(741, 86, 123, 127);
select insereCompra(742, 8, 104, 170);
select insereCompra(743, 95, 114, 92);
select insereCompra(744, 99, 17, 169);
select insereCompra(745, 203, 179, 115);
select insereCompra(746, 152, 44, 29);
select insereCompra(747, 131, 174, 105);
select insereCompra(748, 74, 8, 104);
select insereCompra(749, 82, 169, 169);
select insereCompra(750, 172, 67, 115);
select insereCompra(751, 47, 84, 81);
select insereCompra(752, 89, 32, 90);
select insereCompra(753, 109, 142, 48);
select insereCompra(754, 212, 184, 145);
select insereCompra(755, 32, 193, 175);
select insereCompra(756, 58, 35, 13);
select insereCompra(757, 173, 28, 20);
select insereCompra(758, 195, 183, 120);
select insereCompra(759, 115, 189, 96);
select insereCompra(760, 79, 208, 170);
select insereCompra(761, 84, 181, 104);
select insereCompra(762, 54, 48, 82);
select insereCompra(763, 89, 214, 60);
select insereCompra(764, 144, 60, 53);
select insereCompra(765, 78, 23, 4);
select insereCompra(766, 1, 34, 36);
select insereCompra(767, 35, 135, 124);
select insereCompra(768, 100, 117, 137);
select insereCompra(769, 138, 67, 41);
select insereCompra(770, 88, 30, 33);
select insereCompra(771, 26, 204, 98);
select insereCompra(772, 148, 41, 142);
select insereCompra(773, 204, 213, 131);
select insereCompra(774, 38, 97, 157);
select insereCompra(775, 99, 46, 107);
select insereCompra(776, 179, 75, 28);
select insereCompra(777, 19, 214, 2);
select insereCompra(778, 198, 128, 73);
select insereCompra(779, 132, 194, 168);
select insereCompra(780, 185, 161, 38);
select insereCompra(781, 29, 42, 120);
select insereCompra(782, 3, 98, 112);
select insereCompra(783, 149, 128, 163);
select insereCompra(784, 22, 62, 171);
select insereCompra(785, 45, 154, 134);
select insereCompra(786, 211, 186, 49);
select insereCompra(787, 36, 205, 60);
select insereCompra(788, 59, 115, 91);
select insereCompra(789, 88, 44, 102);
select insereCompra(790, 140, 54, 162);
select insereCompra(791, 210, 119, 110);
select insereCompra(792, 66, 21, 167);
select insereCompra(793, 21, 209, 135);
select insereCompra(794, 132, 18, 48);
select insereCompra(795, 44, 103, 160);
select insereCompra(796, 176, 152, 144);
select insereCompra(797, 157, 166, 159);
select insereCompra(798, 69, 127, 89);
select insereCompra(799, 12, 106, 66);
select insereCompra(800, 8, 26, 136);
select insereCompra(801, 122, 149, 163);
select insereCompra(802, 71, 101, 89);
select insereCompra(803, 97, 12, 33);
select insereCompra(804, 7, 208, 172);
select insereCompra(805, 97, 34, 28);
select insereCompra(806, 81, 60, 72);
select insereCompra(807, 34, 45, 4);
select insereCompra(808, 110, 181, 104);
select insereCompra(809, 74, 84, 44);
select insereCompra(810, 91, 51, 55);
select insereCompra(811, 47, 77, 97);
select insereCompra(812, 17, 158, 63);
select insereCompra(813, 132, 173, 162);
select insereCompra(814, 150, 62, 60);
select insereCompra(815, 19, 88, 132);
select insereCompra(816, 15, 71, 142);
select insereCompra(817, 47, 124, 171);
select insereCompra(818, 216, 106, 64);
select insereCompra(819, 4, 141, 60);
select insereCompra(820, 6, 158, 9);
select insereCompra(821, 203, 103, 84);
select insereCompra(822, 1, 110, 149);
select insereCompra(823, 130, 94, 56);
select insereCompra(824, 67, 185, 117);
select insereCompra(825, 157, 113, 135);
select insereCompra(826, 199, 11, 138);
select insereCompra(827, 11, 117, 97);
select insereCompra(828, 83, 180, 163);
select insereCompra(829, 155, 21, 128);
select insereCompra(830, 82, 204, 164);
select insereCompra(831, 66, 28, 157);
select insereCompra(832, 23, 174, 124);
select insereCompra(833, 35, 53, 147);
select insereCompra(834, 189, 153, 128);
select insereCompra(835, 156, 100, 169);
select insereCompra(836, 152, 190, 51);
select insereCompra(837, 45, 20, 139);
select insereCompra(838, 22, 159, 17);
select insereCompra(839, 206, 66, 12);
select insereCompra(840, 64, 179, 76);
select insereCompra(841, 17, 190, 167);
select insereCompra(842, 166, 34, 27);
select insereCompra(843, 50, 57, 78);
select insereCompra(844, 165, 135, 38);
select insereCompra(845, 98, 14, 11);
select insereCompra(846, 56, 87, 141);
select insereCompra(847, 81, 104, 117);
select insereCompra(848, 63, 192, 32);
select insereCompra(849, 165, 27, 49);
select insereCompra(850, 216, 178, 113);
select insereCompra(851, 211, 133, 160);
select insereCompra(852, 211, 31, 168);
select insereCompra(853, 76, 206, 106);
select insereCompra(854, 78, 64, 141);
select insereCompra(855, 31, 19, 170);
select insereCompra(856, 188, 77, 78);
select insereCompra(857, 52, 88, 107);
select insereCompra(858, 156, 27, 135);
select insereCompra(859, 193, 166, 160);
select insereCompra(860, 87, 10, 70);
select insereCompra(861, 133, 154, 24);
select insereCompra(862, 66, 147, 47);
select insereCompra(863, 214, 168, 18);
select insereCompra(864, 114, 116, 81);
select insereCompra(865, 5, 161, 175);
select insereCompra(866, 4, 41, 148);
select insereCompra(867, 139, 165, 153);
select insereCompra(868, 14, 89, 20);
select insereCompra(869, 101, 72, 21);
select insereCompra(870, 57, 210, 154);
select insereCompra(871, 116, 39, 12);
select insereCompra(872, 1, 119, 133);
select insereCompra(873, 158, 187, 139);
select insereCompra(874, 82, 169, 21);
select insereCompra(875, 215, 147, 125);
select insereCompra(876, 188, 38, 43);
select insereCompra(877, 23, 38, 83);
select insereCompra(878, 127, 202, 136);
select insereCompra(879, 39, 18, 84);
select insereCompra(880, 20, 30, 102);
select insereCompra(881, 97, 118, 52);
select insereCompra(882, 70, 18, 84);
select insereCompra(883, 28, 193, 72);
select insereCompra(884, 97, 57, 65);
select insereCompra(885, 203, 164, 164);
select insereCompra(886, 159, 199, 45);
select insereCompra(887, 180, 118, 60);
select insereCompra(888, 6, 67, 16);
select insereCompra(889, 142, 40, 54);
select insereCompra(890, 12, 204, 158);
select insereCompra(891, 192, 75, 108);
select insereCompra(892, 117, 147, 84);
select insereCompra(893, 215, 8, 155);
select insereCompra(894, 95, 163, 167);
select insereCompra(895, 154, 204, 162);
select insereCompra(896, 202, 197, 65);
select insereCompra(897, 140, 206, 68);
select insereCompra(898, 40, 97, 69);
select insereCompra(899, 136, 210, 71);
select insereCompra(900, 152, 11, 27);
select insereCompra(901, 67, 14, 89);
select insereCompra(902, 204, 72, 170);
select insereCompra(903, 65, 214, 168);
select insereCompra(904, 140, 7, 141);
select insereCompra(905, 149, 5, 135);
select insereCompra(906, 138, 29, 138);
select insereCompra(907, 195, 71, 121);
select insereCompra(908, 162, 51, 102);
select insereCompra(909, 119, 18, 97);
select insereCompra(910, 122, 36, 92);
select insereCompra(911, 118, 27, 145);
select insereCompra(912, 74, 200, 103);
select insereCompra(913, 176, 211, 41);
select insereCompra(914, 57, 206, 81);
select insereCompra(915, 144, 127, 149);
select insereCompra(916, 188, 79, 1);
select insereCompra(917, 216, 62, 38);
select insereCompra(918, 141, 109, 94);
select insereCompra(919, 151, 86, 14);
select insereCompra(920, 74, 156, 78);
select insereCompra(921, 121, 213, 124);
select insereCompra(922, 137, 188, 159);
select insereCompra(923, 41, 140, 165);
select insereCompra(924, 39, 7, 107);
select insereCompra(925, 29, 81, 31);
select insereCompra(926, 3, 35, 124);
select insereCompra(927, 197, 216, 35);
select insereCompra(928, 205, 81, 91);
select insereCompra(929, 112, 52, 141);
select insereCompra(930, 177, 156, 86);
select insereCompra(931, 100, 105, 32);
select insereCompra(932, 64, 150, 131);
select insereCompra(933, 201, 160, 55);
select insereCompra(934, 100, 11, 169);
select insereCompra(935, 29, 139, 21);
select insereCompra(936, 41, 105, 22);
select insereCompra(937, 41, 209, 102);
select insereCompra(938, 169, 203, 46);
select insereCompra(939, 35, 147, 94);
select insereCompra(940, 89, 119, 20);
select insereCompra(941, 83, 142, 45);
select insereCompra(942, 109, 200, 104);
select insereCompra(943, 176, 212, 172);
select insereCompra(944, 83, 196, 121);
select insereCompra(945, 61, 102, 10);
select insereCompra(946, 106, 211, 167);
select insereCompra(947, 125, 181, 118);
select insereCompra(948, 150, 108, 44);
select insereCompra(949, 199, 5, 144);
select insereCompra(950, 87, 57, 143);
select insereCompra(951, 76, 106, 28);
select insereCompra(952, 9, 213, 164);
select insereCompra(953, 74, 35, 50);
select insereCompra(954, 82, 121, 85);
select insereCompra(955, 151, 77, 140);
select insereCompra(956, 164, 130, 36);
select insereCompra(957, 116, 85, 163);
select insereCompra(958, 85, 195, 106);
select insereCompra(959, 200, 63, 137);
select insereCompra(960, 63, 60, 163);
select insereCompra(961, 172, 205, 6);
select insereCompra(962, 29, 108, 8);
select insereCompra(963, 206, 111, 174);
select insereCompra(964, 9, 61, 81);
select insereCompra(965, 151, 19, 151);
select insereCompra(966, 106, 2, 112);
select insereCompra(967, 213, 213, 29);
select insereCompra(968, 178, 2, 66);
select insereCompra(969, 18, 69, 91);
select insereCompra(970, 48, 18, 131);
select insereCompra(971, 17, 154, 87);
select insereCompra(972, 162, 9, 33);
select insereCompra(973, 45, 45, 147);
select insereCompra(974, 12, 58, 32);
select insereCompra(975, 204, 115, 170);
select insereCompra(976, 77, 30, 64);
select insereCompra(977, 92, 162, 87);
select insereCompra(978, 197, 141, 54);
select insereCompra(979, 107, 152, 73);
select insereCompra(980, 122, 201, 142);
select insereCompra(981, 176, 67, 67);
select insereCompra(982, 171, 11, 148);
select insereCompra(983, 168, 140, 101);
select insereCompra(984, 205, 186, 23);
select insereCompra(985, 205, 211, 102);
select insereCompra(986, 93, 37, 62);
select insereCompra(987, 38, 212, 59);
select insereCompra(988, 15, 142, 126);
select insereCompra(989, 130, 26, 25);
select insereCompra(990, 114, 210, 116);
select insereCompra(991, 76, 128, 102);
select insereCompra(992, 36, 131, 108);
select insereCompra(993, 79, 124, 74);
select insereCompra(994, 23, 19, 105);
select insereCompra(995, 159, 118, 56);
select insereCompra(996, 61, 149, 154);
select insereCompra(997, 139, 149, 72);
select insereCompra(998, 19, 191, 26);
select insereCompra(999, 162, 81, 68);
select insereCompra(1000, 28, 122, 129);

 
call renomeiaEstabelecimento(113, 'Loja1'); 
call renomeiaEstabelecimento(40, 'Loja2'); 
call renomeiaEstabelecimento(30, 'Loja3'); 
call renomeiaEstabelecimento(149, 'Loja4'); 
call renomeiaEstabelecimento(102, 'Loja5'); 
call renomeiaEstabelecimento(81, 'Loja6'); 
call renomeiaEstabelecimento(17, 'Loja7'); 
call renomeiaEstabelecimento(98, 'Loja8'); 
call renomeiaEstabelecimento(96, 'Loja9'); 
call renomeiaEstabelecimento(85, 'Loja10'); 
call renomeiaEstabelecimento(26, 'Loja11'); 
call renomeiaEstabelecimento(28, 'Loja12'); 
call renomeiaEstabelecimento(123, 'Loja13'); 
call renomeiaEstabelecimento(90, 'Loja14'); 
call renomeiaEstabelecimento(96, 'Loja15'); 
call renomeiaEstabelecimento(41, 'Loja16'); 
call renomeiaEstabelecimento(87, 'Loja17'); 
call renomeiaEstabelecimento(37, 'Loja18'); 
call renomeiaEstabelecimento(137, 'Loja19'); 
call renomeiaEstabelecimento(117, 'Loja20'); 
call renomeiaEstabelecimento(76, 'Loja21'); 
call renomeiaEstabelecimento(87, 'Loja22'); 
call renomeiaEstabelecimento(41, 'Loja23'); 
call renomeiaEstabelecimento(41, 'Loja24'); 
call renomeiaEstabelecimento(131, 'Loja25'); 
call renomeiaEstabelecimento(167, 'Loja26'); 
call renomeiaEstabelecimento(101, 'Loja27'); 
call renomeiaEstabelecimento(62, 'Loja28'); 
call renomeiaEstabelecimento(96, 'Loja29'); 
call renomeiaEstabelecimento(30, 'Loja30'); 
call renomeiaEstabelecimento(144, 'Loja31'); 
call renomeiaEstabelecimento(134, 'Loja32'); 
call renomeiaEstabelecimento(17, 'Loja33'); 
call renomeiaEstabelecimento(9, 'Loja34'); 
call renomeiaEstabelecimento(152, 'Loja35'); 
call renomeiaEstabelecimento(35, 'Loja36'); 
call renomeiaEstabelecimento(20, 'Loja37'); 
call renomeiaEstabelecimento(69, 'Loja38'); 
call renomeiaEstabelecimento(167, 'Loja39'); 
call renomeiaEstabelecimento(87, 'Loja40'); 
call renomeiaEstabelecimento(21, 'Loja41'); 
call renomeiaEstabelecimento(15, 'Loja42'); 
call renomeiaEstabelecimento(35, 'Loja43'); 
call renomeiaEstabelecimento(7, 'Loja44'); 
call renomeiaEstabelecimento(16, 'Loja45'); 
call renomeiaEstabelecimento(101, 'Loja46'); 
call renomeiaEstabelecimento(16, 'Loja47'); 
call renomeiaEstabelecimento(42, 'Loja48'); 
call renomeiaEstabelecimento(174, 'Loja49'); 
call renomeiaEstabelecimento(92, 'Loja50'); 
call renomeiaEstabelecimento(22, 'Loja51'); 
call renomeiaEstabelecimento(46, 'Loja52'); 
call renomeiaEstabelecimento(54, 'Loja53'); 
call renomeiaEstabelecimento(137, 'Loja54'); 
call renomeiaEstabelecimento(135, 'Loja55'); 
call renomeiaEstabelecimento(63, 'Loja56'); 
call renomeiaEstabelecimento(156, 'Loja57'); 
call renomeiaEstabelecimento(55, 'Loja58'); 
call renomeiaEstabelecimento(59, 'Loja59'); 
call renomeiaEstabelecimento(160, 'Loja60'); 
call renomeiaEstabelecimento(123, 'Loja61'); 
call renomeiaEstabelecimento(168, 'Loja62'); 
call renomeiaEstabelecimento(72, 'Loja63'); 
call renomeiaEstabelecimento(107, 'Loja64'); 
call renomeiaEstabelecimento(32, 'Loja65'); 
call renomeiaEstabelecimento(113, 'Loja66'); 
call renomeiaEstabelecimento(23, 'Loja67'); 
call renomeiaEstabelecimento(40, 'Loja68'); 
call renomeiaEstabelecimento(145, 'Loja69'); 
call renomeiaEstabelecimento(49, 'Loja70'); 
call renomeiaEstabelecimento(77, 'Loja71'); 
call renomeiaEstabelecimento(1, 'Loja72'); 
call renomeiaEstabelecimento(65, 'Loja73'); 
call renomeiaEstabelecimento(47, 'Loja74'); 
call renomeiaEstabelecimento(155, 'Loja75'); 
call renomeiaEstabelecimento(103, 'Loja76'); 
call renomeiaEstabelecimento(58, 'Loja77'); 
call renomeiaEstabelecimento(173, 'Loja78'); 
call renomeiaEstabelecimento(12, 'Loja79'); 
call renomeiaEstabelecimento(67, 'Loja80'); 
call renomeiaEstabelecimento(23, 'Loja81'); 
call renomeiaEstabelecimento(56, 'Loja82'); 
call renomeiaEstabelecimento(19, 'Loja83'); 
call renomeiaEstabelecimento(65, 'Loja84'); 
call renomeiaEstabelecimento(117, 'Loja85'); 
call renomeiaEstabelecimento(21, 'Loja86'); 
call renomeiaEstabelecimento(10, 'Loja87'); 
call renomeiaEstabelecimento(174, 'Loja88'); 
call renomeiaEstabelecimento(47, 'Loja89'); 
call renomeiaEstabelecimento(157, 'Loja90'); 
call renomeiaEstabelecimento(46, 'Loja91'); 
call renomeiaEstabelecimento(93, 'Loja92'); 
call renomeiaEstabelecimento(146, 'Loja93'); 
call renomeiaEstabelecimento(67, 'Loja94'); 
call renomeiaEstabelecimento(135, 'Loja95'); 
call renomeiaEstabelecimento(134, 'Loja96'); 
call renomeiaEstabelecimento(47, 'Loja97'); 
call renomeiaEstabelecimento(88, 'Loja98'); 
call renomeiaEstabelecimento(155, 'Loja99'); 
call renomeiaEstabelecimento(27, 'Loja100'); 
call renomeiaEstabelecimento(9, 'Loja101'); 
call renomeiaEstabelecimento(149, 'Loja102'); 
call renomeiaEstabelecimento(60, 'Loja103'); 
call renomeiaEstabelecimento(144, 'Loja104'); 
call renomeiaEstabelecimento(55, 'Loja105'); 
call renomeiaEstabelecimento(48, 'Loja106'); 
call renomeiaEstabelecimento(99, 'Loja107'); 
call renomeiaEstabelecimento(102, 'Loja108'); 
call renomeiaEstabelecimento(17, 'Loja109'); 
call renomeiaEstabelecimento(112, 'Loja110'); 
call renomeiaEstabelecimento(91, 'Loja111'); 
call renomeiaEstabelecimento(35, 'Loja112'); 
call renomeiaEstabelecimento(89, 'Loja113'); 
call renomeiaEstabelecimento(54, 'Loja114'); 
call renomeiaEstabelecimento(35, 'Loja115'); 
call renomeiaEstabelecimento(65, 'Loja116'); 
call renomeiaEstabelecimento(77, 'Loja117'); 
call renomeiaEstabelecimento(110, 'Loja118'); 
call renomeiaEstabelecimento(105, 'Loja119'); 
call renomeiaEstabelecimento(119, 'Loja120'); 
call renomeiaEstabelecimento(5, 'Loja121'); 
call renomeiaEstabelecimento(8, 'Loja122'); 
call renomeiaEstabelecimento(67, 'Loja123'); 
call renomeiaEstabelecimento(137, 'Loja124'); 
call renomeiaEstabelecimento(128, 'Loja125'); 
call renomeiaEstabelecimento(19, 'Loja126'); 
call renomeiaEstabelecimento(5, 'Loja127'); 
call renomeiaEstabelecimento(89, 'Loja128'); 
call renomeiaEstabelecimento(169, 'Loja129'); 
call renomeiaEstabelecimento(127, 'Loja130'); 
call renomeiaEstabelecimento(173, 'Loja131'); 
call renomeiaEstabelecimento(52, 'Loja132'); 
call renomeiaEstabelecimento(116, 'Loja133'); 
call renomeiaEstabelecimento(119, 'Loja134'); 
call renomeiaEstabelecimento(145, 'Loja135'); 
call renomeiaEstabelecimento(173, 'Loja136'); 
call renomeiaEstabelecimento(67, 'Loja137'); 
call renomeiaEstabelecimento(114, 'Loja138'); 
call renomeiaEstabelecimento(169, 'Loja139'); 
call renomeiaEstabelecimento(163, 'Loja140'); 
call renomeiaEstabelecimento(67, 'Loja141'); 
call renomeiaEstabelecimento(161, 'Loja142'); 
call renomeiaEstabelecimento(51, 'Loja143'); 
call renomeiaEstabelecimento(144, 'Loja144'); 
call renomeiaEstabelecimento(22, 'Loja145'); 
call renomeiaEstabelecimento(19, 'Loja146'); 
call renomeiaEstabelecimento(121, 'Loja147'); 
call renomeiaEstabelecimento(137, 'Loja148'); 
call renomeiaEstabelecimento(150, 'Loja149'); 
call renomeiaEstabelecimento(31, 'Loja150'); 
call renomeiaEstabelecimento(173, 'Loja151'); 
call renomeiaEstabelecimento(143, 'Loja152'); 
call renomeiaEstabelecimento(99, 'Loja153'); 
call renomeiaEstabelecimento(51, 'Loja154'); 
call renomeiaEstabelecimento(70, 'Loja155'); 
call renomeiaEstabelecimento(161, 'Loja156'); 
call renomeiaEstabelecimento(143, 'Loja157'); 
call renomeiaEstabelecimento(27, 'Loja158'); 
call renomeiaEstabelecimento(152, 'Loja159'); 
call renomeiaEstabelecimento(22, 'Loja160'); 
call renomeiaEstabelecimento(12, 'Loja161'); 
call renomeiaEstabelecimento(14, 'Loja162'); 
call renomeiaEstabelecimento(67, 'Loja163'); 
call renomeiaEstabelecimento(31, 'Loja164'); 
call renomeiaEstabelecimento(41, 'Loja165'); 
call renomeiaEstabelecimento(38, 'Loja166'); 
call renomeiaEstabelecimento(13, 'Loja167'); 
call renomeiaEstabelecimento(115, 'Loja168'); 
call renomeiaEstabelecimento(175, 'Loja169'); 
call renomeiaEstabelecimento(95, 'Loja170'); 
call renomeiaEstabelecimento(34, 'Loja171'); 
call renomeiaEstabelecimento(77, 'Loja172'); 
call renomeiaEstabelecimento(54, 'Loja173'); 
call renomeiaEstabelecimento(36, 'Loja174'); 
call renomeiaEstabelecimento(20, 'Loja175'); 

 
call update_preco(96, 262.79);
call update_preco(83, 4023.21);
call update_preco(71, 261.56);
call update_preco(210, 4584.38);
call update_preco(45, 3651.8);
call update_preco(64, 5385.62);
call update_preco(39, 410.54);
call update_preco(110, 2977.09);
call update_preco(85, 6886.71);
call update_preco(73, 6571.2);
call update_preco(188, 3829.16);
call update_preco(86, 1222.95);
call update_preco(82, 4270.17);
call update_preco(22, 6197.43);
call update_preco(91, 7948.97);
call update_preco(105, 2913.26);
call update_preco(115, 2450.43);
call update_preco(169, 2416.12);
call update_preco(90, 3457.74);
call update_preco(201, 3593.37);
call update_preco(205, 3810.84);
call update_preco(191, 6610.37);
call update_preco(196, 4202.81);
call update_preco(181, 413.65);
call update_preco(51, 4833.02);
call update_preco(19, 3691.4);
call update_preco(171, 1987.68);
call update_preco(204, 890.87);
call update_preco(79, 6589.81);
call update_preco(173, 4685.72);
call update_preco(11, 6546.69);
call update_preco(50, 4928.67);
call update_preco(103, 2552.07);
call update_preco(196, 3914.8);
call update_preco(155, 1385.44);
call update_preco(48, 1553.23);
call update_preco(113, 2030.9);
call update_preco(210, 3907.65);
call update_preco(124, 5500.36);
call update_preco(175, 1473.83);
call update_preco(7, 2917.97);
call update_preco(191, 4900.6);
call update_preco(82, 3066.88);
call update_preco(197, 3538.89);
call update_preco(21, 5323.87);
call update_preco(216, 4453.1);
call update_preco(183, 4807.04);
call update_preco(32, 5261.29);
call update_preco(75, 719.41);
call update_preco(23, 5698.12);
call update_preco(85, 2389.59);
call update_preco(209, 4389.66);
call update_preco(95, 4763.2);
call update_preco(61, 6159.76);
call update_preco(186, 2957.14);
call update_preco(200, 5995.13);
call update_preco(128, 1417.79);
call update_preco(112, 7283.88);
call update_preco(9, 6802.92);
call update_preco(148, 3816.52);
call update_preco(172, 3091.43);
call update_preco(198, 5424.06);
call update_preco(207, 2940.07);
call update_preco(14, 6495.54);
call update_preco(76, 5580.67);
call update_preco(46, 5555.19);
call update_preco(174, 7053.23);
call update_preco(128, 469.05);
call update_preco(35, 7323.03);
call update_preco(120, 1865.22);
call update_preco(36, 5232.91);
call update_preco(116, 1098.98);
call update_preco(123, 6494.28);
call update_preco(166, 6767.95);
call update_preco(56, 6614.85);
call update_preco(106, 7972.43);
call update_preco(56, 877.68);
call update_preco(207, 6974.06);
call update_preco(85, 6249.85);
call update_preco(142, 7057.23);
call update_preco(24, 3707.36);
call update_preco(75, 1398.3);
call update_preco(209, 2979.19);
call update_preco(193, 1549.13);
call update_preco(33, 5020.16);
call update_preco(160, 5456.24);
call update_preco(64, 2070.78);
call update_preco(164, 1880.61);
call update_preco(62, 6390.54);
call update_preco(38, 5574.42);
call update_preco(62, 311.85);
call update_preco(114, 4134.78);
call update_preco(80, 4098.21);
call update_preco(126, 1389.31);
call update_preco(43, 1227.7);
call update_preco(215, 6366.23);
call update_preco(180, 1478.18);
call update_preco(100, 5212.33);
call update_preco(70, 7025.43);
call update_preco(85, 3579.15);
call update_preco(15, 3953.82);
call update_preco(124, 240.99);
call update_preco(43, 106.87);
call update_preco(146, 2005.97);
call update_preco(18, 3947.32);
call update_preco(130, 6230.39);
call update_preco(208, 5386.48);
call update_preco(169, 3810.88);
call update_preco(75, 3727.29);
call update_preco(9, 6470.44);
call update_preco(146, 4955.34);
call update_preco(145, 7307.6);
call update_preco(168, 6185.76);
call update_preco(27, 3343.03);
call update_preco(109, 7526.66);
call update_preco(97, 5246.31);
call update_preco(83, 4954.99);
call update_preco(15, 4351.76);
call update_preco(132, 6004.31);
call update_preco(194, 7819.94);
call update_preco(5, 1811.55);
call update_preco(168, 3816.02);
call update_preco(116, 6790.15);
call update_preco(106, 6592.32);
call update_preco(99, 3041.74);
call update_preco(62, 2985.96);
call update_preco(182, 1018.98);
call update_preco(203, 2814.17);
call update_preco(10, 7916.69);
call update_preco(27, 5520.29);
call update_preco(186, 7096.48);
call update_preco(134, 1171.57);
call update_preco(214, 4034.03);
call update_preco(186, 2716.07);
call update_preco(35, 7269.56);
call update_preco(10, 4437.56);
call update_preco(78, 2773.2);
call update_preco(35, 3201.64);
call update_preco(89, 7804.66);
call update_preco(126, 1884.97);
call update_preco(69, 7328.96);
call update_preco(117, 4751.67);
call update_preco(83, 5354.43);
call update_preco(189, 6140.67);
call update_preco(131, 668.83);
call update_preco(13, 898.01);
call update_preco(180, 6428.13);
call update_preco(171, 3351.43);
call update_preco(146, 2871.62);
call update_preco(155, 4562.04);
call update_preco(47, 1057.24);
call update_preco(124, 695.13);
call update_preco(117, 7888.92);
call update_preco(77, 3497.97);
call update_preco(158, 3317.5);
call update_preco(41, 7190.73);
call update_preco(162, 305.94);
call update_preco(137, 6389.51);
call update_preco(162, 6697.58);
call update_preco(130, 4764.81);
call update_preco(147, 1551.45);
call update_preco(127, 3454.2);
call update_preco(68, 2782.34);
call update_preco(100, 6878.7);
call update_preco(41, 6095.12);
call update_preco(16, 2237.16);
call update_preco(70, 4900.32);
call update_preco(26, 1682.36);
call update_preco(201, 6192.95);
call update_preco(145, 958.39);
call update_preco(172, 2617.4);
call update_preco(190, 7915.33);
call update_preco(164, 2851.16);
call update_preco(24, 3946.3);
call update_preco(196, 3722.08);
call update_preco(59, 3189.53);
call update_preco(165, 3940.02);
call update_preco(42, 5472.14);
call update_preco(58, 2377.0);
call update_preco(213, 5873.54);
call update_preco(72, 4661.31);
call update_preco(88, 3635.52);
call update_preco(87, 4285.64);
call update_preco(89, 441.41);
call update_preco(207, 2966.26);
call update_preco(132, 750.3);
call update_preco(135, 2965.87);
call update_preco(203, 3370.9);
call update_preco(94, 2156.99);
call update_preco(44, 503.47);
call update_preco(169, 1662.79);
call update_preco(42, 3524.25);
call update_preco(168, 3207.22);
call update_preco(151, 4098.1);
call update_preco(95, 7738.6);
call update_preco(125, 1685.43);
call update_preco(34, 5793.53);
call update_preco(96, 6403.96);
call update_preco(129, 7951.23);
call update_preco(47, 758.19);
call update_preco(20, 3253.2);
call update_preco(42, 4432.88);
call update_preco(144, 4289.29);
call update_preco(19, 7447.65);
call update_preco(205, 4014.67);
call update_preco(96, 3561.0);
call update_preco(74, 2137.47);
call update_preco(77, 6700.9);
call update_preco(80, 2763.24);
call update_preco(34, 7818.43);
call update_preco(105, 7303.24);
call update_preco(95, 5951.7);
call update_preco(181, 1284.08);
call update_preco(179, 7714.26);
call update_preco(115, 511.0);
call update_preco(59, 6066.16);

 
call update_pref(10, 8);
call update_pref(159, 13);
call update_pref(111, 2);
call update_pref(101, 9);
call update_pref(178, 6);
call update_pref(171, 9);
call update_pref(131, 13);
call update_pref(163, 9);
call update_pref(203, 8);
call update_pref(26, 2);
call update_pref(159, 2);
call update_pref(184, 15);
call update_pref(151, 3);
call update_pref(120, 14);
call update_pref(199, 15);
call update_pref(128, 3);
call update_pref(37, 9);
call update_pref(149, 2);
call update_pref(164, 3);
call update_pref(143, 10);
call update_pref(116, 13);
call update_pref(181, 12);
call update_pref(60, 11);
call update_pref(70, 4);
call update_pref(19, 9);
call update_pref(76, 5);
call update_pref(61, 2);
call update_pref(30, 6);
call update_pref(14, 6);
call update_pref(20, 7);
call update_pref(27, 3);
call update_pref(129, 8);
call update_pref(83, 14);
call update_pref(187, 1);
call update_pref(200, 4);
call update_pref(211, 9);
call update_pref(23, 14);
call update_pref(7, 2);
call update_pref(92, 13);
call update_pref(112, 13);
call update_pref(32, 7);
call update_pref(28, 7);
call update_pref(52, 15);
call update_pref(127, 7);
call update_pref(22, 1);
call update_pref(71, 3);
call update_pref(190, 3);
call update_pref(185, 9);
call update_pref(1, 1);
call update_pref(122, 1);
call update_pref(35, 12);
call update_pref(57, 6);
call update_pref(15, 15);
call update_pref(83, 2);
call update_pref(51, 10);
call update_pref(39, 10);
call update_pref(195, 7);
call update_pref(30, 15);
call update_pref(12, 10);
call update_pref(52, 3);
call update_pref(110, 14);
call update_pref(94, 7);
call update_pref(103, 11);
call update_pref(149, 10);
call update_pref(83, 14);
call update_pref(21, 6);
call update_pref(182, 7);
call update_pref(28, 2);
call update_pref(70, 6);
call update_pref(154, 14);
call update_pref(5, 8);
call update_pref(150, 14);
call update_pref(63, 5);
call update_pref(61, 2);
call update_pref(69, 2);
call update_pref(209, 9);
call update_pref(97, 12);
call update_pref(166, 4);
call update_pref(44, 2);
call update_pref(2, 4);
call update_pref(66, 15);
call update_pref(190, 4);
call update_pref(141, 3);
call update_pref(7, 5);
call update_pref(105, 6);
call update_pref(130, 3);
call update_pref(210, 7);
call update_pref(35, 6);
call update_pref(77, 9);
call update_pref(205, 9);
call update_pref(151, 5);
call update_pref(114, 9);
call update_pref(107, 4);
call update_pref(151, 6);
call update_pref(52, 3);
call update_pref(124, 15);
call update_pref(17, 2);
call update_pref(120, 7);
call update_pref(206, 10);
call update_pref(193, 8);
call update_pref(97, 2);
call update_pref(43, 3);
call update_pref(94, 7);
call update_pref(4, 4);
call update_pref(21, 11);
call update_pref(103, 4);
call update_pref(208, 4);
call update_pref(191, 15);
call update_pref(203, 2);
call update_pref(211, 2);
call update_pref(51, 10);
call update_pref(93, 15);
call update_pref(72, 12);
call update_pref(155, 4);
call update_pref(111, 3);
call update_pref(71, 4);
call update_pref(154, 10);
call update_pref(96, 9);
call update_pref(185, 14);
call update_pref(41, 13);
call update_pref(185, 14);
call update_pref(109, 4);
call update_pref(115, 8);
call update_pref(169, 1);
call update_pref(130, 3);
call update_pref(209, 5);
call update_pref(16, 15);
call update_pref(56, 11);
call update_pref(11, 6);
call update_pref(140, 6);
call update_pref(45, 15);
call update_pref(204, 12);
call update_pref(33, 4);
call update_pref(24, 2);
call update_pref(34, 1);
call update_pref(50, 13);
call update_pref(13, 14);
call update_pref(141, 3);
call update_pref(48, 13);
call update_pref(158, 14);
call update_pref(120, 11);
call update_pref(84, 8);
call update_pref(66, 7);
call update_pref(80, 8);
call update_pref(105, 15);
call update_pref(48, 3);
call update_pref(131, 14);
call update_pref(125, 5);
call update_pref(43, 4);
call update_pref(88, 2);
call update_pref(143, 6);
call update_pref(24, 6);
call update_pref(116, 10);
call update_pref(44, 8);
call update_pref(58, 3);
call update_pref(15, 9);
call update_pref(11, 14);
call update_pref(122, 15);
call update_pref(159, 3);
call update_pref(53, 8);
call update_pref(110, 4);
call update_pref(69, 1);
call update_pref(121, 15);
call update_pref(40, 4);
call update_pref(9, 15);
call update_pref(199, 15);
call update_pref(141, 9);
call update_pref(78, 7);
call update_pref(211, 9);
call update_pref(80, 15);
call update_pref(21, 14);
call update_pref(66, 10);
call update_pref(209, 11);
call update_pref(125, 2);
call update_pref(112, 8);
call update_pref(31, 8);
call update_pref(145, 7);
call update_pref(138, 3);
call update_pref(125, 13);
call update_pref(11, 9);
call update_pref(112, 2);
call update_pref(117, 15);
call update_pref(149, 10);
call update_pref(156, 12);
call update_pref(23, 7);
call update_pref(105, 13);
call update_pref(12, 9);
call update_pref(203, 2);
call update_pref(205, 11);
call update_pref(158, 1);
call update_pref(89, 8);
call update_pref(152, 4);
call update_pref(69, 14);
call update_pref(195, 15);
call update_pref(165, 12);
call update_pref(195, 11);
call update_pref(96, 5);
call update_pref(209, 14);
call update_pref(182, 3);
call update_pref(193, 5);
call update_pref(96, 2);
call update_pref(50, 6);
call update_pref(189, 12);
call update_pref(75, 8);
call update_pref(58, 8);
call update_pref(64, 5);
call update_pref(186, 15);
call update_pref(57, 13);
call update_pref(178, 13);
call update_pref(187, 13);
call update_pref(176, 2);
call update_pref(43, 6);
call update_pref(139, 14);
call update_pref(180, 9);
call update_pref(40, 3);
call update_pref(90, 15);


select cat.nome, count(ID_J) from (Compra com join Jogo j on (j.ID_J = com.ID_JT)) join Categoria cat on(cat.ID_Cat = j.categoria) group by cat.ID_Cat order by count(ID_J);
/*Lista a quantidade de jogos comprados de cada categoria

"Sort  (cost=89.25..90.60 rows=540 width=130) (actual time=0.647..0.648 rows=15 loops=1)"
"  Sort Key: (count(j.id_j))"
"  Sort Method: quicksort  Memory: 26kB"
"  ->  HashAggregate  (cost=59.34..64.74 rows=540 width=130) (actual time=0.626..0.630 rows=15 loops=1)"
"        Group Key: cat.id_cat"
"        ->  Hash Join  (cost=32.01..54.34 rows=1000 width=126) (actual time=0.093..0.496 rows=1000 loops=1)"
"              Hash Cond: (j.categoria = cat.id_cat)"
"              ->  Hash Join  (cost=9.86..29.54 rows=1000 width=8) (actual time=0.078..0.312 rows=1000 loops=1)"
"                    Hash Cond: (com.id_jt = j.id_j)"
"                    ->  Seq Scan on compra com  (cost=0.00..17.00 rows=1000 width=4) (actual time=0.012..0.070 rows=1000 loops=1)"
"                    ->  Hash  (cost=7.16..7.16 rows=216 width=8) (actual time=0.062..0.062 rows=216 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 17kB"
"                          ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=8) (actual time=0.008..0.039 rows=216 loops=1)"
"              ->  Hash  (cost=15.40..15.40 rows=540 width=122) (actual time=0.012..0.012 rows=15 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                    ->  Seq Scan on categoria cat  (cost=0.00..15.40 rows=540 width=122) (actual time=0.008..0.009 rows=15 loops=1)"
"Planning Time: 0.225 ms"
"Execution Time: 0.686 ms"
*/
select cat.nome, count(cat.*) as numerodejogos from jogo j join categoria cat on cat.ID_Cat = j.categoria group by cat.nome having count(cat.*) > 5 order by count(cat.*);
/* Lista numero de jogos em cada categoria que tenha mais de 5 jogos

"Sort  (cost=36.03..36.20 rows=67 width=126) (actual time=0.178..0.179 rows=15 loops=1)"
"  Sort Key: (count(cat.*))"
"  Sort Method: quicksort  Memory: 25kB"
"  ->  HashAggregate  (cost=31.50..34.00 rows=67 width=126) (actual time=0.161..0.168 rows=15 loops=1)"
"        Group Key: cat.nome"
"        Filter: (count(cat.*) > 5)"
"        ->  Hash Join  (cost=22.15..29.88 rows=216 width=264) (actual time=0.035..0.108 rows=216 loops=1)"
"              Hash Cond: (j.categoria = cat.id_cat)"
"              ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=4) (actual time=0.012..0.029 rows=216 loops=1)"
"              ->  Hash  (cost=15.40..15.40 rows=540 width=268) (actual time=0.018..0.018 rows=15 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 10kB"
"                    ->  Seq Scan on categoria cat  (cost=0.00..15.40 rows=540 width=268) (actual time=0.010..0.014 rows=15 loops=1)"
"Planning Time: 0.123 ms"
"Execution Time: 0.211 ms"
*/
select j.nome, c.valor, t.velho, t.novo from (trocaPreco t join compra c on(t.ID_J = c.ID_JT)) join Jogo j on(j.ID_J = c.ID_JT) order by t.datat;
/* Lista todas as mudancas de precos dos jogos

"Sort  (cost=101.02..103.50 rows=991 width=51) (actual time=0.903..0.931 rows=1013 loops=1)"
"  Sort Key: t.datat"
"  Sort Method: quicksort  Memory: 156kB"
"  ->  Hash Join  (cost=17.30..51.71 rows=991 width=51) (actual time=0.273..0.590 rows=1013 loops=1)"
"        Hash Cond: (c.id_jt = t.id_j)"
"        ->  Seq Scan on compra c  (cost=0.00..17.00 rows=1000 width=12) (actual time=0.022..0.101 rows=1000 loops=1)"
"        ->  Hash  (cost=14.60..14.60 rows=216 width=51) (actual time=0.243..0.243 rows=216 loops=1)"
"              Buckets: 1024  Batches: 1  Memory Usage: 26kB"
"              ->  Hash Join  (cost=9.86..14.60 rows=216 width=51) (actual time=0.116..0.182 rows=216 loops=1)"
"                    Hash Cond: (t.id_j = j.id_j)"
"                    ->  Seq Scan on trocapreco t  (cost=0.00..4.16 rows=216 width=28) (actual time=0.013..0.022 rows=216 loops=1)"
"                    ->  Hash  (cost=7.16..7.16 rows=216 width=23) (actual time=0.097..0.097 rows=216 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 21kB"
"                          ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=23) (actual time=0.010..0.046 rows=216 loops=1)"
"Planning Time: 0.354 ms"
"Execution Time: 1.112 ms"
*/
select cli.nome, j.nome, cat.nome, e.nome, com.valor from (((cliente cli join compra com on cli.ID_C = com.ID_CT) join estabelecimento e on com.ID_ET = e.CNPJ) join jogo j on ID_J = ID_JT) join categoria cat on ID_Cat = categoria order by cli.nome;
/* Lista o nomes dos clientes, jogos comprados por eles, sua categoria, onde foram comprados e seu valor

"Sort  (cost=126.34..128.84 rows=1000 width=177) (actual time=3.065..3.092 rows=1000 loops=1)"
"  Sort Key: cli.nome"
"  Sort Method: quicksort  Memory: 165kB"
"  ->  Hash Join  (cost=48.81..76.51 rows=1000 width=177) (actual time=0.254..1.061 rows=1000 loops=1)"
"        Hash Cond: (j.categoria = cat.id_cat)"
"        ->  Hash Join  (cost=26.66..51.71 rows=1000 width=63) (actual time=0.222..0.861 rows=1000 loops=1)"
"              Hash Cond: (com.id_jt = j.id_j)"
"              ->  Hash Join  (cost=16.80..39.17 rows=1000 width=44) (actual time=0.145..0.602 rows=1000 loops=1)"
"                    Hash Cond: (com.id_et = e.cnpj)"
"                    ->  Hash Join  (cost=9.86..29.54 rows=1000 width=37) (actual time=0.083..0.382 rows=1000 loops=1)"
"                          Hash Cond: (com.id_ct = cli.id_c)"
"                          ->  Seq Scan on compra com  (cost=0.00..17.00 rows=1000 width=20) (actual time=0.010..0.093 rows=1000 loops=1)"
"                          ->  Hash  (cost=7.16..7.16 rows=216 width=25) (actual time=0.065..0.065 rows=216 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 21kB"
"                                ->  Seq Scan on cliente cli  (cost=0.00..7.16 rows=216 width=25) (actual time=0.007..0.036 rows=216 loops=1)"
"                    ->  Hash  (cost=4.75..4.75 rows=175 width=15) (actual time=0.057..0.057 rows=175 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 17kB"
"                          ->  Seq Scan on estabelecimento e  (cost=0.00..4.75 rows=175 width=15) (actual time=0.008..0.028 rows=175 loops=1)"
"              ->  Hash  (cost=7.16..7.16 rows=216 width=27) (actual time=0.075..0.075 rows=216 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 21kB"
"                    ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=27) (actual time=0.007..0.039 rows=216 loops=1)"
"        ->  Hash  (cost=15.40..15.40 rows=540 width=122) (actual time=0.028..0.028 rows=15 loops=1)"
"              Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"              ->  Seq Scan on categoria cat  (cost=0.00..15.40 rows=540 width=122) (actual time=0.014..0.014 rows=15 loops=1)"
"Planning Time: 0.866 ms"
"Execution Time: 3.251 ms"
*/

/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/

/* Criando indices */


CREATE INDEX busca_categoria_nome ON categoria using hash(nome );
CREATE INDEX busca_cliente_email ON cliente using hash(email );
CREATE INDEX busca_estabelecimento_nome ON estabelecimento using hash(cidade );
CREATE INDEX busca_jogo_nome ON jogo using hash(nome );
CREATE INDEX busca_compra_valor ON compra using hash(valor );
CREATE INDEX busca_tpref_data ON trocaPref using hash(datat );
CREATE INDEX busca_tpreco_data ON trocaPreco using hash(datat );


select cat.nome, count(ID_J) from (Compra com join Jogo j on (j.ID_J = com.ID_JT)) join Categoria cat on(cat.ID_Cat = j.categoria) group by cat.ID_Cat order by count(ID_J);
/*Lista a quantidade de jogos comprados de cada categoria

"Sort  (cost=39.69..39.73 rows=15 width=130) (actual time=0.600..0.600 rows=15 loops=1)"
"  Sort Key: (count(j.id_j))"
"  Sort Method: quicksort  Memory: 26kB"
"  ->  HashAggregate  (cost=39.25..39.40 rows=15 width=130) (actual time=0.591..0.593 rows=15 loops=1)"
"        Group Key: cat.id_cat"
"        ->  Hash Join  (cost=11.20..34.25 rows=1000 width=126) (actual time=0.094..0.450 rows=1000 loops=1)"
"              Hash Cond: (j.categoria = cat.id_cat)"
"              ->  Hash Join  (cost=9.86..29.54 rows=1000 width=8) (actual time=0.073..0.286 rows=1000 loops=1)"
"                    Hash Cond: (com.id_jt = j.id_j)"
"                    ->  Seq Scan on compra com  (cost=0.00..17.00 rows=1000 width=4) (actual time=0.009..0.067 rows=1000 loops=1)"
"                    ->  Hash  (cost=7.16..7.16 rows=216 width=8) (actual time=0.057..0.057 rows=216 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 17kB"
"                          ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=8) (actual time=0.007..0.034 rows=216 loops=1)"
"              ->  Hash  (cost=1.15..1.15 rows=15 width=122) (actual time=0.018..0.018 rows=15 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"                    ->  Seq Scan on categoria cat  (cost=0.00..1.15 rows=15 width=122) (actual time=0.011..0.013 rows=15 loops=1)"
"Planning Time: 0.264 ms"
"Execution Time: 0.636 ms"
*/
select cat.nome, count(cat.*) as numerodejogos from jogo j join categoria cat on cat.ID_Cat = j.categoria group by cat.nome having count(cat.*) > 5 order by count(cat.*);
/* Lista numero de jogos em cada categoria que tenha mais de 5 jogos

"Sort  (cost=11.09..11.10 rows=5 width=126) (actual time=0.160..0.161 rows=15 loops=1)"
"  Sort Key: (count(cat.*))"
"  Sort Method: quicksort  Memory: 25kB"
"  ->  HashAggregate  (cost=10.84..11.03 rows=5 width=126) (actual time=0.151..0.153 rows=15 loops=1)"
"        Group Key: cat.nome"
"        Filter: (count(cat.*) > 5)"
"        ->  Hash Join  (cost=1.34..9.22 rows=216 width=264) (actual time=0.046..0.110 rows=216 loops=1)"
"              Hash Cond: (j.categoria = cat.id_cat)"
"              ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=4) (actual time=0.012..0.031 rows=216 loops=1)"
"              ->  Hash  (cost=1.15..1.15 rows=15 width=268) (actual time=0.030..0.030 rows=15 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 10kB"
"                    ->  Seq Scan on categoria cat  (cost=0.00..1.15 rows=15 width=268) (actual time=0.021..0.024 rows=15 loops=1)"
"Planning Time: 0.143 ms"
"Execution Time: 0.192 ms"
*/
select j.nome, c.valor, t.velho, t.novo from (trocaPreco t join compra c on(t.ID_J = c.ID_JT)) join Jogo j on(j.ID_J = c.ID_JT) order by t.datat;
/* Lista todas as mudancas de precos dos jogos

"Sort  (cost=101.02..103.50 rows=991 width=51) (actual time=0.852..0.880 rows=1013 loops=1)"
"  Sort Key: t.datat"
"  Sort Method: quicksort  Memory: 156kB"
"  ->  Hash Join  (cost=17.30..51.71 rows=991 width=51) (actual time=0.211..0.567 rows=1013 loops=1)"
"        Hash Cond: (c.id_jt = t.id_j)"
"        ->  Seq Scan on compra c  (cost=0.00..17.00 rows=1000 width=12) (actual time=0.014..0.086 rows=1000 loops=1)"
"        ->  Hash  (cost=14.60..14.60 rows=216 width=51) (actual time=0.192..0.192 rows=216 loops=1)"
"              Buckets: 1024  Batches: 1  Memory Usage: 26kB"
"              ->  Hash Join  (cost=9.86..14.60 rows=216 width=51) (actual time=0.090..0.147 rows=216 loops=1)"
"                    Hash Cond: (t.id_j = j.id_j)"
"                    ->  Seq Scan on trocapreco t  (cost=0.00..4.16 rows=216 width=28) (actual time=0.010..0.021 rows=216 loops=1)"
"                    ->  Hash  (cost=7.16..7.16 rows=216 width=23) (actual time=0.076..0.077 rows=216 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 21kB"
"                          ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=23) (actual time=0.007..0.039 rows=216 loops=1)"
"Planning Time: 0.321 ms"
"Execution Time: 1.025 ms"
*/
select cli.nome, j.nome, cat.nome, e.nome, com.valor from (((cliente cli join compra com on cli.ID_C = com.ID_CT) join estabelecimento e on com.ID_ET = e.CNPJ) join jogo j on ID_J = ID_JT) join categoria cat on ID_Cat = categoria order by cli.nome;
/* Lista o nomes dos clientes, jogos comprados por eles, sua categoria, onde foram comprados e seu valor

"Sort  (cost=106.25..108.75 rows=1000 width=177) (actual time=3.038..3.065 rows=1000 loops=1)"
"  Sort Key: cli.nome"
"  Sort Method: quicksort  Memory: 165kB"
"  ->  Hash Join  (cost=27.99..56.42 rows=1000 width=177) (actual time=0.222..1.046 rows=1000 loops=1)"
"        Hash Cond: (j.categoria = cat.id_cat)"
"        ->  Hash Join  (cost=26.66..51.71 rows=1000 width=63) (actual time=0.194..0.840 rows=1000 loops=1)"
"              Hash Cond: (com.id_jt = j.id_j)"
"              ->  Hash Join  (cost=16.80..39.17 rows=1000 width=44) (actual time=0.119..0.580 rows=1000 loops=1)"
"                    Hash Cond: (com.id_et = e.cnpj)"
"                    ->  Hash Join  (cost=9.86..29.54 rows=1000 width=37) (actual time=0.069..0.372 rows=1000 loops=1)"
"                          Hash Cond: (com.id_ct = cli.id_c)"
"                          ->  Seq Scan on compra com  (cost=0.00..17.00 rows=1000 width=20) (actual time=0.009..0.092 rows=1000 loops=1)"
"                          ->  Hash  (cost=7.16..7.16 rows=216 width=25) (actual time=0.057..0.058 rows=216 loops=1)"
"                                Buckets: 1024  Batches: 1  Memory Usage: 21kB"
"                                ->  Seq Scan on cliente cli  (cost=0.00..7.16 rows=216 width=25) (actual time=0.007..0.032 rows=216 loops=1)"
"                    ->  Hash  (cost=4.75..4.75 rows=175 width=15) (actual time=0.047..0.048 rows=175 loops=1)"
"                          Buckets: 1024  Batches: 1  Memory Usage: 17kB"
"                          ->  Seq Scan on estabelecimento e  (cost=0.00..4.75 rows=175 width=15) (actual time=0.008..0.028 rows=175 loops=1)"
"              ->  Hash  (cost=7.16..7.16 rows=216 width=27) (actual time=0.073..0.073 rows=216 loops=1)"
"                    Buckets: 1024  Batches: 1  Memory Usage: 21kB"
"                    ->  Seq Scan on jogo j  (cost=0.00..7.16 rows=216 width=27) (actual time=0.008..0.036 rows=216 loops=1)"
"        ->  Hash  (cost=1.15..1.15 rows=15 width=122) (actual time=0.025..0.025 rows=15 loops=1)"
"              Buckets: 1024  Batches: 1  Memory Usage: 9kB"
"              ->  Seq Scan on categoria cat  (cost=0.00..1.15 rows=15 width=122) (actual time=0.012..0.014 rows=15 loops=1)"
"Planning Time: 0.457 ms"
"Execution Time: 3.197 ms"
*/

drop INDEX busca_categoria_nome;
drop INDEX busca_cliente_email;
drop INDEX busca_estabelecimento_nome;
drop INDEX busca_jogo_nome;
drop INDEX busca_compra_valor;
drop INDEX busca_tpref_data;
drop INDEX busca_tpreco_data;


drop trigger if exists logpreftrigger on cliente;
drop trigger if exists logprecotrigger on jogo;
drop function if exists preflog;
drop function if exists precolog;
drop function if exists ncompras_categoria_cliente;
drop function if exists jogo_preco;
drop function if exists jogo_cat;
drop function if exists cliente_pref;

drop procedure if exists update_preco;
drop procedure if exists renomeiaEstabelecimento;

drop table if exists trocaPreco;
drop table if exists trocaPref;
drop table if exists Compra;
drop table if exists Jogo;
drop table if exists Estabelecimento;
drop table if exists Cliente;
drop table if exists Categoria;


 