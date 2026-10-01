# ECHOES OF THE SOUL — BLOCO C9: V2 ADOPTION READINESS + RENDERED PERFORMANCE + PLAYTEST

> **Jogo:** ECHOES OF THE SOUL · **Mundo:** AETHERIS · **Cenário:** Vardhelm · **Runtime:** Godot 4.7.1
> **Depende de:** [C7](BLOCK_C7_V2_OPERATIONAL_LOAD.md) · [C8](BLOCK_C8_V2_ADOPTION_AND_OPERATIONAL_SAVE.md) · **Política:** [SAVE_MIGRATION_POLICY.md](SAVE_MIGRATION_POLICY.md) · **Matriz:** [GAMESTATE_RUNTIME_RESTORE_MATRIX.md](GAMESTATE_RUNTIME_RESTORE_MATRIX.md)
> **Testes:** `godot/tests/save_v2/test_c9_adoption_readiness.gd`, `test_c9_adoption_readiness_vardhelm.gd` · **Playtest renderizado:** `godot/tests/save_v2/c9_rendered_playtest.gd`

---

## 1. Resultado

- **Evidência coletada:**
  - performance **com renderização** e headless, pela mesma ferramenta e sem misturar as séries;
  - custo de cada sandbox;
  - UX localizada para recusas e falhas, com a mensagem do jogador separada do log técnico;
  - detecção dos saves antigos;
  - playtest automatizado renderizado com as duas flags ligadas: **31/31**.
- **Defaults intocados:** as duas flags continuam **OFF**.
- **Defeito de integração encontrado e corrigido (§8):** depois de um Load V2 que volta no tempo, a
  deduplicação de eventos do B1 impedia a sombra de registrar o gameplay seguinte.

## 2. Playtest renderizado (automatizado)

**Como roda:**

```
godot --path godot --windowed --resolution 960x540 --script res://tests/save_v2/c9_rendered_playtest.gd -- --out=<dir> --samples=5
```

- Abre a janela do jogo (Windows, **Forward+ / D3D12, Intel(R) UHD Graphics**) e avança frames reais.
- Usa Ctrl+S e Ctrl+L de verdade, com as flags ligadas **só nas instâncias do playtest**.
- Salva capturas de tela e um relatório JSON.
- Não faz parte do runner headless.
- O modo vem de `SaveV2LoadMetrics.render_mode()`: uma execução headless nunca é rotulada como
  "rendered".
- Usa arquivos próprios (`user://c9_playtest/`); o save antigo do usuário é salvo antes e restaurado
  depois.

**Isto é um playtest automatizado, não uma sessão jogada por uma pessoa.** O input, os frames e a
renderização são reais. A verificação visual foi feita nas capturas de tela.

| Fluxo | Resultado |
|---|---|
| 1 explorar → Durn → quest → Save → Eco + memória + observações → Save → mover → Load | posição, quest, Eco, memória, observações, consequência, NPC, ambiente e diálogo restaurados; GameState == runtime (save) e == carregado (load); eventos `game_saved, game_saved, game_loaded` |
| 2 save antes do Eco → Eco + mundo alterado → Load | estado anterior ao Eco: esfera e luz visíveis, sem ambiente pós-Eco, sem banner, observações não descobertas, posição do save |
| 3 save depois do Eco → alterar → Load | estado pós-Eco restaurado; alteração desfeita |
| 4 diálogo aberto → Load | recusa clara; diálogo continua aberto; sessão intacta; nenhum evento; a mensagem some sozinha |
| 5 diálogo → escolha → Save → concluir → alterar → Load | última escolha (`leave`) persistida; sessão **não** reaberta |
| 6 checksum corrompido → Load | mensagem clara; runtime intacto; nenhum evento |
| 7 falha injetada no apply / no rollback | rollback (estado anterior) + mensagem; ROLLBACK_FAILURE → "Não foi possível carregar o jogo com segurança."; nenhum evento |
| 8 flags OFF | Ctrl+S e Ctrl+L legados; defaults continuam OFF |
| 9 flags ON | somente V2; sem fallback; o save antigo (sentinela) fica intocado |

**Achados visuais nas capturas** (registrados, **não corrigidos**, porque estão fora do escopo do C9):

- **Painéis transitórios sobrevivem ao load.** Os painéis de observação e de "Eco de memória" abertos
  antes do load continuam na tela até os próprios timers vencerem (≤ 5 s). Por desenho, o load não
  restaura nem fecha UI transitória. Depois de voltar a um estado anterior, o painel mostra por alguns
  segundos informação do estado desfeito.
- **A câmera se reenquadra** alguns frames depois do teleporte do jogador (câmera transitória).
- **A mensagem de status é pequena e discreta.** Ela usa o `status_label` existente, sob o painel de
  objetivo. Dá para ler, mas pode passar despercebida.
- **Pré-existente, fora do V2:** a caixa de diálogo mostra o falante como a chave crua
  `npc.vardhelm.elder.name`, em vez de "Durn".

