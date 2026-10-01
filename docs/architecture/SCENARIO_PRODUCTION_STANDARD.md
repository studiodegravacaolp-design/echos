# Padrão de Produção de Cenários — ECHOES OF THE SOUL (Godot)

**Origem:** Bloco C20. Consolida o que a Forja de Vardhelm provou (C12–C19) em uma regra de produção.
**Vale para:** todo cenário **novo**. Vardhelm continua sendo o laboratório e a referência. Ele **não** é reconstruído nem migrado por este padrão; seus itens provisórios seguem registrados como futuro no [C19](BLOCK_C19_FORGE_CLOSING_AUDIT.md) §12.
**Modelo para preencher:** [`SCENARIO_TEMPLATE.md`](SCENARIO_TEMPLATE.md).

---

## 1. Objetivo

Fazer cada cenário nascer como **lugar**, não como geometria. Desde o primeiro bloco de implementação, a área precisa ter **FORMA + FUNÇÃO + VIDA + IDENTIDADE**.

## 2. Princípio

> **Um cenário não nasce como geometria vazia.**

Vardhelm começou como chão, paredes e um NPC. A identidade veio em camadas depois (C17 → C17.1 → C17.2 → C17.3), e cada camada precisou refazer parte da anterior:
- os postes da passarela bloquearam um corredor;
- o anteparo deixou o painel acessível só pela frente;
- as rotas dos testes tiveram que mudar por causa dos trabalhadores.

A partir de agora, o conceito, a função, a vida e a atmosfera são definidos **antes** e implementados **juntos**.

**Ordem de produção (obrigatória):**

**CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO**

A ordem é de **decisão**, não de entrega isolada: cada etapa depende da anterior, mas as seis primeiras aparecem já no primeiro bloco jogável, em nível de protótipo (§5).

## 3. Modelo de cenário

O documento de cenário é criado a partir de [`SCENARIO_TEMPLATE.md`](SCENARIO_TEMPLATE.md), em `docs/scenarios/<scenario_id>.md`.

**Seções:**
- IDENTIDADE;
- CONCEITO;
- ARQUITETURA;
- VIDA;
- ATMOSFERA;
- NARRATIVA AMBIENTAL;
- INTERAÇÃO;
- CIRCULAÇÃO;
- NARRATIVA;
- ESTADO;
- IDs E DADOS;
- PRIMEIRO BLOCO.

Regras de preenchimento:
- **Tudo que vier do cânone cita a fonte** (documento e seção).
- Onde o cânone não diz nada, escrever **"não definido no material canônico"**. Lacuna não se preenche com lore inventado: vira pergunta para o dono do cânone.
- O documento de cenário é de **produção**. Não é bíblia de mundo e não redefine cosmologia, raças ou personagens canônicos.

## 4. Ordem de produção e blocos

Cada bloco **amplia o mesmo conceito**. Nenhum bloco existe só para "pôr objetos" ou "dar identidade depois".

| Bloco | Entrega | Nunca |
|---|---|---|
| 1 | Conceito + arquitetura + função + vida básica: a planta funcional com os postos de atividade, ocupada e circulável | uma sala vazia |
| 2 | Atividade + NPCs + circulação + atmosfera (luz, som, partículas) | "agora colocar pessoas" |
| 3 | Narrativa ambiental + pontos de interesse (observações, vestígios) | "agora colocar objetos" |
| 4 | Consequências + estados reativos (antes e depois) | um evento sem reflexo no espaço |
| 5 | Acabamento + integração visual | "tentar dar identidade" |

A divisão é orientativa. O que é fixo:
- o bloco 1 já é um lugar;
- cada bloco termina jogável e testado (§11).

## 5. Protótipo × cenário cru

| | Protótipo (permitido) | Cenário cru (proibido) |
|---|---|---|
| Geometria | blocos simples, primitivas | caixa vazia |
| Materiais | provisórios, com a paleta do lugar | cinza neutro sem intenção |
| Personagens | silhuetas simplificadas (`HumanoidSilhouette`) | cápsulas sem papel |
| Luz | provisória, mas com fonte e motivo | luz de editor |
| O que precisa ler | função, escala, atividade, circulação, atmosfera, identidade | nada disso |

A pergunta de controle vem do C19: **"isso quebra a ilusão do lugar?"**. "Não é asset final" não é defeito; "não parece lugar nenhum" é.

## 6. Integração de vida

- Toda área de atividade tem **quem** a usa, **o quê** faz e **a rotina**, definidos no documento antes de entrar nos dados.
- A vida é dado: postos (`stations`), trabalhadores (`workers`: rota, `outfit`, `carry`), corpo (`worker_body`), props de história (`story_props`), reações (`reactions`). Ver §13.
- A vida respeita a circulação: rotas e colisores novos ficam longe de interações, spawn e entradas. O C17.1 exige 1,5 m.
- **Circulação obrigatória (lição do C21.1):** todo caminho obrigatório (por exemplo, até uma passagem entre áreas) é medido com a **cápsula real do jogador** contra os `CollisionShape`, e não pela distância visual entre malhas. Folga mínima de **1,5 m físicos** (o jogador tem 0,8 m), sem exigir mirar nem passar em diagonal. A prova é um playtest só andando, sem desvio automático.
- Quem colide o faz com um corpo leve (C17.3: camada 1, máscara 0). Personagens de ambiente não viram candidatos de interação.

