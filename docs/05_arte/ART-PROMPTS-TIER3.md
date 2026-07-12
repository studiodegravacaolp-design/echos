# ART-PROMPTS-TIER3 — Repositório de Prompts Técnicos de Arte
## TIER 3: CLÍMAX (Atos 4 e 5 / Níveis 36-50)
### Projeto Aetheris — RPG de Sistemas Mecânico-Ontológicos Mobile

---

**ID do Documento:** ART-PROMPTS-TIER3
**Versão:** 1.0.0
**Status:** APROVADO — REGRA R3 REVOGADA — MARCAS DE VEREDITO LIBERADAS
**Classificação:** Técnico / Pipeline de Arte / Engenharia de Prompts / Endgame
**Auditoria:** Dola IA — Gerenciamento de Conformidade — Exceção Estrutural Concedida
**Autor:** Núcleo de Arte Técnica — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## Preâmbulo — A Revogação da Regra R3 e a Liberação das Marcas de Veredito

Este documento codifica as especificações formais de geração de imagens para o **TIER 3 (Clímax / Endgame)** do Projeto Aetheris, correspondente aos **Atos 4 e 5 (Níveis 36-50)** .

O TIER 3 representa a **DESCALCIFICAÇÃO ONTOLÓGICA** do mundo de Aetheris. A arquitetura de contenção que sustentou os TIERs 1 e 2 — o silêncio de chumbo de Brenhold, a fuligem industrial de Vardhelm — colapsa sob o peso do **Veredito**. A Regra R3, que bloqueava toda manifestação cromática e luminescente nos tiers anteriores, é **REVOGADA** neste documento.

### O que muda com a Revogação da R3

