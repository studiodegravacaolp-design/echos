# ECHOES OF THE SOUL — C12: continuidade narrativa pós-Primeiro Eco (Vardhelm)

> **Status do teste manual:** **NÃO EXECUTADO.** Os testes do C12 foram **automatizados**
> (headless e renderizados com input simulado) e **não substituem** o roteiro manual abaixo.
> **Relacionados:** [C10](BLOCK_C10_ADOPTION_HARDENING.md) · [Checklist C10](C10_HUMAN_PLAYTEST_CHECKLIST.md)

## 1. A ponte

```
Durn (conversa inicial, inalterada) → quest "vardhelm_first_echo" → Primeiro Eco
  → o mundo reage (esfera some, memória, ambiente echo_awakened, banner)
  → o jogador continua explorando (observações; o painel selado já tem texto pós-Eco)
  → Durn reage UMA vez (diálogo "vardhelm_after_echo"), sem explicar nada
  → pista concreta: o painel selado, no fundo do setor, "fez um barulho"
  → nova investigação curta: quest "vardhelm_sealed_panel" (examinar o painel selado)
```

- **Condição de desbloqueio (persistente):** flag de mundo `vardhelm_first_echo_complete`
  **ou** quest `vardhelm_first_echo` concluída. As duas já são salvas/restauradas pelo Save V2.
- **Sem repetição:** depois de concluída (`DialogueRuntimeState.is_completed("vardhelm_after_echo")`),
  falar com Durn abre o mesmo diálogo na entrada `clue`: só a pista e a despedida, sem escolhas.
- **A nova investigação** começa ao concluir a conversa pós-Eco (uma vez) e termina ao examinar o
  painel selado com ela ativa. O painel pode ser examinado de novo (texto pós-Eco já existente),
  e a quest só conclui uma vez.
- **Nada novo de sistema:** DialogueController/DialogueRuntimeState, QuestController/QuestState,
  LocalizationService, EnvironmentalObservation, EventBus sombra e Save/Load V2 existentes. Os IDs
  novos entram no `GameIdCatalog` (`dialogue.vardhelm.after_echo`, `quest.vardhelm.sealed_panel`)
  e no `VardhelmRuntimeStateProvider` (definição do diálogo e apresentação da quest).
- **Texto:** todo em `data/localization/pt-BR.json`. Durn não explica o Eco, a memória, Aethel,
  Asterion, o Homem Cinzento, a origem dos Ecos nem a cosmologia. À pergunta "Você sabe o que era?"
  ele responde "Não."

## 2. Roteiro manual (A–N)

Abrir o projeto no Godot 4.7.1 e rodar a cena principal (F5). Teclas: WASD/setas movem, E interage,
clique/Enter no diálogo, Ctrl+S salva, Ctrl+L carrega. Marcar **PASS / FAIL / NOT TESTED**.

| # | Passo | Esperado | Resultado |
|---|---|---|---|
| A | Falar com Durn antes do Eco | "...Você também sentiu isso?" (conversa inicial de sempre) | NOT TESTED |
| B | Escolher "Sentir o quê?" e concluir | objetivo "Investigue…"; esfera disponível | NOT TESTED |
| C | Falar com Durn de novo **antes** do Eco | conversa inicial outra vez; nenhuma reação nova | NOT TESTED |
| D | Ctrl+S; resolver o Primeiro Eco | "Jogo salvo."; esfera some, memória, ambiente muda, banner | NOT TESTED |
| E | Examinar observações | painel selado: "…vibração do outro lado." | NOT TESTED |
| F | Falar com Durn depois do Eco | "...Você voltou." com duas escolhas; o nome Durn aparece | NOT TESTED |
| G | Com a conversa aberta, Ctrl+L | "Termine a conversa antes de carregar o jogo."; conversa segue aberta | NOT TESTED |
| H | Escolher, perguntar "Você sabe o que era?" e concluir | "Não."; depois a pista do painel selado; "Se for olhar... vá com calma." | NOT TESTED |
| I | Olhar o objetivo | "Procure o painel selado no fundo do setor."; banner antigo some | NOT TESTED |
| J | Falar com Durn de novo | só a pista e a despedida, **sem escolhas** (não repete a conversa) | NOT TESTED |
| K | Ctrl+S; mover-se; Ctrl+L | "Jogo carregado."; investigação ainda ativa; Durn continua só no lembrete | NOT TESTED |
| L | Examinar o painel selado | objetivo "✓ O painel selado — ainda fechado." | NOT TESTED |
| M | Ctrl+S; mover-se; Ctrl+L (duas vezes) | mesmo estado: investigação concluída; sem banner antigo; nada reaparece | NOT TESTED |
| N | Novo jogo: resolver o Eco, Ctrl+S **antes** de falar com Durn, fazer a conversa pós-Eco, Ctrl+L | volta para antes da conversa; sem investigação; Durn reage de novo (uma vez) | NOT TESTED |

### Falhas observadas

| Passo | Esperado | Observado | Captura |
|---|---|---|---|
| — | — | — | — |
