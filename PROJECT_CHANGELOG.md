# 📜 AETHERIS — LOG DE EVOLUÇÃO E ARQUITETURA DO PROJETO

> **Regra de Manutenção:** Este arquivo DEVE ser atualizado a cada nova sprint, funcionalidade, refatoração ou consolidação de código realizada no projeto.

---

## 📊 Resumo do Estado do Sistema
- **Balança de Estafa:** Integrated (Combat, Dialogue, Campaign) — mecânica-core em [`src/mechanics/EstafaCalculator.ts`](src/mechanics/EstafaCalculator.ts)
- **Sistema de Diálogos:** Integrated (Locks Diegéticos + ramificação por Estafa)
- **Equipamentos e Sucata:** Integrated (Durabilidade, Rusted, Repair)
- **Navegação de Campanha:** Integrated (Recursos, Hazard, Crise, Reabastecimento)
- **Status Engine Tático:** Integrated (Poison, Burn, Rust Lock, Spark)
- **Gerenciador de Saves:** Integrated (4 Slots, Checksum SHA-256, AutoSave, XP + Habilidades + Árvore persistidos)
- **Bestiário e Inimigos:** Integrated (Encontros por Hazard, IA Tática, Drop Tables)
- **Combat Loop Engine:** Integrated (Turn-Based, Status, Speed Order)
- **Combate Interativo:** Integrated (Ações gated pela Estafa + feedback loop)
- **Progressão & Recompensas:** Integrated (Sucata, Drops, XP, Level-Up, Stat Scaling DRF)
- **Habilidades de Combate:** Integrated (EP, Cooldown, Status, Gating por Estafa)
- **Mercadores & Economia:** Integrated (Comprar Mantimentos, Reparo, Itens por Sucata)
- **Sistema de Missões:** Integrated (Main/Side, Gatilhos de Nó/Combate/Diálogo, Recompensas, Persistência)
- **Acampamento & Grupo:** Integrated (Descanso HP/EP, Reparo de Campo, Formação, Conversa de Estafa)
- **Anomalias de Duto:** Integrated (Gás Químico, Vapor, Surto Elétrico; mitigação por recurso/risco)
- **Interface CLI:** GameLoop v2.0 (Menu, HUD+Missão, Combate, Habilidades, Diálogo, Mercador, Acampamento, Diário, Game Over)
- **Conteúdo:** Ato 2 (Profundezas de Brenhold) + 9 templates de inimigos
- **Assets & Visuais:** Git LFS (.gitattributes, Portraits, Spritesheets)
- **Save V2 (Godot):** Blocos C1–C10.5 — **V2 é o caminho padrão desde o C10.5** (Ctrl+S/Ctrl+L só V2; legado só com flags OFF explícitas); endurecimento no C10 (câmera/UI/mensagens/Durn; migração OPT-IN decidida e não implementada; checklist humano pronto, não executado); prontidão de adoção medida no C9; ciclo Save V2 + Load V2 operacional opt-in desde o C8 (flags de save e load OFF por padrão); Load V2 operacional desde o C7 (flag OFF por padrão; rehearsal + snapshot + rollback; Ctrl+L antigo continua o padrão e o caminho legado); modo sombra; desde o C2 roda em paralelo no Ctrl+S/Ctrl+L reais, depois do SaveService (que segue operacional), só gravando e comparando; C3–C5 restauram GameState → runtime apenas em diagnóstico/sandbox, com adapters sobre contratos formais (DialogueRuntimeState, RuntimeStateDerivationContract); C6 prova o pipeline arquivo → sandbox (SaveV2DiagnosticCoordinator, flag OFF por padrão, failure policy) ([`docs/architecture/BLOCK_C1_SAVE_V2_SHADOW.md`](docs/architecture/BLOCK_C1_SAVE_V2_SHADOW.md))
- **Narrativa de Vardhelm (Godot):** Bloco C12 — ponte pós-Primeiro Eco: Durn reage uma vez sem explicar, pista do painel selado e investigação curta `vardhelm_sealed_panel`; persistida pelo Save/Load V2 ([`docs/architecture/BLOCK_C12_POST_ECHO_BRIDGE.md`](docs/architecture/BLOCK_C12_POST_ECHO_BRIDGE.md)); Bloco C13 — o mundo reage ao Eco sem avisar (luz fria sobre o painel, trabalhador fora da rotina, máquinas mais baixas), derivado de `echo_awakened` ([`docs/architecture/BLOCK_C13_LIVING_VARDHELM.md`](docs/architecture/BLOCK_C13_LIVING_VARDHELM.md)); Bloco C14 — primeira sequência completa: encerramento em silêncio ao examinar o painel e gancho na fala final de Durn ("Então não fui só eu."); validado em teste humano ([`docs/architecture/BLOCK_C14_FIRST_SEQUENCE.md`](docs/architecture/BLOCK_C14_FIRST_SEQUENCE.md)); Bloco C15 — primeira escolha com consequência perceptível: "Não senti nada." faz Durn ir sozinho até onde o Eco aconteceu, validado em teste humano ([`docs/architecture/BLOCK_C15_CHOICE_CONSEQUENCE.md`](docs/architecture/BLOCK_C15_CHOICE_CONSEQUENCE.md)); Bloco C16 — a mesma escolha abre uma possibilidade futura: no lugar vazio de Durn fica uma folha que pode ser examinada; validado em teste humano ([`docs/architecture/BLOCK_C16_FUTURE_POSSIBILITY.md`](docs/architecture/BLOCK_C16_FUTURE_POSSIBILITY.md)); Bloco C17 — a baia oeste da Forja 01 construída: tijolo e ferro, paredes em corte no sul e leste, entrada aberta, painel num anteparo, cidade abaixo, luz de cima e forja como foco quente ([`docs/architecture/BLOCK_C17_VISUAL_SLICE.md`](docs/architecture/BLOCK_C17_VISUAL_SLICE.md)); C17.1–C17.3 (densidade, identidade, colisão dos trabalhadores); validados em teste humano; Bloco C18 — a dica "E • …" ganhou ciclo de vida (entra suave, espera 0,75 s ao sair, volta sem piscar), componente genérico `ContextualWindowLifecycle` ([`docs/architecture/BLOCK_C18_CONTEXTUAL_WINDOWS.md`](docs/architecture/BLOCK_C18_CONTEXTUAL_WINDOWS.md)); validado em teste humano; **Bloco C19 — auditoria de fechamento: a Forja de Vardhelm é CANDIDATA A FECHAMENTO** (sem pendência real; itens provisórios e futuros registrados) ([`docs/architecture/BLOCK_C19_FORGE_CLOSING_AUDIT.md`](docs/architecture/BLOCK_C19_FORGE_CLOSING_AUDIT.md)); **Bloco C20 — padrão de produção para os próximos cenários** (regra CONCEITO → … → ACABAMENTO, modelo e checklists; próximo cenário ainda não definido no material canônico) ([`docs/architecture/SCENARIO_PRODUCTION_STANDARD.md`](docs/architecture/SCENARIO_PRODUCTION_STANDARD.md)); **Bloco C21 — Distrito das Fundições** (pátio sob a Forja 01, ligado pela talha; vida, atmosfera, 3 observações, reação derivada do C13; Save V2), escolhido por evidência documental; C21.1 abriu a passagem entre a Forja e a talha (bancada 0,6 m a oeste: vão de 0,9 → 1,5 m); **C21 e C21.1 validados em teste humano (fechados)**; **Bloco C22** — mapa de produção de Vardhelm, arco além do gancho não definido, decisões D1–D7 com o usuário ([`docs/architecture/BLOCK_C22_VARDHELM_WORLD_MAP.md`](docs/architecture/BLOCK_C22_VARDHELM_WORLD_MAP.md)); **Bloco C22.1** — cânone do Ato 1 consolidado (Primeiro Eco como evento incitante, investigação, Elyra no Ato 1, combate com função, nível 10 não rígido, matriz de revelação) ([`docs/lore/VARDHELM_ACT1_CANON.md`](docs/lore/VARDHELM_ACT1_CANON.md)); **Bloco C23** — rua do Distrito das Fundições pelo portão sul aberto (Fase 4, abertura do mundo; 12 trabalhadores, 4 observações; teste humano pendente) ([`docs/scenarios/vardhelm_foundry_street.md`](docs/scenarios/vardhelm_foundry_street.md)); **Bloco C24** — design da investigação (Fase 5) até o encontro com Elyra, só documentação; **C24.1** — decisões H1–H5, H7 (conceito) e H8 registradas, H6 aberto, H9 reservado; checkpoint local C22–C24 ([`docs/03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md`](docs/03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md)) ([`docs/scenarios/vardhelm_foundry_district.md`](docs/scenarios/vardhelm_foundry_district.md))
- **Eventos estruturados (Godot):** Bloco B1 — `GameEventBus` de runtime (sem Autoload) alimentado por `GameplayEventPublisher`; não controla gameplay ([`docs/architecture/BLOCK_B1_STRUCTURED_EVENTS.md`](docs/architecture/BLOCK_B1_STRUCTURED_EVENTS.md))
- **GameState canônico (Godot):** Modo sombra (Bloco A3) — acompanha Vardhelm em runtime via `GameStateShadowRecorder` (consumidor de eventos desde o B1), sem ser fonte de verdade e sem Save/Load ([`docs/architecture/BLOCK_A3_SHADOW_GAME_STATE.md`](docs/architecture/BLOCK_A3_SHADOW_GAME_STATE.md)); contratos do A2 em `godot/scripts/state/` ([`docs/architecture/BLOCK_A1_CANONICAL_GAME_STATE.md`](docs/architecture/BLOCK_A1_CANONICAL_GAME_STATE.md))

**Stack:** TypeScript (strict) · execução de testes via `tsx` (harness nativo por suite) · `tsc --noEmit` como build/type-check.

---

## 🗓️ Histórico de Entregas & Modificações

### [2026-10-01] — Bloco C24.1: Checkpoint local C22–C24 + decisões humanas H1–H9 (HEAD)
- **Commit local** (sem push) consolidando o C22 (mapa de Vardhelm), o C22.1 (cânone do Ato 1), o C23 (rua do Distrito das Fundições) e o C24 (design da investigação). É um **estado técnico recuperável**, não aprovação artística. **C23: tecnicamente aprovado, teste humano ainda pendente. C24: design documentado, decisões humanas em consolidação.**
- **Decisões humanas registradas (só documentação):**
  - **H1:** painel fechado durante a investigação, aberto ou rompido no clímax, com revelação material sem cosmologia.
  - **H2:** Durn fica na Forja e deixa aos poucos de ser o motor; clímax não definido.
  - **H3:** o Galpão guarda o histórico operacional do reforço/selamento.
  - **H4:** Elyra investiga o que existia antes das fundições.
  - **H5:** "Véu" ainda não é introduzido.
  - **H6:** conflito NÃO DEFINIDO (K-4 candidata).
  - **H7:** verdade parcial aprovada como conceito; quem, por quê e o quê ficam em aberto.
  - **H8:** progressão narrativa, não relógio.
  - **H9:** ponte Arqueóloga ↔ Arconte reservada.
- **Documentos atualizados:** [`VARDHELM_INVESTIGATION_DESIGN.md`](docs/03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md) (tabela de decisões no topo e marcas "→ H#"), [`BLOCK_C24_VARDHELM_INVESTIGATION.md`](docs/architecture/BLOCK_C24_VARDHELM_INVESTIGATION.md) §5.1, [`VARDHELM_ACT1_CANON.md`](docs/lore/VARDHELM_ACT1_CANON.md) §5/§14, [`vardhelm_world_map.md`](docs/scenarios/vardhelm_world_map.md).
- **UID:** `godot/tests/save_v2/c21_1_passage_playtest.gd.uid` incluído. É o UID gerado pelo Godot para o script versionado `c21_1_passage_playtest.gd` (`uid://cibmtij27ua3w`, único no projeto); o repositório já versiona os `.uid` dos outros playtests.
- **Testes antes do commit:**
  - `npx tsc --noEmit` exit 0;
  - runner 1732/1732 (11 SCRIPT ERROR conhecidos de `memories/save_service.gd:44`, caminho legado);
  - cena principal com 0 erros;
  - testes legados iguais ao baseline;
  - sonda A0 com a mesma diferença conhecida do baseline do C4 (textos e trabalhadores alterados em blocos anteriores).
  - Playtests, todos renderizado e headless: C11 52/52, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17, C21 25/25, C21.1 24/24, C23 16/16.
  - C9 renderizado 66/66.
  - Saves reais intactos.
- Nenhum gameplay alterado no C24.1. C25 não iniciado.

### [2026-10-01] — Bloco C24: Design da investigação de Vardhelm — do Primeiro Eco ao encontro com Elyra (documentação)
- **Somente documentação.** Nenhum .gd, .tscn, dado de gameplay, localização, quest ou NPC alterado. C23 continua tecnicamente aprovado e aguardando fechamento humano/artístico.
- **Criados:**
  - [`VARDHELM_INVESTIGATION_DESIGN.md`](docs/03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md): especificação da Fase 5. Fica em `docs/03_narrativa/` (a pasta de narrativa que já existe) em vez de criar `docs/narrative/`.
  - [`BLOCK_C24_VARDHELM_INVESTIGATION.md`](docs/architecture/BLOCK_C24_VARDHELM_INVESTIGATION.md): registro do bloco, decisões humanas H1–H9 e blocos C25–C30 propostos.
