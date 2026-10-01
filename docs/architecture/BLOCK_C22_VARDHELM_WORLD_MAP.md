# Bloco C22 — Mapa de produção e continuidade do contexto de Vardhelm

**Natureza:** auditoria, mapeamento e planejamento.
- Nenhuma área, NPC, quest, diálogo, memória, Eco ou consequência foi criado.
- Nenhum arquivo de gameplay foi alterado.
- Sem commit, sem push.

**Data:** 2026-10-01.
**Estado anterior:** C21 e C21.1 **fechados**, validados por teste humano: o acesso Forja 01 ↔ pátio está confortável.
**Mapa e fluxos:** [`docs/scenarios/vardhelm_world_map.md`](../scenarios/vardhelm_world_map.md).
**C22.1:** as decisões D1–D7 foram tomadas pelo usuário e consolidadas em [`docs/lore/VARDHELM_ACT1_CANON.md`](../lore/VARDHELM_ACT1_CANON.md) e [`docs/lore/LORE_REVELATION_MATRIX.md`](../lore/LORE_REVELATION_MATRIX.md) (§14).

**Classificação usada:**

| Classe | Significado |
|---|---|
| **A** | canônica / confirmada no repositório |
| **B** | evidência histórica (material antigo ou externo, não confirmado como cânone atual) |
| **C** | proposta de produção |
| **D** | contradição |
| **E** | **não definido no material canônico disponível** |

---

## 1. Estado atual de Vardhelm (o que existe e roda)

**Implementado e validado por humano:** a Forja 01 (C12–C19) e o pátio do Distrito das Fundições (C21/C21.1), na mesma cena e no mesmo `scenario.vardhelm`.

### 1.1 Fluxo jogável atual

1. **Entrada:** começo na Forja 01. O objetivo é "Fale com Durn para descobrir o que está acontecendo." A talha para o pátio já está disponível; não depende da história.
2. **Durn — primeira conversa** (`vardhelm_intro`): "...Você também sentiu isso?"
   - **"Sentir o quê?"** → "...Nada. Deve ter sido nada." → consequência `vardhelm_heard_echo`.
   - **"Não senti nada."** → consequência `consequence.vardhelm.felt_nothing` (C15).
   - Nos dois casos, "Se acontecer de novo... procure por mim." A quest `vardhelm_first_echo` começa e o Eco fica disponível ("Investigue o fenômeno no setor industrial.").
3. **Primeiro Eco** (`echo.vardhelm.first`): consequência `first_echo_complete`, memória `memory.vardhelm.first_echo` e quest concluída.
4. **Reação do mundo (C13):** estado `echo_awakened`. A luz fica fria sobre o painel, um trabalhador sai da rotina e as máquinas ficam mais baixas. No pátio, o respiro da Forja 01 solta menos fumaça e a porta da fundição muda de texto (C21).
5. **Consequência da escolha (C15/C16):** com "Não senti nada.", Durn vai sozinho até onde o Eco aconteceu, e no lugar dele fica a folha (`observation.vardhelm.durn_notes`).
6. **Durn de novo (C12):** "...Você voltou." → pista do painel → quest `vardhelm_sealed_panel` ("Procure o painel selado no fundo do setor.").
7. **Painel selado:** quest concluída ("✓ O painel selado — ainda fechado."), seguida do **silêncio** (C14, cerca de 8 s, áudio a −70 dB).
8. **Gancho (C14):** "...Você ouviu, não ouviu?" / "Então não fui só eu." / "...". Depois disso, Durn só responde "...".
9. **Pátio (C21):** exploração livre a qualquer momento, com 3 observações ambientais e vida.

**Onde a experiência termina hoje:**
- Depois do gancho de Durn não há próximo objetivo. O HUD fica em "✓ O painel selado — ainda fechado.".
- O pátio é exploração opcional.
- Não existe saída de Vardhelm, área seguinte nem evento posterior.

### 1.2 Inventário de estado

