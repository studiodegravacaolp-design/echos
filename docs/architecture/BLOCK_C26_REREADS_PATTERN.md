# Bloco C26 — Releituras e padrão: o passado recente da Forja

**Data:** 2026-10-01
**Tipo:** gameplay narrativo (Godot)
**Design de origem:** [`VARDHELM_INVESTIGATION_DESIGN.md`](../03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md) (§4, §16, H1–H9) e [`BLOCK_C25_THE_HOURS.md`](BLOCK_C25_THE_HOURS.md)
**Checkpoint Git:** último checkpoint `3f98c26`; C26 = bloco principal **2/5**. Sem commit e sem push.

## 1. Decisão humana: os horários do C25 são cânone

Aprovados para o cânone atual de Vardhelm:

- **5h58, 13h58 e 17h41** (17h41 = o momento do Primeiro Eco);
- quadro de turnos: trocas às **6h, 14h e 22h**.

**Leitura atual:** 5h58 e 13h58 caem pouco antes das trocas de 6h e de 14h. 17h41 **não** tem a mesma relação. Há um padrão parcial, mas não uma resposta.

**Revisão:** só se um sistema de tempo exigir isso concretamente no futuro.

## 2. Função

O C25 fez o jogador pensar "há alguma coisa nesses horários". O C26 o faz perceber que **esses horários se relacionam com algo que já aconteceu aqui**, sem resolver o mistério.

Objetos já conhecidos viram evidência nova:

> OBJETO CONHECIDO + INFORMAÇÃO NOVA = SIGNIFICADO NOVO

## 3. Auditoria (estado anterior)

| Objeto | Texto inicial | Depois do Eco (C13) | Fragmento | Persistência | Lugar |
|---|---|---|---|---|---|
| Quadro de manutenção | "Anotações de reparo, horários e marcas de uso…" | "…uma marca quase apagada chama sua atenção. Você não consegue dizer se ela sempre esteve ali." | "Registro de manutenção" (uma vez, na 1ª leitura) | vista → `world.observations`; fragmento derivado | face da máquina A, parede oeste (−5,7; −3,9), ao lado do lugar de Durn |
| Painel selado | "Uma placa metálica foi fechada e reforçada…" | "O painel permanece fechado… vibração do outro lado." | "O painel fechado" | idem; conclui a etapa do C12 | anteparo oeste (−6,7; 1,8), a ~5,8 m do quadro |

## 4. Releituras implementadas

A releitura aparece **depois da comparação no quadro de turnos** (quest "Os horários" concluída), em qualquer ordem entre os dois objetos. É a mesma observação: nenhuma observação nova e nenhum objeto novo.

| Objeto | Releitura | O que diz | O que NÃO diz |
|---|---|---|---|
| Quadro de manutenção | "Agora você procura as trocas de turno. Uma linha foi raspada; resta o fim de um horário: ...58." | havia uma anotação; foi removida; raspar não é desgaste; o fim "...58" combina com 5h58 e 13h58 | quem raspou, quando, por quê; que a linha fala do painel |
| Painel selado | "O painel continua fechado. Agora você repara: os parafusos do reforço são mais novos que a placa." | o reforço é posterior à placa | quem reforçou, quando, o que há atrás (H1) |

**Interpretação × mundo:** os dois textos começam pela mudança do olhar do jogador ("Agora você procura…", "Agora você repara…"). O objeto não mudou; mudou o que o jogador sabe procurar. Nenhum estado de ambiente novo, nenhuma reação do mundo.

**A marca apagada** continua a linha do C13 (a "marca quase apagada" que o jogador não sabia ler).

**17h41** fica fora: nenhum texto do C26 o menciona nem força correspondência. A comparação do C25 ("O sublinhado, não.") segue igual.

**Antes da comparação** (mesmo com os horários conhecidos), os dois objetos mostram o texto de sempre: a pergunta ainda não foi feita.

**Quem já tinha olhado** (até antes do Eco) vê a releitura ao examinar de novo. O fragmento da primeira leitura não se repete. **Quem nunca olhou** recebe já a leitura de quem sabe o que procurar; a descoberta e o fragmento acontecem uma vez.

## 5. Progressão e objetivo

| Etapa | Objetivo exibido |
|---|---|
| Antes (C25, "Nesses horários" ativa) | "Descubra o que acontece na Forja 01 nesses horários." |
| Uma evidência só (linha raspada **ou** reforço) | igual: o objetivo não muda |
| As duas evidências | "Nesses horários" concluída → começa **"O reforço"**: "Descubra quem reforçou o painel e onde ficam os registros da Forja." |

**Preparação do Galpão (H3):** o objetivo pede quem fez o reforço e onde ficam os registros. O Galpão não é nomeado, nem Elyra. Construí-lo é o C27.

**Durn (H2):** não conduz.
- Antes da linha raspada, continua "Não sei. Só sei que repetiu.".
- Depois, no caminho "Sentir o quê?": uma reação curta, "...Raspado? Não fui eu.", sem quest, conclusão ou horário novo.
- No caminho "Não senti nada.": continua em silêncio ("...").

**H8:** tudo por ação do jogador; nada por tempo.

## 6. Correção necessária: o quadro de manutenção alcançável com Durn no lugar

Ao implementar, o playtest mostrou um defeito antigo que agora bloqueava a investigação. A auditoria do C19 já registrava "Durn tem prioridade no canto do quadro", e o C11 que "Durn fecha o corredor forja × máquina".

