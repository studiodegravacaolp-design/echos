# VARDHELM — Cânone do Ato 1

**Referência canônica do Ato 1 de ECHOES OF THE SOUL.**
- **Criado em:** C22.1 (2026-10-01), a partir das decisões humanas sobre a auditoria do C22 ([`BLOCK_C22_VARDHELM_WORLD_MAP.md`](../architecture/BLOCK_C22_VARDHELM_WORLD_MAP.md)).
- **Ritmo das revelações:** [`LORE_REVELATION_MATRIX.md`](LORE_REVELATION_MATRIX.md).
- **Mapa e fluxo da região:** [`docs/scenarios/vardhelm_world_map.md`](../scenarios/vardhelm_world_map.md).

> **Como ler este documento**
> - Cada afirmação traz a **origem**:
>   - **[DH]** decisão humana do C22.1;
>   - **[HIST+DH]** material histórico recuperado, confirmado por decisão humana;
>   - **[DOC]** documento já existente no repositório;
>   - **[IMPL]** já implementado e validado no jogo.
> - **NÃO DEFINIDO** marca o que ainda não foi decidido. Lacuna não se preenche: vira decisão aberta (§14).
> - Este documento consolida decisões. Ele **não** cria acontecimentos, diálogos, quests, locais ou personagens novos.

---

## 1. Papel de Vardhelm

- Vardhelm é a região do **Ato 1**: uma cidade industrial de fundições, chaminés, fuligem e carvão.
  - [DOC] `SYS-BALANCEAMENTO-ATOS` §2, `ENG-PROGRESSAO-NIVEIS`, `ART-PROMPTS-TIER1` §1.1.
  - [DH] decisão do C17: "Vardhelm é uma cidade industrial".
- **Princípio de Vardhelm [DH]:**

> **Vardhelm não é um corredor até o próximo ato.**
> É uma cidade que existia antes da chegada do jogador e continuará existindo depois dele. O Primeiro Eco acontece dentro de uma sociedade que trabalha, produz, circula, comercializa e tem problemas próprios. O mistério invade essa normalidade **aos poucos**.

- **Curva do ato [DH]:** NORMALIDADE → RUPTURA → DÚVIDA → INVESTIGAÇÃO → CONFLITO → DESCOBERTA PARCIAL → CLÍMAX → CONSEQUÊNCIA → TRANSIÇÃO.
- **Escala [DH]:**
  - Vardhelm não deve ser gigantesca só por escala;
  - uma área só entra se tiver função (narrativa, mecânica, exploratória, atmosférica, de circulação ou de worldbuilding);
  - outros distritos **não** devem ser inventados para aumentar a cidade.

## 2. Estado inicial

O que já existe no jogo [IMPL]:
- **Forja 01:** baia de uma fundição de Vardhelm, com trabalho em andamento, trabalhadores e máquinas.
- **Durn:** o primeiro NPC.
- **O pátio do Distrito das Fundições**, sob a Forja 01, ligado pela talha.

**Locais com sustentação:**

| Local | Sustentação |
|---|---|
| Distrito das Fundições | [DOC] TIER1 §1.4.1 e TIER3 §2.3.3 |
| Forja 01 | [IMPL] |
| Pátio | [IMPL]; decisão de produção do C21 |
| Galpão de Manufatura | [DOC] TIER1 §1.4.2 (direção de arte) |
| **Rua do Distrito das Fundições** | [DH] extensão espacial coerente proposta pelo desenvolvimento |

Qualquer outro distrito: **NÃO DEFINIDO**.

## 3. Primeiro Eco

- **Função narrativa [DH]:** é o **evento incitante do Ato 1**. Ele **cria a pergunta**, não entrega a resposta.

| O Primeiro Eco deve | O Primeiro Eco não deve |
|---|---|
| 1. quebrar a normalidade | 1. explicar a própria origem |
| 2. criar uma experiência inexplicável | 2. revelar a cosmologia |
| 3. produzir consequência | 3. identificar Aethel |
| 4. provocar reação ambiental | 4. identificar Asterion |
| 5. gerar dúvida | 5. explicar o Homem Cinzento |
| 6. levar à investigação | 6. resolver o mistério |