- **Design:** a investigação reaproveita consequências que já estão no jogo, sem fenômeno novo:
  - os **horários** (folha de Durn ou relato, conforme a escolha do C15; quadro de manutenção; turnos da rua);
  - o painel **reforçado** e a Forja 01 mais baixa que as outras fundições.
- **Escalada proposta:** incidente → anomalia → registro → padrão → origem do selo (Galpão de Manufatura) → cruzamento com Elyra no mesmo registro → "já aconteceu antes e foi calado" → conflito.
- **Recomendações:** painel fechado até o clímax; Durn como testemunha que não explica; "Véu" só na boca de Elyra, sem definição; conflito K-4. Cada decisão tem classe A–E; as propostas (C) **não** viraram cânone.
- **Atualizados:** `VARDHELM_ACT1_CANON.md` (§5 e §14, como proposta), `vardhelm_world_map.md` (fluxo das Fases 5–7, Galpão).
- **Testes:** nenhum executado (bloco de documentação); nenhum teste humano alegado.

### [2026-10-01] — Bloco C23: Rua do Distrito das Fundições — Vardhelm como cidade (Godot)
- **Função (Fase 4 do Ato 1):** a transição entre o microcosmo da Forja e Vardhelm como cidade; normalidade primeiro; prepara a investigação sem resolvê-la ([`BLOCK_C23_FOUNDRY_STREET.md`](docs/architecture/BLOCK_C23_FOUNDRY_STREET.md), [`vardhelm_foundry_street.md`](docs/scenarios/vardhelm_foundry_street.md)).
- **Construído:** rua de serviço de 56 × 15 m (`vardhelm_foundry_street_01.json` → `vp_03_vardhelm_foundry_street.tscn`), saindo **andando pelo portão sul do pátio**, agora aberto com as folhas para dentro.
  - Norte: fachada da fundição oeste (porta, quadro de turnos) e armazém leste (doca, talha de braço com carga subindo e descendo).
  - Piso: o ramal do pátio encontra a linha da rua; vagões de minério.
  - Sul: corredor ferroviário com trem de carga.
  - Oeste: cancela; a rua continua na névoa.
  - 12 trabalhadores anônimos: 7 andando virados para onde vão, 5 parados com função.
  - 4 observações curtas; o portão tem texto pós-Eco que repete o fato do C13 visto de fora ("a Forja 01 soa mais baixa que as outras fundições").
- **Compartilhado:**
  - AmbientLife: 3 opções **opcionais** (`face_movement`, `facing_degrees`, `carry_offset`); Forja e pátio idênticos;
  - controlador do distrito: `extra_levels`, `extra_lives`, `observation_roots()`, `life_named()`, `animations`;
  - slice: raízes de observação do distrito;
  - 4 IDs de observação;
  - pátio: portão aberto, trilho até o portão, fundo sul removido; `vp_02` re-assada com `unique_id` preservados;
  - 3 checks de contagem do C21 adaptados aos itens do pátio e à config.
- **Sem:** Elyra, combate, NPC nomeado, quest, diálogo, segundo Eco, lore profundo.
- **Corrigido durante o bloco** (achado do playtest): as folhas do portão, abertas para fora, avançavam 2,85 m sobre a calçada e travavam quem andava junto ao muro. Passaram a abrir para dentro do pátio.
- **Testes:**
  - runner **1732/1732** (C23 38/38); playtest novo `c23_foundry_street_playtest.gd` **16/16** renderizado e headless (larguras reais: portão 5,85 m, rua 9,15–14,8 m);
  - C21.1 24/24; C21 25/25; C11 52/52; C15 17/17; C16 16/16; C17.3 11/11; C18 17/17 (renderizado e headless); C9 66/66;
  - cena principal sem erros; legados iguais; saves reais intactos; `tsc` limpo.
- **Desempenho (na tomada):** rua 16,6–17,0 ms; pátio 16,65 ms; Forja (sonda do C19) 17,37–17,52 ms (C21.1: 17,26 ms). A rua tem 217 malhas e 17 corpos.
- **Pendências:**
  - B: cruzamentos ocasionais de pedestres; primeira perna das rotas no AmbientLife (resolvida por dados na rua);
  - C: sensação de cidade maior e ocupação (**teste humano pendente**).
- **Sem commit, sem push.**

### [2026-10-01] — Bloco C22.1: Consolidação canônica do arco de Vardhelm — Ato 1
- **Documental**, sem gameplay: as decisões humanas D1–D7 sobre o relatório do C22 foram formalizadas.
- **Novos:**
  - [`docs/lore/VARDHELM_ACT1_CANON.md`](docs/lore/VARDHELM_ACT1_CANON.md): referência canônica do Ato 1, com a origem de cada item ([DH] decisão humana, [HIST+DH] material histórico, [DOC] documento, [IMPL] implementado);
  - [`docs/lore/LORE_REVELATION_MATRIX.md`](docs/lore/LORE_REVELATION_MATRIX.md): camadas de revelação, verdade fragmentada entre os povos, Lurídeos.
- **Decisões formalizadas:**
  - o **Primeiro Eco é o evento incitante** e cria a pergunta, sem entregar a resposta;
  - depois do gancho começa uma **investigação em Vardhelm**;
  - **Elyra participa do Ato 1** como arqueóloga élfica com conhecimento incompleto, sem revelar a linhagem (Ato 4);
  - Durn segue como primeiro vínculo local, com o futuro NÃO DEFINIDO;
  - **haverá combate no Ato 1**, só com função narrativa;
  - o **nível 10 não é condição rígida** de saída;
  - clímax, conclusão e transição são obrigatórios; a forma da viagem fica para depois;
  - só áreas com função entram; Brenhold foi **adiado**;
  - Kael (Draconiano) fica reservado ao Ato 2;
  - Aethel, Asterion (civilização, não deus), Homem Cinzento e Último Experimento ficam na camada 3;
  - "Véu" só aparece com justificativa do personagem;
  - estrutura macro em **10 fases**;
  - o C23 (rua do distrito) é a transição da Forja para a cidade.
- **Preservados:**
  - contradições: Brenhold; nível 10 × runtime;
  - pontos a conciliar: "arqueóloga élfica" × "Última Arconte Rúnica"; Kael no Ato 2 × documentação do Ato 4.
- **Atualizados:** `BLOCK_C22_VARDHELM_WORLD_MAP.md` (§14) e `vardhelm_world_map.md` (fluxo por fases).
- **Local escolhido para o lore:** `docs/lore/`, como pedido. `DOCUMENTACAO/` é um esqueleto `CANON_LOCKED` vazio, `docs/03_narrativa` guarda eventos individuais e `docs/01_cenario` guarda a bíblia racial travada.
- **Sem commit, sem push.** C22 e C22.1 continuam no working tree; HEAD `b01da03`.

### [2026-10-01] — Bloco C22: Mapa de produção e continuidade do contexto de Vardhelm
- **Contexto:** C21 e C21.1 **fechados**; o teste humano confirmou o acesso confortável entre a Forja 01 e o pátio.
- **Documental:** auditoria, mapeamento e planejamento. Nenhum gameplay alterado; nenhuma área, NPC, quest, diálogo, memória, Eco ou consequência criado.
- **Novos:**
  - [`BLOCK_C22_VARDHELM_WORLD_MAP.md`](docs/architecture/BLOCK_C22_VARDHELM_WORLD_MAP.md): estado atual, fontes, classificação A–E, Durn, Elyra, Primeiro Eco, saída do Ato 1, definição de "Vardhelm completa" (V1–V12), backlog, candidato a C23, decisões D1–D7;
  - [`vardhelm_world_map.md`](docs/scenarios/vardhelm_world_map.md): mapa conceitual, locais e fluxo 🟢/🟡/⚪.
- **Achados:**
  - o arco de Vardhelm depois do gancho "Então não fui só eu." **não está definido** no repositório;
  - Durn só existe no slice (sem futuro documentado);
  - Elyra só aparece nos Atos 4 e 5 (Avatar, "Última Arconte Rúnica", escolha final); a associação dela com o Ato 1 é material histórico **fora do repositório**;
  - a saída do Ato 1 é `EVT_TRANSICAO_ATO1_ATO2` no **nível 10** (documentos de sistema), mas o slice Godot não tem níveis nem combate (contradição registrada);
  - Aethel, Asterion e Homem Cinzento não aparecem em nenhum arquivo.
- **Candidato técnico ao C23:** a rua do Distrito das Fundições, além do portão sul do pátio (TIER1 §1.4.1). **Recomendação: não construir antes da decisão D1.**
- **Refinamento UX registrado (não corrigido):** a janela de observação (660 × 300 px fixos) é grande demais para textos curtos.
- **Git:** HEAD `b01da03` local, sem push; C22 não commitado.

### [2026-09-30] — Bloco C21.1: Correção de circulação entre a Forja 01 e o pátio (Godot)
- **Problema (teste humano do C21):** o jogador teve bastante dificuldade para chegar à talha.
- **Causa (inspeção com a cápsula real do jogador, 0,80 m de largura):**
  - a **bancada** (3,2 m, no eixo do portão, 1,5 m à frente dele) deixava só 0,90 m até o respiro de brasas, ou seja, **0,10 m** livres para o centro do jogador;
  - o lado oeste (0,63 m até a coluna) era impassável;
  - o respiro de vapor baixo, que interpenetra o respiro de brasas (pré-existente), fazia do acesso uma agulha diagonal;
  - não havia colisão invisível nem oclusão de câmera no caminho.
- **Correção (um elemento, escolhido por simulação em memória):**
  - a bancada e as ferramentas sobre ela foram **0,6 m para oeste**: `vardhelm_set_dressing.gd` (1 linha) e `WorkbenchStory` em `vardhelm_forge_01.json` (1 linha);
  - a cena `vp_01_vardhelm.tscn` foi re-assada, mantendo o diff em 2 linhas (transform e hash dos dados);
  - resultado: vão de **1,50 m**, **0,70 m** livres para o centro do jogador, caminho reto até o portão;
  - nenhuma luz, partícula ou geometria nova; respiros, portão, patamar, talha, pátio, Durn, Eco, painel e folha intactos.
- **Testes:**
  - playtest novo `c21_1_passage_playtest.gd` (só andando, sem desvio automático) **16/16** renderizado e headless: vão medido, travessia reta por 3 entradas, ciclo completo 2 vezes nos dois sentidos, 0 travamentos, dica da talha, Save/Load na Forja e no pátio, trabalhadores, câmera e áudio;
  - controle negativo: com a bancada antiga, o mesmo teste falha 7 de 16 checks;
  - runner 1694/1694; C21 25/25; C15 17/17; C16 16/16; C17.3 11/11; C18 17/17; C9 66/66; C11 headless 52/52;
  - C11 renderizado: 37/52 na bateria, por um clique de diálogo não registrado; rodado de novo sozinho, 52/52 duas vezes;
  - cena principal sem erros; legados iguais; saves reais intactos; `tsc` limpo.
- **Desempenho:** igual ao C21 (pátio 16,65 ms; Forja 16,6–17,5 ms; sonda do C19 17,26 ms).
- **Segunda passada (prompt do C21.1 ampliado):**
  - inspeção complementar: as chegadas da talha não ficam em colisão; a dica aparece a até 3,17 m de cada estação (o patamar inteiro); nenhum trabalhador bloqueia o caminho (o mais próximo a 1,97 m); nenhuma `CollisionShape` ou rota alterada; `TransitionPoint` correto;
  - **leitura do acesso:** duas linhas finas de tinta no piso marcam a faixa até o portão (`PassageLine_West/East` em `vardhelm_set_dressing.gd`, mesma tinta das marcas existentes, sem colisão);
  - playtest da passagem ampliado para **24/24** renderizado e headless: sem colisão ao chegar ou carregar; Save/Load colado à talha em cima e embaixo; volta imediata; dica ao cruzar o portão; nenhuma outra interação no caminho; suporte de ferramentas; **antes e depois do Primeiro Eco**; 0 travamentos;
  - regra de circulação registrada no `SCENARIO_PRODUCTION_STANDARD.md` (§6 e §11): rotas obrigatórias medidas com a cápsula real, vão de pelo menos 1,5 m;
  - bateria: runner 1694/1694; C21 25/25; C11 52/52 e 52/52; C16 16/16; C17.3 11/11; C18 17/17; C9 66/66; C15 headless 17/17;
  - C15 renderizado: 7/17 na bateria, por um clique de diálogo não registrado; rodado de novo sozinho, 17/17 duas vezes (pendência do harness);
  - `tsc` limpo;
  - desempenho: na bateria, C21.1 = C21 (24,99 ms nas duas versões, limite de 40 fps da bateria); referência na tomada da primeira passada: 17,26 ms.
- **Aguarda novo teste humano; o C21 não está fechado.** Checklist final em `BLOCK_C21_NEXT_SCENARIO.md` §13.11.

