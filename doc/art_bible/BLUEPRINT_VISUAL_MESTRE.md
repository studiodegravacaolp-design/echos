# 📘 BLUEPRINT VISUAL MESTRE — PROJETO AETHERIS
## O Guia Supremo de Identidade Visual, Direção de Arte e Produção de Assets (HD-2D JRPG)

---

## 📜 INTRODUÇÃO E FILOSOFIA DE TRABALHO
O Projeto **AETHERIS** é um JRPG tático de sobrevivência em estilo **HD-2D Pixel Art**, ambientado nas profundezas industriais de **Brenhold**. Esta documentação artística serve como o único referencial estético para todos os artistas conceituais, ilustradores, pixel artists, animadores, designers de interface e inteligências artificiais gerativas durante todo o ciclo de desenvolvimento do jogo.

Nenhum asset visual deve ser integrado à build sem antes ser submetido aos parâmetros de design, limitações de materiais e grades de pixels definidos neste compêndio.

---

## 🎨 CAPÍTULO 1: O NÚCLEO ESTÉTICO E ASSINATURA VISUAL

### 1. Objetivo do Capítulo
Codificar o DNA visual de *Aetheris*. Este capítulo atua como a âncora conceitual para blindar o tom estético do jogo, garantindo coerência temática e impedindo o desvio para ficções científicas assépticas ou fantasias medievais tradicionais.

### 2. Os Três Pilares Estéticos Canônicos

Todo elemento artístico produzido para o jogo deve ser fundamentado sob a interseção de três princípios estéticos:

#### Pilar 1: Fadiga Mental e Textura Bruta (Scrap-Tech / Diesel-Fantasy)
*   **A Filosofia de Escassez:** A tecnologia em Brenhold não é fruto de manufatura automatizada limpa; é um arranjo de sobrevivência. Armas, armaduras, chassis e dispositivos de controle são representados em pixel art detalhado com marcas de solda, rebites e juntas metálicas grosseiras.
*   **Tradução Prática em Texturas:** 
    *   Metais devem exibir porosidade, fuligem incrustada, marcas de solda grosseira e oxidação ativa.
    *   Peças de vestuário e vedações mecânicas devem ser representadas por panos de lona sujos de graxa, couro desgastado e fiação exposta.
*   **A Expressão Física:** A fadiga tática (Estafa) deve ser impressa nas poses das sprites. Ombros arqueados sob o peso de chassis, olhos cansados protegidos por visores industriais e pernas plantadas de maneira pesada e exausta.

#### Pilar 2: Brilho Lurídeo e Contraste Químico-Técnico
*   **A Filosofia da Luz Reativa:** O cenário cinzento e enfumaçado de Brenhold é quebrado apenas pelas fontes de energia térmica e química que mantêm a cidade pulsando.
*   **Tradução Prática:**
    *   Pistas visuais críticas (interfaces ativos, perigos, pontos fracos de inimigos, núcleos térmicos e botões) devem emitir um brilho vibrante, tóxico e concentrado.
    *   Este brilho deve atuar como o ponto de fuga em silhuetas escuras, garantindo forte contraste visual (Value Contrast) no playfield.

#### Pilar 3: Densidade dos Dutos e Opressão Atmosférica
*   **A Filosofia Claustrofóbica:** Brenhold é uma infraestrutura vertical e asfixiante. O ambiente atua como um opressor direto do jogador.
*   **Tradução Prática:**
    *   Cenários estruturados em múltiplas camadas de paralaxe em pixel art, exibindo tubulações que cruzam a tela em todos os eixos.
    *   Presença constante de fumaça densa, partículas suspensas na atmosfera e jatos de vapor que cortam a iluminação para reduzir a visibilidade do horizonte.

### 3. Limites e Restrições (O que Aetheris NÃO é)
*   **PROIBIDO Cyberpunk / High-Sci-Fi:** Sem hologramas azuis limpos, placas de plástico polido, superfícies de fibra de carbono, luzes de neon puras (como ciano e rosa-choque) ou interfaces digitais minimalistas. A tecnologia é analógica, pesada, de manômetros físicos e tubos catódicos.
*   **PROIBIDO High-Fantasy / Medieval Clássico:** Sem armaduras de cavaleiros reluzentes, espadas mágicas com entalhes rúnicos dourados, elfos de florestas intocadas ou feitiços mágicos arcanos de purpurina. 
*   **PROIBIDO Steampunk Vitoriano Decorativo:** Sem engrenagens puramente estéticas coladas em chapéus ou roupas limpas de aristocratas. Se uma engrenagem existe, ela deve possuir dentes conectados a um sistema mecânico funcional.

