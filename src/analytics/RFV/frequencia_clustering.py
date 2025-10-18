#%%
import sqlalchemy
import pandas as pd

import matplotlib.pyplot as plt
import seaborn as sn

from sklearn.cluster import KMeans
from sklearn.preprocessing import MinMaxScaler

LOYALTY_PATH = "sqlite:///../../data/loyalty_system/database.db"
ANALYTICS_PATH = "sqlite:///../../data/analytics/database.db"


def import_query(path):
    with open(path) as open_file:
        query = open_file.read()
    return query

#%%
query = import_query("frequencia_valor.sql")
engine_loyalty = sqlalchemy.create_engine(LOYALTY_PATH)

df = pd.read_sql(query, engine_loyalty)
df = df[df["somaPontos"] < 6000]
plt.plot(df["qtdFrequencia"], df["somaPontos"], "o")
plt.xlabel("Frequencia - Dias")
plt.ylabel("SaldoPontos")
plt.title("Distribuição - Frequencia vs SaldoPontos em 28 Dias")
plt.grid(True)
plt.show()

#%%
model = KMeans(n_clusters=5, random_state=42, max_iter=1000)
scaled_X = MinMaxScaler().fit_transform(df[["qtdFrequencia", "somaPontos"]])
model.fit(scaled_X)
df["cluster"] = model.labels_

sn.scatterplot(data=df, x="qtdFrequencia", y="somaPontos", hue="cluster", palette="deep")

#%%
max_pontos = df["somaPontos"].max()
sn.scatterplot(data=df, x="qtdFrequencia", y="somaPontos", hue="cluster", palette="deep")
plt.hlines(y=2000, xmin=0, xmax=25, colors="black", linestyles="dotted")
plt.hlines(y=3000, xmin=12, xmax=25, colors="black", linestyles="dotted")
plt.vlines(x=3, ymin=0, ymax=2000, colors="black", linestyles="dotted")
plt.vlines(x=12, ymin=0, ymax=max_pontos, colors="black", linestyles="dotted")
plt.title("Análise de Categoria de Frequência")


#%%
df_cat = pd.read_sql(import_query("frequencia_valor.sql"), engine_loyalty)
df_cat = df_cat[df_cat["somaPontos"] < 6000]
sn.scatterplot(data=df_cat, 
               x="qtdFrequencia", 
               y="somaPontos", 
               hue="catFreqValor", 
               palette="deep")
plt.title("Distribuição - Regras Finais")