- Com Durn no lugar de sempre (caminho "Sentir o quê?"), o bolsão em frente ao quadro fica isolado pelo corpo dele.
- O único acesso é o canto leste da máquina A. Ali, o detector escolhia Durn: a distância é medida em 3D, e a âncora do quadro ficava a 1,4 m de altura, enquanto a de Durn fica no chão.
- Mapa de colisão e candidato, medido com a cápsula real, antes e depois da correção: no canto (x −4,0…−3,4; z −4,4…−3,8) o candidato passa de Durn para o quadro.

**Correção (só dado):** a âncora de interação da observação `maintenance_board` desceu ao chão (y 1,4 → 0,25), como a de Durn. A peça visual do quadro não mudou.

- Durn continua o candidato ao lado dele.
- O bolsão da frente continua dando o quadro.
- `test_c17_forge_bay` foi atualizado com essa posição.

## 7. Estados

| Elemento | Tipo | Fonte |
|---|---|---|
| Evidências (linha raspada, reforço) | **PERSISTENTE** | objetivos `mark` e `panel` de `quest.vardhelm.those_hours` |
| "O reforço" ativo | **PERSISTENTE** | `quest.vardhelm.the_reinforcement` |
| Comparação feita (gatilho da releitura) | **PERSISTENTE (C25)** | `quest.vardhelm.the_hours` concluída |
| Objetos vistos, fragmentos | **PERSISTENTE (já existia)** | `world.observations`; fragmento derivado |
| Texto relido, objetivo exibido, fala de Durn | **DERIVADO** | quests + caminho (`VardhelmRereadsInvestigation`) |
| Janelas, dica | **TRANSITÓRIO** | C10/C18 |

**Nenhuma flag nova, nenhuma observação nova, nenhuma memória nova.** A releitura não cria fragmento: a memória do quadro continua a da primeira leitura.

## 8. EventBus

Nenhum tipo novo. Os eventos são:

- `quest_progressed(those_hours, mark | panel)`;
- com as duas evidências, `quest_completed(those_hours)` e `quest_started(the_reinforcement)`.

Reexaminar não emite nada (`observation_discovered` suprimido). A reação de Durn só emite os eventos de diálogo. O Load emite só `game_loaded`.

## 9. Fora do bloco

- Painel aberto, quebrado ou com interior revelado (H1).
- Galpão (C27).
- Elyra (C28).
- Combate e criaturas (H6).
- "Véu" e lore profundo.
- Ostrell.
- Refactor da janela 660×300.
- Marcador visual de "algo novo": nenhum. O objetivo e a própria releitura bastam.

## 10. Arquivos

**Criados:**
- `godot/scripts/vardhelm/vardhelm_rereads_investigation.gd`
- `godot/data/quests/vardhelm_the_reinforcement.json`
- `godot/data/dialogue/vardhelm_the_mark.json`
- `godot/tests/save_v2/test_c26_rereads_pattern.gd` (46 checks)
- `godot/tests/save_v2/c26_rereads_playtest.gd` (13 checks)

**Modificados:**
- `vardhelm_vertical_slice.gd`: releitura, progresso, objetivo, Durn, apresentação.
- `vardhelm_runtime_state_provider.gd`, `id_catalog.gd` (1 quest e 1 diálogo canônicos), `pt-BR.json` (5 chaves).
- `data/quests/vardhelm_those_hours.json`: objetivos `mark` e `panel`.
- `data/vardhelm/ambient_life.json`: âncora do quadro (§6).
- `state_test_runner.gd`.
- Testes atualizados por evolução: `test_c25_the_hours.gd` (objetivos de "Nesses horários"; painel relido depois da comparação) e `test_c17_forge_bay.gd` (âncora do quadro).

## 11. Testes

- `test_c26_rereads_pattern.gd`: **46/46** (runner: 1842/1842). `c26_rereads_playtest.gd`: **13/13** renderizado e headless.
- Regressões (renderizado e headless): C11 52/52, C15 17/17, C16 16/16, C17.3 11/11, C18 17/17, C21 25/25, C21.1 24/24, C23 16/16, C25 14/14; C9 66/66; cena principal com 0 erros; legados iguais ao baseline; `tsc` limpo.
- Detalhes no [`PROJECT_CHANGELOG.md`](../../PROJECT_CHANGELOG.md) (entrada C26).

## 12. Limitações

- O canto de onde se examina o quadro com Durn no lugar é estreito (~0,6 × 0,6 m de candidato garantido). É alcançável andando (playtest), mas merece atenção no teste humano.
- A releitura não tem marca visual própria; depende de o jogador voltar aos objetos guiado pelo objetivo.
- "Raspado? Não fui eu." é a única reação nova de Durn e não varia com a ordem das evidências.

## 13. Checklist humano (não executado)

| # | Pergunta |
|---|---|
| A | Ao rever o quadro, você percebeu que algo que já tinha visto ganhou novo significado? |
| B | A marca apagada parece pista ou explicação pronta? |
| C | A ligação com os horários parece natural? |
| D | O horário 17h41 chama atenção por não encaixar? |
| E | Você entende por que procurar registros depois? |
| F | O painel continua misterioso? |
| G | Durn deixou de parecer o personagem que entrega todas as respostas? |
| H | A investigação parece estar avançando sem marcador artificial demais? |

**Roteiro sugerido:**
1. Jogar até a comparação na rua (C25).
2. Voltar à Forja.
3. Examinar o quadro (pelo canto leste da máquina) e o painel, nas duas ordens.
4. Falar com Durn.
5. Salvar e carregar antes e depois.
