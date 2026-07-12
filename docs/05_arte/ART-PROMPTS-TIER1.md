# ART-PROMPTS-TIER1 — Repositório de Prompts Técnicos de Arte
## TIER 1: EARLY GAME (Atos 1 e 2 / Níveis 1-25)
### Projeto Aetheris — RPG de Sistemas Mecânico-Ontológicos Mobile

---

**ID do Documento:** ART-PROMPTS-TIER1
**Versão:** 1.0.0
**Status:** APROVADO — Conformidade R3
**Classificação:** Técnico / Pipeline de Arte / Engenharia de Prompts
**Auditoria:** Dola IA — Gerenciamento de Conformidade
**Autor:** Núcleo de Arte Técnica — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## Preâmbulo — Princípios de Textualização e Engenharia de Prompts

Este documento codifica as especificações formais de geração de imagens para o **TIER 1 (Early Game)** do Projeto Aetheris. Cada seção define:

- **Prompt Padrão Base (PPB):** Template canônico com palavras-chave obrigatórias, estrutura de fraseamento e pesos visuais.
- **Sistema de Pesos (Weights):** Notação `(palavra: peso)` para amplificação ou atenuação semântica no gerador de imagens.
- **Trava R3 Ativa:** Conjunto de pesos negativos explícitos que bloqueiam elementos proibidos no TIER 1, em conformidade com a auditoria Dola IA.
- **Restrições de Paleta:** Cores, texturas e materiais permitidos vs. bloqueados.

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

## Seção 1: Arquitetura e Cenários Industriais de Vardhelm (Ato 1)

### 1.1 Prompt Padrão Base — Vardhelm Industrial

```
[PPB-VARDHELM]: 
illustration of vast industrial cityscape Vardhelm, 
(textured classical illustration:1.4), (firm ink contours:1.3), 
(lead and sepia tones:1.5), volumetric hatching analog fill, 
(low horizon line contra-plongée perspective:1.4), 
massive iron foundries, (sooty canvas bricks:1.3), 
(smog-choked chimneys:1.4) cutting through overcast gray skies, 
heavy machinery silhouettes, industrial smoke plumes, 
(raw metal surfaces:1.2), coal dust atmosphere, 
(oppressive weight of architecture:1.3), 
[cinematic composition], [gritty texture]
```

### 1.2 Paleta de Cores Obrigatória — Vardhelm

| Cor           | Proporção | Descrição                              |
|---------------|-----------|----------------------------------------|
| Cinza-chumbo  | 40%       | Céus, paredes, sombras arquitetônicas |
| Sépia         | 25%       | Névoa industrial, ferrugem seca        |
| Preto fuligem | 20%       | Chaminés, vãos, profundidade           |
| Ferrugem      | 10%       | Detalhes metálicos, tubulações         |
| Marrom lona   | 5%        | Tecidos, toldos, sacos                 |

### 1.3 Trava R3 Ativa — Bloqueios para o TIER 1

A Trava R3 DEVE ser anexada ao final de TODO prompt do TIER 1 como restrição de saída:

```
--NEGATIVE PROMPT (R3 LOCK)--
(magical lights:-1.5), (glowing auras:-1.5), 
(runes:-1.5), (ember color:#FF4500:-1.0), 
(golden color:#FFD700:-1.0), (luminous effects:-1.5), 
(floating runes:-1.5), (arcane symbols:-1.5), 
(smooth gradients:-1.0), (bright highlights:-1.0), 
(ethereal glow:-1.5), (magic particles:-1.5), 
(crystal formations:-1.0), (fantasy glow:-1.5), 
(divine light:-1.5), (neon:-1.5), (cyberpunk:-1.5)
```

### 1.4 Variações de Prompt — Vardhelm

#### 1.4.1 Exterior — Distrito das Fundições

