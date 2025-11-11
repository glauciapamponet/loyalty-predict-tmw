WITH grupo_freq_valor AS (
    SELECT 
        SUBSTR(DtCriacao,0,11) AS dataRef,
        IdCliente,
        COUNT(DISTINCT SUBSTR(DtCriacao,0,11)) AS qtdFrequencia,
        SUM(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS somaPontos
    FROM transacoes
    WHERE DtCriacao < '2025-09-30' AND DtCriacao >= DATE('2025-09-30', '-28 days')
    GROUP BY 1, 2
    ORDER BY dataRef)

SELECT
    dataRef,
    ROUND(SUM(somaPontos)/SUM(qtdFrequencia), 0) AS mediaPontos,
    SUM(qtdFrequencia) frequencia
FROM grupo_freq_valor
GROUP BY dataRef
ORDER BY dataRef
