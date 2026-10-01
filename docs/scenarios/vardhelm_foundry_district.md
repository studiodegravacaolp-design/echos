# Vardhelm — Distrito das Fundições (pátio da Forja 01)

> Documento de cenário criado a partir do [`SCENARIO_TEMPLATE.md`](../architecture/SCENARIO_TEMPLATE.md), no Bloco C21 ([`BLOCK_C21_NEXT_SCENARIO.md`](../architecture/BLOCK_C21_NEXT_SCENARIO.md)).
>
> Classificação de cada informação: **CONFIRMADO**, **HISTÓRICO**, **CANDIDATO**, **CONTRADIÇÃO**, **LACUNA**. Uma **decisão de produção** é uma escolha de implementação coerente com o material; não é cânone. O que o cânone não define aparece como **"não definido no material canônico"**.

---

# 1. IDENTIDADE

| Campo | Valor | Classe / fonte |
|---|---|---|
| Nome | Distrito das Fundições | CONFIRMADO: [`ART-PROMPTS-TIER1.md`](../05_arte/ART-PROMPTS-TIER1.md) §1.4.1 ("Exterior — Distrito das Fundições", `[VARDHELM-FORJA]`, "Vardhelm forge district"); [`ART-PROMPTS-TIER3.md`](../05_arte/ART-PROMPTS-TIER3.md) §2.3.3 ("Vardhelm forge district") |
| Recorte construído | o pátio sob a Forja 01 | decisão de produção (§5) |
| ID do cenário (Godot) | `scenario.vardhelm`, o mesmo da Forja. O distrito é uma **área** de Vardhelm, não um cenário novo | [`id_catalog.gd`](../../godot/scripts/state/id_catalog.gd) |
| ID documental | `LOC-VAR-001` **proposto, não registrado**: a tabela `LOC-` do [`MASTER_ID_REGISTRY.md`](../../DOCUMENTACAO/MASTER_ID_REGISTRY.md) está vazia e o registro não foi alterado | decisão pendente do dono do registro |
| Localização | Vardhelm, cidade industrial do Ato 1 (níveis 1–10) | CONFIRMADO: [`SYS-BALANCEAMENTO-ATOS.md`](../01_sistemas/SYS-BALANCEAMENTO-ATOS.md) §2; [`ENG-PROGRESSAO-NIVEIS.md`](../04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md) segmento 1; decisão do usuário no C17 ("Vardhelm é uma cidade industrial") |
| Função narrativa | não definida no material canônico | LACUNA |
| Função no mundo | produção e transporte de fundição: fundições de ferro, chaminés, carvão levado em carrinhos, talhas de corrente | CONFIRMADO (direção de arte): TIER1 §1.1 e §1.4.1 |

# 2. FONTES CANÔNICAS

- **TIER1 §1.1 (Vardhelm industrial):**
  - "vast industrial cityscape", "massive iron foundries", "sooty canvas bricks";
  - "smog-choked chimneys cutting through overcast gray skies", "coal dust atmosphere", "oppressive weight of architecture".
- **TIER1 §1.4.1 (Distrito das Fundições):**
  - "massive iron foundries exterior", "smoke stacks piercing overcast sky";
  - "coolie workers hauling coal carts", "heavy chain pulleys", "industrial grime", "raw cast iron";
  - "diffused overcast lighting".
- **TIER1 §1.2:** paleta de Vardhelm: cinza-chumbo 40%, sépia 25%, preto fuligem 20%, ferrugem 10%, marrom lona 5%.
- **TIER1 §4.1:**
  - luz permitida: difusa de céu encoberto, lampiões a querosene, fogo industrial, sombras duras;
  - luz bloqueada: brilho mágico, bloom.
- **TIER3 §2.3.3:** o mesmo "forge district" existe mais tarde, no colapso. Confirma o lugar, não o seu futuro, que não é usado aqui.
- **[`BLUEPRINT_VISUAL_MESTRE.md`](../../doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) cap. 4 §3 (arquitetura humana):** pedra bruta com reforços de aço escurecido, guindastes, pontes de tábua. O formato HD-2D do blueprint **não** é adotado: decisão do C17, mantida no C21.
- **Slice Godot (C12–C19, validado por humano):**
  - a Forja 01 é uma baia elevada, com um patamar em balanço sobre a cidade abaixo (C17: `EntryLanding`, `Background_CityFloor` a y −12,5);
  - o NPC é Durn;
  - o C13 estabeleceu a reação ao Primeiro Eco: "máquinas mais baixas".

