# Bloco C21 — Próximo cenário: Distrito das Fundições (pátio da Forja 01)

**Status:**
- implementado, com validação automatizada completa;
- **teste humano pendente**; o cenário **não** está fechado;
- sem commit e sem push.

**Documento do cenário:** [`docs/scenarios/vardhelm_foundry_district.md`](../scenarios/vardhelm_foundry_district.md).

## 1. Objetivo

Construir o próximo cenário jogável pelo [padrão de produção](SCENARIO_PRODUCTION_STANDARD.md), na ordem CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO, sem inventar cânone.

## 2. Pesquisa e classificação das fontes

**Onde se buscou:**
- `AETHERIS_MASTER_INDEX.md`;
- `DOCUMENTACAO/` (DOC-000 a DOC-015, registro de IDs, mapa);
- `docs/01_*` a `docs/05_*`;
- `doc/art_bible/`;
- `src/` (protótipo TypeScript);
- `godot/` (catálogo, dados, diálogos);
- `PROJECT_CHANGELOG.md`;
- histórico git (49 commits; nenhum documento apagado encontrado).

| Informação | Fonte | Classe |
|---|---|---|
| Ato 1 = Vardhelm (níveis 1–10) | `SYS-BALANCEAMENTO-ATOS` §2; `ENG-PROGRESSAO-NIVEIS` seg. 1; `SYS-GRIMORIO-EARLYGAME`; `ENG-MATEMATICA-COMBATE` | CONFIRMADO |
| Vardhelm é cidade industrial: fundições de ferro, chaminés, fuligem, poeira de carvão | `ART-PROMPTS-TIER1` §1.1; decisão do usuário no C17 | CONFIRMADO |
| **Distrito das Fundições** de Vardhelm: exterior de fundições, chaminés, trabalhadores com carrinhos de carvão, talhas de corrente, céu encoberto | `ART-PROMPTS-TIER1` §1.4.1; o mesmo "forge district" em `ART-PROMPTS-TIER3` §2.3.3 | CONFIRMADO como lugar e direção de arte; função narrativa = LACUNA |
| Galpão de Manufatura (interior: volantes, correias, ponte rolante, lampiões) | `ART-PROMPTS-TIER1` §1.4.2 | CONFIRMADO como direção de arte (já foi a referência da Forja no C17) |
| Paleta de Vardhelm; luz permitida (céu encoberto, querosene, fogo industrial) | `ART-PROMPTS-TIER1` §1.2 e §4.1 | CONFIRMADO |
| Ato 2 = Ostrell (níveis 11–20): inflação de +20%, "corrupção nas terras altas", rotas de Vardhelm para Ostrell longas e perigosas | `SYS-BALANCEAMENTO-ATOS` §3; `ENG-PROGRESSAO-NIVEIS` | CONFIRMADO (economia e progressão) |
| Arquitetura, cultura, NPCs, locais e acontecimentos de Ostrell | — | LACUNA |
| `EVT_TRANSICAO_ATO1_ATO2` no nível 10 | `ENG-PROGRESSAO-NIVEIS` §3.1 | CONFIRMADO (o slice não tem progressão por nível) |
| Brenhold no **Ato 3** (níveis 21–35), Diretório, Ordem do Silêncio, zonas `LOC-BRE-001..003` | `SYS-BALANCEAMENTO-ATOS` §4; `SYS-GRIMORIO-MIDGAME`; `SYS-MANUFATURA-MIDGAME`; `ENG-PROGRESSAO-NIVEIS`; `ART-PROMPTS-TIER2` | CONFIRMADO nos documentos de sistema |
| Brenhold no **Ato 2** ("profundezas de Brenhold") | `src/core/CampaignMapEngine.ts` (comentário); resumo do `PROJECT_CHANGELOG.md` | **CONTRADIÇÃO** (não resolvida) |
| O jogo inteiro "ambientado nas profundezas industriais de Brenhold" | `BLUEPRINT_VISUAL_MESTRE.md` intro; `AETHERIS_MASTER_INDEX.md` §1 | HISTÓRICO (enquadramento da fase AETHERIS; incompatível com os Atos atuais) |
| Nós do CLI (Entrada de Brenhold, Pátio de Fundição, Mercador de Sucata…) | `src/core/CampaignMapEngine.ts`, `QuestContent.ts` | HISTÓRICO (protótipo AETHERIS; são de Brenhold, não de Vardhelm) |
| TIER1 = "Atos 1 e 2 / Níveis 1-25"; TIER2 = "Ato 3 / Níveis 26-35" | cabeçalhos de `ART-PROMPTS-TIER1/2` | CONTRADIÇÃO menor (faixas de nível diferentes dos Atos) |
| Formato HD-2D pixel art | `BLUEPRINT_VISUAL_MESTRE.md` | HISTÓRICO/futuro (a decisão do C17 mantém 3D/2,5D) |
| Forja 01 elevada sobre a "cidade abaixo"; Durn; reação do C13 ("máquinas mais baixas") | slice Godot C12–C19 (validado por humano) | CONFIRMADO no cânone de produção atual |
| Aethel, Asterion, Homem Cinzento | nenhum arquivo do repositório | LACUNA (não pertinentes ao cenário; não introduzidos) |

