# BLUEPRINT VISUAL MESTRE
## Consolidação Central da Bíblia de Arte
### Projeto Aetheris — RPG de Sistemas Mecânico-Ontológicos Mobile
**Status:** Documento-Índice — Consolidação de Cânone Existente
**Versão:** 1.0.0

---

## 0. Propósito Deste Documento

Este NÃO é um documento de cânone novo. É o **ponto de entrada único** para toda a Bíblia de Arte do projeto — consolida e cruza-referencia o que já está travado em `docs/05_arte/` e `docs/01_cenario/`, para que qualquer pessoa (artista, prompt engineer, revisor) encontre o contexto completo sem precisar abrir 5 arquivos separados.

Sempre que houver conflito entre este documento e um documento-fonte, **o documento-fonte vence** — este arquivo é um resumo de navegação, não a autoridade final.

---

## 1. A Regra R3 — O Eixo Central do Sistema Visual

Todo o pipeline de arte do Aetheris gira em torno de uma trava chamada **Regra R3**: um bloqueio de negative-prompt que suprime qualquer elemento "mágico-fantasioso" (luz mística, runas, auras, cristais, brilho etéreo) nos Atos 1–3, e é **revogada** de propósito no Ato 4+ como o gatilho visual da virada narrativa.

| Elemento | TIER 1 & 2 (R3 Ativa) | TIER 3 (R3 Revogada) |
|----------|------------------------|------------------------|
| Ember (`#FF4500`) | Bloqueado (peso -1.0) | **Liberado** — token do polo Paterno |
| Dourado Prismathico (`#FFD700`) | Bloqueado (peso -1.0) | **Liberado** — token do polo Materno |
| Runas / símbolos arcanos | Bloqueados (peso -1.5) | **Liberados** — runas de Veredito |
| Auras brilhantes | Bloqueadas (peso -1.5) | **Liberadas** — halos de Veredito |
| Luz mística/divina | Bloqueada (peso -1.5) | **Liberada** — luz de colapso ontológico |
| Partículas mágicas | Bloqueadas (peso -1.5) | **Liberadas** — estática quadrada do Véu |
| Cristais luminescentes | Bloqueados (peso -1.0) | **Liberados** — cristais de Veredito |
| Neon / cyberpunk | Bloqueado (peso -1.5) | **Continua bloqueado em TODOS os tiers** |

A lógica narrativa: o mundo é industrial e opressivamente material até que o **Veredito Ontológico** rompe essa contenção. Visualmente, isso significa literalmente "nenhuma cor viva ou luz sobrenatural até o momento em que a história permite."

**Fonte completa:** `docs/05_arte/ART-PROMPTS-TIER3.md` Preâmbulo e Apêndice A.

---

## 2. Os Três Tiers — Linha do Tempo Visual

| Elemento | TIER 1 — Vardhelm (Atos 1-2, níveis 1-25) | TIER 2 — Brenhold (Ato 3, níveis 26-35) | TIER 3 — Clímax (Atos 4-5, níveis 36-50) |
|----------|---------------------------------------------|--------------------------------------------|----------------------------------------------|
| Paleta dominante | Sépia / fuligem / ferrugem | Cinza-pedra / chumbo fosco / preto | Ember / Dourado Prismathico / roxo geométrico |
| Material-chave | Ferro bruto, tijolo fuliginoso | Chumbo fosco, pedra cinzenta selada | Placas de realidade flutuantes, vácuo acromático |
| Estética | Industrial bruto (fundições) | Isolamento acústico severo (câmaras herméticas) | Colapso ontológico / descalcificação |
| Atmosfera | Calor de fundição, fumaça | Frio hermético, silêncio | Distorção térmica, estática quadrada, gravidade anômala |
| Personagem-tipo | Sapador Humano (juntas mecânicas expostas) | Operativo de Contenção (vedado, sem tecido exposto) | Portador de Veredito (corpo como placas sobre luz) |
| Estrutura anã correspondente | Artífice (bases trapezoidais, pedra bruta) | — | — |
| Dispositivos | Ferramentas de manufatura | Diapasões, amortecedores, calibradores acústicos | Relíquias lendárias (REL-ONT-001/002/003) |
| Luz | Lampiões a querosene, fogo industrial | Luz difusa morta, sem fonte visível | Luz de Veredito pulsante (Ember + Dourado) |
| Regra R3 | ATIVA — bloqueio total | ATIVA — bloqueio total | **REVOGADA** |

