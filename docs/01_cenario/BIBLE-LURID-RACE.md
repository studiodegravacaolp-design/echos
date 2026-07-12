# BIBLE-LURID-RACE
## Codex dos Lurídeos — Uma das Seis Raças Fundadoras
### Projeto Aetheris — RPG de Sistemas Mecânico-Ontológicos Mobile
**Status:** Cânone Travado — v1.0.0
**Débito de origem:** Sprint 6 — Matriz das Seis Raças Fundadoras / Engenharia Elemental

---

## 1. Identidade Central

Os Lurídeos são a raça da **fluidez ontológica**. Onde as demais raças fundadoras se definem por estrutura — o osso do Anão, o metal do Humano, a fibra vegetal do Elfo — o Lurídeo se define pela ausência de forma fixa. Sua identidade não é um estado, é um **processo contínuo de adaptação**.

- **Palavra-chave de design:** Fluidez. Nunca desenhe, anime ou escreva um Lurídeo em repouso rígido.
- **Contraponto narrativo:** Enquanto Humanos e Anões conquistam o mundo através da Engenharia (ferramenta, forja, mecanismo), os Lurídeos nunca precisaram conquistar a água — eles **são** a água reagindo à pressão do mundo ao redor.
- **Fraqueza elemental nativa (cânone mecânico):** FIRE. O fogo é o único elemento capaz de romper a coesão fluida do corpo lurídeo, evaporando a adaptabilidade que os define. Esta fraqueza está implementada em `RACIAL_ELEMENTAL_WEAKNESS` (`SkillEngine.ts`) e deve ser respeitada em toda representação visual de combate — o Lurídeo reage ao fogo com pânico existencial, não apenas dor física.

---

## 2. Fluidez e Adaptação Aquática

### 2.1 Biologia Conceitual
- O corpo lurídeo não possui esqueleto rígido no sentido convencional — sua sustentação vem de tensão superficial e pressão hidrostática interna, não de estrutura óssea.
- A silhueta lurídea nunca é geometricamente estável: bordas semi-transparentes, contornos que ondulam mesmo em quadros estáticos, superfícies que refletem luz como água em movimento (nunca como pele opaca).
- Adaptação física real: um Lurídeo pressionado (fisicamente, socialmente, emocionalmente) **muda de forma** antes de quebrar. Isso é a expressão biológica direta da sua identidade narrativa — eles não resistem à força, eles se redistribuem em torno dela.

### 2.2 Comportamento e Filosofia
- Cultura lurídea despreza a permanência. Não constroem monumentos — constroem correntes, marés, rotas que se refazem a cada estação.
- Onde outras raças fundadoras têm "linhagens" no sentido genealógico rígido, os Lurídeos têm "confluências" — identidade coletiva que se mistura e se separa como corpos d'água que se encontram e se bifurcam.
- Conflito é resolvido por cerco e absorção, não por confronto direto: um Lurídeo tende a envolver um problema até neutralizá-lo, nunca a quebrá-lo de frente.

---

## 3. Ausência de Engenharia Pesada — O Contraste Deliberado

Este é o ponto de design mais importante deste Codex, e a razão direta de sua criação nesta sprint.

- **Cânone mecânico:** `EngineeringManager.processEngineeringUsage` concede a mecânica de Engenharia Elemental (substituição do custo místico de Estafa por cargas físicas de kit) **exclusivamente** a HUMAN e DWARF. Lurídeos NÃO têm acesso a esta mecânica — narrativamente, nunca precisaram dela.
- **Por quê:** Engenharia pesada é uma resposta à fragilidade do corpo rígido — Humanos e Anões constroem ferramentas porque seus corpos têm limites físicos definidos que a tecnologia estende. O corpo lurídeo já é adaptável por natureza; forjar um mecanismo externo para contornar um limite seria, para eles, redundante e conceitualmente absurdo.
- **Regra de design para toda a equipe:** Nunca equipe um Lurídeo com engrenagens, forjas, kits de carga, kits de munição elemental ou qualquer silhueta de ferramenta mecânica pesada. Se um Lurídeo precisa interagir com um problema de engenharia, a solução visual correta é *ele se tornar parte do mecanismo* (fluir por dentro de tubulações, preencher uma forma vazia, conduzir uma corrente), nunca operar uma alavanca com as mãos.
- **O que ELES têm em vez disso:** o fluxo místico padrão de Estafa (a Balança) permanece o único caminho de custo para os Lurídeos — exatamente como para Elfos, Faéricos e Draconianos. Isso não é uma limitação de gameplay a ser compensada; é a expressão mecânica direta de que eles não precisam de um atalho físico para o custo místico, porque sua própria natureza já é fluida.