## 3. Matriz de decisão

| Cenário | Evidência canônica | Função | Localização | Ato | Personagens | Eventos | Arquitetura | Atmosfera | Narrativa ambiental | Lacunas | Confiança |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **Distrito das Fundições** | TIER1 §1.1/§1.4.1 e TIER3 §2.3.3 | produção e transporte de fundição | Vardhelm | 1 | trabalhadores sem nome | nenhum | fundições, chaminés, tijolo com fuligem, talhas, carrinhos | céu encoberto, fumaça, poeira de carvão, sépia/chumbo | desgaste, trabalho, carvão | função narrativa, NPCs nomeados, eventos | **alta** para espaço, função, vida e atmosfera; baixa para narrativa |
| Galpão de Manufatura | TIER1 §1.4.2 | manufatura | Vardhelm | 1 | — | — | interior com volantes, correias, ponte rolante | lampiões, chiaroscuro | — | narrativa, NPCs; **repetiria** o interior da Forja (C17) | média |
| Ostrell | economia e progressão | não definida | "terras altas"? (só a inflação cita) | 2 | — | transição no nível 10 | — | — | — | quase tudo | baixa |
| Brenhold | sistemas e TIER2 | Diretório, Ordem do Silêncio | não definida | **2 ou 3 (contradição)** | — | — | muralhas, salas de ressonância | chumbo, silêncio | — | Ato; ligação com Vardhelm; salto de progressão | média na arte; baixa no encaixe |

**Decisão: Distrito das Fundições.**
- É o único candidato do Ato 1 com lugar, função, ocupação e atmosfera sustentados por duas fontes independentes.
- Pode ser construído **sem inventar elemento crítico**: sem NPC nomeado, sem acontecimento e sem lore.
- O Galpão repetiria a Forja.
- Ostrell não tem material de espaço.
- Brenhold tem Ato contraditório, e usá-lo pularia o Ato 1.

**Recorte (decisão de produção, não cânone):**
- o pátio **sob a Forja 01**, no espaço que o C17 já declarou como "cidade abaixo";
- ligado pela talha de corrente, que é elemento do próprio TIER1 ("heavy chain pulleys").

**Contradição de Brenhold:** registrada, não resolvida; não afeta este bloco.

## 4. Arquitetura

- **Mesma cena, mesmo cenário:**
  - `vp_02_vardhelm_foundry_district.tscn` é gerada pelo LevelBuilder e instanciada no slice em (0, −11,9, 19,5);
  - o pátio é uma **área** de `scenario.vardhelm`. Não há cena nova para carregar, troca de cena ou ID de cenário novo.
- **Pátio de 30 × 25 m:**
  - ao norte, a **base da Forja 01** (térreo da fundição, 11,4 m);
  - a oeste, a fachada da fundição vizinha (8 m, portão e janelas altas);
  - ao sul e a leste, muros baixos em corte, porque a câmera olha de sudeste;
  - portão sul de grade fechado, com o trilho passando por baixo.
- **Talha:**
  - poço com guias só até 1,2 m acima do patamar, para não ficar entre a câmera e o jogador;
  - a polia pende de um pórtico sobre o patamar: colunas curtas nos guarda-corpos laterais e travessas só ao sul (a primeira versão, apoiada na verga do portão, cobria a placa "FORJA 01" e foi refeita);
  - a gaiola fica do lado do jogador.
- **Profundidade:** galpões ao sul, blocos a nordeste, massa e chaminé da fundição oeste, chão da cidade ao redor. Nada alto a sudeste.
- **Controlador** (`VardhelmFoundryDistrict`, dados em `data/vardhelm/foundry_district.json`):
  - integra vida, talha, área (névoa e luz ambiente), lampiões, placas, fumaça e poeira, escurecimento da passagem e reação derivada;
  - sem `_process`.

