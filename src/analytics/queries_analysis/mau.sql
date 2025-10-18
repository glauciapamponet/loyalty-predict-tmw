-- Monthly Active Users: observando a quantidade de usuários ativos por Mês
-- MAU acaba sendo mais consistente que o DAU nesse caso
-- Usuários ativos: que mandaram ao menos uma mensagem no chat a cada dia

-- Olhar o MAU de forma mensal pode ser uma escolha que indique problemas de 
-- sumariedade, pois nem todos os meses tem a mesma quantidade de dias e
-- a distribuição de dias da semana é diferente a cada mês

-- Assim, o ideal é adotar uma janela de 28 dias, pois nesse intervalo é
-- possível captar a mesma quantidde de dias da semana para todos os meses.
-- Isso evita a representação ser enviesada por sazonalidade de dia da semana.

WITH tb_daily AS (

    SELECT DISTINCT 
        date(substr(DtCriacao,0,11)) AS DtDia,
        IdCliente

    FROM transacoes
    order by DtDia

),

tb_distinct_day AS (

    SELECT
            DISTINCT DtDia AS dtRef
    FROM tb_daily

)

SELECT t1.dtRef,
       count( distinct IdCliente) AS MAU,
       count(distinct t2.dtDia) AS qtdeDias

FROM tb_distinct_day AS t1

LEFT JOIN tb_daily AS t2
ON t2.DtDia <= t1.dtRef
AND julianday(t1.dtRef) - julianday(t2.DtDia) < 28

GROUP BY t1.dtRef

ORDER BY t1.dtRef ASC