| Elemento                          | TIER 1 & 2 (R3 Ativa)               | TIER 3 (R3 Revogada)                          |
|-----------------------------------|--------------------------------------|-----------------------------------------------|
| **Ember (#FF4500)**               | Bloqueado (peso -1.0)                | **Liberado** — token visual do polo Paterno   |
| **Dourado Prismathico (#FFD700)** | Bloqueado (peso -1.0)                | **Liberado** — token visual do polo Materno   |
| **Runas e símbolos arcanos**      | Bloqueados (peso -1.5)               | **Liberados** — runas de Veredito ativas      |
| **Auras brilhantes**              | Bloqueadas (peso -1.5)               | **Liberadas** — halos de Veredito             |
| **Luz mística/divina**            | Bloqueada (peso -1.5)                | **Liberada** — luz de colapso ontológico      |
| **Partículas mágicas**            | Bloqueadas (peso -1.5)               | **Liberadas** — estática quadrada do Véu      |
| **Cristais luminescentes**        | Bloqueados (peso -1.0)               | **Liberados** — cristais de Veredito          |
| **Efeitos neon/cyberpunk**        | Bloqueados (peso -1.5)               | **Continuam bloqueados** — fora da estética   |

### Marcas de Veredito — Tokens Visuais de Polo

Duas polaridades cromáticas definem o conflito ontológico do TIER 3:

| Marca de Veredito | Polo         | Cor Hex   | Token Visual                                                                 |
|-------------------|--------------|-----------|------------------------------------------------------------------------------|
| **Ember**         | Paterno      | `#FF4500` | Incandescência de metal líquido e brasa ardente — calor ontológico bruto     |
| **Dourado Prismathico** | Materno | `#FFD700` | Linhas e halos circulares de ouro rúnico rígido — geometria de contenção divina |

Ambas as Marcas DEVERÃO coexistir nos prompts de cenário de colapso, frequentemente em conflito visual direto (chamas de Ember rompendo anéis de Dourado Prismathico, ou vice-versa).

### Convenções de Notação

| Símbolo | Significado                                          |
|---------|------------------------------------------------------|
| `(termo:1.0)` | Peso neutro — presença padrão                       |
| `(termo:1.5)` | Amplificação — ênfase forte                         |
| `(termo:2.0)` | Amplificação crítica — elemento dominante           |
| `(termo:-0.5)` | Atenuação suave                                     |
| `(termo:-1.0)` | Bloqueio — elemento proibido, peso negativo explícito |
| `(termo:-1.5)` | Repressão forte — elemento completamente suprimido  |
| `[termo]`     | Modificador técnico (perspectiva, iluminação, enquadramento) |

---

## Seção 1: Descalcificação Ontológica e Personagens de Eixo (Tarefas 3.1 e 3.2)

### 1.1 Prompt Padrão de Ativação — Veredito Endgame

```
[PPB-VEREDITO-END]:
illustration of ontological verdict activation scene,
(textured classical illustration:1.4), (firm ink contours:1.3),
(internal negative space:1.5),
(disconnected plates floating over light channels:1.5),
(ember incandescence:#FF4500 liquid metal glow:1.5),
(dourado prismathico:#FFD700 rigid runic gold circular halos:1.5),
(verdict marks clashing:1.4),
(ontological fracture lines:1.4),
(floating architectural fragments:1.3),
(light bleeding through structural gaps:1.4),
(gravitational distortion:1.3),
(space between matter:1.4),
(plates of reality peeling away:1.5),
[cinematic composition], [dramatic chiaroscuro], [high contrast]
```

### 1.2 Paleta de Cores — Veredito Endgame

| Cor                  | Proporção | Descrição                                              |
|----------------------|-----------|--------------------------------------------------------|
| Ember (#FF4500)      | 30%       | Incandescência Paterna, metal líquido, brasa ardente   |
| Dourado Prismathico (#FFD700) | 25% | Halos rúnicos Maternos, geometria de contenção         |
| Preto do Véu         | 20%       | Vácuo entre placas, espaço negativo, profundidade      |
| Cinza-fantasma       | 15%       | Placas desconectadas, fragmentos de realidade          |
| Roxo geométrico      | 10%       | Fendas do Véu, estática quadrada, distorção            |

### 1.3 Variações de Prompt — Personagens de Eixo

#### 1.3.1 Portador da Marca Paterna (Ember)

```
[PPB-PORTADOR-EMBER]:
portrait of verdict bearer marked by paternal ember,
(textured classical illustration:1.4), (firm ink contours:1.3),
(internal negative space:1.3),
(ember incandescence:#FF4500:1.5) coursing through cracked skin,
(liquid metal veins:1.4),
(burning ember glow from within:1.5),
(rigid rectangular silhouette cracking open:1.4),
(industrial armor fragments floating:1.3),
(heat shimmer distortion around body:1.3),
(ontological burn marks:1.4),
(gravity warping near hands:1.2),
(no fear expression:1.2), (determined acceptance:1.3),
[medium shot], [low angle], [ember backlighting]
```

#### 1.3.2 Portadora da Marca Materna (Dourado Prismathico)

```
[PPB-PORTADORA-DOURADO]:
portrait of verdict bearer marked by maternal dourado prismathico,
(textured classical illustration:1.4), (firm ink contours:1.3),
(internal negative space:1.3),
(dourado prismathico:#FFD700:1.5) rigid runic circular halos,
(golden geometric halo behind head:1.5),
(runic lines tracing skin:1.4),
(containment geometry forming around body:1.4),
(severe right angle shoulder lines dissolving into golden rings:1.3),
(lead armor plates with golden runic inlay:1.3),
(calm transcendent expression:1.2),
(light bending around form:1.3),
[medium shot], [eye-level perspective], [golden rim light]
```

#### 1.3.3 Personagem em Colapso — Fusão dos Polos

```
[PPB-FUSAO-POLOS]:
portrait of character undergoing verdict fusion,
(textured classical illustration:1.4), (firm ink contours:1.3),
(internal negative space:1.5),
(ember:#FF4500 and dourado prismathico:#FFD700:1.5) clashing within same body,
(ember veins intersecting golden runic lines:1.5),
(half face ember incandescence:1.4),
(half face golden geometric patterns:1.4),
(disconnected plates floating around figure:1.4),
(light channels piercing through torso:1.4),
(ontological fracture across centerline:1.5),
(static square particles:1.3),
(achromatic vacuum at point of contact:1.3),
[close-up], [dramatic lighting], [split color grading]
```

### 1.4 Anatomia do Prompt — Veredito (Decomposição Estrutural)

| Componente Visual                | Palavras-Chave Obrigatórias                              | Peso |
|----------------------------------|----------------------------------------------------------|------|
| Estilo base                      | `textured classical illustration`, `firm ink contours`   | 1.4  |
| Espaço negativo                  | `internal negative space`                                | 1.5  |
| Placas flutuantes                | `disconnected plates floating over light channels`       | 1.5  |
| Marca Paterna                    | `ember incandescence:#FF4500 liquid metal glow`          | 1.5  |
| Marca Materna                    | `dourado prismathico:#FFD700 rigid runic gold halos`     | 1.5  |
| Conflito ontológico              | `verdict marks clashing`, `ontological fracture lines`   | 1.4  |
| Fragmentação                     | `floating architectural fragments`, `plates of reality`  | 1.4  |
| Luz entre estruturas             | `light bleeding through structural gaps`                 | 1.4  |
| Distorção                        | `gravitational distortion`                               | 1.3  |

### 1.5 Proibições Específicas — Personagens de Eixo

- **Proibido** expressões de medo ou pânico — os Portadores aceitam o Veredito
- **Proibido** posturas de combate convencionais — a luta aqui é ontológica, não física
- **Proibido** armas convencionais — o Veredito é a arma
- **Proibido** fundos neutros ou passivos — o cenário DEVE refletir o colapso
- **Proibido** qualquer referência a tecnologia elétrica, digital ou cyberpunk
- **Obrigatório** a coexistência visual de Ember e Dourado Prismathico em cenas de conflito
- **Obrigatório** espaço negativo interno — o corpo e o cenário NÃO são sólidos, são placas sobre luz

---

## Seção 2: Cenários Finais e o Colapso Termodinâmico (Tarefa 3.3)

### 2.1 Prompt Padrão de Cenário — Colapso Termodinâmico

```
[PPB-CENARIO-END]:
illustration of thermodynamic collapse and veil rupture,
(textured classical illustration:1.4), (firm dark ink contours:1.3),
(extreme contra-plongée perspective:1.5),
(fusion of industrial steel and lead architecture:1.4)
(with purple geometric veil rifts:1.5),
(ember:#FF4500 molten metal pouring through steel girders:1.4),
(dourado prismathico:#FFD700 runic rings containing rupture:1.4),
(heat shimmer distortion in air:1.4),
(square static particles floating:1.4),
(architectural fragments suspended mid-fall:1.5),
(gravity distortion field:1.4),
(lead plates peeling like paper:1.3),
(purple geometric fracture lines spreading across sky:1.5),
(industrial chimneys split by ontological fault lines:1.3),
(verdict light piercing through smoke:1.4),
[wide shot], [extreme low angle], [high dynamic range]
```

### 2.2 Paleta de Cores — Cenários de Colapso

| Cor                  | Proporção | Descrição                                              |
|----------------------|-----------|--------------------------------------------------------|
| Roxo geométrico      | 25%       | Fendas do Véu, estática quadrada, geometria de fratura |
| Ember (#FF4500)      | 20%       | Metal líquido derretido, brasa ontológica              |
| Dourado Prismathico (#FFD700) | 15% | Anéis de contenção, runas de vedação                   |
| Cinza industrial     | 20%       | Aço, chumbo, arquitetura remanescente                  |
| Preto do Véu         | 15%       | Vácuo entre fragmentos, profundidade do colapso        |
| Branco fantasma      | 5%        | Luz de Veredito, pontos de fusão máxima                |

### 2.3 Variações de Prompt — Cenários

#### 2.3.1 A Fenda do Véu — Ruptura Primária

```
[PPB-FENDA-VEU]:
illustration of primary veil rupture over industrial city,
(textured classical illustration:1.4), (firm dark ink contours:1.3),
(extreme contra-plongée perspective:1.5),
(purple geometric rift tearing across sky:1.5),
(industrial skyline silhouetted against ontological light:1.4),
(ember:#FF4500 cascading from rift like liquid fire:1.4),
(dourado prismathico:#FFD700 containment rings around rift edges:1.5),
(square static particles raining down:1.4),
(heat shimmer distortion:1.3),
(architectural fragments rising toward rift:1.4),
(gravity inversion effect:1.4),
(lead roofs peeling upward:1.3),
[wide shot], [extreme low angle], [purple and ember sky]
```

#### 2.3.2 A Câmara de Veredito — Interior do Colapso

```
[PPB-CAMARA-VEREDITO]:
illustration of verdict chamber interior at ontological zero point,
(textured classical illustration:1.4), (firm ink contours:1.3),
(internal negative space dominant:1.5),
(disconnected plates of reality:1.5) floating in achromatic void,
(ember:#FF4500 and dourado prismathico:#FFD700:1.5) swirling in equilibrium,
(geometric purple fracture lines across all surfaces:1.4),
(no floor visible:1.5), (infinite depth below:1.4),
(light channels crisscrossing empty space:1.4),
(square static particles suspended:1.3),
(architectural fragments orbiting central point:1.3),
(gravity nullified:1.4),
[medium shot], [symmetrical composition], [void background]
```

#### 2.3.3 O Colapso de Vardhelm — Legado Industrial Consumido

```
[PPB-COLAPSO-VARDHELM]:
illustration of Vardhelm forge district during ontological collapse,
(textured classical illustration:1.4), (firm dark ink contours:1.4),
(extreme contra-plongée perspective:1.5),
(familiar industrial architecture splitting apart:1.5),
(sooty canvas bricks floating in zero gravity:1.4),
(ember:#FF4500 molten iron pouring from fractured foundries:1.5),
(purple geometric rifts cutting through smokestacks:1.4),
(heat shimmer and static particles:1.4),
(lead plates from Brenhold architecture drifting through:1.3),
(verdict light burning through smog:1.4),
(coal dust illuminated by ember glow:1.3),
[wide shot], [extreme low angle], [catastrophic composition]
```

### 2.4 Anatomia do Prompt — Cenário (Decomposição Estrutural)

| Componente Visual                | Palavras-Chave Obrigatórias                              | Peso |
|----------------------------------|----------------------------------------------------------|------|
| Perspectiva                      | `extreme contra-plongée perspective`                     | 1.5  |
| Fusão arquitetônica              | `fusion of industrial steel and lead architecture`       | 1.4  |
| Fendas do Véu                    | `purple geometric veil rifts`                            | 1.5  |
| Marca Paterna no cenário         | `ember molten metal pouring through steel girders`       | 1.4  |
| Marca Materna no cenário         | `dourado prismathico runic rings containing rupture`     | 1.4  |
| Distorção atmosférica            | `heat shimmer distortion in air`                         | 1.4  |
| Partículas                       | `square static particles floating`                       | 1.4  |
| Fragmentação                     | `architectural fragments suspended mid-fall`             | 1.5  |
| Gravidade                        | `gravity distortion field`                               | 1.4  |

### 2.5 Proibições Específicas — Cenários

- **Proibido** céu limpo ou atmosfera normal — o ar DEVE exibir distorção
- **Proibido** gravidade funcionando corretamente — fragmentos DEVEM flutuar ou cair em direções anômalas
- **Proibido** arquitetura intacta — todo cenário DEVE mostrar fratura ontológica
- **Proibido** ausência de ambas as Marcas de Veredito — Ember e Dourado Prismathico DEVEM coexistir
- **Proibido** fendas invisíveis ou sutis — as fendas do Véu são GEOMÉTRICAS, ROXAS e ÓBVIAS
- **Obrigatório** distorção térmica (heat shimmer) OU partículas quadradas de estática visíveis no ar
- **Obrigatório** sensação de que o mundo está se desfazendo em camadas

---

## Seção 3: Disciplinas Supremas e Relíquias (Tarefa 3.4)

### 3.1 Prompt Padrão de Assets — Supremo Endgame

```
[PPB-SUPREMO-END]:
illustration of supreme discipline effect and legendary relic activation,
(textured classical illustration:1.4), (firm ink contours:1.3),
(physical deformation of space:1.5),
(ground cracked in mathematical patterns:1.5),
(achromatic vacuum at epicenter:1.5),
(ember:#FF4500 and dourado prismathico:#FFD700:1.5) spiraling around focal point,
(geometric fracture lines radiating outward:1.4),
(square static particles in suspension:1.4),
(gravity distortion rings:1.4),
(lead and steel fragments caught in vacuum:1.3),
(verdict light pulsing from relic core:1.4),
(ontological shockwave pattern on ground:1.4),
[close-up], [macro detail], [high contrast dramatic lighting]
```

### 3.2 Relíquias Lendárias — Especificações Visuais

#### 3.2.1 REL-ONT-001 — O Núcleo de Ember (Polo Paterno)

```
[REL-ONT-001-NUCLEO-EMBER]:
illustration of legendary relic Núcleo de Ember,
(textured classical illustration:1.4), (firm ink contours:1.3),
(cracked industrial iron sphere:1.5) with (liquid ember:#FF4500 core:1.5),
(molten metal veins spreading across surface:1.5),
(heat shimmer radiating outward:1.4),
(ground beneath cracked in radial mathematical pattern:1.4),
(achromatic vacuum ring around base:1.3),
(square static particles orbiting:1.3),
(industrial rivets glowing ember orange:1.3),
(gravity distortion pulling debris inward:1.4),
(ontological weight:1.4),
[close-up], [macro detail], [ember backlighting]
```

#### 3.2.2 REL-ONT-002 — O Anel do Veredito (Polo Materno)

```
[REL-ONT-002-ANEL-VEREDITO]:
illustration of legendary relic Anel do Veredito,
(textured classical illustration:1.4), (firm ink contours:1.3),
(perfect circular golden:#FFD700 ring:1.5) with (rigid runic geometry:1.5),
(dourado prismathico halos concentric:1.5),
(runic inscriptions floating around ring:1.4),
(containment geometry:1.4),
(ground beneath cracked in concentric circular pattern:1.4),
(achromatic vacuum inside ring:1.4),
(light bending around golden geometry:1.3),
(static particles forming geometric shapes:1.3),
(calm gravitational field:1.3),
[close-up], [macro detail], [golden rim light]
```

#### 3.2.3 REL-ONT-003 — A Balança de Pólos (Fusão)

```
[REL-ONT-003-BALANCA-POLOS]:
illustration of legendary relic Balança de Pólos,
(textured classical illustration:1.4), (firm ink contours:1.3),
(dual-sphere relic:1.5) with (ember:#FF4500 and dourado prismathico:#FFD700:1.5) in equilibrium,
(one sphere liquid ember incandescence:1.5),
(one sphere rigid golden runic geometry:1.5),
(beam of achromatic vacuum connecting them:1.5),
(ground beneath cracked in symmetrical dual pattern:1.5),
(ontological balance:1.4),
(space distorted between spheres:1.4),
(square static particles forming bridge:1.4),
(gravity nullified in vicinity:1.4),
(verdict light pulsing between poles:1.4),
[close-up], [macro detail], [split lighting ember and gold]
```

### 3.3 Efeitos de Habilidade — Teto Técnico

#### 3.3.1 Veredito Paterno — Ember Eruption

```
[EFEITO-EMBER-ERUPTION]:
illustration of supreme paternal discipline Ember Eruption,
(textured classical illustration:1.4), (firm ink contours:1.3),
(physical deformation of ground:1.5),
(ground cracked in radial mathematical fractal pattern:1.5),
(ember:#FF4500 eruption from below:1.5),
(liquid metal spraying upward:1.4),
(achromatic vacuum at impact point:1.4),
(heat shimmer distorting entire frame:1.4),
(square static particles propelled outward:1.4),
(industrial debris molten and airborne:1.3),
(gravity inversion in blast radius:1.4),
[wide shot], [dramatic low angle], [ember overexposure]
```

#### 3.3.2 Veredito Materno — Dourado Prismathico Prison

```
[EFEITO-DOURADO-PRISON]:
illustration of supreme maternal discipline Dourado Prismathico Prison,
(textured classical illustration:1.4), (firm ink contours:1.3),
(physical deformation of space:1.5),
(ground cracked in concentric geometric cage pattern:1.5),
(dourado prismathico:#FFD700:1.5) geometric prison rising from ground,
(rigid golden runic bars:1.5),
(circular halos containing target:1.4),
(achromatic vacuum inside prison:1.5),
(containment geometry sealing all exits:1.4),
(square static particles forming cage walls:1.4),
(light trapped inside golden structure:1.3),
[medium shot], [symmetrical composition], [golden containment lighting]
```

#### 3.3.3 Veredito Absoluto — Colapso de Pólos

```
[EFEITO-COLAPSO-POLOS]:
illustration of absolute verdict discipline Colapso de Pólos,
(textured classical illustration:1.4), (firm ink contours:1.3),
(total physical deformation of reality:1.5),
(ground cracked in dual overlapping mathematical patterns:1.5),
(ember:#FF4500 and dourado prismathico:#FFD700:1.5) spiraling into singularity,
(achromatic vacuum consuming center:1.5),
(space folding inward:1.5),
(all matter fragmenting into square static particles:1.5),
(gravity completely collapsed:1.5),
(ontological void expanding:1.5),
(verdict light extinguishing:1.4),
[wide shot], [extreme wide angle], [achromatic center with ember and gold edges]
```

### 3.4 Anatomia do Prompt — Supremo (Decomposição Estrutural)

| Componente Visual                | Palavras-Chave Obrigatórias                              | Peso |
|----------------------------------|----------------------------------------------------------|------|
| Deformação física                | `physical deformation of space`                          | 1.5  |
| Solo fraturado                   | `ground cracked in mathematical patterns`                | 1.5  |
| Vácuo acromático                 | `achromatic vacuum at epicenter`                         | 1.5  |
| Marcas de Veredito               | `ember and dourado prismathico spiraling`                | 1.5  |
| Fraturas geométricas             | `geometric fracture lines radiating`                     | 1.4  |
| Partículas                       | `square static particles in suspension`                  | 1.4  |
| Anéis de distorção               | `gravity distortion rings`                               | 1.4  |
| Fragmentos                       | `lead and steel fragments caught in vacuum`              | 1.3  |
| Pulso de Veredito                | `verdict light pulsing from relic core`                  | 1.4  |

### 3.5 Paleta de Cores — Relíquias e Efeitos

| Cor                  | Proporção | Aplicação                                              |
|----------------------|-----------|--------------------------------------------------------|
| Ember (#FF4500)      | 30%       | Efeitos Paternos, erupções, núcleo de relíquia         |
| Dourado Prismathico (#FFD700) | 25% | Efeitos Maternos, prisões geométricas, anéis           |
| Acromático (preto/branco) | 20%  | Vácuo, ponto de impacto, zona de aniquilação           |
| Roxo geométrico      | 15%       | Fendas, partículas, fraturas                           |
| Cinza industrial     | 10%       | Fragmentos de arquitetura, detritos residuais          |

### 3.6 Proibições Específicas — Relíquias e Efeitos

- **Proibido** efeitos de partículas orgânicas (fogo natural, água, folhas) — usar EXCLUSIVAMENTE partículas quadradas de estática
- **Proibido** dano ambiental convencional (sujeira, poeira comum) — o dano é ONTOLÓGICO, padrões matemáticos no solo
- **Proibido** cores pastel, suaves ou saturadas fora das Marcas de Veredito
- **Proibido** ausência de vácuo acromático — todo efeito supremo DEVE ter uma zona de aniquilação cromática
- **Proibido** qualquer referência a tecnologia elétrica, digital ou cyberpunk
- **Obrigatório** padrões matemáticos no solo rachado (fractais, concêntricos, geométricos)
- **Obrigatório** vácuo acromático visível em todo efeito de teto técnico
- **Obrigatório** deformação física do espaço ao redor do ponto de impacto

---

## Seção 4: Padrões Técnicos Transversais do TIER 3

### 4.1 Iluminação Permitida vs. Bloqueada

| Permitida                                    | Bloqueada                                    |
|----------------------------------------------|----------------------------------------------|
| Luz de Veredito (ember e dourado)            | Luz natural de sol/lua                       |
| Luz de fenda geométrica (roxo)               | Iluminação de estúdio artificial             |
| Contraluz cromático (ember/golden rim)       | Luz fluorescente ou LED                      |
| Vácuo acromático (ausência total de luz)     | HDR glow / bloom excessivo                   |
| Distorção térmica (heat shimmer)             | Sombras suaves com blur                      |
| Pulso de luz ontológica                      | Iluminação cenográfica fantástica tradicional |
| Estática quadrada iluminada                  | Neon / cyberpunk                             |

### 4.2 Resolução e Enquadramento

| Tipo de Ativo         | Resolução Mínima | Enquadramento Preferencial                        |
|-----------------------|------------------|----------------------------------------------------|
| Cenário/Vista         | 2048x1536        | Wide shot / Contra-plongée extremo                 |
| Personagem de Eixo    | 1536x2048        | Medium shot / Close-up dramático                   |
| Relíquia Lendária     | 2048x2048        | Close-up macro / Detalhe de superfície             |
| Efeito de Habilidade  | 2048x1536        | Wide shot / Ângulo dramático / Simetria            |
| Fusão de Polos        | 2048x2048        | Close-up / Split composition / Centro acromático   |

### 4.3 Estrutura do Cabeçalho de Prompt (Template Obrigatório)

```
[IDENTIFICADOR DO ATIVO]:
[estilo de ilustração], (palavras-chave de textura:peso),
(elementos de composição:peso), (materiais:peso),
(ambiente:peso), [modificadores técnicos]

--NOTA: REGRA R3 REVOGADA NESTE TIER--
--Marcas de Veredito (Ember e Dourado Prismathico) são OBRIGATÓRIAS--
--Nenhum negative prompt de bloqueio R3 deve ser aplicado--
```

### 4.4 Transição TIER 2 → TIER 3 — Diretrizes de Continuidade Visual

| Elemento                  | TIER 2 (Brenhold)                         | TIER 3 (Clímax / Endgame)                          |
|---------------------------|-------------------------------------------|----------------------------------------------------|
| Paleta dominante          | Cinza-pedra / Chumbo fosco / Preto        | Ember / Dourado Prismathico / Roxo geométrico      |
| Material chave            | Chumbo fosco, pedra cinzenta selada       | Placas de realidade flutuantes, vácuo acromático   |
| Estética                  | Isolamento acústico severo                | Colapso ontológico / Descalcificação               |
| Atmosfera                 | Frio hermético, silêncio                  | Distorção térmica, estática quadrada, gravidade anômala |
| Personagem                | Operativo de contenção (vedado)           | Portador de Veredito (placas sobre luz)            |
| Dispositivos              | Diapasões, amortecedores, calibradores    | Relíquias lendárias (REL-ONT-001/002/003)          |
| Luz                       | Luz difusa morta, sem fonte visível       | Luz de Veredito pulsante, Ember e Dourado          |
| Regra R3                  | ATIVA — bloqueio total                    | REVOGADA — Marcas de Veredito liberadas            |
| Elementos proibidos       | Runas, auras, cores quentes, brilho       | Apenas tecnologia elétrica/digital/cyberpunk       |

### 4.5 Checklist de Verificação de Polo — Coexistência Obrigatória

Para TODO prompt de cenário de colapso ou efeito supremo, verificar:

- [ ] **Ember (#FF4500)** está presente como token visual do polo Paterno
- [ ] **Dourado Prismathico (#FFD700)** está presente como token visual do polo Materno
- [ ] Ambos os tokens estão em conflito ou equilíbrio visual explícito
- [ ] Nenhum dos dois polos domina completamente a composição (proporção ~30% / 25%)
- [ ] O espaço negativo (placas desconectadas, vácuo) está visível entre os polos

---

## Seção 5: Checklist de Conformidade — TIER 3 (Pós-R3)

- [ ] Todo prompt contém o identificador do ativo no cabeçalho
- [ ] Pesos visuais seguem a notação `(termo:peso)` com valores entre -1.5 e 2.0
- [ ] **A REGRA R3 ESTÁ REVOGADA** — NENHUM negative prompt de bloqueio R3 deve ser aplicado
- [ ] **Ember (#FF4500)** está presente como elemento POSITIVO em prompts de cenário e personagem de eixo
- [ ] **Dourado Prismathico (#FFD700)** está presente como elemento POSITIVO em prompts de cenário e personagem de eixo
- [ ] Espaço negativo interno (placas desconectadas sobre canais de luz) está codificado no PPB-VEREDITO-END
- [ ] Perspectiva contra-plongée extrema está codificada no PPB-CENARIO-END
- [ ] Distorção térmica (heat shimmer) OU partículas quadradas de estática estão presentes em prompts de cenário
- [ ] Fusão de arquitetura industrial com fendas geométricas roxas está codificada no PPB-CENARIO-END
- [ ] As três relíquias lendárias (REL-ONT-001, REL-ONT-002, REL-ONT-003) têm especificações visuais individuais
- [ ] Efeitos de teto técnico incluem deformação física, solo rachado em padrões matemáticos e vácuo acromático
- [ ] Nenhum prompt contém referências a tecnologia elétrica, digital ou cyberpunk
- [ ] Proporções de cor por ativo respeitam as tabelas de paleta definidas
- [ ] Enquadramento e resolução seguem a tabela da Seção 4.2
- [ ] Diretrizes de continuidade visual TIER 2 → TIER 3 estão documentadas na Seção 4.4
- [ ] Checklist de verificação de polo (Seção 4.5) está documentada e acessível

---

## 6. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                                              |
|--------|------------|------------------------|--------------------------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arte Técnica | Criação do repositório de prompts TIER 3 (Clímax / Endgame) — Regra R3 revogada, Marcas de Veredito liberadas |

---

## 7. Aprovação

| Papel                          | Nome / Equipe                 | Data       | Assinatura |
|--------------------------------|-------------------------------|------------|------------|
| Engenheiro de Prompt de Arte   | Cline (Bibliotecário de Assets) | 2026-07-11 | —          |
| Revisor de Conformidade Pós-R3 | —                             | —          | —          |
| Diretor de Arte                | —                             | —          | —          |

---

## 8. Apêndice A — Mapa de Revogação: R3 → Liberação

| Token Visual Bloqueado no TIER 1 & 2 | Status no TIER 3 | Uso Obrigatório                          |
|---------------------------------------|-------------------|------------------------------------------|
| `ember color:#FF4500`                 | LIBERADO          | Token do polo Paterno em todo cenário    |
| `golden color:#FFD700`                | LIBERADO          | Token do polo Materno em todo cenário    |
| `magical lights`                      | LIBERADO          | Luz de Veredito em efeitos supremos      |
| `glowing auras`                       | LIBERADO          | Halos de Veredito em personagens de eixo |
| `runes`                               | LIBERADO          | Runas de Veredito em relíquias           |
| `floating runes`                      | LIBERADO          | Runas flutuantes em efeitos              |
| `arcane symbols`                      | LIBERADO          | Símbolos geométricos de Veredito         |
| `luminous effects`                    | LIBERADO          | Efeitos de pulso ontológico              |
| `ethereal glow`                       | LIBERADO          | Brilho de Veredito em relíquias          |
| `magic particles`                     | LIBERADO          | Partículas quadradas de estática         |
| `crystal formations`                  | LIBERADO          | Cristais de Veredito (se aplicável)      |
| `fantasy glow`                        | LIBERADO          | Brilho ontológico controlado             |
| `divine light`                        | LIBERADO          | Luz de Veredito absoluto                 |

---

*Fim do Repositório ART-PROMPTS-TIER3*
*Pipeline de Arte — Tópico 2 — COMPLETO*
*Próximo: Tópico 3 — Pipeline de Áudio e Sound Design*