## 5. Implementação e sistemas reutilizados

| Sistema | Uso |
|---|---|
| LevelBuilder / LevelValidator | geometria do pátio (141 props, 2 regras de geração; 61 corpos com colisão); validador sem erros |
| `VardhelmAmbientLife` | a mesma classe, com `data_path` apontando para `foundry_district_life.json` (6 trabalhadores e 3 observações) |
| `HumanoidSilhouette` e corpo leve do C17.3 | os 6 trabalhadores |
| Interaction (detector, `Interactable`, E, prioridade) | talha e observações |
| `ContextualWindowLifecycle` (C18) | dica "E • Descer ao pátio" / "E • Subir à Forja 01" / "E • Examinar" |
| `EnvironmentalObservation` + painel | 3 observações (texto pós-Eco pela flag de sempre) |
| `NarrativeController` / `WorldState` / GameState em sombra | flags e observações |
| `GameEventBus` | `observation_discovered`; nenhum evento novo |
| Save V2 (provedor + `ObservationRestoreAdapter`) | posição no pátio e observações |

**Novo (mínimo):**
- `TransitionPoint` (`scripts/interaction/transition_point.gd`): um `Interactable` com `prompt_key` e destino. Só dados; é genérico e reutilizável.
- `VardhelmFoundryDistrict` (`scripts/vardhelm/vardhelm_foundry_district.gd`).

## 6. Alterações compartilhadas (regressão de Vardhelm executada)

| Arquivo | Mudança | Compatibilidade |
|---|---|---|
| `scripts/vardhelm/vardhelm_ambient_life.gd` | `var data_path := DATA_PATH` (lido no `_load_data`) | padrão inalterado; a Forja usa o mesmo arquivo |
| `scripts/vardhelm/vardhelm_vertical_slice.gd` | `_setup_foundry_district()`; `observation_roots()` (Forja + pátio) nos dois laços que já existiam; `foundry_district.refresh()` no fim de `_refresh_persistent_world_state()`; ramo da dica para `TransitionPoint` | sem pátio, `observation_roots()` devolve só a raiz da Forja |
| `scripts/vardhelm/vardhelm_runtime_state_provider.gd` | `_observation_nodes()` lê `observation_roots()` | mesma lista na Forja |
| `scripts/state/id_catalog.gd` | 3 observações + aliases | IDs existentes intocados |
| `scenes/prototypes/vardhelm_vertical_slice.tscn` | instância `VP02_FoundryDistrict` | — |
| `data/localization/pt-BR.json` | 9 chaves novas | nenhuma chave existente alterada |
| `tests/state/state_test_runner.gd` | registra a suíte do C21 | — |

- **Não alterados:** a Forja 01 (nível, cena `vp_01`, set dressing, `ambient_life.json`), C13–C19, diálogos, quests, Save V2 e EventBus.
- **Mudanças visíveis na Forja 01** (necessárias para a ligação):
  - a talha surge atrás do guarda-corpo sul do patamar;
  - o pórtico da polia fica sobre o patamar, apoiado nos guarda-corpos laterais;
  - a alavanca fica no guarda-corpo;
  - do patamar, através da névoa, vê-se o pátio lá embaixo.

## 7. IDs criados

| ID | Tipo |
|---|---|
| `observation.vardhelm.foundry_coal_carts` | observação |
| `observation.vardhelm.foundry_chain_pulley` | observação |
| `observation.vardhelm.foundry_forge_door` | observação |

- Chaves de localização: `ui.hoist.down`, `ui.hoist.up`, `observation.foundry_*`.
- `LOC-VAR-001` foi **proposto** no documento do cenário e **não** registrado no `MASTER_ID_REGISTRY`.

## 8. Estados

**PERSISTENTE:**
- observações do pátio (flags → `world.observations` → Save V2);
- posição e rotação.

**DERIVADO:**
- área (posição);
- névoa e luz ambiente (área);
- gaiola (área);
- fumaça do respiro e texto da porta (flag `vardhelm_first_echo_complete`);
- rotinas.

**TRANSITÓRIO:**
- passagem pela talha;
- dica.

Nada visual é salvo (testado). Tabela completa: documento do cenário, §12.

## 9. Testes

