# ECHOES OF THE SOUL — C16: uma escolha muda uma possibilidade futura (Vardhelm)

> **Status:** implementado, testes automatizados verdes. **Aguarda o teste humano** (seção 7). Entregue a
> quem vai jogar **só** a seção 7: as outras revelam a consequência.
> **Relacionados:** [C15](BLOCK_C15_CHOICE_CONSEQUENCE.md) · [C14](BLOCK_C14_FIRST_SEQUENCE.md)

## 1. Auditoria das interações de Vardhelm

| Interação | Situação | Serve como possibilidade futura? |
|---|---|---|
| Durn: 3 conversas (inicial, pós-Eco, pós-painel) | aprovadas no C10.5/C12/C14 | **não**: mexer nelas altera o comportamento aprovado de Durn |
| Primeiro Eco | desativado depois de resolvido | **não**: reabrir duplicaria o Eco |
| Quadro de manutenção / ferramentas | existem nos dois caminhos, com texto pós-Eco | **fraco**: não há por que a negação mudar o quadro |
| Painel selado | investigação do C12/C14, fechado | **não**: o C14 fica intacto e o painel não abre |
| Marca do Eco no chão | decorativa; no caminho B, Durn fica em cima dela | **não**: disputaria o E com Durn |
| Trabalhadores e estações | sem interação | **não**: exigiria infraestrutura nova |
| **Lugar de sempre de Durn** | no caminho B (C15) ele fica **vazio** depois do Eco | **sim**: a ausência abre uma oportunidade |

## 2. A possibilidade escolhida

No caminho "Não senti nada.", quando o Eco acontece, Durn sai sozinho (C15) e deixa para trás o que fazia:
uma **folha dobrada**, caída no lugar de sempre dele. Ela pode ser examinada:

> **Folha dobrada** — "Uma folha dobrada, caída onde Durn costumava ficar. Horários anotados à mão, todos
> de hoje. O último está sublinhado duas vezes."

No caminho "Sentir o quê?", Durn nunca sai, então não há folha: ali o E continua sendo para ele.

- **Por que reutilizar o C15:** a folha só pode ser vista porque Durn saiu. É a consequência do C15 que
  abre a oportunidade, sem ligação forçada.
- **Menor interação nova:** uma observação do tipo que já existe (`EnvironmentalObservation`), descrita em
  `ambient_life.json`, sem memória nova, sem quest e sem diálogo. Ela fica numa lista separada
  (`conditional_observations`) para não mudar as 3 observações de sempre, e um teste legado conta
  exatamente 3.
- **Texto:** observacional, sem explicar nada. "Todos de hoje" conversa com "Você também sentiu isso?" e
  com "Hoje ele fez um barulho que eu nunca tinha ouvido", e o jogador conclui o resto.

## 3. IDs e condição

| Papel | ID |
|---|---|
| Escolha (existente) | `dialogue.vardhelm.intro` / `start` / `leave` |
| Consequência (C15) | `consequence.vardhelm.felt_nothing` |
| Estado derivado (C15) | `envstate.vardhelm.durn_alone` (+ `envstate.vardhelm.echo_awakened`) |
| **Interação** | `observation.vardhelm.durn_notes` (runtime `durn_notes`) |

**Condição (explícita, uma só):** `VardhelmAmbientLife.is_durn_alone_after_echo()`, a mesma que tira Durn
do lugar no C15. `VardhelmVerticalSlice._apply_durn_presence` aplica as duas coisas juntas: onde Durn
está e se a folha existe. Nunca depende da posição do jogador.

## 4. Fluxo de eventos (EventBus existente, uma vez cada)

```
dialogue_choice_selected (leave)
→ consequence_applied (consequence.vardhelm.felt_nothing)
→ world_state_changed (envstate.vardhelm.durn_alone)
→ … Eco: consequence_applied (first_echo_complete) → world_state_changed (echo_awakened)
→ (derivado) Durn sai; a folha passa a existir
→ examinar: observation_discovered (observation.vardhelm.durn_notes)   ← reexame não repete
```

## 5. Persistência e Save/Load

- **Salvo (Save V2, IDs canônicos):** a decisão, a consequência e o fato de a folha ter sido examinada
  (`world.observations`).
- **Não salvo, derivado:** a disponibilidade da folha e onde Durn está. No Load, a derivação existente
  os recalcula.
- Um save de antes da escolha volta sem folha e com Durn no lugar. O caminho A salvo e carregado
  continua sem folha. A folha e Durn nunca são duplicados, e os Loads não reemitem nada.

## 6. Arquivos

- `godot/data/vardhelm/ambient_life.json`: `conditional_observations` com `durn_notes`.
- `godot/data/localization/pt-BR.json`: título e texto da folha.
- `godot/scripts/state/id_catalog.gd`: `observation.vardhelm.durn_notes`.
- `godot/scripts/vardhelm/vardhelm_ambient_life.gd`: lista condicional, cor opcional da marca,
  `set_observation_available` e `is_observation_available`.
- `godot/scripts/vardhelm/vardhelm_vertical_slice.gd`: a folha acompanha `_apply_durn_presence`.
- Testes: `test_c16_future_possibility.gd` (runner) e `c16_future_playtest.gd` (input real, 3 partidas).

## 7. Teste humano — roteiro para o jogador

> Entregue só esta seção a quem vai jogar.

Jogue Vardhelm **pelo menos duas vezes**, do começo até o fim da conversa depois do painel selado. Jogue
como jogador, sem procurar bugs. Na segunda vez, responda de outro jeito nas conversas. Explore com
calma, principalmente depois do Eco, e volte aos lugares por onde já passou. Em cada partida, salve
(Ctrl+S) e carregue (Ctrl+L) pelo menos uma vez depois do Eco.

Depois, conte em poucas palavras:

1. As escolhas pareceram naturais?
2. O que foi diferente entre as partidas?
3. Alguma coisa que você pôde fazer, ou encontrar, só apareceu numa das partidas?
4. Você percebeu a diferença sem nenhum texto explicando?
5. Conseguiu relacionar a diferença a algo que você fez antes?
6. Pareceu parte do mundo, ou uma mecânica de jogo?
7. Depois de salvar e carregar, as coisas continuaram como estavam?
8. O ritmo continuou bom?
9. O resto da sequência (Eco, painel, silêncio, a última fala de Durn) continuou como antes?