## 7. Integração narrativa

- A narrativa usa os sistemas existentes: `DialogueController`/`DialogueRuntimeState`, `QuestController`, `NarrativeController`/`WorldState`, observações, Eco e memória. Nada de sistema paralelo.
- Consequência, memória e observação são coisas separadas (A2/C15).
- O mundo reage por **estado derivado**, não por script de cena (C13): a apresentação é recalculada do estado, e o Load ressincroniza sem reemitir eventos.
- Toda escolha que existir precisa de consequência **perceptível no espaço** (C15/C16).
- O jogo **não explica** o que deve ser descoberto. Os textos passam pelas mesmas proibições de termos de lore dos testes do C12/C14.

## 8. Integração visual

- **Referência:**
  - paleta 70/20/10 e materiais canônicos do [`BLUEPRINT_VISUAL_MESTRE.md`](../../doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) (cap. 2 e 4);
  - arquitetura pela raça ou cultura do lugar (cap. 4 §3);
  - prompts por tier em `docs/05_arte/`.
- **Decisão vigente (C17):** o protótipo Godot é 3D/2,5D; HD-2D é a referência futura.
- **Cor:** o laranja fica reservado ao foco quente. Brilho emissivo só com motivo narrativo; o ciano do Eco é exceção deliberada.
- A avaliação visual é sempre **pela câmera real do jogador** (C17 e C19), nunca pelo editor.
- Custo medido a cada bloco: SSAO foi desligado no C17 por dobrar o tempo de quadro.

## 9. Estados

Todo elemento do cenário é classificado **antes** de ser implementado:

| Tipo | O que é | Onde vive | Exemplos em Vardhelm |
|---|---|---|---|
| **PERSISTENTE** | fato de jogo que o Save precisa lembrar | `WorldState` / `QuestState` / `DialogueRuntimeState` → GameState → Save V2 | consequência `felt_nothing`, quest concluída, observação vista, memória |
| **DERIVADO** | apresentação calculada a partir do persistente | só no runtime; recalculado no Load (resync) | luz fria no painel, trabalhador `after_echo`, Durn fora de casa, folha disponível, volume reduzido |
| **TRANSITÓRIO** | apresentação momentânea | só no runtime; **nunca** salvo | dica "E • …" (C18), silêncio do encerramento (C14), painel de observação, fades |

- Estado transitório **não entra no GameState** nem no Save V2 (C18, C19 §9).
- Estado derivado não se salva: salva-se a causa.

## 10. Critérios de entrada (checklist)

Nenhum cenário entra em implementação sem este mínimo:

- [ ] conceito definido
- [ ] função definida
- [ ] arquitetura definida
- [ ] circulação definida
- [ ] ocupação definida
- [ ] rotina definida
- [ ] atmosfera definida
- [ ] narrativa ambiental definida
- [ ] pontos de interesse definidos
- [ ] interações definidas
- [ ] estados persistentes definidos
- [ ] estados derivados definidos
- [ ] estados transitórios definidos
- [ ] IDs definidos
- [ ] dados definidos
- [ ] primeiro bloco de implementação preparado

**Pré-condição de cânone:** o cenário precisa ter base documental (ver [C20](BLOCK_C20_PRODUCTION_FOUNDATION.md) §4). Sem base, o checklist não começa.

## 11. Critérios de fechamento (checklist)

Modelo: auditoria do [C19](BLOCK_C19_FORGE_CLOSING_AUDIT.md). Cada área recebe ✅ CONCLUÍDO, ⚠️ PEQUENO AJUSTE, ❌ PENDÊNCIA REAL ou 🔵 FUTURO. Há ❌ só se o item impedir:
- jogar, entender o fluxo, concluir ou escolher;
- perceber consequências;
- explorar, interagir ou navegar;
- salvar, carregar ou manter estado;
- manter a estabilidade.

- [ ] jogabilidade
- [ ] narrativa
- [ ] mundo
- [ ] atmosfera
- [ ] vida
- [ ] interação
- [ ] física
- [ ] Save/Load
- [ ] EventBus
- [ ] performance
- [ ] visual
- [ ] ausência de dependências críticas
- [ ] teste automatizado
- [ ] teste humano

**Evidência mínima esperada (igual ao C19):**
- runner completo;
- playtests com input real (renderizado e headless);
- ciclos Save → mover e girar → Load em cada etapa, com 0 diferenças no GameState e no estado percebido;
- contagem e ordem de eventos;
- circulação das rotas obrigatórias medida com a cápsula real (vão ≥ 1,5 m, playtest só andando, 0 travamentos);
- capturas pela câmera do jogador;
- medição de quadro com condições registradas (energia, GPU, renderer, resolução, vsync);
- teste humano declarado como humano. Teste automatizado nunca é apresentado como humano.