## 3. Performance

Tudo em ms, com 5 amostras por cenário (os cenários 1 e 2 têm uma amostra cada). Formato: mín /
mediana / média / máx. A série headless foi medida pela mesma ferramenta e na mesma máquina.

### 3.1 Total do Load V2

| Cenário | Renderizado | Headless |
|---|---|---|
| 1 primeiro Load (cold) | 119,0 | 73,9 |
| 2 segundo Load (warm) | 118,0 | 72,1 |
| 3 antes do Eco | 102,5 / 105,1 / 105,9 / 112,8 | 63,6 / 69,5 / 70,0 / 78,4 |
| 4 depois do Eco | 105,2 / 113,3 / 113,2 / 121,0 | 68,5 / 69,6 / 71,1 / 76,2 |
| 5 com observações | 109,5 / 111,4 / 112,6 / 118,5 | 72,4 / 77,7 / 79,2 / 88,8 |
| 6 diálogo persistido | 97,6 / 102,6 / 105,5 / 116,0 | 63,2 / 69,9 / 69,2 / 72,7 |
| 7 quest ativa | 93,5 / 104,3 / 103,7 / 114,8 | 65,2 / 66,1 / 66,8 / 70,8 |
| 8 quest concluída | 98,7 / 108,9 / 202,5 / **586,4** ¹ | 66,7 / 75,7 / 75,2 / 83,4 |
| **faixa geral** | mín 93,5 · medianas 102,6–113,3 · máx 586,4 | mín 63,2 · medianas 66,1–77,7 · máx 88,8 |
| Save V2 | 13,1 / 17,0 / 16,5 / 19,6 | 7,0 / 12,1 / 11,4 / 14,4 |

¹ Um único pico: a criação do sandbox 2 levou 523,8 ms nessa amostra. As outras 4 amostras do
cenário ficaram entre 98,7 e 121 ms. O pico foi registrado, não descartado.

### 3.2 Custo de cada sandbox (medianas dos cenários 3–8)

| Parte | Renderizado | Headless |
|---|---|---|
| sandbox 1: validação do arquivo | 3,0–6,2 | 1,5–4,1 |
| sandbox 1: **criação** (instanciar a cena) | 42,5–48,5 | 29,6–36,1 |
| sandbox 1: restore + verificação + comparação | 1,2–2,5 | 1,1–2,3 |
| sandbox 1: descarte | ≈0,5 | ≈0,4 |
| sandbox 2: **criação** | 49,9–52,2 | 28,0–32,3 |
| sandbox 2: restore + verificação | 1,3–2,5 | 1,2–2,5 |
| snapshot | 0,3–0,5 | 0,3–0,5 |
| apply no jogo principal | 1,1–2,3 | 0,9–2,2 |
| validação pós-restore | ≈0,09 | ≈0,08 |
| rollback (quando aplicado) | 1,6 | 1,6 |

- **Leitura.** A **criação das duas instâncias de sandbox** responde por cerca de 90% do load nas
  duas séries. Restore, apply, validação e rollback ficam cada um abaixo de 3 ms. Com renderização, a
  criação custa cerca de 1,5× a do headless.
- **Contexto de frame.** Nesta máquina, o frame ocioso renderizado mediu mínimo 1,0 / mediana 251,3 /
  média 169,6 / máximo 268,0 ms: a própria cena renderiza devagar no Intel UHD com Forward+. O
  headless mediu cerca de 6,9 ms. Por isso o "frame que contém o load" (mediana ≈ 235–246 ms
  renderizado) não se destaca do frame comum aqui.
- **Em hardware que rode a 60 fps**, cerca de 100–120 ms de load equivalem a uma pausa de 6–7 frames
  (um engasgo único e curto). Uma loading screen não se justifica. Uma indicação mínima só faria
  sentido se a medição no hardware-alvo mostrar pausa perceptível; está documentada como critério
  (§9), não implementada.
- **Sobre o C8.** O C8 mediu 141–214 ms headless com outra sonda, sem frames entre os loads e com
  outro estado do projeto. Os números devem ser comparados só dentro de uma mesma ferramenta.
- **Nada foi otimizado.** Os dois sandboxes foram mantidos.

## 4. UX: mensagem do jogador × log técnico

`SaveV2PlayerMessages` traduz o resultado em uma **chave de localização**. O log técnico
(`push_warning`, ou `push_error` em ROLLBACK_FAILURE) leva código, detalhes, falha original e falha do
rollback.

| Situação | Mensagem ao jogador (pt-BR) |
|---|---|
| Save OK | "Jogo salvo." |
| Save recusado ou inválido | "Não foi possível salvar o jogo agora. Nada foi alterado." |
| Falha de escrita | "Não foi possível gravar o jogo salvo. O save anterior foi mantido." |
| Load OK | "Jogo carregado." |
| Diálogo aberto | "Termine a conversa antes de carregar o jogo." |
| Sem save | "Nenhum jogo salvo encontrado." |
| Só existe save antigo | "Só existe um jogo salvo no formato antigo; ele não é carregado neste modo." |
| Checksum, schema ou arquivo inválido | "O jogo salvo está danificado ou é incompatível. Nada foi alterado." |
| Recusado antes do apply | "Não foi possível carregar este jogo salvo. Nada foi alterado." |
| Apply ou validação falhou (com rollback) | "Não foi possível carregar o jogo. O estado anterior foi mantido." |
| **ROLLBACK_FAILURE** | "**Não foi possível carregar o jogo com segurança.**" |

