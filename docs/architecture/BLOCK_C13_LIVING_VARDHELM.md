# ECHOES OF THE SOUL — C13: Vardhelm como espaço vivo

> **Status do teste manual:** **NÃO EXECUTADO** para o C13. Os testes do C13 foram **automatizados**
> (headless e renderizados com input simulado) e não substituem o roteiro da seção 5.
> **Relacionados:** [C12](BLOCK_C12_POST_ECHO_BRIDGE.md)

## 1. Auditoria: o que já reagia ao Primeiro Eco

| Elemento | Antes do Eco | Depois do Eco (antes do C13) | Persistente? |
|---|---|---|---|
| Esfera do Eco (malha + luz ciano) | visível | oculta | sim (derivada da flag/quest) |
| Marca no chão (`MemoryAfterglow`) | oculta | visível | sim |
| Banner "✓ Primeiro Eco registrado" | oculto | visível até a próxima etapa (C12) | sim |
| `environment_states` do AmbientLife | vazio | `echo_awakened` | sim (re-derivado no Load) |
| Rótulos de estação (`_set_station_attention`) | — | nada visível: rótulos ocultos (`show_station_labels=false`) e a função procura `Label3D` no nível errado | — |
| Trabalhadores (`react_to_consequence`) | rotina na estação | sobressalto de ~0,5 s e voltam à rotina | **não** |
| Rótulos "• ATENÇÃO" das estações | — | pulso temporário (invisível: rótulos ocultos) | não |
| Observações (quadro, painel, ferramentas) | texto normal | texto `after_echo` (já existia para as três) | sim |
| Luzes do cenário (forja, lâmpadas, 3 luzes de trabalho) | quentes, estáveis | iguais | — |
| Áudio (zumbido, vapor, máquinas) | 3 loops fixos | iguais | — |
| Durn | conversa inicial | conversa pós-Eco (C12) | sim |
| Eventos | — | `consequence_applied`, `world_state_changed`, `quest_progressed`, `quest_completed`, `echo_triggered`, `memory_recovered` | — |

**Conclusão:** longe da esfera, o mundo depois do Eco era idêntico ao de antes. As únicas reações
persistentes estavam no ponto do Eco. O resto era temporário ou invisível.

## 2. Reações escolhidas (3)

Todas são **derivadas** do estado persistente que já existia: flag `vardhelm_first_echo_complete`
→ `environment_state` `echo_awakened`, aplicadas em `VardhelmAmbientLife._apply_persistent_state_visuals`.
No Load V2 são desfeitas por `reset_persistent_state()` e re-derivadas pela derivação existente
(`derive_environment_state`). Nenhum estado novo é salvo e nenhum evento novo existe. Os parâmetros
ficam em `data/vardhelm/ambient_life.json` (`after_echo` e `after_echo_route`).

| # | O jogador vê/ouve | Antes | Depois | Por que chama atenção |
|---|---|---|---|---|
| 1 | Luz de trabalho sobre o **painel selado** (`WorkLight_00` + luminária `WorkLightFixture_00`) | âmbar, fraca, estável, como as outras duas | fria (#BFE3EA), um pouco mais forte e com alcance maior (2,4 → 3,6, chega ao painel e ao chão); a luz e a luminária falham juntas de vez em quando | é a única luz fria e instável do setor, justo sobre o painel apontado por Durn |
| 2 | Trabalhador da oficina (`worker_bench_01`) | vai e volta na bancada | depois do sobressalto, larga a bancada e fica parado perto do painel, mudando de pé de vez em quando | uma rotina conhecida quebrada; ninguém explica por quê |
| 3 | Som das máquinas (`VardhelmMachinery`) | −20 dB | −30 dB (o zumbido e o vapor continuam) | o setor fica perceptivelmente mais quieto, coerente com um trabalhador parado |

Sem texto novo e sem popup. O painel continua **fechado**: mesma placa, mesmo texto pós-Eco,
nenhum estado de abertura, nenhuma passagem.

## 3. Resíduos de UX corrigidos (pequenos)

- O banner "✓ Primeiro Eco registrado" foi para o `HudTop`, abaixo do objetivo e do status. Ele
  cobria parte do objetivo em 1152×648.
- O status "Você registrou o primeiro Eco. Ctrl+S…" sai quando a investigação do painel começa. Antes
  ele era reescrito a cada atualização do objetivo e ficava na tela.

## 4. Persistência

```
antes do Eco → estado A (lâmpada âmbar estável, trabalhador na bancada, máquinas −20 dB)
Eco          → consequência (uma vez) → estado B (lâmpada fria falhando, trabalhador perto do painel, −30 dB)
Save B → Load → estado B (re-derivado; não acumula: −30 dB, não −40)
Save A → Eco → Load → estado A (reset + derivação; trabalhador volta para a bancada)
```

## 5. Playtest humano (roteiro)

Abrir o projeto no Godot 4.7.1 e rodar a cena principal (F5). Controles: WASD/setas, E, Ctrl+S, Ctrl+L.
Marcar **PASS / FAIL / NOT TESTED**.

| # | Passo | O que observar | Resultado |
|---|---|---|---|
| 1 | Entrar em Vardhelm | trabalhador indo e voltando na bancada perto do suporte de ferramentas; luzes âmbar | NOT TESTED |
| 2 | Olhar a luz de trabalho sobre o painel selado (canto oeste, perto das caixas) | âmbar e estável, igual às outras | NOT TESTED |
| 3 | Falar com Durn | conversa inicial de sempre | NOT TESTED |
| 4 | Encontrar e examinar o Primeiro Eco | esfera some; trabalhadores se sobressaltam | NOT TESTED |
| 5 | Continuar explorando e voltar à área do painel | a luz sobre o painel está fria e pisca de vez em quando; o trabalhador da bancada está parado perto do painel; as máquinas soam mais baixo | NOT TESTED |
| 6 | Conferir que nada explica a mudança | nenhum popup nem texto do tipo "o mundo mudou" | NOT TESTED |
| 7 | Falar com Durn | conversa pós-Eco do C12; depois só o lembrete | NOT TESTED |
| 8 | Examinar o painel selado | continua fechado; investigação concluída | NOT TESTED |
| 9 | Olhar o HUD | banner abaixo do objetivo (não o cobre); status do Eco não fica preso | NOT TESTED |
| 10 | Ctrl+S, andar, Ctrl+L | mundo continua no estado pós-Eco (luz, trabalhador, som) | NOT TESTED |
| 11 | (opcional) Novo jogo: Ctrl+S **antes** do Eco → Eco → Ctrl+L | luz âmbar de novo, trabalhador de volta à bancada, som normal | NOT TESTED |

### Falhas observadas

| Passo | Esperado | Observado | Captura |
|---|---|---|---|
| — | — | — | — |
