# SYS-BALANCEAMENTO-ATOS — Balanço Macroeconômico e Inflação Paramétrica
**Versão:** 1.0.0  
**Status:** Consolidado  
**Classificação:** Sistema Econômico — Atos 1 e 2

---

## 1. Propósito

Este documento indexa o comportamento macroeconômico e a inflação paramétrica vigentes nos Atos 1 e 2 do Projeto Aetheris. Define as bases de preços, regras de transação e multiplicadores de escassez que regem a economia de Marcas de Aço (moeda global) durante o Early Game (Níveis 1–20).

---

## 2. Ato 1 — Vardhelm (Níveis 1–10)
**Regime Econômico:** Base Estabilizada

### 2.1 Características Gerais

| Parâmetro                     | Valor                                         |
|-------------------------------|-----------------------------------------------|
| **Região**                    | Vardhelm                                      |
| **Faixa de Níveis**           | 1–10                                          |
| **Regime**                    | Economia estabilizada / Mercado padrão        |
| **Inflação**                  | Nula (0%)                                     |
| **Multiplicador de Escassez** | K_Rar = 1.0x (nenhum agravante)              |

### 2.2 Regras de Preços

- Todos os preços de bens, equipamentos e serviços seguem o **preço padrão de mercado** definido na tabela mestra de itens (DOC-008_ITEMS_AND_CRAFTING.md).
- Não há acréscimo inflacionário sobre transações comerciais.
- O refino de componentes segue a tabela base de custos, sem taxas adicionais.
- Transações entre jogadores (se aplicável) também obedecem ao preço padrão de mercado, sem margem compulsória.

### 2.3 Tabela de Preços de Referência — Ato 1

| Categoria              | Item Exemplo                | Preço (Marcas de Aço) |
|------------------------|-----------------------------|------------------------|
| Arma Branca Inicial    | EQP-ARM-001 (Espada Curta) | 150                    |
| Armadura Leve          | EQP-ARMAD-001 (Túnica)     | 200                    |
| Poção de Vida Pequena  | CNS-POC-001                 | 25                     |
| Poção de Mana Pequena  | CNS-POC-002                 | 30                     |
| Reagente Neutro        | RGT-NEU-001 (Pó de Ferro)   | 10                     |
| Componente de Refino   | REF-COM-001 (Liga Fraca)    | 40                     |
| Estalagem (1 noite)    | —                           | 15                     |
| Refeição Simples       | —                           | 8                      |

---

## 3. Ato 2 — Ostrell (Níveis 11–20)
**Regime Econômico:** Inflação Quadrática Ativada

### 3.1 Características Gerais

| Parâmetro                     | Valor                                         |
|-------------------------------|-----------------------------------------------|
| **Região**                    | Ostrell                                       |
| **Faixa de Níveis**           | 11–20                                         |
| **Regime**                    | Inflação compulsória ativa                    |
| **Inflação Base**             | +20% em todas as transações com Marcas de Aço |
| **Multiplicador de Escassez** | K_Rar = 1.5x (reagentes neutros e componentes de refino) |

### 3.2 Regras de Preços — Inflação Compulsória

Toda transação comercial realizada em **Ostrell** sofre acréscimo compulsório de **+20%** sobre o preço base de mercado. Esta regra aplica-se a:

- Compra de equipamentos e armas
- Compra de consumíveis (poções, alimentos, reagentes)
- Serviços (estalagem, refino, encantamento)
- Reparos e manutenção de equipamentos

**Fórmula geral de preço no Ato 2:**

```
Preço_Final = Preço_Base × 1.20
```

### 3.3 Multiplicador de Escassez — Reagentes e Componentes

Para a compra de **reagentes neutros** (categoria RGT-NEU-*) e **componentes de refino** (categoria REF-COM-*), o multiplicador de escassez K_Rar = 1.5x é aplicado **cumulativamente** sobre o preço inflacionado.

**Fórmula para reagentes e componentes no Ato 2:**

```
Preço_Final = Preço_Base × 1.20 × 1.50
Preço_Final = Preço_Base × 1.80
```

### 3.4 Tabela de Preços Comparativa — Ato 1 vs Ato 2

