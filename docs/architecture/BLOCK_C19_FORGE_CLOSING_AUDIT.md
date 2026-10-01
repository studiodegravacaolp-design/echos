# Bloco C19 — Auditoria de fechamento da Forja de Vardhelm

**Natureza:** somente auditoria. Nenhum arquivo de jogo, dado, teste ou sistema foi alterado neste bloco.
**Data:** 2026-09-30.
**Contexto:** o usuário informou que C13–C18 foram validados em teste humano.

**Decisão: CENÁRIO FECHÁVEL.** "VARDHELM FORGE — CANDIDATO A FECHAMENTO"; ver §12.

## Classificação

| Área | Estado | Observação |
|---|---|---|
| Jogabilidade | ✅ CONCLUÍDO | fluxo completo nos dois caminhos; orientação por HUD e placa |
| Narrativa | ✅ CONCLUÍDO | começo, descoberta, consequência, investigação, conclusão e gancho |
| C15 | ✅ CONCLUÍDO | A e B coerentes; `felt_nothing` persiste |
| C16 | ✅ CONCLUÍDO | folha só no caminho B, examinável, persiste, sem duplicar |
| Mundo reativo | ✅ CONCLUÍDO | reage uma vez, persiste, não reemite no Load |
| Visual | ⚠️ PEQUENO AJUSTE | cápsula do jogador; fundo de neblina bege; câmera atravessa a máquina B no canto noroeste |
| Atmosfera | ✅ CONCLUÍDO | fumaça, vapor, poeira, luz quente da forja e fria do Eco; cidade construída ao fundo = 🔵 |
| NPCs | ✅ CONCLUÍDO | trabalhadores e Durn distintos, com rotina e colisão; placa DURN às vezes recortada (A) |
| Interação | ✅ CONCLUÍDO | E, prioridades, observações, Eco, painel, folha, Durn |
| C18 | ✅ CONCLUÍDO | 17/17 + 20/20; validado em teste humano |
| Física | ✅ CONCLUÍDO | 11/11; rotas, entrada sul e alvos alcançáveis |
| Save/Load | ✅ CONCLUÍDO | 11 ciclos, 0 diferenças, posição e rotação |
| EventBus | ✅ CONCLUÍDO | ordem estável, sem duplicação nem reemissão |
| Performance | ✅ CONCLUÍDO | cerca de 17 ms, limitado pelo vsync, na tomada |
| Arquitetura | ✅ CONCLUÍDO | genérico onde precisa; generalizar AmbientLife e dividir o slice = 🔵 |

## 1. Método

- **Bateria completa guardada**, em cópia de trabalho com os saves reais do usuário protegidos:
  - runner;
  - sonda A0;
  - cena principal;
  - legados;
  - playtests C11, C15, C16, C17.3 e C18 (renderizados e headless);
  - C9 renderizado;
  - `tsc`.
- **Sonda de auditoria própria** (fora do projeto, descartável), com 41 checks:
  - joga os **dois caminhos do C15 até o gancho**;
  - em cada etapa faz **Save → mover e girar → Load** e compara o GameState projetado inteiro, mais o que o jogador percebe (objetivo, Eco, mundo, Durn, folha, volumes, contagem de nós);
  - registra a ordem e a contagem dos eventos.
- **Capturas pela câmera real do jogador** (15, em [`c19_audit/`](c19_audit/)): antes do Eco e depois do Eco no caminho B.
- **Medição de quadro renderizada na tomada:** 1500 quadros em 5 pontos, duas execuções.
- **Leitura de código** para arquitetura, placeholders e texto visível.

## 2. Jogabilidade e fluxo

- A sonda percorreu ENTRADA → DURN → ESCOLHA → ECO → CONSEQUÊNCIA → VARDHELM REAGE → RETORNO A DURN → PAINEL → SILÊNCIO → GANCHO, nos dois caminhos, sem falha.
- **Onde o jogador está:**
  - HUD "VARDHELM" + objetivo "Fale com Durn…";
  - placa de ferro "FORJA 01" no portão;
  - controles na linha de status.
