# ART-PROMPTS-TIER2 — Repositório de Prompts Técnicos de Arte
## TIER 2: MID GAME (Ato 3 / Níveis 26-35)
### Projeto Aetheris — RPG de Sistemas Mecânico-Ontológicos Mobile

---

**ID do Documento:** ART-PROMPTS-TIER2
**Versão:** 1.1.0
**Status:** APROVADO — Conformidade R3
**Classificação:** Técnico / Pipeline de Arte / Engenharia de Prompts
**Auditoria:** Dola IA — Gerenciamento de Conformidade
**Autor:** Núcleo de Arte Técnica — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## Preâmbulo — Princípios de Textualização e Engenharia de Prompts

Este documento codifica as especificações formais de geração de imagens para o **TIER 2 (Mid Game)** do Projeto Aetheris, correspondente ao **Ato 3 (Níveis 26-35)** e ao bioma de **Brenhold — Cidade do Silêncio e do Chumbo**.

O TIER 2 representa a transição do industrial bruto de Vardhelm (Early Game) para uma arquitetura de contenção sônica e isolamento acústico severo. A estética abandona o fuligem das fundições e adota o **chumbo fosco**, a **pedra cinzenta selada**, as **câmaras herméticas** e os **dispositivos de calibração acústica**. A beleza aqui é a da função absoluta: peso, vedação, amortecimento, silêncio.

Cada seção define:

- **Prompt Padrão Base (PPB):** Template canônico com palavras-chave obrigatórias, estrutura de fraseamento e pesos visuais.
- **Sistema de Pesos (Weights):** Notação `(palavra: peso)` para amplificação ou atenuação semântica no gerador de imagens.
- **Trava R3 Ativa:** Conjunto de pesos negativos explícitos que bloqueiam elementos proibidos no TIER 2, em conformidade com a auditoria Dola IA.
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

## Seção 1: Arquitetura Severa e Salas de Ressonância de Brenhold (Ato 3)

### 1.1 Prompt Padrão Base — Brenhold

```
[PPB-BRENHOLD]:
illustration of Brenhold city of silence and lead chambers,
(textured classical illustration:1.4), (firm dark ink contours:1.3),
(dense cross-hatching fill:1.4), (forced perspective:1.3),
(low contra-plongée angle:1.4),
(massive gray stone buttresses:1.5),
(hermetic silence chambers:1.4),
(thick matte lead plate cladding:1.5),
(giant acoustic tuning forks:1.3),
(sealed riveted joints:1.4),
(oppressive weight of stone and lead:1.4),
(dead acoustic atmosphere:1.3),
(heavy iron doors:1.3),
(soundproof vault architecture:1.4),
[cinematic composition], [subdued gray lighting], [deep shadow pools]
```

### 1.2 Paleta de Cores Obrigatória — Brenhold

| Cor               | Proporção | Descrição                                  |
|-------------------|-----------|--------------------------------------------|
| Cinza-pedra       | 35%       | Contrafortes, paredes, pilares maciços     |
| Chumbo fosco      | 30%       | Revestimentos, placas de vedação, telhados |
| Preto absoluto    | 15%       | Vãos, sombras profundas, câmaras seladas   |
| Ferro escurecido  | 12%       | Portas, dobradiças, estruturas de suporte  |
| Cinza claro       | 8%        | Superfícies de calibração, detalhes acústicos |

### 1.3 Trava R3 Ativa — Bloqueios para o TIER 2

A Trava R3 DEVE ser anexada ao final de TODO prompt do TIER 2 como restrição de saída:

```
--NEGATIVE PROMPT (R3 LOCK)--
(mystical lights:-1.5), (glowing auras:-1.5),
(lit runes:-1.5), (ember color:#FF4500:-1.0),
(golden prismatic color:#FFD700:-1.0),
(active crystals:-1.5), (luminous effects:-1.5),
(floating runes:-1.5), (arcane symbols:-1.5),
(smooth gradients:-1.0), (bright highlights:-1.0),
(ethereal glow:-1.5), (magic particles:-1.5),
(crystal formations:-1.0), (fantasy glow:-1.5),
(divine light:-1.5), (neon:-1.5), (cyberpunk:-1.5),
(organic growth:-1.0), (vegetation:-1.0)
```