Ver §10 para os números da bateria.
- **Runner** `tests/save_v2/test_c21_foundry_district.gd` (42 checks, 5 seções):
  - dados;
  - cena (colisão = geometria; um só ambiente e uma só luz direcional; câmera do jogador);
  - integração (talha, dica pelo C18, observações, EventBus, GameState, sombra);
  - reação derivada;
  - Save/Load V2 (posição e rotação no pátio, observações, só `game_loaded`, sem duplicar, save antes e depois do Eco).
- **Playtest** `tests/save_v2/c21_foundry_district_playtest.gd` (25 checks, input real, renderizado e headless; automatizado, **não humano**):
  - dentro da Forja 01 o pátio não é desenhado, mas a talha continua visível;
  - do início ao patamar pela passagem do portão; perto do patamar o pátio volta a ser desenhado;
  - E na talha → pátio;
  - 3 observações examinadas andando;
  - vida em movimento;
  - limites leste, sul e oeste (não sai, não cai);
  - Save no pátio → subir → Load → de volta ao pátio;
  - subir → Durn → Eco;
  - descer → menos fumaça e texto novo na porta.

## 10. Resultados e desempenho

**Bateria completa guardada** (saves reais do usuário protegidos e intactos):

| Suite | Resultado |
|---|---|
| Runner (A2–C21) | **1694/1694** (C21: 42/42) |
| Playtest C21 | 25/25 renderizado · 25/25 headless |
| C11 | 52/52 · 52/52 |
| C15 | 17/17 · 17/17 |
| C16 | 16/16 · 16/16 |
| C17.3 | 11/11 · 11/11 |
| C18 | 17/17 · 17/17 |
| C9 (renderizado) | 66/66 |
| Cena principal | 0 erros de script |
| Legados | iguais à linha de base (limitações conhecidas inalteradas) |
| `tsc --noEmit` | limpo |

**Desempenho:**
- **Condições:**
  - na tomada (BatteryStatus 2), plano "Equilibrado";
  - Intel UHD Graphics, Forward+;
  - janela 1152×648, vsync ligado.
- **Pátio:** média de 16,61–16,66 ms em três pontos (300 quadros cada), travado no vsync (60 fps).
- **Forja 01 com o pátio** (sonda do C19, 1500 quadros, A/B alternado na mesma sessão):

| Rodada | Com o pátio | Sem o pátio |
|---|---|---|
| 1 | 17,59 ms | 17,21 ms |
| 2 | 17,02 ms | 16,92 ms |

- A diferença (+0,1 a +0,4 ms) fica dentro do ruído da máquina (±1 ms entre execuções) e dos 16,9–17,4 ms do C19.
- **Problema encontrado e corrigido:**
  - na primeira versão, o pátio era desenhado mesmo escondido sob o piso da Forja (não há oclusão);
  - o A/B mostrou +0,4 a +1,0 ms na Forja;
  - a decomposição por modo mostrou que o custo vinha da geometria; partículas, vida e sombra não mudavam nada;
  - correção: **desenho derivado da área**. O pátio só é desenhado no pátio ou perto do patamar; a talha fica sempre visível.
- **Execuções descartadas:** duas, em que a janela perdeu o foco e o vsync deixou de limitar (quadros de 6,9 ms). É o mesmo fenômeno do C19.
- **Recursos presos na saída:** o runner passou de 4 para 7. Uma sonda com e sem o pátio mostra **os mesmos** 3 WAV de áudio de Vardhelm presos. É pré-existente e cresce com o número de instâncias do slice nas suites. Não vem do C21.

**Playtest automatizado** (não humano):
- tudo que o C21 promete passou andando com input real: chegada, passagem, observações, vida, limites, Save/Load, retorno, Durn, Eco e reação;
- capturas pela câmera do jogador em [`c21_district/`](c21_district/).

## 11. Classificação para fechamento (A aceitável · B ajuste pequeno · C pendência relevante)

