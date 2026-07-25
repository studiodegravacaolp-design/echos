# 🖼️ PROMPTS MESTRES DE ARTE — PROJETO AETHERIS
## Repositório Canônico de Prompts de Geração (HD-2D Pixel Art)

> **Nota para IAs/Assistentes de Arte:** Este arquivo consolida os prompts mestres de geração de imagem do Aetheris. Todos os prompts seguem a convenção de pesos `(termo:peso)` e as travas negativas (R3 LOCK) definidas em [`docs/05_arte/ART-PROMPTS-TIER1.md`](../../docs/05_arte/ART-PROMPTS-TIER1.md) e respeitam a paleta e as proibições da [`BLUEPRINT_VISUAL_MESTRE.md`](BLUEPRINT_VISUAL_MESTRE.md).

---

## 1. PADRÃO DE PORTRAITS — "CARD DE UI COM CAIXA DE DIÁLOGO INTEGRADA"

### 1.1 Definição do Padrão Diegético

A partir do Blueprint v1.2, **todo Portrait do Aetheris deixa de ser um retrato solto** e passa a ser gerado como um **Card de UI diegético completo**: o retrato do personagem vem **emoldurado por uma moldura de ferro industrial**, ornamentada com **runas gravadas** (marcas de fundição — ver §1.3), e traz na **base uma caixa de texto de pergaminho** integrada, pronta para receber o diálogo/nome da unidade.

Isso unifica retrato e HUD de diálogo em um único asset coeso, reforçando o tom de "arqueologia de máquinas" — a UI é parte do mundo, não uma sobreposição limpa.

| Elemento | Descrição |
| --- | --- |
| **Moldura de Ferro** | Borda espessa de ferro fundido oxidado, rebites nos cantos, cantoneiras reforçadas. |
| **Runas Gravadas** | Glifos de fundição **gravados/estampados** no ferro (não mágicos, não emissivos — ver §1.3). |
| **Retrato Central** | Busto do personagem em HD-2D pixel art, iluminação chiaroscuro de topo. |
| **Caixa de Pergaminho** | Faixa de pergaminho envelhecido na base da moldura, para nome + linha de diálogo. |

### 1.2 Prompt Mestre — UI Card / Dialog Frame

```
[PPB-UICARD-PORTRAIT]:
HD-2D pixel art character portrait rendered as a diegetic UI card,
(character bust centered:1.4), (chiaroscuro top-down volumetric light:1.3),
(coal-dust smudged industrial face:1.2), (grim weary expression:1.1),

--- FRAME ---
(thick cast-iron ornamental frame:1.6), (oxidized rusted iron border:1.4),
(corner rivets and reinforced bracket plates:1.3),
(engraved stamped foundry runes on the iron frame:1.4),
(non-glowing etched industrial glyphs:1.2),

--- DIALOGUE BOX ---
(integrated aged parchment text box at the bottom base:1.5),
(weathered grease-stained parchment banner:1.3),
(empty engraved nameplate strip:1.2),

--- STYLE ---
(70-20-10 palette rust-grey base, brass accents, single emissive glow:1.2),
[medium bust shot], [eye-level], [hard directional light], [1px carbon outline], [12 FPS pixel art]

--NEGATIVE PROMPT (R3 LOCK)--
(glowing runes:-1.5), (magical arcane runes:-1.5), (golden runes:-1.5),
(glowing auras:-1.5), (ethereal glow:-1.5), (magic particles:-1.5),
(neon:-1.5), (cyberpunk:-1.5), (sleek polished metal:-1.0),
(clean minimalist UI:-1.5), (floating HUD overlay:-1.2),
(smooth gradients:-1.0), (photorealistic:-1.5), (3D render:-1.5)
```

### 1.3 Reconciliação Canônica — Runas Não-Mágicas

> ⚠️ **Atenção de conformidade:** o R3 LOCK padrão bloqueia `(runes:-1.5)` e a Bíblia de Arte proíbe "entalhes rúnicos dourados" (alta-fantasia). As runas deste padrão **não violam** essa regra: são **glifos industriais gravados/estampados no ferro** — marcas de fundição, números de série e selos de forja funcionais —, **sem brilho, sem cor mágica e sem purpurina arcana**. O R3 LOCK acima mantém explicitamente o bloqueio de `glowing runes`, `magical arcane runes` e `golden runes` para preservar o tom.

### 1.4 Anatomia do Card (Decomposição Estrutural)

| Componente | Palavras-Chave Obrigatórias | Peso |
| --- | --- | --- |
| Moldura de ferro | `thick cast-iron ornamental frame`, `oxidized rusted iron border` | 1.6 / 1.4 |
| Rebites/cantoneiras | `corner rivets and reinforced bracket plates` | 1.3 |
| Runas gravadas | `engraved stamped foundry runes`, `non-glowing etched industrial glyphs` | 1.4 / 1.2 |
| Caixa de diálogo | `integrated aged parchment text box at the bottom base` | 1.5 |
| Placa de nome | `empty engraved nameplate strip` | 1.2 |
| Retrato | `character bust centered`, `chiaroscuro top-down volumetric light` | 1.4 / 1.3 |

