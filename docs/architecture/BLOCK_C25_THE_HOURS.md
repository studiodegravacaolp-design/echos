# Bloco C25 — Os horários: primeiro passo jogável da investigação de Vardhelm

**Data:** 2026-10-01
**Tipo:** gameplay narrativo (Godot)
**Design de origem:** [`VARDHELM_INVESTIGATION_DESIGN.md`](../03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md) §4, §7, §8, §16 e decisões H1–H9 (C24.1)
**Checkpoint Git:** último checkpoint `3f98c26`; C25 = bloco principal **1/5**. Sem commit e sem push neste bloco.

## 1. Objetivo

Transformar os **horários** já plantados (a folha de Durn: "Horários anotados à mão, todos de hoje. O último está sublinhado duas vezes.") no primeiro passo jogável da investigação.

O jogador passa de "algo estranho aconteceu" para **"há alguma coisa nesses horários"**, e não para "agora eu sei o que está acontecendo".

## 2. Auditoria: o que já existia sobre os horários

| Fonte | Texto | Horários concretos? |
|---|---|---|
| Folha de Durn (C16) | "Horários anotados à mão, todos de hoje. O último está sublinhado duas vezes." | não |
| Quadro de manutenção (Forja) | "Anotações de reparo, horários e marcas de uso…" | não |
| Quadro de turnos (rua, C23) | "Os nomes mudam; os horários continuam os mesmos." | não |
| Durn (C12) | "Hoje ele [o painel] fez um barulho que eu nunca tinha ouvido." | não |
| Documentação (lore, cenários, C22–C24) | nenhuma hora definida | não |

Como não havia horários concretos, o C25 definiu um padrão simples, proposto como decisão de produção. **Atualização (C26): aprovado como cânone atual de Vardhelm por decisão humana** ([`BLOCK_C26_REREADS_PATTERN.md`](BLOCK_C26_REREADS_PATTERN.md) §1):

| Fonte | Horários | Natureza |
|---|---|---|
| Durn / folha (hoje) | **5h58 · 13h58 · 17h41** (o último sublinhado duas vezes; "quando você estava lá" = o Primeiro Eco) | observados: o painel fez barulho |
| Quadro de turnos | **troca de turno às 6h, 14h e 22h** | rotina operacional da cidade |

**O que o jogador percebe:** dois horários de Durn caem minutos antes da troca de turno; o sublinhado não cai em troca nenhuma. Ou seja, uma **ocorrência ligada à rotina** e **uma que fugiu dela**.

**O que NÃO é dito:**
- por que antes da troca;
- o que acontece na Forja 01 nesses minutos;
- o que o painel é;
- por que o último foi diferente.

Isso é material futuro do C26 (releituras: a marca apagada do quadro de manutenção) e do Galpão (H3, histórico operacional).

## 3. Fluxo

```
GANCHO (C14): "...Você ouviu, não ouviu?" / "Então não fui só eu." / "..."
   ↓ (fim desta conversa) quest "Os horários" começa
   ├── caminho "Sentir o quê?" (vardhelm_heard_echo): Durn no lugar de sempre
   │     objetivo: "Pergunte a Durn o que mais ele percebeu."
   │     Durn: "...Eu comecei a anotar." / "Hoje cedo, o painel. 5h58. Depois de novo, 13h58."
   │           "E o último... quando você estava lá. 17h41."
   │           [jogador: "Por que você anotou?" | "Isso quer dizer alguma coisa?"]
   │           "Não sei. Só sei que repetiu."
   └── caminho "Não senti nada." (vardhelm_felt_nothing): Durn sozinho onde o Eco aconteceu (C15)
         objetivo: "Leia a folha que Durn deixou no lugar de sempre."
         Durn: "...Você disse que não sentiu nada." / "Está na folha. Onde eu ficava."
         Folha (C16), agora lida: "A letra é de Durn. 5h58. 13h58. E, sublinhado duas vezes, 17h41."
   ↓ (os dois) objetivo: "Procure esses horários na rotina das fundições."
QUADRO DE TURNOS (rua, C23), lido com os horários:
   "Troca de turno às 6h, às 14h e às 22h. Dois horários de Durn caem minutos antes da troca. O sublinhado, não."
   ↓ "Os horários" concluída; começa "Nesses horários"
   objetivo: "Descubra o que acontece na Forja 01 nesses horários."   (C26+)
```