- **Circulação:** o C17.3 caminha até Eco, painel e lugar da folha. O C15 e o C16 usam as rotas reais. O C17 garante a abertura sul real e colisão igual à geometria.

## 3. C15 — dois caminhos

| | Caminho A "Sentir o quê?" | Caminho B "Não senti nada." |
|---|---|---|
| Fala inicial | 3 falas, termina em "procure por mim" | 2 falas, termina em "procure por mim" |
| Após o Eco | Durn fica no lugar | `consequence.vardhelm.felt_nothing`; Durn vai até onde o Eco aconteceu |
| Folha (C16) | indisponível; o E continua sendo para Durn | disponível, examinável, texto do catálogo (`observation.durn_notes.text`) |
| Resto da sequência | painel, silêncio e gancho idênticos | idênticos |
| Save/Load | 0 diferenças em 5 etapas | 0 diferenças em 6 etapas (inclui a folha examinada) |

## 4. C16

- A folha só existe no caminho B e depois do Eco. O C16 playtest cobre ainda um save **antes** da escolha: Load → sem folha.
- A folha fica no lugar de sempre de Durn e é examinável.
- Persistência: Save/Load, Load repetido e contagem de nós (`notes_nodes == 1`, `durns == 1`) sem duplicação.

## 5. Narrativa (avaliação, sem reescrita)

| Pergunta | Resposta |
|---|---|
| A. Começo claro | Sim: Durn como primeiro alvo, objetivo explícito. |
| B. Descoberta | Sim: o Eco só abre depois de Durn. |
| C. Consequência | Sim: memória, quest, mundo e, no caminho B, Durn se desloca. |
| D. Reação do mundo | Sim: luz fria no painel, trabalhador fora da rotina, máquinas mais baixas (C13). |
| E. Investigação | Sim: painel selado, apontado por Durn. |
| F. Conclusão local | Sim: silêncio de cerca de 8,4 s depois do painel. |
| G. Gancho | Sim: "...Você ouviu, não ouviu?" / "Então não fui só eu." / "...", e depois só "...". |
| H. Escolha perceptível | Sim no caminho B (Durn ausente, folha). O caminho A é o comportamento de base. |
| I. Não explica demais | Sim: os testes do C12 e C14 proíbem termos de lore nas falas. |
| J. Durn coerente | Sim: as falas pós-Eco são as mesmas nos dois caminhos e seguem as regras do C12. |
| K. Silêncio como encerramento | Funciona (transitório; nunca reaplicado pelo Load). |
| L. Gancho | Continua funcionando nos dois caminhos. |

## 6. Mundo reativo (C13)

- Antes do Eco: trabalhadores em rotina, máquinas em volume normal, luz padrão.
- No Eco: a reação acontece **uma vez**:
  - `echo_triggered` 1 no caminho inteiro, com 10 a 12 Loads;
  - `world_state_changed` 1 no caminho A e 2 no caminho B (o segundo é a consequência do C15).
- Depois do Eco: luz fria sobre o painel (captura 12), trabalhador em `after_echo` e redução sonora em volume estável (−6 / −16 / −30 dB).
- O Load mantém o estado e não reemite a reação: no Load o único evento é `game_loaded`.

## 7. Visual (câmera real do jogador) e placeholders