- **Princípio [DH]:** *o jogador percebe primeiro, interpreta depois e compreende muito mais tarde.*
- **Já implementado [IMPL]** (C12–C16; os 6 "deve" acima estão cobertos):
  - memória e consequência;
  - Vardhelm reage (luz fria, trabalhador fora da rotina, máquinas mais baixas);
  - a escolha "Não senti nada." muda Durn de lugar e deixa a folha;
  - Durn aponta o painel selado;
  - silêncio e gancho: "...Você ouviu, não ouviu?" / "Então não fui só eu.".

## 4. Durn

**Função [IMPL + DH]:**
- primeiro vínculo humano e local do protagonista com o fenômeno;
- personagem da Forja;
- testemunha indireta do Primeiro Eco;
- primeiro sinal de que a experiência **talvez não tenha sido só subjetiva**.

**Não transformar automaticamente em [DH]:** companheiro permanente, grande sábio, expositor de lore, membro da jornada ou especialista no Véu.

**Futuro além da Forja:** **NÃO DEFINIDO**. Isso inclui se ele reaparece, se acompanha o jogador e se tem relação com a saída de Vardhelm.

## 5. Investigação

**[DH]** Depois do Primeiro Eco e de "Então não fui só eu.":
- o arco **deixa de ficar restrito à Forja**;
- começa uma **investigação dentro de Vardhelm**.

**O protagonista ainda não entende [DH]:**
- o que é exatamente o fenômeno;
- a origem;
- a relação cosmológica;
- por que ele o percebeu;
- o significado completo do Eco.

**Cadeia [DH]:**
1. vida normal / Forja;
2. Primeiro Eco;
3. consequência;
4. Durn confirma que algo aconteceu;
5. investigação em Vardhelm;
6. novos indícios;
7. conflito;
8. desenvolvimento do Ato 1;
9. clímax de Vardhelm;
10. transição para o Ato 2.

**O que pode aparecer em Vardhelm [DH]:**
- Ecos, memória, fragmentos, sinais de anormalidade e indícios ligados ao Véu;
- o conhecimento permanece **fragmentário**;
- a palavra **"Véu"** só é usada quando o personagem que a diz tem razão narrativa para conhecer o conceito. Conhecimento de documento de lore **não** é conhecimento automático dos personagens.

**NÃO DEFINIDO:** quais indícios, onde aparecem, em que ordem, que padrão formam e quem investiga junto.

**C24 — design proposto (não é cânone):** a especificação está em [`VARDHELM_INVESTIGATION_DESIGN.md`](../03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md).
- A investigação nasce de elementos já no jogo: horários (folha de Durn, quadro de manutenção, turnos), o painel **reforçado** e a Forja 01 mais baixa que as outras fundições.
- Escalada proposta: incidente → anomalia → registro → padrão → origem do selo (Galpão) → cruzamento com Elyra → implicação maior → conflito.
- Tudo isso é **[C] proposta** ou **[D] decisão humana pendente** (H1–H9 em [`BLOCK_C24_VARDHELM_INVESTIGATION.md`](../architecture/BLOCK_C24_VARDHELM_INVESTIGATION.md) §5). Só vira cânone por decisão humana.