**Convergência:** os dois caminhos chegam à mesma informação, ao mesmo objetivo e às mesmas quests.

**Diferença preservada:**
- **Relacionamento:** num caminho Durn conta (confiança); no outro, só aponta a folha e depois fica em silêncio (distância).
- **Consequência:** `heard_echo` × `felt_nothing` continua no estado.
- **Conversa registrada:** `the_hours` × `the_notes`.
- **Lugar de Durn:** a posição dele continua derivada como no C15.

**Durn (H2):** econômico, sem conclusão, sem explicar. Depois de dar a pista, deixa de ser o motor: no primeiro caminho só repete "Não sei. Só sei que repetiu."; no outro, "...".

## 4. O que mudou no C23 (alteração pequena autorizada)

Só o **texto derivado** do quadro de turnos quando o jogador já conhece os horários (chave nova `observation.foundry_street_shift_board.hours`).

- Nada da geometria, da vida, das rotas ou das outras observações da rua mudou.
- O C23 continua **tecnicamente aprovado e com o teste humano/artístico pendente**.

## 5. Estados

| Elemento | Tipo | Fonte / restauração |
|---|---|---|
| Etapa "Os horários" (ativa/concluída; objetivos `hours`, `compare`) | **PERSISTENTE** | `QuestState` → GameState `quest.vardhelm.the_hours` → Save V2 |
| Etapa "Nesses horários" (ativa) | **PERSISTENTE** | `quest.vardhelm.those_hours` |
| Conversa dos horários concluída / pergunta escolhida | **PERSISTENTE** | `DialogueRuntimeState` → `dialogue.vardhelm.the_hours` / `the_notes` |
| Caminho da primeira escolha | **PERSISTENTE (já existia)** | flags `vardhelm_heard_echo` / `vardhelm_felt_nothing` (C15) |
| Folha e quadro de turnos vistos | **PERSISTENTE (já existia)** | `world.observations` |
| Objetivo exibido | **DERIVADO** | quests + caminho (`VardhelmHoursInvestigation.objective_key`) |
| Texto da folha e do quadro de turnos | **DERIVADO** | quests (`observation_text_key`) |
| Fala de Durn escolhida | **DERIVADO** | quests + caminho + conversas concluídas |
| Posição de Durn e disponibilidade da folha | **DERIVADO (C15/C16)** | sem mudança |
| Caixa de diálogo, janela de observação, dica | **TRANSITÓRIO** | C10/C18 |

**Nenhuma flag nova:**
- "conhece os horários" = objetivo `hours` concluído;
- "comparou" = quest `the_hours` concluída;
- "etapa" = quest ativa.

## 6. Progressão (H8)

Tudo avança por ação do jogador (conversa concluída, observação examinada) sobre o estado das quests.

- Nenhum timer, tempo real ou permanência na área.
- O Load nunca avança nada: as derivações só leem.

**Saves de antes do C25** (gancho já dito, etapa inexistente): a etapa abre quando o jogador volta a falar com Durn (ação do jogador, nunca no Load).

## 7. EventBus

Nenhum tipo de evento novo. Os eventos são os do pipeline de quests e diálogos:

| Momento | Eventos |
|---|---|
| Fim do gancho | `quest_started(the_hours)` |
| Horários conhecidos | `quest_progressed(the_hours, hours)` |
| Comparação | `quest_progressed(the_hours, compare)`, `quest_completed(the_hours)`, `quest_started(those_hours)` |