# 3. CONCEITO

- **O que é este lugar?** O pátio de uma fundição de Vardhelm, ao pé da Forja 01: onde o carvão chega, é descarregado, pesado na talha e carregado para dentro.
- **Por que ele existe?** Para abastecer as fundições (carvão, lingotes, cargas). Qualquer razão além disso não está definida no material canônico.
- **O que acontece nele diariamente?** Carvão chega pelo trilho em carrinhos, é descarregado em pilhas, sobe pela talha de corrente para a tremonha e entra pela porta do térreo da fundição, enquanto a doca recebe caixas e barris. É direção de arte do TIER1 ("workers hauling coal carts", "heavy chain pulleys") transformada em rotina.
- **Quem utiliza o espaço?** Trabalhadores sem nome: carregadores, quem trabalha com a pá, quem opera a talha e quem move a carga na doca. Nomes, facções ou donos não estão definidos no material canônico.

# 4. ARQUITETURA

| Campo | Valor |
|---|---|
| Estrutura | pátio fechado por três lados: ao norte, a **base da Forja 01** (o térreo da fundição, 11,4 m de tijolo sob a baia do slice); a oeste, a fachada da fundição vizinha; ao sul e a leste, muros baixos |
| Materiais | tijolo com fuligem (o mesmo shader da Forja, com a fuligem calibrada à altura do pátio); ferro escurecido; madeira velha; carvão; lona; piso de pedra em placas pequenas (o mesmo shader de chapas, em cinza-pedra) |
| Escala | 30 × 25 m; base da Forja com 11,4 m; fachada oeste com 8 m; muros sul e leste com 1,1 m; talha com 13 m (do pátio até 1,2 m acima do patamar) |
| Entradas | a talha (única passagem jogável, a partir do patamar da Forja 01) |
| Saídas | a talha (de volta ao patamar); o portão sul fica fechado, e o trilho passa por baixo dele |
| Áreas | chegada da talha (centro-norte); porta do térreo da Forja 01 (noroeste); pilha de carvão e carrinho de mão (oeste); lingotes e portões da fundição oeste; talha de braço e tremonha (sudoeste); trilho com para-choque e 3 carrinhos (centro); doca de carga (leste); portão sul |
| Elementos verticais | poço e guias da talha; pórtico da polia sobre o patamar (colunas curtas nos guarda-corpos laterais, travessas só ao sul, para não cobrir a placa "FORJA 01" do portão); talha de braço na fachada oeste; tubulação que desce pela quina da base; janelas altas da fundição oeste |
| Profundidade | a Forja 01 em cima (a partir do patamar, o pátio aparece através da névoa); galpões baixos ao sul; blocos da cidade a nordeste; massa e chaminé da fundição oeste; chão da cidade ao redor, coberto pela névoa |
| Planta funcional | [`level_data/vardhelm_foundry_district_01.json`](../../godot/level_data/vardhelm_foundry_district_01.json), gerada a partir de coordenadas de mundo |

**Regras aplicadas** (padrão §12):
- A **colisão é igual à geometria**: 61 corpos, cada um com a própria malha.
- Não há parede invisível.
- Sul e leste ficam **em corte**, porque a câmera olha de sudeste, como no C17.

# 5. DECISÃO DE PRODUÇÃO: por que "o pátio sob a Forja 01"

- O C17 construiu a Forja 01 como **baia elevada**: patamar em balanço, com a cidade 12 m abaixo.
- O TIER1 descreve o Distrito das Fundições como o exterior das fundições de Vardhelm.
- Colocar o recorte do distrito **abaixo e em frente** à Forja 01 dá três coisas:
  - usa o espaço que o slice já tinha declarado ("cidade abaixo");
  - liga as duas áreas sem cena nova, sem carregamento e sem mudar o ID de cenário;
  - dá à passagem uma função do próprio distrito, a talha de corrente ("heavy chain pulleys").
- **Isso não é cânone.** Se o material futuro situar a Forja 01 em outro lugar, o pátio se move sem afetar o estado salvo: nenhum ID depende da posição.

# 6. CIRCULAÇÃO

