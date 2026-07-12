# SYS-ATO4-FENDA — Mecânica de Ambiente — Ato 4 (Fenda Estática)
**Versão:** 1.0.0  
**Status:** Consolidado  
**Classificação:** Sistema de Ambiente — Late Game (Níveis 36–45)

---

## 1. Propósito

Este documento estabelece as regras operacionais estáveis do ambiente da Fenda Estática, vigentes durante o Ato 4 (O Sonho Compartilhado / Fenda Estática, Níveis 36–45). Nenhuma mecânica nova é introduzida; apenas consolidação das regras de revelação de interface, modificadores de zona e roteiro operacional que regem este bloco narrativo.

---

## 2. REGRA DE REVELAÇÃO — Descalcificação Ontológica

### 2.1 Descrição

Durante o Ato 4, as salvaguardas de interface que ocultavam as Linhagens Oculta do Herdeiro e dos Avatares (Kael e Elyra) são revogadas. As tags de Linhagem Oculta tornam-se visualmente expostas na interface de combate para o jogador.

### 2.2 Regra Operacional

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID**                   | REG-REVELACAO-ATO4                                                    |
| **Nome**                 | Descalcificação Ontológica                                            |
| **Gatilho**              | Início do Ato 4 (Bloco 30, Beat 1)                                    |
| **Efeito**               | Tags de Linhagem Oculta do Herdeiro e dos Avatares são expostas na interface de combate |
| **Alvos**                | Herdeiro (jogador), Kael, Elyra                                       |
| **Revogação**            | Regra Antivazamento R3 de tier (SYS-SALVAGUARDAS-R3) é suspensa permanentemente neste Ato |
| **Impacto na IA**        | Inimigos com IA "Leitura de Linhagem" passam a ter acesso visual às tags expostas |
| **Restrição Narrativa**  | O delta M de longo prazo (Linhagem Oculta) permanece cifrado até o evento do Bloco 30, Beat 4 |

### 2.3 Interface Visual

- As tags de Linhagem Oculta são exibidas como um selo cromático pulsante ao lado dos retratos de personagem na HUD de combate.
- A cor do selo reflete o eixo da Linhagem Oculta (Luz, Sombras, Neutro).
- Um tooltip descritivo é exibido ao passar o cursor sobre o selo, indicando o nome da Linhagem Oculta, sem revelar valores numéricos de delta M de longo prazo.

### 2.4 Justificativa Diegética

A Fenda Estática é um ambiente de sonho compartilhado onde as barreiras ontológicas entre os personagens se dissolvem. As Linhagens Oculta, antes abafadas pelas salvaguardas da Ordem do Silêncio, tornam-se visíveis como um reflexo da verdadeira natureza dos personagens exposta pelo colapso da realidade onírica.

---

## 3. ZONA DE ECO REVERSIVO (LOC-FEN-002)

### 3.1 Descrição

A Zona de Eco Reversivo é uma região da Fenda Estática onde o tempo de recarga de habilidades é espelhado entre eixos opostos, e o ponteiro da Balança sofre injeção de +15% de estafa reversa ao executar comandos.

### 3.2 Especificação Técnica

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID**                   | LOC-FEN-002                                                           |
| **Nome**                 | Zona de Eco Reversivo                                                 |
| **Tipo**                 | Modificador de Ambiente (Zona)                                        |
| **Localização**          | Fenda Estática — Câmaras do Espelho (Níveis 38–42)                    |
| **Ativo**                | Durante todo o Ato 4                                                  |

### 3.3 Modificadores de Ambiente

#### 3.3.1 Estafa Reversa

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **Efeito**               | Injeção de +15% de estafa reversa no ponteiro da Balança do jogador ao executar comandos |
| **Mecânica**             | Cada comando executado (habilidade, item, troca de personagem) adiciona 15% de estafa no sentido oposto ao último movimento do ponteiro |
| **Fórmula**              | `Estafa_Reversa = Comandos_Executados × 0.15 × Sentido_Oponto(Último_Movimento)` |
| **Reset**                | A estafa reversa zera ao sair da Zona de Eco Reversivo                |
| **Interação c/ Fratura** | Se o jogador entra em Fratura de Frenesi (+100), a estafa reversa é congelada até o fim da Fratura |

