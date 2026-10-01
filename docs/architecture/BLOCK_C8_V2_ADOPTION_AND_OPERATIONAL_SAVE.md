# ECHOES OF THE SOUL — BLOCO C8: V2 ADOPTION + OPERATIONAL SAVE + PERSISTENCE POLICY

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C1](BLOCK_C1_SAVE_V2_SHADOW.md) · [C2](BLOCK_C2_DUAL_SAVE_SHADOW.md) · [C6](BLOCK_C6_V2_DIAGNOSTIC_LOAD.md) · [C7](BLOCK_C7_V2_OPERATIONAL_LOAD.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Testes:** `godot/tests/save_v2/test_save_v2_operational_save.gd`, `test_save_v2_operational_save_vardhelm.gd`, `godot/tests/echo/test_echo_visual_state.gd`

---

## 1. Resultado

O ciclo V2 completo funciona pelo Ctrl+S / Ctrl+L reais:

```
SAVE V2 ─► arquivo ─► LOAD V2 ─► runtime ─► SAVE V2 ─► arquivo equivalente ─► LOAD V2 ─► mesmo estado
```

As duas flags continuam **OFF** por padrão; nenhum default foi alterado.

## 2. Feature flags

| Flag (`SaveV2OperationalConfig`) | Padrão | OFF | ON |
|---|---|---|---|
| `enabled` = **SAVE_V2_OPERATIONAL_LOAD_ENABLED** | false | Ctrl+L antigo, exatamente como antes | somente Load V2, sem fallback |
| `save_enabled` = **SAVE_V2_OPERATIONAL_SAVE_ENABLED** | false | Ctrl+S antigo + sombra C2, como antes | somente Save V2; o save antigo **não é gravado** |

As flags são um objeto local da experiência: sem Autoload, `ProjectSettings` ou variáveis de ambiente.

## 3. Save V2 operacional

`SaveV2RuntimeSaveCoordinator` (`godot/scripts/save_v2/save_v2_runtime_save_coordinator.gd`):

```
runtime ─► SaveV2RuntimeSnapshot.project (projeção persistente completa)
        ─► validação ─► GameState sombra sincronizado (cópia)
        ─► SaveV2Service (formato C1, escrita atômica) ─► checksum sobre o texto literal
        ─► SUCCESS ─► game_saved
```

- **Não usa sandbox.** O save custa ~13–19 ms, dominados pela escrita atômica com verificação.
- **Grava** a projeção persistente: player (posição, rotação, cenário), world, consequences,
  observations, quests, `DialogueRuntimeState`, memory (derivada) e NPCs.
- **Não grava** estado derivado nem transitório: UI, câmera, áudio, timers, animações, efeitos ou
  sessão de diálogo.
- **Resultados:**

| Status | Quando |
|---|---|
| DISABLED | flag desligada |
| SUCCESS | projetado, validado, gravado e checksum conferido |
| SAVE_REJECTED | alvo inválido ou runtime não representável; nada é gravado |
| VALIDATION_FAILURE | GameState projetado inválido |
| WRITE_FAILURE | erro de E/S ou checksum; o save anterior é preservado pela escrita atômica do C1 |

- **Sincronização da sombra.** Antes de gravar, a sombra é comparada com a projeção: as divergências
  vão para `shadow_divergence` e a sombra recebe uma cópia da projeção. No jogo real a divergência foi
  **vazia** em todos os saves testados, o que comprova que a sombra já acompanhava o runtime.
- **Arquivo e slot.** Grava no mesmo arquivo que o Ctrl+S já produzia desde o C2
  (`user://echoes_of_the_soul_save_v2_shadow.json`), com `slot_id = "current"`.

## 4. Load V2 operacional (C7 + C8)

O pipeline do C7 continua o mesmo (rehearsal → snapshot → rehearsal do rollback → apply → validação
→ rollback se preciso). O C8 acrescenta:

- **Recusa com diálogo aberto** (§6).
- **`game_loaded`** publicado só depois da validação pós-restore com SUCCESS.
- **Tempos por etapa** em `timings_ms` (§9).
- **Sombra sincronizada.** Depois do SUCCESS a experiência passa à sombra uma cópia do estado carregado
  (desde o C7). O caso crítico A → B → Load → Save → B' → Load = A foi testado.

**Correção no núcleo (C3), achada no C8.** `QuestState.start_quest` sempre cria
`objective_progress[quest] = {}`, mas o passo de quests do restaurador descartava objetivos vazios.
Com isso, um runtime com a quest ativa e nenhum objetivo concluído não podia ser recarregado: o
snapshot não voltava exato e o load era recusado como `SNAPSHOT_NOT_REVERSIBLE`. O passo agora
preserva a entrada (mesma invariante do `QuestState`).

## 5. GameState

- Continua **sombra do gameplay**: nenhum controller lê o GameState.
- A **projeção** do runtime é a representação persistente oficial do V2.
- O GameState é sincronizado no save e no load; nunca vira dependência do gameplay.

## 6. Diálogo aberto

| Ação | Política |
|---|---|
| **Load V2 com sessão aberta** | **LOAD_REJECTED_TRANSIENT_DIALOGUE**. Nada é tocado: a sessão não é fechada, reaberta nem destruída, não há rehearsal nem evento, e não há fallback para o load antigo. O jogador precisa concluir o diálogo antes. Motivo: não existe contrato para restaurar uma sessão transitória |
| **Save V2 com sessão aberta** | **Permitido**, e o resultado marca `dialogue_session_open = true`. Grava só o `DialogueRuntimeState` persistente (escolhas já feitas, diálogos concluídos). Uma escolha feita com a sessão ainda aberta é gravada; a conclusão só depois do fim. Entrada atual, texto, escolhas visíveis, falante e caixa **não** são gravados (testado). É seguro porque a projeção nunca lê a sessão |

A detecção usa `RuntimeStateDerivationContract.is_dialogue_session_open()` (padrão `false`). No
Vardhelm ela é verdadeira quando `DialogueController.is_active()` ou a `DialogueBox` está visível.

## 7. Bug da esfera do Eco — corrigido

- **Causa.** `EchoMemoryInteractable._ready` guardava `Visual`/`Light` quando o slice fazia
  `add_child(echo)`, antes de o slice criar esses nós. As referências ficavam nulas e, ao resolver o
  Eco ao vivo, a esfera e a luz continuavam visíveis.
- **Correção mínima**, em `echo_memory_interactable.gd` (+6 linhas): `interact()` resolve os nós na
  hora de usar, se ainda não tiver as referências. Nada mudou em GameState, Save V2, RestorePlan ou
  derivações.
- **Resultado.** O jogo ao vivo e o runtime após o Load V2 ficam idênticos também na esfera e na luz.
- **Testes.**
  - `test_echo_visual_state_after_resolution` cobre as duas ordens de criação e o Vardhelm real,
    comparando o estado ao vivo com a derivação.
  - Os testes C4–C7 que registravam a divergência agora exigem consistência.

## 8. SaveService antigo = LEGACY COMPATIBILITY PATH

- **Não recebe** novos recursos nem novos campos.
- **Não é fonte** do GameState V2.
- **Não deve** ser usado para novos saves.
- **Permanece** temporariamente, para compatibilidade; não foi removido.
- **Bug conhecido** em `save_service.gd:44`: o load antigo aborta antes de quests e Player. **Não foi
  corrigido**, porque não afeta a integração V2.
- **Ctrl+L antigo:** disponível só com a flag de load OFF.
- **Ctrl+S antigo:** disponível só com a flag de save OFF. Com a flag ON, o save antigo **não é
  sobrescrito**. Testado com um arquivo sentinela.

### Política de saves antigos

- **OLD SAVE** (`user://echoes_of_the_soul_save.json`) é o formato legado.
- **V2 SAVE** é o formato atual.
- Saves antigos continuam legíveis pelo caminho antigo. O V2 não os lê, não os modifica, não os
  sobrescreve, não os converte e não os apaga (testado).
- Não existe migração, silenciosa ou não, e não há migrator. Uma migração futura precisará:
  1. ler o legado com o migrator do A2 (`GameStateMigrator.migrate_legacy_payload`, que já existe e
     põe dados desconhecidos em quarentena);
  2. contornar ou corrigir a perda causada pelo bug de `save_service.gd:44`;
  3. gravar um novo arquivo V2 sem apagar o antigo;
  4. ter opt-in explícito do jogador.

## 9. Custo medido

Medições em headless (sem renderização), em ms:

| Situação | rehearsal | snapshot | rehearsal do rollback | apply | pós-restore | total |
|---|---|---|---|---|---|---|
| processo novo, 1º load (cold) | 84–93 | 0,4 | 72–118 | 1,7–2,2 | 0,1 | 159–214 |
| mesmo processo, 2º/3º load (warm) | 82–84 | 0,4–0,6 | 57–77 | 1,7–1,8 | 0,1 | 141–163 |
| suíte de testes (recursos já em cache) | 30–43 | 0,5–1,0 | 38–55 | 1,2–4,6 | 0,1–0,2 | 82–87 |
| rollback executado | — | — | — | — | — | +1,3 no rollback |
| **Save V2** | — | project 0,4–0,5 | — | — | — | 13–19 (escrita 12–18) |

- **Leitura.** As duas instâncias de sandbox custam cerca de 99% do load; apply e validação ficam
  abaixo de 5 ms. Não há otimização neste bloco, e o rehearsal de segurança foi mantido.
- **Otimização proposta (futura), só se medida em jogo com renderização:**
  - reutilizar um único sandbox para o rehearsal do arquivo e o do rollback (reset entre os dois);
  - ou validar o rollback de forma mais barata, comparando a projeção do snapshot sem instanciar a
    cena.

## 10. Eventos

- `game_saved`: publicado só depois de gravar e verificar o arquivo com sucesso.
- `game_loaded`: publicado só depois da validação pós-restore com sucesso.
- **Não são publicados** quando:
  - o save falha;
  - o arquivo é inválido;
  - o diálogo está aberto;
  - o load cai em rollback.
- Nenhum evento novo: `restore_*` continuam fora do catálogo. O `GameStateShadowRecorder` ignora esses
  dois eventos. O diagnóstico fica no resultado de cada coordenador.

## 11. Single-slot

A implementação atual tem **um único arquivo V2** (`slot_id = "current"`). Não há múltiplos slots, e
nenhum foi inventado.

## 12. Critérios para, no futuro, ligar as flags por padrão

1. Decisão explícita sobre os saves antigos: migração opt-in, ou aceitar que continuam só no caminho
   legado.
2. Custo do load medido **em jogo com renderização**, em hardware-alvo, e aceito (ou otimizado conforme
   §9).
3. Comportamento do Ctrl+L com diálogo aberto validado com jogadores (a recusa aparece só no
   `status_label`).
4. Estratégia para o erro de rollback (ROLLBACK_FAILURE), que hoje só é mostrado e registrado.
5. Decisão sobre `save_service.gd:44`: corrigir ou remover o caminho legado.
6. Um ciclo inteiro de playtest com as duas flags ON, sem regressão.

## 13. Limitações

- A recusa com diálogo aberto só é informada pelo `status_label` e pelo `push_warning`: não há UI nova.
- O contador "Memórias registradas" (UI) não é recalculado pelo load.
- A ordem de `WorldState.memories` não é preservada (C3); as comparações usam conjunto.
- Os tempos foram medidos em headless; o custo com renderização é desconhecido.
- Testes legados `extends Node` continuam não executáveis diretamente (C7 §13).
