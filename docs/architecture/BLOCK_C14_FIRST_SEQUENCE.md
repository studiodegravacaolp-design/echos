# ECHOES OF THE SOUL — C14: primeira sequência narrativa completa (Vardhelm)

> **Status:** testes automatizados concluídos. **O C14 só estará concluído depois do teste humano**
> (seção 5), que ainda não foi feito.
> **Relacionados:** [C12](BLOCK_C12_POST_ECHO_BRIDGE.md) · [C13](BLOCK_C13_LIVING_VARDHELM.md)

## 1. A sequência antes do C14 (como o jogador a vivia)

| # | Etapa | O que o jogador vê |
|---|---|---|
| 1 | Entrada | setor industrial em penumbra, trabalhadores em rotina, zumbido/vapor/máquinas; esfera ciano ao fundo |
| 2 | Primeiro objetivo | "Fale com Durn para descobrir o que está acontecendo."; status com os controles |
| 3 | Exploração | quadro, painel selado e ferramentas examináveis (texto "de antes") |
| 4 | Encontro com Durn | nome "DURN" sobre ele; dica "E • Falar com Durn" |
| 5 | Diálogo inicial | "...Você também sentiu isso?" |
| 6 | Escolha | "Sentir o quê?" / "Não senti nada." (as duas terminam em "Se acontecer de novo... procure por mim.") |
| 7 | Início da quest | objetivo "Investigue o fenômeno no setor industrial." ⚠ durante a conversa, o status mostrava o ID técnico "Memória registrada: vardhelm_heard_echo" |
| 8 | Descoberta | a esfera ciano (dica "E • Observar o Eco") |
| 9 | Exame | painel "ECO DE MEMÓRIA"; a esfera some; marca no chão |
| 10 | Consequência | flag + estado de ambiente `echo_awakened` |
| 11 | Memória | memória registrada; objetivo "✓ Primeiro Eco — concluído" + banner |
| 12 | Reação ambiental (C13) | luz fria falhando sobre o painel; trabalhador parado perto dele; máquinas mais baixas |
| 13 | Retorno a Durn | por iniciativa do jogador ("procure por mim") |
| 14 | Diálogo pós-Eco (C12) | "...Você voltou." → pista do painel selado |
| 15 | Investigação | objetivo "Procure o painel selado no fundo do setor." |
| 16 | Conclusão | "…vibração do outro lado."; objetivo "✓ O painel selado — ainda fechado." |
| 17 | Estado final | **nada acontecia.** Durn repetia "...O painel selado… / Se for olhar... vá com calma." como se o jogador ainda não tivesse ido |

## 2. O que o C14 mudou (pouco, e só no fim)

| Etapa | Mudança | Por quê |
|---|---|---|
| 7 | o status não mostra mais o ID técnico da consequência | ruído técnico no meio da primeira conversa |
| 16 → encerramento | ao concluir o exame do painel, Vardhelm fica **em silêncio** por alguns segundos (zumbido, vapor e máquinas quase somem) e a **luz fria sobre o painel se apaga**; depois tudo volta ao estado pós-Eco | um fim perceptível, discreto, sem texto: "você chegou a algum lugar" — e o painel respondeu com silêncio |
| 17 → gancho | Durn, uma vez: "...Você ouviu, não ouviu?" / "Então não fui só eu." / "..." — depois, só "..." | fecha o arco que abriu com "...Você também sentiu isso?"; deixa as perguntas: *o que há atrás do painel?* *por que Durn ouviu aquilo antes?* Sem escolha, sem explicação |

Todo o resto ficou como estava: a conversa inicial, a do C12, as reações do C13, o banner, o status e o painel fechado.

**Ritmo:** entre as etapas não há empurrão. O objetivo só muda quando algo acontece, e o jogador volta a
Durn por conta própria ("procure por mim"). O espaço entre o Eco e Durn é exploração livre, e as três
observações têm um texto próprio para depois do Eco.

**Estado:** nada novo é salvo. O fim da sequência é representado pelo que já existe:

- quest `vardhelm_sealed_panel` concluída = painel examinado;
- diálogo `vardhelm_after_panel` concluído (DialogueRuntimeState) = fala final já dita.

O silêncio é transitório. Um Load no meio dele o interrompe, e nenhum Load o toca de novo.

## 3. Sistemas reutilizados

DialogueController, DialogueRuntimeState, QuestController/QuestState, LocalizationService,
EnvironmentalObservation, VardhelmAmbientLife (as luzes e o áudio do C13), GameIdCatalog,
VardhelmRuntimeStateProvider e Save/Load V2 com o resync existente.