---

## ⚙️ CAPÍTULO 2: DIREÇÃO CROMÁTICA & ILUMINAÇÃO (COLOR & LIGHT RIG)

### 1. Objetivo do Capítulo
Padronizar a aplicação de cores e a física das fontes de luz no jogo para garantir excelente leitura de silhuetas, foco dramático nas mecânicas de jogo e perfeita integração em monitores de exibição padrão.

### 2. A Regra Proporcional Cromática: Sistema 70 - 20 - 10

Toda composição visual (ilustrações, telas de UI, sprites e cenários) deve respeitar a distribuição de cores a fim de evitar confusão visual:

#### Os Valores de Amostragem de Cores (Paletas Hexadecimais Canônicas)
*   **Tons Base (70%):**
    *   `#121214` - Preto-Carbono (Sombras profundas e metais carbonizados)
    *   `#1E222A` - Chumbo Oxidado (Base de armaduras e paredes de dutos)
    *   `#2A2C30` - Cinza-Ferrugem (Chapas de metal gastas)
*   **Tons de Transição / Accents (20%):**
    *   `#4A7C7A` - Cobre Oxidado / Azul-Verdete (Tubulações frias e conexões)
    *   `#8C633E` - Bronze Queimado (Engrenagens, fivelas e eixos de armas)
    *   `#A68052` - Latão Industrial (Rebites, tampas de reator e detalhes de UI)
*   **Tons Emissivos / Glow (10%):**
    *   `#39FF14` - Verde-Químico Emissivo (Energia instável, radiação, núcleos químicos)
    *   `#FF7900` - Laranja-Incandescente (Calor térmico, vapor superaquecido, forja)
    *   `#00E5FF` - Azul-Centelha (Faíscas elétricas, curto-circuito e danos de sistema)

*Nota: As cores da marca de Veredito (Ember/Dourado) permanecem reservadas para o Clímax/Tier 3 do jogo, não colidindo com os tons de emissão ativa das raças e sistemas industriais.*

### 3. Comportamento da Luz (Luminância)
*   **A Iluminação Volumétrica de Topo:** A luz principal deve ser sempre projetada verticalmente de cima para baixo, simulando aberturas distantes nos tetos dos dutos de Brenhold. Esta luz é fraca, fria e poeirenta, criando sombras projetadas pesadas sob os olhos, peitorais e bases das entidades.
*   **A Luz Emissiva Reativa (Luz de Baixo):** Qualquer vazamento químico ou reator no piso projeta luz de baixo para cima nas entidades com alta saturação (verde ou laranja). A luz nunca é plana; ela compete dramaticamente com o fundo escuro (estilo *Chiaroscuro*).

---

## 🤖 CAPÍTULO 3: GUIA DE DESIGN DE ENTIDADES (HERÓIS, CRIATURAS E MÁQUINAS)

### 1. Objetivo do Capítulo
Codificar as regras anatômicas, proporções e marcas de design para todas as entidades vivas, autômatos e ciborgues do jogo no formato **HD-2D Pixel Art**. Este capítulo garante que a transição de um herói do estado lógico para o visual seja feita mantendo o peso tático e a coerência com o Lore de escassez industrial.

### 2. O Chassi Biológico-Mecânico (HD-2D Sprites)
Em *Aetheris*, os personagens não usam armaduras decorativas; eles se fundem a chassis de sobrevivência. A carne e o metal coexistem em uma simbiose bruta e dolorosa.
*   **A Cabeça e a Expressão (Fadiga Ativa):** Olheiras profundas, pele pálida ou acinzentada pela falta de sol nos dutos, e marcas de queimaduras de vapor. Uso obrigatório de óculos de proteção de latão escuro (goggles), respiradores químicos ou máscaras de filtro acopladas diretamente à mandíbula.
*   **O Tronco e as Articulações (O Acoplamento):** As armaduras devem parecer parafusadas diretamente no corpo do personagem. As articulações (ombros, cotovelos, joelhos) não usam placas de metal polido; são cobertas por panos sujos de graxa, couro desgastado ou fiações hidráulicas expostas.

### 3. Diretrizes Visuais para Raças do Subsolo