| Elemento | Onde | Classe |
|---|---|---|
| **Jogador é uma cápsula lisa** ao lado de trabalhadores e Durn humanoides | todas as capturas | **B**: pequeno problema visual; não impede nada |
| Fora da baia, chão bege plano e liso (neblina) em vez de cidade legível | 02, 06, 09 | **B** |
| Com o jogador no canto noroeste (quadro de manutenção), a carcaça da máquina B atravessa a câmera e vira facetas pretas no canto inferior direito | 07 | **B**: posição de canto, fora das rotas principais |
| Placa "DURN" às vezes recortada pela geometria ("DURI") | 13, 14 | A |
| Eco usado vira disco ciano chapado, cortado por uma viga | 13, 14 | A: exceção narrativa ciano (decisão C17) |
| HUD com linha de controles e "✓ Primeiro Eco registrado" persistente | todas | A: coerente com um vertical slice |
| Status "O caminho está aberto. Encontre o fenômeno no setor industrial." cita um setor cuja placa saiu no C17.2 | texto | A |
| Rótulos flutuantes de estações, props, observações e trabalhadores | dados | A: existem, mas desligados por `presentation.show_* = false` |
| `_create_zone_sign` em `vardhelm_set_dressing.gd` | código | A: função morta, sem efeito na tela |

- Nenhum elemento na classe **C** (impede o fechamento).
- Arquitetura, densidade, identidade, atmosfera, personagens e narrativa visual correspondem às decisões do C17 a C17.3, validadas por humano.

## 8. Interação, C18 e física

- **E e prioridades:** Durn tem prioridade no canto do quadro (captura 07); observações, Eco, painel e folha são cobertos por C11, C15, C16 e C17.3.
- **C18:** 17/17 no playtest e 20/20 no runner:
  - some cerca de 0,9 s após sair;
  - retorno rápido sem piscar;
  - borda sem piscar;
  - conversa nunca fechada pela distância.
- **Artefato das capturas de auditoria:** a dica ainda aparece em algumas capturas logo depois de um teletransporte (01, 02, 08). A sonda teletransporta e captura 0,42 s depois, dentro da espera de 0,75 s. Não é defeito.
- **Física:** C17.3 11/11:
  - o jogador não atravessa trabalhadores e os contorna;
  - as rotas seguem com o jogador no caminho;
  - Eco, painel e folha são alcançáveis;
  - o E não escolhe trabalhadores.

## 9. Save/Load e EventBus

- **Resultado geral:** 11 ciclos Save → mover e girar → Load nos dois caminhos, cada um com Load repetido:
  - **0 diferenças** no GameState projetado e no estado percebido;
  - posição e rotação restauradas;
  - o único evento emitido no Load é `game_loaded`;
  - nenhuma duplicação de memória, quest, Durn, folha, trabalhadores ou dica.
- **Observação (não é defeito):** salvar **durante** o silêncio do C14 e carregar devolve o som no volume estável.
  - O silêncio é transitório por decisão do C14 ("nunca reaplicado pelo Load").
  - A primeira execução da sonda acusou isso porque salvou no meio da rampa. Depois do silêncio, 0 diferenças.
- **Ordem dos eventos:**
  - no Eco: `consequence_applied → world_state_changed → quest_progressed → quest_completed → echo_triggered → memory_recovered`;
  - do painel ao gancho: `observation_discovered → quest_progressed → quest_completed → memory_recovered → dialogue_started/completed ×2`.
- **Totais no caminho inteiro:** `echo_triggered` 1, `quest_started` 2, `quest_completed` 2, `consequence_applied` 2.
- A cadeia do C15 (escolha → consequência → mundo) e a do C16 (… → possibilidade) são afirmadas nos runners.
- UI transitória (dica, silêncio, painel de observação) fora do Save V2 e do GameState: sem referência em `scripts/state` e `scripts/save_v2`.

## 10. Desempenho

**Condições:**
- Intel UHD Graphics, Forward+, janela 1152×648;
- vsync ligado, `max_fps` 0;
- **na tomada** (BatteryStatus 2, 97%), plano de energia "Equilibrado".

| Execução | Média | Mín | Máx | Mediana | p99 |
|---|---|---|---|---|---|
| 1 (válida) | 17,37 ms | 14,92 | 22,33 | 17,18 | 20,85 |
| 2 (válida) | 16,87 ms | 8,87 | 27,52 | 16,77 | 19,41 |