---

## 4. Diretrizes Conceituais de Design — Bíblia de Arte

### 4.1 Silhueta
- Contorno **nunca** fechado com linhas retas ou ângulos de 90°. Toda curva deve sugerir tensão superficial, nunca esqueleto.
- Variação de silhueta quadro a quadro é obrigatória em qualquer animação idle — um Lurídeo perfeitamente estático é um erro de produção, não um estilo.
- Extremidades (mãos, cauda, franjas) devem ler como prolongamentos que gotejam ou se dissolvem nas bordas, nunca como terminações duras (garras, cascos, dedos ósseos).

### 4.2 Paleta
- Base cromática: tons translúcidos e refletivos — azul-profundo, verde-alga, cinza-tempestade — nunca cores opacas sólidas de pele ou metal.
- Reflexo de luz é o principal veículo de expressividade visual (equivalente ao "brilho" nas outras raças): luz quebrada, cáustica, tremeluzente sobre superfície líquida.
- **Proibido:** brilho incandescente ou tons ember/dourados associados às Marcas de Veredito Paterno/Materno (ver `ART-BIBLIA-INTERFACE.md` Seção 1.2–1.3) — esses tokens pertencem ao eixo Paterno/Materno humano e nunca devem contaminar a leitura visual de um Lurídeo.

### 4.3 Movimento
- Toda locomoção lurídea é fluida e contínua — sem poses-chave rígidas de contato no chão. Prefira interpolação orgânica a cortes de pose.
- Reação a dano físico: ondulação e dispersão momentânea da silhueta, com retorno à forma — nunca um "flinch" ósseo (recuo rígido de esqueleto).
- Reação a dano de FIRE (fraqueza nativa): a única exceção à regra de movimento contínuo — aqui, e apenas aqui, é aceitável um efeito de contração abrupta e perda de coesão de forma, comunicando pânico existencial diretamente ligado à Seção 1.

### 4.4 O Que Evitar (Checklist de Revisão)
- [ ] Nenhuma engrenagem, forja, kit de carga ou silhueta de ferramenta mecânica pesada em qualquer asset lurídeo.
- [ ] Nenhuma linha reta ou ângulo de 90° na silhueta principal.
- [ ] Nenhuma pose idle perfeitamente estática.
- [ ] Nenhum uso de tons ember/dourados (reservados às Marcas de Veredito).
- [ ] Nenhuma terminação óssea/dura (garras, cascos, dedos rígidos) nas extremidades.

---

## 5. Referências Cruzadas

| Documento | Relação |
|-----------|---------|
| `src/types/aetheris.types.ts` (`Race.LURID`) | Fonte de cânone mecânico — raça registrada no enum das Seis Raças Fundadoras |
| `src/modules/skills/SkillEngine.ts` (`RACIAL_ELEMENTAL_WEAKNESS`) | Fraqueza nativa a FIRE (Seção 1, 4.3) |
| `src/modules/engineering/EngineeringManager.ts` | Confirma ausência de acesso à Engenharia Elemental (Seção 3) — exclusiva a HUMAN/DWARF |
| `docs/05_arte/ART-BIBLIA-INTERFACE.md` | Paleta de Marcas de Veredito (Ember/Dourado Prismathico) — vocabulário visual a NÃO reutilizar em Lurídeos (Seção 4.2) |

---

## Histórico de Versões

| Versão | Data | Descrição |
|--------|------|-----------|
| 1.0.0 | Sprint 6 | Criação do Codex dos Lurídeos — identidade fluida/aquática, contraste com Engenharia Elemental, diretrizes de arte. |