### [2026-09-30] — Bloco C21: Próximo cenário — Distrito das Fundições, pátio da Forja 01 (Godot)
- **Escolha, por evidência** ([`BLOCK_C21_NEXT_SCENARIO.md`](docs/architecture/BLOCK_C21_NEXT_SCENARIO.md)):
  - o **Distrito das Fundições** de Vardhelm (Ato 1) é o único candidato com lugar, função, ocupação e atmosfera sustentados por duas fontes (`ART-PROMPTS-TIER1` §1.1/§1.4.1 e `TIER3` §2.3.3);
  - o Galpão repetiria a Forja; Ostrell só tem economia e progressão;
  - Brenhold tem **contradição de Ato** (2 no CLI e neste resumo × 3 nos documentos de sistema), registrada e não resolvida;
  - recorte (decisão de produção, não cânone): o pátio **sob a Forja 01**, na "cidade abaixo" do C17.
- **Documento do cenário:** [`docs/scenarios/vardhelm_foundry_district.md`](docs/scenarios/vardhelm_foundry_district.md), pelo modelo do C20, com fontes classificadas e lacunas mantidas (função narrativa, NPCs nomeados, `LOC-` só proposto).
- **Construído:**
  - pátio de 30 × 25 m via LevelBuilder (`vardhelm_foundry_district_01.json` → `vp_02_vardhelm_foundry_district.tscn`, instanciado no slice): base de tijolo da Forja 01 com porta e placa, fundição vizinha a oeste, cortes ao sul e a leste, trilho com 3 carrinhos, pilha de carvão, talha de braço, lingotes, doca, portão de grade, profundidade da cidade; colisão = geometria;
  - **talha** entre o patamar e o pátio: `TransitionPoint`, um `Interactable` genérico com escurecimento curto;
  - 6 trabalhadores com carga, pelo `VardhelmAmbientLife` (novo `data_path`);
  - 3 observações sem memória;
  - lampiões, fumaça, vapor, poeira;
  - névoa, luz ambiente e desenho **derivados da área**;
  - depois do Primeiro Eco, o respiro da Forja 01 solta menos fumaça e a porta conta que o barulho de cima baixou (reusa o C13; nada novo de lore).
- **Integração:**
  - mesmo `scenario.vardhelm`; 3 IDs de observação novos no catálogo; nenhum evento, NPC, quest ou estado global novo;
  - Save V2 restaura posição no pátio e observações; névoa, área, gaiola e passagem ficam fora do save.
- **Compartilhado:**
  - slice (`observation_roots()`, setup, dica da talha, `refresh`);
  - provedor do Save V2;
  - `id_catalog.gd`;
  - `data_path` no AmbientLife.
- **Forja 01:** dados e cenas intocados. Visualmente, o pórtico da talha fica sobre o patamar; a primeira versão cobria a placa "FORJA 01" e foi refeita.
- **Testes:**
  - runner **1694/1694** (C21 42/42); playtest novo `c21_foundry_district_playtest.gd` **25/25** renderizado e headless;
  - C11 52/52, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17, C9 66/66;
  - cena principal sem erros; legados iguais; saves reais intactos; `tsc` limpo.
- **Desempenho (na tomada):**
  - pátio 16,6 ms (vsync);
  - Forja 17,0–17,6 ms com o pátio × 16,9–17,2 ms sem, dentro do ruído;
  - custo de geometria escondida medido e corrigido com desenho derivado.
- **Pendências:**
  - B: trabalhadores não se viram, carrinhos parados, piso e fundo simples, folga pré-existente de 0,9 m no portão da Forja;
  - C: **teste humano pendente, cenário não fechado**.

### [2026-09-30] — Bloco C20: Fundação de produção integrada dos próximos cenários
- **Documental:** nenhum cenário, mapa, NPC, diálogo, quest ou área criado; `godot/` idêntico antes e depois (mesmo hash de diff e de lista de arquivos). Vardhelm intacto, como laboratório e referência.
- **Novos documentos:**
  - [`SCENARIO_PRODUCTION_STANDARD.md`](docs/architecture/SCENARIO_PRODUCTION_STANDARD.md): regra CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO; protótipo × cenário cru; integração de vida, narrativa e visual; estados persistente, derivado e transitório; checklists de entrada e fechamento (modelo C19); relação com LevelBuilder, AmbientLife, Save V2 e EventBus;
  - [`SCENARIO_TEMPLATE.md`](docs/architecture/SCENARIO_TEMPLATE.md): modelo de cenário;
  - [`BLOCK_C20_PRODUCTION_FOUNDATION.md`](docs/architecture/BLOCK_C20_PRODUCTION_FOUNDATION.md): registro e pesquisa documental.
- **Pesquisa do próximo cenário:** "Próximo cenário ainda não definido no material canônico disponível". Três candidatos com evidência parcial:
  - outra área de Vardhelm (Ato 1, só prompts de arte);
  - Ostrell (Ato 2, só economia e progressão);
  - Brenhold (nós do protótipo CLI).
- **Lacunas registradas:**
  - conflito de Ato de Brenhold (Ato 2 no CLI e neste resumo × Ato 3 em `SYS-BALANCEAMENTO-ATOS`/`ENG-PROGRESSAO-NIVEIS`);
  - World Bible e Narrative vazios; tabela `LOC-` vazia;
  - Aethel, Asterion e Homem Cinzento ausentes do repositório.
- **Testes (linha de base):**
  - runner 1652/1652;
  - C11 52/52, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17 (renderizados e headless); C9 66/66;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo.

### [2026-09-30] — Bloco C19: Auditoria de fechamento da Forja de Vardhelm (Godot)
- **Somente auditoria:** nenhum arquivo de jogo, dado, teste ou sistema alterado. Contexto: C13–C18 validados em teste humano, segundo o usuário.
- **Evidências:**
  - bateria completa guardada;
  - sonda de auditoria descartável, fora do projeto: dois caminhos do C15 até o gancho, 11 ciclos Save → mover e girar → Load, **41/41**, 0 diferenças no GameState e no estado percebido, só `game_loaded` no Load;
  - 15 capturas pela câmera do jogador (`docs/architecture/c19_audit/`);
  - medição de quadro na tomada.
- **Testes:**
  - runner 1652/1652 (C10 56, C10.5 24, C11 18, C12 46, C13 27, C14 45, C15 31, C16 24, C17 19, C17.1 5, C17.2 8, C18 20);
  - playtests C11 52/52, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17 (renderizados e headless);
  - C9 66/66;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo.
- **Desempenho (tomada, Intel UHD, Forward+, 1152×648, vsync):** média 16,87 a 17,37 ms, mínimo 8,87, máximo 27,52 (quadros isolados), p99 cerca de 20 ms. Limitado pelo vsync; igual ao C17.3 dentro do ruído.
- **Classificação:** nenhuma ❌; ⚠️ só no visual:
  - cápsula do jogador;
  - fundo de neblina bege;
  - câmera atravessando a máquina B no canto noroeste.
- **Decisão: CENÁRIO FECHÁVEL**, "VARDHELM FORGE — CANDIDATO A FECHAMENTO".
- **Regra registrada para o próximo cenário:** CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO desde o primeiro bloco ([`docs/architecture/BLOCK_C19_FORGE_CLOSING_AUDIT.md`](docs/architecture/BLOCK_C19_FORGE_CLOSING_AUDIT.md)).

### [2026-09-30] — Bloco C18: Ciclo de vida das janelas contextuais (Godot)
- **Problema:** a dica "E • …" seguia o candidato do detector quadro a quadro: sumia na hora ao sair da área e piscava na borda.
- **Auditoria:** a única janela aberta por proximidade é a `InteractionHint`, que serve observações, suporte de ferramentas, Eco, painel, folha do C16 e Durn. O painel de observação (aberto pelo E) e o `DialogueBox` ficam fora.
- **Solução:**
  - `ContextualWindowLifecycle` (novo, genérico, `scripts/ui/`) com estados oculta → visível → fechamento pendente → fechando;
  - fade-in 0,10 s, atraso de fechamento 0,75 s, fade-out 0,15 s, em dados (`data/ui/contextual_windows.json`);
  - voltar durante o atraso cancela o fechamento sem reiniciar a animação;
  - sem `_process`: um `Timer` de uso único e tweens;
  - `_on_candidate_changed` do slice passou a só pedir abrir ou fechar; conversa ativa → `force_hide()` imediato (C11 preservado);
  - detector, prioridade, E, áreas, Eco, painel e folha inalterados; nada vai para o Save V2;
  - histerese espacial não adicionada: o atraso já absorve a borda, e ela exigiria mudar o detector.
- **Regra de produção registrada** (para cenários futuros; Vardhelm não alterado): CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO ([`docs/architecture/BLOCK_C18_CONTEXTUAL_WINDOWS.md`](docs/architecture/BLOCK_C18_CONTEXTUAL_WINDOWS.md)).
- **Testes:**
  - 1652/1652 checks PASS (suite nova `test_c18_contextual_windows.gd`, 20 checks: A–I, M, N);
  - playtest novo `c18_contextual_windows_playtest.gd` 17/17, renderizado e headless: some cerca de 0,9 s após sair, volta em cerca de 0,2 s sem piscar, 8 travessias da borda sem piscar, conversa não fechada pela distância, Save/Load;
  - C11 52/52, C9 66/66, C15 17/17, C16 16/16, C17.3 11/11;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo;
  - desempenho: A/B sem e com o C18 igual (24,77 × 24,74 ms). O valor absoluto está acima dos 16,3 ms do C17.3 porque a máquina rodava na bateria;
  - **teste humano pendente.**

### [2026-09-29] — Bloco C17.3: Colisão corporal dos trabalhadores (Godot)
- **Problema (teste humano do C17.2):** o jogador atravessava os trabalhadores.
- **Solução:**
  - `AnimatableBody3D` + `CapsuleShape3D` (raio 0,25 m, altura 1,7 m: pernas e tronco) filho de cada trabalhador comum, criado pelo AmbientLife a partir de `worker_body` no `ambient_life.json`;
  - acompanha o tween da rota sem processamento novo; a rota nunca depende da física, então o trabalhador não trava nem treme;
  - camada 1, máscara 0: o jogador colide; trabalhadores não se detectam entre si; fora da camada de interação, então o E não os escolhe;
  - Durn não recebe corpo extra; nenhuma rota ou posição mudou; nenhuma camada nova.
- **Testes:**
  - 1632/1632 checks PASS; o teste do C17.1 que afirmava "sem colisão" passou a exigir um corpo leve por trabalhador;
  - playtest novo `c17_3_worker_collision_playtest.gd` 11/11, renderizado e headless: não atravessa, contorna, rota segue, Durn inalterado, Eco/painel/folha alcançáveis, E não captura, Save/Load;
  - C11 52/52; C15 17/17 (o andador passou a ir ao painel pela rota aberta, porque a linha reta raspava no trabalhador da bigorna); C16 16/16; C9 66/66;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo; 16,35 ms por quadro;
  - **teste humano pendente.**

### [2026-09-29] — Bloco C17.2: Identidade e acabamento visual de Vardhelm (Godot)
- **Auditoria pela câmera do jogador** (em `BLOCK_C17_VISUAL_SLICE.md` §10): rótulos flutuantes de protótipo; máquinas A e B como blocos lisos (o quadro de manutenção estava **enterrado dentro** da máquina A); pessoas em cápsula; suporte de ferramentas como placa solta; bases de estação cinzas; madeira lendo laranja; colunas sem base.
- **Sinalização:** "SETOR INDUSTRIAL" e o "FORJA 01" do canto removidos; o texto flutuante do portão virou **placa de ferro fixa** com "FORJA 01".
- **Máquinas** (grupos de dados do C17.1):
  - máquina B com plinto, cintas, carcaça com chaminé curta, volante e correia até um motor, manômetros, portinhola, cano até o coletor e óleo;
  - máquina A com plinto, **quadro visível com folhas**, cano até a parede, manômetro e portinhola;
  - suporte de ferramentas com postes, travessa e ferramentas;
  - chapas de base nas colunas;
  - só o motor tem colisão nova, em canto morto.
- **Pessoas:** `HumanoidSilhouette` (novo, genérico, só visual: pernas, tronco, braços, cabeça, avental e boné opcionais). Trabalhadores via AmbientLife (`outfit` opcional, camisas apagadas). **Durn** com a mesma base, mas casaco longo no tom de couro de sempre, mais alto e com a placa DURN; a cápsula ficou oculta, e colisão, interação, prioridade, posição e C15/C16 seguem inalterados.
- **Materiais:** madeira velha no lugar do laranja-marrom; estrados de madeira nas estações; cor opcional nos adereços de história (suporte de ferramentas em madeira).
- **Ajuste durante o bloco:** a chaminé alta da máquina B ficava exatamente embaixo do Eco na projeção isométrica; virou uma chaminé curta. Um teste novo garante que nada decorativo fique na frente do Eco ou do painel na câmera do jogador.
- **Sem:** luzes novas, emissivos novos, SSAO (continua desligado) e recursos novos no LevelBuilder. Quadro em 16,5 ms (60 fps).
- **Testes:**
  - 1632/1632 checks PASS (C17 32, com +8 do C17.2);
  - playtests com input real: C11 52/52 (renderizado e headless), C15 17/17, C16 16/16, C9 renderizado 66/66;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo;
  - **teste visual humano pendente.**

