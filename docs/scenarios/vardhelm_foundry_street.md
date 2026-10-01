# Vardhelm — Rua do Distrito das Fundições

> Documento de cenário criado pelo [`SCENARIO_TEMPLATE.md`](../architecture/SCENARIO_TEMPLATE.md), no Bloco C23 ([`BLOCK_C23_FOUNDRY_STREET.md`](../architecture/BLOCK_C23_FOUNDRY_STREET.md)).
> **Referências canônicas:** [`VARDHELM_ACT1_CANON.md`](../lore/VARDHELM_ACT1_CANON.md) (§1, §2, §10 Fase 4) e [`LORE_REVELATION_MATRIX.md`](../lore/LORE_REVELATION_MATRIX.md) (camada 1).
> **Origens:** [DOC] documento · [DH] decisão humana (C22.1/C23) · [PROD] decisão de produção deste bloco (não é cânone) · NÃO DEFINIDO.

# IDENTIDADE

| Campo | Valor |
|---|---|
| Nome | Rua do Distrito das Fundições |
| ID (Godot) | área de `scenario.vardhelm` (sem ID de cenário novo) |
| ID documental | NÃO DEFINIDO (o `LOC-` do distrito continua só proposto: `LOC-VAR-001`) |
| Localização | Vardhelm, Distrito das Fundições, diante do complexo da Forja 01, saindo pelo **portão sul do pátio** [DH] |
| Função narrativa | **Fase 4: abertura do mundo.** A transição entre o microcosmo da Forja e **Vardhelm como cidade**, preparando a investigação (Fase 5) [DH] |
| Função no mundo | **rua de serviço industrial**: carvão e minério chegam pela linha da rua; as fundições recebem e despacham; trabalhadores circulam, conferem turnos e afiam ferramentas [PROD, coerente com TIER1 §1.4.1] |
| Fontes | [DOC] TIER1 §1.1 e §1.4.1 (fundições, chaminés, "workers hauling coal carts", "heavy chain pulleys", céu encoberto), TIER3 §2.3.3; [DH] C22.1 (a rua como extensão espacial; papel de transição) |

# CONCEITO

- **O que é?** A rua que passa diante do complexo da Forja 01: a calçada das fundições, com uma linha de trilho no meio.
- **Por que existe?** Para o material entrar e sair das fundições (carvão, minério, caixas) e para as pessoas chegarem ao trabalho.
- **O que acontece aqui todo dia?**
  - os vagões de minério esperam na linha;
  - o carrinho de mão leva carga de uma ponta à outra;
  - os carregadores descem caixas da doca;
  - a talha do armazém sobe e desce carga;
  - um trem de carga passa devagar no corredor atrás do muro;
  - dois trabalhadores conversam diante do quadro de turnos;
  - outros esperam a vez na pedra de afiar.
- **Quem usa?** Trabalhadores anônimos: carregadores, conferentes, quem afia ferramentas, quem varre e quem passa a caminho de outras fundições.
  - NPCs nomeados: **nenhum**.
  - Durn fica na Forja [DH].

**Normalidade primeiro [DH]:** a rua funciona para quem ignora o mistério. O único traço do Primeiro Eco é o texto pós-Eco do portão (§NARRATIVA AMBIENTAL), que **repete um fato já estabelecido** (C13: "máquinas mais baixas") visto de fora.

# ARQUITETURA

