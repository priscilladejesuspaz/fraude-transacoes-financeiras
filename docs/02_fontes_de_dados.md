# Fontes de Dados — Detecção de Fraude em Cartão de Crédito

## 1. Dataset

**Nome:** Credit Card Transactions Fraud Detection Dataset
**Autor:** Kartik Shenoy
**Plataforma:** Kaggle
**Link:** https://www.kaggle.com/datasets/kartik2112/fraud-detection

## 2. Como os dados foram gerados

O dataset é **sintético**, produzido com a ferramenta **Sparkov Data Generation** (desenvolvida por Brandon Harris), criada especificamente para gerar dados realistas de transações de cartão de crédito — incluindo transações legítimas e fraudulentas — a partir de perfis simulados de clientes e comerciantes, distribuídos geograficamente.

Isso tem uma implicação importante para o projeto: **não há dados reais de clientes envolvidos**, o que elimina questões de privacidade e LGPD, mas também significa que os padrões de fraude refletem as regras do simulador, não necessariamente todo o espectro de fraude real observado por uma instituição financeira.

## 3. Arquivos disponíveis e o que foi usado

O dataset original é dividido em dois arquivos (split temporal feito pelo próprio autor):

| Arquivo | Linhas aproximadas | Uso neste projeto |
|---|---|---|
| `fraudTrain.csv` | ~1,3 milhão | Não utilizado nesta etapa |
| `fraudTest.csv` | 555.719 | **Utilizado** — base de toda a EDA e da modelagem |

A escolha de trabalhar apenas com `fraudTest.csv` foi por tamanho/tempo de processamento; ele já é grande o suficiente (555.719 transações, 2.145 fraudes) para uma análise estatisticamente robusta e para treinar e validar os modelos preditivos.

## 4. Schema (colunas)

| Coluna | Descrição |
|---|---|
| `trans_date_trans_time` | Data e hora da transação |
| `cc_num` | Número (anonimizado/sintético) do cartão de crédito |
| `merchant` | Nome do comerciante |
| `category` | Categoria do comércio (ex.: `shopping_net`, `grocery_pos`, `misc_net`) |
| `amt` | Valor da transação |
| `first`, `last` | Nome e sobrenome (sintéticos) do titular do cartão |
| `gender` | Gênero do titular |
| `street`, `city`, `state`, `zip` | Endereço do titular |
| `lat`, `long` | Latitude/longitude do titular |
| `city_pop` | População da cidade do titular |
| `job` | Ocupação do titular |
| `dob` | Data de nascimento do titular |
| `trans_num` | Identificador único da transação |
| `unix_time` | Timestamp Unix da transação |
| `merch_lat`, `merch_long` | Latitude/longitude do comerciante |
| `is_fraud` | Variável-alvo: 1 = fraude, 0 = transação legítima |

## 5. Qualidade e tratamento

A validação de qualidade dos dados (nulos, datas inválidas, integridade de registros) foi feita em SQL, documentada em `sql/03_data_quality.sql`. Nenhuma inconsistência estrutural relevante foi encontrada que exigisse descarte de linhas.

Na etapa de modelagem (`notebooks/02_modelagem_fraude.py`), os dados brutos foram enriquecidos com variáveis derivadas — hora e dia da semana da transação, idade do titular calculada a partir da data de nascimento, período do dia, e distância aproximada entre a localização do titular e do comerciante — usadas como atributos preditivos além das colunas originais.

## 6. Licenciamento e uso

O dataset é público no Kaggle, disponibilizado para fins educacionais e de pesquisa. Por ser sintético, seu uso neste projeto (incluindo a publicação dos resultados e do dashboard) não envolve dados pessoais reais nem restrições de privacidade.
