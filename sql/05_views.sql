USE fraude_cartao;

-- Transações por faixa de valor
CREATE VIEW vw_transacoes_por_valor AS
SELECT 
    CASE 
        WHEN amt >= 1000 THEN 'Alto Valor'
        ELSE 'Baixo Valor'
    END AS faixa_valor,
    COUNT(*) AS total_transacoes
FROM transacoes 
GROUP BY faixa_valor;

-- Taxa média de fraude por categoria (acima da média global)
CREATE VIEW vw_taxa_fraude_categoria AS
WITH media_global AS (
    SELECT AVG(is_fraud) AS media 
    FROM transacoes
)
SELECT 
    category,
    ROUND(AVG(is_fraud) * 100, 2) AS taxa_fraude_percentual
FROM transacoes
GROUP BY category
HAVING AVG(is_fraud) > (SELECT media FROM media_global)
ORDER BY taxa_fraude_percentual DESC;

-- Fraudes por período do dia
CREATE VIEW vw_fraude_por_periodo AS
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

-- Transações fraude vs normal
CREATE VIEW vw_transacoes_tipo AS
SELECT 
    CASE 
        WHEN is_fraud = 1 THEN 'fraude'
        ELSE 'normal'
    END AS tipo_transacao,
    COUNT(*) AS total_transacoes
FROM transacoes
GROUP BY is_fraud;