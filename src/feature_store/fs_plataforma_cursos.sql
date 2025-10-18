-- FEATURE STORE: Plataforma de Cursos TeoMeWhy
-- Montagem de características na granularidade de cliente baseado no possivel cadastro
-- na plataforma de cursos linkado com o id da twitch

WITH tb_qtd_curso_assistido AS (
    SELECT idUsuario,
        descSlugCurso,
        COUNT(descSlugCursoEpisodio) qtdAssistido
    FROM cursos_episodios_completos
    GROUP BY idUsuario, descSlugCurso),

tb_qtd_curso AS (
    SELECT 
        descSlugCurso,
        COUNT(descEpisodio) as qtdEps
    FROM cursos_episodios
    GROUP BY descSlugCurso
),

tb_andamento_cursos AS (
    SELECT
        t1.idUsuario,
        t1.descSlugCurso,
        1. * t1.qtdAssistido / t2.qtdEps AS pctAssistido
    FROM
        tb_qtd_curso_assistido t1 LEFT JOIN tb_qtd_curso t2
        ON t1.descSlugCurso = t2.descSlugCurso
    GROUP BY t1.idUsuario),

-- 1. Cursos completos na plataforma de cursos (Qtde e quais)
-- 2. Cursos iniciados na plataforma de cursos (Qtde e quais)
tb_cursos_completos_pivot AS (
    SELECT
        idUsuario,
        SUM(CASE WHEN pctAssistido = 1 THEN 1 ELSE 0 END) AS qtdCursosCompletos,
        SUM(CASE WHEN pctAssistido > 0 AND pctAssistido < 1 THEN 1 ELSE 0 END) AS qtdCursosIncompletos,
        SUM(CASE WHEN descSlugCurso = 'carreira' THEN pctAssistido ELSE 0 END) AS careira,
        SUM(CASE WHEN descSlugCurso = 'coleta-dados-2024' THEN pctAssistido ELSE 0 END) AS coletaDados2024,
        SUM(CASE WHEN descSlugCurso = 'data-platform-2025' THEN pctAssistido ELSE 0 END) AS dataPlatform2025,
        SUM(CASE WHEN descSlugCurso = 'ds-databricks-2024' THEN pctAssistido ELSE 0 END) AS dsDatabricks2024,
        SUM(CASE WHEN descSlugCurso = 'ds-pontos-2024' THEN pctAssistido ELSE 0 END) AS dsPontos2024,
        SUM(CASE WHEN descSlugCurso = 'estatistica-2024' THEN pctAssistido ELSE 0 END) AS estatistica2024,
        SUM(CASE WHEN descSlugCurso = 'estatistica-2025' THEN pctAssistido ELSE 0 END) AS estatistica2025,
        SUM(CASE WHEN descSlugCurso = 'github-2024' THEN pctAssistido ELSE 0 END) AS github2024,
        SUM(CASE WHEN descSlugCurso = 'github-2025' THEN pctAssistido ELSE 0 END) AS github2025,
        SUM(CASE WHEN descSlugCurso = 'ia-canal-2025' THEN pctAssistido ELSE 0 END) AS iaCanal2025,
        SUM(CASE WHEN descSlugCurso = 'lago-mago-2024' THEN pctAssistido ELSE 0 END) AS lagoMago2024,
        SUM(CASE WHEN descSlugCurso = 'loyalty-predict-2025' THEN pctAssistido ELSE 0 END) AS loyaltyPredict2025,
        SUM(CASE WHEN descSlugCurso = 'machine-learning-2025' THEN pctAssistido ELSE 0 END) AS machineLearning2025,
        SUM(CASE WHEN descSlugCurso = 'matchmaking-trampar-de-casa-2024' THEN pctAssistido ELSE 0 END) AS matchmakingTramparDeCasa2024,
        SUM(CASE WHEN descSlugCurso = 'ml-2024' THEN pctAssistido ELSE 0 END) AS ml2024,
        SUM(CASE WHEN descSlugCurso = 'mlflow-2025' THEN pctAssistido ELSE 0 END) AS mlflow2025,
        SUM(CASE WHEN descSlugCurso = 'pandas-2024' THEN pctAssistido ELSE 0 END) AS pandas2024,
        SUM(CASE WHEN descSlugCurso = 'pandas-2025' THEN pctAssistido ELSE 0 END) AS pandas2025,
        SUM(CASE WHEN descSlugCurso = 'python-2024' THEN pctAssistido ELSE 0 END) AS python2024,
        SUM(CASE WHEN descSlugCurso = 'python-2025' THEN pctAssistido ELSE 0 END) AS python2025,
        SUM(CASE WHEN descSlugCurso = 'sql-2020' THEN pctAssistido ELSE 0 END) AS sql2020,
        SUM(CASE WHEN descSlugCurso = 'sql-2025' THEN pctAssistido ELSE 0 END) AS sql2025,
        SUM(CASE WHEN descSlugCurso = 'streamlit-2025' THEN pctAssistido ELSE 0 END) AS streamlit2025,
        SUM(CASE WHEN descSlugCurso = 'trampar-lakehouse-2024' THEN pctAssistido ELSE 0 END) AS tramparLakehouse2024,
        SUM(CASE WHEN descSlugCurso = 'tse-analytics-2024' THEN pctAssistido ELSE 0 END) AS tseAnalytics2024

    FROM tb_andamento_cursos
    GROUP BY idUsuario),
    