| Área | Classe | Observação |
|---|---|---|
| Identidade | A | pátio de fundição legível: base de tijolo da Forja 01 com a placa, trilho, carvão, talhas, doca, placa do distrito |
| Arquitetura | A | fechado por três lados, cortes ao sul e a leste, profundidade, colisão = geometria |
| Função | A | carvão chega, é descarregado, sobe e entra; doca; nada é cenário sem uso |
| Vida | **B** | 6 rotinas com carga; os trabalhadores não se viram na direção em que andam e os carrinhos não se movem (limites do AmbientLife atual) |
| Atmosfera | **B** | névoa, luz, lampiões, fumaça, vapor e poeira; o piso de pedra ainda lê como grade regular; o fundo (galpões e blocos) é simples |
| Narrativa ambiental | A | 3 observações descritivas e desgaste; a consequência reusa o C13; a função narrativa do distrito continua LACUNA de cânone (não é defeito) |
| Circulação | **B** | o pátio circula bem; o acesso ao patamar depende da folga **pré-existente** de 0,9 m entre a bancada e o respiro de brasas da Forja (jogador de 0,8 m) |
| Interação | A | E, prioridade e janela contextual do C18; trabalhadores não viram candidatos |
| Integração | A | mesma cena e cenário; observações no GameState, EventBus e sombra; Durn e Eco intactos |
| Save V2 | A | posição no pátio, observações, reação derivada; só `game_loaded`; nada transitório salvo; nada duplicado |
| Performance | A | pátio a 60 fps; Forja dentro do ruído depois do desenho derivado |
| Regressão | A | todas as suites na linha de base; recursos presos na saída são pré-existentes (áudio) |
| Playtest humano | **C** | **pendente**: o cenário não pode ser fechado sem ele |

**Pendências B** (ajustes pequenos, a decidir depois do teste humano):
1. trabalhadores virando para onde andam;
2. um carrinho em movimento no trilho;
3. variação no piso de pedra e fundo mais rico;
4. a folga do portão da Forja (se o teste humano achar apertada, deslocar a bancada exige mexer na Forja 01, o que precisa de aprovação).

**Pendência C:** teste humano.

## 12. Checklist de teste humano

1. Entrar no cenário: da Forja 01, passar pela folga do portão até o patamar e apertar E na talha ("Descer ao pátio").
2. Observar a arquitetura: base da Forja 01, fachada oeste, muros baixos, portão sul, talha. Dá para dizer "onde estou?"?
3. Caminhar: pátio inteiro; tentar sair pelos muros e pelo portão; passar entre carrinhos, pilhas e doca.
4. Interagir: E nos carrinhos, na talha de corrente e na porta da fundição.
5. NPCs: os trabalhadores não viram candidatos do E; o jogador não os atravessa.
6. Vida: rotinas (pá, carregadores, doca, talha de braço, carrinhos), fumaça, vapor e poeira.
7. Pontos de interesse: a placa "FORJA 01" na porta, a placa do distrito e os lampiões.
8. Salvar (Ctrl+S) no pátio.
9. Subir à Forja 01 e carregar (Ctrl+L): de volta ao pátio, na mesma posição.
10. Continuidade: falar com Durn, fazer o Eco, descer e olhar o respiro e a porta.
11. Retornar: subir de novo, andar pela Forja, conferir que a névoa e a luz da Forja voltaram.
12. Nada quebrado: C13–C18 (Durn, Eco, painel, folha do C16, dica do C18).

## 13. C21.1 — Correção de circulação entre a Forja 01 e o pátio

**Status:**
- correção aplicada e validada por testes automatizados;
- **novo teste humano pendente**; o C21 não está fechado;
- sem commit e sem push.

### 13.1 Problema (teste humano do C21)

O cenário foi considerado funcional e coerente, mas o jogador teve **bastante dificuldade para chegar à talha**, entre a Forja 01 e o pátio. O C21 já tinha registrado o ponto (§6 do documento do cenário e pendência B 4).

### 13.2 Inspeção (antes de qualquer mudança)

Método:
- sonda headless que lista todos os colisores da passagem, com a AABB de mundo;
- mapa de ocupação feito com a **cápsula real do jogador** (raio 0,40 m, altura 1,80 m: largura 0,80 m, como esperado), a cada 0,1 m.

