-- FEATURE STORE: Ciclo de Vida do Usuário
-- Montagem de características na granularidade de cliente baseado no banco analytics (lifecycle, mau, dau)

-- 1. Ciclo de vida no MAU D28
WITH tb_lifecycle_atual AS (
    SELECT
        IdCliente,
        qtdFrequencia,
        catLifeCycle AS catLCAtual
    FROM life_cycle
    WHERE dtRef = DATE('{date}', '-1 day')),

tb_lifecycle_D28 AS (SELECT
    IdCliente,
    catLifeCycle AS catLCD28
FROM life_cycle
WHERE dtRef = DATE('{date}', '-29 day')),

-- 2. Porcentagem de tempo que ficou em cada ciclo
tb_share_ciclos AS (SELECT
    IdCliente,
    1. * SUM(CASE WHEN catLifeCycle = '02-FIEL' THEN 1 ELSE 0 END) / COUNT(*) AS pctFiel,
    1. * SUM(CASE WHEN catLifeCycle = '05-ZUMBI' THEN 1 ELSE 0 END) / COUNT(*) AS pctZumbi,
    1. * SUM(CASE WHEN catLifeCycle = '01 - CURIOSO' THEN 1 ELSE 0 END) / COUNT(*) AS pctCurioso,
    1. * SUM(CASE WHEN catLifeCycle = '04-DESENCANTADA' THEN 1 ELSE 0 END) / COUNT(*) AS pctDesencantada,
    1. * SUM(CASE WHEN catLifeCycle = '03-TURISTA' THEN 1 ELSE 0 END) / COUNT(*) AS pctTurista,
    1. * SUM(CASE WHEN catLifeCycle = '07-REBORN' THEN 1 ELSE 0 END) / COUNT(*) AS pctReborn,
    1. * SUM(CASE WHEN catLifeCycle = '06-RECONQUISTADO' THEN 1 ELSE 0 END) / COUNT(*) AS pctReconquistado
FROM life_cycle
WHERE dtRef < '{date}'
GROUP BY IdCliente),

tb_avg_ciclo AS (
    SELECT
        catLCAtual,
        AVG(qtdFrequencia) AS avgFreqCiclo
    FROM tb_lifecycle_atual
    GROUP BY catLCAtual),

-- Unindo no Join
tb_join_lifecycle AS (
    SELECT
        t1.*,
        t2.catLCD28,
        t3.pctFiel,
        t3.pctZumbi,
        t3.pctCurioso,
        t3.pctDesencantada,
        t3.pctTurista,
        t3.pctReborn,
        t3.pctReconquistado,
        t4.avgFreqCiclo,
        1. * t1.qtdFrequencia / t4.avgFreqCiclo AS ratioFreqCiclo
    FROM tb_lifecycle_atual t1 LEFT JOIN tb_lifecycle_D28 t2
        ON t1.IdCliente = t2.IdCliente
    LEFT JOIN tb_share_ciclos t3
        ON t2.IdCliente = t3.IdCliente
    LEFT JOIN tb_avg_ciclo t4
        ON t1.catLCAtual = t4.catLCAtual)

SELECT
    DATE('{date}', '-1 day') as dtRef,
    *
FROM tb_join_lifecycle;
