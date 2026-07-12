# SYS-MANUFATURA-ATO4 — Manufatura e Equipamentos — Ato 4
**Versão:** 1.0.0  
**Status:** Consolidado  
**Classificação:** Sistema de Manufatura — Late Game (Níveis 36–45)

---

## 1. Propósito

Este documento estabelece as especificações técnicas, custos de drops e propriedades dos equipamentos forjáveis na Fenda Estática durante o Ato 4 (O Sonho Compartilhado / Fenda Estática, Níveis 36–45). Nenhuma mecânica nova é introduzida; apenas consolidação das regras operacionais estáveis de forja e manufatura vigentes sob o regime de Eco Reversivo e Descalcificação Ontológica.

---

## 2. Equipamentos do Ato 4 — SYS-EQUIPAMENTOS-A4

Os equipamentos abaixo estão disponíveis para forja durante o Ato 4. Todos utilizam recursos obtidos exclusivamente na Fenda Estática (RES-ESPELHO-FRATURADO, Fibra de Névoa, ITM-CABO-DIAPASAO). Os custos em Marcas de Aço seguem a tabela de preços do Ato 4 (ver SYS-BALANCEAMENTO-ATOS.md, Seção 5).

### 2.1 EQP-ARM-041 — Gume do Paradoxo (Espada de Aço Éreo)

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | EQP-ARM-041                  |
| **Nome**            | Gume do Paradoxo             |
| **Tipo**            | Arma (Espada de uma mão — Neutro) |
| **Raridade**        | Raro                         |
| **Nível Mínimo**    | 38                           |
| **Custo de Forja**  | 3x RES-ESPELHO-FRATURADO + 1x ITM-CABO-DIAPASAO + 600 Marcas de Aço |
| **Atributo Base**   | 112 de Dano Físico           |
| **Traço**           | "Cópia Síncrona"             |
| **Descrição do Traço** | Reduz em 25% o dano recebido por habilidades mimetizadas por inimigos do Ato 4. |
| **Delta_M**         | 0 (Neutro)                   |
| **Descrição Operacional** | Espada forjada com estilhaços de espelho da Fenda Estática, cujo gume reflete a imperfeição das cópias. O traço "Cópia Síncrona" reduz em 25% o dano recebido de habilidades copiadas por inimigos com IA de cópia (MON-ERR-031, MON-ERR-032, MON-ERR-ELITE-04). |
| **Efeitos Visuais** | Lâmina translúcida com fragmentos de espelho incrustados ao longo do gume. Emissão cromática azul-pálida ao balançar. Brilho intensifica quando ativa o traço "Cópia Síncrona". |
| **Regras de Forja** | O custo em Marcas de Aço segue o preço do Ato 4 (inflação base a definir em SYS-BALANCEAMENTO-ATOS.md, Seção 5). RES-ESPELHO-FRATURADO e ITM-CABO-DIAPASAO são obtidos exclusivamente por drop na Fenda Estática. |

### 2.2 EQP-ARM-042 — Manto do Véu Descalcificado

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | EQP-ARM-042                  |
| **Nome**            | Manto do Véu Descalcificado  |
| **Tipo**            | Armadura (Manto)             |
| **Raridade**        | Raro                         |
| **Nível Mínimo**    | 40                           |
| **Custo de Forja**  | 5x RES-ESPELHO-FRATURADO + 2x Fibra de Névoa + 800 Marcas de Aço |
| **Atributo Base**   | +24 Defesa Mística           |
| **Traço**           | "Janela Estendida"           |
| **Descrição do Traço** | Quando o jogador entra em Fratura de Frenesi (+100), estende a Janela Tática Útil de ação de 4 para 5 segundos cheios, neutralizando o atraso ambiental da Zona de Eco Reversivo. |
| **Delta_M**         | 0 (Neutro)                   |
| **Descrição Operacional** | Manto tecido com fibra de névoa e fragmentos de espelho, que manipula a percepção temporal do portador. Em Fratura de Frenesi, a Janela Tática Útil é estendida em 1 segundo adicional (4s → 5s), permitindo ao jogador executar comandos sem sofrer o atraso ambiental imposto pela Estafa Reversa da Zona de Eco Reversivo (LOC-FEN-002). |
| **Efeitos Visuais** | Manto longo e esvoaçante de tecido cinza-nebuloso, com fios prateados que cintilam como estilhaços de vidro. Quando ativa o traço "Janela Estendida", o contorno do manto emite uma aura cromática pulsante no espectro azul-violeta. |
| **Regras de Forja** | O custo em Marcas de Aço segue o preço do Ato 4 (inflação base a definir em SYS-BALANCEAMENTO-ATOS.md, Seção 5). RES-ESPELHO-FRATURADO e Fibra de Névoa são obtidos exclusivamente por drop na Fenda Estática (ver SYS-BESTIARIO-A4.md, Seção 5 — Tabela de Drops). |

---

## 3. Componentes de Forja do Ato 4