- As mensagens aparecem no `status_label` existente (sem UI nova) e **somem sozinhas depois de 4 s**,
  devolvendo o texto anterior. Um status mais recente nunca é apagado.
- Não fecham o diálogo e não mostram código nem stack trace (testado).
- Em ROLLBACK_FAILURE: nada de sucesso, nada de load antigo, o processo não fecha e o runtime não é
  destruído.
- **Localização:** 11 chaves `save.v2.*` em `data/localization/pt-BR.json`, resolvidas por
  `LocalizationService.tr_key`. A apresentação V2 do slice não tem nenhum texto fixo; os textos
  antigos do caminho legado ficaram como estavam.

## 5. Saves antigos

`SaveV2PersistenceInventory`, somente leitura, classifica os arquivos:

| Arquivo | Classificação |
|---|---|
| Caminho legado com JSON `{"version", "world"/"quests"}` sem `format` | **legado** |
| Caminho legado com `format = echoes_of_the_soul_save` | **envelope V2 no caminho legado** (sinalizado, não confundido) |
| Caminho legado ilegível ou com forma desconhecida | **não reconhecido** |
| Caminho V2 | **válido** ou **inválido** (com o código do C1) |

- **A. Só save antigo:** o Load V2 responde FILE_NOT_FOUND e o jogador vê "Só existe um jogo salvo no
  formato antigo…". O arquivo antigo não é lido nem alterado, e não há fallback.
- **B. Antigo + V2:** caminhos distintos. O V2 carrega e grava só o V2, e o antigo fica intocado.

A análise completa e as opções de migração estão em [SAVE_MIGRATION_POLICY.md](SAVE_MIGRATION_POLICY.md).
**Nenhuma opção foi escolhida.**

## 6. Eventos

Verificados no playtest e nos testes:

- `game_saved` só aparece depois de um Save com SUCCESS;
- `game_loaded` só aparece depois de um Load com SUCCESS;
- nenhum dos dois aparece com diálogo aberto, checksum ou validação com falha, rollback ou rollback
  failure;
- nenhum evento novo foi criado.

## 7. Estados das flags

`SAVE_V2_OPERATIONAL_LOAD_ENABLED = false` e `SAVE_V2_OPERATIONAL_SAVE_ENABLED = false`, sem
alteração. As flags só foram ligadas dentro das instâncias de teste e do playtest.

## 8. Sincronização do GameState — defeito encontrado e corrigido

- **Achado.** O `GameplayEventPublisher` (B1) deduplica consequências, observações e estados de
  ambiente durante a sessão inteira. Depois de um Load V2 que volta a um ponto anterior, refazer o Eco
  ou as observações **não gerava evento**, e a sombra ficava defasada. O próximo Save detectava a
  diferença (`shadow_divergence`) e gravava a projeção correta, então o arquivo nunca ficou errado,
  mas a sombra ficava divergente entre o Load e o Save.
- **Correção.** `GameplayEventPublisher.resync_after_load(state)` realinha a deduplicação ao estado
  carregado sem publicar nada. O slice a chama só depois de um Load V2 com SUCCESS.
- **Resultado.** Após Save, GameState == runtime persistente. Após Load, GameState == estado
  carregado. No Save seguinte a divergência é **vazia** (testado).

## 9. Critérios para ligar as flags por padrão (atualizados)

1. **Decisão explícita** registrada em [SAVE_MIGRATION_POLICY.md](SAVE_MIGRATION_POLICY.md) (A, B ou C).
2. **Load medido no hardware-alvo, com renderização.** Se a pausa (~100–120 ms aqui, ≈90% na criação
   dos sandboxes) for perceptível, avaliar reutilizar um único sandbox ou uma indicação mínima.
3. **Decisão sobre a UI transitória** (painéis) ao carregar: fechá-la no load com SUCCESS, ou aceitar
   que expire sozinha.
4. **Visibilidade das mensagens** de save/load: o `status_label` atual é discreto.
5. **Playtest humano** com as duas flags ligadas, cobrindo pelo menos os fluxos 1–9.
6. **`save_service.gd:44`:** corrigir ou encerrar o caminho legado.

## 10. Limitações

- O playtest é automatizado; não foi uma sessão jogada por uma pessoa.
- Só uma máquina foi medida (Intel UHD, Forward+, D3D12). Os frames renderizados dela são lentos.
- Os achados visuais do §2 não foram corrigidos.
- Testes legados `extends Node` continuam não executáveis diretamente (C7 §13).