| Pergunta | Resposta |
|---|---|
| Nós da passagem | `VardhelmSetDressing/WorkbenchTop` + `WorkbenchLeg_*` (bancada), `VP01_Vardhelm/Generated/Props/EmberVent` (respiro de brasas, cilindro de 1 m e 2,2 m de altura), `VardhelmSetDressing/SteamVent_01` (respiro de vapor baixo, 0,36 m), `CraneRunwayColumn_E`, `EntryPostL/R` (portão), `SouthWall_00/01`, `EntryRail_W/E/S` (patamar), guias da talha |
| Colisão invisível | **nenhuma**: todo corpo tem a própria malha |
| O que estreita o caminho | a **bancada**: 3,2 m de largura (x −1,6…1,6), bem no eixo do portão, 1,5 m à frente dele. A folga leste até o respiro de brasas era de 0,90 m físicos, o que deixava **0,10 m** para o centro da cápsula. A oeste, até a coluna da ponte rolante, a folga era de 0,63 m (impassável) |
| O respiro ocupa espaço demais? | não é o limitante. A simulação mostrou que movê-lo sozinho não abre nada. Mas o respiro de vapor baixo `SteamVent_01` **interpenetra** o respiro de brasas (pré-existente) e fecha o lado leste depois da bancada. O resultado era uma "agulha" **diagonal** de 0,1 a 0,2 m para o centro do jogador |
| Câmera | a linha jogador → câmera no meio da passagem não cruza nenhum objeto (sem oclusão); o respiro de brasas não esconde o jogador |
| Navegação e interação | a talha (`hoist_top`) no patamar é alcançável e a dica aparece; o problema era só chegar ao patamar |

**Simulação em memória** (mesma métrica, cápsula real) antes de editar:

| Opção | Faixa para o centro | Vão físico |
|---|---|---|
| atual | 0,10 m | 0,90 m |
| só o respiro de vapor 01 deslocado | 0,10 m | 0,90 m |
| **só a bancada 0,6 m a oeste** | **0,70 m** | **1,50 m** |
| bancada + vapor + brasas | 0,98 m | 1,78 m |

**Escolhida: só a bancada.** É um elemento só; a outra opção muda três. A bancada fica encostada na coluna, que já fechava o lado oeste. O caminho do início até o portão fica **reto**, ao lado da bancada.

### 13.3 Alteração

| Arquivo | Antes | Depois |
|---|---|---|
| `godot/scripts/vardhelm/vardhelm_set_dressing.gd` | `_create_workbench(Vector3(0.0, 0.0, 4.7))` | `_create_workbench(Vector3(-0.6, 0.0, 4.7))` (com comentário C21.1) |
| `godot/level_data/vardhelm_forge_01.json` | `WorkbenchStory` em `[0.0, 1.11, 4.7]` | `[-0.6, 1.11, 4.7]` (as ferramentas acompanham a bancada) |
| `godot/scenes/prototypes/vp_01_vardhelm.tscn` | — | **2 linhas**: o `transform` do `WorkbenchStory` e o `source_data_hash` do JSON. O rebake gerou `unique_id` novos em todos os nós; foram mantidos os antigos para o diff mostrar só a mudança real |

**Preservado:**
- respiro de brasas, respiro de vapor, portão, patamar, guarda-corpos, talha;
- máquinas, rotas, Durn, Eco, painel, folha, diálogos, interações;
- todo o pátio (30 × 25 m, trabalhadores, carrinhos, carvão, talha de braço, doca, portão, fundição vizinha, atmosfera, névoa, luz, observações), GameState, EventBus, Save V2 e transição;
- nenhuma luz, partícula ou geometria nova.

**Pré-existente, não corrigido:** o respiro de vapor 01 continua interpenetrando o respiro de brasas. Não atrapalha mais a passagem, que agora corre a oeste dele.

### 13.4 Resultado geométrico

| | Antes | Depois |
|---|---|---|
| Vão físico bancada ↔ respiro de brasas | 0,90 m | **1,50 m** |
| Faixa livre para o centro do jogador | 0,10 m (agulha diagonal) | **0,70 m**, reta no sentido do portão |
| Lado oeste (bancada ↔ coluna) | 0,63 m (impassável) | fechado (bancada encostada na coluna) |

### 13.5 Testes

Novo playtest `tests/save_v2/c21_1_passage_playtest.gd`:
- só andando, sem teleporte e **sem desvio automático** (qualquer bloqueio conta como travamento);
- o vão medido;
- atravessar em linha reta entrando por três pontos (x 1,45 / 1,70 / 1,95);
- o ciclo completo **duas vezes**: Forja → passagem → portão → patamar → talha → pátio → talha → patamar → passagem → Forja;
- zero travamentos;
- dica da talha nos dois sentidos;
- Save/Load na Forja (na própria passagem) e no pátio (posição, rotação, área, observação);
- trabalhadores, câmera e áudio iguais.

**Controle negativo:** o mesmo teste, rodado com a Forja antiga (bancada em x 0), **falha em 7 de 16 checks**: o vão medido é de 0,90 m, duas das três entradas em linha reta ficam presas, o retorno pela passagem falha nos dois ciclos e o andador trava 11 vezes.