**Decisões humanas depois do C24 (C24.1) [DH]:**
- **H1:** o painel permanece fechado durante a investigação; abertura ou ruptura reservada ao clímax de Vardhelm; o que ele revelar será material e concreto, sem explicar a cosmologia.
- **H2:** Durn permanece na Forja, pode reagir quando o protagonista volta e deixa aos poucos de ser o motor da investigação; não é companheiro nem expositor. Participação no clímax: possível, NÃO DEFINIDA.
- **H3:** o Galpão de Manufatura tem relação com o histórico operacional do reforço/selamento do painel e fornece documentação ou rastro operacional que faz a investigação avançar.
- **H4:** Elyra investiga o que existia na área antes das fundições ("o que existia aqui antes?"), enquanto o protagonista investiga "o que aconteceu aqui agora?"; as investigações convergem sobre evidências ou registros relacionados.
- **H5:** o termo "Véu" **não** será introduzido ainda (nem Durn, nem o protagonista, nem o primeiro encontro com Elyra).
- **H6:** natureza exata do conflito NÃO DEFINIDA; a hipótese combinada é candidata, não cânone.
- **H7 (conceito):** "Isso já aconteceu antes. Alguém reconheceu o perigo, algo foi selado, e parte dos registros desapareceu." NÃO define quem, por quê, o que foi selado nem a natureza cosmológica.
- **H8:** progressão narrativa, não relógio, dispara os eventos importantes do painel; nenhum evento crítico depende de tempo real decorrido.
- **H9:** a ponte "arqueóloga élfica" ↔ "Última Arconte Rúnica" fica deliberadamente reservada.

O restante da especificação do C24 continua **proposta**.

**Os horários [DH, C26]:** cânone atual de Vardhelm, aprovado depois do C25 ([`BLOCK_C25_THE_HOURS.md`](../architecture/BLOCK_C25_THE_HOURS.md)).
- Durn anotou hoje **5h58, 13h58 e 17h41**; **17h41** é o momento do Primeiro Eco.
- O quadro de turnos marca as trocas às **6h, 14h e 22h**.
- 5h58 e 13h58 caem pouco antes das trocas de 6h e de 14h; 17h41 **não** tem essa relação. É um padrão parcial, não uma resposta.
- Só se revisam se um sistema de tempo exigir isso concretamente no futuro.
- **Continuam NÃO DEFINIDOS:** o que o fenômeno é, por que acontece perto da troca de turno e por que 17h41 foi diferente.

**C26 (implementado; leitura de produção, não cânone novo):** depois da comparação, o quadro de manutenção mostra uma linha **raspada** que termina em "...58", e o painel mostra parafusos de reforço **mais novos que a placa**. É evidência, não fato estabelecido: **não** se afirma quem raspou, quem reforçou, quando nem por quê ([`BLOCK_C26_REREADS_PATTERN.md`](../architecture/BLOCK_C26_REREADS_PATTERN.md)).

## 6. Elyra

**Presença no Ato 1 [HIST+DH]:**
- Elyra **participa do Ato 1**.
- Origem da decisão: material histórico do projeto, que não estava formalizado no repositório, mais a decisão humana atual. A partir do C22.1 faz parte da direção canônica.

**Quem é, para o Ato 1 [HIST+DH]:**
- **arqueóloga élfica**;
- ligada à preservação da memória, à busca da verdade, ao conhecimento histórico e à investigação de vestígios do passado.

**Função no Ato 1 [DH]:**
- a entrada dela se liga naturalmente à investigação aberta pelo Primeiro Eco;
- ela tem **conhecimento incompleto**;
- pode:
  - reconhecer que há algo anormal;
  - identificar padrões;
  - perceber que o fenômeno tem profundidade histórica;
  - ajudar a transformar o mistério em investigação;
- **não** entra como NPC que explica o universo.

**Elyra não explica no Ato 1 [DH]:** Aethel, a verdadeira natureza de AETHERIS, o Homem Cinzento, a história completa de Asterion ou a cosmologia completa do Véu.

**Linhagem [DOC + DH]:**
- `SYS-ATO4-FENDA` reserva a revelação das Linhagens Ocultas (Herdeiro, Kael e Elyra) para o **Ato 4**. A presença no Ato 1 **não muda isso**.
- **Não revelar no Ato 1:** a linhagem oculta, a importância final dela, nem nada que antecipe explicitamente a revelação do Ato 4.
- A apresentação dela precisa funcionar para um jogador que **não sabe** que ela será importante no futuro.