| Campo | Valor |
|---|---|
| Estrutura | uma faixa de 56 × 15 m (x −28…28, z 32…47), no chão do pátio (y −11,9) |
| Lado norte (alto, ao fundo para a câmera) | **fachada da fundição oeste** (10 m, porta escura, janelas acesas, quadro de turnos); **muro do pátio** com o **portão sul aberto** (folhas de grade abertas para dentro do pátio); **fachada do armazém leste** (8 m), com **doca** (0,9 m) e **talha de braço** |
| Lados sul, oeste e leste (baixos, em corte: a câmera olha de sudeste) | muros de 1,1 m. Ao sul, o **corredor ferroviário** com trem de carga; a oeste, a **cancela fechada** com vagões além; a leste, um muro baixo |
| Materiais | tijolo com fuligem (shader da Forja); pedra em placas; ferro escurecido e gasto; madeira velha; lona; minério; carvão |
| Escala e profundidade | **primeiro plano:** rua jogável. **Segundo plano:** fachadas, doca, talha, vagões, trem. **Fundo:** a Forja 01 e a fundição oeste ao norte; a rua continuando a oeste além da cancela (esquinas, janelas acesas, poste); névoa |
| Entradas e saídas | **só o portão sul do pátio** (andando, sem transição) |

**Regras aplicadas:**
- colisão = geometria;
- cenário distante sem colisão;
- nada alto a sudeste;
- caminhos obrigatórios medidos com a cápsula real.

# FUNÇÃO

| Elemento | Por que está ali |
|---|---|
| Ramal do pátio → linha da rua (junção em frente ao portão) | o carvão do pátio chega pela rua |
| Vagões de minério na linha (oeste) | o minério espera a fundição oeste |
| Porta da fundição oeste + quadro de turnos | por onde os trabalhadores entram; a escala de trabalho |
| Armazém, doca, talha de braço | carga e descarga; caixas descendo para a rua |
| Pedra de afiar com banco | manutenção na calçada, compartilhada pelas fundições |
| Corredor ferroviário com trem | o transporte maior da cidade, atrás do muro |
| Cancela fechada a oeste | a rua segue, mas a passagem está fechada pela linha |
| Postes, bueiro com vapor, drenagem, poças, carvão e minério caídos | uso e desgaste |

# CIRCULAÇÃO

- **Caminho principal:** pátio → portão sul (vão livre de **5,85 m**) → centro da rua; depois leste ou oeste ao longo da faixa central (z 36–41).
- **Larguras reais medidas com a cápsula do jogador**, em 5 seções transversais, com os trabalhadores no lugar: **9,15 / 14,55 / 14,8 / 14,55 / 10,35 m** (mínimo exigido: 1,5 m).
- **Desvios exploráveis:** o canto do quadro de turnos, o lado dos vagões, a pedra de afiar e a frente da doca.
- **Bloqueios naturais:** fachadas, doca (0,9 m), muros baixos, cancela, vagões, banco e estrutura da afiação, pallets, barris.
- **Rotas de NPC:** faixas separadas (pedestres em z 37,8–40, carrinho em z 41,2, varredor em z 42,5, inspetor em z 46,2 atrás dos vagões). Ninguém fica parado dentro do portão.
- **Orientação sem HUD:** o portão, os trilhos que saem dele, a linha da rua, o fluxo de trabalhadores e os lampiões.

# VIDA

12 trabalhadores anônimos (`foundry_street_life.json`), com silhueta humana e corpo leve (C17.3):
- **7 andando, virados para onde vão:**
  - carrinho de mão com carga baixa;
  - 2 pedestres, um vindo da porta da fundição e um passando pela rua;
  - 2 carregadores com caixas, entre a doca e a rua;
  - o inspetor dos vagões;
  - o varredor.
- **5 parados com função, virados para o que fazem:**
  - a dupla conversando no quadro de turnos;
  - o afiador;
  - 2 esperando a vez.

**Movimento de cenário:** carga da talha subindo e descendo, pedal da pedra de afiar, trem de carga no corredor, vapor do bueiro, fumaça no telhado do armazém.

# ATMOSFERA

- **Névoa e luz:** a mesma área de névoa e luz ambiente do pátio, ampliada para cobrir a rua (céu encoberto).
- **Lampiões:** 3 lampiões de querosene (porta da fundição e dois postes), sem sombra.
- **Emissivos:** só as janelas acesas, sem ciano.
- **Paleta:** chumbo, sépia, fuligem, ferrugem, lona, madeira velha, ferro.
- **Áudio:** os mesmos loops ambiente do slice (nada novo).

