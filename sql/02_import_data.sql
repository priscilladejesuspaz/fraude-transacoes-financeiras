USE fraude_cartao;
-- Importando DATASET, pois pelo Wizard deu erro, devido o tamanho do mesmo.
LOAD DATA LOCAL INFILE 'C:\Users\Book\Downloads\archive\test.csv'
INTO TABLE transacoes
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

