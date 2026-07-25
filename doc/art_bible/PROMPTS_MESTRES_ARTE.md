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

---

## 2. HISTÓRICO DE MUDANÇAS

- **Blueprint v1.2 — Portraits:** substituição do padrão de "retrato solto" pelo padrão diegético **"Card de UI com Caixa de Diálogo Integrada"** (moldura de ferro + runas gravadas + caixa de pergaminho na base). Mantido o R3 LOCK contra runas mágicas/emissivas.