| Item                         | Preço Base | Ato 1 (K_Rar 1.0x) | Ato 2 (+20% inflação) | Ato 2 c/ K_Rar 1.5x |
|------------------------------|------------|---------------------|------------------------|----------------------|
| EQP-ARM-001 (Espada Curta)  | 150        | 150                 | 180                    | —                    |
| EQP-ARMAD-001 (Túnica)      | 200        | 200                 | 240                    | —                    |
| CNS-POC-001 (Poção de Vida) | 25         | 25                  | 30                     | —                    |
| CNS-POC-002 (Poção de Mana) | 30         | 30                  | 36                     | —                    |
| RGT-NEU-001 (Pó de Ferro)   | 10         | 10                  | 12                     | **18**               |
| REF-COM-001 (Liga Fraca)    | 40         | 40                  | 48                     | **72**               |
| Estalagem (1 noite)         | 15         | 15                  | 18                     | —                    |
| Refeição Simples             | 8          | 8                   | 9,6 (10)               | —                    |

> *Nota: Valores de preço no Ato 2 com K_Rar 1.5x são arredondados para o inteiro mais próximo (regra de arredondamento comercial).*

### 3.5 Justificativa Diegética

A inflação em Ostrell reflete a escassez de recursos provocada pelo avanço da corrupção nas terras altas. As rotas comerciais de Vardhelm para Ostrell são mais longas e perigosas, encarecendo o transporte de suprimentos. Reagentes neutros e componentes de refino, em particular, tornam-se artigos de luxo devido à dificuldade de mineração e purificação na região.

---

## 4. Ato 3 — Diretório de Brenhold (Níveis 21–35)
**Regime Econômico:** Inflação Acumulada com Censura Rígida

### 4.1 Características Gerais

| Parâmetro                     | Valor                                         |
|-------------------------------|-----------------------------------------------|
| **Região**                    | Diretório de Brenhold                         |
| **Faixa de Níveis**           | 21–35                                         |
| **Regime**                    | Inflação acumulativa / Censura rígida da Ordem |
| **Inflação Base**             | +40% em relação ao Ato 1 em todas as transações com Marcas de Aço |
| **Multiplicador de Escassez** | K_Rar = 2.0x |

### 4.2 Regras de Preços — Inflação Acumulada

Toda transação comercial realizada no **Diretório de Brenhold** sofre acréscimo inflacionário de **+40%** sobre o preço base de mercado (Ato 1), devido à censura rígida da Ordem e ao isolamento econômico da região. Esta regra aplica-se a:

- Compra de equipamentos e armas
- Compra de consumíveis (poções, alimentos, reagentes)
- Serviços (estalagem, refino, encantamento)
- Reparos e manutenção de equipamentos

**Fórmula geral de preço no Ato 3:**

```
Preço_Final = Preço_Base × 1.40
```

### 4.3 Multiplicador de Escassez — Brenhold

Para a compra de **reagentes neutros** (categoria RGT-NEU-*), **componentes de refino** (categoria REF-COM-*), e **ligas especiais** (categoria RES-LIGA-*), o multiplicador de escassez K_Rar = 2.0x é aplicado **cumulativamente** sobre o preço inflacionado.

**Fórmula para reagentes, componentes e ligas no Ato 3:**

```
Preço_Final = Preço_Base × 1.40 × 2.00
Preço_Final = Preço_Base × 2.80
```

### 4.4 Tabela de Preços Comparativa — Ato 3

| Item                         | Preço Base | Ato 1 (K_Rar 1.0x) | Ato 3 (+40% inflação) | Ato 3 c/ K_Rar 2.0x |
|------------------------------|------------|---------------------|------------------------|----------------------|
| EQP-ARM-001 (Espada Curta)  | 150        | 150                 | 210                    | —                    |
| EQP-ARMAD-001 (Túnica)      | 200        | 200                 | 280                    | —                    |
| CNS-POC-001 (Poção de Vida) | 25         | 25                  | 35                     | —                    |
| CNS-POC-002 (Poção de Mana) | 30         | 30                  | 42                     | —                    |
| RGT-NEU-001 (Pó de Ferro)   | 10         | 10                  | 14                     | **28**               |
| REF-COM-001 (Liga Fraca)    | 40         | 40                  | 56                     | **112**              |
| RES-LIGA-CHUMBO (Liga de Chumbo) | 80    | 80                  | 112                    | **224**              |
| Estalagem (1 noite)         | 15         | 15                  | 21                     | —                    |
| Refeição Simples             | 8          | 8                   | 11,2 (11)              | —                    |

> *Nota: Valores de preço no Ato 3 com K_Rar 2.0x são arredondados para o inteiro mais próximo (regra de arredondamento comercial).*