**Já documentado para o fim do jogo [DOC]:** `EVT-ESCOLHA-FINAL-001` a chama de "Última Arconte Rúnica", defensora da memória, Rota B (Estase Rúnica). "Arqueóloga élfica" (Ato 1) e "Última Arconte Rúnica" (fim do jogo) **devem ser conciliadas** no design futuro. Não há contradição declarada, mas a ponte entre as duas não está definida.

**NÃO DEFINIDO:** local e momento da primeira aparição, diálogo, quest, como ela chegou a Vardhelm, relação pessoal com o protagonista, se acompanha o jogador e o papel dela no clímax e na saída.

## 7. Combate

**[DH]** O Ato 1 **terá combate**. [DOC] Os documentos de sistema já preveem combate e monstros no Ato 1 (`SYS-GRIMORIO-EARLYGAME`, `ENG-MATEMATICA-COMBATE`: "monstro padrão de Vardhelm").

**Regra [DH]:**
- o combate entra quando tiver **função narrativa e espacial** dentro do arco (Fase 7: conflito);
- **nada de inimigos aleatórios** só para cumprir o documento.

**NÃO DEFINIDO:** inimigos, onde e quando, sistema no Godot.

## 8. Progressão

- **[DOC]** Ato 1 = **níveis 1–10**. `EVT_TRANSICAO_ATO1_ATO2` no nível 10 (`ENG-PROGRESSAO-NIVEIS` §3.1).
- **[DH]** O nível 10 **não** é, por ora, a condição canônica rígida de saída de Vardhelm. "Níveis 1–10" fica como referência do design de progressão existente.
- A condição narrativa real de encerramento é definida com o arco.
- A relação entre progressão mecânica e narrativa é **decisão futura**.
- O runtime Godot ainda não tem níveis [IMPL].

## 9. Hierarquia de revelações

Matriz completa em [`LORE_REVELATION_MATRIX.md`](LORE_REVELATION_MATRIX.md).

**No Ato 1 pode-se conhecer:**
- o fenômeno e o Eco;
- memória fragmentária;
- anormalidades;
- a existência de perguntas maiores.

**Fica para depois:**
- Véu como conceito compreendido (camada 2, salvo justificativa do personagem);
- Aethel, a natureza de AETHERIS, a verdade de Asterion, o Homem Cinzento, o Último Experimento e a cosmologia completa (camada 3).

## 10. Estrutura macro do ato [DH]

| Fase | Conteúdo | Estado |
|---|---|---|
| 1 — Normalidade | Forja 01, trabalho, Durn, ambiente industrial | 🟢 implementado |
| 2 — Ruptura | Primeiro Eco | 🟢 implementado |
| 3 — Consequência imediata | a Forja reage, Durn reage, a escolha produz consequência | 🟢 implementado |
| 4 — Abertura do mundo | pátio 🟢; **rua do Distrito das Fundições** (C23, candidato); Vardhelm começa a se mostrar como cidade | 🟡 parcial |
| 5 — Investigação | vestígios e fenômenos começam a formar um padrão | ⚪ conteúdo NÃO DEFINIDO |
| 6 — Elyra | os caminhos do protagonista e de Elyra se cruzam por uma razão ligada à investigação | ⚪ ponto exato NÃO DEFINIDO |
| 7 — Conflito | o arco deixa de ser investigação passiva; o combate ganha justificativa | ⚪ NÃO DEFINIDO |
| 8 — Descoberta parcial | o protagonista aprende algo verdadeiro, mas incompleto | ⚪ NÃO DEFINIDO |
| 9 — Clímax de Vardhelm | evento | ⚪ NÃO DEFINIDO |
| 10 — Consequência e saída | encerramento do Ato 1; transição futura para Ostrell | ⚪ NÃO DEFINIDO |

**Papel do C23 [DH]:**
- A rua do Distrito das Fundições é a **transição entre o microcosmo da Forja e Vardhelm como cidade**: escala, atividade industrial, trabalhadores, circulação, consequências sociais e ambientais, um mundo além da Forja.
- Ela prepara a investigação (Fase 5).
- **Não é "mais uma área do mapa"**, e não foi implementada no C22.1.

