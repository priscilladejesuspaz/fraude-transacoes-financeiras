# Detecção de Fraude em Transações Financeiras com Cartão de Crédito

Projeto de análise de dados desenvolvido no Programa de Empregabilidade EBAC/Semantix, com foco no perfil de clientes da Semantix na vertical de fintechs, crédito e pagamentos (PicPay, Vindi, BoaVista SCPC).

O objetivo é identificar padrões de fraude em transações de cartão de crédito, combinando análise exploratória em SQL, um dashboard interativo e um modelo preditivo capaz de sinalizar transações suspeitas.

---

## 📂 Estrutura do repositório

```
docs/
  01_dissertacao_problema.md   # contexto do problema de fraude e por que ele importa
  02_fontes_de_dados.md        # documentação completa da fonte de dados
  03_relatorio_insights.md     # EDA + resultados da modelagem, consolidados
notebooks/
  02_modelagem_fraude.py       # script de modelagem (Regressão Logística + Random Forest)
sql/
  01_create_table.sql          # criação da tabela
  02_import_data.sql           # importação dos dados brutos
  03_data_quality.sql          # validação de qualidade dos dados
  04_analysis.sql              # consultas de análise exploratória
  05_views.sql                 # views usadas no dashboard
data/processed/                # agregados usados no dashboard (saída das queries SQL)
reports/
  figures/                     # gráficos de avaliação do modelo
  metricas_modelos.csv         # métricas consolidadas dos dois modelos
dashboard/
  fraude-transacoes-financeiras.pdf                # pdf do dashboard no Looker Studio
```

---

## 🎯 O problema

Fraude em cartão de crédito é rara em volume, mas cara em impacto, e é um problema clássico de classe desbalanceada, onde acurácia simples é enganosa. O contexto completo do problema, sua relevância para o setor financeiro e a motivação do projeto estão em [`docs/01_dissertacao_problema.md`](docs/01_dissertacao_problema.md).

## 📊 Fonte de dados

**Credit Card Transactions Fraud Detection Dataset**, por Kartik Shenoy ([Kaggle](https://www.kaggle.com/datasets/kartik2112/fraud-detection)), gerado com a ferramenta **Sparkov Data Generation** — dados sintéticos, sem informação real de clientes.

- Arquivo analisado: `fraudTest.csv` — 555.719 transações, 2.145 fraudes (0,386%)
- Colunas: `trans_date_trans_time`, `cc_num`, `merchant`, `category`, `amt`, dados demográficos do titular (`first`, `last`, `gender`, endereço, `job`, `dob`), geolocalização do cliente e do comerciante, `trans_num`, `unix_time` e o rótulo `is_fraud`

Documentação completa da fonte em [`docs/02_fontes_de_dados.md`](docs/02_fontes_de_dados.md).

## 🔍 Análise exploratória (SQL)

Qualidade dos dados validada (nulos, datas inválidas, integridade dos registros) e análises feitas diretamente em SQL (`sql/04_analysis.sql`):

- Comparação entre transações normais e fraudulentas
- Análise de fraude por período do dia
- Distribuição de transações por valor
- Identificação de categorias com maior taxa de fraude

**Principais achados:**
- Fraudes representam 0,386% das transações (2.145 de 555.719), mas concentram risco desproporcional
- 71% de taxa de fraude à noite e 69% na madrugada, contra 8% pela manhã e 6% à tarde — fraude é um evento noturno
- Categorias digitais lideram a taxa de fraude: `shopping_net` (1,21%), `misc_net` (0,98%), `grocery_pos` (0,92%)
- Transações de baixo valor dominam o volume total (R$ 35,6 milhões vs. R$ 2,95 milhões em alto valor)

## 🤖 Modelagem preditiva

Dois modelos treinados sobre os dados brutos (555.719 linhas, split estratificado 75/25), ambos com `class_weight='balanced'` para lidar com o desbalanceamento extremo:

| Modelo | AUC-ROC | AUC-PR | Recall (fraude) | Precisão (fraude) |
|---|---|---|---|---|
| Regressão Logística | 0,942 | 0,147 | 80,6% | 2,3% |
| **Random Forest** | **0,990** | **0,816** | **87,9%** | **36,0%** |

O Random Forest é o modelo recomendado: recall similar à Regressão Logística, mas com precisão muito superior, menos falsos positivos para revisar. `amt` (valor) e `hora` da transação são as variáveis mais relevantes, confirmando quantitativamente o padrão noturno identificado na EDA.

Script completo em [`notebooks/02_modelagem_fraude.py`](notebooks/02_modelagem_fraude.py). Análise completa, incluindo por que AUC-PR é a métrica certa aqui e as limitações do modelo, em [`docs/03_relatorio_insights.md`](docs/03_relatorio_insights.md).

## 🚨 Possíveis ações de negócio

- Monitoramento reforçado em horários críticos (22h–6h)
- Alertas automáticos para categorias digitais de maior incidência (`shopping_net`, `misc_net`)
- Modelo de scoring (Random Forest) como camada adicional de triagem antes da revisão manual
- Threshold de decisão ajustável conforme o apetite ao risco do time de fraude (ver curva Precisão-Recall)

## 📊 Dashboard interativo

Desenvolvido no Google Looker Studio a partir das views SQL (`sql/05_views.sql`):

🔗 https://datastudio.google.com/reporting/71a786d5-9c84-4154-9db4-0d58a8c8f274

## 📥 Importação dos dados

Dados carregados via `LOAD DATA LOCAL INFILE` no MySQL (`sql/02_import_data.sql`). O caminho do arquivo deve ser ajustado conforme o ambiente local.

## 🧠 Aprendizados

- Análise exploratória de dados e modelagem preditiva em conjunto, não isoladas
- Avaliação de modelos sob classe desbalanceada (AUC-PR, matriz de confusão, importância de variáveis — não acurácia)
- Manipulação e consulta com SQL
- Construção de dashboards
- Documentação de projeto de ponta a ponta, do problema de negócio à recomendação de modelo

## 📫 Contato

- LinkedIn: https://www.linkedin.com/in/priscilla-j-paz-844900394/