| Tipo | Itens | Classe de estado |
|---|---|---|
| Quests | `vardhelm_first_echo` ("Primeiro Eco"), `vardhelm_sealed_panel` ("O painel selado") | persistente |
| Diálogos | `vardhelm_intro`, `vardhelm_after_echo`, `vardhelm_after_panel` | persistente (`DialogueRuntimeState`) |
| Consequências | `heard_echo`, `felt_nothing`, `first_echo_complete` | persistente |
| Memórias | `first_echo`, `maintenance_board`, `sealed_panel`, `tool_rack` | persistente |
| Observações | Forja: `maintenance_board`, `sealed_panel`, `tool_rack`, `durn_notes` (condicional). Pátio: `foundry_coal_carts`, `foundry_chain_pulley`, `foundry_forge_door` | persistente |
| Flags | `vardhelm_first_echo_complete`, `observation_<id>_seen`, entre outras do `WorldState` | persistente |
| NPCs | **Durn** (`npc.vardhelm.durn`), o único com fala. Trabalhadores: 7 na Forja e 6 no pátio, sem fala | persistente (Durn) / derivado (rotinas) |
| Estados de ambiente | `echo_awakened`, `durn_alone`, `*_remembered` | **derivados** |
| Área do jogador, névoa, luz, gaiola, desenho do pátio | — | **derivados** da posição |
| Dica "E • …", silêncio do encerramento, passagem pela talha, painéis | — | **transitórios** |
| Caminhos e transições | Forja ↔ pátio pela talha (`TransitionPoint`); o portão sul do pátio e os portões da fundição oeste estão **fechados** (cenário) | — |

## 2. Fontes auditadas

**Onde se buscou:**
- `AETHERIS_MASTER_INDEX.md`, `DOCUMENTACAO/` (DOC-000 a DOC-015, registro de IDs), `docs/01_*` a `docs/05_*`, `doc/art_bible/`;
- `src/` (protótipo TypeScript);
- `godot/data`, `godot/level_data`, `docs/architecture`, `docs/scenarios`;
- `PROJECT_CHANGELOG.md` e histórico git (`b01da03`, `a526cc4` e anteriores; nenhum documento de mundo apagado).

**Termos buscados:** Vardhelm, Ato 1, Forja, Distrito das Fundições, Ostrell, Brenhold, Durn, Elyra, Kael, Eco/Echo, Véu, Linhagem, Herdeiro, `EVT_TRANSICAO`, arqueologia, Aethel, Asterion, Homem Cinzento.

| Fonte | Conteúdo relevante |
|---|---|
| `docs/01_sistemas/SYS-BALANCEAMENTO-ATOS.md` | Ato 1 = Vardhelm (níveis 1–10, economia estável); Ato 2 = Ostrell (+20%; "rotas comerciais de Vardhelm para Ostrell mais longas e perigosas"; "corrupção nas terras altas"); Ato 3 = Diretório de Brenhold (`LOC-BRE-001..003`) |
| `docs/04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md` | segmentos por Ato; `EVT_MARCO_NIVEL_5` (Ato 1); **`EVT_TRANSICAO_ATO1_ATO2` no nível 10, "Transição narrativa para Ostrell"**; `EVT_REVELACAO_LINHAGEM` no nível 36 (Ato 4) |
| `docs/01_sistemas/SYS-GRIMORIO-EARLYGAME.md` | habilidades do Ato 1 (Vardhelm, níveis 1–10); Catalisador de Estafa no Ato 2 |
| `docs/01_sistemas/ENG-MATEMATICA-COMBATE.md` | exemplo: "jogador nível 10 contra um **monstro padrão de Vardhelm** (Ato 1)" |
| `docs/05_arte/ART-PROMPTS-TIER1.md` | Vardhelm industrial (§1.1); **Distrito das Fundições** (§1.4.1, exterior); **Galpão de Manufatura** (§1.4.2, interior); arquitetura de Artífice Anão (§3, sem local); paleta e luz |
| `docs/05_arte/ART-PROMPTS-TIER3.md` §2.3.3 | o mesmo "forge district" de Vardhelm no colapso ontológico (fim de jogo) |
| `docs/01_sistemas/SYS-ATO4-FENDA.md` | Ato 4: Linhagens Ocultas do **Herdeiro (jogador)** e dos **Avatares Kael e Elyra** expostas; "Zona de Eco Reversivo" |
| `docs/03_narrativa/EVT-ESCOLHA-FINAL-001.md` | escolha final: **Kael** ("Ferreiro de Aço", Era do Aço) × **Elyra** ("Última Arconte Rúnica", Estase Rúnica, memória) |
| `docs/04_arquitetura_software/ENG-PERSISTENCIA-CAMPANHA.md`, `src/core/CampaignStateManager.ts` | persistência das rotas finais Kael/Elyra |
| `AETHERIS_MASTER_INDEX.md`, `BLUEPRINT_VISUAL_MESTRE.md` | enquadramento AETHERIS ("profundezas industriais de Brenhold"; "arqueologia de máquinas em Brenhold"); seis raças |
| `src/core/CampaignMapEngine.ts`, `QuestContent.ts` | nós e quests de Brenhold do protótipo CLI ("Ato 2: profundezas de Brenhold") |
| `DOCUMENTACAO/DOC-001` (World), `DOC-005` (Narrative), `DOC-006` (Characters), `DOC-009/010` | **só estrutura vazia** |
| `docs/architecture/BLOCK_C12…C21`, `docs/scenarios/vardhelm_foundry_district.md` | o slice implementado (Durn, Forja 01, Primeiro Eco, pátio) |

