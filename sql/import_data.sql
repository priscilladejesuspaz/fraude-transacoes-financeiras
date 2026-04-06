USE fraude_cartao;

-- Habilitar importação de arquivos locais
SET GLOBAL local_infile = 1;

-- Importação dos dados
-- OBS: ajustar o caminho conforme o ambiente local
LOAD DATA LOCAL INFILE 'caminho/do/arquivo/transacoes.csv'
INTO TABLE transacoes
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Verificação básica
SELECT COUNT(*) AS total_registros FROM transacoes;
SELECT * FROM transacoes LIMIT 5;