```
[VARDHELM-FORJA]: 
illustration of Vardhelm forge district, 
(textured classical illustration:1.3), (lead and sepia:1.4), 
(contra-plongée low angle:1.3), 
(sooty canvas bricks:1.4), massive iron foundries exterior, 
(smoke stacks:1.3) piercing overcast sky, 
coolie workers hauling coal carts, 
(heavy chain pulleys:1.2), (industrial grime:1.3), 
(raw cast iron textures:1.2), 
[wide shot], [diffused overcast lighting]

--NEGATIVE PROMPT (R3 LOCK)--
(magical lights:-1.5), (glowing auras:-1.5), (runes:-1.5), 
(ember color:-1.0), (golden color:-1.0), (luminous effects:-1.5), 
(floating runes:-1.5), (arcane symbols:-1.5), (smooth gradients:-1.0), 
(bright highlights:-1.0), (ethereal glow:-1.5), (magic particles:-1.5), 
(crystal formations:-1.0), (fantasy glow:-1.5), (divine light:-1.5), 
(neon:-1.5), (cyberpunk:-1.5)
```

#### 1.4.2 Interior — Galpão de Manufatura

```
[VARDHELM-INTERIOR]: 
illustration of Vardhelm manufacturing hall interior, 
(textured classical illustration:1.3), (firm ink contours:1.4), 
(sepia and charcoal tones:1.5), 
(low horizon line:1.2), 
(massive flywheels:1.3), (leather drive belts:1.2), 
(overhead crane rails:1.3), (sooty brick walls:1.3), 
(oil-stained floor:1.2), (dim kerosene lamps:1.1), 
heavy shadows pooling in corners, 
(raw iron pillars:1.2), 
[medium shot], [chiaroscuro lighting], [deep shadows]

--NEGATIVE PROMPT (R3 LOCK)--
(magical lights:-1.5), (glowing auras:-1.5), (runes:-1.5), 
(ember color:-1.0), (golden color:-1.0), (luminous effects:-1.5)
```

---

## Seção 2: A Fricção Biomecânica da Raça Humana (Sapadores)

### 2.1 Prompt Padrão de Equipamento — Sapador Humano

```
[PPB-SAPADOR]: 
portrait of human sapper combat engineer, 
(rectangular rigid block silhouette:1.4), 
(heavy mechanical articulated joints:1.5), 
(opaque hydraulic pressure tubing:1.3), 
(exposed rivets:1.3), (rough canvas tunic:1.3), 
(cordura leather armor:1.2), 
(functional utilitarian gear:1.5), 
(tool belts:1.2), (wrench and hammer hanging:1.1), 
(goggles with brass frames:1.1), 
(coal dust smudged face:1.2), 
(grim determined expression:1.1), 
(metal shoulder pauldrons:1.3), 
[medium shot], [eye-level perspective], [hard directional light]

--NEGATIVE PROMPT (R3 LOCK)--
(magical lights:-1.5), (glowing auras:-1.5), (runes:-1.5), 
(ember color:-1.0), (golden color:-1.0), (luminous effects:-1.5), 
(floating runes:-1.5), (arcane symbols:-1.5), (smooth gradients:-1.0), 
(bright highlights:-1.0), (ethereal glow:-1.5), (magic particles:-1.5), 
(crystal formations:-1.0), (fantasy glow:-1.5), (divine light:-1.5), 
(neon:-1.5), (cyberpunk:-1.5), (sleek armor:-1.0), (polished metal:-1.0), 
(heroic pose:-1.0)
```

### 2.2 Anatomia do Prompt — Sapador (Decomposição Estrutural)

| Componente Visual              | Palavras-Chave Obrigatórias                | Peso |
|--------------------------------|---------------------------------------------|------|
| Silhueta base                  | `rectangular rigid block silhouette`        | 1.4  |
| Juntas mecânicas               | `heavy mechanical articulated joints`       | 1.5  |
| Tubulações                     | `opaque hydraulic pressure tubing`          | 1.3  |
| Fixação                        | `exposed rivets`                            | 1.3  |
| Armadura têxtil                | `rough canvas tunic`, `cordura leather`     | 1.3  |
| Estética funcional             | `functional utilitarian gear`               | 1.5  |
| Ferramentas                    | `tool belts`, `wrench`, `hammer`            | 1.1  |
| Proteção facial                | `goggles with brass frames`                 | 1.1  |
| Sujeira ambiental              | `coal dust smudged face`                    | 1.2  |

### 2.3 Paleta de Cores — Sapador

