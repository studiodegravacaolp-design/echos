# ECHOES OF THE SOUL — BLOCO C1: SAVE V2 EM MODO SOMBRA

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [A1](BLOCK_A1_CANONICAL_GAME_STATE.md) · [A3](BLOCK_A3_SHADOW_GAME_STATE.md) · [B1](BLOCK_B1_STRUCTURED_EVENTS.md)
> **Código:** `godot/scripts/save_v2/` · **Testes:** `godot/tests/save_v2/` · **Branch:** `integration/godot-vardhelm`

---

## 1. Objetivo

Provar, em paralelo ao save atual, o ciclo completo:

```
GameState → serialização → SaveV2Envelope (+checksum) → arquivo
arquivo → leitura → validação → reconstrução → GameState equivalente
```

O Save V2 **não controla gameplay, não substitui o `SaveService` e não altera Ctrl+S/Ctrl+L**.
Nesta etapa ele só é chamado por testes (`save_game_state()` / `load_game_state()`).

### Componentes

| Classe | Arquivo | Responsabilidade |
|---|---|---|
| `SaveV2Envelope` | `save_v2_envelope.gd` | Constantes (`FORMAT`, `SCHEMA_VERSION`, `GAME_VERSION`) e montagem do envelope. |
| `SaveV2Serializer` | `save_v2_serializer.gd` | GameState ↔ Dictionary (delegando ao contrato A2), forma canônica, parse do arquivo. |
| `SaveV2Checksum` | `save_v2_checksum.gd` | SHA-256 da forma canônica; extração do texto coberto no arquivo. |
| `SaveV2Validator` | `save_v2_validator.gd` | Validação estrita, sem fallback. |
| `SaveV2Errors` | `save_v2_errors.gd` | Códigos de erro. |
| `SaveV2Result` | `save_v2_result.gd` | Resultado explícito (ok / código / mensagem / detalhes / estado / envelope). |
| `SaveV2Service` | `save_v2_service.gd` | `save_game_state`, `load_game_state`, `has_save`, `delete_save`; escrita atômica. |

Nomes: `save_v2_errors.gd` e `save_v2_result.gd` foram acrescentados à sugestão para
concentrar códigos e resultados (erros não ficam como strings espalhadas). Todas as classes são
`RefCounted` — nenhuma é Node, Autoload ou singleton.

---

## 2. Envelope

```json
{
  "checksum": "sha256:<64 hex>",
  "format": "echoes_of_the_soul_save",
  "game_version": "0.1.0-dev",
  "metadata": { "created_at": 1700000000, "slot_id": "shadow", "updated_at": 1700000100 },
  "schema_version": 2,
  "state": { "state_version": 1, "player": {…}, "world": {…}, "quests": {…}, "dialogue": {…}, "memory": {…}, "npcs": {…} }
}
```

- Somente esses seis campos; qualquer outro é `INVALID_ENVELOPE`.
- `format` identifica explicitamente o Save V2 — o payload do SaveService antigo
  (`{"version": 2, "language", "world", "quests", "player"}`) é recusado com `INVALID_FORMAT`.
- `game_version`: o projeto não tem versão canônica de runtime (`project.godot` não define
  `application/config/version`). Usa-se a constante explícita `SaveV2Envelope.GAME_VERSION =
  "0.1.0-dev"` — não inferida do nome da pasta nem de data/hora. Neste bloco ela é registrada e
  validada como String não vazia; não há regra de compatibilidade por `game_version`.

## 3. `schema_version` (save)

`schema_version = 2` é a versão do **formato do arquivo**. Só `2` é aceito: `1`, `3` ou qualquer
outro inteiro → `UNSUPPORTED_SCHEMA`; ausente ou não inteiro → `INVALID_ENVELOPE`. Não há
fallback nem tentativa de leitura de schema futuro.

## 4. `GameState.state_version`

`state.state_version = 1` é a versão do **contrato GameState** (A2) e é validada pelo próprio
contrato (`GameState.validate_dict`). As duas versões são independentes. `progression` continua
reservado: presente no `state`, é recusado (`INVALID_STATE`).

## 5. Metadata

Somente dados técnicos: `slot_id` (String não vazia), `created_at` e `updated_at` (segundos
Unix UTC, inteiros ≥ 0, `created_at ≤ updated_at`). Qualquer outro campo (ex.: posição, quests,
memórias, flags, diálogo) → `INVALID_METADATA`. `created_at` é preservado ao sobrescrever um
save válido; `updated_at` é renovado. O relógio é injetável (`SaveV2Service.clock`) e usado
**somente** em metadata — nenhuma lógica depende dele. Metadata não entra no GameState.

## 6. Checksum

```
checksum = "sha256:" + hex_minúsculo( SHA-256( UTF-8( C ) ) )
C = canonical_json( envelope sem o campo "checksum" )
```