### [2026-09-29] — Bloco C17.1: Densidade industrial e vida de Vardhelm (Godot)
- **Motivo:** feedback humano ao C17: "Melhorou, mas ainda parece muito vazio."
- **Postos de trabalho como dados** (novo tipo genérico `"type": "group"` no LevelBuilder/LevelValidator: um nó com itens primitivos em coordenadas locais):
  - forja (carvão, barras, balde de têmpera, tenaz);
  - bigorna (barra em trabalho, martelo, tina, carepa);
  - bancada (engrenagem, chapa, ferramentas, peças, óleo);
  - nicho de manutenção (caixa aberta, peças desmontadas, chave, lata de óleo);
  - transporte (palete com barras amarradas, caixas, corrente com gancho);
  - carga na ponte rolante.
- **Vertical e profundidade:**
  - vertical: tubulação fria de cobre oxidado na parede norte, polia e corrente no trilho, porta-ferramentas;
  - primeiro plano escuro: barris e sacos de lona;
  - fundo: pórtico, tanque e janelas distantes;
  - marcas de uso (fuligem, carepa, óleo) e vapor no coletor.
- **Trabalhadores:** +3 pelo AmbientLife existente (bigorna, carregador com o campo opcional novo `carry`, um distante), 7 no total. Sem IA nova e sem colisão; Durn inalterado.
- **Correções:** o gancho da ponte rolante (C17) atravessava a máquina A e agora segura a carga acima dela; o `EmberVent` da entrada deixou de ser um bloco laranja.
- **Regras:** colisão só em palete, caixas e barris, todos em cantos mortos. Nenhum colisor novo a menos de 1,5 m de Durn, da folha, do Eco, da frente do painel, do quadro, das ferramentas, do início, da entrada ou do corredor. Nenhuma interação nova, nenhum emissivo novo, SSAO desligado; quadro em 16,1 ms (60 fps).
- **Teste do C14 ajustado:** exigia exatamente 4 trabalhadores; agora exige ≥ 4, todos na rotina antes do Eco.
- **Testes:**
  - 1624/1624 checks PASS (C17 24, com +5 do C17.1);
  - playtests com input real: C11 52/52 (renderizado e headless), C15 17/17, C16 16/16, C9 renderizado 66/66;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo;
  - **teste visual humano pendente** (seção 9 de `BLOCK_C17_VISUAL_SLICE.md`).

### [2026-09-29] — Bloco C17 (Fase 2): Baia oeste da Forja 01 — de "caixa com objetos" a "baia construída" (Godot)
- **Direção aprovada:** 3D/2.5D atual (HD-2D como referência futura); Vardhelm = cidade industrial (`ART-PROMPTS-TIER1`, `BLUEPRINT_VISUAL_MESTRE`); laranja concentrado na forja; ciano do Eco mantido como exceção narrativa. Detalhes em [`docs/architecture/BLOCK_C17_VISUAL_SLICE.md`](docs/architecture/BLOCK_C17_VISUAL_SLICE.md).
- **Arquitetura (data-driven, `vardhelm_forge_01.json`):**
  - paredes norte e oeste de tijolo com fuligem (5,5 m) com janelas altas; **paredes sul e leste em corte**: parapeitos de 1,1 m com **colisão de 1,1 m**, sem parede invisível;
  - pilares e pilastras de ferro; **ponte rolante** na baia oeste; passarela com apoios e guarda-corpo;
  - **abertura real no sul**, levando a um patamar fechado por guarda-corpo;
  - o **painel selado** dentro de um anteparo de tijolo com moldura de ferro, na mesma posição e com a mesma interação;
  - piso de chapas com óleo;
  - a **cidade abaixo** em silhueta, vista pelas janelas e pela entrada.
- **Luz e atmosfera:**
  - direcional de cima, fria e fraca;
  - forja `#FF7900` como a fonte quente;
  - faixas, anéis e tampa sem brilho; lâmpadas de querosene fracas, presas às paredes;
  - névoa de profundidade e névoa densa abaixo do piso;
  - fumaça na forja, vapor e poeira (partículas leves); tonemap filmic.
  - O **SSAO ficou desligado**: dobrava o tempo de quadro na GPU integrada (16,7 → 35 ms). Sem ele, 16,3 ms (60 fps).
- **LevelBuilder/LevelValidator (genéricos, opcionais, compatíveis):** paredes por lado com altura, material e aberturas (portas e janelas); materiais por shader (`brick_wall.gdshader`, `floor_plates.gdshader`); props sem colisão e com rotação; cor e energia de luz; névoa, SSAO e tonemap. `vp_01_vardhelm.tscn` foi regerada pelo builder, com o uid preservado.
- **Set dressing:** duto que atravessava o painel reposicionado; chaminé da forja até 8 m; hastes nas luminárias. `WorkLight_00` e a luminária do C13 ficaram intactas.
- **Removido:** `test_prefab_pillar.tscn` (pilar magenta). **Pendência:** `MachineBlock_B`; cápsulas mantidas.
- **Circulação:**
  - os apoios da passarela fechavam o corredor ao norte de Durn e foram movidos;
  - o painel agora só é acessível pela frente. O playtest do C11 examinava o painel por trás; o andador passou a chegar pela frente, na ordem de um jogador;
  - a câmera não foi alterada.
- **Testes:**
  - 1619/1619 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18 · C12 46 · C13 27 · C14 45 · C15 31 · C16 24 · **C17 19**: validador, colisão = malha em todas as paredes, abertura e patamar, janelas, C13–C16 nas mesmas posições, laranja só na forja, SSAO desligado);
  - playtests com input real: C11 52/52 headless e renderizado (o renderizado leva mais que os 400 s antigos do script; rodado com 900 s), C15 17/17, C16 16/16 (renderizado e headless), C9 renderizado 66/66;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos;
  - sonda A0 difere nas 3 falas do C10.5 e em nomes automáticos de nós internos (`@Label3D@…`).
  - **Teste visual humano pendente.**

### [2026-09-29] — Bloco C17 (Fase 1): Auditoria visual e definição do setor de Vardhelm (Godot)
- **Só auditoria e proposta; nada implementado.** [`docs/architecture/BLOCK_C17_VISUAL_AUDIT.md`](docs/architecture/BLOCK_C17_VISUAL_AUDIT.md) com capturas da câmera real em `docs/architecture/c17_audit/`.
- **Achados:** sala-caixa de 20 × 14 m sem arquitetura, flutuando no vazio. As paredes sul e leste (4 m) tapam a câmera isométrica: na entrada, a primeira imagem é uma parede cobrindo quase metade da tela. O painel selado é uma placa solta no piso. O portão está encostado numa parede maciça. Há um pilar magenta de teste. Não há névoa, SSAO nem fundo, e o laranja emissivo está espalhado bem acima de um acento.
- **Cânone consultado:** `docs/05_arte/ART-PROMPTS-TIER1.md` (Vardhelm = cidade industrial; tijolo com fuligem, ferro bruto, chaminés sob céu nublado; paleta chumbo, sépia, fuligem, ferrugem, lona; Trava R3) e `doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md` (**HD-2D pixel art**, 70/20/10, luz de cima fria, proibido neon ciano). O slice 3D de primitivas diverge do formato definido.
- **Setor proposto:** a baia oeste da forja ("FORJA 01"), onde se passa do C12 ao C16. Direção de galpão de manufatura conforme o cânone. Prioridade 1: paredes em corte no sul e no leste, com a colisão intacta.
- **Decisões pendentes antes de implementar:** formato (HD-2D × 3D atual), ciano do Eco e laranja × blueprint, Brenhold × Vardhelm, entrada da Forja 01, paredes em corte.
- **Testes:** nenhum código alterado neste bloco; a última bateria completa (C16) segue válida: 1600/1600, playtests verdes.

### [2026-09-29] — Bloco C16: Consequência que altera uma possibilidade futura (Godot)
- **Auditoria:** conversas de Durn, Eco, quadro, ferramentas, painel, marca do Eco, trabalhadores e estações. Nenhuma servia sem alterar o que já foi aprovado ou sem forçar a ligação com a escolha. **Selecionado:** o lugar de sempre de Durn, que no caminho "Não senti nada." (C15) fica vazio depois do Eco.
- **Possibilidade:** nesse caminho, Durn deixa para trás uma **folha dobrada** que pode ser examinada ("…Horários anotados à mão, todos de hoje. O último está sublinhado duas vezes."). No caminho "Sentir o quê?" ele nunca sai, não há folha, e o E continua sendo para ele. Reutiliza `consequence.vardhelm.felt_nothing` com naturalidade: a folha só existe porque Durn saiu.
- **Arquitetura existente:** uma `EnvironmentalObservation` a mais, `observation.vardhelm.durn_notes`, descrita em `ambient_life.json` numa lista separada (`conditional_observations`; as 3 de sempre intactas). Sem memória, quest ou diálogo novos. Disponibilidade derivada da mesma condição do C15 (`is_durn_alone_after_echo`), aplicada junto com a posição de Durn.
- **Persistência:** decisão, consequência e "folha examinada" pelo Save V2 (IDs canônicos); disponibilidade derivada, não salva. Um save de antes da escolha volta sem folha. Os Loads não reemitem eventos e nada duplica.
- **Incidente corrigido no bloco:** a primeira versão pôs a folha na lista `observations` e quebrou um teste legado que conta exatamente 3. Ela foi para a lista separada, e os legados voltaram à linha de base. Uma edição de `ambient_life.json` com `sed` truncou o arquivo; ele foi restaurado da cópia de testes, conferida (372 linhas, com todo o conteúdo do C13 ao C16), antes de refazer a edição com a ferramenta de edição.
- **Testes:** 1600/1600 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18 · C12 46 · C13 27 · C14 45 · C15 31 · **C16 24**); playtest novo com input real, 3 partidas (A, B com Save/Load, e save de antes da escolha), 16/16 renderizado e headless; C15 17/17; continuidade 52/52; C9 renderizado 66/66; sonda A0 difere nas 3 falas do C10.5 e no nome automático de um nó interno (`@Label3D@146→147`, pela folha nova); cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc --noEmit` limpo. **Teste humano pendente** (seção 7 de [`docs/architecture/BLOCK_C16_FUTURE_POSSIBILITY.md`](docs/architecture/BLOCK_C16_FUTURE_POSSIBILITY.md)).

### [2026-09-29] — Bloco C15: Primeira escolha com consequência perceptível (Godot)
- **Auditoria:** três pontos de escolha em Vardhelm; só "Sentir o quê?" tinha consequência (`vardhelm_heard_echo`, invisível no mundo). **Selecionada:** "Não senti nada." na primeira conversa (`dialogue.vardhelm.intro` / `start` / `leave`). É a primeira decisão do jogador, é relacional, vem cedo (dá espaço para a consequência aparecer depois) e não tinha efeito algum.
- **Consequência:** `consequence.vardhelm.felt_nothing` (fonte `dialogue.vardhelm.intro`) → estado derivado `envstate.vardhelm.durn_alone`. Quando o Eco acontece, Durn ("Se acontecer de novo... procure por mim.") não espera o jogador: vai sozinho até onde o Eco aconteceu e fica ali. Com "Sentir o quê?", nada muda. Sem texto novo, sem mensagem, falas de Durn inalteradas.
- **Arquitetura existente:** campo `consequences` do diálogo → NarrativeController → EventBus (`dialogue_choice_selected` → `consequence_applied` → `world_state_changed`) → AmbientLife (`narrative_consequences` em `ambient_life.json`) → o slice posiciona o NPC existente (`_apply_durn_presence`: ao vivo caminha; na derivação/Load já está no lugar). IDs no GameIdCatalog (consequência, estado, aliases, fonte).
- **Persistência:** decisão (DialogueState) e consequência (world.consequences) pelo Save V2; estado de ambiente e posição **não** salvos (derivados). O Load não reencena a caminhada e nunca recria o NPC.
- **Ajuste durante o bloco:** o primeiro lugar (junto ao painel) fazia o E falar com Durn em vez de examinar o painel, e no canto afastado a parede escondia Durn da câmera. O lugar final é o do Eco: aberto, visível, sem disputa de interação.
- **Testes:** 1576/1576 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18 · C12 46 · C13 27 · C14 45 · **C15 31**); playtest novo da escolha com input real 17/17 (renderizado e headless); continuidade 52/52; C9 renderizado 66/66; sonda A0 difere só nas 3 falas do C10.5; cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc --noEmit` limpo. **Teste humano pendente** (seção 6 de [`docs/architecture/BLOCK_C15_CHOICE_CONSEQUENCE.md`](docs/architecture/BLOCK_C15_CHOICE_CONSEQUENCE.md), sem revelar a consequência).

### [2026-09-29] — Bloco C14.2: Ajuste fino do piso do silêncio (Godot)
- **Teste humano do C14.1:** melhorou bastante, mas o zumbido (`VardhelmHum`) ainda era claramente audível no silêncio.
- **Ajuste de parâmetro:** `closing_silence.silent_db` −60 → **−70 dB** (`ambient_life.json`). O zumbido desce a ~−86 dBFS no núcleo do silêncio. Duração (1,4 + 4 + 3 s), fades, retorno, código, estado e Save/Load inalterados.
- **Testes:** 1545/1545 checks PASS (piso exato de −70 dB e cobertura das 3 fontes); playtest de continuidade 52/52 (renderizado e headless: as 3 fontes a −70 dB no silêncio, de volta a −6/−16/−30 dB); C9 renderizado 66/66; sonda A0, cena principal e legados como antes; saves reais intactos. **Teste humano de áudio pendente.**

