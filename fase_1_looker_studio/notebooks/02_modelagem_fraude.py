"""
02_modelagem_fraude.py

Modelagem preditiva de fraude em transacoes de cartao de credito.

Dataset: Credit Card Transactions Fraud Detection Dataset (Kartik Shenoy, Kaggle)
Gerado com Sparkov Data Generation (sintetico, nao confidencial).
Arquivo usado: fraudTest.csv (555.719 transacoes, 2.145 fraudes = 0,386%)

Classe extremamente desbalanceada -> metricas usadas sao AUC-ROC, AUC-PR (average
precision), matriz de confusao e importancia de variaveis. Acuracia simples e
enganosa aqui (um modelo que so chuta "nao fraude" já acerta 99,6%) e por isso
NAO e usada como metrica de decisao.

Modelos: Regressao Logistica (baseline interpretavel) e Random Forest
(nao-linear, captura interacoes), ambos com class_weight='balanced' para
compensar o desbalanceamento sem subamostrar os dados.

Saidas:
  - reports/figures/*.png  (curvas ROC, PR, matriz de confusao, importancia de variaveis)
  - reports/metricas_modelos.csv
  - reports/predicoes_amostra.csv (amostra de casos para inspecao)
"""

import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    roc_auc_score, roc_curve, average_precision_score, precision_recall_curve,
    confusion_matrix, classification_report
)

# ---------------------------------------------------------------------------
# Paleta consistente com o projeto (dataviz): azul = classe/serie principal,
# laranja = destaque/alerta (fraude). Sem eixo duplo, legendas sempre visiveis.
# ---------------------------------------------------------------------------
AZUL = "#2a78d6"
LARANJA = "#eb6834"
CINZA_GRADE = "#d9d9d9"
CINZA_TEXTO = "#4d4d4d"

plt.rcParams.update({
    "figure.facecolor": "white",
    "axes.facecolor": "white",
    "axes.edgecolor": CINZA_TEXTO,
    "axes.grid": True,
    "grid.color": CINZA_GRADE,
    "grid.linewidth": 0.6,
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.titleweight": "bold",
})

RAW_PATH = "data/raw_fraudTest.csv"
FIG_DIR = "reports/figures"
REPORT_DIR = "reports"
RANDOM_STATE = 42

# ---------------------------------------------------------------------------
# 1. Carga e engenharia de atributos
# ---------------------------------------------------------------------------
print("Carregando dados...")
df = pd.read_csv(RAW_PATH, index_col=0)
print(f"Linhas: {len(df):,} | Fraudes: {df['is_fraud'].sum():,} "
      f"({df['is_fraud'].mean()*100:.3f}%)")

df["trans_date_trans_time"] = pd.to_datetime(df["trans_date_trans_time"])
df["dob"] = pd.to_datetime(df["dob"])

df["hora"] = df["trans_date_trans_time"].dt.hour
df["dia_semana"] = df["trans_date_trans_time"].dt.dayofweek
df["idade"] = ((df["trans_date_trans_time"] - df["dob"]).dt.days / 365.25).astype(int)

# distancia (aprox, graus) entre cliente e o comerciante -> proxy de anomalia geografica
df["dist_cliente_comerciante"] = np.sqrt(
    (df["lat"] - df["merch_lat"]) ** 2 + (df["long"] - df["merch_long"]) ** 2
)

# periodo do dia, coerente com o insight do README (noite/madrugada concentram fraude)
def periodo_dia(h):
    if 0 <= h < 6:
        return "madrugada"
    if 6 <= h < 12:
        return "manha"
    if 12 <= h < 18:
        return "tarde"
    return "noite"

df["periodo_dia"] = df["hora"].apply(periodo_dia)

features_num = [
    "amt", "city_pop", "hora", "dia_semana", "idade", "dist_cliente_comerciante"
]
features_cat = ["category", "gender", "periodo_dia"]

X = pd.get_dummies(df[features_num + features_cat], columns=features_cat, drop_first=True)
y = df["is_fraud"]

# ---------------------------------------------------------------------------
# 2. Split treino/teste (estratificado, preserva a proporcao de fraude)
# ---------------------------------------------------------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.25, stratify=y, random_state=RANDOM_STATE
)
print(f"Treino: {len(X_train):,} | Teste: {len(X_test):,}")

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# ---------------------------------------------------------------------------
# 3. Modelos
# ---------------------------------------------------------------------------
resultados = {}

print("Treinando Regressao Logistica...")
logreg = LogisticRegression(class_weight="balanced", max_iter=1000, random_state=RANDOM_STATE)
logreg.fit(X_train_scaled, y_train)
proba_logreg = logreg.predict_proba(X_test_scaled)[:, 1]
pred_logreg = logreg.predict(X_test_scaled)

print("Treinando Random Forest...")
rf = RandomForestClassifier(
    n_estimators=300, max_depth=12, class_weight="balanced",
    random_state=RANDOM_STATE, n_jobs=-1
)
rf.fit(X_train, y_train)
proba_rf = rf.predict_proba(X_test)[:, 1]
pred_rf = rf.predict(X_test)