| Campo | Valor |
|---|---|
| Entrada do jogador | E na talha do patamar da Forja 01 → chegada em frente à gaiola, no pátio |
| Para onde pode ir | todo o pátio: pilha de carvão, porta da Forja 01, carrinhos, talha de braço, doca, portão sul |
| Áreas abertas | o piso do pátio (30 × 25 m menos os obstáculos) |
| Bloqueios naturais | base da Forja 01 e fachada oeste (paredes); muros baixos sul e leste com portão de grade (cada barra colide); doca (0,9 m); pilhas de carvão, tremonha, lingotes, barris e sacos; cercado do poço da talha |
| Rotas dos NPCs | seguem vão e volta entre pontos livres; ficam a mais de 1,5 m do centro das observações e da gaiola; nenhuma cruza carrinhos, para-choque ou poço |

**Circulação entre a Forja 01 e a talha (corrigida no C21.1):**
- **C21:** a bancada (x −1,6…1,6, z 4,7) deixava uma única folga de **0,9 m** junto ao respiro de brasas, para um jogador de 0,8 m. O teste humano confirmou a dificuldade de acesso.
- **C21.1:** a bancada e as ferramentas sobre ela passaram **0,6 m para oeste** (x −2,2…1,0). O vão até o respiro de brasas é agora de **1,5 m**, e o caminho segue reto até o portão.
- Duas linhas finas de tinta no piso da Forja (a mesma tinta das marcas que ela já tem) marcam a faixa até o portão.
- As chegadas da talha não ficam dentro de colisão, e a dica aparece a até 3,17 m de cada estação.
- Nenhum trabalhador bloqueia o caminho; o mais próximo fica a 1,97 m.
- Detalhes em [`BLOCK_C21_NEXT_SCENARIO.md`](../architecture/BLOCK_C21_NEXT_SCENARIO.md) §13 e §13.9.

# 7. PONTOS DE INTERESSE

| Ponto | Onde | Tipo |
|---|---|---|
| Talha (patamar ↔ pátio) | x 0, z 10,9 | passagem (`TransitionPoint`) |
| Carrinhos de carvão | trilho central | observação `observation.vardhelm.foundry_coal_carts` |
| Talha de corrente | talha de braço da fachada oeste | observação `observation.vardhelm.foundry_chain_pulley` |
| Porta da fundição | térreo da Forja 01, com a placa "FORJA 01" | observação `observation.vardhelm.foundry_forge_door` (com texto pós-Eco) |
| Respiro da Forja 01 | fachada da base | reação derivada (fumaça) |
| Placa "DISTRITO DAS FUNDIÇÕES" | trecho leste do muro norte | orientação ("onde estou?") |

# 8. VIDA

- **Quem está presente?** Seis trabalhadores sem nome, com a silhueta humana do C17.2 e o corpo leve do C17.3.
- **O que fazem e com que rotina:**

| Trabalhador | Posto → atividade | Rotina |
|---|---|---|
| `worker_district_shovel_01` | pilha de carvão → trabalho com a pá | vai e volta curto (1,1 s / 1,4 s) |
| `worker_district_hauler_01` | pilha → porta da Forja 01, com saco | 4,2 s de caminhada / 2 s parado |
| `worker_district_hauler_02` | carrinhos → porta da Forja 01, com saco | rota de 3 pontos, em vai e volta |
| `worker_district_carts_01` | carrinhos → conferência | passo curto e lento |
| `worker_district_jib_01` | talha de braço → tremonha | vai e volta |
| `worker_district_dock_01` | frente da doca, com caixa | 3,6 s / 2,2 s |

- **Elementos que mostram atividade:**
  - carrinhos cheios (um quase vazio) e carvão caído entre os trilhos;
  - trilha de fuligem da pilha até a porta;
  - pás encostadas e carrinho de mão carregado;
  - caçamba pendurada e tremonha com carvão;
  - caixas e barris na doca;
  - fumaça do respiro, vapor da fundição oeste e poeira de carvão.

# 9. ATMOSFERA

| Campo | Valor |
|---|---|
| Luz | a direcional fria de cima (a mesma da Forja, já no espírito "céu encoberto"); luz ambiente de 0,42 no pátio contra 0,3 na Forja, derivada da área; 3 lampiões de querosene (omni, sem sombra, `#D89A5A`); janelas altas da fundição oeste com brilho baixo |
| Som | o áudio ambiente global do slice (zumbido, vapor, maquinário), sem arquivo novo; a redução pós-Eco do C13 vale aqui também |
| Clima | céu encoberto: névoa com altura baixa no pátio (−11,2 contra −0,6 na Forja, derivada da área) |
| Partículas | fumaça do respiro da Forja 01 (20), vapor da fundição oeste (10), poeira de carvão (40): 3 emissores de CPU |
| Temperatura visual | fria e cinza; o quente fica só nos lampiões e nas janelas da fundição; nenhum laranja de forja no pátio |
| Paleta | a de Vardhelm (TIER1 §1.2): tijolo `#4A3328`/`#3A2A22`, ferro `#1E222A`, ferro gasto `#3B2A22`, madeira `#3F3022`, carvão `#121112`, lona `#4B3F30`, pedra `#2B2926` |