- Reexame da folha ou do quadro: `observation_discovered` suprimido (já descoberta).
- Conversa repetida: nada de quest.
- Load: só `game_loaded`.

## 8. Memória

**Nenhuma memória nova.** Os horários são **conhecimento** (registrado na quest), não impressão de lugar. O sistema de memória continua com o Primeiro Eco e os fragmentos das observações da Forja. Não houve composição de fragmentos.

## 9. O que não entrou

- Painel: continua fechado (H1).
- Galpão: não entrou (o objetivo não aponta o Galpão nem "registros").
- Elyra: sem aparição, silhueta, voz, carta ou assinatura.
- Combate.
- "Véu" e lore profundo.
- Ostrell.
- Refactor da janela 660×300.

## 10. Arquivos

**Criados:**
- Código: `godot/scripts/vardhelm/vardhelm_hours_investigation.gd` (`VardhelmHoursInvestigation`: leitura das quests + derivações; sem estado próprio).
- Dados:
  - `godot/data/quests/vardhelm_the_hours.json`, `vardhelm_those_hours.json`;
  - `godot/data/dialogue/vardhelm_the_hours.json`, `vardhelm_the_notes.json`.
- Testes: `godot/tests/save_v2/test_c25_the_hours.gd` (64 checks, no runner), `c25_the_hours_playtest.gd` (14 checks, renderizado e headless).

**Modificados:**
- `vardhelm_vertical_slice.gd`: conversa de Durn depois do gancho, fim de conversa, observações, objetivo, apresentação da conclusão.
- `vardhelm_runtime_state_provider.gd`: conversas e quests novas no contrato do Save V2.
- `id_catalog.gd`: 2 diálogos e 2 quests canônicos.
- `pt-BR.json`: 16 chaves.
- `state_test_runner.gd`: registro da suite.
- Expectativas atualizadas, por evolução deliberada:
  - `test_c14_first_sequence.gd`: depois do gancho, Durn passa aos horários em vez do silêncio;
  - `test_c23_foundry_street.gd`: a rua continua sem quest própria.

## 11. Testes

- `test_c25_the_hours.gd`: **64/64** (no runner, que ficou em 1796/1796). `c25_the_hours_playtest.gd`: **14/14** renderizado e headless.
- Regressões (renderizado e headless): C11 52/52, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17, C21 25/25, C21.1 24/24, C23 16/16; C9 66/66; cena principal com 0 erros; legados iguais ao baseline; `tsc` limpo.
- Detalhes no [`PROJECT_CHANGELOG.md`](../../PROJECT_CHANGELOG.md) (entrada C25).

## 12. Limitações

- Os horários (5h58, 13h58, 17h41; trocas 6h/14h/22h) foram propostos como decisão de produção. **Aprovados como cânone no C26.**
- A escolha do jogador na conversa dos horários fica registrada, mas não muda nenhuma fala posterior (agência leve, sem ramificação).
- A janela de observação continua 660×300 para textos curtos (refactor adiado, como pedido).
- O quadro de manutenção da Forja ainda não ganhou releitura (C26).

## 13. Checklist humano (não executado)

| # | Pergunta |
|---|---|
| A | Você entendeu por que voltou a falar com Durn? |
| B | A diferença entre as duas escolhas anteriores é perceptível? |
| C | Os horários parecem uma pista, e não uma resposta pronta? |
| D | A comparação com a rotina da cidade faz sentido? |
| E | Você entendeu o que investigar depois? |
| F | Algum diálogo parece explicar demais? |
| G | Save/Load mantém corretamente o ponto da investigação? |

**Roteiro sugerido:**
1. Jogar os dois caminhos ("Sentir o quê?" e "Não senti nada.") até o gancho.
2. Voltar a Durn e obter os horários.
3. Descer pela talha até a rua e examinar o quadro de turnos.
4. Salvar antes e depois de cada passo e carregar.