Resultados da bateria: §13.6.

### 13.6 Resultados

Bateria completa guardada, com os saves reais intactos:

| Suite | Resultado |
|---|---|
| Runner | **1694/1694** (C21: 42/42) |
| Playtest C21.1 (passagem) | **16/16** renderizado · **16/16** headless |
| Playtest C21 | 25/25 · 25/25 |
| C11 | headless 52/52 · renderizado: ver abaixo |
| C15 | 17/17 · 17/17 |
| C16 | 16/16 · 16/16 |
| C17.3 | 11/11 · 11/11 |
| C18 | 17/17 · 17/17 |
| C9 (renderizado) | 66/66 |
| Cena principal / legados / `tsc` | 0 erros / iguais à linha de base / limpo |

- **C11 renderizado:** na bateria, 37/52.
  - A cascata começou num **clique de mouse numa escolha de diálogo do C12** que não foi registrado (dependência de foco da janela no modo renderizado).
  - Não tem relação com a passagem: o andador do C11 não passa pela bancada, e o C11 headless da mesma bateria deu 52/52.
  - Rodado de novo sozinho, **duas vezes: 52/52 e 52/52**.

**Desempenho** (na tomada, Intel UHD, Forward+, 1152×648, vsync):

| Medição | C21.1 | C21 |
|---|---|---|
| Pátio | 16,65 ms (3 pontos) | 16,61–16,66 ms |
| Forja 01 (sonda do pátio) | 16,64–17,52 ms | 16,9–17,4 ms |
| Forja 01 (sonda do C19, 1500 quadros) | 17,26 ms nas duas execuções | 17,0–17,6 ms |

Nenhum custo novo: nada foi acrescentado, só um objeto mudou de lugar.

### 13.7 Pendências

- **Circulação:** A no teste automatizado. **Aguarda o novo teste humano** (é ele que decide se "confortável" foi atingido).
- As pendências B do C21 continuam como estavam (trabalhadores não se viram, carrinhos parados, piso e fundo simples). O C21.1 não as tocou, por ser correção cirúrgica.
- Pré-existente e registrado: o respiro de vapor 01 interpenetra o respiro de brasas.
- **O C21 não está fechado:** falta o novo teste humano.

### 13.8 Checklist do novo teste humano (C21.1)

1. Começar na Forja 01 e ir até o portão sem pensar no caminho. A passagem ao lado da bancada se acha sozinha?
2. Atravessar ao lado da bancada várias vezes, entrando por pontos diferentes: não pode haver raspão, parada nem necessidade de mirar.
3. Chegar ao patamar e ver "E • Descer ao pátio"; apertar E.
4. No pátio, ver "E • Subir à Forja 01"; apertar E.
5. Voltar do patamar para dentro da Forja pela mesma passagem.
6. Repetir o ciclo inteiro pelo menos duas vezes, nos dois sentidos.
7. Salvar dentro da Forja, perto da passagem; andar; carregar: mesma posição e direção.
8. Salvar no pátio; subir; carregar: de volta ao pátio.
9. Conferir que a Forja continua igual: Durn, Eco, painel, folha (C16), dica do C18 e a bancada no novo lugar (ainda parece a mesma bancada).
10. Conferir o pátio: trabalhadores, carrinhos, fumaça, observações, câmera e áudio.

### 13.9 Complemento do C21.1 (segunda passada: inspeção ampliada, leitura do acesso, testes)

**Inspeção complementar** (sonda headless, cápsula real):

| Verificação | Resultado |
|---|---|
| Chegada da talha no pátio (0, −11,65, 12,75) | a cápsula cabe: 0 colisões |
| Chegada da talha no patamar (0, 0,25, 9,2) | a cápsula cabe: 0 colisões |
| Área da dica (detector 2,5 m + área da talha 0,8 m) | a dica aparece até **3,17 m** de cada estação. Em cima, cobre o patamar inteiro: aparece ao cruzar o portão (z ≈ 6,4). Embaixo, cobre a frente da gaiola. Não é preciso procurar um ponto exato |
| Trabalhadores × caminho principal | os mais próximos são `worker_bench_01` (Forja), a 1,97 m do caminho, com 1,32 m entre os corpos, e `worker_district_hauler_02` (pátio), a 2,11 m, com 1,46 m. Os outros estão a mais de 2,5 m. Nenhum bloqueia; **nenhuma rota foi alterada** |
| `TransitionPoint` | destino, chegada e volta imediata corretos. Movimento relativo à câmera: a rotação do jogador não interfere |
| Colisões | nenhuma alteração de `CollisionShape` foi necessária (nenhuma indevida, nenhuma excessiva) |

