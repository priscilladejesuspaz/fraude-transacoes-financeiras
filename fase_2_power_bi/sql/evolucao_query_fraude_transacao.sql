/*
==========================================================================
PROJETO: Análise de Fraudes em Transações Financeiras
BANCO: fraude_cartao
TABELA PRINCIPAL: transacoes_completas

STATUS (28/08/2026):
✅ Dataset completo: 1.852.394 transações (jan/2019 a dez/2020)
   - train.csv: 1.296.675 linhas (jan/2019 - jun/2020)
   - test.csv: 555.719 linhas (jun/2020 - dez/2020)
✅ Coluna trans_date_trans_time convertida de TEXT para DATETIME
✅ Views criadas: vw_analise_temporal, t_altovalor_baixovalor,
   taxa_media_fraude, horarios_fraudes, transacoes_fraudes_normais

PENDENTE:
⏳ Análise por dia da semana
⏳ Conectar views no Looker Studio / Power BI
==========================================================================
*/

USE fraude_cartao;

-- --------------------------------------------------------------------
-- ETAPA 1: CRIAÇÃO DA TABELA UNIFICADA
-- --------------------------------------------------------------------
-- O dataset original vem dividido em dois arquivos (train.csv e test.csv).
-- Aqui os dois são importados na mesma tabela, evitando precisar
-- fazer UNION depois.

CREATE TABLE transacoes_completas (
    trans_date_trans_time TEXT,
    cc_num BIGINT,
    merchant TEXT,
    category TEXT,
    amt DOUBLE,
    first TEXT,
    last TEXT,
    gender TEXT,
    street TEXT,
    city TEXT,
    state TEXT,
    zip INT,
    lat DOUBLE,
    lng DOUBLE,
    city_pop INT,
    job TEXT,
    dob TEXT,
    trans_num TEXT,
    unix_time INT,
    merch_lat DOUBLE,
    merch_long DOUBLE,
    is_fraud INT
);

-- Antes de importar arquivo grande, aumentar timeout em:
-- Edit > Preferences > SQL Editor > DBMS connection read timeout > 600

-- Habilitar import local (precisa nas duas pontas: servidor e cliente)
SET GLOBAL local_infile = 1;

-- Importando train.csv (o CSV tem uma coluna de índice sem nome — @indice descarta ela)
LOAD DATA LOCAL INFILE 'C:/Users/Book/Documents/train.csv'
INTO TABLE transacoes_completas
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@indice, trans_date_trans_time, cc_num, merchant, category, amt, first, last,
 gender, street, city, state, zip, lat, lng, city_pop, job, dob, trans_num,
 unix_time, merch_lat, merch_long, is_fraud);

-- Importando test.csv na mesma tabela
LOAD DATA LOCAL INFILE 'C:/Users/Book/Documents/test.csv'
INTO TABLE transacoes_completas
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(@indice, trans_date_trans_time, cc_num, merchant, category, amt, first, last,
 gender, street, city, state, zip, lat, lng, city_pop, job, dob, trans_num,
 unix_time, merch_lat, merch_long, is_fraud);

-- Confirmação: deve retornar 1.852.394
SELECT COUNT(*) FROM transacoes_completas;

-- --------------------------------------------------------------------
-- ETAPA 2: CORREÇÃO DO TIPO DE DADO DA COLUNA DE DATA
-- --------------------------------------------------------------------
-- A coluna veio como TEXT no formato 'YYYY-MM-DD HH:MM:SS'.
-- MODIFY COLUMN converte a coluna existente sem precisar criar uma nova.

ALTER TABLE transacoes_completas
MODIFY COLUMN trans_date_trans_time DATETIME;

-- --------------------------------------------------------------------
-- ETAPA 3: VERIFICAÇÃO DE DADOS NULOS
-- --------------------------------------------------------------------
-- SUM(coluna IS NULL) é a forma mais direta de contar nulos —
-- o MySQL trata TRUE como 1 e FALSE como 0 automaticamente.

SELECT
    SUM(trans_date_trans_time IS NULL) AS nulos_data,
    SUM(amt IS NULL)                   AS nulos_valor,
    SUM(category IS NULL)              AS nulos_categoria,
    SUM(is_fraud IS NULL)              AS nulos_fraude,
    SUM(merchant IS NULL)              AS nulos_merchant
FROM transacoes_completas;