**Regra de cor:**
- o ciano do Eco **não** aparece no pátio;
- nenhum emissivo novo além dos lampiões e das janelas.

# 10. NARRATIVA AMBIENTAL

- **O que se percebe sem diálogo:**
  - o carvão é o trabalho do lugar;
  - o trilho gastou as rodas do mesmo lado;
  - os carregadores entram pela porta de baixo de onde o jogador acabou de estar;
  - a Forja 01 é uma parte de um conjunto maior.
- **Histórias que o ambiente conta:** rotina, desgaste, repetição.
- **Acontecimentos passados sugeridos:** os mesmos gestos repetidos durante muito tempo (elos lisos, rodas gastas, fuligem acumulada). Nenhum acontecimento específico.
- **Consequência:** depois do Primeiro Eco, o respiro da Forja 01 solta menos fumaça, e a porta da fundição "conta" que o barulho de cima baixou. É o efeito **já estabelecido** no C13 ("máquinas mais baixas"), visto de fora. Não é um fato novo.

# 11. INTERAÇÕES

| O quê | Como | Prioridade |
|---|---|---|
| Observar/examinar | 3 `EnvironmentalObservation` (E → painel de observação; texto pós-Eco só na porta) | 2 (padrão das observações) |
| Passar | 2 `TransitionPoint` ("E • Descer ao pátio" / "E • Subir à Forja 01") | 0 |
| NPCs | trabalhadores sem interação (não são candidatos; camada 1, máscara 0) | — |

- Todas as interações usam o mesmo detector, a tecla E e a janela contextual do C18 (atraso de 0,75 s e fades vindos dos dados).
- Não há sistema de interação novo.

# 12. ESTADOS

| Elemento | Tipo | Fonte de verdade | Como o Load o restaura |
|---|---|---|---|
| Observações do pátio vistas | **PERSISTENTE** | `WorldState` (flag `observation_<id>_seen` + valor) → `GameState.world.observations` (ID canônico) → Save V2 | `ObservationRestoreAdapter` pelo provedor (`observation_roots()`) |
| Posição e rotação do jogador (inclusive no pátio) | **PERSISTENTE** | `GameState.player.location` | núcleo do restaurador (C3) |
| Em que área o jogador está | **DERIVADO** | a posição do jogador (`Area3D`) | sinais da área depois do Load |
| Névoa de altura e luz ambiente da área | **DERIVADO** | a área | tween curto ao entrar ou sair |
| Posição da gaiola | **DERIVADO** | a área (a gaiola fica do lado do jogador) | ao entrar ou sair da área |
| Fumaça do respiro e texto da porta pós-Eco | **DERIVADO** | flag persistente `vardhelm_first_echo_complete` (C13) | `refresh()` em `_refresh_persistent_world_state()` (início e Load) e ao aplicar consequência |
| Rotinas dos trabalhadores | **DERIVADO** | dados | recriadas no `_ready` |
| Passagem em andamento (escurecimento) | **TRANSITÓRIO** | `VardhelmFoundryDistrict.riding` | nunca salvo; um Load no meio não é sobrescrito pela passagem |
| Dica "E • …" | **TRANSITÓRIO** | `ContextualWindowLifecycle` (C18) | nunca salvo |

# 13. INTEGRAÇÃO COM O GAMESTATE

- **O que muda:**
  - três IDs de observação novos no catálogo (§16);
  - a sombra (A3) e o projetor passam a registrá-las como qualquer observação.
- **O que não muda:** nenhum cenário, NPC, quest, memória, consequência ou tipo de estado novo. Nenhum campo global novo.
- **Estado transitório:** área, névoa, gaiola e passagem ficam **fora** do GameState.

# 14. INTEGRAÇÃO COM O EVENTBUS

- **Eventos usados:** só os existentes. Examinar emite `observation_discovered` com o ID canônico, sem `memory_recovered`, porque as observações do pátio não têm fragmento.
- **Ausências deliberadas:**
  - nenhum evento de "entrar na área", pois a área é derivada;
  - nenhum `world_state_changed` novo, pois a reação reusa `echo_awakened`.
- **Load:** só `game_loaded`.