- Cobre `format`, `game_version`, `metadata`, `schema_version` e `state`.
- Determinístico, sem aleatoriedade e sem sal. Detecta corrupção e edição; **não** é proteção
  contra adulteração intencional (qualquer um pode recalcular).
- **Ao gravar:** `C` é gerado a partir dos valores em memória.
- **Ao carregar:** o arquivo é a forma canônica do envelope completo e `"checksum"` é a primeira
  chave em ordem lexicográfica; logo `C` = texto do arquivo sem o membro `"checksum":"…",`,
  extraído **literalmente** — números não são relidos para verificar o checksum.

### Por que o checksum é verificado sobre o texto (achado do C1)

Medição no Godot 4.7.1 (200 000 floats, incluindo floats vindos de `Vector3`): o parser JSON
**não devolve exatamente o mesmo double** para ~17,7 % dos valores (ex.: `0.0010000000474974513`
volta com 1 ulp de diferença), e 0,14 % nunca se estabilizam em ciclos escrita→leitura.
Recalcular o checksum a partir de números relidos rejeitaria saves legítimos. Verificar sobre
o texto canônico gravado elimina essa dependência, mantendo um único algoritmo.

## 7. Serialização canônica

`SaveV2Serializer.canonical_json(valor)`:

- Dictionary: somente chaves String, ordenadas lexicograficamente; sem espaços.
- Array: elementos na ordem.
- Números: int, ou float finito de valor inteiro com |x| < 2⁵³ → sem parte decimal (`3` e `3.0`
  → `3`); demais floats → formato de precisão completa do Godot.
- String escapada como JSON; `true`/`false`; `null`.
- Objetos (Node/Resource), `Vector3` cru, NaN/±Inf e chaves não String são **recusados**.

O mesmo estado produz sempre o mesmo texto, independentemente da ordem de inserção nos
Dictionaries e de int×float. O arquivo gravado **é** essa forma canônica (uma linha).
O GameState é convertido pelo próprio contrato A2 (`GameState.to_dict/from_dict`, via
`GameStateSerde`) — a serialização do estado não é duplicada; `Vector3` já chega como `[x, y, z]`.

## 8. Validação

`SaveV2Validator.validate(envelope, texto_do_arquivo = "")`, nesta ordem:

| # | Verificação | Erro |
|---|---|---|
| 1 | envelope é Dictionary não vazio | `INVALID_ENVELOPE` |
| 2 | `format` existe e é `echoes_of_the_soul_save` | `INVALID_FORMAT` |
| 3 | `schema_version` existe e é inteiro | `INVALID_ENVELOPE` |
| 3b | `schema_version` == 2 | `UNSUPPORTED_SCHEMA` |
| 4 | somente campos conhecidos; `game_version` String não vazia | `INVALID_ENVELOPE` |
| 5 | `metadata` válida (§5) | `INVALID_METADATA` |
| 6 | `state` existe e é Dictionary | `INVALID_STATE` |
| 7 | `checksum` existe, bem formado e confere (§6) | `INVALID_CHECKSUM` |
| 8 | `state` compatível com o contrato GameState (tipos, IDs de status, `Vector3` = 3 números finitos, `state_version` 1) | `INVALID_STATE` |

Depois da validação, `load_game_state` reconstrói o GameState e confirma que ele reproduz o
`state` gravado (comparação estrutural; números com `is_equal_approx`) — se algo se perdesse,
`CORRUPTED_DATA`. Nenhum fallback silencioso em nenhuma etapa.

## 9. Erros (`SaveV2Errors`)

| Código | Quando |
|---|---|
| `INVALID_FORMAT` | `format` ausente ou diferente (inclui o save do SaveService antigo). |
| `UNSUPPORTED_SCHEMA` | `schema_version` inteiro ≠ 2 (futuro ou antigo). |
| `INVALID_ENVELOPE` | não Dictionary, vazio, campo desconhecido, `schema_version` ausente/não inteiro, `game_version` inválido. |
| `INVALID_STATE` | `state` ausente/inválido ou incompatível com o GameState; GameState inválido ao gravar. |
| `INVALID_CHECKSUM` | checksum ausente, malformado, divergente; arquivo fora da forma canônica (ex.: reformatado, byte extra). |
| `INVALID_METADATA` | metadata ausente, com campo desconhecido ou tipo inválido. |
| `CORRUPTED_DATA` | arquivo vazio ou JSON inválido; estado que não sobrevive à reconstrução. |
| `FILE_NOT_FOUND` | não existe save no caminho. |
| `IO_ERROR` | **adicional ao conjunto mínimo**: falha ao criar diretório, gravar, verificar ou substituir. |

## 10. Caminho do arquivo