**Leitura visual do acesso:**
- Duas linhas finas de tinta no piso (`PassageLine_West/East`, x 1,10 e 1,95, de z 3,6 a 6,75) marcam a faixa ao lado da bancada até o portão.
- É a mesma tinta das marcas de piso que a Forja já tem (`FloorMark`, `SafetyLine`, `#687178`), sem colisão.
- Sem luz nova, sem texto, sem seta, sem ciano.
- Com o pórtico da talha visível desde o início, o caminho se lê pela própria arquitetura.

**Playtest `c21_1_passage_playtest.gd` ampliado para 24 checks**, só andando:
- o jogador nunca chega nem carrega dentro de colisão;
- Save/Load **colado à talha** embaixo e em cima, depois andar e usar a talha na hora;
- **volta imediata** (descer e subir sem sair do lugar);
- a dica aparece ao cruzar o portão;
- na faixa, no portão e no patamar nenhuma outra interação vira candidata;
- o suporte de ferramentas ao lado da bancada continua examinável;
- **antes e depois do Primeiro Eco** (Durn → Eco → passagem de novo);
- 0 travamentos nas caminhadas da passagem;
- o ciclo inteiro com os trabalhadores ativos.

**Duas correções no próprio teste:**
- o ponto da dica passou para a entrada do patamar, porque na linha do portão ela ainda não aparece;
- a gravação de candidatos ficou restrita à faixa, ao portão e ao patamar, porque no ponto de início o suporte de ferramentas sempre foi candidato, desde antes do C21.

### 13.10 Resultados da segunda passada

| Suite | Resultado |
|---|---|
| Runner | **1694/1694** |
| C21.1 (passagem) | **24/24** renderizado · **24/24** headless |
| C21 | 25/25 · 25/25 |
| C11 | 52/52 · 52/52 |
| C16 | 16/16 · 16/16 |
| C17.3 | 11/11 · 11/11 |
| C18 | 17/17 · 17/17 |
| C9 (renderizado) | 66/66 |
| C15 | headless 17/17 · renderizado: ver abaixo |
| Cena principal / legados / `tsc` | 0 erros / iguais à linha de base / limpo |

- **C15 renderizado:** na bateria, 7/17.
  - A cascata começou no **clique de mouse na escolha "Não senti nada."**, que não foi registrado (dependência de foco da janela). É o mesmo fenômeno do C11 renderizado na primeira passada.
  - Rodado de novo sozinho, **duas vezes: 17/17 e 17/17**.
  - Fica como pendência do **harness de teste** (cliques de mouse nos playtests renderizados), não do jogo.

**Desempenho:**
- Nesta passada a máquina estava **na bateria** (BatteryStatus 1, 78%, "Equilibrado"). A GPU fica limitada em cerca de 25 ms por quadro (40 fps) em tudo.
- A/B alternado na mesma sessão, sonda do C19, 1500 quadros:

| Rodada | C21.1 | C21 (bancada antiga, sem linhas) |
|---|---|---|
| 1 | 24,99 ms | 24,99 ms |
| 2 | 24,99 ms | 24,99 ms |

- O limite da bateria pode esconder diferenças pequenas. A referência na tomada é a da primeira passada (Forja 17,26 ms, igual ao C21).
- As linhas de piso são 2 malhas pequenas, sem colisão nem luz.

### 13.11 Checklist humano final (substitui o §13.8)

**Critério:** "o acesso parece natural e confortável e não exige precisão excessiva".

- **A.** Forja → passagem ao lado da bancada (linhas no piso) → portão → patamar → E na talha → pátio.
- **B.** Pátio → E na talha → patamar → portão → passagem → dentro da Forja.
- **C.** Repetir A e B algumas vezes, sem procurar o ponto certo, entrando pela faixa em lugares diferentes.
- **D.** Fazer o Primeiro Eco (falar com Durn e ir ao Eco) e repetir A e B.
- **E.** Salvar no pátio → carregar → voltar à Forja pela talha.
- **F.** Salvar na Forja (inclusive no patamar, colado à talha) → carregar → descer de novo.
- **Olhar também:** se a bancada no novo lugar e as linhas no piso parecem da Forja (não de um tutorial), e se Durn, Eco, painel, folha (C16) e a dica do C18 seguem iguais.