tb_data_atividade AS (
        SELECT
            idUsuario,
            MAX(dtRecompensa) AS dtCriacao
        FROM recompensas_usuarios
        WHERE dtRecompensa < '2025-09-30'
        GROUP BY idUsuario
    UNION ALL
        SELECT 
            idUsuario,
            MAX(dtCriacao) AS dtCriacao
        FROM habilidades_usuarios
        WHERE dtCriacao < '2025-09-30'
        GROUP BY idUsuario
    UNION ALL
        SELECT
            idUsuario,
            MAX(dtCriacao) AS dtCriacao
        FROM cursos_episodios_completos
        WHERE dtCriacao < '2025-09-30'
        GROUP BY idUsuario),

-- 3. Dias desde a última interação na plataforma de cursos
tb_ultima_ativ AS (
    SELECT 
        idUsuario,
        MIN(JULIANDAY('2025-09-30') - JULIANDAY(dtCriacao)) AS diasUltimaAtiv
    FROM tb_data_atividade
    GROUP BY idUsuario)


-- LEFT JOIN das Features e INNER JOIN do DE PARA (usuário Twitch >< Usuario TMW)
SELECT
    DATE('{date}', '-1 day') AS dtRef,
    t3.idTMWCliente AS idCliente,
    t1.qtdCursosCompletos,
    t1.qtdCursosIncompletos,
    t1.careira,
    t1.coletaDados2024,
    t1.dataPlatform2025,
    t1.dsDatabricks2024,
    t1.dsPontos2024,
    t1.estatistica2024,
    t1.estatistica2025,
    t1.github2024,
    t1.github2025,
    t1.iaCanal2025,
    t1.lagoMago2024,
    t1.loyaltyPredict2025,
    t1.machineLearning2025,
    t1.matchmakingTramparDeCasa2024,
    t1.ml2024,
    t1.mlflow2025,
    t1.pandas2024,
    t1.pandas2025,
    t1.python2024,
    t1.python2025,
    t1.sql2020,
    t1.sql2025,
    t1.streamlit2025,
    t1.tramparLakehouse2024,
    t1.tseAnalytics2024,
    t2.diasUltimaAtiv
FROM 
    tb_cursos_completos_pivot t1 LEFT JOIN tb_ultima_ativ t2
    ON t1.idUsuario = t2.idUsuario
    INNER JOIN usuarios_tmw t3
    ON t1.idUsuario = t3.idUsuario;
    


