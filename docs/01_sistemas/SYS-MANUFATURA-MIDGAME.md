# SYS-MANUFATURA-MIDGAME — Manufatura e Equipamentos — Ato 3
**Versão:** 1.0.0  
**Status:** Consolidado  
**Classificação:** Sistema de Manufatura — Mid Game (Níveis 21–35)

---

## 1. Propósito

Este documento estabelece as especificações técnicas, custos de drops e propriedades dos equipamentos forjáveis e encontráveis no Ato 3 (Diretório de Brenhold). Nenhuma mecânica nova é introduzida; apenas consolidação das regras operacionais estáveis de forja e manufatura vigentes sob o regime de Vácuo Acústico e Asfixia Rúnica.

---

## 2. Equipamentos do Ato 3 — SYS-EQUIPAMENTOS-A3

Os equipamentos abaixo estão disponíveis para forja ou drop durante o Ato 3. Todos os custos de forja seguem a tabela de preços inflacionados do Diretório de Brenhold (ver SYS-BALANCEAMENTO-ATOS.md, Seção 4).

### 2.1 EQP-ARM-021 — Couraça de Abafamento

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | EQP-ARM-021                  |
| **Nome**            | Couraça de Abafamento        |
| **Tipo**            | Armadura (Peitoral)          |
| **Raridade**        | Incomum                      |
| **Nível Mínimo**    | 21                           |
| **Custo de Forja**  | 4x RES-LIGA-CHUMBO + 2x Marcas de Aço |
| **Atributo Base**   | +38 Armadura                 |
| **Propriedade Especial** | Reduz em 50% a duração de qualquer Silêncio recebido em combate. |
| **Descrição Operacional** | Peitoral forjado com liga de chumbo densa, projetado para abafar ressonâncias mágicas. A estrutura interna de amortecimento dissipa ondas de silêncio, reduzindo pela metade sua duração sobre o portador. |
| **Efeitos Visuais** | Placas de metal cinza-escuro com rebites de aço fosco. Superfície levemente texturizada, sem polimento. Sem emissão cromática. |
| **Regras de Forja** | O custo de forja em Marcas de Aço segue o preço inflacionado do Ato 3 (×1.40). O custo em RES-LIGA-CHUMBO segue o multiplicador de escassez K_Rar = 2.0x. |

### 2.2 EQP-ARM-022 — Marreta de Fricção

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | EQP-ARM-022                  |
| **Nome**            | Marreta de Fricção           |
| **Tipo**            | Arma (Martelo de duas mãos — Terra) |
| **Raridade**        | Incomum                      |
| **Nível Mínimo**    | 22                           |
| **Custo de Forja**  | 1x Cabo Mecânico + 3x Diapasão Metálico |
| **Atributo Base**   | Dano 94 (Terra)              |
| **Propriedade Especial** | Ignora 40% da armadura do alvo. |
| **Deslocamento na Balança (Delta_M)** | **0** (Neutro Puro — estável) |
| **Descrição Operacional** | Martelo de guerra pesado com cabeça de metal texturizado que gera fricção sônica ao impacto. A vibração ressonante atravessa armaduras, ignorando 40% da proteção física do alvo. A Balança permanece neutra (Delta_M = 0). |
| **Efeitos Visuais** | Cabeça do martelo em aço escovado com ranhuras de ressonância. Sem emissão cromática. Visual puramente termodinâmico mecânico e acromático. |
| **Regras de Forja** | O Cabo Mecânico e o Diapasão Metálico são componentes obtidos por drop em inimigos das Catacumbas Acústicas (LOC-BRE-001) e da Agulha de Ressonância (LOC-BRE-003). |

---

## 3. Componentes de Forja do Ato 3

### 3.1 RES-LIGA-CHUMBO — Liga de Chumbo

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | RES-LIGA-CHUMBO              |
| **Nome**            | Liga de Chumbo               |
| **Tipo**            | Recurso de Manufatura (Liga Especial) |
| **Raridade**        | Incomum                      |
| **Drop**            | Minerado nas profundezas do Diretório de Brenhold; drop de golems de pedra nas Catacumbas Acústicas (30% chance). |
| **Preço Base**      | 80 Marcas de Aço             |
| **Descrição**       | Liga metálica densa e maleável, resistente a ressonâncias mágicas. Utilizada na forja de equipamentos de abafamento. |