### 4.5 Modificadores das Zonas de Brenhold

As três zonas do Diretório de Brenhold operam sob condições especiais de Vácuo Acústico e Asfixia Rúnica, impondo modificadores numéricos específicos:

#### 4.5.1 LOC-BRE-001 — Catacumbas Acústicas

| Campo               | Valor                                        |
|---------------------|----------------------------------------------|
| **ID**              | LOC-BRE-001                                  |
| **Nome**            | Catacumbas Acústicas                         |
| **Efeito**          | Silêncio de Canalização                      |
| **Modificador**     | +50% Cooldown em feitiços de Luz/Sombras     |
| **Descrição**       | O ambiente acusticamente selado das catacumbas interfere na canalização de magias de Luz e Sombras, aumentando o tempo de recarga em 50%. |
| **Impacto Econômico** | Poções e reagentes de Luz/Sombras têm seus preços inflacionados em +25% adicionais (cumulativo com a inflação base). |

#### 4.5.2 LOC-BRE-002 — Monastério do Primeiro Silêncio

| Campo               | Valor                                        |
|---------------------|----------------------------------------------|
| **ID**              | LOC-BRE-002                                  |
| **Nome**            | Monastério do Primeiro Silêncio              |
| **Efeito**          | Supressão Rúnica                             |
| **Modificador**     | -15% Eficácia de magias de Cura             |
| **Descrição**       | As runas de silêncio gravadas nas paredes do monastério suprimem a eficácia de toda magia de cura em 15%. |
| **Impacto Econômico** | Itens de cura (poções, bandagens) têm seu custo majorado em +30% (cumulativo com a inflação base). |

#### 4.5.3 LOC-BRE-003 — Agulha de Ressonância

| Campo               | Valor                                        |
|---------------------|----------------------------------------------|
| **ID**              | LOC-BRE-003                                  |
| **Nome**            | Agulha de Ressonância                        |
| **Efeito**          | Fricção de Vibração                          |
| **Modificador**     | +20% Dano em técnicas de Terra/Física        |
| **Descrição**       | A ressonância geológica da agulha amplifica técnicas de Terra e Físicas, aumentando seu dano em 20%. |
| **Impacto Econômico** | Equipamentos de Terra/Física têm custo de reparo reduzido em 15%. |

### 4.6 Justificativa Diegética

O Diretório de Brenhold é governado pela Ordem do Silêncio, que impõe censura rígida a toda forma de comércio e expressão mágica. O isolamento geográfico da região, combinado com o controle severo da Ordem sobre as rotas comerciais, resulta em inflação acumulada de +40% sobre os preços base. A escassez de recursos é agravada pelo ambiente hostil — o Vácuo Acústico e a Asfixia Rúnica tornam a mineração e o refino de materiais perigosos e ineficientes, elevando o multiplicador de escassez para K_Rar = 2.0x.

---

## 6. Regras Globais de Transação

| Regra                          | Descrição                                                                           |
|--------------------------------|-------------------------------------------------------------------------------------|
| **Moeda Única**                | Marcas de Aço (MGA) — moeda global em todos os Atos.                               |
| **Sem Troco Fracionado**       | Valores fracionados são arredondados para o inteiro mais próximo (comerciante sempre ganha no arredondamento). |
| **Revenda**                    | Itens revendidos a 50% do preço de compra (após inflação, se aplicável).            |
| **Acúmulo de Multiplicadores** | K_Rar é cumulativo com inflação, mas não acumula com outros multiplicadores de escassez (vigora o maior). |

---

## 7. Registro de Versionamento

| Versão | Data       | Autor | Descrição                                      |
|--------|------------|-------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Cline | Consolidação inicial do balanço econômico.    |
| 1.1.0  | 2026-07-11 | Cline | Adicionada Seção 4 — Ato 3 (Diretório de Brenhold). |

---

## 8. Referências

- DOC-002_SYSTEMS.md — Documento mestre de sistemas
- DOC-008_ITEMS_AND_CRAFTING.md — Tabela mestra de itens e refino
- DOC-004_GAMEPLAY.md — Documento de gameplay
- SYS-GRIMORIO-MIDGAME.md — Grimório do Mid Game (Ato 3)
- SYS-MANUFATURA-MIDGAME.md — Manufatura do Mid Game
- GLOBAL_RULES.md — Regras globais do projeto
- DOCUMENT_MAP.md — Mapa de documentos