### [2026-09-29] — Bloco C14.1: Correção do momento de silêncio (áudio) (Godot)
- **Auditoria:** o jogo tem 3 fontes de som (`VardhelmAudio`: zumbido, vapor, máquinas), num único bus (Master). Nenhum player extra toca durante o silêncio (sandboxes do Load descartados). Níveis medidos nos `.wav`: o **zumbido** (drone contínuo de 8 s, −16 dBFS) é 30 dB mais alto que vapor e máquinas. Com o piso de −42 dB ele continuava em ~−58 dBFS, sozinho, e mascarava a quebra; os outros dois já ficavam inaudíveis.
- **Correção:** piso do silêncio `closing_silence.silent_db` −42 → **−60 dB** (`ambient_life.json`). O zumbido fica num resquício quase inaudível (~−76 dBFS), sem silêncio absoluto; vapor e máquinas somem. Duração (1,4 + 4 + 3 s), fades, código, estado e Save/Load inalterados; nenhum recurso novo.
- **Testes:** 1545/1545 checks PASS (C14 45: +cobertura de todas as fontes de ambiente e piso ≤ −60 dB, +duração inalterada); playtest de continuidade 52/52 (renderizado e headless: as 3 fontes a −60 dB no silêncio, de volta a −6/−16/−30 dB depois); C9 renderizado 66/66; sonda A0, cena principal e legados como antes; saves reais do usuário intactos. **Teste humano de áudio pendente** (seção 6 de [`docs/architecture/BLOCK_C14_FIRST_SEQUENCE.md`](docs/architecture/BLOCK_C14_FIRST_SEQUENCE.md)).

### [2026-09-29] — Bloco C14: Primeira sequência narrativa completa (Godot)
- **Mapa da sequência** (entrada → Durn → escolha → Eco → consequência/memória → Vardhelm reage → Durn → painel → conclusão) em [`docs/architecture/BLOCK_C14_FIRST_SEQUENCE.md`](docs/architecture/BLOCK_C14_FIRST_SEQUENCE.md). O mapa mostrou dois buracos no fim: depois do painel nada acontecia, e Durn repetia "Se for olhar... vá com calma." como se o jogador não tivesse ido.
- **Encerramento (sem texto):** ao concluir o exame do painel, Vardhelm fica em silêncio por alguns segundos (zumbido, vapor e máquinas quase somem; a luz fria sobre o painel se apaga) e depois volta ao estado pós-Eco. Áudio e luz existentes (`VardhelmAmbientLife.play_closing_silence`, parâmetros em `ambient_life.json`). É transitório, só acontece ao vivo, nunca num Load, e um Load no meio o interrompe.
- **Gancho:** Durn, uma vez: "...Você ouviu, não ouviu?" / "Então não fui só eu." / "..."; depois, só "...". Diálogo curto `vardhelm_after_panel` (dados + localização, sem escolha). O ID está no GameIdCatalog e a definição no provider. O estado final usa o que existe: quest concluída + diálogo concluído.
- **UX:** o status não mostra mais o ID técnico da consequência ("Memória registrada: vardhelm_heard_echo" aparecia durante a primeira conversa).
- **Preservado:** conversa inicial, conversa pós-Eco (C12), as três reações do C13, banner/status do C13, painel fechado. Testes do C12/C13 que esperavam a pista repetida depois do painel foram atualizados para a fala final.
- **Testes:** 1543/1543 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18 · C12 46 · C13 27 · **C14 43**: sequência inteira do começo ao gancho, Save/Load A–E, Load no meio do silêncio, nada duplicado, legado 0); playtest de continuidade com input real 52/52 (renderizado e headless; silêncio medido: zumbido −42 dB e luz apagada, volta a −6 dB; fala final e silêncio de Durn); playtest C9 renderizado 66/66; duração real do silêncio medida em 8,1 s; sonda A0 difere só nas 3 falas do C10.5; cena principal sem erros; legados SceneTree iguais à linha de base; saves reais do usuário intactos; `tsc --noEmit` limpo. **Teste humano pendente** (roteiro na seção 5 do documento do C14; o C14 só fecha depois dele).

### [2026-09-27] — Bloco C13: Vardhelm como espaço vivo (Godot)
- **Auditoria:** longe da esfera, o mundo depois do Eco era idêntico ao de antes. O que era persistente ficava no ponto do Eco (esfera, marca no chão, banner); o resto era temporário (sobressalto dos trabalhadores) ou invisível (rótulos de estação ocultos; `_set_station_attention` procura `Label3D` no nível errado).
- **Três reações sutis, sem texto nem popup**, todas DERIVADAS do estado persistente existente (flag `vardhelm_first_echo_complete` → `echo_awakened`) em `VardhelmAmbientLife`, com parâmetros em `ambient_life.json` (`after_echo`, `after_echo_route`):
  1. a luz de trabalho sobre o painel selado (e sua luminária) fica fria, alcança o painel e falha de vez em quando;
  2. o trabalhador da oficina larga a bancada e fica parado perto do painel;
  3. o som das máquinas cai 10 dB.
- **Persistência e resync:** nada novo é salvo. O Load V2 desfaz (`reset_persistent_state`) e re-deriva pela derivação existente (`derive_environment_state`). A aplicação é idempotente: não acumula volume nem reinicia rotina ou piscar. O Load não reemite consequência, Eco, memória nem observação.
- **Painel continua fechado** (mesma placa, mesmo texto, nenhum estado de abertura). Durn e a ponte do C12 inalterados.
- **UX (resíduos do C12):** banner do Eco movido para o `HudTop`, abaixo do objetivo e do status (não cobre mais o objetivo em 1152×648); o status "Você registrou o primeiro Eco…" sai quando a investigação do painel começa.
- **Testes:** 1500/1500 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18 · C12 46 · **C13 27**); playtest de continuidade com input real 47/47 (renderizado e headless; agora confere estado A/B do mundo em cada Save/Load e o banner fora do objetivo); playtest C9 renderizado 66/66; sonda A0 difere só nas 3 falas de Durn do C10.5; cena principal sem erros; legados SceneTree iguais à linha de base; saves reais do usuário intactos; `tsc --noEmit` limpo. Roteiro humano em [`docs/architecture/BLOCK_C13_LIVING_VARDHELM.md`](docs/architecture/BLOCK_C13_LIVING_VARDHELM.md) — **não executado**.

### [2026-09-27] — Bloco C12: Continuidade narrativa pós-Primeiro Eco (Godot)
- **Lacuna corrigida:** depois do Eco, Durn repetia a conversa inicial. Agora: Eco → o mundo reage → exploração → **Durn reage uma vez** (diálogo `vardhelm_after_echo`, 5 entradas, 2 pontos de escolha) sem explicar nada ("Você sabe o que era?" → "Não.") → **pista concreta**: o painel selado "fez um barulho" → **nova investigação curta** (quest `vardhelm_sealed_panel`: examinar o painel selado, cujo texto pós-Eco já existia).
- **Condição persistente:** flag `vardhelm_first_echo_complete` **ou** quest `vardhelm_first_echo` concluída (ambas já salvas pelo V2). Depois de concluída, a conversa pós-Eco não se repete: Durn abre o mesmo diálogo na entrada `clue` (só a pista e a despedida, sem escolhas).
- **Só sistemas existentes:** DialogueController/DialogueRuntimeState, QuestController/QuestState, LocalizationService (todo texto em `pt-BR.json`), EnvironmentalObservation, EventBus e Save/Load V2. IDs novos no `GameIdCatalog` (`dialogue.vardhelm.after_echo`, `quest.vardhelm.sealed_panel` + aliases); `VardhelmRuntimeStateProvider` fornece a definição do novo diálogo e a apresentação das duas quests; objetivo/banner derivados de forma igual no jogo e no restore (`_apply_followup_objective`).
- **Testes existentes adaptados** (falavam com Durn depois do Eco esperando a conversa inicial): C10 (UI transitória), C10.5 G/H (escolha restaurada agora é a da conversa pós-Eco), A3 "diálogo repetido" (abre a conversa inicial explicitamente) e o final do playtest C11 (agora percorre a ponte com input real).
- **Testes:** 1473/1473 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18 · **C12 46**); playtest de continuidade com input real 40/40 (renderizado e headless; inclui Durn pós-Eco, pista, lembrete, painel selado e Save/Load); playtest C9 renderizado 66/66; sonda A0 difere só nas 3 falas de Durn do C10.5; cena principal sem erros; legados SceneTree iguais à linha de base; saves reais do usuário intactos; `tsc --noEmit` limpo. Roteiro manual A–N em [`docs/architecture/BLOCK_C12_POST_ECHO_BRIDGE.md`](docs/architecture/BLOCK_C12_POST_ECHO_BRIDGE.md) — **não executado** (testes foram automatizados).

### [2026-09-27] — Bloco C11: Continuidade jogável de Vardhelm (Godot)
- **Auditoria com input real** (movimento por ações, E, clique nas escolhas, Enter, Ctrl+S/Ctrl+L, frames reais) revelou bloqueios que os testes por chamada direta não viam; corrigidos no mínimo, só nos sistemas existentes:
  - **Durn inalcançável pelo E:** observações (prioridade 2, sempre examináveis) venciam Durn (0) mesmo com ele mais perto — o quadro ao lado recebia o E. Durn agora tem a mesma prioridade das observações (vence o mais próximo; regra existente do `InteractionDetector`); o Eco (10) continua acima. O quadro segue examinável pelos lados oeste/sul.
  - **E durante a conversa examinava o mundo** e a dica ficava por baixo do diálogo: o detector de interação é suspenso enquanto há conversa aberta (dica oculta) e volta ao terminar.
  - **Ctrl+S fazia o personagem recuar** (S físico = `move_down`): o save gravava a posição e o personagem andava depois; o Load parecia devolver a outro lugar. `PlayerController` ignora movimento com Ctrl pressionado.
  - **HUD:** objetivo + status num `VBoxContainer` ancorado (status sempre abaixo do objetivo em 1, 2 ou mais linhas); removido o reposicionamento manual do C10.
  - **Destaque da mensagem de save/load vazava** para um status escrito pelo jogo (ex.: "Você registrou o primeiro Eco…" em verde): o destaque sai no mesmo frame em que o jogo troca o texto, e o timer sempre restaura o estilo.
- **Sem sistema novo:** GameState, Save/Load V2, EventBus, RestorePlan, adapters, DialogueRuntime, QuestState, memória, consequências e interação reutilizados; nenhuma duplicação.
- **Testes:** 1427/1427 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24 · C11 18); playtest de continuidade com input real 32/32 (renderizado e headless); playtest C9 renderizado 54/54; HUD sem sobreposição em 1152×648, 800×450, 700×800 e 1900×700. Sonda A0 difere só nas falas de Durn (C10.5); cena principal sem erros; legados SceneTree iguais à linha de base; `tsc --noEmit` limpo; saves reais do usuário intactos.

### [2026-09-27] — Bloco C10.5: Correções pós-playtest humano — Load, janela, diálogo de Durn (Godot)
- **Causa do "travamento" do Ctrl+L (investigada pelo log da sessão):** Ctrl+L → ação `load_game` (InputMap) → `VardhelmVerticalSlice._unhandled_input` → flags V2 OFF (padrão da época) → `SaveService.load_game` legado → SCRIPT ERROR em `save_service.gd:44` → o debugger do editor pausa o jogo. Sem handler duplo, sem atalho do editor/Control, sem Load V2 envolvido.
- **Correção (decisão do usuário):** `SAVE_V2_OPERATIONAL_LOAD/SAVE_ENABLED` passam a **true por padrão** — Ctrl+L/Ctrl+S usam somente o V2, sem chamar nem cair no SaveService legado (que fica no código como LEGACY COMPATIBILITY PATH, só com flags OFF explícitas). `SaveV2OperationalConfig.create()` continua OFF por padrão (configuração explícita). Teste com `SaveService` espião: 0 chamadas legadas no caminho V2; jogo segue respondendo após o Load (sem pausa, um único `game_loaded`).
- **Janela:** `DialogueBox` com offsets reais (24 px laterais, 36 px embaixo, cresce para cima — o antigo `size = (-48, 246)` era descartado e a caixa passava ~110 px da borda direita em qualquer tamanho); notificação de memória ancorada no centro-inferior. `canvas_items` + `expand` mantidos. Sonda renderizada: todos os elementos dentro da área em 1152×648, 1600×900, 800×450, 1280×720, 700×800 e 1900×700.
- **Durn (menos explicativo, só chaves de localização):** "Você também ouviu o eco?" → "...Você também sentiu isso?"; escolhas "Sentir o quê?" / "Não senti nada."; "Um instante impossível atravessa sua memória." → "...Nada. Deve ter sido nada."; "Então siga. Talvez o Eco encontre você depois." → "Se acontecer de novo... procure por mim." IDs de entrada/escolha, consequência e DialogueState inalterados; as duas falas literais do JSON viraram chaves (`dialogue.vardhelm.pause`, `dialogue.vardhelm.farewell`).
- **Incidente de teste corrigido:** um teste legado sobrescreveu o save antigo do playtest do usuário (mesma pasta `user://`); o arquivo foi restaurado byte a byte (424 bytes, conteúdo registrado antes). A cópia de trabalho dos testes agora usa diretório de usuário próprio e a regressão confere os saves reais antes/depois.
- **Testes:** 1409/1409 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56 · C10.5 24) + playtest automatizado renderizado 54/54. Sonda A0 difere só nas 3 falas de Durn (esperado); cena principal sem erros; legados SceneTree iguais à linha de base; `tsc --noEmit` limpo.