## 3. Informações classificadas

| Informação | Classe | Fonte |
|---|---|---|
| Ato 1 = Vardhelm, níveis 1–10 | **A** | SYS-BALANCEAMENTO §2; ENG-PROGRESSAO seg. 1; SYS-GRIMORIO-EARLYGAME |
| Vardhelm é cidade industrial (fundições, chaminés, fuligem, carvão) | **A** | TIER1 §1.1; decisão do usuário no C17 |
| Distrito das Fundições existe em Vardhelm | **A** | TIER1 §1.4.1; TIER3 §2.3.3 |
| Galpão de Manufatura existe em Vardhelm (interior) | **A** (direção de arte) | TIER1 §1.4.2 |
| Ato 1 tem combate, habilidades e monstros ("monstro padrão de Vardhelm") | **A** (documento de sistema) | SYS-GRIMORIO-EARLYGAME; ENG-MATEMATICA-COMBATE |
| Transição Ato 1 → 2 disparada no **nível 10** (`EVT_TRANSICAO_ATO1_ATO2`) | **A** | ENG-PROGRESSAO §3.1 |
| Existem rotas comerciais entre Vardhelm e Ostrell, longas e perigosas | **A** (justificativa econômica) | SYS-BALANCEAMENTO §3.5 |
| Forja 01, Durn, Primeiro Eco, painel selado, gancho "Então não fui só eu." | **A** (cânone de produção, validado por humano; sem documento de design) | slice C12–C16 |
| Pátio sob a Forja 01, talha, fundição vizinha | **C** (decisão de produção do C21) | BLOCK_C21 |
| Elyra = Avatar, "Última Arconte Rúnica", tese da memória, Linhagem Oculta revelada no Ato 4, escolha final | **A** | SYS-ATO4-FENDA; EVT-ESCOLHA-FINAL-001 |
| **Elyra no Ato 1** (material histórico citado pelo usuário) | **B** (fora do repositório; não verificável aqui) | — |
| Herdeiro = o jogador; Linhagem Oculta só no Ato 4 | **A** | SYS-ATO4-FENDA |
| Jogo ambientado "nas profundezas de Brenhold" | **B** (enquadramento AETHERIS) | MASTER_INDEX; BLUEPRINT |
| Brenhold no Ato 2 × Ato 3 | **D** | CLI e resumo do changelog × documentos de sistema |
| TIER1 = "Atos 1 e 2 / níveis 1–25" × Ato 2 = 11–20 e Ato 3 = 21–35 | **D** (menor) | cabeçalhos TIER1/TIER2 × SYS-BALANCEAMENTO |
| Ato 1 com combate e níveis (documentos) × slice Godot sem combate nem níveis | **D** (intenção documentada × direção implementada) | documentos de sistema × `godot/` |
| Aethel, Asterion, Homem Cinzento | **E** (nenhum arquivo do repositório) | — |
| Arco narrativo de Vardhelm, distritos, NPCs além de Durn, eventos, conclusão do Ato 1 | **E** | — |
| Papel do Eco além do Primeiro Eco | **E** (só "Zona de Eco Reversivo", mecânica do Ato 4) | — |

## 4. Durn

| Aspecto | Documentado | Implementado |
|---|---|---|
| Papel | **E**: nenhum documento de design cita Durn; só os blocos A1/A3/B1/C10–C21 (o slice) | primeiro NPC; quem também "sentiu"; aponta o Eco e o painel; dá o gancho "Então não fui só eu." |
| História existente | — | três falas (`intro`, `after_echo`, `after_panel`); C15: vai sozinho ao lugar do Eco; C16: a folha com horários |
| Futuro previsto | **E** | nenhum: depois do gancho só diz "..." |
| Acompanha o jogador? | **E** | não; fica na Forja 01 (ou no lugar do Eco, no caminho B) |
| Relação com a saída de Vardhelm | **E** | nenhuma |