for nome, proba, pred in [
    ("Regressao Logistica", proba_logreg, pred_logreg),
    ("Random Forest", proba_rf, pred_rf),
]:
    auc_roc = roc_auc_score(y_test, proba)
    auc_pr = average_precision_score(y_test, proba)
    resultados[nome] = {"auc_roc": auc_roc, "auc_pr": auc_pr}
    print(f"\n{nome}")
    print(f"  AUC-ROC: {auc_roc:.4f}  |  AUC-PR: {auc_pr:.4f}")
    print(classification_report(y_test, pred, target_names=["nao_fraude", "fraude"], digits=3))

pd.DataFrame(resultados).T.to_csv(f"{REPORT_DIR}/metricas_modelos.csv")

# ---------------------------------------------------------------------------
# 4. Graficos de avaliacao
# ---------------------------------------------------------------------------

# 4.1 Curvas ROC
fig, ax = plt.subplots(figsize=(7, 6))
for nome, proba, cor in [
    ("Regressao Logistica", proba_logreg, AZUL),
    ("Random Forest", proba_rf, LARANJA),
]:
    fpr, tpr, _ = roc_curve(y_test, proba)
    auc = roc_auc_score(y_test, proba)
    ax.plot(fpr, tpr, color=cor, linewidth=2, label=f"{nome} (AUC = {auc:.3f})")
ax.plot([0, 1], [0, 1], color=CINZA_GRADE, linewidth=1.5, linestyle="--", label="Modelo aleatorio")
ax.set_xlabel("Taxa de Falsos Positivos")
ax.set_ylabel("Taxa de Verdadeiros Positivos")
ax.set_title("Curva ROC — Deteccao de Fraude")
ax.legend(loc="lower right", frameon=False)
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig(f"{FIG_DIR}/01_curva_roc.png", dpi=150)
plt.close(fig)

# 4.2 Curvas Precision-Recall (mais informativa que ROC para classe rara)
fig, ax = plt.subplots(figsize=(7, 6))
for nome, proba, cor in [
    ("Regressao Logistica", proba_logreg, AZUL),
    ("Random Forest", proba_rf, LARANJA),
]:
    prec, rec, _ = precision_recall_curve(y_test, proba)
    ap = average_precision_score(y_test, proba)
    ax.plot(rec, prec, color=cor, linewidth=2, label=f"{nome} (AP = {ap:.3f})")
baseline = y_test.mean()
ax.axhline(baseline, color=CINZA_GRADE, linewidth=1.5, linestyle="--",
           label=f"Linha de base ({baseline*100:.2f}% de fraude)")
ax.set_xlabel("Recall (sensibilidade)")
ax.set_ylabel("Precisao")
ax.set_title("Curva Precisao-Recall — Deteccao de Fraude")
ax.legend(loc="upper right", frameon=False)
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig(f"{FIG_DIR}/02_curva_precision_recall.png", dpi=150)
plt.close(fig)

# 4.3 Matrizes de confusao (lado a lado, mesma escala de leitura)
fig, axes = plt.subplots(1, 2, figsize=(11, 5))
for ax, nome, pred, cor in [
    (axes[0], "Regressao Logistica", pred_logreg, AZUL),
    (axes[1], "Random Forest", pred_rf, LARANJA),
]:
    cm = confusion_matrix(y_test, pred)
    im = ax.imshow(cm, cmap="Blues" if cor == AZUL else "Oranges")
    ax.set_xticks([0, 1]); ax.set_xticklabels(["Nao fraude", "Fraude"])
    ax.set_yticks([0, 1]); ax.set_yticklabels(["Nao fraude", "Fraude"])
    ax.set_xlabel("Previsto"); ax.set_ylabel("Real")
    ax.set_title(nome)
    for i in range(2):
        for j in range(2):
            ax.text(j, i, f"{cm[i, j]:,}", ha="center", va="center",
                     color="white" if cm[i, j] > cm.max() / 2 else CINZA_TEXTO,
                     fontsize=11, fontweight="bold")
fig.suptitle("Matriz de Confusao — Conjunto de Teste", fontweight="bold")
fig.tight_layout()
fig.savefig(f"{FIG_DIR}/03_matriz_confusao.png", dpi=150)
plt.close(fig)

# 4.4 Importancia de variaveis (Random Forest)
importancias = pd.Series(rf.feature_importances_, index=X.columns).sort_values(ascending=False).head(12)
fig, ax = plt.subplots(figsize=(8, 6))
cores = [LARANJA if i == 0 else AZUL for i in range(len(importancias))]
ax.barh(importancias.index[::-1], importancias.values[::-1], color=cores[::-1])
ax.set_xlabel("Importancia (Random Forest)")
ax.set_title("Variaveis Mais Relevantes para Detectar Fraude")
ax.spines[["top", "right"]].set_visible(False)
ax.xaxis.set_major_formatter(mticker.PercentFormatter(xmax=1))
fig.tight_layout()
fig.savefig(f"{FIG_DIR}/04_importancia_variaveis.png", dpi=150)
plt.close(fig)

# ---------------------------------------------------------------------------
# 5. Amostra de predicoes para inspecao / defesa do modelo
# ---------------------------------------------------------------------------
amostra = X_test.copy()
amostra["real"] = y_test.values
amostra["proba_fraude_rf"] = proba_rf
amostra["previsto_rf"] = pred_rf
amostra.sample(min(2000, len(amostra)), random_state=RANDOM_STATE).to_csv(
    f"{REPORT_DIR}/predicoes_amostra.csv", index=False
)

print("\nConcluido. Graficos em reports/figures/, metricas em reports/metricas_modelos.csv")