### [2026-09-27] — Bloco C10: Adoption Hardening + UX + Migration Decision (Godot)
- **Migração:** decisão registrada — **OPTION B — OPT-IN MIGRATION** (`SAVE_MIGRATION_POLICY.md`); nada implementado, nenhum migrator novo, nenhuma migração automática.
- **Câmera (causa real):** cada sandbox do Load V2 roubava a câmera ativa (Player do sandbox com `Camera3D.current`); após todo Load a câmera ficava presa na panorâmica do nível. `VardhelmDiagnosticSandbox` agora desativa as câmeras do sandbox e devolve a câmera do jogo. Velocidade do Player zerada após apply (SUCCESS/rollback).
- **UI transitória:** painéis de memória/observação/notificação do estado anterior descartados após Load SUCCESS (não em falha/recusa/rollback; diálogo nunca fechado).
- **Mensagens:** status existente destacado (fonte 18, fundo, cor por severidade), abaixo do painel de objetivo, some em 4 s; seis mensagens distintas e localizadas; `SaveV2PlayerMessages.severity_of`.
- **Durn:** `DialogueBox.show_entry` passa a localizar o falante (`npc.vardhelm.elder.name` → "Durn"); ID `npc.vardhelm.durn`, GameIdCatalog, DialogueState e dados inalterados.
- **Performance C9 × C10 (renderizado):** cold 119,0 → 100,4 ms; warm 118,0 → 92,0; medianas 102,6–113,3 → 92,3–100,6; máx 586,4 → 117,6. Headless: cold 73,9 → 67,7; medianas 66,1–77,7 → 67,3–84,8. Variância alta entre execuções na mesma máquina (frame ocioso renderizado 251 → 16,6 ms); diferenças não atribuídas às mudanças. Dois sandboxes e rehearsal mantidos; nada otimizado.
- **Checklist humano:** `docs/architecture/C10_HUMAN_PLAYTEST_CHECKLIST.md` (NÃO EXECUTADO; todos os itens NOT TESTED). Não houve playtest humano.
- **Flags:** continuam OFF. SaveService/`save_service.gd:44` intactos (legacy).
- **Testes:** 1385/1385 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59 · C10 56) + playtest automatizado 66/66 (renderizado e headless). Sonda A0 idêntica; cena principal sem erros; legados SceneTree iguais à linha de base; `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C10_ADOPTION_HARDENING.md`, `C10_HUMAN_PLAYTEST_CHECKLIST.md`, `SAVE_MIGRATION_POLICY.md` (decisão) (+ matriz).

### [2026-09-27] — Bloco C9: V2 Adoption Readiness + Rendered Performance + Playtest (Godot)
- **Playtest renderizado automatizado** (`tests/save_v2/c9_rendered_playtest.gd`, fora do runner headless): Forward+/D3D12, Intel UHD, Ctrl+S/Ctrl+L reais com as duas flags ON só nas instâncias do playtest — fluxos 1–9 **31/31**; capturas de tela verificadas.
- **Performance (mesma ferramenta, séries separadas):** Load renderizado cold 119,0 ms · warm 118,0 · medianas 102,6–113,3 (mín 93,5; máx 586,4 — pico único na criação do sandbox 2); headless cold 73,9 · warm 72,1 · medianas 66,1–77,7. Criação dos dois sandboxes ≈ 90% do Load (renderizado 42–52 ms cada); restore/apply/validação/rollback < 3 ms. Save 13–20 ms renderizado. Nada otimizado.
- **UX:** `SaveV2PlayerMessages` separa mensagem do jogador (11 chaves `save.v2.*` em `pt-BR.json`, via `LocalizationService`) do log técnico (`push_warning`; `push_error` em ROLLBACK_FAILURE). Mensagens no `status_label` existente, somem após 4 s; diálogo aberto → "Termine a conversa antes de carregar o jogo."; ROLLBACK_FAILURE → "Não foi possível carregar o jogo com segurança.". Sem códigos/stack trace ao jogador.
- **Saves antigos:** `SaveV2PersistenceInventory` (somente leitura) detecta legado × V2 × envelope V2 no caminho legado; só save antigo → mensagem própria; coexistência documentada. `docs/architecture/SAVE_MIGRATION_POLICY.md`: opções A (automática), B (opt-in), C (encerrar legado) — **decisão pendente**.
- **Correção:** `GameplayEventPublisher.resync_after_load` — após Load V2 que volta no tempo, a deduplicação do B1 impedia a sombra de registrar o gameplay seguinte (divergia até o próximo Save).
- **Instrumentação:** tempos por sandbox (`sandbox1_*`, `sandbox2_*`); `SaveV2LoadMetrics` (min/máx/média/mediana, modo headless × renderizado).
- **Achados visuais registrados (não corrigidos):** painéis transitórios sobrevivem ao Load até o timer; câmera reenquadra após teleporte; mensagem de status discreta; falante do diálogo exibido como chave crua (pré-existente).
- **Flags:** LOAD/SAVE continuam OFF por padrão. SaveService e `save_service.gd:44` intactos.
- **Testes:** 1329/1329 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92 · C9 59) + playtest renderizado 31/31 (e 31/31 headless). Sonda A0 idêntica; cena principal sem erros; legados SceneTree iguais à linha de base; `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C9_ADOPTION_READINESS.md`, `SAVE_MIGRATION_POLICY.md` (+ matriz).

### [2026-09-27] — Bloco C8: V2 Adoption + Operational Save + Persistence Policy (Godot)
- **Save V2 operacional (opt-in):** `SaveV2RuntimeSaveCoordinator` + `SaveV2RuntimeSaveResult`; flag SAVE_V2_OPERATIONAL_SAVE_ENABLED (padrão OFF). Ctrl+S com flag ON = somente V2 (projeção persistente → validação → sombra sincronizada → SaveV2Service → checksum literal → game_saved), sem sandbox; o save antigo não é gravado. Slot único (`current`), mesmo arquivo do C2.
- **Load V2:** recusa com diálogo aberto (LOAD_REJECTED_TRANSIENT_DIALOGUE, nada tocado); `game_loaded` só após validação pós-restore com SUCCESS; tempos por etapa. Contrato: `is_dialogue_session_open()`. Save com diálogo aberto permitido (só o persistente).
- **Correções:** bug da esfera do Eco (`EchoMemoryInteractable.interact` resolve Visual/Light na hora; +6 linhas) — ao vivo == após load; núcleo do restaurador preserva `objective_progress` vazio de quest iniciada (Load com quest ativa sem progresso era recusado).
- **Ciclo real (Ctrl+S/Ctrl+L):** antes e depois do Eco, A → B → Load → Save → B' → Load = A, save duplo equivalente, diálogo aberto, eventos só após sucesso, saves antigos intactos (sentinela), Old Load isolado.
- **Custo medido (headless):** Load 141–214 ms em processo novo (≈99% nos dois sandboxes; apply+validação < 5 ms); Save 13–19 ms.
- **Política:** SaveService/Ctrl+S/Ctrl+L antigos = LEGACY COMPATIBILITY PATH (sem novos recursos; `save_service.gd:44` não corrigido); saves antigos não são lidos, alterados, convertidos nem apagados pelo V2; sem migração nem migrator.
- **Testes:** 1270/1270 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104 · C8 92). Sonda A0 idêntica; cena principal sem erros; legados SceneTree iguais à linha de base (3 `extends Node` não executáveis — limitação conhecida); `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C8_V2_ADOPTION_AND_OPERATIONAL_SAVE.md` (+ matriz).

### [2026-09-27] — Bloco C7: V2 Operational Load Controlado + Runtime Rollback (Godot)
- **Load V2 operacional (opt-in):** `SaveV2RuntimeLoadCoordinator` + `SaveV2RuntimeLoadResult` + `SaveV2OperationalConfig` (SAVE_V2_OPERATIONAL_LOAD_ENABLED, padrão OFF). Fluxo: rehearsal C6 em sandbox → snapshot transitório (`SaveV2RuntimeSnapshot`, nunca gravado) → rehearsal do rollback → apply no runtime principal (`GameStateRuntimeRestorer.apply_to_runtime`, mesmos adapters, só com autorização do coordenador) → validação pós-restore (persistente + funcional) → SUCCESS ou rollback verificado (0 diferenças). Estados: DISABLED · SUCCESS · LOAD_FAILURE · VALIDATION_FAILURE · RESTORE_REJECTED · APPLY_FAILURE · POST_RESTORE_MISMATCH · ROLLBACK_SUCCESS · ROLLBACK_FAILURE.
- **Ctrl+L:** flag OFF = load antigo byte a byte igual; flag ON = SOMENTE V2, sem fallback silencioso (falha mostrada/registrada, runtime preservado). Sucesso → sombra recebe cópia do estado carregado. Ctrl+S, SaveService e `save_service.gd:44` intactos (LEGACY COMPATIBILITY PATH); sem migração de saves antigos.
- **Reversão de derivados (aprovada):** `VardhelmAmbientLife.reset_persistent_state()` (aditivo), `derive_environment_state`/`derive_quest_presentation` do slice com reset, `QuestPresentationRestoreAdapter` deriva mesmo sem quest. Permite voltar a um save anterior (ex.: antes do Eco).
- **Vardhelm real (Ctrl+L):** estado inicial, antes do Eco (exato, inclusive esfera), depois do Eco (exceto KNOWN GAMEPLAY BUG da esfera), posição/rotação, diálogo, observações+fragmentos em runtime recriado, consequências sem duplicação; checksum corrompido não toca o runtime; falha no apply → rollback 0 diferenças; falha do rollback → ROLLBACK_FAILURE; runtime inconsistente → SNAPSHOT_NOT_REVERSIBLE sem tocar; idempotente; sem eventos.
- **Testes:** 1178/1178 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94 · C7 104). Sonda A0 idêntica; cena principal sem erros; `tsc --noEmit` limpo.
- **Estratégia de regressão corrigida:** tudo headless e só entrypoints `extends SceneTree`; os 6 legados SceneTree iguais à linha de base; os 3 legados `extends Node` (`memory_echoes`, `narrative_consequence`, `world_response`) não são mais executados com `--script` (abriam alerta nativo do Godot e travavam) — limitação conhecida, sem runner no projeto; nenhum teste legado alterado.
- **Documentação:** `docs/architecture/BLOCK_C7_V2_OPERATIONAL_LOAD.md` (+ matriz).

### [2026-09-27] — Bloco C6: V2 Diagnostic Load + Failure Policy (Godot)
- **Pipeline diagnóstico de ponta a ponta:** `SaveV2DiagnosticCoordinator` (save → arquivo → load → envelope → checksum → GameState → RestorePlan → sandbox novo → adapters → verificação → comparação) + `SaveV2DiagnosticReport`, `SaveV2DiagnosticConfig` (flag SAVE_V2_DIAGNOSTIC_ENABLED, padrão OFF, objeto local sem Autoload) e contrato `SaveV2DiagnosticSandbox` (Vardhelm: `VardhelmDiagnosticSandbox`, instância isolada sem input/processamento/Save V2 sombra). Arquivo próprio `user://echoes_of_the_soul_save_v2_diagnostic.json`; formato C1 inalterado.
- **Failure policy:** SUCCESS · PARTIAL_FAILURE · FAILURE · CORRUPTED_DATA · INVALID_SAVE · UNSUPPORTED_SCHEMA · RESTORE_REJECTED (+ DISABLED), com código específico; plano com unsupported/requires_adapter recusado antes do sandbox; qualquer falha após criar o sandbox o descarta; nunca "best effort". Rollback do jogo principal: requisito do C7.
- **Vardhelm real:** antes e depois do Eco o sandbox reproduz o estado funcional do jogo (posição exata, rotação, diálogo, 3 observações, fragmentos, memória do Eco, consequências com origem do catálogo, NPC, apresentação); única divergência = KNOWN GAMEPLAY BUG da esfera. Old Load × V2 em instâncias isoladas: V2 == esperado; Old Load aborta em `save_service.gd:44` antes de quests/Player e não tem diálogo (registrado, não corrigido). Idempotente, sem duplicação, jogo principal com ZERO diferenças e ZERO eventos.
- **Não operacional:** Ctrl+S/Ctrl+L/SaveService intactos; nenhum código de gameplay chama o coordenador; GameState segue sombra.
- **Testes:** 1074/1074 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86 · C6 94). Sonda A0 idêntica; cena principal sem erros; testes legados inalterados; `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C6_V2_DIAGNOSTIC_LOAD.md` (+ matriz).

