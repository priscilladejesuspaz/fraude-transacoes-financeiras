# Dissertação sobre o Problema - Fraude em Cartão de Crédito

**Projeto:** Detecção de Fraude em Transações Financeiras
**Programa:** Empregabilidade EBAC/Semantix

## 1. O problema

Fraude em cartão de crédito é um dos problemas clássicos de análise de dados aplicada a negócios financeiros: um evento **raro em volume, mas caro em impacto**. Neste projeto, fraudes representam apenas 0,386% das transações analisadas (2.145 de 555.719), mas cada fraude não detectada gera prejuízo direto, para o emissor do cartão, para o comerciante ou para o próprio cliente, além de custo reputacional e regulatório para a instituição financeira.

Esse desbalanceamento extremo é o que torna o problema tecnicamente interessante e, ao mesmo tempo, arriscado de tratar de forma ingênua: um classificador que sempre prevê "não fraude" já acerta 99,6% dos casos, mas é inútil na prática. A escolha de métricas (AUC-PR em vez de acurácia), a estratégia de balanceamento de classes e a forma de comunicar o trade-off entre falsos positivos (fricção para o cliente legítimo) e falsos negativos (fraude que passa) são decisões de negócio tanto quanto técnicas.

## 2. Por que esse problema, e por que agora

A escolha desse projeto, entre os dois desenvolvidos no programa, foi deliberada: a vaga de Análise de Dados na Semantix tem como parte do portfólio de clientes empresas de fintech, crédito e meios de pagamento: PicPay, Vindi, BoaVista SCPC, entre outras. Detecção de fraude é um problema central e recorrente para esse tipo de cliente, o que torna este projeto mais diretamente relevante para a vaga do que uma análise puramente exploratória ou demográfica.

## 3. Perguntas que o projeto busca responder

- Qual a real proporção de fraude na base, e o que isso implica para a escolha de métricas de avaliação?
- Existe um padrão temporal na ocorrência de fraude (horário, período do dia)?
- Existem categorias de comércio com risco de fraude desproporcionalmente maior?
- É possível construir um modelo preditivo que sinalize transações suspeitas com um equilíbrio operacionalmente viável entre recall (fraudes capturadas) e precisão (alertas falsos)?
- Quais variáveis mais contribuem para essa previsão, e essas variáveis fazem sentido do ponto de vista de negócio?

## 4. Abordagem

O projeto segue um fluxo de ponta a ponta:

1. **Documentação da fonte de dados** (`docs/02_fontes_de_dados.md`) — entendimento de onde os dados vêm, como foram gerados e suas limitações.
2. **Análise exploratória em SQL** (`sql/`) — validação de qualidade dos dados e primeiras respostas descritivas sobre padrões de fraude.
3. **Dashboard interativo** (Looker Studio) — comunicação visual dos achados da EDA para um público não técnico.
4. **Modelagem preditiva** (`notebooks/02_modelagem_fraude.py`) — Regressão Logística como baseline interpretável e Random Forest como modelo de maior capacidade preditiva, ambos avaliados com métricas apropriadas para classe desbalanceada.
5. **Relatório de insights** (`docs/03_relatorio_insights.md`) — síntese consolidando EDA e modelagem, com recomendação de modelo e ações de negócio.

## 5. Escopo e limitações reconhecidas desde o início

O dataset usado (ver `docs/02_fontes_de_dados.md`) é **sintético**, gerado pela ferramenta Sparkov, não é dado real de clientes, o que remove qualquer preocupação de privacidade/LGPD, mas também significa que os padrões encontrados podem não capturar toda a complexidade de fraude no mundo real (ex.: fraude organizada, ataques coordenados, adaptação do fraudador ao longo do tempo). Essa limitação é tratada explicitamente no relatório de insights, e é um ponto que vale a pena antecipar numa eventual entrevista: o projeto não afirma ter resolvido detecção de fraude, mas demonstra a capacidade de estruturar o problema, escolher métricas corretas e defender as escolhas feitas.
