#%%
import matplotlib.pyplot as plt
import seaborn as sn
import pandas as pd
import sqlalchemy
import mlflow

from sklearn import model_selection as ms, tree, metrics, ensemble, pipeline

from feature_engine import selection, imputation, encoding

QUERY = "SELECT * FROM abt_fiel"
DB_ANALYTICS = "sqlite:///../../data/analytics/database.db"
ENGINE = sqlalchemy.create_engine(DB_ANALYTICS)

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment(experiment_id=254953468549675508)

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)

#%%
df_abt = pd.read_sql(QUERY, ENGINE)

#%% SAMPLE: Validação (data + recente), treino e teste - amostragem estratificada
target = "flFiel"
features = df_abt.columns.to_list()[3:]

df_val = df_abt[df_abt["dtRef"] == df_abt["dtRef"].max()].reset_index(drop=True)
df_train_test = df_abt[df_abt["dtRef"] < df_abt["dtRef"].max()].reset_index(drop=True)

df_X = df_train_test[features] # pd.Dataframe
df_y = df_train_test[target] # pd.Series

X_train, X_test, y_train, y_test = ms.train_test_split(
    df_X,
    df_y,
    random_state=42,
    test_size=0.25,
    stratify=df_y
)

print(f"Tamanho treino: {y_train.shape[0]} (Taxa target: {100*y_train.mean():.2f}%)")
print(f"Tamanho teste: {y_test.shape[0]} (Taxa target: {100*y_test.mean():.2f}%)")

#%% EXPLORE: Missing Values

s_nas = X_train.isna().mean()
s_nas = s_nas[s_nas > 0]
s_nas

#%% EXPLORE: Análise bivariada - Média de valores para Fiel e Não Fiel daqui 28 dias

categ_features = ["catLCAtual", "catLCD28"]
numeric_features = list(set(features) - set(categ_features))

X_train[numeric_features] = X_train[numeric_features].astype(float)
X_test[numeric_features] = X_test[numeric_features].astype(float)

df_train = X_train.copy()
df_train[target] = y_train.copy()
df_train[numeric_features] = df_train[numeric_features].astype(float)

# 1/0: ratio do quão diferentes os valores de mediana são nas targets
# aponta se a variavel apresenta diferença que possa ser usada pelo modelo
# 1/0 > 1 = SIM; 1/0 < 1 = SIM; 1/0 = 1 = NÃO
bivariada = df_train.groupby(target)[numeric_features].median().T
bivariada["1/0"] = ((bivariada[1] + (10**-6)) / (bivariada[0] + (10**-6)))
bivariada.sort_values(by="1/0", ascending = False)

#%% EXPLORE: Análise bivariada - % de Fiéis 28 dias depois em cada lifecycle atual
df_train.groupby("catLCAtual")[target].mean().T

#%% EXPLORE: Análise bivariada - % de Fiéis 28 dias depois em cada lifecycle de 28 dias atrás
df_train.groupby("catLCD28")[target].mean().T

#%% MODIFY: Excluindo features com pouca importância e preenchendo missings
to_remove = list(bivariada[bivariada["1/0"] == 1].index)
drop = selection.DropFeatures(to_remove)

s_nas = X_train.isna().mean()
inf_cols = ["mediaIntervaloAtivVida", "mediaIntervaloAtivD28", "diasUltimaAtiv"]
fill_0 = list(set(s_nas[s_nas > 0].index) - set(inf_cols + ["catLCD28"]))

imput_0 = imputation.ArbitraryNumberImputer(arbitrary_number=0, variables=fill_0)
imput_new = imputation.CategoricalImputer(fill_value="NAO-USUARIO", variables=["catLCD28"])
imput_1000 = imputation.ArbitraryNumberImputer(arbitrary_number=1000, variables=inf_cols)

# %% MODIFY: Encoding de variaveis categoricas
onehot = encoding.OneHotEncoder(variables=categ_features)

#%% MODELLING: primeiro treino em modelo

params = {
    "n_estimators": [100,200,400,500,1000],
    "min_samples_leaf": [10, 20, 30, 40, 50]
}