### 3.1 RES-ESPELHO-FRATURADO — Estilhaço de Espelho Fraturado

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | RES-ESPELHO-FRATURADO        |
| **Nome**            | Estilhaço de Espelho Fraturado |
| **Tipo**            | Recurso de Manufatura (Estilhaço Onírico) |
| **Raridade**        | Incomum                      |
| **Drop**            | Drop de inimigos da Fenda Estática (MON-ERR-031: 45% chance; MON-ERR-032: 55% chance; MON-ERR-ELITE-04: 100% chance). |
| **Preço Base**      | 120 Marcas de Aço            |
| **Descrição**       | Fragmento de espelho onírico da Fenda Estática, que reflete memórias fragmentadas de realidades paralelas. Utilizado na forja de equipamentos com traços de cópia e sincronia. |

### 3.2 Fibra de Névoa

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | — (Componente onírico)       |
| **Nome**            | Fibra de Névoa               |
| **Tipo**            | Componente de Manufatura (Fibra Onírica) |
| **Raridade**        | Incomum                      |
| **Drop**            | Drop de inimigos da Fenda Estática (MON-ERR-031: 20% chance; MON-ERR-ELITE-04: 80% chance). |
| **Preço Base**      | 90 Marcas de Aço             |
| **Descrição**       | Fibra tecida com névoa condensada da Fenda Estática, flexível e resistente a ataques mágicos. Utilizada na confecção de mantos e vestes oníricas. |

### 3.3 ITM-CABO-DIAPASAO — Cabo Diapasão

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | ITM-CABO-DIAPASAO            |
| **Nome**            | Cabo Diapasão                |
| **Tipo**            | Componente de Manufatura (Cabo Ressonante) |
| **Raridade**        | Raro                         |
| **Drop**            | Drop de MON-ERR-032 (15% chance) e MON-ERR-ELITE-04 (50% chance). |
| **Preço Base**      | 200 Marcas de Aço            |
| **Descrição**       | Cabo de empunhadura forjado com liga ressonante, que vibra em sincronia com o gume da arma. Utilizado na forja do Gume do Paradoxo (EQP-ARM-041). |

---

## 4. Tabela de Custos de Forja — Ato 4

| Equipamento                  | Componente 1                | Qtd | Componente 2               | Qtd | Componente 3             | Marcas de Aço |
|------------------------------|-----------------------------|-----|----------------------------|-----|--------------------------|---------------|
| EQP-ARM-041 (Gume do Paradoxo) | RES-ESPELHO-FRATURADO     | 3x  | ITM-CABO-DIAPASAO          | 1x  | —                        | 600           |
| EQP-ARM-042 (Manto do Véu Descalcificado) | RES-ESPELHO-FRATURADO | 5x  | Fibra de Névoa             | 2x  | —                        | 800           |

> *Nota: Os custos em Marcas de Aço para o Ato 4 serão ajustados conforme a inflação base definida em SYS-BALANCEAMENTO-ATOS.md, Seção 5 (a consolidar). Os componentes RES-ESPELHO-FRATURADO, Fibra de Névoa e ITM-CABO-DIAPASAO são obtidos exclusivamente por drop na Fenda Estática — não comercializáveis em lojas.*

---

## 5. Regras de Manufatura do Ato 4

| Regra                          | Descrição                                                                           |
|--------------------------------|-------------------------------------------------------------------------------------|
| **Forja Exclusiva**            | Equipamentos do Ato 4 só podem ser forjados em forjas oníricas da Fenda Estática.   |
| **Componentes por Drop**       | RES-ESPELHO-FRATURADO, Fibra de Névoa e ITM-CABO-DIAPASAO são obtidos exclusivamente por drop (não comercializáveis em lojas). |
| **Delta_M Neutro**             | Ambos os equipamentos do Ato 4 possuem Delta_M = 0 (Neutro), não deslocando a Balança. |
| **Traço "Cópia Síncrona"**     | A redução de 25% no dano de habilidades mimetizadas do Gume do Paradoxo é cumulativa com outras fontes de resistência a cópia (máximo 50% de redução total). |
| **Traço "Janela Estendida"**   | A extensão da Janela Tática Útil de 4s para 5s do Manto do Véu Descalcificado só é ativada em Fratura de Frenesi (+100). Fora da Fratura, o traço não tem efeito. |
| **Neutralização de Atraso**    | O Manto do Véu Descalcificado neutraliza o atraso ambiental da Estafa Reversa (LOC-FEN-002) exclusivamente durante a janela de 5s de Fratura de Frenesi. |

---

## 6. Registro de Versionamento

| Versão | Data       | Autor | Descrição                                      |
|--------|------------|-------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Cline | Consolidação inicial da manufatura do Ato 4 (Fenda Estática). |

---

## 7. Referências

- DOC-002_SYSTEMS.md — Documento mestre de sistemas
- DOC-008_ITEMS_AND_CRAFTING.md — Tabela mestra de itens e refino
- SYS-BALANCEAMENTO-ATOS.md — Balanço macroeconômico dos Atos
- SYS-ATO4-FENDA.md — Mecânica de ambiente do Ato 4
- SYS-BESTIARIO-A4.md — Bestiário do Ato 4
- SYS-MANUFATURA-MIDGAME.md — Manufatura do Mid Game (referência de formato)
- GLOBAL_RULES.md — Regras globais do projeto
- DOCUMENT_MAP.md — Mapa de documentos