#### A. Humanos de Brenhold (Os Engenheiros de Sucata)
*   **O Chassi:** Modificações utilitárias e focadas em ferramentas. Próteses pesadas feitas de ferro fundido, cintos de ferramentas volumosos e chassis de suporte de carga nas costas.
*   **Paleta de Destaque:** 70% Preto-Carbono, 20% Latão Industrial e 10% Laranja-Incandescente nos visores e medidores analógicos.

#### B. Os Ciborgues Scavengers (Os Modificados)
*   **O Chassi:** Alto nível de assimetria. Metade do rosto preservando a pele humana pálida, enquanto a outra metade é integrada a órbitas mecânicas de bronze. Membros inteiros substituídos por pistões e fiações hidráulicas aparentes.
*   **Paleta de Destaque:** 70% Chumbo Escurecido, 20% Cobre e 10% Laranja-Incandescente vibrando nos olhos ópticos artificiais.

#### C. Os Elfos de Brenhold (Engenheiros de Precisão de Reator)
*   **O Chassi:** Silhueta esguia, mas imponente (escala de 1,88m). Suas orelhas pontiagudas são marcadas por cicatrizes de fuligem. Braço mecânico altamente detalhado, projetado para micromanipulação mecânica e fiações finas de cobre.
*   **Paleta de Destaque:** 70% Chumbo Escurecido, 20% Bronze e 10% Azul-Centelha pulsando nas pontas dos dedos e fiação exposta.

#### D. As Faeries Industriais (Mecânicas Pneumáticas de Dutos)
*   **O Chassi:** Silhueta compacta e ágil. As asas biológicas foram substituídas por estruturas de asas mecânicas pneumáticas feitas de chapas de bronze finas que emitem vapor para sustentação física (momentum).
*   **Paleta de Destaque:** 70% Cinza-Ferrugem, 20% Latão e 10% Verde-Químico nos núcleos de pressão traseiros.

#### E. Os Draconianos (Forjadores de Chapa de Alta Temperatura)
*   **O Chassi:** Silhueta massiva, cauda reforçada com ponteiras mecânicas de impacto. Usam respiradores industriais pesados integrados ao focinho para filtrar gases nocivos e cinzas na boca da forja.
*   **Paleta de Destaque:** 70% Preto-Carbono, 20% Bronze Queimado e 10% Laranja-Incandescente brilhando sob as fendas das escamas térmicas.

#### F. Os Lurídeos (Fluidez e Adaptação Subaquática)
*   **O Chassi:** Escamas e membranas em tons aquáticos azulados. Equipamento respiratório subaquático acoplado ao chassi e fendas de exaustão de resíduos químicos.
*   **Paleta de Destaque:** 70% Chumbo Escurecido, 20% Azul-Verdete e 10% Verde-Químico emissivo nos visores de pressurização.

### 4. Assinatura Visual dos Inimigos (A Linguagem Tática)
*   **O "Assassino" (Ex: Catador de Dutos):** Silhueta esguia, curvada e angular. Garras longas de metal afiado. Um único visor óptico emitindo brilho Verde-Químico na cabeça.
*   **O "Protetor" (Ex: Autômato Desgovernado):** Silhueta massiva, quadrada, ombros largos e sem pescoço. Grelhas de ventilação no peito emitindo brilho Laranja-Incandescente.
*   **O "Drenador" (Ex: Engenheiro Desertor):** Silhueta assimétrica com tanques de gás combustível e bobinas de indução nas costas. Luzes pulsantes alternando entre Verde-Químico e Azul-Centelha.

---

## 🏗️ CAPÍTULO 4: CENÁRIOS, ARQUITETURA E TEXTURAS EM HD-2D

### 1. Objetivo do Capítulo
Codificar a linguagem arquitetônica das seis raças fundadoras e os padrões de materiais e texturas que compõem o cenário do jogo em pixel art. Este capítulo orienta os artistas de cenário (environment pixel artists) a desenharem os blocos de cenário (tilesets) mantendo a clara diferenciação cultural e o peso visual de cada ambiente.

