# SYS-BESTIARIO-A4 — Bestiário — Ato 4 (Fenda Estática)
**Versão:** 1.0.0  
**Status:** Consolidado  
**Classificação:** Sistema de Bestiário — Late Game (Níveis 36–45)

---

## 1. Propósito

Este documento consolida as fichas técnicas e padrões de Inteligência Artificial dos inimigos encontrados na Fenda Estática durante o Ato 4 (Níveis 36–45). Todos os inimigos documentados reagem estritamente ao medidor de curto prazo (SYS-RITMO-COMBATE-001), sem acesso ao delta M de longo prazo (Linhagem Oculta), conforme salvaguarda narrativa.

---

## 2. MON-ERR-031 — Reflexo Desgarrado

### 2.1 Ficha Técnica

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID**                   | MON-ERR-031                                                           |
| **Nome**                 | Reflexo Desgarrado                                                    |
| **Tipo**                 | Inimigo Comum (Errático)                                              |
| **Nível**                | 36–38                                                                 |
| **HP**                   | 850                                                                   |
| **R_Estafa**             | 1.0 (padrão)                                                          |
| **Experiência**          | 180 XP                                                                |
| **Drop**                 | 1–2x RES-ESPELHO-FRATURADO (45% chance), 1x Fibra de Névoa (20% chance) |
| **Localização**          | Fenda Estática — Câmaras do Espelho                                   |

### 2.2 Padrão de IA — "Cópia Imperfeita"

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID da IA**             | IA-COPIA-IMPERFEITA                                                   |
| **Nome**                 | Cópia Imperfeita                                                      |
| **Gatilho**              | A cada 3 ações do Herdeiro no Eixo Neutro                             |
| **Comportamento**        | Lê a pilha de ações do jogador e dispara réplicas automáticas de habilidades do Eixo Neutro usadas pelo Herdeiro |
| **Precisão da Cópia**    | 70% do dano original (imperfeita)                                     |
| **Limite de Cópia**      | Máximo de 2 réplicas simultâneas ativas                               |
| **Cooldown da IA**       | 8 segundos entre ativações                                            |
| **Reação ao Medidor**    | A IA é ativada exclusivamente pelo medidor de curto prazo da Balança — não lê delta M de longo prazo |

### 2.3 Vulnerabilidades e Resistências

| Tipo         | Modificador | Observação                                      |
|--------------|-------------|-------------------------------------------------|
| Fogo Puro    | ×2.0 (Vulnerável) | Dano dobrado — fraqueza primária               |
| Luz          | ×1.0 (Neutro)     | —                                               |
| Sombras      | ×1.0 (Neutro)     | —                                               |
| Terra        | ×0.5 (Resistente) | Dano reduzido pela metade                       |
| Água         | ×0.5 (Resistente) | Dano reduzido pela metade                       |
| Físico       | ×0.75 (Resistente Leve) | Dano reduzido em 25%                      |

### 2.4 Estratégia de Combate

- **Priorizar Fogo Puro:** A vulnerabilidade a Fogo Puro (×2.0) é a forma mais eficiente de eliminar o Reflexo Desgarrado rapidamente.
- **Evitar Eixo Neutro:** Usar habilidades do Eixo Neutro ativa a IA de cópia, gerando réplicas que aumentam a pressão sobre o jogador.
- **Gerenciamento de Réplicas:** Manter no máximo 2 réplicas ativas; eliminar réplicas existentes antes de usar novas habilidades Neutras.

---

## 3. MON-ERR-032 — Simulacro de Linhagem

### 3.1 Ficha Técnica

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID**                   | MON-ERR-032                                                           |
| **Nome**                 | Simulacro de Linhagem                                                 |
| **Tipo**                 | Inimigo Comum (Errático)                                              |
| **Nível**                | 38–41                                                                 |
| **HP**                   | 980                                                                   |
| **R_Estafa**             | 1.2                                                                   |
| **Experiência**          | 240 XP                                                                |
| **Drop**                 | 2–3x RES-ESPELHO-FRATURADO (55% chance), 1x ITM-CABO-DIAPASAO (15% chance) |
| **Localização**          | Fenda Estática — Câmaras do Espelho / Núcleo da Fenda                 |

### 3.2 Padrão de IA — "Inversão de Polo"

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID da IA**             | IA-INVERSAO-POLO                                                      |
| **Nome**                 | Inversão de Polo                                                      |
| **Gatilho**              | Quando o medidor de curto prazo da Balança do jogador atinge ≥ 60 em qualquer direção |
| **Comportamento**        | Lê o medidor de curto prazo da Balança do jogador e executa um ataque que empurra o ponteiro para o extremo oposto da sobrecarga |
| **Dano do Ataque**       | 120–150 (baseado no nível do jogador)                                 |
| **Força de Inversão**    | Empurra o ponteiro para o extremo oposto (ex: de +60 para -100, ou de -60 para +100) |
| **Cooldown da IA**       | 15 segundos entre ativações                                           |
| **Reação ao Medidor**    | Lê exclusivamente o medidor de curto prazo — não acessa delta M de longo prazo |

