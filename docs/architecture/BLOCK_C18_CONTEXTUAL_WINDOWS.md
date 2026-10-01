# Bloco C18 — Ciclo de vida das janelas contextuais

**Status:** implementado; validação automatizada completa; **teste humano pendente** (o bloco só é aprovado depois dele).

## 1. Problema

A dica de interação ("E • Examinar", "E • Falar com Durn", "E • Observar o Eco", …) seguia o candidato do detector quadro a quadro:
- sumia no instante em que o jogador saía da área;
- aparecia e sumia a cada passo na borda da área.

## 2. Auditoria: o que é janela contextual

| Elemento | Quem abre | Entra no C18? |
|---|---|---|
| `InteractionHint` (dica "E • …") | proximidade: o candidato do `InteractionDetector` | **sim**: é a única janela aberta por proximidade |
| `ObservationPanel` (texto da observação) | tecla E; fecha por timer de 5 s | não: é aberto por ação, não por proximidade |
| `DialogueBox` (conversa) | tecla E em Durn | não, e **nunca** é fechado por distância |

A dica serve a todos os alvos: observações ambientais, suporte de ferramentas, Eco, painel selado, folha do C16 e Durn. Como o componente fica na dica, todos passam a usar o ciclo sem nenhuma mudança neles.

## 3. Arquitetura

**`ContextualWindowLifecycle`** ([`godot/scripts/ui/contextual_window_lifecycle.gd`](../../godot/scripts/ui/contextual_window_lifecycle.gd)) é um `Node` genérico que só cuida da apresentação:
- **quando** abrir ou fechar continua sendo decidido pelo sistema existente (o sinal `candidate_changed` do detector);
- o componente decide **como** a janela entra, fica e sai.

```
HIDDEN ──request_open──▶ VISIBLE          fade-in curto; não reinicia se já está visível
VISIBLE ──request_close──▶ PENDING_CLOSE  espera close_delay; continua na tela
PENDING_CLOSE ──request_open──▶ VISIBLE   cancela o fechamento; sem animação
PENDING_CLOSE ──timeout──▶ CLOSING ──▶ HIDDEN   fade-out curto
CLOSING ──request_open──▶ VISIBLE         volta a partir da opacidade atual
qualquer ──force_hide──▶ HIDDEN           imediato (ex.: começou uma conversa)
```

- **Sem `_process`** e sem checagem de distância: um `Timer` de uso único ("CloseDelay") e tweens curtos em `modulate:a`.
- A janela é **um nó só**: nada é criado ou recriado. `open_count` conta as entradas reais (fade-in) e serve para medir "sem reinício".
- **Estado transitório:** nada vai para o Save V2, GameState, EventBus ou quests.

**Integração** ([`vardhelm_vertical_slice.gd`](../../godot/scripts/vardhelm/vardhelm_vertical_slice.gd)): `_on_candidate_changed` passou a ter três casos:
- **conversa ativa** → `force_hide()`;
- **sem candidato** (ou candidato desabilitado) → `request_close()`;
- **com candidato** → `request_open()`, e o texto é trocado como antes.

Trocar de alvo durante o atraso mantém a mesma janela e só troca o texto. `_on_dialogue_started` usa `force_hide()`: a conversa fecha a dica na hora, como no C11.

## 4. Dados

[`godot/data/ui/contextual_windows.json`](../../godot/data/ui/contextual_windows.json):

```json
{"interaction_hint": {"close_delay": 0.75, "fade_in": 0.10, "fade_out": 0.15}}
```

- Os valores ausentes usam esses mesmos padrões.
- `close_delay <= 0` fecha sem espera, e fade `<= 0` desliga a animação.

## 5. Decisões

- **Histerese espacial: não adicionada.**
  - O atraso de fechamento já absorve a oscilação na borda: sair e voltar dentro de 0,75 s não produz piscada.
  - Uma histerese de raio exigiria mudar o detector, o que o bloco proíbe.
  - A borda continua sendo a mesma para o E: o candidato do detector não mudou.
- **Durante o atraso, a dica mostra o texto do último alvo, mas o E não age.** O detector não tem candidato nesse intervalo. É o comportamento esperado de "janela saindo", mas precisa ser observado no teste humano.
- **Load:** não força o fechamento.
  - O detector não reemite o sinal para o mesmo candidato, então fechar à força deixaria a dica escondida com um alvo na frente.
  - Se o Load leva o jogador para longe, o detector emite "sem candidato" e a dica fecha pelo ciclo normal.
- **Conversa:** a distância nunca fecha uma conversa. O componente não conhece o `DialogueBox`.

## 6. Testes

| # | Critério | Onde |
|---|---|---|
| A | entrar → aparece | suite C18 (componente e dica) + playtest |
| B | permanecer → não reinicia | suite + playtest (1,5 s parado, alpha 1, `open_count` fixo) |
| C | sair → não some na hora | suite (timer 0,75 s) + playtest (visível nos primeiros 0,3 s) |
| D | depois do atraso → fecha com fade-out | suite + playtest (some cerca de 0,9 s após sair) |
| E | volta rápida → cancela | suite + playtest (sai e volta em cerca de 0,17 s: nenhuma piscada) |
| F | sem piscar | suite (sequência de estados) + playtest (8 travessias da borda) |
| G | uma janela só | suite + playtest |
| H | conversa não afetada | suite + playtest (a dica sai na hora; 1,5 s longe e a conversa segue) |
| I | E funciona | suite (conversa/quest) + playtest (E examina o suporte) |
| J/K/L | Eco, painel, folha do C16 | playtests C11, C15, C16 e C17.3 (inalterados) |
| M | Save sem estado visual | suite + playtest |
| N | Load não cria janela | suite + playtest |

- Suite do runner: [`test_c18_contextual_windows.gd`](../../godot/tests/save_v2/test_c18_contextual_windows.gd).
- Playtest com frames reais: [`c18_contextual_windows_playtest.gd`](../../godot/tests/save_v2/c18_contextual_windows_playtest.gd). É automatizado, **não é teste humano**.

- **Regressão:**
  - runner 1652/1652;
  - C11 52/52, C9 66/66, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17, renderizados e headless;
  - cena principal sem erros; legados iguais à linha de base; saves reais intactos; `tsc` limpo.
- **Desempenho:**
  - A/B na mesma sessão, com o componente trocado por um stub do comportamento antigo: 24,77 ms sem o C18 e 24,74 ms com ele (mediana);
  - o valor absoluto acima dos 16,3 ms do C17.3 vem da máquina rodando na bateria, não do bloco.

## 7. Teste humano (pendente)

Rodar `vp_01_vardhelm` e, para cada alvo, fazer quatro coisas:
1. aproximar;
2. ficar parado;
3. afastar devagar;
4. afastar e voltar logo.

Os alvos são:
- observações ambientais;
- suporte de ferramentas ("E • Examinar");
- Eco;
- painel selado;
- folha no lugar de Durn (C16, depois de "Não senti nada.");
- Durn.

Observar:
- a dica entra suave;
- não pisca parado nem na borda;
- ao sair, fica cerca de 0,75 s e some suave;
- ao voltar rápido, não some;
- ao falar com Durn, some na hora e a conversa não fecha;
- se a espera parece longa ou curta, ajustar `close_delay` no JSON.

## 8. Regra de produção para cenários futuros (registrada no C18)

Todo cenário novo segue um pipeline integrado, nesta ordem: **CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO**. Vardhelm não foi alterado por esta regra.