### 2. Os Seis Materiais e Texturas Canônicos
Toda estrutura física em *Aetheris* deve ser representada graficamente utilizando uma destas texturas em pixel art de alta definição, respeitando seu comportamento sob iluminação:
*   **Aço (Industrial):** Apresenta ranhuras lineares rígidas, marcas de rebites e áreas de alto contraste metálico. Reflete luz fria e esbranquiçada.
*   **Bronze (Engrenagens/Conexões):** Tons quentes e oxidados (verdetes nas dobras). Reflete luz âmbar e possui brilho especular suave.
*   **Pedra (Estrutural):** Blocos rústicos e tijolos refratários envelhecidos. Textura áspera e sem reflexo de luz, com sombras densas nas fendas de encaixe.
*   **Madeira (Suporte/Nostalgia):** Tábuas paralelas de fibra visível e tons terrosos escuros, utilizadas em pontes e estruturas de suporte iniciais.
*   **Cristal (Emissão/Véu):** Superfícies facetadas e angulares com transparência simulada (dithering). Emite luz ativa própria (azul, roxa ou dourada).
*   **Água (Fluidez):** Apresenta linhas de brilho sinuosas de animação cíclica e reflexos distorcidos das estruturas próximas na superfície.

### 3. Arquitetura por Raça (Os Seis Estilos Visuais de Cenário)

Para que o jogador identifique instantaneamente em qual território do mundo ele se encontra, as construções devem seguir estes perfis arquitetônicos rígidos:
*   **Arquitetura dos Humanos (Adaptação e Engenharia):** Cidades e castelos medievais industriais fundindo tijolos de pedra bruta com reforços estruturais de aço escurecido. Torres cilíndricas, pontes de tábua de madeira suspensas, guindastes e dirigíveis nos céus com balões de lona.
*   **Arquitetura dos Anões (Engenharia Pesada e Metalurgia):** Cidades escavadas na rocha profunda, dominadas por ligas metálicas pesadas de bronze e latão. Sistemas gigantescos de engrenagens expostas, pistões hidráulicos, forjas ativas e tubulações de vapor cruzando os corredores de pedra.
*   **Arquitetura dos Elfos (Memória e História):** Estruturas góticas clássicas e elegantes, com linhas curvas suaves que dão sensação de antiguidade e reverência histórica. Arcos ogivais de pedra clara, janelas em mosaico, escadarias suspensas e ruínas preservadas integradas ao ambiente natural.
*   **Arquitetura das Fadas (Magia e Conexão com o Véu):** Cidades místicas construídas no topo ou interior de árvores colossais bioluminescentes. Paletas púrpuras e azuladas profundas, névoa densa e brilhante flutuando entre as plataformas de madeira orgânica, e lanternas de cristal emissivo.
*   **Arquitetura dos Draconianos (Poder Elemental Ancestral):** Fortalezas monolíticas cravadas em ambientes geotérmicos hostis, construídas em blocos de rocha vulcânica escura. Paredes reforçadas para suportar calor extremo, fendas estruturais revelando fluxos ativos de lava (Laranja-Incandescente), e grandes portões de ferro forjado.
*   **Arquitetura dos Lurídeos (Fluidez e Adaptação):** Cúpulas de vidro e torres ornamentadas subaquáticas inspiradas em conchas e na fluidez da água. Estruturas em tons de azul-turquesa, aquedutos decorativos ativos correndo por fora dos prédios, e caminhos orgânicos iluminados por cristais subaquáticos verdes.

### 4. Limites de Construção de Cenários em HD-2D
*   **Proibido Elementos de Colagem Fotográfica:** O cenário não pode usar texturas fotorrealistas de verdade. Cada tijolo, viga ou gota d'água deve ser desenhada pixel por pixel na paleta clássica do jogo.
*   **Proibido Perspectiva Inconsistente:** Todos os tilesets devem respeitar a projeção ortogonal ou isométrica de perspectiva do jogo de forma matemática rigorosa, garantindo que as sprites 2D dos personagens caminhem corretamente sobre o piso sem flutuar.

---

### 📏 CAPÍTULO 5: REGRAS DE RENDERIZAÇÃO E ESTILO DE SPRITE

### 1. Diretrizes de Sprite em Pixel Art
*   **Estilo de Render:** O jogo é estritamente em pixel art bidimensional de alta definição. Assets 3D ou pinturas digitais sem a textura de pixels individuais (pixel grid) são proibidos na build final.
*   **Dithering Manual:** Sombras e transições de cor devem usar técnicas clássicas de pontilhado (dithering) para simular profundidade, evitando gradientes de cores modernos gerados por computador.
*   **Contorno (Outline):** Todo sprite de personagem ou inimigo deve possuir um contorno nítido de 1 pixel de espessura de cor escura (Preto-Carbono ou Chumbo) para separar as entidades do cenário e garantir leitura instantânea em movimento.
*   **FPS Canônico:** Todas as animações devem ser desenhadas visando uma taxa padrão de **12 quadros por segundo (12 FPS)** para manter a fluidez e a nostalgia clássica de herança retro.
