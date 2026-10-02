# Bloco C24 — Design da investigação de Vardhelm (do Primeiro Eco ao encontro com Elyra)

**Data:** 2026-10-01
**Tipo:** design narrativo; **somente documentação**
**Gameplay alterado:** nenhum (.gd, .tscn, dados, localização, quests, NPCs intocados)
**Especificação:** [`docs/03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md`](../03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md)

## 1. Objetivo

Desenhar a **Fase 5 (investigação)** do Ato 1, que substitui o "???" depois de "RUA / VARDHELM SE ABRE". O design chega até o encontro com Elyra e o caminho para o conflito, e serve de base para os próximos blocos de produção.

## 2. Local do documento de design

O pedido indicava `docs/narrative/`, que não existe. O repositório já usa [`docs/03_narrativa/`](../03_narrativa/) para narrativa (ex.: `EVT-ESCOLHA-FINAL-001.md`). Por isso a especificação foi criada lá, para não duplicar uma pasta com a mesma função.

## 3. Método

1. Levantamento de **todo texto e reação já no jogo** (diálogos de Durn, observações da Forja, do pátio e da rua, memórias, quests, reações do C13–C16), feito a partir de `pt-BR.json` e `ambient_life.json`.
2. A investigação foi construída **reaproveitando essas consequências**: horários, registros, painel reforçado e a Forja 01 diferente das outras. Nenhum fenômeno novo foi necessário para o gancho.
3. Cada decisão recebeu uma classe: **A** canônica, **B** derivada, **C** proposta, **D** decisão humana, **E** reservada. Nenhuma proposta C foi registrada como cânone.

## 4. Resultado em uma página

| Tema | Decisão | Classe |
|---|---|---|
| Mistério local | Por que só a Forja 01 mudou, o que o painel guarda e por que foi selado | B |
| Mistério global | O que são o Eco e o Véu; Aethel, Asterion etc. **Não é respondido** | E |
| Motivação | "O que eu senti?" vira "o que este lugar esconde?" | A+C |
| Gatilho | O gancho de Durn + a Forja 01 mais baixa que as outras fundições (já no jogo) | A |
| Primeira pista | Os **horários**: relato de Durn (caminho A) ou folha (caminho B) | C |
| Padrão | Comparar registros que já existem (folha, quadro de manutenção, turnos) + evento opcional do painel | C |
| Galpão de Manufatura | Onde o painel foi reforçado: ordens de serviço | C (D3) |
| Painel | Fechado durante a investigação; aberto ou rompido no clímax; o foco é **o selo** | D (recomendação C) |
| Durn | Testemunha e contexto local; não explica | A+D |
| Elyra | Motivo próprio (E-1/E-2/E-3); encontro no **mesmo registro** | A+C+D |
| Véu | Ninguém da Forja usa a palavra; se aparecer, quem a usa é Elyra, como termo antigo, sem definir | C/D |
| Conflito | K-4 (combinação): reação humana ao segredo + perigo físico ligado ao lugar | D |
| Verdade parcial | "Já aconteceu antes; foi selado; o registro foi apagado" | C/D |

Os detalhes e as 14 perguntas respondidas estão na especificação (§§0–17).

## 5. Decisões humanas pendentes