## 11. Condição de conclusão (pendente)

- **[DH]** Vardhelm precisa ter clímax próprio, conclusão narrativa do Ato 1 e transição coerente para a próxima região.
- **NÃO DEFINIDO:**
  - o evento de clímax;
  - a condição de encerramento (não é o nível 10 de forma rígida, ver §8);
  - a forma da saída (estrada, trem, carroça, portão, navio, viagem automática ou outra).

## 12. Conexão com Ostrell

- **[DOC]** Ato 2 = **Ostrell** (`SYS-BALANCEAMENTO-ATOS` §3).
- **[DOC] Evidência preservada:** "as rotas comerciais de Vardhelm para Ostrell são mais longas e perigosas" (§3.5).
- **[DH]** A forma concreta da viagem será definida depois que o arco de Vardhelm estiver estruturado. **Ostrell não deve ser iniciado.**
- **[DH]** **Kael** (Draconiano) fica reservado para o **Ato 2**. Não entra em Vardhelm sem decisão humana explícita.
  - [DOC] No fim do jogo ele é o "Ferreiro de Aço", Rota A (Era do Aço), com Linhagem revelada no Ato 4.

## 13. Elementos proibidos de revelar em Vardhelm

| Não revelar | Regra |
|---|---|
| Aethel como consciência primordial; "AETHERIS é Aethel" | fica fora da compreensão direta do protagonista no Ato 1 |
| Verdade completa de Asterion | [DH] Asterion **não é um deus**: foi a primeira civilização que tentou entender o que existia por trás do Véu. "Tecnologia asteriana" é termo válido. Se surgir um vestígio, o jogador o encontra **antes** de entender a origem. **Não entra automaticamente no C23** |
| Homem Cinzento (História Perdida; selo vivo ligado ao Último Experimento) | camada profunda. No máximo preparação **extremamente indireta**, e só se um bloco narrativo justificar |
| Último Experimento; cosmologia completa do Véu | camada 3 |
| Linhagem oculta de Elyra (e do Herdeiro e de Kael); a importância final dela | reservado ao Ato 4 |
| Kael | Ato 2 |
| Origem dos Lurídeos, Édor, Árvore-Biblioteca | fora do escopo de Vardhelm (ver a matriz) |

## 14. Decisões abertas

| # | Decisão | Origem |
|---|---|---|
| 1 | Etapas intermediárias da investigação: indícios, ordem, padrão | D1 (parcial) |
| 2 | Primeira aparição de Elyra: local, momento, motivo, diálogo, quest, relação pessoal | D2 (parcial) |
| 3 | Ponte entre "arqueóloga élfica" (Ato 1) e "Última Arconte Rúnica" (fim do jogo) | conciliação |
| 4 | Conflito e combate do Ato 1: inimigos, onde, quando, sistema Godot | D3 (parcial) |
| 5 | Relação entre progressão mecânica (níveis 1–10) e narrativa | D3/D4 |
| 6 | Clímax de Vardhelm | — |
| 7 | Condição de encerramento e forma da saída | D4 (parcial) |
| 8 | Futuro de Durn além da Forja | — |
| 9 | Galpão de Manufatura: função e posição | D5 |
| 10 | Brenhold: Ato 2 ou 3 (**adiado**, não bloqueia Vardhelm) | D6 |
| 11 | Interpretação das Fadas sobre a verdade (não consolidada) | — |

**C24 / C24.1:** itens decididos ou reduzidos pelas decisões H1–H9 (§5): painel no clímax (#6, parcial), Durn (#8, parcial), Galpão (#9, função; posição aberta), motivo de Elyra (#2, parcial: momento e local abertos), "Véu" fora por enquanto. Continuam abertos: conflito (#4, H6), conteúdo do clímax (#6), quem/por quê/o quê da verdade parcial (H7). #3 (Arconte) fica **reservado** (H9).
