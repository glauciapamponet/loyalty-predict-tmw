-- Daily Active Users: observando os usuários ativos por dia
-- Usuário ativo: usuário que enviou ao menos uma mensagem no chat a cada dia

SELECT substr(DtCriacao,0, 11) AS DtDia,
       count(DISTINCT IdCliente) AS DAU

FROM transacoes
GROUP BY 1
ORDER BY DtDia