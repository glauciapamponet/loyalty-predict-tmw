-- RFV - FREQUENCIA e VALOR
-- Coletando a frequencia de usuários dentro da janela de 28 dias do MAU, baseado  
-- nas transações e no saldo de pontos
-- Construção de tabelas para descobrir as categorias de frequencia dos clientes

WITH tb_frequencia_valor AS (SELECT 
    IdCliente,
    COUNT(DISTINCT SUBSTR(DtCriacao,0,11)) AS qtdFrequencia,
    SUM(CASE WHEN QtdePontos > 0 THEN QtdePontos ELSE 0 END) AS somaPontos
FROM transacoes
WHERE DtCriacao < '2025-09-30' AND DtCriacao >= DATE('2025-09-30', '-28 days')
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

-- SELECT 
--     t1.*,
--     t2.qtdFrequencia,
--     t2.somaPontos,
--     t2.catFreqValor
-- FROM 
--     tb_lifeCycle t1 LEFT JOIN tb_cluster t2
--     ON t1.IdCliente = t2.IdCliente