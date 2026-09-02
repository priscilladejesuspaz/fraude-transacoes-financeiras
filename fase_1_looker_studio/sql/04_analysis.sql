USE fraude_cartao;

-- Quantidade de transações por tipo (fraude vs normal)
SELECT 
    CASE 
        WHEN is_fraud = 1 THEN 'fraude'
        ELSE 'normal'
    END AS tipo_transacao,
    COUNT(*) AS total_transacoes
FROM transacoes
GROUP BY is_fraud
ORDER BY total_transacoes DESC;

-- Percentual de fraude vs normal
SELECT 
    CASE 
        WHEN is_fraud = 1 THEN 'fraude'
        ELSE 'normal'
    END AS tipo_transacao,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentual
FROM transacoes
GROUP BY is_fraud;

-- Distribuição de transações por categoria
SELECT 
    category,
    COUNT(*) AS total_transacoes
FROM transacoes
GROUP BY category
ORDER BY total_transacoes DESC;

-- Valor médio das transações por tipo (fraude vs normal)
SELECT 
    CASE 
        WHEN is_fraud = 1 THEN 'fraude'
        ELSE 'normal'
    END AS tipo_transacao,
    ROUND(AVG(amt), 2) AS valor_medio
FROM transacoes
GROUP BY is_fraud;

-- Distribuição de fraude por período do dia
SELECT 
    CASE 
        WHEN HOUR(trans_date_trans_time) BETWEEN 0 AND 5 THEN 'madrugada'
        WHEN HOUR(trans_date_trans_time) BETWEEN 6 AND 11 THEN 'manha'
        WHEN HOUR(trans_date_trans_time) BETWEEN 12 AND 17 THEN 'tarde'
        ELSE 'noite'
    END AS periodo,
    COUNT(*) AS total_transacoes,
    SUM(is_fraud) AS total_fraudes,
    ROUND(AVG(is_fraud) * 100, 2) AS taxa_fraude_percentual
FROM transacoes
GROUP BY periodo
ORDER BY taxa_fraude_percentual DESC;