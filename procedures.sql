CREATE PROCEDURE insert_jogo(a integer, b float, c varchar, d varchar, e integer)
LANGUAGE SQL
AS $$
INSERT INTO Jogo VALUES (a,b,c,d,e);
$$;

CREATE PROCEDURE insert_estabelecimento(a integer, b varchar, c varchar)
LANGUAGE SQL
AS $$
INSERT INTO Estabelecimento VALUES (a,b,c);
$$;

CREATE PROCEDURE insert_categoria(a integer, b varchar)
LANGUAGE SQL
AS $$
INSERT INTO Categoria VALUES (a,b);
$$;

CREATE PROCEDURE insert_cliente(a integer, b varchar, c date, d varchar, e varchar, f integer)
LANGUAGE SQL
AS $$
INSERT INTO Cliente VALUES (a,b,c,d,e,f);
$$;



##########perguntar sapoha

cursor caralho


CREATE PROCEDURE insert_compra(a integer, c integer, d integer, e integer)
LANGUAGE SQL
AS $$
is
temporario integer;

temporario =select count(categoria) in (Cliente join Compra on(id_cliente = id_idcompra_cliente)
 join Jogo on(id_jogo = id_idcomprajogo)) join Categoria on(id_categoria = id_jogocategoria)
 where categoria=preferencia and id_cliente id_idcompra_cliente;

 if temporario < 20 then
 total = preco * ((60 - (20 - temporario)*3)/100);
 else
 total = preco * 0.6;

INSERT INTO Compra VALUES (a,total,c,d,e);
$$;



call insert_categoria(221, 'Estrategia');
call insert_categoria(222, 'Corrida');
call insert_categoria(223, 'RPG');
call insert_categoria(224, 'Aventura');
call insert_categoria(225, 'Luta');


call insert_cliente(111111, 'Guilherme', TO_DATE('02/09/98', 'dd/mm/yy'),'123456789','guilhermeb@ufscar.com',221);
call insert_cliente(111112, 'Arnaldo', TO_DATE('17/07/98', 'dd/mm/yy'),'234567891','arnaldob@ufscar.com', 221);
call insert_cliente(111113, 'Lineu', TO_DATE('13/04/99', 'dd/mm/yy'),'345678912','lineub@ufscar.com', 221);
call insert_cliente(111114, 'Pedro', TO_DATE('08/12/98', 'dd/mm/yy'),'456789123','pedrob@ufscar.com', 221);
call insert_cliente(111115, 'Roberto', TO_DATE('11/11/97', 'dd/mm/yy'),'567891234','robertob@ufscar.com',221);

call insert_estabelecimento(331, 'Rio Preto', 'Vilars Juegos');
call insert_estabelecimento(332, 'Rio de Janeiro', 'Rogerinho Eletricos');
call insert_estabelecimento(333, 'Rio Branco', 'Joao e Jao Joojinhos');
call insert_estabelecimento(334, 'Rio Pardo', 'Marcela Gamers');
call insert_estabelecimento(335, 'Rio das Antas', 'Dr Jogos');

call insert_jogo(441, 8000.99, 'Digital', 'As aventuras de Balduino The Gamer',224);
call insert_jogo(442, 20.55, 'Fisico', 'Damas',221);
call insert_jogo(443, 30.01, 'Fisico', 'Xadrez',221);
call insert_jogo(444, 212.23, 'Digital', 'The Crew',222);
call insert_jogo(445, 99.98, 'Digital', 'Mortal Kombat 12',225);

call insert_compra(551, 0, 441, 111111,331);
call insert_compra(552, 0, 445, 111112,335);
call insert_compra(553, 0, 445, 111115,333);
call insert_compra(554, 0, 442, 111115,332);
call insert_compra(555, 0, 444, 111111,334);

drop procedure insert_compra;
drop procedure insert_jogo;
drop procedure insert_categoria;
drop procedure insert_estabelecimento;
drop procedure insert_cliente;