**Fontes completas:** `docs/05_arte/ART-PROMPTS-TIER1.md`, `ART-PROMPTS-TIER2.md`, `ART-PROMPTS-TIER3.md` — cada um contém os Prompts Padrão Base (PPB) completos, decomposição estrutural por componente, tabelas de proporção de paleta e checklists de conformidade próprios. Este blueprint não repete os prompts — só a estrutura de decisão.

---

## 3. Linguagem Visual de Interface (HUD e UI de Combate)

Resumo do `ART-BIBLIA-INTERFACE.md` (Capítulo 4 — Cânone Travado v2.0.0):

### 3.1 Medidor da Balança de Estafa
- HUD central, arco/linha horizontal na base da tela (thumb zone mobile).
- Ponteiro em movimento **exclusivamente analógico** — nunca transição digital suave.
- **Paterno (+):** partículas de brasa seca (Ember) tremeluzindo — sem glow.
- **Materno (−):** anéis concêntricos dourados pulsando — sem gradiente.
- **Neutro (0):** totalmente fosco/acromático, sem sinalizador.

### 3.2 Estados de Colapso
- **Fratura de Frenesi (+100):** moldura da UI vira metal líquido Ember + tremulação estática; cronômetro de 4s (Massa Abafadora) em contagem regressiva severa sobrepondo tudo.
- **Estagnação Tática (−100):** paralisia visual total — opacidade cinza-chumbo fosca, ícones inertes ("ferramentas petrificadas"), zero brilho.

### 3.3 Geometria e Paleta de UI
- Botões usam exclusivamente **Geometria de Contraforte**: retângulos pesados, trapézios, ângulos retos. Proibido: cantos arredondados, ícones flutuantes, neon, glow difuso.
- **Regra 70/30:** 70% tons de opressão dessaturados (cinza-chumbo, ferrugem, asfalto) / 30% sinalizadores de ativação (Ember, Dourado Prismathico). Em alerta (+100/−100), sinalizadores podem chegar a 60%, nunca ao fundo inteiro.

**Fonte completa:** `docs/05_arte/ART-BIBLIA-INTERFACE.md` — inclui hierarquia de layout mobile, tabela de timing de animação e checklist de conformidade próprios.

---

## 4. Glossário Cromático Central

| Token | Hex | Significado | Onde é permitido |
|-------|-----|--------------|-------------------|
| **Ember** | `#FF4500` | Incandescência de metal líquido — polo Paterno | Bloqueado no TIER 1-2; liberado no TIER 3; liberado na UI como sinalizador Paterno (Seção 3.1) |
| **Dourado Prismathico** | `#FFD700` | Anéis rúnicos rígidos — polo Materno | Bloqueado no TIER 1-2; liberado no TIER 3; liberado na UI como sinalizador Materno (Seção 3.1) |
| Roxo geométrico | — | Fendas do Véu, estática quadrada, fratura ontológica | Exclusivo do TIER 3 |
| Acromático (preto/branco) | — | Vácuo, zona de aniquilação cromática | Exclusivo do TIER 3, obrigatório em todo efeito supremo |

**Regra de ouro:** Ember e Dourado Prismathico são os ÚNICOS tokens de cor viva reservados às Marcas de Veredito. Nenhuma raça, item ou efeito fora do eixo Paterno/Materno pode usá-los — ver Seção 5.

---

## 5. Raças Fundadoras — Status de Cobertura Visual

O cânone mecânico (`src/types/aetheris.types.ts`, enum `Race`) define **seis raças fundadoras**: `HUMAN`, `DWARF`, `ELF`, `FAERIE`, `DRACONIAN`, `LURID`. A cobertura de Bíblia de Arte **não é uniforme** entre elas — registro honesto do que existe hoje:

| Raça | Codex de Arte dedicado? | Cobertura visual existente |
|------|--------------------------|------------------------------|
| HUMAN | ❌ Não existe | Apenas via arquétipo "Sapador" (`ART-PROMPTS-TIER1.md` Seção 2) — não é um codex racial completo, é um traje de classe |
| DWARF | ❌ Não existe | Apenas via arquétipo "Artífice" (`ART-PROMPTS-TIER1.md` Seção 3) — mesma ressalva acima |
| ELF | ❌ Não existe | Nenhuma menção visual dedicada encontrada |
| FAERIE | ❌ Não existe | Nenhuma menção visual dedicada encontrada |
| DRACONIAN | ❌ Não existe | Nenhuma menção visual dedicada encontrada |
| LURID | ✅ **Completo** | `docs/01_cenario/BIBLE-LURID-RACE.md` — identidade, biologia, silhueta, paleta, movimento, checklist de revisão |