## 4. Save/Load

| Caso | Resultado esperado |
|---|---|
| A. Save antes do Eco → Eco → Load | volta ao antes do Eco |
| B. Save depois do Eco → Durn → Load | antes da conversa pós-Eco; Durn reage de novo |
| C. Save durante a investigação → Load | investigação ativa (e o silêncio, se estiver tocando, para) |
| D. Save depois do painel → Load | painel concluído; a fala final acontece se ainda não foi dita |
| E. Load repetido | mesmo estado; nada é reemitido |

## 5. Teste humano (jogar como jogador)

Não é para procurar bugs nem marcar PASS/FAIL. Jogue do começo ao fim, no seu ritmo.

1. Abra o jogo (F5) e entre em Vardhelm.
2. Explore um pouco antes de fazer qualquer coisa.
3. Fale com Durn.
4. Encontre o Eco.
5. Continue andando e observe Vardhelm.
6. Volte a Durn quando tiver vontade.
7. Investigue o painel selado.
8. Fique mais alguns segundos depois de examinar o painel. Depois, fale com Durn mais uma vez.
9. Conte como foi, em poucas palavras:
   - **Ritmo:** algum trecho pareceu apressado ou arrastado?
   - **Clareza:** em algum momento você não soube o que fazer?
   - **Curiosidade:** o que você ficou querendo saber?
   - **Atmosfera:** o que chamou sua atenção no ambiente?
   - **Continuidade:** as etapas pareceram ligadas umas às outras?
   - **Encerramento:** pareceu que a sequência terminou?
   - **Vontade de continuar:** você jogaria a próxima parte?

## 6. C14.1 — correção do momento de silêncio (áudio)

**Status:** correção aplicada e testes automatizados verdes. **Aguarda o teste humano de áudio** (abaixo).

**Auditoria.** O jogo tem só 3 fontes de som, todas em `VardhelmAudio` (`vardhelm_audio.tscn`), num único
bus (Master). Não há AudioStreamPlayer3D, música nem outros buses. Nenhuma instância extra toca durante
o silêncio: os sandboxes do Load são descartados, e só as 3 do jogo existem. Níveis medidos nos arquivos:

| Fonte | Clipe | Nível no arquivo | Jogo normal | No silêncio (antes: −42 dB) | No silêncio (C14.1: −60 dB) |
|---|---|---|---|---|---|
| **Zumbido** (`VardhelmHum`) | 8 s, reiniciado em loop | −16 dBFS contínuo | ≈ −22 dBFS | **≈ −58 dBFS, contínuo** | ≈ −76 dBFS |
| Vapor (`VardhelmSteam`) | 2,4 s, sopros | −36 dBFS | ≈ −52 | ≈ −78 | ≈ −96 |
| Máquinas (`VardhelmMachinery`) | 1,6 s, batidas | −34 dBFS | ≈ −64 (pós-Eco) | ≈ −76 | ≈ −94 |

**Causa:** o zumbido é um drone contínuo e é 30 dB mais alto que os outros dois. Com o piso de −42 dB
ele continuava em ~−58 dBFS, sozinho, e mascarava a quebra. Os outros dois já ficavam inaudíveis.

**Correção:** o piso do silêncio (`closing_silence.silent_db` em `ambient_life.json`) passou de −42 para
**−60 dB**. O zumbido fica num resquício quase inaudível (~−76 dBFS), sem silêncio absoluto, e o vapor e
as máquinas somem. Nada mais mudou: duração (1,4 s para abafar, 4 s suspenso, 3 s para voltar),
retorno gradual ao volume de repouso, código, estado e Save/Load.

### Teste humano — só áudio

F5 → siga a sequência normalmente → examine o painel selado e fique parado prestando atenção ao som.

- Você percebe claramente que o ambiente ficou abafado?
- O som repetitivo de antes ainda mascara o momento?
- O ambiente parece ter prendido a respiração por alguns segundos?
- O som volta de forma natural?

### C14.2 — ajuste fino

O teste humano do C14.1 mostrou que o zumbido ainda era claramente audível a −60 dB. O piso passou para
**−70 dB**: o zumbido fica em ~−86 dBFS no núcleo do silêncio, e o vapor e as máquinas ficam bem abaixo
disso. Mais nada mudou. Teste humano de áudio pendente, com as mesmas perguntas: o zumbido ainda é
claramente perceptível? O ambiente parece abafado? O efeito parece natural? O retorno continua suave?