## 12. Relação com o LevelBuilder

- **Genéricos** ([`level_builder.gd`](../../godot/scripts/level/level_builder.gd), [`level_validator.gd`](../../godot/scripts/level/level_validator.gd)):
  - o nível é um JSON em `godot/level_data/<scenario>_<área>.json`;
  - chaves de topo: `level_name`, `material_palette`, `room`, `props`, `generation_rules`, `spawns`, `camera`, `lights`, `environment`.
- **Recursos já comprovados:**
  - `room.walls` com `openings`;
  - materiais de shader;
  - `collision:false`;
  - `rotation_degrees`;
  - props `"type":"group"`;
  - cor e energia de luz;
  - fog/ssao/tonemap no `environment`.
- **Regras:**
  - A **colisão é igual à geometria**. Não existe parede invisível; aberturas são reais (C17).
  - A cena é gerada pelo builder e depois assada (`@tool`). Mudança de layout se faz no JSON, nunca à mão na cena.
  - O validador roda sobre todo nível novo. Capacidade que falte vai para o builder ou o validador de forma **genérica**, nunca com o nome do cenário no código.

## 13. Relação com o AmbientLife

- **Dirigido por dados:**
  - `godot/data/<scenario>/ambient_life.json`;
  - chaves de topo: `workers`, `stations`, `story_props`, `reactions`, `observations`, `conditional_observations`, `memory_responses`, `after_echo`, `worker_body`, `presentation`, entre outras.
- **Limite atual, registrado como 🔵 no C19:**
  - a classe ainda se chama `VardhelmAmbientLife`;
  - conhece dois IDs de estado (`echo_awakened`, `sealed_panel_remembered`);
  - `durn_alone` é específico.
- **Regra para o próximo cenário:**
  - o **primeiro bloco** que precisar do AmbientLife fora de Vardhelm traz essa generalização como pré-requisito: IDs de estado para dados, sem mudar o comportamento de Vardhelm e com os testes de Vardhelm como regressão;
  - não se cria um segundo AmbientLife;
  - não se faz isso antes de existir o cenário (o C20 não implementa).
- **Rótulos de depuração** (`presentation.show_*`) nascem desligados.

## 14. Relação com o Save V2

- O que persiste passa pelo GameState (`player`, `world`, `quests`, `dialogue`, `memory`, `npcs`) e pelo Save V2 operacional:
  - V2 é o padrão desde o C10.5;
  - o legado só é usado com flags explícitas.
- **Todo cenário novo:**
  - registra seu `scenario_id` e seus IDs estáveis no catálogo (§ IDs abaixo);
  - informa `player.location.scenario_id`;
  - declara na seção ESTADO do documento o que é persistente, derivado ou transitório;
  - testa Save/Load em cada etapa da sua sequência.
- **Restauração:**
  - usa o `GameStateRuntimeRestorer` e os adapters existentes; um adapter novo só entra se houver um **tipo** de estado novo;
  - o Load **ressincroniza** a apresentação e **não reemite** eventos de gameplay (só `game_loaded`).
- **IDs:**
  - hoje o catálogo de IDs é código ([`id_catalog.gd`](../../godot/scripts/state/id_catalog.gd): `scenario.vardhelm`, `npc.vardhelm.durn`…), no formato `<tipo>.<cenário>.<nome>`;
  - IDs de conteúdo seguem esse formato; os registros documentais usam os prefixos do [`MASTER_ID_REGISTRY.md`](../../DOCUMENTACAO/MASTER_ID_REGISTRY.md) (`LOC-`, `EVT-`…);
  - o documento de cenário lista os dois.

## 15. Relação com o EventBus

- **Canal:** `GameEventBus` de runtime, sem Autoload, alimentado pelo `GameplayEventPublisher`. É observação, não controle de gameplay (B1).
- **Catálogo** ([`event_catalog.gd`](../../godot/scripts/events/event_catalog.gd)):
  - `scenario_entered`, `scenario_completed`;
  - `dialogue_started`, `dialogue_choice_selected`, `dialogue_completed`;
  - `quest_started`, `quest_progressed`, `quest_completed`;
  - `echo_triggered`, `memory_recovered`, `consequence_applied`, `observation_discovered`;
  - `npc_state_changed`, `world_state_changed`;
  - `game_saved`, `game_loaded`.
- Cenário novo **usa esses tipos**. Um tipo novo só entra com necessidade demonstrada e registro no catálogo, nunca por conveniência de um cenário.
- **Cada sequência documenta a ordem esperada dos eventos e a testa.** Referência do Eco em Vardhelm: `consequence_applied → world_state_changed → quest_progressed → quest_completed → echo_triggered → memory_recovered`.
- O GameState em sombra consome eventos; ele não é fonte de verdade.

---

**Reutilizar, não duplicar:** LevelBuilder, LevelValidator, AmbientLife, HumanoidSilhouette, ContextualWindowLifecycle, Interaction (detector, `Interactable`, `EnvironmentalObservation`), Dialogue, Quest, Narrative, GameState, EventBus e Save V2.

**Conteúdo → dados; execução → sistemas genéricos.**