**Gap identificado:** apenas 1 das 6 raças fundadoras (LURID) tem um Codex de Arte no mesmo padrão de profundidade. Os arquétipos de Sapador/Artífice cobrem *equipamento de classe* de HUMAN/DWARF, não a raça em si (anatomia, silhueta racial base, paleta de pele/textura). ELF, FAERIE e DRACONIAN não têm nenhuma diretriz visual registrada. Se a produção depender de consistência visual entre as seis raças, este é o próximo débito de conteúdo a fechar — **não preenchido aqui** para não inventar cânone que a equipe ainda não decidiu.

### 5.1 Resumo do Codex Lurídeo (referência rápida)
- **Identidade:** fluidez ontológica — sem esqueleto rígido, silhueta nunca fechada em ângulos de 90°.
- **Fraqueza nativa:** FIRE (`RACIAL_ELEMENTAL_WEAKNESS` em `SkillEngine.ts`) — única exceção às regras de movimento contínuo (contração de pânico ao dano de fogo).
- **Contraste de design:** sem Engenharia Elemental (exclusiva HUMAN/DWARF) — narrativamente redundante para um corpo já adaptável.
- **Paleta:** tons translúcidos/refletivos (azul-profundo, verde-alga, cinza-tempestade) — **proibido** Ember/Dourado (reservados às Marcas de Veredito, Seção 4).

**Fonte completa:** `docs/01_cenario/BIBLE-LURID-RACE.md`.

---

## 6. Checklist Rápido de Conformidade (Uso Diário do Artista)

Antes de considerar qualquer asset pronto, confirmar:

- [ ] O tier correto foi identificado (1, 2 ou 3) e a Trava R3 correspondente foi aplicada ou revogada?
- [ ] Nenhum Ember/Dourado apareceu fora do TIER 3 ou fora de um sinalizador de UI Paterno/Materno?
- [ ] A paleta do ativo respeita as proporções da tabela do tier correspondente (ver documento-fonte)?
- [ ] Personagens/equipamentos seguem a geometria proibida/permitida do tier (contraforte na UI; retangular-rígido para Sapador; trapezoidal-largo para Artífice; fluida-sem-ângulo-reto para Lurídeo)?
- [ ] Se o ativo é de uma raça sem Codex dedicado (HUMAN/DWARF/ELF/FAERIE/DRACONIAN além de equipamento de classe), foi sinalizado à Direção de Arte em vez de inventado ad hoc?
- [ ] Neon, cyberpunk, cantos arredondados suaves ou gradientes difusos foram evitados (proibição universal, todos os tiers)?

---

## 7. Índice de Referências Cruzadas

| Documento-fonte | Conteúdo | Autoridade sobre |
|-------------------|----------|---------------------|
| `docs/05_arte/ART-BIBLIA-INTERFACE.md` | Linguagem visual de HUD/UI de combate | Cânone travado — Capítulo 4 |
| `docs/05_arte/ART-PROMPTS-TIER1.md` | Prompts técnicos Early Game (Vardhelm, Sapador, Artífice) | Aprovado — conformidade R3 |
| `docs/05_arte/ART-PROMPTS-TIER2.md` | Prompts técnicos Mid Game (Brenhold, Contenção, Calibração) | Aprovado — conformidade R3 |
| `docs/05_arte/ART-PROMPTS-TIER3.md` | Prompts técnicos Clímax/Endgame — revogação da R3 | Aprovado — R3 revogada |
| `docs/01_cenario/BIBLE-LURID-RACE.md` | Codex racial completo dos Lurídeos | Cânone travado v1.0.0 |
| `DOCUMENTACAO/DOC-003_ART_BIBLE.md` | Placeholder de escopo/objetivo da Art Bible geral | Em construção (v0.1.0, sem conteúdo ainda) |
| `src/types/aetheris.types.ts` (`Race`, `ElementType`) | Cânone mecânico das seis raças e elementos — base para qualquer diretriz visual futura | Código-fonte (não documental) |

---

## 8. Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 1.0.0 | 2026-07-15 | Criação do Blueprint Visual Mestre — consolidação da Regra R3, dos três tiers, da linguagem de interface e do status de cobertura racial (gap de 5/6 raças sem Codex sinalizado). |
