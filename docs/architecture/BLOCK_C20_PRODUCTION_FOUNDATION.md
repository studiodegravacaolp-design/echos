# Bloco C20 — Fundação de produção integrada dos próximos cenários

**Natureza:** documental.
- Nenhum cenário, mapa, NPC, máquina, diálogo, quest ou área foi criado.
- Nenhum arquivo de `godot/` foi alterado.
- Vardhelm permanece intacto como laboratório e primeiro vertical slice validado (C19).

**Data:** 2026-09-30.

## 1. O que o C20 registra

- **Padrão:** [`SCENARIO_PRODUCTION_STANDARD.md`](SCENARIO_PRODUCTION_STANDARD.md), com a regra, os estados, os critérios de entrada e fechamento e a relação com LevelBuilder, AmbientLife, Save V2 e EventBus.
- **Modelo:** [`SCENARIO_TEMPLATE.md`](SCENARIO_TEMPLATE.md), para copiar em `docs/scenarios/<scenario_id>.md`.
- **Regra:** **CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO**. Um cenário não nasce como geometria vazia; o primeiro bloco já tem FORMA + FUNÇÃO + VIDA + IDENTIDADE.

## 2. Vardhelm no padrão

- Vardhelm é **laboratório e referência**: técnica, de integração e de produção.
- Não é reconstruído nem migrado.
- Os itens provisórios continuam como 🔵 no [C19](BLOCK_C19_FORGE_CLOSING_AUDIT.md) §12:
  - modelo do jogador;
  - cidade ao fundo;
  - generalização do AmbientLife;
  - divisão do script do slice;
  - câmera e oclusão;
  - código morto;
  - migração opt-in.
- A generalização do AmbientLife **só** acontece no primeiro bloco de um cenário que precise dela, com os testes de Vardhelm como regressão (padrão §13).

## 3. Pesquisa documental: próximo cenário

**Onde se buscou:**
- `AETHERIS_MASTER_INDEX.md`;
- `DOCUMENTACAO/` (DOC-000 a DOC-015, `MASTER_ID_REGISTRY.md`, `DOCUMENT_MAP.md`);
- `docs/01_cenario`, `docs/01_sistemas`, `docs/03_narrativa`, `docs/04_arquitetura_software`, `docs/05_arte`;
- `doc/art_bible/`;
- conteúdo do protótipo TypeScript em `src/core/`;
- catálogos Godot.

**Termos buscados:** atos, Vardhelm, Ostrell, Brenhold, Fenda, locais, "Ato 1", Kael, Elyra, Aethel, Asterion, Homem Cinzento, Véu.

### 3.1 O que existe

| Fato | Evidência |
|---|---|
| Sequência de Atos: **Ato 1 Vardhelm** (níveis 1–10) → **Ato 2 Ostrell** (11–20) → **Ato 3 Diretório de Brenhold** (21–35) → **Ato 4 Fenda** (36–49) → Ato 5 Clímax | [`SYS-BALANCEAMENTO-ATOS.md`](../01_sistemas/SYS-BALANCEAMENTO-ATOS.md) §2–§4; [`ENG-PROGRESSAO-NIVEIS.md`](../04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md) segmentos 1–4 e §3.1; [`SYS-GRIMORIO-EARLYGAME.md`](../01_sistemas/SYS-GRIMORIO-EARLYGAME.md) |
| Transição do Ato 1 para o 2 acontece no nível 10: `EVT_TRANSICAO_ATO1_ATO2`, "Transição narrativa para Ostrell" | `ENG-PROGRESSAO-NIVEIS.md` §3.1 |
| Ostrell: só economia (+20% de inflação; "corrupção nas terras altas"; rotas comerciais de Vardhelm para Ostrell) | `SYS-BALANCEAMENTO-ATOS.md` §3 |
| Vardhelm tem duas vistas descritas **só como prompts de arte**: **Distrito das Fundições** (exterior) e **Galpão de Manufatura** (interior) | [`ART-PROMPTS-TIER1.md`](../05_arte/ART-PROMPTS-TIER1.md) §1.4.1 e §1.4.2 |
| Brenhold: zonas, Ordem do Silêncio, estética do TIER 2 | `SYS-BALANCEAMENTO-ATOS.md` §4; [`ART-PROMPTS-TIER2.md`](../05_arte/ART-PROMPTS-TIER2.md) |
| Nós de mapa do protótipo CLI: Entrada de Brenhold, Pátio de Fundição, Sala de Máquinas Principal, Refúgio Selado, Condutos de Vapor, Profundezas da Fundição, Santuário Enferrujado, Mercado das Profundezas, Câmara do Reator Central | [`src/core/CampaignMapEngine.ts`](../../src/core/CampaignMapEngine.ts) |
| Único cenário no catálogo Godot: `scenario.vardhelm` | [`id_catalog.gd`](../../godot/scripts/state/id_catalog.gd) |
| O "gancho" da Forja ("Então não fui só eu.") aponta para outra pessoa, não para um lugar | `godot/data/dialogue/vardhelm_after_panel.json` (C14) |