### [2026-09-27] — Bloco C5: Runtime Contract Hardening + Dialogue Restore Contract (Godot)
- **Dialogue Runtime Contract:** `DialogueRuntimeState` (`godot/scripts/dialogue/`) — parte persistente (concluídos + última escolha por dialogue_id + entry_id; identidade por IDs, nunca texto/falante/índice) e lista explícita do que é transiente. Dono: `DialogueController.persistent_state` (+7 linhas aditivas; só registra, nenhum gameplay consulta). `DialogueRestoreAdapter` agora restaura no sandbox: `dialogue.completed`/`dialogue.choices` = adapter-supported; sem destino/definição → requires_adapter; escolha inexistente → unsupported.
- **Runtime Derivation Contract:** `RuntimeStateDerivationContract` (`godot/scripts/save_v2/`) + `VardhelmRuntimeStateProvider` (`godot/scripts/vardhelm/`). `RuntimeRestoreTargets` sem Callables nem nós da experiência; o slice ganhou só 3 métodos públicos `derive_*` que delegam às derivações existentes (+12 linhas). Save V2/GameState sem nenhuma referência ao slice (testado por varredura de código).
- **Projetor:** parâmetro opcional `dialogue_state` (ausente = comportamento anterior).
- **Fluxo real de Vardhelm:** 13 supported · 10 adapter-supported · 0 requires_adapter · 0 unsupported · 1 not_implemented. Sandbox × GameState V2: 0 diferenças, nada faltando (diálogo incluído); GameState original == restaurado. KNOWN GAMEPLAY BUG da esfera do Eco registrado, não corrigido. Jogo principal: zero diferenças.
- **Não operacional:** Ctrl+S/Ctrl+L/SaveService intactos; GameState segue sombra.
- **Testes:** 980/980 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 83 · C5 86). Sonda A0 idêntica; cena principal sem erros; testes legados inalterados; `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C5_RUNTIME_CONTRACT_HARDENING.md` (+ matriz).

### [2026-09-26] — Bloco C4: Runtime Restore Adapters (Godot)
- **`RuntimeRestoreAdapterRegistry`** (objeto comum, sem Autoload) + `RestoreAdapter`/`RestoreAdapterResult` e 7 adapters em `godot/scripts/save_v2/adapters/`: consequence, observation, echo, memory, dialogue, quest_presentation, environment_presentation. Só usam propriedades públicas e derivações já existentes do runtime (injetadas como `Callable` em `RuntimeRestoreTargets`); nenhum MemoryState/EchoState/DialogueState paralelo, nenhum evento.
- **Restaurador:** `GameStateRuntimeRestorer.new(registry)` (sem registry = C3), novo status `adapter-supported`, ordem `scenario → player → world → consequences → observations → quests → echo → memory → npcs → dialogue → presentation → progression`, erro de adapter → `partial_failure`.
- **Fluxo real de Vardhelm:** 13 supported · 8 adapter-supported · 2 requires_adapter (só diálogo) · 0 unsupported · 1 not_implemented. Sandbox reproduz o estado funcional do jogo (Eco, marcador, banner, objetivo, `echo_awakened`, observação, NPC) — antes e depois do Eco; sandbox × GameState V2: 0 diferenças. Divergência única: esfera do Eco visível no jogo ao vivo (defeito pré-existente de `EchoMemoryInteractable`, não corrigido). Jogo principal: zero diferenças.
- **Não operacional:** não ligado a Ctrl+L/SaveService; GameState segue sombra.
- **Testes:** 893/893 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111 · C4 82). Sonda A0 idêntica; cena principal sem erros; `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C4_RUNTIME_RESTORE_ADAPTERS.md` (+ matriz e nota no C3).

### [2026-09-26] — Bloco C3: Runtime State Restore / Load Diagnostic (Godot)
- **`GameStateRuntimeRestorer`** + `RestorePlan`, `RestoreResult`, `RuntimeRestoreTargets` (`godot/scripts/save_v2/`): MODE 1 diagnóstico (plano por campo com destino/ação/status, sem mutação) e MODE 2 sandbox (aplica só em alvos marcados sandbox, com pré-checagem, ordem de dependência e `partial_failure`). Escreve só nas representações existentes do runtime (Player, WorldState, QuestState, NPCController); diálogo, memória, Eco e apresentação = `requires_adapter`; progression = `not_implemented`.
- **Fluxo real de Vardhelm:** 13 supported · 10 requires_adapter · 0 unsupported · 1 not_implemented. Sandbox (2ª instância da cena) restaurado × GameState V2: 0 diferenças, 0 IDs inesperados; só o DialogueState falta. Jogo principal intacto; Ctrl+L segue o load antigo; nenhum evento publicado.
- **Não operacional:** não ligado a Ctrl+L, ao SaveService nem ao coordenador; GameState segue sombra.
- **Testes:** 811/811 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33 · C3 111). Sonda A0 idêntica. `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C3_RUNTIME_STATE_RESTORE.md` e `GAMESTATE_RUNTIME_RESTORE_MATRIX.md`.

### [2026-09-26] — Bloco C2: Dual Save / Dual Load em Modo Sombra (Godot)
- **`SaveV2ShadowCoordinator`** (objeto de runtime, sem Autoload): ligado ao Ctrl+S/Ctrl+L reais **depois** do `SaveService` antigo, que continua operacional. Save: grava o GameState sombra no Save V2 e publica `game_saved` só após sucesso. Load: carrega o V2, publica `game_loaded` só após sucesso e compara o estado carregado com o runtime pós-load antigo e com a sombra — nada é restaurado e a sombra não é ressincronizada.
- **Slice:** ganchos aditivos em `_unhandled_input` e no setup (`vardhelm_vertical_slice.gd` +44/−0 vs `a526cc4`, A3+B1+C2). `save_service.gd`, InputMap e UI **inalterados**; bug de load antigo preservado. Catálogo: `game_saved`/`game_loaded` deixam de ser reservados. Recorder: getter `tracked_player()`.
- **Resultado com input real:** gameplay idêntico a um controle sem V2; V2 × runtime pós-load antigo sem diferenças (exceto DialogueState, invisível ao projetor); V2 × sombra expõe o que mudou depois do save; com frames reais também a posição do jogador (assentamento por gravidade, não restaurada pelo load antigo). Falhas do V2 (IO_ERROR/FILE_NOT_FOUND/CORRUPTED_DATA) ficam só no relatório, sem evento.
- **Testes:** 700/700 checks PASS (A2 203 · A3 99 · B1 147 · C1 218 · C2 33); runner espera um frame entre suítes para isolar cenas. Sonda A0 idêntica. `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C2_DUAL_SAVE_SHADOW.md` (+ notas em B1/C1).

### [2026-09-26] — Bloco C1: Save V2 em Modo Sombra (Godot)
- **`godot/scripts/save_v2/`:** `SaveV2Envelope` (`format` = `echoes_of_the_soul_save`, `schema_version` 2 independente de `state_version` 1, `game_version` constante `0.1.0-dev`, metadata técnica), `SaveV2Serializer` (GameState via contrato A2; forma canônica determinística), `SaveV2Checksum` (SHA-256 da forma canônica sem o campo checksum), `SaveV2Validator` (estrito, sem fallback), `SaveV2Errors`/`SaveV2Result` (códigos explícitos) e `SaveV2Service` (`save_game_state`/`load_game_state`/`has_save`/`delete_save`; caminho próprio `user://echoes_of_the_soul_save_v2_shadow.json`; escrita atômica .tmp → verificação → rename com .bak).
- **Achado:** o parser JSON do Godot 4.7.1 não devolve o mesmo double para ~17,7% dos floats (medido); por isso o checksum é verificado sobre o texto canônico gravado, não sobre números relidos. `Vector3` volta exato.
- **Isolamento:** `SaveService`, Ctrl+S/Ctrl+L, gameplay e EventBus **inalterados**; Save V2 não publica `game_saved`/`game_loaded`; GameState segue sombra.
- **Testes:** runner `godot/tests/state/state_test_runner.gd` — 667/667 checks PASS (A2 203 · A3 99 · B1 147 · C1 218), incluindo 13+ round trips, 19 cenários de corrupção e o GameState real de Vardhelm. Sonda A0 idêntica ao B1/A3. `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_C1_SAVE_V2_SHADOW.md`.

### [2026-09-26] — Bloco B1: Eventos Estruturados — Modo Não Invasivo (Godot)
- **`godot/scripts/events/`:** `GameEvent` (imutável, JSON, `event_id`/`tick` sequenciais, sem relógio do SO), `GameEventCatalog` (16 tipos genéricos; `scenario_completed` preparado; `game_saved`/`game_loaded` reservados ao Bloco C), `GameEventBus` (objeto de runtime, sem Autoload; subscribe/unsubscribe/publish; entrega FIFO; valida payload e rejeita Node/texto de UI), `GameplayEventPublisher` (adaptador somente leitura dos sinais existentes → eventos com IDs canônicos; uma vez por acontecimento) e `RecordedEvents` (diagnóstico).
- **Fluxo:** gameplay → publisher → bus → `GameStateShadowRecorder` (agora consumidor de eventos; único que escreve no GameState). GameState segue em modo sombra.
- **Catálogo de IDs:** `envstate.vardhelm.*` e busca reversa de alias (aditivo).
- **Slice:** integração aditiva (`vardhelm_vertical_slice.gd` +35/−0 vs `a526cc4`, A3+B1). SaveService, controladores, UI e áudio **inalterados**.
- **Ordem real do Primeiro Eco:** consequence_applied → world_state_changed → quest_progressed → quest_completed → echo_triggered → memory_recovered (documentada, não forçada). Sem duplicações; projetor não publica.
- **Testes:** runner `godot/tests/state/state_test_runner.gd` — 449/449 checks PASS (A2 203 · A3 99 · B1 núcleo 86 · B1 Vardhelm 61). Sonda A0 inalterada: saída idêntica ao A3. `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_B1_STRUCTURED_EVENTS.md`.

### [2026-09-26] — Bloco A3: GameState em Modo Sombra (Godot)
- **`GameStateShadowRecorder`** (objeto de runtime, sem Autoload): nasce em `VardhelmVerticalSlice._setup_shadow_game_state()` e acompanha, por sinais já existentes, cenário, escolha de diálogo (última por ponto), diálogo concluído, quests, consequências (→ `world.consequences`, nunca memórias), Primeiro Eco (echo resolvido + `memory.vardhelm.first_echo`), observações e fragmentos de memória (sem consequência/reação). Posição do jogador e estado de NPC são amostrados. O runtime atual continua sendo a fonte de verdade.
- **`GameStateComparator` / `GameStateComparison`:** comparação estrutural sombra × projetor (iguais, diferenças, ausentes, IDs inesperados), sem correção automática.
- **Integração:** `vardhelm_vertical_slice.gd` +22/−0 linhas (aditivo). `SaveService`, controladores, AmbientLife, observações, NPC e LevelBuilder **inalterados**.
- **Testes:** runner `godot/tests/state/` — 300/300 checks PASS (203 A2 + 97 A3, incluindo o fluxo real de Vardhelm). Sombra × projetor no fluxo real: 0 diferenças, 0 IDs inesperados; única divergência esperada = DialogueState (invisível ao projetor). Sonda A0 inalterada: saída idêntica exceto `memory_signal_connections 0 → 1` (o próprio registro paralelo). `tsc --noEmit` limpo.
- **Documentação:** `docs/architecture/BLOCK_A3_SHADOW_GAME_STATE.md`.