# model = tree.DecisionTreeClassifier(random_state=42, min_samples_leaf=40)
model = ensemble.RandomForestClassifier(random_state=42)

grid = ms.GridSearchCV(model,
                    param_grid=params,
                    cv=3,
                    scoring='roc_auc',
                    refit=True,
                    verbose=3,
                    n_jobs=3)

with mlflow.start_run() as r:
    mlflow.sklearn.autolog()

    pipe = pipeline.Pipeline(
        [("Removendo Feat.", drop),
        ("Imputação I", imput_0),
        ("Imputação II", imput_new),
        ("Imputação III", imput_1000),
        ("OneHotEncoding", onehot),
        ("Model", grid)]
    )
    pipe.fit(X_train, y_train)

    # ACCESS: primeira predição de modelo
    y_pred_train = pipe.predict(X_train)
    y_prob_train = pipe.predict_proba(X_train)

    acc_train = metrics.accuracy_score(y_train, y_pred_train)
    auc_train = metrics.roc_auc_score(y_train, y_prob_train[:, 1])

    print(f"Acurácia Treino: {acc_train}")
    print(f"AUC Treino: {auc_train}")

    y_pred_test = pipe.predict(X_test)
    y_prob_test = pipe.predict_proba(X_test)

    acc_test = metrics.accuracy_score(y_test, y_pred_test)
    auc_test = metrics.roc_auc_score(y_test, y_prob_test[:, 1])

    print(f"Acurácia Teste: {acc_test}")
    print(f"AUC Teste: {auc_test}")

    # ACCESS: validação
    X_val = df_val[features]
    y_val = df_val[target]

    y_pred_val = pipe.predict(X_val)
    y_prob_val = pipe.predict_proba(X_val)

    acc_val = metrics.accuracy_score(y_val, y_pred_val)
    auc_val = metrics.roc_auc_score(y_val, y_prob_val[:, 1])

    print(f"Acurácia Validação: {acc_val}")
    print(f"AUC Validação: {auc_val}")

    # ACCESS: Persistindo modelo e métricas
    mlflow.log_metrics({
        "acc_train":acc_train,
        "auc_train":auc_train,
        "acc_test":acc_test,
        "auc_test":auc_test,
        "acc_val":acc_val,
        "auc_val":auc_val,
    })

    roc_train = metrics.roc_curve(y_train, y_prob_train[:,1])
    roc_test = metrics.roc_curve(y_test, y_prob_test[:,1])
    roc_val =  metrics.roc_curve(y_val, y_prob_val[:,1])

    plt.plot(roc_train[0], roc_train[1])
    plt.plot(roc_test[0], roc_test[1])
    plt.plot(roc_val[0], roc_val[1])
    plt.legend([f"Treino: {auc_train:.4f}",
                f"Teste: {auc_test:.4f}",
                f"Validação: {auc_val:.4f}"])

    plt.plot([0,1], [0,1], '--', color='black')
    plt.grid(True)
    plt.title("Curva ROC")
    plt.savefig("../../img/curva_roc.png")
    
    mlflow.log_artifact('../../img/curva_roc.png')

# %%
path_model = "models:///fiel_predict/1"
loaded_model = mlflow.sklearn.load_model(path_model)

X_transform = drop.fit_transform(X_train)
X_transform = imput_0.fit_transform(X_transform)
X_transform = imput_new.fit_transform(X_transform)
X_transform = imput_1000.fit_transform(X_transform)
X_transform = onehot.fit_transform(X_transform)

feat_importance = pd.DataFrame(grid.best_estimator_.feature_importances_, index=X_transform.columns)
feat_importance.sort_values(by=[0], ascending=False, inplace=True)

fig, ax = plt.subplots(figsize=(10, 5))
sn.barplot(data=feat_importance, y=0, x=feat_importance.index, ax=ax, color="skyblue")
ax.set_ylim(0, feat_importance.max().iloc[0])
ax.set_ylabel("Importância")
ax.set_xlabel("Features")
ax.tick_params(axis='x', rotation=90)
ax.set_title("Importância das Features para o Modelo")