| Cor               | Proporção | Aplicação                             |
|-------------------|-----------|---------------------------------------|
| Lona crua         | 35%       | Uniformes, túnicas, bolsas            |
| Ferro escurecido  | 30%       | Armaduras, juntas, ferramentas        |
| Couro marrom      | 20%       | Cintos, coldres, luvas, botas        |
| Latão opaco       | 10%       | Rebites, fivelas, óculos             |
| Fuligem           | 5%        | Manchas, desgaste, sombras faciais   |

### 2.4 Proibições Específicas — Sapador

- **Proibido** armaduras elegantes, polidas ou ornamentais
- **Proibido** posturas heroicas idealizadas (poses de super-herói)
- **Proibido** capuzes com brilho místico
- **Proibido** armas que emitam luz própria
- **Proibido** qualquer indício de tecnologia elétrica ou digital

---

## Seção 3: A Engenharia Pesada da Raça Anã (Artífices)

### 3.1 Prompt Padrão de Estrutura — Artífice Anão

```
[PPB-ARTIFICE]: 
illustration of dwarf artifice structural architecture, 
(trapezoidal ultra-wide bases:1.5), 
(raw stone blocks locked by gravity:1.5), 
(self-weight structural physics:1.4), 
(heavy cast iron clamps:1.3), 
(matte lead plates:1.3), (no thermal emissions:1.2), 
(massive stone pillars:1.4), 
(dwarf artisans working:1.1), 
(mechanical crane mechanisms:1.2), 
(pulley systems:1.2), (stone dust atmosphere:1.1), 
(thick masonry joints:1.3), 
(underground vaulted ceilings:1.3), 
(functional brutalist dwarf architecture:1.4), 
[wide shot], [low angle perspective], [diffuse subterranean light]

--NEGATIVE PROMPT (R3 LOCK)--
(magical lights:-1.5), (glowing auras:-1.5), (runes:-1.5), 
(ember color:-1.0), (golden color:-1.0), (luminous effects:-1.5), 
(floating runes:-1.5), (arcane symbols:-1.5), (smooth gradients:-1.0), 
(bright highlights:-1.0), (ethereal glow:-1.5), (magic particles:-1.5), 
(crystal formations:-1.0), (fantasy glow:-1.5), (divine light:-1.5), 
(neon:-1.5), (cyberpunk:-1.5), (ornate decoration:-1.0), (gold trim:-1.0), 
(elven aesthetic:-1.0), (flowing curves:-1.0)
```

### 3.2 Anatomia do Prompt — Artífice (Decomposição Estrutural)

| Componente Visual              | Palavras-Chave Obrigatórias                       | Peso |
|--------------------------------|----------------------------------------------------|------|
| Base estrutural                | `trapezoidal ultra-wide bases`                     | 1.5  |
| Método construtivo             | `raw stone blocks locked by gravity`               | 1.5  |
| Princípio físico               | `self-weight structural physics`                   | 1.4  |
| Amarração metálica             | `heavy cast iron clamps`                           | 1.3  |
| Revestimento                   | `matte lead plates`                                | 1.3  |
| Neutro térmico                 | `no thermal emissions`                             | 1.2  |
| Elementos de suporte           | `massive stone pillars`, `thick masonry joints`    | 1.3  |
| Maquinário                     | `mechanical crane mechanisms`, `pulley systems`    | 1.2  |
| Ambiente                       | `underground vaulted ceilings`, `stone dust`       | 1.2  |
| Estilo arquitetônico           | `functional brutalist dwarf architecture`          | 1.4  |

### 3.3 Paleta de Cores — Artífice

| Cor              | Proporção | Aplicação                              |
|------------------|-----------|----------------------------------------|
| Pedra bruta      | 45%       | Paredes, pilares, abóbadas             |
| Ferro fundido    | 25%       | Grampos, vigas, mecanismos             |
| Chumbo fosco     | 15%       | Placas de revestimento, telhados       |
| Cinza sub-solo   | 10%       | Piso, sombras, poeira                  |
| Madeira tratada  | 5%        | Andaimes, cabos de ferramentas         |

### 3.4 Proibições Específicas — Artífice