-- --------------------------------------------------------------------
-- ETAPA 4: VIEWS DE ANÁLISE
-- --------------------------------------------------------------------
-- 4. 1 — Análise temporal: volume e taxa de fraude por mês
SELECT
    COUNT(*)                                          AS quantidade_transacao,
    SUM(is_fraud)                                     AS total_transacao,
    ROUND((SUM(is_fraud) / COUNT(*)) * 100, 2)        AS taxa_fraude,
    DATE_FORMAT(trans_date_trans_time, '%Y-%m')       AS mes_ano
FROM transacoes_completas
GROUP BY DATE_FORMAT(trans_date_trans_time, '%Y-%m');

-- 4.1 — Análise temporal: volume e taxa de fraude por mês
CREATE VIEW vw_analise_temporal AS
SELECT
    COUNT(*)                                          AS quantidade_transacao,
    SUM(is_fraud)                                     AS total_transacao,
    ROUND((SUM(is_fraud) / COUNT(*)) * 100, 2)        AS taxa_fraude,
    DATE_FORMAT(trans_date_trans_time, '%Y-%m')       AS mes_ano
FROM transacoes_completas
GROUP BY DATE_FORMAT(trans_date_trans_time, '%Y-%m');

-- 4.2 — Transações por faixa de valor (alto vs baixo)
SELECT
    CASE
        WHEN amt >= 1000 THEN 'Alto Valor'
        ELSE 'Baixo Valor'
    END AS valores_transacoes,
    COUNT(*) AS valor_total
FROM transacoes_completas
GROUP BY valores_transacoes
ORDER BY valor_total ASC;

-- 4.2 — View da Transações por faixa de valor (alto vs baixo)
-- Critério: alto valor = amt >= 1000
CREATE VIEW t_altovalor_baixovalor AS
SELECT
    CASE
        WHEN amt >= 1000 THEN 'Alto Valor'
        ELSE 'Baixo Valor'
    END AS valores_transacoes,
    COUNT(*) AS valor_total
FROM transacoes_completas
GROUP BY valores_transacoes
ORDER BY valor_total ASC;

-- 4.3 — Categorias com taxa de fraude acima da média geral
WITH media_global AS (
    SELECT AVG(is_fraud) AS media
    FROM transacoes_completas
)
SELECT
    category,
    AVG(is_fraud) AS media_fraude
FROM transacoes_completas
GROUP BY category
HAVING AVG(is_fraud) > (SELECT media FROM media_global)
ORDER BY media_fraude DESC;

-- 4.3 — View da Categorias com taxa de fraude acima da média geral
CREATE VIEW taxa_media_fraude AS
WITH media_global AS (
    SELECT AVG(is_fraud) AS media
    FROM transacoes_completas
)
SELECT
    category,
    AVG(is_fraud) AS media_fraude
FROM transacoes_completas
GROUP BY category
HAVING AVG(is_fraud) > (SELECT media FROM media_global)
ORDER BY media_fraude DESC;

-- 4.4 — Taxa de fraude por período do dia
SELECT
    SUM(is_fraud) AS total_fraude,
    CASE
        WHEN HOUR(trans_date_trans_time) BETWEEN 0 AND 5  THEN 'madrugada'
        WHEN HOUR(trans_date_trans_time) BETWEEN 6 AND 11 THEN 'manha'
        WHEN HOUR(trans_date_trans_time) BETWEEN 12 AND 17 THEN 'tarde'
        ELSE 'noite'
    END AS periodo,
    AVG(is_fraud) AS taxa
FROM transacoes_completas
GROUP BY periodo
ORDER BY taxa DESC;

-- 4.4 — View da Taxa de fraude por período do dia
CREATE VIEW horarios_fraudes AS
SELECT
    SUM(is_fraud) AS total_fraude,
    CASE
        WHEN HOUR(trans_date_trans_time) BETWEEN 0 AND 5  THEN 'madrugada'
        WHEN HOUR(trans_date_trans_time) BETWEEN 6 AND 11 THEN 'manha'
        WHEN HOUR(trans_date_trans_time) BETWEEN 12 AND 17 THEN 'tarde'
        ELSE 'noite'
    END AS periodo,
    AVG(is_fraud) AS taxa
FROM transacoes_completas
GROUP BY periodo
ORDER BY taxa DESC;

-- 4.5 — Total de transações: fraude vs normal
SELECT
    CASE
        WHEN is_fraud = 1 THEN 'fraude'
        ELSE 'normal'
    END AS tipo,
    COUNT(*) AS total
FROM transacoes_completas
GROUP BY is_fraud
ORDER BY is_fraud ASC;

-- 4.5 — View Total de transações: fraude vs normal
CREATE VIEW transacoes_fraudes_normais AS
SELECT
    CASE
        WHEN is_fraud = 1 THEN 'fraude'
        ELSE 'normal'
    END AS tipo,
    COUNT(*) AS total