### 3.3 Salvaguarda de IA

| Salvaguarda              | Descrição                                                                 |
|--------------------------|---------------------------------------------------------------------------|
| **Bloqueio de Delta M**  | A IA "Inversão de Polo" é bloqueada contra a leitura do Delta M de longo prazo (Linhagem Oculta). Esta salvaguarda protege o mistério narrativo antes do evento do Bloco 30, Beat 4. |
| **Consequência de Violação** | Se uma fonte externa tentar expor o delta M de longo prazo à IA, a IA entra em estado de erro (loop infinito de leitura) e o inimigo fica atordoado por 3 segundos. |

### 3.4 Vulnerabilidades e Resistências

| Tipo         | Modificador | Observação                                      |
|--------------|-------------|-------------------------------------------------|
| Luz          | ×1.5 (Fraco)      | Dano aumentado em 50%                          |
| Sombras      | ×1.5 (Fraco)      | Dano aumentado em 50%                          |
| Fogo         | ×1.0 (Neutro)     | —                                               |
| Água         | ×1.0 (Neutro)     | —                                               |
| Terra        | ×0.5 (Resistente) | Dano reduzido pela metade                       |
| Ar           | ×0.5 (Resistente) | Dano reduzido pela metade                       |
| Físico       | ×0.5 (Resistente) | Dano reduzido pela metade                       |

### 3.5 Estratégia de Combate

- **Manter Balança Equilibrada:** Evitar que o medidor de curto prazo atinja ≥ 60 em qualquer direção para não ativar a IA de Inversão de Polo.
- **Uso de Habilidades de Luz/Sombras:** A fraqueza a Luz e Sombras (×1.5) permite dano aumentado sem ativar a IA (desde que a Balança permaneça abaixo de 60).
- **Exploração da Salvaguarda:** Se o jogador conseguir expor o delta M de longo prazo (após o Bloco 30, Beat 4), a IA entra em erro e o inimigo fica atordoado.

---

## 4. MON-ERR-ELITE-04 — Amálgama Ontológico (Elite)

### 4.1 Ficha Técnica

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID**                   | MON-ERR-ELITE-04                                                      |
| **Nome**                 | Amálgama Ontológico                                                   |
| **Tipo**                 | Inimigo Elite (Chefe de Zona)                                         |
| **Nível**                | 42–45                                                                 |
| **HP**                   | 6800                                                                  |
| **R_Estafa**             | 1.9                                                                   |
| **Experiência**          | 1200 XP                                                               |
| **Drop**                 | 5–8x RES-ESPELHO-FRATURADO (100% chance), 2–3x Fibra de Névoa (80% chance), 1x ITM-CABO-DIAPASAO (50% chance) |
| **Localização**          | Fenda Estática — Núcleo da Fenda                                      |

### 4.2 Padrão de IA — "Paradoxo Absoluto"

| Campo                    | Valor                                                                 |
|--------------------------|-----------------------------------------------------------------------|
| **ID da IA**             | IA-PARADOXO-ABSOLUTO                                                  |
| **Nome**                 | Paradoxo Absoluto                                                     |
| **Gatilho**              | Início do combate (fase 1)                                            |
| **Comportamento**        | Divide-se em 3 clones intangíveis com HP partilhado que executam o Grimório ativo do jogador em simultâneo |
| **HP Compartilhado**     | 6800 HP total — dividido igualmente entre os 3 clones (2267 HP cada) |
| **Intangibilidade**      | Clones são intangíveis (imunes a dano direto) até que a fraqueza sequencial seja aplicada |
| **Dano dos Clones**      | 60% do dano original das habilidades copiadas do Grimório do jogador |
| **Limite de Clones**     | Sempre 3 clones ativos; se um é destruído, os outros 2 absorvem seu HP proporcionalmente |
| **Reação ao Medidor**    | A IA reage exclusivamente ao medidor de curto prazo — não lê delta M de longo prazo |

### 4.3 Mecânica de Quebra de Ritmo — Fraquezas Sequenciais

Para quebrar a intangibilidade dos clones e causar dano real ao Amálgama Ontológico, o jogador deve aplicar dano dos eixos na sequência correta:

| Passo | Eixo        | Efeito                                                                 |
|-------|-------------|------------------------------------------------------------------------|
| 1     | Fogo        | Primeiro clone se torna vulnerável (intangibilidade removida por 8s)   |
| 2     | Luz         | Segundo clone se torna vulnerável (intangibilidade removida por 8s)    |
| 3     | Terra       | Terceiro clone se torna vulnerável (intangibilidade removida por 8s)   |
| 4     | (qualquer)  | Todos os clones vulneráveis simultaneamente — dano real aplicado ao HP compartilhado |