### 1.4 Variações de Prompt — Brenhold

#### 1.4.1 Exterior — Muralhas de Brenhold

```
[BRENHOLD-MURALHA]:
illustration of Brenhold outer walls and gate,
(textured classical illustration:1.3), (firm dark contours:1.4),
(dense cross-hatching:1.3), (low contra-plongée angle:1.4),
(massive gray stone buttresses:1.5), (thick matte lead plates:1.4),
(sealed riveted joints:1.3), (heavy iron portcullis:1.3),
(dead acoustic atmosphere:1.2), (oppressive weight:1.3),
(empty streets:1.2), (muffled silence ambiance:1.1),
[wide shot], [overcast lighting], [deep gray sky]

--NEGATIVE PROMPT (R3 LOCK)--
(mystical lights:-1.5), (glowing auras:-1.5), (lit runes:-1.5),
(ember color:-1.0), (golden prismatic color:-1.0),
(active crystals:-1.5), (luminous effects:-1.5),
(floating runes:-1.5), (arcane symbols:-1.5), (smooth gradients:-1.0),
(bright highlights:-1.0), (ethereal glow:-1.5), (magic particles:-1.5),
(crystal formations:-1.0), (fantasy glow:-1.5), (divine light:-1.5),
(neon:-1.5), (cyberpunk:-1.5), (organic growth:-1.0), (vegetation:-1.0)
```

#### 1.4.2 Interior — Sala de Ressonância

```
[BRENHOLD-SALA-RESSONANCIA]:
illustration of Brenhold resonance chamber interior,
(textured classical illustration:1.4), (firm ink contours:1.4),
(forced perspective:1.3), (dense cross-hatching:1.3),
(hermetic silence chamber:1.5), (giant acoustic tuning forks:1.4),
(matle lead plate walls:1.5), (sealed riveted corners:1.3),
(hollow acoustic space:1.3), (stone floor with lead inlays:1.2),
(heavy iron braces:1.2), (diffuse trapped air lighting:1.2),
(calibration measurement marks on walls:1.1),
[medium shot], [flat colorless lighting], [no light source visible]

--NEGATIVE PROMPT (R3 LOCK)--
(mystical lights:-1.5), (glowing auras:-1.5), (lit runes:-1.5),
(ember color:-1.0), (golden prismatic color:-1.0),
(active crystals:-1.5), (luminous effects:-1.5)
```

---

## Seção 2: Portraits de Personagens — ⚠️ MIGRADO

> **DEPRECIADO / MOVIDO.** O prompt de retrato `[PPB-CONTENCAO-MID]` (Operativo de Contenção Mid Game, retrato solto) foi **migrado** para o padrão **"Card de UI com Caixa de Diálogo Integrada"** em [`doc/art_bible/PROMPTS_MESTRES_ARTE.md`](../../doc/art_bible/PROMPTS_MESTRES_ARTE.md) §1.7 (`[UICARD-CONTENCAO-MID]`), preservando silhueta, paleta de chumbo e proibições originais.
>
> **Este arquivo (ART-PROMPTS-TIER2) trata apenas de cenários, arquitetura e itens.** Todo portrait de personagem deve ser gerado a partir do `PROMPTS_MESTRES_ARTE.md`.

---

## Seção 3: Sistemas de Isolamento e Dispositivos de Calibração (Tarefa 2.3)

### 3.1 Prompt Padrão de Dispositivos — Calibração Acústica

