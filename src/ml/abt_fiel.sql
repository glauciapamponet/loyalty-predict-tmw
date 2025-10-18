--  ABT: Analytical Base Table
-- Criação da base de dados recebida pelos modelos, em granularidade de cliente,
-- com informações sumarizadas de 28 dias atrás
-- Construção do predict do modelo: descobrir qual a perspectiva do cliente virar 
-- fiel nos proximos 28 dias baseado nos ultimos 28 dias

DROP TABLE IF EXISTS abt_fiel;
CREATE TABLE IF NOT EXISTS abt_fiel AS

-- randomCol: preservar a independencia das amostras diminuindo aleatoriamente amostras 
-- parecidas dos mesmos clientes, pois gera viés no modelo. 
WITH tb_flag_maker AS (
    SELECT
        t1.dtRef,
        t1.IdCliente,
        t1.catLifeCycle,
        t2.catLifeCycle,
        CASE WHEN t2.catLifeCycle = '02-FIEL' THEN 1 ELSE 0 END AS flFiel,
        ROW_NUMBER() OVER (PARTITION BY t1.IdCliente ORDER BY RANDOM()) AS randomCol
    FROM
        life_cycle t1 LEFT JOIN life_cycle t2
        ON t1.IdCliente = t2.IdCliente
        AND DATE(t1.dtRef, '+28 day') = DATE(t2.dtRef)
    WHERE
        ((t1.dtRef >= '2024-09-30' AND t1.dtRef <= '2025-07-30')
        OR t1.dtRef = '2025-09-01')
        AND t1.catLifeCycle <> '05-ZUMBI'),

tb_cohort AS (
    SELECT
        dtRef,
        IdCliente,
        flFiel
    FROM tb_flag_maker 
    WHERE randomCol <= 2
    ORDER BY IdCliente, dtRef)

SELECT
    t1.*,
    t2.idadeDias,
    t2.freqDiasD7,
    t2.freqDiasD14,
    t2.freqDiasD28,
    t2.freqDiasD56,
    t2.freqDiasVida,
    t2.freqTransacaoD7,
    t2.freqTransacaoD14,
    t2.freqTransacaoD28,
    t2.freqTransacaoD56,
    t2.freqTransacaoVida,
    t2.saldoPontosD7,
    t2.saldoPontosD14,
    t2.saldoPontosD28,
    t2.saldoPontosD56,
    t2.saldoVida,
    t2.qtdPontosPosD7,
    t2.qtdPontosPosD14,
    t2.qtdPontosPosD28,
    t2.qtdPontosPosD56,
    t2.qtdPontosPosVida,
    t2.qtdPontosNegD7,
    t2.qtdPontosNegD14,
    t2.qtdPontosNegD28,
    t2.qtdPontosNegD56,
    t2.qtdPontosNegVida,
    t2.totalHorasManha,
    t2.totalHorasTarde,
    t2.totalHorasNoite,
    t2.pctTransacoesManha,
    t2.pctTransacoesTarde,
    t2.pctTransacoesNoite,
    t2.medTransacoesAtivoD7,
    t2.medTransacoesAtivoD14,
    t2.medTransacoesAtivoD28,
    t2.medTransacoesAtivoD56,
    t2.percentAtivMAU,
    t2.qtdHorasD7,
    t2.qtdHorasD14,
    t2.qtdHorasD28,
    t2.qtdHorasD56,
    t2.qtdHorasVida,
    t2.mediaIntervaloAtivVida,
    t2.mediaIntervaloAtivD28,
    t2.pctTipoChatMessage,
    t2.pctTipoListaPresenÃ§a,
    t2.pctTipoTrocaPontos,
    t2.pctTipoResgatarPonei,
    t2.pctTipoAirflowLover,
    t3.qtdFrequencia,
    t3.catLCAtual,
    t3.catLCD28,
    t3.pctFiel,
    t3.pctZumbi,
    t3.pctCurioso,
    t3.pctDesencantada,
    t3.pctTurista,
    t3.pctReborn,
    t3.pctReconquistado,
    t3.avgFreqCiclo,
    t3.ratioFreqCiclo,
    t4.qtdCursosCompletos,
    t4.qtdCursosIncompletos,
    t4.careira,
    t4.coletaDados2024,
    t4.dataPlatform2025,
    t4.dsDatabricks2024,
    t4.dsPontos2024,
    t4.estatistica2024,
    t4.estatistica2025,
    t4.github2024,
    t4.github2025,
    t4.iaCanal2025,
    t4.lagoMago2024,
    t4.loyaltyPredict2025,
    t4.machineLearning2025,
    t4.matchmakingTramparDeCasa2024,
    t4.ml2024,
    t4.mlflow2025,
    t4.pandas2024,
    t4.pandas2025,
    t4.python2024,
    t4.python2025,
    t4.sql2020,
    t4.sql2025,
    t4.streamlit2025,
    t4.tramparLakehouse2024,
    t4.tseAnalytics2024,
    t4.diasUltimaAtiv
FROM tb_cohort t1 
    LEFT JOIN fs_transacional t2
        ON t1.IdCliente = t2.IdCliente
        AND t1.dtRef = t2.dtRef
    LEFT JOIN fs_lifecycle t3
        ON t1.IdCliente = t3.IdCliente
        AND t1.dtRef = t3.dtRef
    LEFT JOIN fs_plataforma_cursos t4
        ON t1.IdCliente = t4.IdCliente
        AND t1.dtRef = t4.dtRef
WHERE t3.dtRef IS NOT NULL;