### 3.2 Cabo Mecânico

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | — (Componente genérico)      |
| **Nome**            | Cabo Mecânico                |
| **Tipo**            | Componente de Manufatura     |
| **Raridade**        | Comum                        |
| **Drop**            | Drop de inimigos mecânicos na Agulha de Ressonância (45% chance). |
| **Preço Base**      | 25 Marcas de Aço             |
| **Descrição**       | Cabo de fibra metálica trançada, utilizado como empunhadura em armas pesadas. |

### 3.3 Diapasão Metálico

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | — (Componente genérico)      |
| **Nome**            | Diapasão Metálico            |
| **Tipo**            | Componente de Manufatura     |
| **Raridade**        | Incomum                      |
| **Drop**            | Drop de sentinelas acústicas no Monastério do Primeiro Silêncio (25% chance). |
| **Preço Base**      | 40 Marcas de Aço             |
| **Descrição**       | Haste de metal ressonante, capaz de vibrar em frequências específicas. Utilizada na forja de armas de fricção sônica. |

---

## 4. Tabela de Custos de Forja — Ato 3

| Equipamento                  | Componente 1          | Qtd | Componente 2            | Qtd | Marcas de Aço | Custo Total (MGA) c/ Inflação |
|------------------------------|-----------------------|-----|-------------------------|-----|---------------|-------------------------------|
| EQP-ARM-021 (Couraça de Abafamento) | RES-LIGA-CHUMBO | 4x  | —                       | —   | 2x            | (4 × 224) + (2 × 2,80) = 901,60 → **902 MGA** |
| EQP-ARM-022 (Marreta de Fricção)    | Cabo Mecânico     | 1x  | Diapasão Metálico       | 3x  | —             | (1 × 25) + (3 × 40) = **145 MGA** |

> *Nota: O custo em Marcas de Aço para a Couraça de Abafamento considera o preço inflacionado do Ato 3 (×1.40) sobre o valor base de 2 Marcas de Aço, resultando em 2,80 MGA cada. O custo dos componentes RES-LIGA-CHUMBO considera o multiplicador de escassez K_Rar = 2.0x (preço base 80 MGA → 224 MGA cada com inflação + escassez). Os componentes Cabo Mecânico e Diapasão Metálico seguem o preço base sem inflação (obtidos por drop).*

---

## 5. Regras de Manufatura do Ato 3

| Regra                          | Descrição                                                                           |
|--------------------------------|-------------------------------------------------------------------------------------|
| **Forja Exclusiva**            | Equipamentos do Ato 3 só podem ser forjados em forjas do Diretório de Brenhold.     |
| **Componentes por Drop**       | Cabo Mecânico e Diapasão Metálico são obtidos exclusivamente por drop (não comercializáveis em lojas). |
| **Liga de Chumbo**             | RES-LIGA-CHUMBO pode ser comprada em ferreiros de Brenhold (sujeito a inflação e escassez) ou minerada. |
| **Delta_M Neutro**             | A Marreta de Fricção (EQP-ARM-022) possui Delta_M = 0 (Neutro Puro), não deslocando a Balança. |
| **Propriedade de Abafamento**  | A redução de 50% na duração de Silêncio da Couraça de Abafamento é cumulativa com outras fontes de resistência a Silêncio (máximo 75% de redução total). |

---

## 6. Registro de Versionamento

| Versão | Data       | Autor | Descrição                                      |
|--------|------------|-------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Cline | Consolidação inicial da manufatura do mid game. |

---

## 7. Referências

- DOC-002_SYSTEMS.md — Documento mestre de sistemas
- DOC-008_ITEMS_AND_CRAFTING.md — Tabela mestra de itens e refino
- SYS-BALANCEAMENTO-ATOS.md — Balanço macroeconômico dos Atos
- SYS-GRIMORIO-MIDGAME.md — Grimório do Mid Game (Ato 3)
- GLOBAL_RULES.md — Regras globais do projeto
- DOCUMENT_MAP.md — Mapa de documentos