# 15. INTEGRAÇÃO COM O SAVE V2

- **Caminho:** o de sempre, V2 operacional. O legado nunca é chamado.
- **Posição:** salvar no pátio grava a posição no pátio; carregar volta ao pátio, com área, névoa e gaiola re-derivadas.
- **Observações:** o provedor do Save V2 (`VardhelmRuntimeStateProvider`) lê as observações das duas raízes (Forja e pátio) via `observation_roots()` do slice.
- **Transitório fora do save:** o save não contém talha, névoa nem área (testado).

# 16. IDs E DADOS

| Tipo | ID | Arquivo |
|---|---|---|
| cenário | `scenario.vardhelm` (existente) | — |
| nível | — | `godot/level_data/vardhelm_foundry_district_01.json` → `scenes/prototypes/vp_02_vardhelm_foundry_district.tscn` |
| vida | — | `godot/data/vardhelm/foundry_district_life.json` |
| integração | — | `godot/data/vardhelm/foundry_district.json` (área, névoa, luz, talha, lampiões, placas, fumaça) |
| observação | `observation.vardhelm.foundry_coal_carts` / `foundry_chain_pulley` / `foundry_forge_door` (runtime: `foundry_coal_carts`…) | `foundry_district_life.json` + `localization/pt-BR.json` |
| textos | `ui.hoist.down`, `ui.hoist.up`, `observation.foundry_*.title/text`, `observation.foundry_forge_door.after_echo` | `godot/data/localization/pt-BR.json` |
| consequência / envstate / diálogo / quest | nenhum novo | — |

# 17. DEPENDÊNCIAS

- **Forja 01:**
  - WorldEnvironment e luz direcional;
  - guarda-corpos laterais do patamar, sobre os quais fica o pórtico da polia;
  - patamar, onde fica a talha de cima.
- **Sistemas reutilizados:** LevelBuilder/LevelValidator, `VardhelmAmbientLife` (com `data_path`), `HumanoidSilhouette`, `Interactable`/`InteractionDetector`, `EnvironmentalObservation`, `ContextualWindowLifecycle`, `NarrativeController`/`WorldState`, GameState em sombra, `GameEventBus`, Save V2.
- **Flag do C13:** `vardhelm_first_echo_complete`.

# 18. LACUNAS (mantidas, não preenchidas)

- Função narrativa do distrito; acontecimentos; relação com Durn ou com o Eco além do efeito do C13.
- NPCs nomeados, facções, donos das fundições, o que se produz além de ferro.
- Para onde levam o portão sul e o trilho; o resto do distrito; a posição da Forja 01 no mapa da cidade.
- `LOC-` do distrito no registro mestre.
- Ostrell e a transição do Ato 1 para o 2 (fora do escopo; ver C21 §3).

# 19. PRIMEIRO BLOCO (C21) E CRITÉRIOS DE FECHAMENTO

- **Entregue:**
  - FORMA (arquitetura), FUNÇÃO (carvão, trilho, talha, doca) e VIDA (6 rotinas);
  - IDENTIDADE (materiais e placa de Vardhelm);
  - ATMOSFERA (névoa, luz, lampiões, fumaça, poeira) e NARRATIVA AMBIENTAL (3 observações e desgaste);
  - CONSEQUÊNCIA (efeito do C13 visto de fora), entrada jogável e integração com Save V2 e EventBus.
- **Testes:**
  - runner `test_c21_foundry_district.gd`;
  - playtest `c21_foundry_district_playtest.gd` (input real, renderizado e headless).
- **Critérios de fechamento:** checklist do [padrão](../architecture/SCENARIO_PRODUCTION_STANDARD.md) §11. Avaliação atual em [`BLOCK_C21_NEXT_SCENARIO.md`](../architecture/BLOCK_C21_NEXT_SCENARIO.md) §11. **Não fechado: falta o teste humano.**

---

## Checklist de entrada

- [x] conceito definido
- [x] função definida
- [x] arquitetura definida
- [x] circulação definida
- [x] ocupação definida
- [x] rotina definida
- [x] atmosfera definida
- [x] narrativa ambiental definida
- [x] pontos de interesse definidos
- [x] interações definidas
- [x] estados persistentes definidos
- [x] estados derivados definidos
- [x] estados transitórios definidos
- [x] IDs definidos
- [x] dados definidos
- [x] primeiro bloco de implementação preparado

**Ressalva:** a função **narrativa** segue como LACUNA. O bloco se limita à narrativa ambiental e ao efeito do C13, sem acontecimento novo.