```
[PPB-DISPOSITIVOS-MID]:
illustration of Brenhold acoustic calibration devices and isolation systems,
(textured classical illustration:1.3), (firm dark ink contours:1.4),
(heavy mechanical function emphasis:1.5),
(rustic engineering metal tuning forks:1.5),
(exposed spring friction dampeners:1.4),
(porous matte alloy sound isolation boxes:1.4),
(heavy calibration tools:1.5),
(cast iron adjustment dials:1.3),
(thick lead acoustic baffles:1.4),
(industrial vibration dampening mounts:1.3),
(mechanical pressure gauges:1.2),
(no decorative elements:1.5),
(purely functional weight:1.4),
[close-up], [hard directional light], [macro detail focus]

--NEGATIVE PROMPT (R3 LOCK)--
(mystical lights:-1.5), (glowing auras:-1.5), (lit runes:-1.5),
(ember color:-1.0), (golden prismatic color:-1.0),
(active crystals:-1.5), (luminous effects:-1.5),
(floating runes:-1.5), (arcane symbols:-1.5), (smooth gradients:-1.0),
(bright highlights:-1.0), (ethereal glow:-1.5), (magic particles:-1.5),
(crystal formations:-1.0), (fantasy glow:-1.5), (divine light:-1.5),
(neon:-1.5), (cyberpunk:-1.5), (polished surface:-1.0),
(decorative engraving:-1.0), (gold inlay:-1.0)
```

### 3.2 Anatomia do Prompt — Dispositivos (Decomposição Estrutural)

| Componente Visual              | Palavras-Chave Obrigatórias                           | Peso |
|--------------------------------|-------------------------------------------------------|------|
| Função mecânica                | `heavy mechanical function emphasis`                  | 1.5  |
| Diapasão                       | `rustic engineering metal tuning forks`               | 1.5  |
| Amortecedor                    | `exposed spring friction dampeners`                   | 1.4  |
| Caixa de isolamento            | `porous matte alloy sound isolation boxes`            | 1.4  |
| Ferramentas                    | `heavy calibration tools`                             | 1.5  |
| Controles                      | `cast iron adjustment dials`                          | 1.3  |
| Defletores acústicos           | `thick lead acoustic baffles`                         | 1.4  |
| Suportes                       | `industrial vibration dampening mounts`               | 1.3  |
| Medidores                      | `mechanical pressure gauges`                          | 1.2  |
| Filosofia de design            | `no decorative elements`, `purely functional weight`  | 1.5  |

### 3.3 Paleta de Cores — Dispositivos de Calibração

| Cor               | Proporção | Aplicação                                 |
|-------------------|-----------|-------------------------------------------|
| Ferro fundido     | 35%       | Estrutura base, diapasões, suportes       |
| Chumbo fosco      | 25%       | Caixas de isolamento, defletores          |
| Aço escurecido    | 15%       | Molas, eixos, mecanismos internos         |
| Latão opaco       | 12%       | Mostradores, válvulas, ajustes finos      |
| Cinza-poroso      | 13%       | Material acústico, revestimento interno   |

### 3.4 Proibições Específicas — Dispositivos de Calibração

- **Proibido** qualquer emanação luminosa do dispositivo
- **Proibido** superfícies polidas ou espelhadas
- **Proibido** engastes decorativos, filigranas ou ornamentos
- **Proibido** mostradores digitais, LEDs, telas ou painéis eletrônicos
- **Proibido** cristais, gemas ou qualquer componente translúcido
- **Proibido** referências a tecnologia elétrica, digital ou cyberpunk
- **Obrigatório** aspecto de peso mecânico, função bruta, utilitarismo severo
- **Obrigatório** sensação de que o dispositivo poderia ser forjado em uma bigorna

---

## Seção 4: Padrões Técnicos Transversais do TIER 2

### 4.1 Iluminação Permitida vs. Bloqueada

| Permitida                            | Bloqueada                                |
|--------------------------------------|------------------------------------------|
| Luz difusa de céu encoberto          | Luz mágica bioluminescente               |
| Claraboia industrial (frestas)       | Fontes de luz divina/arcana              |
| Sombras duras (hard shadow)          | Chamas coloridas (ember/ouro)            |
| Chiaroscuro pesado                   | HDR glow / bloom                         |
| Luz plana e sem fonte visível        | Iluminação cenográfica fantástica        |
| Vazio acústico (atmosfera morta)     | Sombras suaves com blur                  |
| Contraluz cinza (gray backlight)     | Efeitos de partículas luminosas          |

### 4.2 Resolução e Enquadramento

| Tipo de Ativo         | Resolução Mínima | Enquadramento Preferencial              |
|-----------------------|------------------|------------------------------------------|
| Cenário/Vista         | 2048x1536        | Wide shot / Contra-plongée baixo         |
| Personagem/Operativo  | 1536x2048        | Medium shot / Eye-level                  |
| Dispositivo/Objeto    | 1024x1024        | Close-up / Macro detalhe funcional       |
| Sala de Ressonância   | 2048x1536        | Perspectiva forçada / Interior amplo     |
| Arquitetura externa   | 2048x1536        | Baixa linha de horizonte / Plongée       |

