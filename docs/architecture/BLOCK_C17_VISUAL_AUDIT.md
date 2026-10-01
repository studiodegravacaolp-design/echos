# ECHOES OF THE SOUL — C17 (Fase 1): auditoria visual e definição do setor (Vardhelm)

> **Status:** auditoria e proposta. **Nada foi implementado.** A implementação espera a direção aprovada e
> as decisões pendentes (seção 9). A mais importante é o formato visual: os documentos de arte do projeto
> definem **HD-2D pixel art**, e o slice atual é 3D com primitivas.
> Capturas em [`c17_audit/`](c17_audit/), tiradas da câmera real do jogador (1152×648, renderizado).

## 1. Como o cenário é montado hoje

| Camada | Origem | Conteúdo |
|---|---|---|
| **Sala** | `level_data/vardhelm_forge_01.json` → `LevelBuilder` (`@tool`) → nó `Generated` **gravado** em `vp_01_vardhelm.tscn` | caixa de 20 × 14 m, piso, 4 paredes de 4 m, 2 blocos de máquina, passarela, respiro de brasa, 6 pilares ao norte, 1 prefab de teste; 16 malhas |
| **Ambientação** | `VardhelmSetDressing` (código, em runtime) | forja (oeste), banco de tubos (leste), bancada, caixas, 4 luminárias de parede, marcas de piso, 2 placas, 2 respiros, cabo e 3 vigas aéreas, 2 estantes, duto de fundição, portão, grelhas, faixas de aviso, 3 luzes de trabalho; 98 malhas |
| **Vida** | `VardhelmAmbientLife` (`ambient_life.json`) | 4 trabalhadores (cápsulas), 4 estações, 3 adereços de história, observações (C13–C16); 19 malhas |
| **Câmera do jogo** | `player.tscn` → `CameraRig/Camera3D` | ortográfica, tamanho 10, isométrica fixa (−35°, 40°), segue o jogador |
| **Luz** | nível + set dressing + Eco | 1 direcional neutra, lateral, com sombra; 9 omni (forja, 4 de parede, 3 de trabalho, Eco) |
| **Ambiente** | `WorldEnvironment` do nível | fundo de cor chapada `#101419`, ambiente frio 0,35, glow 0,8; **sem névoa, sem SSAO, sem tonemap** |
| **Escala** | jogador: cápsula de 1,8 m | paredes de 4 m ≈ 2,2 alturas de gente; sala de 20 × 14 m |

## 2. O que os documentos de arte do projeto já definem

**Esta é a referência; a proposta segue ela e não inventa uma estética.**

- [`docs/05_arte/ART-PROMPTS-TIER1.md`](../05_arte/ART-PROMPTS-TIER1.md) §1 (Vardhelm, Ato 1):
  - Vardhelm é uma **"vast industrial cityscape"**: fundições de ferro, **tijolo com fuligem**, **chaminés
    cortando um céu cinza e nublado**, fumaça, poeira de carvão, peso opressivo da arquitetura;
  - o interior de "galpão de manufatura" tem volantes, correias de couro, **trilhos de ponte rolante**,
    paredes de tijolo com fuligem, **pilares de ferro bruto**, **piso manchado de óleo**, lâmpadas de
    querosene fracas, **chiaroscuro**, sombras pesadas nos cantos;
  - **paleta:** cinza-chumbo 40%, sépia 25%, preto fuligem 20%, ferrugem 10%, marrom lona 5%;
  - **Trava R3** (ilustrações): sem brilhos, auras, efeitos luminosos, destaques fortes, neon, e sem
    "ember #FF4500" nem dourado.
- [`doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md`](../../doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) (o jogo):
  - **formato: HD-2D pixel art.** Texturas pixel a pixel, sprites 2D com contorno de 1 px, projeção
    ortogonal/isométrica rigorosa, e "Assets 3D ... sem a textura de pixels ... proibidos na build final";
  - **70/20/10:** base `#121214`, `#1E222A`, `#2A2C30`; acentos `#4A7C7A`, `#8C633E`, `#A68052`;
    emissivos (até 10%) `#39FF14`, **`#FF7900` (forja)**, `#00E5FF` (faíscas);
  - **luz:** a principal vem **de cima**, fraca, fria e poeirenta; os emissivos iluminam de baixo;
    chiaroscuro. É **proibido** "neon puro (ciano, rosa)";
  - **atmosfera:** fumaça densa, partículas, jatos de vapor, camadas de paralaxe, tubulações em todos os
    eixos;
  - **arquitetura humana:** pedra bruta com reforços de aço escurecido, torres cilíndricas, guindastes,
    pontes de tábua.
  - O blueprint situa o jogo em **Brenhold**, e os demais documentos põem Vardhelm como o Ato 1: uma
    divergência entre documentos.

