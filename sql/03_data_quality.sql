USE fraude_cartao;

-- Volume de dados
SELECT COUNT(*) AS total_registros
FROM transacoes;

-- Preview dos dados
SELECT * 
FROM transacoes 
LIMIT 5;

-- Verificar datas inválidas
SELECT COUNT(*) AS datas_invalidas
FROM transacoes
WHERE trans_date_trans_time = '0000-00-00 00:00:00';

-- Distribuição de datas (amostra)
SELECT trans_date_trans_time, COUNT(*) 
FROM transacoes 
GROUP BY trans_date_trans_time 
LIMIT 10;

-- Verificar datas válidas
SELECT trans_date_trans_time 
FROM transacoes 
WHERE trans_date_trans_time IS NOT NULL
LIMIT 5;

-- Verificar modo SQL
SHOW VARIABLES LIKE 'sql_mode';

-- Verificação de valores nulos
SELECT 
    COUNT(*) AS total,
    SUM(CASE WHEN trans_date_trans_time IS NULL THEN 1 ELSE 0 END) AS data_nula,
    SUM(CASE WHEN amt IS NULL THEN 1 ELSE 0 END) AS valor_nulo,
    SUM(CASE WHEN is_fraud IS NULL THEN 1 ELSE 0 END) AS fraud_nulo
FROM transacoes;