**Conclusão:** o futuro de Durn é **decisão do usuário**. O gancho do C14 implica continuidade (outra pessoa ouviu o mesmo), mas o material não diz qual.

## 5. Elyra

**No repositório (A):**
- é um dos dois **Avatares** e a "Última Arconte Rúnica";
- defende a memória ("o progresso sem memória é apenas destruição");
- é a Rota B da escolha final (Estase Rúnica);
- tem **Linhagem Oculta revelada no Ato 4**.

**Não existe no repositório (E):**
- presença em Vardhelm ou no Ato 1;
- momento de entrada;
- relação com o protagonista antes do Ato 4;
- arqueologia;
- relação com o Primeiro Eco ou com o Véu;
- papel na saída de Vardhelm.

**Material histórico citado pelo usuário (B):** associa Elyra ao Ato 1. **Não está no repositório e não pôde ser verificado.**

**Conclusão:**
- Pelo repositório, **nada obriga Elyra a entrar no fechamento de Vardhelm**.
- Se o material histórico for adotado, ela precisa entrar ainda em Vardhelm, e esse material deve ser trazido ao repositório **antes** de qualquer bloco que a use.
- Atenção: os documentos tratam a Linhagem como segredo até o Ato 4. Uma entrada no Ato 1 não pode revelar isso.

## 6. Primeiro Eco

```
Primeiro Eco 🟢
   ↓
Vardhelm reage (C13) 🟢 → consequência da escolha (C15/C16) 🟢
   ↓
Durn aponta o painel (C12) 🟢 → painel + silêncio (C14) 🟢
   ↓
Gancho: "Então não fui só eu." 🟢
   ↓
⚪ NÃO DEFINIDO (o que o Eco significa, quem mais ouviu, o que o painel guarda)
   ↓
⚪ NÃO DEFINIDO (próximos Ecos? memória? Véu?)
   ↓
🟡 saída de Vardhelm: EVT_TRANSICAO_ATO1_ATO2 (nível 10) — conteúdo narrativo ⚪
```

- O nome do jogo põe os Ecos no centro, mas o repositório só documenta o Eco **mecânico** do Ato 4 (Zona de Eco Reversivo).
- O ritmo de revelação (Véu, Linhagem, Aethel, Asterion, Homem Cinzento) **não está no repositório**. Nada disso deve entrar em Vardhelm sem decisão.

## 7. Conclusão do Ato 1 e ligação com o Ato 2

| Pergunta | Resposta |
|---|---|
| Como o Ato 1 termina | **E** (narrativamente). Sistemicamente: nível 10 → `EVT_TRANSICAO_ATO1_ATO2` (**A**) |
| Evento de transição documentado | **A**: `EVT_TRANSICAO_ATO1_ATO2`, "Transição narrativa para Ostrell" (só o ID e o gatilho) |
| Condição de saída | **A**: nível 10. No slice Godot **não há níveis** (**D**); a condição precisa de decisão |
| Estrada, portão, viagem | **E**. Só "rotas comerciais de Vardhelm para Ostrell, longas e perigosas" (**A**, texto econômico) |
| Ostrell | Ato 2 (**A**); espaço, cultura e NPCs **E**. Não iniciar |

## 8. Definição objetiva de "Vardhelm completa"

Vardhelm está completa como primeira região quando os itens abaixo estiverem 🟢. Não é preciso esgotar o conteúdo possível. A lista combina o que os documentos exigem do Ato 1 com o padrão de produção do C20.