# NARRATIVA AMBIENTAL

4 observações, textos curtos (até 110 caracteres):

| Observação | Texto | Ensina |
|---|---|---|
| Portão do pátio | "O portão do pátio da Forja 01 dá direto na rua. O trilho do carvão passa por baixo dele." | onde a Forja fica na cidade |
| Portão do pátio, **depois do Eco** | "Daqui da rua, a Forja 01 soa mais baixa que as outras fundições." | a pergunta "aquilo afetou só a Forja?" sem resposta nem novo fenômeno |
| Quadro de turnos | "Turnos a giz, riscados e refeitos. Os nomes mudam; os horários continuam os mesmos." | trabalho e rotina |
| Vagões de minério | "Chegam pela linha da rua cheios de minério e voltam vazios para buscar mais." | circulação de material |
| Pedra de afiar | "Ferramentas de várias fundições esperam a vez. Cada cabo tem a marca do dono riscada." | manutenção; a rua serve a muitas fundições |

**Não aparecem [DH]:**
- Aethel, Asterion, Homem Cinzento, Último Experimento, Véu;
- Elyra, Kael, Lurídeos, Édor;
- combate;
- um segundo Eco.

# INTERAÇÃO

- 4 `EnvironmentalObservation`: E, prioridade 2, dica "E • Examinar" pelo ciclo do C18.
- A passagem pátio ↔ rua é **andando pelo portão**: não precisa de interação nem de `TransitionPoint`.
- Os trabalhadores não são candidatos de interação.

# ESTADOS

| Elemento | Tipo | Fonte / restauração |
|---|---|---|
| Observações da rua vistas | **PERSISTENTE** | flags → `world.observations` (ID canônico) → Save V2 → `ObservationRestoreAdapter` |
| Posição e rotação do jogador na rua | **PERSISTENTE** | `player.location` |
| Área (pátio ou rua), névoa, luz, desenho | **DERIVADO** | posição (`Area3D`) |
| Texto pós-Eco do portão | **DERIVADO** | flag `vardhelm_first_echo_complete` (C13) |
| Rotinas e direção dos trabalhadores, animações, partículas | **DERIVADO / TRANSITÓRIO** | dados; recriados no `_ready`, nunca salvos |
| Dica "E • …" e painel de observação | **TRANSITÓRIO** | C18 |

# IDs E DADOS

| Tipo | ID / arquivo |
|---|---|
| observação | `observation.vardhelm.foundry_street_gate`, `…_shift_board`, `…_ore_wagons`, `…_sharpening` |
| nível | `godot/level_data/vardhelm_foundry_street_01.json` → `scenes/prototypes/vp_03_vardhelm_foundry_street.tscn` (em (0, −11,9, 39,5)) |
| vida | `godot/data/vardhelm/foundry_street_life.json` |
| integração | `godot/data/vardhelm/foundry_district.json` (`extra_levels`, `extra_lives`, área, lampiões, placa, fumaça, `animations`) |
| textos | `observation.foundry_street_*` em `pt-BR.json` |

# DEPENDÊNCIAS

- O pátio (C21): portão sul, muro, chão e a massa da fundição oeste.
- A talha (C21) é o caminho a partir da Forja 01.
- Sistemas reutilizados: LevelBuilder/LevelValidator, `VardhelmAmbientLife`, `VardhelmFoundryDistrict`, `EnvironmentalObservation`, `ContextualWindowLifecycle`, GameState, EventBus, Save V2.

# LACUNAS

- O papel da rua na investigação (Fase 5): **NÃO DEFINIDO**. A rua só prepara o palco.
- Nomes da fundição oeste e do armazém; o que fica além da cancela e do corredor.
- `LOC-` da rua.

# CRITÉRIOS DE FECHAMENTO

Padrão §11 + teste humano (checklist em [`BLOCK_C23_FOUNDRY_STREET.md`](../architecture/BLOCK_C23_FOUNDRY_STREET.md)). **Não fechado: falta o teste humano.**
