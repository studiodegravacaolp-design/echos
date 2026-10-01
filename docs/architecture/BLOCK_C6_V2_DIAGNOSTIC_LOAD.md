# ECHOES OF THE SOUL — BLOCO C6: V2 DIAGNOSTIC LOAD + FAILURE POLICY

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C1](BLOCK_C1_SAVE_V2_SHADOW.md) · [C3](BLOCK_C3_RUNTIME_STATE_RESTORE.md) · [C4](BLOCK_C4_RUNTIME_RESTORE_ADAPTERS.md) · [C5](BLOCK_C5_RUNTIME_CONTRACT_HARDENING.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Testes:** `godot/tests/save_v2/test_save_v2_diagnostic.gd`, `test_save_v2_diagnostic_vardhelm.gd`

---

## 1. Objetivo

Primeiro teste real do pipeline completo, de ponta a ponta, **somente em diagnóstico**:

```
GameState ─► SAVE V2 ─► arquivo ─► LOAD V2 ─► envelope ─► checksum ─► GameState ─► RestorePlan
          ─► sandbox NOVO ─► núcleo + adapters ─► verificação ─► comparação ─► relatório
```

Não é a migração do Save/Load: Ctrl+S, Ctrl+L e `SaveService` continuam exatamente como antes, o
V2 não é obrigatório nem oficial, e o GameState continua sombra.

## 2. Feature flag

`SaveV2DiagnosticConfig` (`godot/scripts/save_v2/save_v2_diagnostic_config.gd`):

- `enabled` corresponde a **SAVE_V2_DIAGNOSTIC_ENABLED**, com padrão **OFF** (`DEFAULT_ENABLED = false`).
- É um objeto local passado explicitamente ao coordenador. Não é Autoload, não lê `ProjectSettings`,
  variáveis de ambiente nem arquivos, e `project.godot` não foi alterado.
- Com a flag desligada, `save()` e `load_and_restore()` devolvem **DISABLED**: nenhum arquivo é lido
  ou gravado e nenhum sandbox é criado (testado).
- Nenhum código de gameplay usa o coordenador. Não há atalho nem gancho no jogo: o diagnóstico é
  acionado por testes e ferramentas.

## 3. SaveV2DiagnosticCoordinator

`godot/scripts/save_v2/save_v2_diagnostic_coordinator.gd`. É um objeto comum, que não conhece
`SaveService`, Ctrl+S/Ctrl+L, a cena, o jogo principal nem o EventBus.

| Etapa | O que faz |
|---|---|
| `flag` | recusa tudo se desligado |
| `load` / `envelope` | `SaveV2Service.load_game_state()` do C1 (parse, format, schema, metadata) |
| `checksum` | validador do C1 sobre o texto literal + recálculo explícito pelo coordenador **antes** de qualquer sandbox |
| `game_state` | `GameState.validate()` |
| `plan` | `RestorePlan` completo: qualquer `unsupported` → RESTORE_REJECTED/UNKNOWN_ID; qualquer `requires_adapter` (ou `not_implemented` fora de `progression`) → RESTORE_REJECTED/PLAN_INCOMPLETE — **antes** de criar o sandbox |
| `sandbox` | `SaveV2DiagnosticSandbox.create_targets()` — runtime **novo**; alvo precisa ser `is_sandbox` |
| `restore` | `GameStateRuntimeRestorer` + adapters (C3–C5) |
| `verify` | nenhum adapter com `requires_adapter`/`unsupported`; **todo** item supported/adapter-supported do plano foi aplicado |
| `comparison` | runtime do sandbox × GameState carregado = 0 diferenças / 0 ausentes / 0 IDs inesperados; opcionalmente × GameState esperado |

O retorno é um `SaveV2DiagnosticReport`: status, código, mensagem, detalhes, etapas, checksum,
contagem do plano, resultado da restauração, diferenças e estado do sandbox. Em SUCCESS o sandbox fica
no relatório para inspeção e quem chamou o descarta.

**Sandbox.** `SaveV2DiagnosticSandbox` é o contrato. A implementação Vardhelm é
`VardhelmDiagnosticSandbox` (`godot/scripts/vardhelm/`):

- cada execução instancia uma experiência nova, fora do jogo principal;
- a instância é isolada: sem Save V2 sombra, sem input (Ctrl+S/Ctrl+L do sandbox nunca disparam),
  sem processamento, sem física do Player e invisível;
- os alvos vêm do `VardhelmRuntimeStateProvider` (C5);
- `discard()` remove e libera a instância.

## 4. V2 Save (diagnóstico)

`coordinator.save(GameState)` usa o `SaveV2Service` do C1 **sem alterar** formato, envelope,
`schema_version` 2, serialização canônica ou checksum; o slot é `diagnostic`. Depois de gravar, o
coordenador lê o arquivo literal e recalcula o checksum.

Salvar o mesmo GameState duas vezes (com o mesmo relógio) produz um arquivo idêntico.

## 5. Arquivo

`user://echoes_of_the_soul_save_v2_diagnostic.json`, que segue o padrão de nomes do C1. Nunca é o
arquivo do SaveService (`user://echoes_of_the_soul_save.json`) nem o da sombra do C2
(`user://echoes_of_the_soul_save_v2_shadow.json`). Os testes usam um diretório próprio e restauram o
save antigo do usuário.

## 6. Failure policy

Cada resultado tem um status e um código específico, nunca "best effort". O coordenador não ignora
erro e não restaura parcialmente.

| Status | Quando | Códigos (exemplos testados) |
|---|---|---|
| **SUCCESS** | pipeline completo, sandbox == GameState (== esperado) | `OK` |
| **PARTIAL_FAILURE** | a restauração já escreveu no sandbox e falhou → **sandbox descartado** | `ADAPTER_FAILURE`, `DERIVATION_FAILURE`, `UNSUPPORTED_CONTENT`, `INCOMPLETE_RESTORE`, `CORE_STEP_FAILURE` |
| **FAILURE** | falha sem restauração válida | `FILE_NOT_FOUND`, `IO_ERROR`, `RESTORE_MISMATCH`, `EXPECTED_MISMATCH` |
| **CORRUPTED_DATA** | arquivo ilegível ou adulterado | `CORRUPTED_DATA` (JSON corrompido), `INVALID_CHECKSUM` |
| **INVALID_SAVE** | fora do contrato | `INVALID_FORMAT`, `INVALID_ENVELOPE`, `INVALID_METADATA`, `INVALID_STATE` |
| **UNSUPPORTED_SCHEMA** | `schema_version` não suportada (ex.: futura) | `UNSUPPORTED_SCHEMA` |
| **RESTORE_REJECTED** | recusado **antes de qualquer escrita** | `UNKNOWN_ID`, `PLAN_INCOMPLETE`, `TARGET_NOT_SANDBOX`, `RESTORE_REFUSED` (ex.: cenário diferente), `SANDBOX_UNAVAILABLE` |
| DISABLED | flag desligada (não é falha) | `FLAG_DISABLED` |

Os 9 casos pedidos foram testados, cada um com status e código específicos:

1. arquivo inexistente;
2. checksum inválido;
3. JSON corrompido;
4. schema futuro;
5. GameState inválido;
6. ID desconhecido;
7. falha de adapter;
8. falha de derivação;
9. restore rejeitado (alvo não-sandbox e cenário diferente).

Nos casos 1–6 nenhum sandbox chega a ser criado. Nos casos 7–9 o sandbox é criado e sempre
descartado. Em nenhum caso algo fora do sandbox é tocado.

## 7. Rollback policy

```
sandbox falhou ─► descartar sandbox ─► preservar runtime principal ─► retornar diagnóstico
```

O único alvo de escrita é o sandbox, então não existe rollback do jogo principal: ele nunca é tocado.
**O rollback real do gameplay principal é requisito do C7.**

## 8. Resultados com o Vardhelm real

- **Antes do Eco** (Durn → escolha → quest):
  - save V2 → coordenador novo → load → sandbox novo;
  - o estado funcional é **idêntico** ao do jogo, incluindo a esfera do Eco e o diálogo persistente;
  - GameState restaurado == capturado.
- **Depois do Eco** (Durn → quest → Eco → memória → 3 observações → consequências):
  - plano: **17 supported · 14 adapter-supported · 0 requires_adapter · 0 unsupported ·
    1 not_implemented** (há mais itens que no C5 porque as 3 observações foram descobertas);
  - GameState do arquivo == capturado, e runtime restaurado == capturado em player, world,
    consequences, observations, quests, dialogue, memory e npcs;
  - estado funcional idêntico ao do jogo, exceto a esfera (§11).
- **Campos verificados:**
  - posição exata e rotação não padrão, sem checkpoint;
  - `scenario_id`;
  - diálogo concluído + última escolha, com a caixa não reaberta e nada transitório restaurado;
  - as 3 observações (nó, flag, value);
  - 3 fragmentos (sem composição) + `memory.vardhelm.first_echo` com origem echo;
  - `consequence.vardhelm.heard_echo` e `consequence.vardhelm.first_echo_complete` com origem do
    `GameIdCatalog`; memory ≠ consequence;
  - Eco derivado; NPC; apresentação derivada (conclusão, marcador, `echo_awakened`).
- **Fora da comparação:** UI transitória, animações, efeitos temporários, câmera, áudio e timers.

## 9. Old Load × V2 Load

Cada load roda em uma instância **isolada**. O Ctrl+L antigo é entregue só à instância do Old Load,
e nem o jogo principal nem o sandbox V2 o recebem. Nenhum dos dois contaminou o outro (testado).

| | × GameState esperado |
|---|---|
| **V2 Load** | 33 iguais, **0 diferenças, 0 ausentes** |
| **Old Load** | 27 iguais, 2 diferenças (posição, rotação), 3 ausentes (`quests.quest.vardhelm.first_echo`, `dialogue.completed…`, `dialogue.choices…`) |

O Old Load aborta em `save_service.gd:44` (atribui `Array` a `WorldState.memories`, que é tipado)
**antes** de restaurar quests e o Player. O `SaveService` também nunca gravou diálogo. O bug foi
**registrado e não corrigido** (fora do escopo; `save_service.gd` intacto).

## 10. Idempotência, duplicação e não mutação

- **Idempotência:**
  - dois sandboxes independentes carregados do mesmo arquivo chegam ao mesmo estado final;
  - uma restauração repetida sobre o mesmo sandbox dá o mesmo estado.
- **Sem duplicação:** consequências aparecem uma vez em `WorldState.memories`, memórias nunca aparecem
  ali, há uma quest concluída e uma escolha por entry, com observações e NPC únicos.
- **Não mutação:** o jogo principal foi capturado depois do Ctrl+S. Após V2 save + V2 load + restore
  + sandboxes + comparação + Old Load isolado, a comparação dá **ZERO diferenças**, **ZERO eventos
  novos** e o GameState sombra não foi alterado nem substituído.
- **EventBus:** nenhum evento novo. `restore_started`, `restore_completed` e `restore_failed` não
  existem no catálogo (testado). O último relatório fica só dentro do coordenador (`last_report`).

## 11. KNOWN GAMEPLAY BUG — esfera do Eco

Ao vivo, o Eco resolvido continua com a esfera visível: `EchoMemoryInteractable` guarda o nó visual
antes de ele existir. O estado restaurado a oculta. O bug está registrado, **não foi corrigido** e
fica fora dos contratos do Save V2 (C5 §7).

## 12. Por que o Ctrl+L ainda não foi substituído

1. O C6 prova o pipeline em sandbox. Aplicar no jogo principal exige rollback real, que é
   requisito do C7.
2. O Old Load e o V2 Load divergem (§9). Substituir o Ctrl+L muda o que o jogador vê, e isso
   precisa de decisão explícita.
3. O bug da esfera faz o estado carregado divergir do estado ao vivo.
4. Não existe estratégia de migração dos saves antigos, e ela está fora do escopo.

## 13. Limitações

- A comparação funcional é específica do Vardhelm (feita nos testes). O coordenador compara pelo
  projetor, que é genérico.
- O sandbox Vardhelm instancia a cena inteira. É barato em teste, mas não foi medido em jogo.
- `describe_quest_presentation` só verifica "conclusão apresentada" (C5).
- A ordem de `WorldState.memories` não é preservada (herdado do C3).
- Testes legados `extends Node` (`memory_echoes`, `narrative_consequence`, `world_response`) não são
  executáveis diretamente com `--script`: o Godot abre um alerta nativo e fica preso até o timeout
  (a "oscilação" observada aqui). Desde o C7 eles não são mais executados por esse método e ficam
  registrados como limitação conhecida (ver [C7 §13](BLOCK_C7_V2_OPERATIONAL_LOAD.md)).