| # | Decisão | Opções (especificação) | Recomendação |
|---|---|---|---|
| H1 | Destino do painel | A / B / C / D (§6) | A+C, conteúdo D |
| H2 | Futuro de Durn | D-1 / D-2 / D-3 (§8) | D-1 + toque de D-2 |
| H3 | Galpão como lugar do selo (D5/D3) | sim / outra função (§5) | sim |
| H4 | Motivo de Elyra | E-1 / E-2 / E-3 (§9) | E-2 (registros) ou E-1 (vestígios); escolha humana |
| H5 | A palavra "Véu" no Ato 1 | não aparece / só Elyra, sem definir (§10) | só Elyra, sem definir |
| H6 | Natureza do conflito | K-1 / K-2 / K-3 / K-4 (§11) | K-4 |
| H7 | Verdade parcial | proposta principal / alternativas (§12) | proposta principal |
| H8 | Evento opcional do painel "no horário" | por progresso (sem relógio) / relógio do jogo | por progresso (o slice não tem relógio diegético) |
| H9 | Ponte "arqueóloga élfica" ↔ "Última Arconte Rúnica" | já pendente (C22.1 §14 #3) | não bloqueia o C24 |

### 5.1 Decisões tomadas depois do C24 (C24.1)

| # | Estado | Decisão |
|---|---|---|
| H1 | **decidido** | painel fechado durante a investigação; abertura ou ruptura no clímax; revelação material e concreta, sem cosmologia |
| H2 | **decidido** | Durn fica na Forja, reage quando o protagonista volta, deixa aos poucos de ser o motor; não é companheiro nem expositor; clímax possível, **não definido** |
| H3 | **decidido** | o Galpão guarda o histórico operacional do reforço/selamento do painel e fornece o rastro que faz a investigação avançar |
| H4 | **decidido** | Elyra investiga o que existia na área antes das fundições; as investigações convergem sobre evidências ou registros relacionados |
| H5 | **decidido** | "Véu" **não** é introduzido ainda (nem Durn, nem o protagonista, nem o primeiro encontro com Elyra) |
| H6 | **aberto** | natureza do conflito NÃO DEFINIDA; K-4 é candidata, não cânone |
| H7 | **aprovado como conceito** | "Isso já aconteceu antes. Alguém reconheceu o perigo, algo foi selado, e parte dos registros desapareceu." Quem, por quê e o quê: abertos |
| H8 | **decidido** | progressão narrativa, **não relógio**, dispara os eventos importantes do painel |
| H9 | **reservado** | ponte "arqueóloga élfica" ↔ "Última Arconte Rúnica" não se resolve agora |

**Estado do C24:** design documentado; decisões humanas em consolidação (H6 aberto; H7 com detalhes abertos; H9 reservado). Os blocos abaixo continuam **não implementados**, salvo o C25 (implementado depois: [`BLOCK_C25_THE_HOURS.md`](BLOCK_C25_THE_HOURS.md)).

## 6. Decomposição em blocos de produção (não implementados)

Os números são indicativos; a ordem depende de H1–H8.

### C25 — Os horários (retorno a Durn)
- **Objetivo:** voltar a Durn depois do gancho e obter a primeira pista concreta.
- **Função narrativa:** passar de "o que eu senti" para "quando aconteceu", e dar consequência real à escolha A/B do C15/C16.
- **Área:** Forja 01 (existente).
- **Sistemas:** diálogo de Durn (novo estado), quest do pipeline existente, consequência C15 como condição, observação da folha (C16) como alternativa; Save V2 pelo caminho atual (flags → GameState).
- **Dependências:** H2 (decidido); C23 fechado em teste humano (recomendado, não obrigatório).
- **Fechamento:** os dois caminhos entregam a mesma pista com tom diferente; Save/Load no meio preserva o estado; testes automáticos + teste humano.

### C26 — Releituras e padrão
- **Objetivo:** observações existentes ganham uma leitura nova depois da pista; o padrão surge da comparação.
- **Função narrativa:** a cidade como instrumento de medida (anomalia → padrão).
- **Área:** Forja (quadro de manutenção), rua (quadro de turnos: **integração futura do C23**).
- **Sistemas:** `EnvironmentalObservation` com texto derivado de flag (mesmo mecanismo do `after_echo`); fragmentos de memória por observação; evento opcional do painel, disparado por progressão (H8).
- **Dependências:** C25; H8.
- **Fechamento:** a ordem das observações é livre; o padrão é reconhecível sem lista de pistas; nenhum estado derivado vai para o save.

### C27 — Galpão de Manufatura (cenário)
- **Objetivo:** construir o Galpão pelo padrão C20 (CONCEITO → … → ACABAMENTO).
- **Função narrativa:** lugar onde o selo foi feito.
- **Área:** nova, com acesso pela rua (posição a definir; TIER1 §1.4.2: volantes, correias, trilhos de ponte rolante, lampiões de querosene).
- **Sistemas:** LevelBuilder, `VardhelmAmbientLife`, controlador do distrito, observações, Save V2.
- **Dependências:** H3; C23 fechado.
- **Fechamento:** checklist do padrão C20 (circulação medida com a cápsula, desempenho, captura) + teste humano.

### C28 — O registro do selo e Elyra
- **Objetivo:** encontrar o registro do reforço do painel e a primeira aparição de Elyra.
- **Função narrativa:** cruzamento das duas investigações; diferença de conhecimento.
- **Área:** Galpão (ou o lugar do registro, conforme H3/H4).
- **Sistemas:** NPC nomeado novo (Elyra), diálogo com escolha (o que contar), quest.
- **Dependências:** C27; H4 e H5 (decididos); H9 reservado (não bloqueia).
- **Fechamento:** Elyra não revela nada da camada 2/3 nem a linhagem; o que o jogador contou muda o diálogo; teste humano.

### C29 — Investigação conjunta → implicação maior
- **Objetivo:** juntar a experiência dele com a leitura dela: "já aconteceu antes; houve silêncio".
- **Função narrativa:** passagem de padrão para implicação.
- **Área:** Forja, Galpão, eventualmente arquivo (a definir).
- **Sistemas:** diálogo, observações, fragmentos de memória.
- **Dependências:** C28; H7.
- **Fechamento:** o mistério local fica parcialmente respondido e o global intacto (auditoria contra a matriz C22.1).

### C30 — Primeiro conflito
- **Objetivo:** a investigação provoca reação; primeiro combate com função narrativa.
- **Função narrativa:** escalada para o conflito.
- **Área:** um lugar da investigação (nunca "inimigos na rua por acaso").
- **Sistemas:** **sistema de combate no Godot: NÃO DEFINIDO** (o combate atual é do CLI TypeScript). Exige bloco técnico próprio antes.
- **Dependências:** H6; decisão do sistema de combate (C22.1 §14 #4).
- **Fechamento:** a definir no próprio bloco.

**Fora do escopo do C24:** Fases 8–10 (descoberta parcial, clímax, saída), refinamento visual + UX, Ostrell.

## 7. Integração futura na rua (C23 não alterado)

C23 continua **tecnicamente aprovado e aguardando fechamento humano/artístico**. As possíveis mudanças na rua (leitura nova do quadro de turnos, ligação da pedra de afiar com a "ferramenta familiar", acesso ao Galpão) estão registradas na especificação, §18, e entram no C26/C27.

## 8. Garantias

- Nenhum arquivo de gameplay alterado. Arquivos deste bloco:
  - criados: `docs/03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md` e este documento;
  - atualizados: `docs/lore/VARDHELM_ACT1_CANON.md`, `docs/scenarios/vardhelm_world_map.md`, `PROJECT_CHANGELOG.md`.
- Sem testes executados: o bloco é só documentação. Nenhum teste humano é alegado.
- Nada revelado da lista proibida.
- Kael, Lurídeos, Édor e Árvore-Biblioteca não aparecem.
- Sem commit, sem push.
