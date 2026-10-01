# ECHOES OF THE SOUL — BLOCO C4: RUNTIME RESTORE ADAPTERS

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C3](BLOCK_C3_RUNTIME_STATE_RESTORE.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Código:** `godot/scripts/save_v2/adapters/` · **Testes:** `godot/tests/save_v2/test_restore_adapters*.gd`

---

> **Atualização C5** ([BLOCK_C5_RUNTIME_CONTRACT_HARDENING.md](BLOCK_C5_RUNTIME_CONTRACT_HARDENING.md)): os
> Callables descritos em §2 foram substituídos pelo `RuntimeStateDerivationContract`
> (Vardhelm: `VardhelmRuntimeStateProvider`), e o diálogo ganhou destino (`DialogueRuntimeState`) —
> o fluxo real passou a 13 · 10 adapter-supported · 0 requires_adapter · 0 · 1.

## 1. Objetivo

Transformar os campos `requires_adapter` do C3 em estado de runtime coerente — **somente em
diagnóstico e sandbox**, sem ligar ao Ctrl+L, sem tocar no jogo principal e sem criar nova fonte
de verdade.

```
GameState ─► RestorePlan (núcleo C3) ─► adapters refinam o plano ─► sandbox: núcleo + adapters ─► comparação
```

## 2. Regra arquitetural

Um adapter **só usa o que o runtime já tem**: propriedades públicas existentes e derivações
existentes da experiência. Nenhum adapter cria MemoryState, EchoState, DialogueState,
EnvironmentVisualState ou armazenamento paralelo; nenhum guarda estado; nenhum publica eventos;
nenhum conhece a cena ou o SaveService. As derivações da experiência chegam como `Callable`
explícito em `RuntimeRestoreTargets` (quem monta o sandbox decide) — no Vardhelm, os métodos já
existentes do slice, os mesmos usados pelo load antigo:

| Callable em `RuntimeRestoreTargets` | Vardhelm (sandbox) |
|---|---|
| `echo_state_refresher` | `VardhelmVerticalSlice._apply_loaded_visual_state` |
| `quest_presentation_refresher` | `VardhelmVerticalSlice._refresh_objective_text` |
| `environment_refresher` | `VardhelmVerticalSlice._refresh_persistent_world_state` |

Sem o Callable, o adapter reporta `requires_adapter` (com aviso) — não falha e não inventa.

## 3. Registry e contrato

- `RuntimeRestoreAdapterRegistry` — objeto comum (não Autoload/singleton). `create_default()`
  registra os 7 adapters em ordem; recusa adapter nulo, passo desconhecido ou ID repetido.
  `GameStateRuntimeRestorer.new()` sem registry = comportamento exato do C3.
- `RestoreAdapter` (base): `adapter_id()`, `step()`, `diagnose(GameState, RestorePlan)` (refina itens
  — `adapter-supported` quando reconstruível) e `apply(GameState, RestorePlan, RuntimeRestoreTargets)`
  → `RestoreAdapterResult` (`supported`, `applied`, `requires_adapter`, `unsupported`, `warnings`,
  `errors`).
- `RestoreResult` ganhou `adapter_supported` e `adapter_results`.

## 4. Adapters criados

| Adapter | Passo | O que faz |
|---|---|---|
| `ConsequenceRestoreAdapter` | consequences | Verifica que o runtime reconhece cada consequência exatamente uma vez (flag + compatibilidade em `WorldState.memories`); fonte = catálogo → adapter-supported, fonte divergente → requires_adapter. Nada vira memória. |
| `ObservationRestoreAdapter` | observations | Reconstrói `revealed` / `memory_registered` do `EnvironmentalObservation` (o fragmento não é emitido de novo); observações ausentes voltam ao padrão. |
| `EchoRestoreAdapter` | echo | Aciona a derivação existente e **verifica**: resolvido → oculto/sem interação; quest ativa → visível/interativo; sem quest → sem interação. Eco resolvido sem consequência/quest → requires_adapter. |
| `MemoryRestoreAdapter` | memory | Não grava nada. Classifica cada memória pela sua representação existente (Eco derivável / observação de origem) e verifica pelo projetor que o runtime a reproduz com a mesma origem; falha se alguma memória tiver sido gravada em `WorldState.memories`. |
| `DialogueRestoreAdapter` | dialogue | Mantém `requires_adapter` com motivo explícito; informa quantos registros continuam preservados no GameState. |
| `QuestPresentationRestoreAdapter` | presentation | Aciona `_refresh_objective_text` (painel/conclusão/marcador) a partir do QuestState. |
| `EnvironmentPresentationRestoreAdapter` | presentation | Aciona `_refresh_persistent_world_state` e reporta os estados de ambiente reconstruídos; efeitos temporários não são reproduzidos. |

Não foram criados adapters de **Player**, **Quest** (status/objetivos) nem **NPC**: o núcleo do C3 já
os restaura (supported); os testes garantem que os adapters não interferem neles.

## 5. Ordem

`scenario → player → world → consequences → observations → quests → echo → memory → npcs →
dialogue → presentation → progression` — exatamente a ordem pedida. `world` passou a cobrir só
flags/values (e limpa `memories`); consequências e observações têm passos próprios. O Eco vem
depois das quests porque a derivação usa o QuestState; memória depois do Eco porque a memória do
Eco depende dele; apresentação por último porque deriva de tudo acima.

## 6. Resultados

### Fluxo real (Durn → diálogo → quest → Primeiro Eco → observação → Ctrl+S → Ctrl+L)

- Plano: **13 supported · 8 adapter-supported · 2 requires_adapter · 0 unsupported · 1 not_implemented**.
- GameState original (sombra) == GameState carregado (V2).
- **Sandbox (Eco resolvido)**, 2ª instância isolada da cena: volta ao **mesmo estado funcional** do
  jogo — Eco resolvido e não interativo, marcador, banner, painel de objetivo, `echo_awakened` no
  AmbientLife, nó da observação (`revealed` + `memory_registered`), Durn no padrão.
- **Sandbox (Eco não resolvido)**, 3ª instância, com o GameState capturado antes do Eco: Eco oculto e
  interativo, objetivo "investigar", sem estado de ambiente — igual ao jogo naquele momento.
- Runtime sandbox × GameState carregado: **0 diferenças, 0 IDs inesperados**; só `dialogue.completed`
  e `dialogue.choices` faltam (requires_adapter). GameState original × GameState restaurado: idem.
- Nenhum evento publicado; ordem de passos respeitada.

### Divergência encontrada — defeito pré-existente do runtime (não corrigido)

No jogo ao vivo, ao resolver o Eco, **a esfera (`Visual`) e a luz continuam visíveis**:
`EchoMemoryInteractable` guarda `_visual`/`_light` no próprio `_ready`, que roda quando o slice faz
`add_child(echo)` — antes de o slice adicionar os nós `Visual` e `Light`. Na restauração, a derivação
existente (`_apply_loaded_visual_state`) busca os nós na hora e os oculta. Resultado: o estado
restaurado difere do jogo ao vivo **apenas** em `echo_visual` (ao vivo `true`, restaurado `false`). O
teste registra essa divergência explicitamente e exige paridade em todo o resto. Corrigir é mudança
de gameplay — fora do escopo do C4.

### Casos importantes (testados)

1. Memória do Primeiro Eco + consequência: memória continua memória, consequência continua consequência.
2. Fragmento `maintenance_board`: permanece fragmento (origem observation), sem composição.
3. Sem `world.observations`: nada é inventado (nós, flags e values vazios).
4. Observação sem flag espelho: reconstruída (flag + value + nó) e a flag aparece como diferença explícita.
5. `dialogue.completed` presente: não descartado; `requires_adapter` com motivo.

Também testados: registry, contrato, fonte de consequência divergente, fragmento sem observação,
Eco sem base de derivação, nó/derivação ausentes (requires_adapter sem falha), derivação de Eco
quebrada (→ `partial_failure`, passos anteriores listados, aviso para descartar o sandbox), NPC
persistido e padrão, IDs `unsupported` não promovidos, e nenhuma mutação fora do sandbox.

## 7. Não mutação do jogo principal

Estado do jogo principal (WorldState, QuestState, estado funcional/visual, status, posição/rotação)
capturado depois do Ctrl+L e comparado depois de diagnóstico + adapters + dois sandboxes:
**zero diferenças**; nenhum evento novo; GameState sombra não substituído.

## 8. Limitações

- Diálogo continua `requires_adapter` (sem destino seguro no runtime).
- As derivações da experiência são métodos privados do slice, consumidos por `Callable` explícito;
  uma integração operacional deveria expô-los formalmente.
- Defeito pré-existente da esfera do Eco (§6).
- Efeitos temporários de ambiente (tweens/pulse) não são reproduzidos (por desenho).
- Ordem de `WorldState.memories` não é preservada (herdado do C3).

## 9. O que NÃO foi feito

Ctrl+L/SaveService/load operacional intactos; nada aplicado ao jogo principal; GameState continua
sombra; nenhum evento `restore_*`; nenhum sistema novo de memória, Eco, diálogo, quest ou
apresentação; progression não implementado.