FROM transacoes_completas
GROUP BY is_fraud
ORDER BY is_fraud ASC;

-- --------------------------------------------------------------------
-- PRÓXIMA ETAPA (não iniciada): análise por dia da semana
-- Sugestão de estrutura, usando DAYNAME() ou DAYOFWEEK():
--
CREATE VIEW vw_analise_dia_semana AS
SELECT 
    DAYNAME(trans_date_trans_time) AS dia_semana,
    COUNT(*) AS quantidade_transacao,
    SUM(is_fraud) AS total_fraude,
    ROUND((SUM(is_fraud) / COUNT(*)) * 100, 2) AS taxa_fraude
FROM transacoes_completas
GROUP BY DAYNAME(trans_date_trans_time), DAYOFWEEK(trans_date_trans_time)
ORDER BY DAYOFWEEK(trans_date_trans_time);

-- CREATE VIEW vw_analise_dia_semana AS
SELECT 
    DAYNAME(trans_date_trans_time) AS dia_semana,
    COUNT(*) AS quantidade_transacao,
    SUM(is_fraud) AS total_fraude,
    ROUND((SUM(is_fraud) / COUNT(*)) * 100, 2) AS taxa_fraude
FROM transacoes_completas
GROUP BY DAYNAME(trans_date_trans_time), DAYOFWEEK(trans_date_trans_time)
ORDER BY DAYOFWEEK(trans_date_trans_time);

-- Traduzir os dias de semana para ptbr
SELECT 
    CASE DAYOFWEEK(trans_date_trans_time)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Segunda'
        WHEN 3 THEN 'Terça'
        WHEN 4 THEN 'Quarta'
        WHEN 5 THEN 'Quinta'
        WHEN 6 THEN 'Sexta'
        WHEN 7 THEN 'Sábado'
    END AS dia_semana,
    COUNT(*) AS quantidade_transacao,
    SUM(is_fraud) AS total_fraude,
    ROUND((SUM(is_fraud) / COUNT(*)) * 100, 2) AS taxa_fraude
FROM transacoes_completas
GROUP BY 
    CASE DAYOFWEEK(trans_date_trans_time)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Segunda'
        WHEN 3 THEN 'Terça'
        WHEN 4 THEN 'Quarta'
        WHEN 5 THEN 'Quinta'
        WHEN 6 THEN 'Sexta'
        WHEN 7 THEN 'Sábado'
    END,
    DAYOFWEEK(trans_date_trans_time)
ORDER BY DAYOFWEEK(trans_date_trans_time);

CREATE VIEW vw_analise_dia_semana AS
SELECT 
    CASE DAYOFWEEK(trans_date_trans_time)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Segunda'
        WHEN 3 THEN 'Terça'
        WHEN 4 THEN 'Quarta'
        WHEN 5 THEN 'Quinta'
        WHEN 6 THEN 'Sexta'
        WHEN 7 THEN 'Sábado'
    END AS dia_semana,
    COUNT(*) AS quantidade_transacao,
    SUM(is_fraud) AS total_fraude,
    ROUND((SUM(is_fraud) / COUNT(*)) * 100, 2) AS taxa_fraude
FROM transacoes_completas
GROUP BY 
    CASE DAYOFWEEK(trans_date_trans_time)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Segunda'
        WHEN 3 THEN 'Terça'
        WHEN 4 THEN 'Quarta'
        WHEN 5 THEN 'Quinta'
        WHEN 6 THEN 'Sexta'
        WHEN 7 THEN 'Sábado'
    END,
    DAYOFWEEK(trans_date_trans_time)
ORDER BY DAYOFWEEK(trans_date_trans_time);


-- --------------------------------------------------------------------

SHOW FULL TABLES FROM fraude_cartao WHERE TABLE_TYPE = 'VIEW'; -- verifica as views criadas
DROP VIEW horarios_fraudes; -- deletar viu para alterar o dataset
DROP VIEW taxa_media_categoria;
DROP VIEW transacoes_fraudes_normais;
SELECT * FROM vw_analise_temporal; -- verificar view criada

SHOW VARIABLES LIKE 'wait_timeout'; -- verificando o timeout do servidor

SHOW VARIABLES LIKE 'net_read_timeout'; -- verificando a leitura 
SHOW VARIABLES LIKE 'net_write_timeout'; 

SET GLOBAL net_read_timeout = 600; -- alterando timeout para o servidor para de reiniciar durante uma consulta 
SET GLOBAL net_write_timeout = 600;