| # | Requisito | Base | Estado |
|---|---|---|---|
| V1 | Começo do arco (chegada, primeiro NPC, primeiro mistério) | slice | 🟢 |
| V2 | Primeira descoberta e consequência (Eco, reação, escolha) | slice | 🟢 |
| V3 | Desenvolvimento: o que acontece depois do gancho (quem mais ouviu, investigação seguinte) | **E** | ⚪ decisão |
| V4 | Conflito do Ato 1 | **E** | ⚪ decisão |
| V5 | NPCs necessários além de Durn (Elyra? outros?) | **B/E** | ⚪ decisão |
| V6 | Locais necessários (quais distritos ou áreas o arco exige) | Distrito (**A**), Galpão (**A**, arte); demais **E** | 🟡 parcial |
| V7 | Sistemas do Ato 1 que os documentos preveem (combate, habilidades, monstros, níveis 1–10) | **A** nos documentos × **D** no slice | ⚪ decisão |
| V8 | Conclusão local do arco de Vardhelm | **E** | ⚪ decisão |
| V9 | Condição de saída (nível 10? evento narrativo? os dois?) | **A** (nível) / **D** | ⚪ decisão |
| V10 | Estrutura física da saída (rota, portão, viagem) | **E** | ⚪ decisão |
| V11 | Ligação com o Ato 2 (Ostrell) sem construir Ostrell | **A** (Ato) / **E** (conteúdo) | ⚪ decisão |
| V12 | Fechamento C19-like da região (técnico + humano) | C20 | depois |

**Situação:** V1–V2 prontos; V6 parcial; **V3–V5 e V7–V11 dependem de decisões do usuário**.

## 9. Backlog de Vardhelm (IDs provisórios)

**Antes de qualquer bloco novo de conteúdo**, as decisões D1–D7 (§11).

| ID | Local | Objetivo | Dependências | Fonte | Risco | Narrativa | Técnica |
|---|---|---|---|---|---|---|---|
| C23 (candidato técnico) | Distrito das Fundições: rua além do portão sul do pátio | estender o distrito pelo próprio portão e trilho (fundições, chaminés, carvão chegando) | D1 (função narrativa), D5 | **A**: TIER1 §1.4.1, TIER3 §2.3.3; ligação **C** (portão e trilho do C21) | médio: vira "mais mapa" se D1 não estiver decidido | **E** | baixa: LevelBuilder, AmbientLife, Save V2 e passagem prontos |
| C24 | Galpão de Manufatura | interior de manufatura (volantes, correias, ponte rolante) | D1, D5; distinguir da Forja 01 | **A** (arte): TIER1 §1.4.2; ligação **C** (portões da fundição oeste do pátio) | médio: **repetir a Forja** | **E** | baixa |
| C25 | onde D1 definir | continuação do arco depois do gancho de Durn | **D1**, D7 | **E** | **alto** sem material | **alta** | média (sistemas de diálogo, quest e consequência prontos) |
| C26 | onde D2 definir | entrada de Elyra no Ato 1 (se adotada) | **D2** (material histórico no repositório) | **B** | **alto** (risco de revelar a Linhagem cedo) | alta | média |
| C27 | Vardhelm | combate, habilidades e progressão do Ato 1 (se adotados) | **D3** | **A** (documentos de sistema) / **D** (slice) | **alto** (sistema grande e novo no Godot) | média | **alta** |
| C28 | saída de Vardhelm | condição e estrutura da transição para o Ato 2 (sem Ostrell) | **D4**, D3 | **A** (`EVT_TRANSICAO_ATO1_ATO2`) / **E** | médio | alta | média |
| C29 | Vardhelm | fechamento da região (auditoria tipo C19 + teste humano) | C23–C28 decididos/feitos | C20 | — | — | média |
| R-UX | Forja/pátio | **REFINAMENTO UX DE VARDHELM** (ver §10) | depois do contexto | teste humano | baixo | — | baixa |

## 10. Refinamento (registrado, não corrigido)

**REFINAMENTO UX DE VARDHELM** (teste humano do C21): a janela de observação ambiental (`ObservationPanel`, 660 × 300 px fixos, no centro) ocupa boa parte da tela para textos curtos ("Suporte de ferramentas" e poucas linhas).

**Também da etapa de acabamento** (pendências B do C21):
- trabalhadores que não se viram para onde andam;
- carrinhos parados;
- piso de pedra e fundo simples;
- respiro de vapor que interpenetra o respiro de brasas;
- fragilidade de clique de mouse nos playtests renderizados (harness).

## 11. Decisões que dependem do usuário

