-- FEATURE STORE : Parte Transacional
-- Montagem de características na granularidade de cliente baseado nos dados da tabela transacoes

WITH tb_transacao AS (
    SELECT 
        *,
        SUBSTR(DtCriacao, 0, 11) AS dtDia,
        CAST((SUBSTR(DtCriacao, 12,2)) AS int) AS dtHora
    FROM transacoes
    WHERE dtCriacao < '{date}'),

-- 1. Frequencia em Dias (D7, D14, D28, D56, Vida)
-- 2. Frequencia em transações (D7, D14, D28, D56, Vida)
-- 4. Valor de Pontos (pos, neg, abs) (D7, D14, D28, D56, Vida)
-- 8. Idade na base em Dias
-- 9. Horas totais de live por periodo do dia (Manhã, Tarde, Noite)
-- 10. Porcentagem do periodo do dia (Manhã, Tarde, Noite)

tb_agg_transacao AS (
    SELECT
        IdCliente,

        MAX(JULIANDAY('{date}') - JULIANDAY(DtCriacao)) AS idadeDias,

        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-7 day') THEN dtDia END) AS freqDiasD7,
        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-14 day') THEN dtDia END) AS freqDiasD14,
        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-28 day') THEN dtDia END) AS freqDiasD28,
        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-56 day') THEN dtDia END) AS freqDiasD56,
        COUNT(DISTINCT DtCriacao) AS freqDiasVida,

        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-7 day') THEN IdTransacao END) AS freqTransacaoD7,
        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-14 day') THEN IdTransacao END) AS freqTransacaoD14,
        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-28 day') THEN IdTransacao END) AS freqTransacaoD28,
        COUNT(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-56 day') THEN IdTransacao END) AS freqTransacaoD56,
        COUNT(DISTINCT IdTransacao) AS freqTransacaoVida,

        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-7 day') THEN qtdePontos ELSE 0 END) AS saldoPontosD7,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-14 day') THEN qtdePontos ELSE 0 END) AS saldoPontosD14,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-28 day') THEN qtdePontos ELSE 0 END) AS saldoPontosD28,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-56 day') THEN qtdePontos ELSE 0 END) AS saldoPontosD56,
        SUM(qtdePontos) AS saldoVida,

        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-7 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPosD7,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-14 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPosD14,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-28 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPosD28,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-56 day') AND qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPosD56,
        SUM(CASE WHEN qtdePontos > 0 THEN qtdePontos ELSE 0 END) AS qtdPontosPosVida,

        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-7 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegD7,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-14 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegD14,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-28 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegD28,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-56 day') AND qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegD56,
        SUM(CASE WHEN qtdePontos < 0 THEN qtdePontos ELSE 0 END) AS qtdPontosNegVida,

        COUNT(CASE WHEN dtHora BETWEEN 10 AND 14 THEN IdTransacao END) AS totalHorasManha,
        COUNT(CASE WHEN dtHora BETWEEN 15 AND 21 THEN IdTransacao END) AS totalHorasTarde,
        COUNT(CASE WHEN dtHora > 21 OR dtHora < 10 THEN IdTransacao END) AS totalHorasNoite,

        1. * COUNT(CASE WHEN dtHora BETWEEN 10 AND 14 THEN IdTransacao END) / COUNT(IdTransacao) AS pctTransacoesManha,
        1. * COUNT(CASE WHEN dtHora BETWEEN 15 AND 21 THEN IdTransacao END) / COUNT(IdTransacao) AS pctTransacoesTarde,
        1. * COUNT(CASE WHEN dtHora > 21 OR dtHora < 10 THEN IdTransacao END) / COUNT(IdTransacao) AS pctTransacoesNoite

    FROM tb_transacao
    GROUP BY IdCliente),

-- 3. Quantidade de transações por dia ativo (D7, D14, D28, D56)
-- 5. Percentual de ativação no MAU
tb_calculo_agg AS (
    SELECT
        *,
        CASE WHEN freqDiasD7 = 0 THEN 0. ELSE 1. * (freqTransacaoD7/freqDiasD7) END AS medTransacoesAtivoD7,
        CASE WHEN freqDiasD14 = 0 THEN 0. ELSE 1. * (freqTransacaoD14/freqDiasD14) END AS medTransacoesAtivoD14,
        CASE WHEN freqDiasD28 = 0 THEN 0. ELSE 1. * (freqTransacaoD28/freqDiasD28) END AS medTransacoesAtivoD28,
        CASE WHEN freqDiasD56 = 0 THEN 0. ELSE 1. * (freqTransacaoD56/freqDiasD56) END AS medTransacoesAtivoD56,

        (freqDiasD28 * 1.)/28.0 AS percentAtivMAU
    FROM tb_agg_transacao),