#### 3.3.2 Espelhamento de Cooldown

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **Efeito**               | Espelha o tempo de recarga (cooldown) de habilidades de eixos opostos |
| **Mecânica**             | Quando uma habilidade de um eixo (ex: Luz) é usada, a habilidade correspondente do eixo oposto (ex: Sombras) recebe o mesmo tempo de recarga |
| **Pares de Eixos Opostos** | Luz ↔ Sombras; Fogo ↔ Água; Terra ↔ Ar; Ordem ↔ Caos              |
| **Duração do Espelho**   | Cooldown espelhado = Cooldown original × 1.0 (100% do valor, sem ajuste) |
| **Exceção**              | Habilidades do Eixo Neutro não são afetadas pelo espelhamento         |
| **Notificação**          | Um ícone de corrente aparece sobre as habilidades afetadas pelo espelhamento |

### 3.4 Tabela de Modificadores — Zona de Eco Reversivo

| Modificador                        | Valor   | Alvo                     | Duração      |
|------------------------------------|---------|--------------------------|--------------|
| Estafa Reversa                     | +15%    | Ponteiro da Balança      | Por comando  |
| Espelhamento de Cooldown (Luz↔Sombras) | 100% | Habilidades dos eixos opostos | Até sair da zona |
| Espelhamento de Cooldown (Fogo↔Água)   | 100% | Habilidades dos eixos opostos | Até sair da zona |
| Espelhamento de Cooldown (Terra↔Ar)    | 100% | Habilidades dos eixos opostos | Até sair da zona |
| Espelhamento de Cooldown (Ordem↔Caos)  | 100% | Habilidades dos eixos opostos | Até sair da zona |

### 3.5 Estratégias de Jogador

- **Uso de Neutro:** Habilidades do Eixo Neutro não sofrem espelhamento, tornando-se a escolha ideal para evitar penalidades duplicadas de cooldown.
- **Fratura de Frenesi:** Congelar a estafa reversa ao atingir +100 de Fratura permite executar comandos sem penalidade durante a janela de Fratura.
- **Rotação Alternada:** Alternar entre eixos opostos pode ser usado para forçar cooldowns sincronizados em inimigos que copiam habilidades (ver SYS-BESTIARIO-A4.md — MON-ERR-031).

---

## 4. Roteiro Operacional — Fenda Estática

### 4.1 Fluxo de Progressão

| Etapa | Descrição                                                                 |
|-------|---------------------------------------------------------------------------|
| 1     | Entrada na Fenda Estática — Revelação das tags de Linhagem Oculta         |
| 2     | Exploração das Câmaras do Espelho — Ativação da Zona de Eco Reversivo     |
| 3     | Combate contra MON-ERR-031 (Reflexo Desgarrado) — Primeiro contato com IA de cópia |
| 4     | Combate contra MON-ERR-032 (Simulacro de Linhagem) — Inversão de polo     |
| 5     | Exploração do Núcleo da Fenda — Preparação para o Elite                   |
| 6     | Combate contra MON-ERR-ELITE-04 (Amálgama Ontológico) — Boss da Fenda     |
| 7     | Transição para o Bloco 30, Beat 4 — Evento narrativo de revelação         |

### 4.2 Salvaguardas de IA

| Salvaguarda          | Descrição                                                                 |
|----------------------|---------------------------------------------------------------------------|
| **Bloqueio de Delta M** | IA dos inimigos da Fenda (MON-ERR-032) é bloqueada contra leitura do Delta M de longo prazo (Linhagem Oculta), protegendo o mistério narrativo antes do evento do Bloco 30, Beat 4 |

---

## 5. Registro de Versionamento

| Versão | Data       | Autor | Descrição                                      |
|--------|------------|-------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Cline | Consolidação inicial da mecânica da Fenda Estática (Ato 4). |

---

## 6. Referências

- DOC-002_SYSTEMS.md — Documento mestre de sistemas
- DOC-005_NARRATIVE.md — Documento narrativo
- DOC-011_UI_UX.md — Documento de interface
- SYS-BALANCEAMENTO-ATOS.md — Balanço macroeconômico dos Atos
- SYS-BESTIARIO-A4.md — Bestiário do Ato 4
- SYS-MANUFATURA-ATO4.md — Manufatura do Ato 4
- GLOBAL_RULES.md — Regras globais do projeto
- DOCUMENT_MAP.md — Mapa de documentos