`user://echoes_of_the_soul_save_v2_shadow.json` (`SaveV2Service.DEFAULT_PATH`) — diferente do
arquivo do SaveService (`user://echoes_of_the_soul_save.json`). O caminho é injetável; os testes
usam `user://save_v2_tests/` (removido ao final) e nunca gravam no caminho padrão.

## 11. Round trip

Testado (`GameStateComparator`, sem mascarar diferenças — a mensagem lista campo, valor original
e valor carregado): estado inicial; após diálogo iniciado; após escolha; após quest; após
consequência; após Primeiro Eco e sua memória; após observação; posição/rotação; múltiplos flags
(inclusive `false`), memórias e observações; dados vazios; valores numéricos e strings; estado de
NPC; floats afetados pelo parser JSON; e o GameState real de Vardhelm (fluxo do jogo → eventos B1
→ sombra → Save V2 → Load V2): **original == carregado** em todos.

- `Vector3` (float32) volta **exato** (`==`), mesmo quando o double relido difere em 1 ulp.
- `memory.vardhelm.first_echo` (origem echo) e fragmentos (origem observation) continuam separados.
- `consequence.vardhelm.first_echo_complete` permanece em `world.consequences`, nunca em
  `memory.memories`.
- `dialogue.completed` e `dialogue.choices` (dialogue_id, entry_id, choice_id = última) preservados.

## 12. Corrupção

Todos falham com código explícito e sem estado: arquivo inexistente; JSON inválido; arquivo
vazio; envelope vazio; envelope não Dictionary; format errado; schema ausente; schema futuro;
metadata inválida; state ausente; state inválido; checksum ausente; checksum incorreto; payload
alterado depois do checksum (edição do arquivo); `Vector3` inválido; tipo inválido em campo
conhecido; save do SaveService antigo; arquivo reformatado; byte extra no fim.

## 13. Atomicidade

Implementada, restrita ao arquivo do Save V2 (o save antigo nunca é tocado):

```
texto → <arquivo>.tmp → releitura + validação completa do .tmp
      → [<arquivo> → <arquivo>.bak] → <arquivo>.tmp → <arquivo> → remove .bak
```

- Se a verificação do `.tmp` falha, ele é removido e o save anterior fica intacto.
- Se a substituição falha, o `.bak` é restaurado.
- Um `.bak` remanescente é descartado na próxima gravação; um GameState inválido nunca é gravado.
- Limite conhecido: uma queda do processo entre os dois `rename` pode deixar só o `.bak`; neste
  bloco não há recuperação automática a partir dele (seria um fallback) — `has_save()` responde
  pelo arquivo principal.

## 14. Relação com o SaveService antigo

Nenhuma: `godot/scripts/save/save_service.gd` está inalterado; o Save V2 não o importa nem o
chama (verificado por varredura de código); o SaveService não referencia o Save V2; Ctrl+S e
Ctrl+L continuam chamando apenas o SaveService, com o bug de load conhecido. Os testes confirmam
que o arquivo do SaveService não é criado nem removido.

## 15. Relação futura com o EventBus

**Atualização (C2):** integração feita pelo `SaveV2ShadowCoordinator`, seguindo esta regra. Texto original do C1: `game_saved` / `game_loaded` continuam reservados no catálogo B1 e **não** são publicados. Na
integração futura: `game_saved` somente depois de `save_game_state()` retornar `ok` (arquivo
substituído e verificado); `game_loaded` somente depois de `load_game_state()` retornar `ok`
(estado reconstruído e conferido). Os testes confirmam que Save/Load V2 não publicam eventos hoje.

## 16. Limitações

- Doubles fora de `Vector3` (ex.: `world.values`) podem voltar com diferença de 1 ulp por
  limitação do parser JSON do Godot 4.7.1; a comparação estrutural usa `is_equal_approx`. O
  checksum não é afetado.
- O arquivo precisa estar exatamente na forma canônica; reformatá-lo (indentação, quebra de
  linha) invalida o checksum de forma explícita.
- Um único slot/caminho por serviço; `slot_id` é só metadata.
- Sem recuperação automática a partir do `.bak` (§13).
- Checksum não é assinatura (sem proteção contra adulteração intencional).

## 17. O que NÃO foi migrado

- Ctrl+S/Ctrl+L, Input e o SaveService continuam como estavam; o bug de load permanece.
- O GameState continua **sombra**: nenhum gameplay consulta o Save V2, o GameState carregado ou
  `load_game_state()`; o load V2 serve só para verificação de round trip.
- Sem publicação de `game_saved`/`game_loaded` neste bloco (integrados no C2, ver [BLOCK_C2_DUAL_SAVE_SHADOW.md](BLOCK_C2_DUAL_SAVE_SHADOW.md)).
- Sem migração de saves antigos (o `GameStateMigrator` do A2 continua não usado pelo jogo).
- Sem múltiplos slots reais, sem autosave, sem UI de save.