### [2026-09-26] — Bloco A2: Contrato em Código do GameState (Godot)
- **Contratos puros (`godot/scripts/state/`):** `GameState` (`state_version = 1`) com `GamePlayerState` (cenário + posição/rotação exatas), `GameWorldState` (flags / values / consequences / observations separados; `environment_states` derivado), `GameQuestState` (status + objetivos), `GameDialogueState` (concluídos + última escolha por ponto), `GameMemoryState` (Ecos resolvidos + memórias com origem echo/observation — fragmentos) e `GameNPCState` (só diferenças do padrão). `progression` reservado. Prefixo `Game` evita colisão com os `class_name` de runtime `WorldState`/`QuestState`.
- **Serialização R2 (`GameStateSerde`):** só tipos JSON, `Vector3 ↔ [x,y,z]`, conversão explícita (nenhum Array do JSON atribuído a coleção tipada), comparações seguras contra tipos inesperados.
- **Catálogo de IDs (`GameIdCatalog`):** IDs canônicos `kind.scope.name` e aliases como dado; nenhum conteúdo renomeado.
- **Projetor somente leitura (`GameStateProjector`) + migração preparatória pura (`GameStateMigrator`):** separa consequências de memórias em `WorldState.memories`, converte observações e quests, registra o Primeiro Eco como memória (decisão A1 #2) sem reaplicar a consequência pela quest (#4), e envia IDs desconhecidos para quarentena. Não usados pelo jogo; Save/Load, `SaveService`, `VardhelmVerticalSlice` e controladores **inalterados**.
- **Documentação:** `docs/architecture/BLOCK_A1_CANONICAL_GAME_STATE.md` com as 8 decisões humanas aprovadas.
- **Testes:** `godot/tests/state/` (runner `SceneTree` próprio) — 203/203 checks PASS no Godot 4.7.1 headless. Regressão: cena principal e sonda de fluxo de Vardhelm idênticas ao A0; testes Godot antigos com o mesmo resultado do A0; `tsc --noEmit` limpo.

### [2026-07-27] — Anomalias de Duto & Eventos de Travessia (HEAD)
- **HazardEventEngine.ts (novo):** eventos ambientais aleatórios sorteados por `hazardLevel` (RNG injetável). 3 anomalias táticas com mitigação: **Vazamento de Gás Químico** (filtro −1 mantimento / correr → CHEMICAL_POISON 2 turnos / severo → +10 Paterno e dano ao líder), **Sobrecarga de Vapor** (desviar −1 sucata → +5 EP / forçar → STEAM_BURN) e **Surtos Elétricos** (descarregar → −5% durabilidade, pode oxidar / contornar → −1 mantimento).
- **GameLoop:** `performTraversal` sorteia a anomalia pelo perigo do nó de destino e a devolve; a tela de evento (narrativa + opções + feedback imediato) precede o processamento do destino (`processArrival`). Seam de RNG injetável (`setHazardRng`) para testes determinísticos.
- **Testes:** `HazardEventIntegration` 20/20 (sorteio, mitigação por recurso, status/dano/estafa, disparo via GameLoop). Type-check limpo; regressão verde.

### [2026-07-25] — Acampamento & Gestão de Grupo (REST_SITE)
- **CampingEngine.ts (novo):** `restAndFeed` (−2 mantimentos → +40% HP / +50% EP; descanso parcial só-EP com alerta de SURVIVAL_CRISIS), `fieldRepair` (reparo com sucata, remove *Rusted* acima de 25%), `adjustFormation` e `campConversation` (±10 Estafa Paterno/Materno).
- **EP persistente:** `CharacterState` ganhou `currentEp`/`maxEp` (MAX_EP=100); a `InteractiveCombatSession` passa a semear e sincronizar o EP a partir do `CharacterState` (descanso restaura o EP entre combates).
- **CampaignManager:** `reorderParty` e `swapFormationPositions` (Vanguarda/Retaguarda).
- **Mapa & GameLoop:** novo tipo de nó `REST_SITE` (Bivaque Selado); ao chegar, abre a tela de Acampamento; "Levantar Acampamento & Marchar" dispara o AutoSave.
- **Testes:** `CampingIntegration` 25/25 (descanso HP/EP, parcial, reparo de oxidado, formação, conversa, persistência pós-acampamento). Type-check limpo; regressão verde.

### [2026-07-25] — Integração de Missões: GameLoop, Gatilhos & Persistência
- **QuestManager estendido:** tipos `MAIN`/`SIDE`, metas tipadas (`REACH_NODE`/`DEFEAT_ENEMIES`/`KILL_BOSS`/`TALK_NPC`), gatilhos `notifyNodeVisited`/`notifyEnemiesDefeated`/`notifyNpcTalked`, `getActiveMainQuest`/`getCurrentGoal`, `claimQuestReward` (XP/Sucata/Mantimentos) e `serializeState`/`restoreState`. Catálogo em `QuestContent.ts` (missão principal + secundária).
- **GameLoop:** registra/ativa quests no novo jogo; HUD mostra a **Missão Principal** e a etapa atual; "Ver Diário de Missões" lista principal/secundárias/concluídas; gatilhos disparam na travessia (nó), na vitória de combate (inimigos) e no fim de diálogo (NPC); recompensas concedidas ao grupo automaticamente.
- **Persistência:** `SaveSlotEngine` serializa/reidrata o estado das quests (`quests` no payload), com auto-migração para saves legados (checksum SHA-256 preservado).
- **Testes:** `QuestIntegration` 22/22 (gatilhos → conclusão → recompensa → salvar/carregar). Type-check limpo; regressão verde.

### [2026-07-25] — Persistência de Habilidades & Árvore de Talentos no SaveSlotEngine
- **Schema de save expandido:** `ISavedCharacter` ganha `learnedAbilityIds` (habilidades ativas aprendidas) e `unlockedSkillNodes` (nós passivos da árvore). `saveToSlot` captura ambos via `ProgressionManager`/`SkillTreeEngine` (opções); checksum SHA-256 preservado.
- **Reidratação na carga:** `applyPayloadToCampaign` reconstrói as habilidades do catálogo canônico (`CANONICAL_ABILITIES`) e reaplica os bônus passivos via `SkillTreeEngine.restoreUnlockedNodes` (novo). `GameLoop.loadSlot` passa o `skillTree`; `startNewGame` inicializa a árvore.
- **Auto-migração:** saves legados recebem o **starter kit** de habilidades e árvore vazia, mantendo a integridade do checksum (validação antes da migração em memória).
- **Testes:** `SkillTreeSaveIntegration` 19/19 (ciclo aprender→salvar→carregar→validar + migração legada). Type-check limpo; regressão verde.

### [2026-07-25] — Sprint Dupla: Habilidades no Combate & Economia de Mercador
- **Opção 1 — Habilidades ativas no combate:** `CombatAbilities.ts` (kit canônico: Golpe de Forja, Descarga de Ferrugem, Solda de Sobrevivência); `CharacterState` aprende habilidades; `SkillTreeEngine.grantStarterAbilities` faz a ponte. `InteractiveCombatSession` ganha **pool de EP** (regen modulado pelo bônus Materno), **cooldowns**, opções de habilidade e `submitAbility` — com **gating pela Estafa** (agressivas travadas no Materno; suporte no Paterno), custo de EP efetivo (encarecido no Paterno), aplicação de status via `StatusEngine` e feedback loop de Estafa.
- **Opção 2 — Mercador & economia de sucata:** `TraderManager` ganha `buySupplies` (sucata → mantimentos), `repairEquipment` (reparo via `EquipmentEngine`) e estoque de equipamento; `GameLoop` abre a interface de mercador ao chegar em nós `SCRAP_TRADER`, persistindo no AutoSave.
- **Testes:** `CombatSkillsIntegration` 19/19 e `TraderIntegration` 18/18. Type-check limpo; regressão verde.

### [2026-07-25] — Diretriz de Documentação Contínua
- **Implementado:** `CLAUDE.md` na raiz formaliza a regra de **commit atômico** (código + `PROJECT_CHANGELOG.md` sempre no mesmo commit). A partir daqui, toda entrega atualiza este changelog junto do código.

### [2026-07-25] — Ganchos de Nó: Diálogos Ancorados & Reabastecimento
- **Commit:** `708506c`
- **Commit:** `708506c`
- **Implementado:** nós do mapa ganham `dialogueId` e `supplyRestock`. `traverseToNode` reabastece mantimentos (limpando crise) e o CLI dispara o diálogo ancorado ao chegar (Condutos de Vapor → Autômato Preso; Refúgio → Engenheira Ferida).
- **Testes:** +4 em `CampaignNavigationIntegration`, +7 na seção H de `GameLoopCLIIntegration`.

### [2026-07-25] — Expansão de Conteúdo (Bestiário, Mapa Ato 2, Diálogos)
- **Commit:** `a60aba9`
- **Implementado:** 5 novos templates de inimigo (tiers 2–5, incl. chefe **Colosso de Ferrugem** t5); ramificação do mapa para o Ato 2 (Refúgio, Condutos de Vapor, Fundição, Santuário Enferrujado, Mercado das Profundezas, Reator Central); 2 diálogos ramificados por Estafa.

### [2026-07-25] — Progressão, Recompensas & Game Over
- **Commits:** `0e27fbd`, `aeae4cc`, `c932b40`, `f45c36b`, `8dc7e9e`
- **Implementado:**
  - `CombatRewardEngine.ts` — sucata (LootEngine) + XP/level-up (ProgressionManager) na vitória.
  - Persistência de XP por personagem no `SaveSlotEngine` (migração de saves antigos).
  - Fluxo de **Game Over** no defeat (Carregar/Novo Jogo/Sair) + `isPartyWiped()`.
  - **Drops de itens** por template de inimigo (materiais/consumíveis/equipamento).
  - **Escala de atributos por nível** (DRF) reaplicada em level-up e no load.
- **Testes:** `CombatRewardEngine` 10/10; seções de Game Over, drops e level-scaling verdes.

### [2026-07-25] — Combate Interativo & Feedback Loop da Estafa
- **Commits:** `ecd27e8`, `6047dea`, `89f897c`
- **Implementado:**
  - `CombatLoopEngine.ts` — combate headless por turnos (ordem por velocidade, DoT, mitigação hiperbólica, IA de alvo).
  - `InteractiveCombatSession.ts` — o jogador escolhe a ação de cada herói (Atacar / Execução Fria / Cura Compassiva), gated pela Balança de Estafa (Insubordinação Tática → ação autônoma).
  - **Feedback loop:** ações de combate deslocam a Estafa (Execução → +Paterno, Cura → −Materno), re-gating dinâmico e persistência no grupo.
- **Testes:** `CombatLoopEngine` 14/14; `InteractiveCombatSession` 32/32.

### [2026-07-25] — Bestiário & Geração de Encontros
- **Commits:** `f131fa5`, `ae04ce1`
- **Implementado:** `BestiaryEngine.ts` (templates: Rato Químico, Batedor Catador, Autômato Oxidado, Guardião de Vapor; `generateEncounter` escalado por hazard/nível; RUST_LOCK ambiental; `ENEMY_TO_COMBAT_ARCHETYPE`). Integrado ao `GameLoop` — nós de combate/emboscada geram encontros na travessia.
- **Testes:** `BestiaryEngine` 25/25.

### [2026-07-25] — Multi-Slot Save Engine & GameLoop CLI v2.0
- **Commits:** `8f34e7d`, `5398a79`
- **Implementado:** `SaveSlotEngine.ts` (4 slots, checksum SHA-256, migração de schema, AutoSave) e `GameLoop.ts` refatorado (Menu Principal, HUD de grupo, preview de duto, travessia + AutoSave).
- **Testes:** `SaveSlotEngine` 34/34; `GameLoopCLIIntegration` (base) verdes.

### [2026-07-25] — Assets via Git LFS
- **Commit:** `0b71943`
- **Implementado:** Git LFS (`.gitattributes` para `assets/**/*.png`), padronização de extensão PNG (correção de `.png.png`) e inclusão de 11 artes (6 portraits + 5 spritesheets, ~26 MB fora do histórico).

### [2026-07-24] — Consolidação de Engines Pré-existentes & Tooling
- **Commit:** `98b5451`
- **Implementado:** versionamento de `QuestManager`, `SkillTreeEngine`, `TraderManager`, `ArenaHazardEngine`, `StatusEffectEngine` e seus testes; scripts `test`/`build` e devDependency `tsx` no `package.json`.

### [2026-07-24] — Status Engine Tático
- **Commit:** `53133de`
- **Implementado:** `src/core/StatusEngine.ts` — condições `CHEMICAL_POISON`, `STEAM_BURN`, `SPARK_OVERCHARGE`, `RUST_LOCK` (empilhamento, DoT, penalidades de atributo refletidas nos getters do `CharacterState`). Distinto do motor TECH_* legado.
- **Testes:** `StatusEngineTactical` 24/24.

### [2026-07-24] — Navegação de Campanha (Recursos, Desgaste, Estafa)
- **Commit:** `afc7d3a`
- **Implementado:** `CampaignMapEngine.traverseToNode` — consumo de `supplies`, degradação de durabilidade dos equipamentos, deslocamento de Estafa por perigo e estado `SURVIVAL_CRISIS` por escassez.

### [2026-07-24] — Durabilidade, Oxidação e Reparo
- **Commit:** `f2fee53`
- **Implementado:** modelo `IDurableEquipment` no `EquipmentEngine` — durabilidade, `isRusted` (≤25% → penalidade de 50%), degradação e reparo via sucata; integração com `CharacterState.getEffectivePhysicalDefense`.

### [2026-07-24] — Diálogos com Locks Diegéticos
- **Commit:** `ac40ea4`
- **Implementado:** `DialogueEngine` integrado ao `EstafaCalculator` — `getAvailableOptions` marca opções incompatíveis como travadas; `selectOption` aplica o `estafaShift` clampado ao grupo.

### [2026-07-24] — Integração da Estafa ao Combate
- **Commit:** `f8c1837`
- **Implementado:** `CharacterState.getEffective*` moduladas pela Estafa; `CombatAIEngine.resolvePlayerCommand` (Insubordinação Tática); seam `resolveCombatCommand` no GameLoop.

### [2026-07-24] — Mecânica-Core: Balança de Estafa
- **Commits:** `6dc2b91`, `e73d1b0`
- **Implementado:** `src/mechanics/EstafaCalculator.ts` — `calculateModifiers`, `getQuadrant`, `validateAction` (clamp [-100,+100]); testes unitários (42/42) e doc formal `docs/mechanics/ESTAFA_SYSTEM.md`.

### [2026-07-24] — Blueprint Mestre & Bíblia de Arte
- **Commits:** `9f7863f`, `ada07c5`, `cf23dfb`, `b8cbde0`, `7be16c5`
- **Implementado:** `AETHERIS_MASTER_INDEX.md` (fonte única da verdade); calibração de prompts HD-2D (Anões, Fadas, Lurídeos); padrão de Portraits "Card de UI com Caixa de Diálogo Integrada"; consolidação/migração de prompts (Tier 1/2, exceção Veredito do Tier 3).

---

## 🧪 Convenção de Testes
- Cada suite é um script executável via `npx tsx src/test/<suite>.test.ts`, com harness próprio (`assert` + relatório).
- Validação padrão de cada entrega: `npx tsc --noEmit` (type-check global) + execução das suites afetadas.

## 📌 Índice de Documentação
- [`AETHERIS_MASTER_INDEX.md`](AETHERIS_MASTER_INDEX.md) — blueprint mestre do produto e regras de sistema.
- [`docs/mechanics/ESTAFA_SYSTEM.md`](docs/mechanics/ESTAFA_SYSTEM.md) — especificação da Balança de Estafa.
- [`doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md`](doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) — direção de arte HD-2D.
- [`doc/art_bible/PROMPTS_MESTRES_ARTE.md`](doc/art_bible/PROMPTS_MESTRES_ARTE.md) — prompts canônicos de geração.