| # | Decisão | Por quê |
|---|---|---|
| **D1** | **O que acontece depois do gancho "Então não fui só eu."** (desenvolvimento e conflito de Vardhelm) | sem isso, qualquer área nova é só mapa |
| **D2** | **Elyra entra no Ato 1?** Se sim, trazer o material histórico ao repositório (momento, função, relação com o protagonista, limites de revelação) | o repositório só a tem nos Atos 4 e 5 |
| **D3** | **O Ato 1 do jogo Godot terá combate e progressão (níveis 1–10)**, como os documentos de sistema preveem? | define a condição de saída e o tamanho do Ato |
| **D4** | **Condição e forma da saída de Vardhelm** (nível 10, evento narrativo ou ambos; rota comercial, portão, viagem?) | `EVT_TRANSICAO_ATO1_ATO2` só tem ID e gatilho |
| **D5** | **Quais distritos e áreas Vardhelm precisa** (além do Distrito das Fundições) | só o Distrito e o Galpão têm evidência |
| **D6** | **Brenhold: Ato 2 ou Ato 3** | contradição aberta desde o C20 |
| **D7** | **Ritmo de revelação** (Eco, Véu, Linhagem, Aethel, Asterion, Homem Cinzento): o que pode aparecer em Vardhelm | evitar revelação fora de hora |

## 12. Candidato a C23

**Melhor candidato técnico:** **a rua do Distrito das Fundições, além do portão sul do pátio.**
- **Por que agora:** é a mesma área documentada do C21 (TIER1 §1.4.1, confirmada pelo TIER3), com a evidência mais forte de Vardhelm. O pátio já aponta para ela: o portão de grade está fechado e o trilho passa por baixo.
- **Ligação com o pátio:** física e direta (portão sul + trilho). Seria uma decisão de produção, como o próprio pátio.
- **Função documentada:** exterior de fundições, chaminés, carvão chegando em carrinhos, talhas de corrente, céu encoberto.
- **Ainda exige decisão humana:** a função **narrativa** (D1), se a rua leva à saída de Vardhelm (D4) e quais outros pontos ela conecta (D5).

**Recomendação:** **não construir o C23 antes de D1** (e, se possível, D2 e D4). Construir a rua agora produziria espaço sem papel no arco, o padrão que o C20 e o C22 querem evitar. Com D1 decidido, a rua (ou o Galpão, se D1 apontar para dentro) vira o primeiro bloco do arco, e não "mais mapa".

## 13. Git

- **Estado verificado:** `integration/godot-vardhelm`, HEAD `b01da03` (local, 1 commit à frente de `origin/integration/godot-vardhelm`).
- **Não versionado, não tocado:** `godot/tests/save_v2/c21_1_passage_playtest.gd.uid`, gerado pelo Godot depois do commit, provavelmente ao abrir o projeto no teste humano.
- **C22:** só documentação, não commitada. Sem push, rebase, reset ou alteração de histórico.

## 14. C22.1 — Decisões tomadas (consolidação canônica)

Decisões do usuário sobre este relatório, formalizadas no C22.1. É só documentação.

| # | Decisão | Resultado | Onde |
|---|---|---|---|
| D1 | o que vem depois do gancho | **decidido em parte**: o Primeiro Eco é o **evento incitante**; começa uma **investigação em Vardhelm**; a estrutura macro tem 10 fases. As etapas intermediárias continuam NÃO DEFINIDAS | canon §3, §5, §10 |
| D2 | Elyra no Ato 1 | **sim**: material histórico + decisão humana; **arqueóloga élfica** com conhecimento incompleto; linhagem só no Ato 4. Local, momento e diálogo NÃO DEFINIDOS | canon §6 |
| D3 | combate no Ato 1 | **sim**, mas só com função narrativa e espacial (Fase 7). Não foi implementado | canon §7 |
| D4 | saída | **em parte**: clímax, conclusão e transição obrigatórios; o nível 10 **não** é condição rígida; a forma da viagem fica para depois do arco | canon §8, §11, §12 |
| D5 | distritos | só áreas com função. Sustentados: Distrito das Fundições, Forja 01, pátio, Galpão de Manufatura e a **rua do distrito** (extensão proposta) | canon §1, §2 |
| D6 | Brenhold | **adiado**; contradição registrada; não bloqueia Vardhelm | matriz §6 |
| D7 | ritmo de revelação | matriz em 3 camadas; Aethel, Asterion (civilização, não deus), Homem Cinzento e Último Experimento na camada 3; "Véu" só com justificativa do personagem | [`LORE_REVELATION_MATRIX.md`](../lore/LORE_REVELATION_MATRIX.md) |

**C23 confirmado como candidato preferencial:** a rua do Distrito das Fundições, com a função de **transição entre o microcosmo da Forja e Vardhelm como cidade**, preparando a investigação. Ainda **não implementado**.