### 3.2 Candidatos (não escolhidos)

| Candidato | A favor | Contra / lacuna |
|---|---|---|
| **A. Outra área de Vardhelm, Ato 1** (Distrito das Fundições ou Galpão de Manufatura) | mesmo Ato e região da Forja; o Ato 1 cobre 10 níveis, então há espaço para mais de uma área; há prompts de arte com arquitetura, materiais e ocupação | existe **só como direção de arte**; sem função narrativa, NPCs, acontecimentos ou relação com a Forja |
| **B. Ostrell, Ato 2** | é o próximo Ato na sequência documentada; existe um evento de transição | documentado só por economia e progressão; sem local, arquitetura, cultura, NPCs ou narrativa; a transição exige nível 10, e o slice atual não tem progressão |
| **C. Brenhold** (nós do protótipo CLI) | já tem nós nomeados, quests (`quest_heart_of_brenhold`, `quest_echoes_in_ducts`) e inimigos no protótipo TypeScript | **conflito de Ato**: os docs de sistema o põem no **Ato 3**, mas o protótipo CLI e o resumo do changelog dizem "Ato 2 (Profundezas de Brenhold)"; o conteúdo do CLI é de combate e mapa, não de cenário explorável |

### 3.3 Lacunas

- `DOCUMENTACAO/DOC-001_WORLD_BIBLE.md` e `DOC-005_NARRATIVE.md`: só estrutura, sem conteúdo.
- `MASTER_ID_REGISTRY.md`: tabela `LOC-` vazia.
- Não há, no repositório, documento de sequência narrativa do Ato 1 além da Forja, nem documento de local para Ostrell.
- **Aethel, Asterion e Homem Cinzento não aparecem em nenhum arquivo do repositório.** O material canônico de ECHOES OF THE SOUL citado nas instruções não está disponível aqui para consulta.
- **Conflito de Ato de Brenhold** (Ato 2 no CLI e no changelog × Ato 3 nos docs de sistema): não resolvido aqui; decisão de cânone.
- **Direção visual:** o Art Bible pede HD-2D pixel art, e o protótipo Godot é 3D/2,5D (decisão do C17). Não é conflito de cenário, mas o primeiro bloco do próximo cenário deve citar essa decisão.

### 3.4 Conclusão

> **Próximo cenário ainda não definido no material canônico disponível.**

Há três candidatos com evidência **parcial** (§3.2). Nenhum atende o mínimo do checklist de entrada: função narrativa, ocupação, acontecimentos e relação com a Forja. A escolha é do dono do cânone. Para destravar:
1. indicar qual candidato (ou outro local) segue a Forja;
2. fornecer ou apontar o material canônico desse local;
3. resolver o Ato de Brenhold.

Nenhum lore foi criado para preencher as lacunas.

## 4. Verificação

- **Documentos:**
  - nenhum documento existente foi reescrito;
  - o padrão referencia o C19, o Art Bible, o `MASTER_ID_REGISTRY` e os catálogos, sem duplicá-los;
  - o único documento existente alterado é o `PROJECT_CHANGELOG.md` (entrada e resumo).
- **IDs:**
  - o padrão adota os formatos já usados no Godot (`<tipo>.<cenário>.<nome>`) e os prefixos documentais já registrados (`LOC-`, `EVT-`);
  - nenhum ID novo foi criado.
- **Código de gameplay:** `godot/` idêntico antes e depois do bloco (hash do diff e da lista de arquivos).
- **Testes:** bateria completa guardada, igual à linha de base (ver `PROJECT_CHANGELOG.md`).
