-- RFV - RECÊNCIA: Categorizando o MAU em fases do ciclo de vida do usuário
-- Recencia = (tempo desde penultimo dia - tempo desde ultimo dia)


WITH tb_daily AS (
    SELECT DISTINCT
        IdCliente,
        (substr(DtCriacao, 0, 11)) as dtDia
    FROM transacoes
    WHERE DtCriacao < '{date}'),

tb_primeiro_ultimo AS (
    SELECT 
        IdCliente, 
        CAST(MAX(JULIANDAY('{date}')-JULIANDAY(dtDia)) AS int) AS diasPrimInteracao,
        CAST(MIN(JULIANDAY('{date}')-JULIANDAY(dtDia)) AS int) AS diasUltInteracao
    FROM tb_daily
    GROUP BY IdCliente),

tb_rn AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY IdCliente ORDER BY dtDia DESC) AS rnDia
    FROM tb_daily),

tb_penultima AS(
    SELECT 
    *,
    CAST((JULIANDAY('{date}')-JULIANDAY(dtDia)) AS INTEGER) AS diasPenultInteracao
    FROM tb_rn 
    WHERE rnDia = 2),

-- CATEGORIAS
-- Curiosa: tempo desde ultimo dia <= 7
-- Fiel: tempo desde ultimo dia <= 7 e recencia < 15
-- Turista: 7 <= recência <= 14
-- Desencantada: recência <= 28
-- Zumbi: recência  > 28
-- Reconquistada: recência < 7 e 14 <= recencia <= 28
-- Reborn: recencia < 7 e recencia > 28

tb_lifeCycle AS (
    SELECT 
        t1.*,
        t2.diasPenultInteracao,
        CASE
            WHEN diasPrimInteracao <= 7 THEN '01 - CURIOSO'
            WHEN diasUltInteracao <= 7 AND diasPenultInteracao - diasUltInteracao <= 14 THEN '02-FIEL'
            WHEN diasUltInteracao BETWEEN 8 AND 14 THEN '03-TURISTA'
            WHEN diasUltInteracao BETWEEN 15 AND 28 THEN '04-DESENCANTADA'
            WHEN diasUltInteracao > 28 THEN '05-ZUMBI'
            WHEN diasUltInteracao <= 7 AND diasPenultInteracao - diasUltInteracao BETWEEN 15 AND 27 THEN '06-RECONQUISTADO'
            WHEN diasUltInteracao <= 7 AND diasPenultInteracao - diasUltInteracao > 27 THEN '07-REBORN'
        END AS catLifeCycle
        
    FROM 
        tb_primeiro_ultimo AS t1 
        LEFT JOIN tb_penultima AS t2
        ON t1.IdCliente = t2.IdCliente), 

-- RFV - FREQUENCIA e VALOR
-- Coletando a frequencia de usuários dentro da janela de 28 dias do MAU, baseado  
-- nas transações e no saldo de pontos
-- Construção de tabelas para descobrir as categorias de frequencia dos clientes

tb_frequencia_valor AS (SELECT 
    IdCliente,
    COUNT(DISTINCT SUBSTR(DtCriacao,0,11)) AS qtdFrequencia,
    SUM(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS somaPontos
FROM transacoes
WHERE DtCriacao < '{date}' AND DtCriacao >= DATE('{date}', '-28 days')
GROUP BY 1
ORDER BY qtdFrequencia DESC),

-- Categorias baseada no clustering e comportamento de dados Freq x Saldo:
-- HYPERS: Baixa frequencia e alto saldo de pontos (povavelmente tem alto tempo de live)
-- EFICIENTES: Alta frequencia e alto saldo de pontos
-- ESFORÇADOS: Frequencia mediana e saldo mediano
-- INTERESSADOS: Alta frequencia e ascenção de saldo
-- PREGUIÇOSOS: Baixa frequencia e baixo saldo
-- OLHEIROS: Frequencia baixissima e saldo baixissimo

-- A arquitetura de hierarquia dessas categorias ajuda a pensar em congratulações ou
-- premiações para os clientes (Ex: streak de presença - 5 dias = 100 pontos)

tb_cluster AS (SELECT *,
    CASE
        WHEN qtdFrequencia < 12 AND somaPontos >= 2000 THEN '10-HYPER'
        WHEN qtdFrequencia >= 12 AND somaPontos > 3000 THEN '21-EFICIENTE'
        WHEN qtdFrequencia >= 12 AND somaPontos >= 2000 THEN '20-ESFORCADO'
        WHEN qtdFrequencia >= 12 THEN '11-INTERESSADO'
        WHEN qtdFrequencia > 3 THEN '01-PREGUICOSO'
        WHEN qtdFrequencia <= 3 THEN '00-OLHEIRO'
    END AS catFreqValor
FROM tb_frequencia_valor)

SELECT 
    DATE('{date}', '-1 day') AS dtRef,
    t1.*,
    t2.qtdFrequencia,
    t2.somaPontos,
    t2.catFreqValor
FROM 
    tb_lifeCycle t1 LEFT JOIN tb_cluster t2
    ON t1.IdCliente = t2.IdCliente