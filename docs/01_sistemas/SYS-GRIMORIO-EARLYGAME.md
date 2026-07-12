# SYS-GRIMORIO-EARLYGAME — Grimório de Progressão — Atos 1 e 2
**Versão:** 1.0.0  
**Status:** Consolidado  
**Classificação:** Sistema de Habilidades — Early Game (Níveis 1–20)

---

## 1. Propósito

Este documento estabelece o registro oficial das habilidades iniciais do jogador (Níveis 1–10, Ato 1 — Vardhelm) e as diretrizes restritivas para a criação de habilidades intermediárias (Níveis 11–20, Ato 2 — Ostrell). Nenhuma mecânica nova é introduzida; apenas consolidação das regras operacionais estáveis vigentes.

---

## 2. Habilidades Iniciais — SYS-HABILIDADES-A1 (Níveis 1–10)

As habilidades abaixo são concedidas ao personagem durante o Ato 1, estabelecendo a base do kit de combate e a interação com a Balança (Momentum Gauge).

### 2.1 SKL-NEU-001 — Estocada Cinética

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | SKL-NEU-001                  |
| **Nome**            | Estocada Cinética            |
| **Tipo**            | Neutro (Físico)              |
| **Dano Base**       | Dano Físico Puro (Aço)       |
| **Custo**           | 10 de Stamina                |
| **Alcance**         | Corpo a corpo (1,5 m)        |
| **Tempo de Conjuração** | Instantâneo               |
| **Recarga (Cooldown)** | 1 turno (3 segundos)      |
| **Deslocamento na Balança (Delta_M)** | 0             |
| **Descrição Operacional** | Golpe linear perfurante desferido com arma branca. Sem alteração na Balança. |
| **Efeitos Visuais** | Trilha de aço fosco, sem emissão cromática. |
| **Regras**          | Nenhum deslocamento dinâmico na Balança. Dano reduzido por armadura física. |

### 2.2 SKL-PAT-001 — Ignição de Escape

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | SKL-PAT-001                  |
| **Nome**            | Ignição de Escape            |
| **Tipo**            | Patrono (Fogo)               |
| **Dano Base**       | Dano de Fogo                 |
| **Custo**           | 25 de Stamina / 10 de Mana   |
| **Alcance**         | 8 m (projétil dirigido)      |
| **Tempo de Conjuração** | 0,5 segundo                |
| **Recarga (Cooldown)** | 3 turnos (9 segundos)      |
| **Deslocamento na Balança (Delta_M)** | **+15** (fixo)  |
| **Descrição Operacional** | Dispara um jato concentrado de chamas que avança linearmente. Desloca a Balança para o polo positivo em +15 unidades. |
| **Efeitos Visuais** | Chamas âmbar opacas com rastros de calor distorcendo o ar (distorção termodinâmica física). Proibida a emissão de cor Ember ou Dourado Prismathico. |
| **Regras**          | Deslocamento fixo positivo obrigatório. Pode incendiar alvos em superfícies inflamáveis (chance 30%). |

### 2.3 SKL-MAT-001 — Drenagem de Condensação

| Campo               | Valor                        |
|---------------------|------------------------------|
| **ID**              | SKL-MAT-001                  |
| **Nome**            | Drenagem de Condensação      |
| **Tipo**            | Matriarcal (Luz)             |
| **Dano Base**       | Dano de Luz                  |
| **Custo**           | 30 de Mana                   |
| **Alcance**         | 12 m (raio alvo)             |
| **Tempo de Conjuração** | 1 segundo                  |
| **Recarga (Cooldown)** | 4 turnos (12 segundos)     |
| **Deslocamento na Balança (Delta_M)** | **-15** (fixo)  |
| **Descrição Operacional** | Drena a energia térmica do ambiente e do alvo, condensando-a em um ponto de vácuo frio. Desloca a Balança para o polo negativo em -15 unidades. |
| **Efeitos Visuais** | Vácuo acústico acromático — ondulação de ar frio descendente, ausência de som no impacto, partículas de estase branco-neutro. Proibida a emissão de cor Dourado Prismathico. |
| **Regras**          | Deslocamento fixo negativo obrigatório. Reduz velocidade do alvo em 10% por 2 turnos (efeito acumulável até 30%). |

---

## 3. Habilidades Intermediárias — Diretrizes do Ato 2 (Níveis 11–20)

As habilidades do Ato 2 (Ostrell) expandem o kit do jogador com o uso dos primeiros Catalisadores de Estafa. Abaixo, as restrições e comportamentos obrigatórios para criação e registro dessas habilidades.

### 3.1 Catalisadores de Estafa

O primeiro Catalisador de Estafa disponível ao jogador é a arma base **EQP-ARM-013**. Esta arma serve como canal para habilidades que consomem Estafa como recurso secundário.

**Regras de uso do Catalisador:**
- O Catalisador de Estafa não substitui a arma primária; ocupa o slot de ferramenta secundária.
- Habilidades canalizadas pelo Catalisador consomem Estafa (carga máxima: 100 unidades) em adição ao custo base.
- O acúmulo de Estafa é gerado por ações que desloquem a Balança além de |Delta_M| = 30 em qualquer direção.

### 3.2 Regra Antivazamento R3 de Linhagem

**Proibição absoluta — VFX e Cromática:**

É **rigorosamente proibida** a exibição de qualquer cor associada às marcas **Ember** (vermelho alaranjado intenso, hex #E25822 e adjacências) ou **Dourado Prismathico** (dourado metálico cintilante, hex #C9A96E e adjacências) em qualquer habilidade do tier intermediário (Níveis 11–20).

**Diretrizes de expressão visual obrigatórias:**

| Polo da Habilidade | Expressão Visual Permitida                                                                 |
|--------------------|--------------------------------------------------------------------------------------------|
| **Positivo** (Patrono / Fogo / Calor) | Reações termodinâmicas físicas **opacas**: vapor superaquecido, distorção de ar por calor, pressão atmosférica visível, brasa sem chama colorida. |
| **Negativo** (Matriarcal / Luz Fria / Gelo) | Estase ou **vácuo acústico acromático**: ondas de ar frio sem cor, cintilação neutra, silêncio de impacto, partículas branco-cinza. |

### 3.3 Comportamento Operacional das Habilidades do Ato 2

| Requisito                          | Especificação                                                                 |
|------------------------------------|-------------------------------------------------------------------------------|
| **Dano Base Mínimo**               | 1.4x o dano base das habilidades iniciais equivalentes.                      |
| **Deslocamento na Balança**        | Delta_M entre ±20 e ±35, variável conforme o tipo.                           |
| **Custo de Estafa (se canalizado)**| 15–25 unidades por uso.                                                      |
| **Recarga Mínima**                 | 5 turnos (15 segundos).                                                      |
| **Efeito Adicional Obrigatório**   | Cada habilidade deve aplicar um efeito de estado (Atordoamento, Lentidão, Hemorragia, ou Silêncio) por 1–2 turnos. |

---

## 4. Registro de Versionamento

| Versão | Data       | Autor | Descrição                                    |
|--------|------------|-------|----------------------------------------------|
| 1.0.0  | 2026-07-11 | Cline | Consolidação inicial do grimório early game. |

---

## 5. Referências

- DOC-002_SYSTEMS.md — Documento mestre de sistemas
- DOC-004_GAMEPLAY.md — Documento de gameplay
- GLOBAL_RULES.md — Regras globais do projeto
- DOCUMENT_MAP.md — Mapa de documentos
- DOC-001_WORLD_BIBLE.md — Bíblia de mundo