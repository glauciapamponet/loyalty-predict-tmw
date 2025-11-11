#%%
import os
import sqlalchemy
import pandas as pd

import matplotlib.pyplot as plt
import seaborn as sn

os.chdir("C:/Users/glaup/Desktop/DADOS/Bootcamps/TMW/Loyalty Predict/loyalty-predict-tmw/src")

LOYALTY_PATH = "sqlite:///../data/loyalty_system/database.db"
engine_loyalty = sqlalchemy.create_engine(LOYALTY_PATH)

def import_query(path):
    with open(path) as open_file:
        query = open_file.read()
    return query

#%%
query = "SELECT " \
            "SUBSTR(DtCriacao, 0, 8) AS DtMAU, " \
            "COUNT(DISTINCT IdCliente) AS MAU " \
        "FROM transacoes " \
        "GROUP BY 1 " \
        "ORDER BY DtMAU"

df = pd.read_sql(query, engine_loyalty)
plt.figure(figsize=(10, 4))
sn.lineplot(df, x="DtMAU", y="MAU")
plt.title("MAU - Ecossistema TMW")
plt.xticks(rotation=45)
plt.show()

# %%
query = import_query("analytics/queries_analysis/dau.sql")
df = pd.read_sql(query, engine_loyalty)
df['DtDia'] = pd.to_datetime(df['DtDia'])
sn.lineplot(df, x="DtDia", y="DAU")
plt.title("DAU - Ecossistema TMW")
plt.xticks(pd.date_range(start=df['DtDia'].min(), 
            end=df['DtDia'].max(), 
            freq='3M'),
            rotation=45)

# %%
query = import_query("analytics/queries_analysis/stickiness.sql")

df = pd.read_sql(query, engine_loyalty)

plt.figure(figsize=(10, 4))
ax1 = sn.lineplot(data=df, x="DtMes", y="mau", color="blue", label="MAU")
ax1.set_ylabel("MAU")
plt.xticks(rotation=45)

ax2 = ax1.twinx()
ax2 = sn.lineplot(data=df, x="DtMes", y="stickiness", color="red", label="Stickiness", ax=ax2)
ax2.set_ylabel("Stickiness")
ax2.set_yticks([i*0.1 for i in range(2, 11, 2)])

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax2.legend(lines1 + lines2, labels1 + labels2, loc='upper left')

if ax1.get_legend():
    ax1.get_legend().remove()

plt.title("Ecossistema TMW - MAU & Stickiness")
plt.show()


#%%
query_teste = import_query("analytics/queries_analysis/stickiness.sql")
df_teste = pd.read_sql(query_teste, engine_loyalty)
# df_teste[df_teste["DtMes"] == "2024-02"]["dau_diario"].mean()
df_teste

#%%
query = import_query("analytics/queries_analysis/frequencia_pontos.sql")
df = pd.read_sql(query, engine_loyalty)

plt.figure(figsize=(10, 4))
ax1 = sn.barplot(data=df, x="dataRef", y="mediaPontos", color="#3de3b7", label="Pontuação Media", legend=None)
ax1.set_ylabel("Pontuação Media por Usuário")
plt.xticks(rotation=55)

ax2 = ax1.twinx()
ax2 = sn.lineplot(data=df, x="dataRef", y="frequencia", color="blue", label="Frequencia do Dia", ax=ax2)
ax2.set_ylabel("Frequencia")

lines1, labels1 = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax2.legend(lines1 + lines2, labels1 + labels2, loc='upper left')

plt.title("Ecossistema TMW - Pontuação Média e Frequencia: 28 Dias")
plt.show()