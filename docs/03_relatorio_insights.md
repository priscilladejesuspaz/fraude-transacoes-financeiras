# Relatório de Insights - Detecção de Fraude em Cartão de Crédito

**Projeto:** Detecção de Fraude em Transações Financeiras
**Programa:** Empregabilidade EBAC/Semantix
**Fonte de dados:** Credit Card Transactions Fraud Detection Dataset (Kartik Shenoy, Kaggle), gerado com Sparkov Data Generation - dados sintéticos, sem informação real de clientes
**Base analisada:** `fraudTest.csv` - 555.719 transações, 2.145 marcadas como fraude (0,386%)

Este documento consolida os dois pilares do projeto na Fase 1: a análise exploratória feita em SQL (etapa já concluída, refletida no dashboard e no README) e os resultados da modelagem preditiva (Regressão Logística e Random Forest), rodada sobre os dados brutos reais. A Fase 2 do projeto (dataset expandido, análise por dia da semana e evolução temporal, dashboard em Power BI) está documentada no README principal e ainda não teve a modelagem preditiva reexecutada sobre o dataset ampliado.

---

## 1. O que a EDA em SQL já mostrava

A análise exploratória, feita diretamente no banco (scripts em `fase_1_looker_studio/sql/`), estabeleceu o cenário:

- **Desbalanceamento extremo**: 553.574 transações normais contra 2.145 fraudulentas - a classe positiva é 0,39% da base. Qualquer modelo avaliado só por acurácia estaria mascarando esse desbalanceamento.
- **Concentração horária**: 71% das fraudes ocorrem à noite (taxa de 0,71% das transações naquele período) e 69% na madrugada (0,69%), contra 0,08% pela manhã e 0,06% à tarde. Fraude não é um evento uniforme ao longo do dia, é um evento noturno.
- **Categorias de risco**: `shopping_net` (1,21% de taxa de fraude) e `misc_net` (0,98%) lideram, seguidas por `grocery_pos` (0,92%) e `shopping_pos` (0,43%). Categorias digitais/online concentram o risco relativo, mesmo que o volume financeiro esteja em outro lugar.
- **Valor**: transações de baixo valor dominam o volume total (R$ 35,6 milhões) frente a transações de alto valor (R$ 2,95 milhões), volume não é sinônimo de risco.

## 2. O que a modelagem confirma e adiciona

Com os dados brutos linha a linha (555.719 registros), foram treinados dois modelos sobre um split estratificado 75/25 (416.789 treino / 138.930 teste), ambos com `class_weight='balanced'` para lidar com o desbalanceamento sem descartar dados via subamostragem.

| Modelo | AUC-ROC | AUC-PR (Average Precision) | Recall (fraude) | Precisão (fraude) |
|---|---|---|---|---|
| Regressão Logística | 0,942 | 0,147 | 80,6% | 2,3% |
| Random Forest | 0,990 | 0,816 | 87,9% | 36,0% |

**Por que AUC-PR importa mais que AUC-ROC aqui:** com 0,39% de positivos, a AUC-ROC fica artificialmente alta mesmo para um modelo fraco (a Regressão Logística tem 0,942 de AUC-ROC mas apenas 0,147 de AUC-PR, ou seja, na prática ela gera uma enxurrada de falsos positivos: para cada 100 alertas que dispara, só ~2 são fraude real). O Random Forest, com AUC-PR de 0,816, é a diferença entre um modelo que soa bem no papel e um que é operacionalmente utilizável.

**Matriz de confusão (Random Forest, conjunto de teste):**
- Fraudes corretamente identificadas: 471 de 536 (87,9% de recall)
- Fraudes não detectadas (falso negativo): 65
- Transações legítimas sinalizadas por engano (falso positivo): 837 de 138.394 (0,6%)

Esse equilíbrio é o que se busca em detecção de fraude: falso negativo tem custo direto (a fraude passa), falso positivo tem custo operacional (revisão manual) - 837 revisões desnecessárias em 138 mil transações é uma taxa de fricção administrável.

**Importância de variáveis (Random Forest)** confirma e refina o que a EDA sugeria:
1. **`amt` (valor da transação)** é de longe a variável mais relevante, cerca de metade do poder preditivo do modelo vem dela.
2. **`hora`** é a segunda mais relevante, validando quantitativamente o padrão noturno/madrugada já visto na EDA.
3. Variáveis de categoria (`shopping_net`, `grocery_pos`) e a distância geográfica cliente–comerciante entram como sinais secundários, mas não dominantes.

Isso é um refinamento importante do insight original: a EDA em SQL, ao segmentar por categoria, destacou `shopping_net`/`misc_net` como categorias de risco, mas quando o modelo vê todas as variáveis simultaneamente, valor e horário absorvem a maior parte do sinal preditivo, e a categoria passa a ser coadjuvante. Isso é uma resposta a se antecipar caso perguntem em entrevista: "os dois achados não se contradizem, a EDA descreve onde a fraude se concentra proporcionalmente, o modelo aponta o que mais separa fraude de não-fraude quando tudo é considerado junto."

## 3. Escolha do modelo final

**Random Forest é o modelo recomendado**, por três motivos:
- AUC-PR quase 6x maior que a Regressão Logística (0,816 vs 0,147), a métrica que mais importa em classe rara.
- Recall comparável (87,9% vs 80,6%) com precisão muito superior (36% vs 2,3%), menos ruído para quem for revisar os alertas.
- Captura não-linearidades e interações (ex.: valor alto **combinado com** horário de madrugada) que a Regressão Logística, sendo linear, não modela diretamente.

A Regressão Logística permanece útil como baseline interpretável, seus coeficientes são fáceis de explicar a um time de negócio, mas não é a escolha para produção.

## 4. Limitações e próximos passos

- O dataset é sintético (Sparkov), então padrões podem não capturar toda a complexidade de fraude real (ex.: fraude organizada, ataques coordenados).
- O modelo foi avaliado em split temporal aleatório, não em validação out-of-time; em produção, testar em um período posterior ao de treino seria o próximo passo natural.
- Um ajuste de threshold de decisão (hoje 0,5 por padrão) poderia trocar mais precisão por recall ou vice-versa, dependendo do apetite ao risco do negócio, vale explorar a curva precisão-recall (`fase_1_looker_studio/reports/figures/02_curva_precision_recall.png`) para escolher esse ponto de operação.
- **Escopo não coberto ainda:** a modelagem preditiva foi feita apenas sobre o dataset da Fase 1 (555.719 transações). O dataset expandido da Fase 2 (1.852.394 transações, período jan/2019–dez/2020) ainda não foi usado para retreinar ou validar os modelos — é o próximo passo natural de evolução do projeto.

## 5. Artefatos gerados

- `fase_1_looker_studio/reports/figures/01_curva_roc.png` — curva ROC comparando os dois modelos
- `fase_1_looker_studio/reports/figures/02_curva_precision_recall.png` — curva Precisão-Recall (a mais informativa para essa classe rara)
- `fase_1_looker_studio/reports/figures/03_matriz_confusao.png` — matrizes de confusão lado a lado
- `fase_1_looker_studio/reports/figures/04_importancia_variaveis.png` — importância de variáveis do Random Forest
- `fase_1_looker_studio/reports/metricas_modelos.csv` — métricas consolidadas
- `fase_1_looker_studio/reports/predicoes_amostra.csv` — amostra de 2.000 predições para inspeção manual