### Divergências entre o slice e esses documentos

| Tema | Documentos | Slice atual |
|---|---|---|
| **Formato** | HD-2D pixel art (3D só com textura de pixel; personagens em sprite) | 3D com primitivas de cor chapada; personagens em cápsula |
| Material | tijolo com fuligem, ferro bruto, piso com óleo | cor lisa em tudo; nenhum tijolo |
| Laranja | forja `#FF7900` até 10% (blueprint); sem ember nas ilustrações (R3) | `#FF8A3D` emissivo em faixas, discos, lâmpadas, anéis e brasa, bem mais que um acento |
| Ciano do Eco | proibido "neon puro ciano"; `#00E5FF` só para faíscas | `#6FE7FF` com brilho forte (esfera, marca no chão, luz do C13) |
| Luz | de cima, fraca, fria, com poeira; chiaroscuro | direcional lateral neutra; ambiente chapado |
| Fora da sala | cidade de chaminés sob céu nublado | vazio de cor chapada |

## 3. Análise visual

**Arquitetura.** É uma caixa fechada, sem arquitetura reconhecível: quatro paredes lisas iguais, sem
aberturas, pilastras, recuos ou níveis. A passarela a 2,5 m é o único elemento de altura, e ninguém a
usa. O espaço parece **preenchido**, não construído. O portão "FORJA 01 • VARDHELM" está encostado na
parede sul, que é maciça: não emoldura nada, e a câmera o vê por trás.

**O problema dominante (câmera × paredes).** A câmera isométrica olha de sudeste, e as paredes **sul e
leste**, com 4 m, ficam entre ela e a sala. Na **entrada** (`10_entrada_spawn`), a primeira imagem do
jogo é uma parede cinza cobrindo quase metade da tela. O mesmo acontece perto do painel e no leste. No
C15, isso escondeu Durn no canto sudoeste.

**Escala e profundidade.** O que está fora da sala é um vazio de cor chapada. A caixa flutua
(`00_visao_geral`), então não há cidade além dela, embora o cânone fale de uma cidade. Sem névoa, tudo
tem o mesmo contraste a qualquer distância. As vigas aéreas, a 3,55 m, cruzam a tela como barras pretas
em primeiro plano.

| Camada | Hoje | Onde fortalecer |
|---|---|---|
| Primeiro plano | parede sul/leste maciça (atrapalha); vigas aéreas | trocar a parede por um limite **baixo** que ainda defina o espaço |
| Plano médio | a sala inteira; é onde tudo acontece | organizar por zonas (forja, painel, eco), não por objetos soltos |
| Fundo | nenhum | chaminés e silhuetas de fundições sob céu nublado, com fumaça (cânone) |

**Composição.** Há dois focos fortes: a **forja** (oeste) e o **Eco** (centro leste). Entre eles, o centro
é um chão escuro e plano. O **painel selado**, peça central da história do C12 ao C16, é uma placa solta
no meio do piso, a ~3 m da parede oeste, sem nada atrás. Ele não lê como "painel", nem como "selado",
nem como parte de algo. O laranja espalhado em marcas no chão compete com os focos.

**Atmosfera.** Os tons escuros de metal e a oposição quente × frio (forja × Eco) já apontam para o
cânone. Faltam o ar (fumaça e vapor, névoa), a luz fria de cima com poeira, sombras de contato e
qualquer material com textura. O laranja emissivo está bem acima dos 10% do blueprint.

**Provisórios.** O pilar **magenta** (`assets/vardhelm/prefabs/test_prefab_pillar.tscn`, cor de depuração)
no canto sudoeste; os rótulos 3D já ocultos; trabalhadores e Durn como cápsulas; o `MachineBlock_B`
sem forma de máquina.

