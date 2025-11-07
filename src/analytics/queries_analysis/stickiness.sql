-- STICKINESS: Taxa de aderência do público ao ecossistema TMW mensalmente
-- Selecionamos os dias normais de live (seg a sex) dentro da base de dados
-- STICKINESS = dau_diario/mau

-- DAU diario selecionado do agrupamento por dia, pois:
-- AVG(DAU agrupado a Mês) = MAU do Mês -> Stickiness = 1.0
WITH dau AS (
    SELECT 
        substr(DtCriacao, 1, 7) AS DtMes,
        substr(DtCriacao, 1, 10) AS dia,
        COUNT(DISTINCT IdCliente) AS dau_diario
    FROM transacoes
    WHERE STRFTIME('%w', substr(DtCriacao, 1, 10)) NOT IN ("0", "6")
    GROUP BY DtMes, dia
),

mau AS (
    SELECT 
        substr(DtCriacao, 1, 7) AS DtMes,
        COUNT(DISTINCT IdCliente) AS mau
    FROM transacoes
    WHERE STRFTIME('%w', substr(DtCriacao, 1, 10)) NOT IN ("0", "6")
    GROUP BY DtMes
)

SELECT 
    d.DtMes,
    ROUND(AVG(d.dau_diario), 2) AS avg_dau,
    m.mau,
    ROUND((AVG(d.dau_diario) * 1.0 / m.mau), 2) AS stickiness
FROM dau d
JOIN mau m ON d.DtMes = m.DtMes
GROUP BY d.DtMes
ORDER BY d.DtMes;