-- 6. Horas assistidas (D7, D14, D28, D56)
tb_horas_dia AS (SELECT
    IdCliente,
    dtDia,
    24 * (MAX(JULIANDAY(DtCriacao)) - MIN(JULIANDAY(DtCriacao))) AS duracao
FROM tb_transacao
GROUP BY IdCliente, dtDia),

tb_agg_horas AS (
    SELECT
        IdCliente,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-7 day') THEN duracao ELSE 0 END) AS qtdHorasD7,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-14 day') THEN duracao ELSE 0 END) AS qtdHorasD14,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-28 day') THEN duracao ELSE 0 END) AS qtdHorasD28,
        SUM(DISTINCT CASE WHEN dtDia >= DATE('{date}', '-56 day') THEN duracao ELSE 0 END) AS qtdHorasD56,
        SUM(duracao) AS qtdHorasVida
    FROM tb_horas_dia
    GROUP BY IdCliente),

-- 7. Intervalo entre ativação
tb_diff_dia AS (SELECT
    IdCliente,
    dtDia,
    LAG(dtDia) OVER (PARTITION BY IdCliente ORDER BY dtDia) AS lagDia
FROM tb_horas_dia),

tb_agg_intervalo_dias AS (
    SELECT
        IdCliente,
        AVG(JULIANDAY(dtDia) - JULIANDAY(lagDia)) AS mediaIntervaloAtivVida,
        AVG(CASE WHEN dtDia >= DATE('{date}', '-28 day') THEN (JULIANDAY(dtDia) - JULIANDAY(lagDia)) END) AS mediaIntervaloAtivD28
    FROM tb_diff_dia
    GROUP BY IdCliente),

-- 11. Porcentagem de produtos "comprados" (Marketshare dos tipos de transações)
tb_marketshare_prod_agg AS (
    SELECT
        t1.IdCliente,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'ChatMessage' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoChatMessage,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'Lista de presença' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoListaPresença,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'Troca de Pontos StreamElements' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoTrocaPontos,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'Resgatar Ponei' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoResgatarPonei,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'Airflow Lover' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoAirflowLover,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'Presença Streak' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoPresençaStreak,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'R Lover' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoRLover,
        1. * COUNT(CASE WHEN t3.DescNomeProduto = 'Reembolso: Troca de Pontos' THEN t1.IdTransacao END) / COUNT(t1.IdTransacao) AS pctTipoReembolso,
        1. * COUNT(CASE WHEN descCategoriaProduto = 'rpg' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS pctTipoRPG,
        1. * COUNT(CASE WHEN descCategoriaProduto = 'churn_model' THEN t1.IdTransacao END) / count(t1.IdTransacao) AS pctTipoChurnModel

    FROM tb_transacao AS t1
    LEFT JOIN transacao_produto AS t2
        ON t1.IdTransacao = t2.IdTransacao
    LEFT JOIN produtos AS t3
        ON t3.IdProduto = t2.IdProduto
    GROUP BY t1.IdCliente)

-- Unificando Features (Total de 55 colunas até agora - 03/10/2025):
SELECT
    DATE('{date}', '-1 day') AS dtRef,
    t1.*,
    t2.medTransacoesAtivoD7,
    t2.medTransacoesAtivoD14,
    t2.medTransacoesAtivoD28,
    t2.medTransacoesAtivoD56,
    t2.percentAtivMAU,
    t3.qtdHorasD7,
    t3.qtdHorasD14,
    t3.qtdHorasD28,
    t3.qtdHorasD56,
    t3.qtdHorasVida,
    t4.mediaIntervaloAtivVida,
    t4.mediaIntervaloAtivD28,
    t5.pctTipoChatMessage,
    t5.pctTipoListaPresença,
    t5.pctTipoTrocaPontos,
    t5.pctTipoResgatarPonei,
    t5.pctTipoAirflowLover,
    t5.pctTipoPresençaStreak,
    t5.pctTipoRLover,
    t5.pctTipoReembolso,
    t5.pctTipoRPG,
    t5.pctTipoChurnModel
FROM
    tb_agg_transacao AS t1
    LEFT JOIN tb_calculo_agg AS t2
        ON t1.IdCliente = t2.IdCliente
    LEFT JOIN tb_agg_horas AS t3
        ON t2.IdCliente = t3.IdCliente
    LEFT JOIN tb_agg_intervalo_dias AS t4
        ON t3.IdCliente = t4.IdCliente
LEFT JOIN tb_marketshare_prod_agg AS t5
        ON t4.IdCliente = t5.IdCliente;