### 1.5 Aplicação por Raça

O prompt mestre acima é o **template base**. Para cada raça, injete no bloco `--- character bust ---` as palavras-chave de chassi e a paleta de destaque já consolidadas na [`BLUEPRINT_VISUAL_MESTRE.md`](BLUEPRINT_VISUAL_MESTRE.md) §3 (Humanos, Anões, Elfos, Fadas, Draconianos, Lurídeos). A moldura de ferro, as runas gravadas e a caixa de pergaminho permanecem **constantes** em todos os portraits para garantir coesão de UI.

| Raça | Injeção de Chassi no bloco `character bust` (peso) |
| --- | --- |
| **Humanos (Sapador)** | `rectangular rigid block silhouette:1.4`, `heavy mechanical articulated joints:1.5`, `exposed rivets:1.3`, `rough canvas tunic + cordura leather:1.3`, `tool belts + wrench and hammer:1.1`, `goggles with brass frames:1.1`, `metal shoulder pauldrons:1.3` |
| **Anões** | `short broad immovable silhouette:1.5`, `oversized press-hands:1.3`, `brass-ringed braided beard:1.2`, `functional hydraulic pistons:1.3`, `portable forge vents glowing incandescent-orange (#FF7900):1.1` |
| **Elfos** | `slender imposing silhouette:1.3`, `soot-scarred pointed ears:1.2`, `finely detailed micro-manipulation mechanical arm:1.4`, `copper wiring, spark-blue (#00E5FF) fingertip glow:1.0` |
| **Fadas** | `compact agile silhouette:1.4`, `thin bronze pneumatic wing-plates venting steam:1.3`, `chemical-green (#39FF14) rear pressure cores:1.0` |
| **Draconianos** | `massive silhouette:1.4`, `industrial muzzle rebreather:1.3`, `impact-tipped reinforced tail:1.2`, `incandescent-orange (#FF7900) glow under thermal scales:1.0` |
| **Lurídeos** | `fluid scaled body aquatic blue-teal:1.3`, `membrane fins:1.2`, `bolted subaquatic rebreather rig:1.3`, `chemical-green (#39FF14) pressurization visors:1.0` |

### 1.6 Exemplo Migrado — Portrait do Sapador Humano (UI Card)

> **Migração:** o antigo prompt `[PPB-SAPADOR]` (retrato solto, em `docs/05_arte/ART-PROMPTS-TIER1.md`) foi **depreciado e migrado** para o padrão UI Card abaixo. Todos os retratos de raça agora residem aqui.

```
[UICARD-SAPADOR-HUMANO]:
HD-2D pixel art character portrait rendered as a diegetic UI card,
(human sapper combat engineer bust centered:1.4),
(rectangular rigid block silhouette:1.4), (heavy mechanical articulated joints:1.5),
(opaque hydraulic pressure tubing:1.3), (exposed rivets:1.3),
(rough canvas tunic:1.3), (cordura leather armor:1.2), (metal shoulder pauldrons:1.3),
(tool belts, wrench and hammer hanging:1.1), (goggles with brass frames:1.1),
(coal dust smudged face:1.2), (grim determined expression:1.1),
(chiaroscuro top-down volumetric light:1.3),

--- FRAME ---
(thick cast-iron ornamental frame:1.6), (oxidized rusted iron border:1.4),
(corner rivets and reinforced bracket plates:1.3),
(engraved stamped foundry runes on the iron frame:1.4),
(non-glowing etched industrial glyphs:1.2),

--- DIALOGUE BOX ---
(integrated aged parchment text box at the bottom base:1.5),
(weathered grease-stained parchment banner:1.3), (empty engraved nameplate strip:1.2),

--- STYLE ---
(70-20-10 palette rust-grey base, brass accents, single emissive glow:1.2),
[medium bust shot], [eye-level], [hard directional light], [1px carbon outline], [12 FPS pixel art]

--NEGATIVE PROMPT (R3 LOCK)--
(glowing runes:-1.5), (magical arcane runes:-1.5), (golden runes:-1.5),
(glowing auras:-1.5), (ethereal glow:-1.5), (magic particles:-1.5),
(neon:-1.5), (cyberpunk:-1.5), (sleek armor:-1.0), (polished metal:-1.0),
(heroic pose:-1.0), (clean minimalist UI:-1.5), (floating HUD overlay:-1.2),
(photorealistic:-1.5), (3D render:-1.5)
```

---

## 2. HISTÓRICO DE MUDANÇAS

- **Blueprint v1.2 — Portraits:** substituição do padrão de "retrato solto" pelo padrão diegético **"Card de UI com Caixa de Diálogo Integrada"** (moldura de ferro + runas gravadas + caixa de pergaminho na base). Mantido o R3 LOCK contra runas mágicas/emissivas.
- **Consolidação de Portraits:** migração do `[PPB-SAPADOR]` (retrato solto) do `ART-PROMPTS-TIER1.md` para `[UICARD-SAPADOR-HUMANO]` (§1.6); tabela de injeção de chassi por raça (§1.5). O `ART-PROMPTS-TIER1.md` passa a tratar apenas cenários/arquitetura/itens e aponta para cá quanto a portraits.