- Na execução 2, os valores por ponto variaram de 16,56 a 17,47 ms de média, antes e depois do Eco.
- Comparação: C17.3 16,35 ms. O C18 na bateria deu cerca de 24,8 ms.
- **Resultado:** limitado pelo vsync (cerca de 60 fps), igual ao C17.3 dentro do ruído. Os máximos isolados (27 ms) são quadros únicos, logo após teletransporte.
- **Execução descartada:** uma primeira execução travou depois das medições pré-Eco. Os quadros não estavam limitados (6,9 ms), sinal de janela sem foco ou ocluída. Não se repetiu em duas execuções seguidas.

## 11. Código e arquitetura

- **LevelBuilder e LevelValidator:** genéricos ("não conhece Vardhelm"); só o caminho padrão exportado aponta para o JSON da forja.
- **AmbientLife:** dirigido por dados (estações, trabalhadores, observações, `after_echo`, `worker_body`, `durn_alone`). Ainda se chama `VardhelmAmbientLife` e conhece os IDs de estado `echo_awakened` e `sealed_panel_remembered`: reutilizável com generalização (🔵).
- **ContextualWindowLifecycle:** genérico (sem Vardhelm, sem `_process`).
- **Separação de estado:** Save V2 separado do legado (`SaveService` nunca chamado nas sondas). GameState em sombra, sem estado transitório. Nenhum Autoload.
- **`vardhelm_vertical_slice.gd` (982 linhas):** é o orquestrador do slice; concentra HUD, diálogo, Save/Load e C12–C18. Funciona e está coberto; dividir fica para quando houver o segundo cenário (🔵).

## 12. VARDHELM FORGE — CANDIDATO A FECHAMENTO

**Validado:**
- sequência completa nos dois caminhos;
- escolha com consequência perceptível;
- possibilidade futura (folha);
- mundo reativo único e persistente;
- encerramento em silêncio e gancho;
- Save/Load V2 em cada etapa, com posição e rotação;
- EventBus sem duplicação nem reemissão;
- ciclo da dica contextual;
- colisão corporal;
- cenário com identidade industrial;
- desempenho estável.

**Deliberadamente provisório:**
- cápsula do jogador;
- silhuetas humanoides de primitivas;
- materiais de cor e shader simples;
- fundo de neblina no lugar de uma cidade construída;
- HUD de protótipo com linha de controles;
- três loops de áudio ambiente provisórios.

**Futuro (🔵):**
- modelo do jogador;
- cidade ao fundo;
- generalizar AmbientLife (IDs de estado para dados);
- dividir o orquestrador do slice;
- remover `_create_zone_sign`;
- ajuste de câmera e oclusão nos cantos;
- migração OPT-IN do save legado (decidida no C10, não implementada).

**Sistemas comprovados:**
- LevelBuilder/LevelValidator;
- AmbientLife;
- HumanoidSilhouette;
- InteractionDetector com Interactable e EnvironmentalObservation;
- DialogueController e DialogueRuntimeState;
- QuestController;
- NarrativeController, WorldState e memórias;
- Save V2 (save e load operacionais, rehearsal, rollback);
- GameEventBus com GameplayEventPublisher;
- GameState em sombra;
- ContextualWindowLifecycle.

**Decisões arquiteturais comprovadas:**
- sem Autoload;
- GameState em sombra;
- consequência separada de memória e de observação;
- apresentação derivada do estado (resync no Load em vez de reemitir eventos);
- estado transitório nunca salvo;
- conteúdo em dados (nível, vida, diálogos, quests, textos);
- colisão igual à geometria;
- testes com harness nativo e playtests com input real.

## 13. Próxima fase

A partir do próximo cenário, aplicar desde o primeiro bloco a regra:

**CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO.**

O próximo cenário não foi iniciado. C20 não foi implementado.
