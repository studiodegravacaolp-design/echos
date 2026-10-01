# ECHOES OF THE SOUL — C15: primeira escolha com consequência perceptível (Vardhelm)

> **Status:** implementado, testes automatizados verdes. **Aguarda o teste humano** (seção 6). O roteiro
> para o jogador está numa seção separada e **não** revela a consequência. Não mostre as seções 1–5 a
> quem vai jogar antes do teste.
> **Relacionados:** [C14](BLOCK_C14_FIRST_SEQUENCE.md) · [C13](BLOCK_C13_LIVING_VARDHELM.md)

## 1. Auditoria das escolhas existentes

| # | Onde | Opções | Efeito antes do C15 |
|---|---|---|---|
| 1 | Primeira conversa com Durn (`dialogue.vardhelm.intro`, entrada `start`) | "Sentir o quê?" (`learn`) / "Não senti nada." (`leave`) | `learn` aplica `vardhelm_heard_echo` (flag + memória), **sem nada visível**; `leave` não faz nada |
| 2 | Conversa pós-Eco (`dialogue.vardhelm.after_echo`, `start`) | "Encontrei alguma coisa." / "Não sei o que foi aquilo." | nenhum (só registrada) |
| 3 | Conversa pós-Eco (`noticed`) | "Você sabe o que era?" / "Você também sentiu?" | nenhum (só registrada) |

**Selecionada: a nº 1, opção "Não senti nada."** Motivos:

- é a primeira decisão do jogador e é relacional: o jogador **nega** para Durn o que ele sentiu;
- acontece cedo, o que deixa espaço para a consequência aparecer **depois** (no Eco), e não na hora;
- era a única opção sem efeito algum, então a consequência não mexe na que já existe (`vardhelm_heard_echo`);
- a fala de Durn que ela provoca, "Se acontecer de novo... procure por mim.", dá sentido à consequência;
- a consequência reforça o gancho do C14 ("Então não fui só eu.") sem alterá-lo;
- as escolhas 2 e 3 ficam dentro da conversa pós-Eco, onde uma consequência seria imediata e menos
  "descoberta".

## 2. A consequência

"Se acontecer de novo... procure por mim." Se o jogador disse que não sentiu nada, quando o Eco acontece
(quando *acontece de novo*), Durn não espera por ele. Pouco depois, ele sai andando sozinho até **onde o
Eco aconteceu** e fica ali, olhando para a marca no chão. O jogador, que está no Eco, vê Durn chegar.
Depois ele não está mais no lugar de sempre: continua junto à marca do Eco.

Com "Sentir o quê?", nada muda: Durn espera no lugar de sempre, como antes do C15.

- Sem texto novo, sem mensagem, sem ID na tela. As falas de Durn (conversa inicial, C12, gancho do C14)
  são as mesmas.
- A conversa pós-Eco e o gancho do C14 acontecem onde Durn estiver.
- **Por que o lugar do Eco, e não o painel:** a primeira versão levava Durn para junto do painel
  selado. O playtest mostrou dois problemas:
  1. perto do painel, o E às vezes falava com Durn em vez de examinar o painel (mesma prioridade,
     vence o mais próximo);
  2. no canto mais afastado, a parede em primeiro plano escondia Durn da câmera.

  O lugar do Eco é aberto, fica no campo de visão, e o Eco já está desativado quando Durn chega, então
  não há disputa de interação (verificado por geometria e andando).

## 3. IDs e fluxo de eventos

| Papel | ID |
|---|---|
| Escolha (existente, estável) | `dialogue.vardhelm.intro` / `start` / `leave` |
| Consequência | `consequence.vardhelm.felt_nothing` (runtime `vardhelm_felt_nothing`), fonte `dialogue.vardhelm.intro` |
| Estado de mundo (derivado) | `envstate.vardhelm.durn_alone` (runtime `durn_alone`) |

```
dialogue_choice_selected (leave)
→ consequence_applied (consequence.vardhelm.felt_nothing, source dialogue.vardhelm.intro)
→ world_state_changed (envstate.vardhelm.durn_alone)
… mais tarde, no Eco:
→ consequence_applied (first_echo_complete) → world_state_changed (echo_awakened)
→ durn_alone + echo_awakened ⇒ Durn caminha até onde o Eco aconteceu (apresentação)
```

Tudo passa pelo EventBus e pelo NarrativeController existentes. A escolha usa o campo `consequences`
que o diálogo já tinha. Nenhum polling novo e nenhum sistema paralelo.

## 4. Persistência

- **Salvo:** a decisão (DialogueState: `intro/start = leave`) e a consequência (`world.consequences` +
  flag/memória no runtime), pelo Save V2 existente, com IDs canônicos.
- **Não salvo, derivado:** o estado `durn_alone` e a posição de Durn. No Load, o AmbientLife é
  re-derivado (reset + derivação existente) e o slice recoloca Durn **direto no lugar**, sem reencenar a
  caminhada. Um save de antes da escolha devolve Durn ao lugar de sempre. O NPC nunca é recriado.

## 5. Arquivos

- `godot/data/dialogue/vardhelm_intro.json`: `consequences` na opção `leave` (textos iguais).
- `godot/data/vardhelm/ambient_life.json`: consequência → `durn_alone`; bloco `durn_alone` (lugar,
  direção, espera e duração da caminhada).
- `godot/scripts/state/id_catalog.gd`: consequência, estado, aliases e fonte.
- `godot/scripts/vardhelm/vardhelm_ambient_life.gd`: `durn_alone_def`, `is_durn_alone_after_echo`.
- `godot/scripts/vardhelm/vardhelm_vertical_slice.gd`: `_apply_durn_presence` (ao vivo: caminha;
  derivação/Load: no lugar).
- Testes: `test_c15_choice_consequence.gd` (runner) e `c15_choice_playtest.gd` (input real).

## 6. Teste humano — roteiro para o jogador

> Entregue só esta seção a quem vai jogar.

Jogue Vardhelm **duas vezes**, do começo até o fim da conversa depois do painel selado. Jogue como
jogador, sem procurar bugs. Na segunda vez, responda de outro jeito nas conversas. Em cada partida,
salve (Ctrl+S) e carregue (Ctrl+L) pelo menos uma vez, em algum momento depois do Eco.

Depois das duas partidas, conte em poucas palavras:

1. As escolhas pareceram naturais?
2. Alguma coisa foi diferente entre as duas partidas? O quê?
3. Você sentiu que o mundo, ou alguém, reagiu ao que você fez?
4. Pareceu consequência da sua escolha, mesmo sem nenhum texto explicando?
5. Pareceu natural, ou forçado?
6. Depois de salvar e carregar, as coisas continuaram como estavam?
7. Pareceu significativo sem exagero?
8. O ritmo de Vardhelm continuou bom?
9. O resto da sequência (Eco, painel, silêncio, a última fala de Durn) continuou como antes?