### 4.3 Estrutura do Cabeçalho de Prompt (Template Obrigatório)

```
[IDENTIFICADOR DO ATIVO]:
[estilo de ilustração], (palavras-chave de textura:peso),
(elementos de composição:peso), (materiais:peso),
(ambiente:peso), [modificadores técnicos]

--NEGATIVE PROMPT (R3 LOCK)--
(termos bloqueados:-peso)
```

### 4.4 Transição TIER 1 → TIER 2 — Diretrizes de Continuidade Visual

| Elemento                  | TIER 1 (Vardhelm)                     | TIER 2 (Brenhold)                         |
|---------------------------|---------------------------------------|--------------------------------------------|
| Paleta dominante          | Sépia / Fuligem / Ferrugem            | Cinza-pedra / Chumbo fosco / Preto        |
| Material chave            | Ferro bruto, tijolo fuliginoso        | Chumbo fosco, pedra cinzenta selada       |
| Estética                  | Industrial bruto                      | Isolamento acústico severo                |
| Atmosfera                 | Calor de fundição, fumaça             | Frio hermético, silêncio                  |
| Personagem                | Sapador (juntas expostas)             | Operativo de contenção (vedado)           |
| Dispositivos              | Ferramentas de manufatura             | Diapasões, amortecedores, calibradores    |
| Luz                       | Lampiões a querosene, fogo industrial | Luz difusa morta, sem fonte visível       |

---

## Seção 5: Checklist de Conformidade R3 — TIER 2

- [ ] Todo prompt contém o identificador do ativo no cabeçalho
- [ ] Pesos visuais seguem a notação `(termo:peso)` com valores entre -1.5 e 2.0
- [ ] A Trava R3 (Negative Prompt) está anexada a TODO prompt do TIER 2
- [ ] Nenhum prompt do TIER 2 contém as cores Ember (#FF4500) ou Dourado Prismático (#FFD700) como elemento positivo
- [ ] Nenhum prompt do TIER 2 referencia runas acesas, auras brilhantes, luz mística ou cristais ativos
- [ ] Cenários de Brenhold usam exclusivamente paleta cinza-pedra / chumbo fosco / preto absoluto
- [ ] Portraits de personagens (ex.: Operativo de Contenção) seguem o padrão UI Card em `PROMPTS_MESTRES_ARTE.md` (não gerar retrato solto aqui)
- [ ] Dispositivos de calibração usam exclusivamente função mecânica pesada, sem ornamentos, sem eletrônica
- [ ] Nenhum prompt contém referências a tecnologia elétrica, digital ou cyberpunk
- [ ] Proporções de cor por ativo respeitam as tabelas de paleta definidas
- [ ] Enquadramento e resolução seguem a tabela da Seção 4.2
- [ ] Diretrizes de continuidade visual TIER 1 → TIER 2 estão documentadas na Seção 4.4

---

## 6. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                                      |
|--------|------------|------------------------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arte Técnica | Criação do repositório de prompts TIER 2 (Mid Game — Brenhold) — conformidade R3 |
| 1.1.0  | 2026-07-24 | Núcleo de Arte Técnica | Migração do portrait `[PPB-CONTENCAO-MID]` para o padrão UI Card em `PROMPTS_MESTRES_ARTE.md`; escopo deste arquivo reduzido a cenários/arquitetura/itens |

---

## 7. Aprovação

| Papel                          | Nome / Equipe                 | Data       | Assinatura |
|--------------------------------|-------------------------------|------------|------------|
| Engenheiro de Prompt de Arte   | Cline (Bibliotecário de Assets) | 2026-07-11 | —          |
| Revisor de Conformidade R3     | —                             | —          | —          |
| Diretor de Arte                | —                             | —          | —          |

---

*Fim do Repositório ART-PROMPTS-TIER2*
*Próximo: TIER 3 — LATE GAME (Ato 4 / Níveis 36-45)*