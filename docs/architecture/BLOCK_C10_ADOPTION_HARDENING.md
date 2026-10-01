# ECHOES OF THE SOUL — BLOCO C10: ADOPTION HARDENING + UX + MIGRATION DECISION

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C9](BLOCK_C9_ADOPTION_READINESS.md) · **Política:** [SAVE_MIGRATION_POLICY.md](SAVE_MIGRATION_POLICY.md) · **Checklist humano:** [C10_HUMAN_PLAYTEST_CHECKLIST.md](C10_HUMAN_PLAYTEST_CHECKLIST.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Testes:** `godot/tests/save_v2/test_c10_adoption_hardening.gd`, `test_c10_adoption_hardening_vardhelm.gd` · playtest automatizado `c9_rendered_playtest.gd`

---

> **Importante:** **não houve playtest humano.** Os playtests do C9 e do C10 são automatizados (input,
> frames e renderização reais, conduzidos por script). O C10 só **preparou** o checklist humano, que
> está sem preencher.

## 1. Decisão de migração

**OPTION B — OPT-IN MIGRATION**, registrada em [SAVE_MIGRATION_POLICY.md](SAVE_MIGRATION_POLICY.md) §5.

- O fluxo previsto é: save antigo detectado → jogador decide → conversão **somente** com consentimento
  explícito.
- Nenhuma migração automática ou silenciosa; nenhum save antigo sobrescrito, movido ou apagado.
- O caminho legado continua disponível (flags OFF).
- **Nada foi implementado:** nem conversão, nem migrator novo (testado: o único migrator do projeto é o
  `GameStateMigrator` do A2), nem UI de consentimento.

## 2. UI transitória após Load

`VardhelmVerticalSlice._discard_transient_ui_after_load()` roda **só depois de Load V2 com SUCCESS** e
fecha os painéis que mostram o estado anterior:

- Eco de memória (`memory_panel`);
- observação (`observation_panel`);
- notificação de memória (`memory_notification_panel`).

O que **não** é fechado:

- a HUD estrutural (objetivo, status);
- o banner de conclusão e o objetivo: são **derivados** e re-derivados do estado carregado;
- o diálogo: um Load com diálogo aberto é recusado antes e não fecha nada;
- a `DialogueSession` e o `DialogueRuntimeState`.

Em Load com falha, recusa ou rollback, o estado não mudou para um novo save, então a UI fica como
estava (testado).

## 3. Câmera após Load — causa real e correção

**A hipótese do C9 estava errada.** A câmera é filha rígida do Player, sem suavização, e não demorava a
reenquadrar. A sonda mostrou outra coisa:

1. **Depois de todo Load V2, a câmera ativa deixava de ser a do jogador e ficava presa na câmera
   panorâmica do nível** (`VP01_Vardhelm/Camera3D`). Cada sandbox instancia um Player com
   `Camera3D.current = true`, que rouba o viewport. Quando o sandbox é descartado, o Godot escolhe
   outra câmera. **Era um vazamento de isolamento do sandbox do Save V2.**
2. **A `velocity` do Player sobrevivia ao teleporte.** Na sonda, o jogador fora do mapa caía a
   −19,7 m/s e continuava com essa velocidade depois do Load.

**Correções (sem CameraState e sem persistir câmera):**

- `VardhelmDiagnosticSandbox` desliga as câmeras do sandbox e devolve a câmera ativa do jogo principal,
  tanto na criação quanto no descarte.
- Após Load com SUCCESS ou rollback (qualquer apply no jogo principal), `player.velocity = Vector3.ZERO`.
  A velocidade é estado físico transitório e não é persistida.

**Testado** em headless e no playtest renderizado, a cada Load comparado: a câmera ativa é a do jogador
depois de SUCCESS, recusa e rollback, e o Player fica no ponto salvo com velocidade zero.

## 4. Mensagens de Save/Load

- **Continuam no `status_label` existente, agora destacadas:**
  - fonte 18 (o status comum usa 12);
  - fundo escuro com borda e texto na cor da severidade: sucesso verde, aviso âmbar, erro vermelho;
  - posicionadas logo abaixo do painel de objetivo, também quando ele cresce para duas linhas no
    mesmo frame.
- Não bloqueiam o gameplay e **somem depois de 4 s**, devolvendo o texto e o estilo originais.
- Não há sistema de notificações novo, nem texto fixo no código (continuam as chaves `save.v2.*`).
- As seis mensagens pedidas são distintas e sem código técnico, que vai só para o log:

| Caso | Mensagem (pt-BR) | Destaque |
|---|---|---|
| SAVE SUCCESS | Jogo salvo. | sucesso |
| SAVE FAILURE | Não foi possível gravar o jogo salvo. O save anterior foi mantido. | erro |
| LOAD SUCCESS | Jogo carregado. | sucesso |
| LOAD FAILURE | O jogo salvo está danificado ou é incompatível. Nada foi alterado. | erro |
| LOAD REJECTED DIALOGUE | Termine a conversa antes de carregar o jogo. | aviso |
| ROLLBACK FAILURE | Não foi possível carregar o jogo com segurança. | erro |

`SaveV2PlayerMessages.severity_of(key)` define o destaque. A UI não depende do EventBus.

## 5. Durn

- **Correção.** `DialogueBox.show_entry` exibia `entry.speaker_id` sem traduzir, enquanto o texto e as
  escolhas já passavam pelo `LocalizationService`. Agora o falante também passa, e
  `npc.vardhelm.elder.name` aparece como **Durn**.
- **Sem localizador,** o comportamento anterior é preservado.
- **Inalterados:** o ID canônico `npc.vardhelm.durn`, o `GameIdCatalog`, o `DialogueState`, os dados do
  diálogo e o conteúdo narrativo. Há teste de regressão.

## 6. Performance — C9 × C10

Mesma ferramenta, mesma máquina (Intel UHD, Forward+/D3D12, 960×540), 5 amostras por cenário. Valores
em ms.

| Série | Métrica | C9 | C10 |
|---|---|---|---|
| **Renderizado** | cold | 119,0 | 100,4 |
| | warm | 118,0 | 92,0 |
| | medianas (cenários 3–8) | 102,6–113,3 | 92,3–100,6 |
| | mín | 93,5 | 89,6 |
| | máx | 586,4 ¹ | 117,6 |
| | criação do sandbox 1 (medianas) | 42,5–48,5 | 38,2–42,0 |
| | criação do sandbox 2 (medianas) | 49,9–52,2 | 44,0–49,0 |
| | apply | 1,1–2,3 | 1,0–2,2 |
| | rollback | 1,6 | 1,8 |
| | Save (mín/med/máx) | 13,1 / 17,0 / 19,6 | 8,2 / 9,8 / 18,0 |
| | frame ocioso (mediana) | 251,3 | 16,6 |
| **Headless** | cold | 73,9 | 67,7 |
| | warm | 72,1 | 66,0 |
| | medianas (cenários 3–8) | 66,1–77,7 | 67,3–84,8 |
| | mín | 63,2 | 64,6 |
| | máx | 88,8 | 106,9 |
| | criação do sandbox 1 / 2 (medianas) | 29,6–36,1 / 28,0–32,3 | 28,9–42,8 / 29,2–35,1 |
| | Save (mín/med/máx) | 7,0 / 12,1 / 14,4 | 6,5 / 6,7 / 13,0 |

¹ Pico único no C9, na criação do sandbox 2.

**Leitura, sem juízo de rápido ou lento:**

- A criação das duas instâncias de sandbox continua sendo a maior parte do Load. Apply, validação e
  rollback ficam abaixo de 3 ms.
- **Há variação grande entre execuções na mesma máquina.** O frame ocioso renderizado mediu 251 ms no C9
  e 16,6 ms no C10. Uma execução renderizada do C10 foi interrompida pelo timeout de 400 s e teve de ser
  refeita. Por isso as diferenças entre C9 e C10 **não devem ser atribuídas às mudanças do C10** sem
  mais amostras. As mudanças do C10 (câmera, UI, mensagens) não alteram o caminho de criação dos
  sandboxes, que só ganhou a troca de câmera.
- **Nada foi otimizado.** Os dois sandboxes e o rehearsal continuam. A decisão sobre usar um único
  sandbox fica para depois do playtest humano, se necessário.

## 7. Flags

`SAVE_V2_OPERATIONAL_LOAD_ENABLED = false` e `SAVE_V2_OPERATIONAL_SAVE_ENABLED = false`, testados na
instância padrão do jogo. Para o teste humano, o checklist explica como ligá-las **temporariamente**,
editando uma linha e revertendo depois. Não existe modo de teste permanente.

## 8. Sem mudança

- Save V2, Load V2, rollback, sandbox duplo e GameState sombra continuam iguais.
- O V2 persiste a projeção do runtime; nenhum gameplay consulta o GameState.
- `game_saved`/`game_loaded` só aparecem após sucesso, e não há eventos novos.
- O caminho legado continua (**LEGACY COMPATIBILITY PATH**, com `save_service.gd:44` não corrigido).
- Saves antigos não são modificados.

## 9. Limitações

- **Validação:** não houve playtest humano; só o checklist foi preparado.
- **Medição:** feita em uma única máquina, com variância alta entre execuções.
- **Rollback failure:** em ROLLBACK_FAILURE a UI transitória não é descartada, e o estado do jogo não é
  confirmado. A mensagem ao jogador diz isso.
- **Testes legados:** os `extends Node` continuam não executáveis diretamente (C7 §13).