**Reaproveitáveis.** O LevelBuilder guiado por dados, a paleta de materiais (ajustável aos hex do
blueprint), a forja, o duto de fundição, as estantes, os 6 pilares do norte (já parecem "pilares de
ferro bruto"), as vigas aéreas (base para os "trilhos de ponte rolante") e o contraste quente × frio.

## 4. O que NÃO pode mudar (dependências de C13–C16)

| Elemento | Quem depende |
|---|---|
| `PlayerSpawn` (0, 0.25, 3) e `NPCSpawn` (−4, 0.25, −2) | início; lugar de sempre de Durn (C15) e a folha (C16) |
| `VardhelmSetDressing/WorkLight_00` e `WorkLightFixture_00` (−6.2, 2.7, 2.0), nomes e posição | reação do C13 e silêncio do C14 (buscados pelo caminho do nó) |
| observações: quadro (−5.7, −3.9), painel (−6.7, 1.8), ferramentas (−3.5, 3.1), folha (−4, −2) | C12–C16 |
| Eco (2.5, 1, −3) e o lugar de Durn sozinho (1.1, −3.4) | C12–C15 |
| rotas dos trabalhadores (bancada → perto do painel) | C13 |
| `VardhelmAudio` | C13, C14.1, C14.2 |
| caminhos livres até Durn, Eco, painel, ferramentas e folha | todos os playtests com input real |

Colisão nova em qualquer um desses caminhos exige rodar de novo os playtests de caminhada.

## 5. Setor escolhido: a baia oeste da forja ("FORJA 01")

A metade oeste: forja, painel selado, lâmpada fria, bancada, suporte de ferramentas, quadro de manutenção
e o lugar de Durn.

- É onde o jogador passa mais tempo do C12 ao C16: Durn, painel, silêncio, o trabalhador que para, a
  folha.
- Tem o melhor foco visual do jogo (a forja) e a pergunta narrativa (o painel).
- É o ponto mais perto do "galpão de manufatura" do cânone: forja, duto, pilares de ferro.
- A parede oeste e o canto noroeste estão livres de dependências.
- Aparece logo na entrada, se a parede sul deixar de tapar a vista.

## 6. Direção visual proposta (segue os documentos de arte)

- **Formas:** um galpão de manufatura. Paredes de **tijolo com fuligem** com **pilares de ferro bruto** e
  vigas no ritmo dos 6 pilares existentes; as vigas aéreas viram **trilhos de ponte rolante**; um
  **anteparo de tijolo e ferro** atrás do painel selado, para que ele fique **dentro** de uma parede; o
  duto e a chaminé da forja subindo acima da linha das paredes (escala vertical). Sem caixas novas
  espalhadas.
- **Materiais:** base `#121214` / `#1E222A` / `#2A2C30`, acentos de ferrugem, bronze e latão
  (`#8C633E`, `#A68052`), cobre oxidado `#4A7C7A` nos tubos frios. Piso manchado de óleo e mais gasto
  perto da forja. **Se** o formato for HD-2D (decisão 9.1), texturas pixel art nesses materiais.
- **Luz:** a principal passa a vir **de cima**, fria, fraca e com poeira, no lugar da direcional lateral.
  A forja `#FF7900` é o emissivo quente que ilumina de baixo, **reduzida a um acento**: sai o laranja das
  faixas, discos e anéis espalhados. As lâmpadas de trabalho e de parede ficam fracas, como querosene.
  Cantos no escuro (chiaroscuro). O Eco e a lâmpada fria do C13 continuam sendo o único frio, **sem
  mudar** o que foi validado (decisão 9.2).
- **Atmosfera:** fumaça e vapor baixos (névoa ou volumétrico) e SSAO para sombras de contato. Medir o
  custo na GPU integrada.
- **Fundo:** o cânone é uma cidade industrial. Poucas silhuetas escuras de **chaminés e fundições sob céu
  nublado**, com fumaça, vistas por cima das paredes baixas. Nada jogável e nada detalhado.

## 7. Alterações propostas (em ordem de prioridade; nenhuma feita)

1. **Paredes em corte (cutaway) no sul e no leste:** a malha visível baixa para ~0,9 m (um parapeito) e a
   **colisão continua com 4 m**, então a circulação não muda. É o maior ganho, e é neutro em relação à
   lore. No LevelBuilder: altura visual separada da altura de colisão (opcional no JSON; o que não usar
   continua igual) e um novo *build* do `Generated`.
2. **Tirar o pilar magenta de teste** do `vardhelm_forge_01.json` (e do `Generated`).
3. **Reduzir o laranja** ao acento da forja (faixas, discos e anéis passam para tons base e ferrugem).
4. **Anteparo atrás do painel selado:** um trecho de parede ao norte do painel, com moldura, sem mover a
   observação, a luz nem o painel. Colisão só atrás dele, fora do caminho de aproximação (conferir com
   os playtests).
5. **Galpão na baia oeste:** tijolo com fuligem nas paredes oeste e norte, pilastras e trilhos de ponte
   rolante.
6. **Luz e atmosfera:** luz de cima fria e com poeira, fumaça e vapor baixos, SSAO, tonemap filmic.
7. **Fundo de cidade** (chaminés e fundições sob céu nublado), junto com a proposta 1.
8. **Portão de entrada:** abrir a parede sul atrás dele (a colisão fecha a saída) ou tirá-lo; decisão 9.4.

**Arquivos que seriam modificados:** `level_data/vardhelm_forge_01.json`, `scripts/level/level_builder.gd`
e `level_validator.gd` (campo opcional de corte), `scenes/prototypes/vp_01_vardhelm.tscn` (novo *build*),
`scripts/vardhelm/vardhelm_set_dressing.gd` (galpão, anteparo, fundo, materiais). Nenhum arquivo de
narrativa, estado, save, eventos, diálogo, quest ou localização.

**Riscos técnicos:**

- o `Generated` é gravado pelo builder em modo `@tool`; um *build* novo regrava a cena inteira (conferir
  com "Check Sync With JSON" e com a regressão);
- colisões novas podem bloquear caminhos dos playtests;
- névoa, volumétrico e SSAO custam desempenho na GPU integrada medida no C9 (Intel UHD);
- mudar a luz principal altera a leitura das reações do C13 (lâmpada fria) e deve ser conferido
  visualmente;
- se o formato for HD-2D, boa parte do trabalho de materiais em 3D liso seria refeita.

**Impacto esperado:** a primeira imagem do jogo passa a ser a sala e não uma parede; o painel passa a ler
como parte de uma estrutura; a baia ganha escala vertical, ar e luz com volume; o jogo começa a parecer
a Vardhelm dos documentos; nenhuma mudança de gameplay.

## 8. Próximas oportunidades visuais (fora da Fase 1)

Personagens em sprite HD-2D (ou silhuetas) no lugar das cápsulas, conforme a decisão 9.1; a passarela
ganhar função visual (acesso, guarda-corpo); `MachineBlock_B` virar uma máquina legível (volante,
correias); o painel com rebites, lacres e marcas de reforço, sem abrir nada; vapor animado nos respiros.

## 9. Decisões pendentes (não assumidas)

1. **Formato visual.** O blueprint define HD-2D pixel art (3D só com textura de pixel, personagens em
   sprite 2D), e o slice é 3D com primitivas. O C17 deve:
   - (a) seguir HD-2D desde já (texturas pixel art nos volumes 3D, sprites depois);
   - (b) evoluir o 3D atual como protótipo e adiar o HD-2D;
   - (c) outra direção?
2. **Ciano do Eco e laranja.** O blueprint proíbe "neon puro ciano" e limita os emissivos a 10%. O brilho
   do Eco e a lâmpada fria (C13, validados em teste humano) ficam como exceção narrativa, ou devem ir para
   o `#00E5FF` e perder intensidade? Esta proposta não toca neles sem essa decisão.
3. **Brenhold × Vardhelm.** O blueprint situa o jogo em Brenhold, e os outros documentos põem Vardhelm como
   Ato 1. Para o C17 vale o TIER1 (Vardhelm, cidade industrial)?
4. **Por onde se entra na Forja 01?** O portão sugere uma entrada ao sul, mas a parede é maciça.
5. **Paredes em corte (proposta 1):** é aceitável esse recurso clássico de câmera isométrica, ou a
   intenção é manter as paredes cheias e mudar a câmera?