**Regras da Quebra de Ritmo:**

| Regra                          | Descrição                                                                 |
|--------------------------------|---------------------------------------------------------------------------|
| **Ordem Fixa**                 | A sequência deve ser Fogo ➔ Luz ➔ Terra. Não pode ser alterada.          |
| **Janela de Vulnerabilidade**  | Cada clone fica vulnerável por 8 segundos após receber o dano do eixo correto. |
| **Reset de Sequência**         | Se a janela de 8s expirar sem completar a sequência, todos os clones retornam à intangibilidade e a sequência é reiniciada. |
| **Penalidade de Erro**         | Se um eixo errado for usado, o clone que recebeu o dano errado ganha +20% de dano em seu próximo ataque. |
| **Dano Durante Vulnerabilidade** | Apenas dano do eixo correspondente ao clone vulnerável causa dano real ao HP compartilhado. |

### 4.4 Fases do Combate

| Fase | Condição                    | Comportamento da IA                                                    |
|------|-----------------------------|------------------------------------------------------------------------|
| 1    | HP ≥ 50% (3400+)            | Clones executam habilidades copiadas do Grimório do jogador em rotação |
| 2    | HP entre 25% e 50% (1700–3399) | Clones passam a executar 2 habilidades simultaneamente; velocidade de ataque +25% |
| 3    | HP < 25% (0–1699)           | Clones executam 3 habilidades simultaneamente; velocidade de ataque +50%; IA ignora cooldown de cópia |

### 4.5 Vulnerabilidades e Resistências

| Tipo         | Modificador | Observação                                      |
|--------------|-------------|-------------------------------------------------|
| Fogo         | ×1.0 (Neutro) | Usado como primeiro passo da quebra de ritmo   |
| Luz          | ×1.0 (Neutro) | Usado como segundo passo da quebra de ritmo    |
| Terra        | ×1.0 (Neutro) | Usado como terceiro passo da quebra de ritmo   |
| Água         | ×0.5 (Resistente) | Dano reduzido pela metade                     |
| Ar           | ×0.5 (Resistente) | Dano reduzido pela metade                     |
| Sombras      | ×0.5 (Resistente) | Dano reduzido pela metade                     |
| Neutro       | ×0.25 (Altamente Resistente) | Dano reduzido a 25%                    |
| Físico       | ×0.25 (Altamente Resistente) | Dano reduzido a 25%                    |

### 4.6 Estratégia de Combate

- **Preparação de Grimório:** Equipar habilidades de Fogo, Luz e Terra no Grimório ativo antes de enfrentar o Amálgama.
- **Gerenciamento de Janela:** Completar a sequência Fogo ➔ Luz ➔ Terra dentro da janela de 8 segundos para maximizar a janela de dano real.
- **Evitar Eixos Errados:** Usar Água, Ar, Sombras ou Neutro durante a fase de quebra de ritmo resulta em penalidade de +20% de dano nos clones.
- **Fase 3 Crítica:** Abaixo de 25% HP, a IA acelera drasticamente. Usar itens de redução de dano ou escudos para sobreviver ao bombardeio de 3 habilidades simultâneas.

---

## 5. Tabela de Drops — Fenda Estática

| Inimigo                    | Drop Comum                  | Chance | Drop Raro                   | Chance |
|----------------------------|-----------------------------|--------|-----------------------------|--------|
| MON-ERR-031 (Reflexo Desgarrado) | RES-ESPELHO-FRATURADO (1–2x) | 45%    | Fibra de Névoa (1x)         | 20%    |
| MON-ERR-032 (Simulacro de Linhagem) | RES-ESPELHO-FRATURADO (2–3x) | 55%    | ITM-CABO-DIAPASAO (1x)      | 15%    |
| MON-ERR-ELITE-04 (Amálgama Ontológico) | RES-ESPELHO-FRATURADO (5–8x) | 100%   | Fibra de Névoa (2–3x)       | 80%    |
| MON-ERR-ELITE-04 (Amálgama Ontológico) | ITM-CABO-DIAPASAO (1x)       | 50%    | —                           | —      |

---

## 6. Registro de Versionamento

| Versão | Data       | Autor | Descrição                                      |
|--------|------------|-------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Cline | Consolidação inicial do bestiário do Ato 4 (Fenda Estática). |

---

## 7. Referências

- DOC-002_SYSTEMS.md — Documento mestre de sistemas
- DOC-007_BESTIARY.md — Documento mestre do bestiário
- SYS-ATO4-FENDA.md — Mecânica de ambiente do Ato 4
- SYS-MANUFATURA-ATO4.md — Manufatura do Ato 4
- SYS-RITMO-COMBATE-001 — Sistema de ritmo de combate (medidor de curto prazo)
- GLOBAL_RULES.md — Regras globais do projeto
- DOCUMENT_MAP.md — Mapa de documentos