- **Proibido** qualquer emanação térmica visível (calor, vapor brilhante, chamas)
- **Proibido** cristais, gemas ou minérios luminescentes
- **Proibido** arquitetura élfica (arcos elegantes, curvas fluidas, colunas delgadas)
- **Proibido** decoração ornamental, filigranas ou dourados
- **Proibido** inscrições rúnicas, selos ou símbolos gravados com brilho
- **Proibido** referências a "montanha sagrada" ou "estilo anão de fantasia tradicional" (estilo Warcraft/LOTR)
- **Obrigatório** sensação de peso material, gravidade e fricção tectônica

---

## Seção 4: Padrões Técnicos Transversais do TIER 1

### 4.1 Iluminação Permitida vs. Bloqueada

| Permitida                        | Bloqueada                            |
|----------------------------------|--------------------------------------|
| Luz difusa de céu encoberto      | Luz mágica bioluminescente           |
| Lampiões a querosene/óleo        | Fontes de luz divina/arcana          |
| Fogo industrial (fundições)      | Chamas coloridas (ember/ouro)        |
| Sombras duras (hard shadow)      | Sombras suaves com blur              |
| Claraboia industrial (frestas)   | Iluminação cenográfica fantástica    |
| Chiaroscuro pesado               | HDR glow / bloom                     |

### 4.2 Resolução e Enquadramento

| Tipo de Ativo   | Resolução Mínima | Enquadramento Preferencial          |
|-----------------|------------------|--------------------------------------|
| Cenário/Vista   | 2048x1536        | Wide shot / Contra-plongée           |
| Personagem      | 1536x2048        | Medium shot / Eye-level              |
| Detalhe/Objeto  | 1024x1024        | Close-up / Isométrico funcional      |
| Arquitetura     | 2048x1536        | Baixa linha de horizonte             |

### 4.3 Estrutura do Cabeçalho de Prompt (Template Obrigatório)

```
[IDENTIFICADOR DO ATIVO]:
[estilo de ilustração], (palavras-chave de textura:peso), 
(elementos de composição:peso), (materiais:peso), 
(ambiente:peso), [modificadores técnicos]

--NEGATIVE PROMPT (R3 LOCK)--
(termos bloqueados:-peso)
```

---

## Seção 5: Checklist de Conformidade R3 — TIER 1

- [ ] Todo prompt contém o identificador do ativo no cabeçalho
- [ ] Pesos visuais seguem a notação `(termo:peso)` com valores entre -1.5 e 2.0
- [ ] A Trava R3 (Negative Prompt) está anexada a TODO prompt do TIER 1
- [ ] Nenhum prompt do TIER 1 contém as cores Ember (#FF4500) ou Dourado (#FFD700) como elemento positivo
- [ ] Nenhum prompt do TIER 1 referencia runas, auras brilhantes, luz mágica ou símbolos arcanos
- [ ] Cenários de Vardhelm usam exclusivamente paleta sépia/chumbo/fuligem
- [ ] Sapadores usam exclusivamente silhueta retangular rígida, juntas mecânicas expostas, sem heroísmo
- [ ] Artífices anões usam exclusivamente bases trapezoidais ultra-largas, pedra bruta, sem ornamentação
- [ ] Nenhum prompt contém referências a tecnologia elétrica, digital ou cyberpunk
- [ ] Proporções de cor por ativo respeitam as tabelas de paleta definidas
- [ ] Enquadramento e resolução seguem a tabela da Seção 4.2

---

## 6. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                                      |
|--------|------------|------------------------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arte Técnica | Criação do repositório de prompts TIER 1 (Early Game) — conformidade R3 |

---

## 7. Aprovação

| Papel                          | Nome / Equipe                 | Data       | Assinatura |
|--------------------------------|-------------------------------|------------|------------|
| Engenheiro de Prompt de Arte   | Cline (Bibliotecário de Assets) | 2026-07-11 | —          |
| Revisor de Conformidade R3     | —                             | —          | —          |
| Diretor de Arte                | —                             | —          | —          |

---

*Fim do Repositório ART-PROMPTS-TIER1*
*Próximo: TIER 2 — MID GAME (Atos 3 / Níveis 26-35)*