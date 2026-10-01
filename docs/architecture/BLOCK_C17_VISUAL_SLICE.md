# ECHOES OF THE SOUL — C17 (Fase 2): baia oeste da Forja 01

> **Status:** implementado; testes automatizados verdes. **Aguarda o teste visual humano** (seção 7).
> Capturas da câmera do jogador: antes em [`c17_audit/`](c17_audit/), depois em [`c17_after/`](c17_after/).
> **Relacionados:** [auditoria C17 (Fase 1)](BLOCK_C17_VISUAL_AUDIT.md) · [C14](BLOCK_C14_FIRST_SEQUENCE.md) · [C15](BLOCK_C15_CHOICE_CONSEQUENCE.md) · [C16](BLOCK_C16_FUTURE_POSSIBILITY.md)
> **Decisões aprovadas:** manter o 3D/2.5D atual (HD-2D fica como referência futura); Vardhelm = cidade
> industrial (`ART-PROMPTS-TIER1`, `BLUEPRINT_VISUAL_MESTRE`); laranja concentrado na forja; o ciano do
> Eco e da lâmpada fria continua sendo uma exceção narrativa.

## 1. De "caixa com objetos" para "baia construída"

| Camada | Antes | Depois |
|---|---|---|
| **Paredes** | 4 paredes lisas de 4 m; sul e leste tapavam a câmera | **Norte e oeste:** tijolo com fuligem, 5,5 m, janelas altas. **Sul e leste em corte:** parapeitos de tijolo de 1,1 m, com **colisão de 1,1 m** e capa de ferro |
| **Estrutura** | 6 cilindros ao norte | 6 pilares de ferro ao norte (a mesma regra, agora de ferro e até o topo) + 4 pilastras na parede oeste |
| **Estrutura superior** | 3 vigas aéreas | + **ponte rolante** na baia oeste: 2 trilhos, viga-ponte, carro, corrente e gancho; a passarela ganhou apoios e guarda-corpo |
| **Entrada** | portão encostado numa parede maciça | **abertura real** no sul, entre os postes do portão, dando num **patamar** com guarda-corpo de tijolo (com colisão), sobre a cidade |
| **Painel selado** | placa solta no piso | dentro de um **anteparo de tijolo** com moldura de ferro (postes, verga, soleira); a mesma posição e a mesma interação; fechado |
| **Forja** | chaminé de 3,7 m | chaminé até 8 m (escala vertical); o duto que atravessava o painel agora desce ao lado do anteparo |
| **Piso** | cor lisa | chapas de ferro com juntas e **manchas de óleo** (shader) |
| **Fundo** | vazio de cor chapada | a **cidade abaixo**: galpões, chaminés e janelas distantes em silhueta, afundados em névoa, vistos pelas janelas e pela entrada |
| **Luz** | direcional lateral neutra; laranja espalhado | direcional **de cima, fria e fraca**; a forja como fonte quente principal (`#FF7900`); lâmpadas de querosene fracas e presas às paredes; o frio fica para o Eco e a lâmpada do painel |
| **Atmosfera** | nenhuma | névoa de profundidade leve + névoa densa **abaixo** do piso (a cidade no *smog*); fumaça na boca da forja, vapor nos respiros, poeira na baia; tonemap filmic |

**Por que o fundo fica abaixo e é visto pelas janelas.** A câmera do jogo é ortográfica, enquadra só ~10 m
na vertical, segue o jogador e olha para baixo a 35°. Tudo o que está **atrás** das paredes norte e oeste,
acima do piso, sai **por cima da tela**. Silhuetas altas atrás das paredes nunca apareceriam no jogo. Por
isso a cidade fica num nível **abaixo** da forja, e a linha de visão desce e a encontra pelas janelas altas
e pela entrada. Isso coincide com o cânone ("chaminés sob céu nublado", cidade industrial).

## 2. Laranja e emissivos

- **Forja:** mais quente e mais forte (face e brasa `#FF7900`, luz 1,9, alcance 6 m, fumaça).
- **Deixaram de brilhar:** as faixas de aviso (tinta ocre), os anéis dos respiros (ferrugem), a tampa do
  duto (ferrugem) e o respiro `EmberVent` (brilho residual 0,06).
- **Lâmpadas de parede:** querosene fraco (`#D9964F`, 0,7); as duas que flutuavam foram presas à parede e
  ao portão.
- **Intocados (C13/C14):** `WorkLight_00` e a luminária (nome, posição, cor, energia); as luminárias 01 e
  02 continuam iguais por coerência. Ganharam só uma **haste** até o cabo aéreo (nó à parte).
- **Ciano:** só o Eco, a marca dele no chão e a lâmpada fria do C13. Nada comum ficou ciano.

## 3. Removido

`assets/vardhelm/prefabs/test_prefab_pillar.tscn` (pilar magenta de teste), dos dados e do disco.
**Mantidos:** as cápsulas dos personagens (trocá-las exige um sistema de personagens) e o `MachineBlock_B`,
que fica fora da baia oeste (pendência).

## 4. LevelBuilder (data-driven, genérico, compatível)

Tudo continua vindo de `level_data/vardhelm_forge_01.json`. O builder ganhou campos **opcionais**; um JSON
que não os use gera exatamente o que gerava antes:

- `room.walls.<lado>`: `height`, `material` e `openings` (`from`/`to`, e `bottom`/`top` para janelas).
  Colisão sempre igual à malha.
- `material_palette.<nome>.shader` + `shader_params` → `ShaderMaterial` (`brick_wall.gdshader`,
  `floor_plates.gdshader`, em coordenadas de mundo, sem UV).
- `props`/`template`: `collision: false` (só para o que o jogador não alcança: estruturas altas e fundo) e
  `rotation_degrees` em primitivas.
- `lights[]`: `color`, `energy`.
- `environment`: `tonemap`, `fog` (densidade, cor, altura) e `ssao`.

O `LevelValidator` valida todos esses campos. A cena `vp_01_vardhelm.tscn` foi **regerada pelo próprio
builder** (fora do editor, com o owner dos nós ajustado antes de salvar; o uid da cena foi preservado).

## 5. Colisões e circulação

- Paredes em corte: parapeitos de 1,1 m com colisão de 1,1 m. Não há salto, então o limite é honesto e
  **não existe parede invisível**.
- A abertura sul leva ao patamar, que é fechado por guarda-corpos de tijolo com colisão.
- Colisões novas: anteparo e moldura do painel, pilastras (dentro da faixa da parede), pilares ao norte
  (menores que os cilindros antigos), 2 apoios da passarela e a coluna do trilho leste da ponte rolante.
- **Ajuste feito durante o bloco:** os apoios da passarela estavam em (±3,8; −3,6) e fechavam o corredor
  ao norte de Durn (só 0,6 m livres). Foram para (±3,3; −5,3).
- **O painel agora só é acessível pela frente** (sul e leste): o anteparo fecha as costas. Antes, o andador
  do playtest do C11 o examinava por trás. O teste foi ajustado para chegar pela frente, na ordem de um
  jogador.
- A câmera **não foi alterada**.

## 6. Desempenho

Medido na GPU integrada (Intel UHD, 1152×648, vsync):

| Configuração | Tempo de quadro |
|---|---|
| Antes do C17 | ~16,6 ms (60 fps) |
| C17 **com** SSAO | ~35 ms (30 fps) |
| C17 sem SSAO | **~16,3 ms (60 fps)** |

Névoa e partículas não têm custo mensurável. O **SSAO fica desligado**; o builder o suporta, mas o nível
não o usa.

## 7. Teste visual humano

F5 → entre em Vardhelm e jogue a sequência normalmente, olhando o espaço. Não é para procurar bugs.

1. A primeira impressão da Forja melhorou?
2. A parede deixou de dominar a câmera?
3. A entrada parece mesmo uma entrada?
4. O espaço parece construído?
5. Existe profundidade?
6. A escala melhorou?
7. A baia oeste tem identidade industrial?
8. O painel parece integrado ao lugar?
9. O fundo sugere um mundo maior?
10. O laranja deixou de competir demais?
11. O ciano do Eco continua especial?
12. A iluminação melhorou a leitura?
13. O cenário parece menos uma coleção de objetos?
14. A jogabilidade continua intacta?
15. C14, C15 e C16 continuam funcionando como antes?

## 8. Pendências

- `MachineBlock_B` (leste) continua um bloco; fica para um bloco visual do setor leste.
- A placa do painel (adereço do AmbientLife, conferido pelo C16) continua lisa e escura; mais luz ou
  textura nela é uma melhoria futura.
- O corredor entre a forja e a máquina A continua estreito com Durn no lugar (isso é anterior ao C17).
- O SSAO pode voltar se o alvo de hardware mudar, ou com uma qualidade reduzida de projeto (não mexi nas
  configurações de renderização do projeto).
- O rótulo flutuante "SETOR INDUSTRIAL" (sudeste) segue como está.

---

## 9. C17.1 — Densidade industrial e vida

> **Status:** implementado, testes automatizados verdes. **Aguarda o teste visual humano** (9.6).
> Feedback que motivou o bloco: "Melhorou, mas ainda parece muito vazio."

### 9.1 Postos de trabalho (micro-histórias sem texto)

Cada posto é um **grupo** no `vardhelm_forge_01.json` (tipo novo do LevelBuilder, `"type": "group"`: um nó
com posição própria e itens primitivos em coordenadas locais).

| Posto | Onde | O que conta |
|---|---|---|
| **ForgeStation_West** | faixa entre a forja e a parede oeste | caixa de carvão, monte de carvão, barras esperando, balde de têmpera com água, tenaz encostada na forja |
| **AnvilStation** | a leste da forja (fora do corredor do painel) | bigorna com uma barra em trabalho e o martelo, tina, marca de carepa no chão, **trabalhador batendo** |
| **WorkbenchStory** | sobre a bancada principal (que não mudou de lugar) | engrenagem sendo trabalhada, chapa, martelo, alicate, lima, bandeja de peças, balde, mancha de óleo |
| **MaintenanceNook** | nicho entre a parede oeste e a máquina A | caixa aberta com peças, tampa encostada, engrenagem e eixo desmontados, chave, lata de óleo, óleo no chão |
| **TransportStack** | faixa norte, sob a passarela | palete com barras amarradas, caixas empilhadas, corrente com gancho pendurada da passarela, **trabalhador carregando** caixa |
| **CraneLoad** | no gancho da ponte rolante | feixe de barras suspenso por lingas, logo acima da máquina A |

### 9.2 Vertical, profundidade e marcas de uso

- **Vertical:** carga na ponte rolante, polia, corrente com gancho no trilho oeste, **tubulação fria** (cobre
  oxidado, acento do blueprint) na parede norte, com braçadeiras, descida e registro; porta-ferramentas na
  parede oeste, perto da forja.
- **Primeiro plano (escuro, enquadramento):** barris no canto sudeste; sacos de lona no canto sudoeste.
- **Fundo:** pórtico, tanque e mais janelas distantes na cidade abaixo.
- **Marcas de uso:** fuligem na boca da forja, carepa sob a bigorna, óleo sob a bancada e no nicho de
  manutenção; vapor no coletor de tubos (leste).

### 9.3 Trabalhadores (AmbientLife existente)

3 trabalhadores novos no `ambient_life.json`, com as rotas simples do sistema de sempre: um na bigorna
(movimento curto), um carregando uma caixa entre o palete e a baia (campo opcional novo `carry`), e um
distante, perto do coletor de tubos (leste). Não há IA nova nem colisão. Durn não mudou. Agora são 7 no
total.

### 9.4 Correções

- **O gancho da ponte rolante (C17) atravessava a máquina A.** Agora ele sobe e segura a carga de barras
  logo acima dela.
- **O `EmberVent` da entrada** ainda aparecia como um bloco laranja (a lâmpada da entrada o iluminava de
  perto). Passou a ferro enferrujado.

### 9.5 Regras mantidas

- **Colisão só no que é volume de verdade e fica em canto morto:** palete, caixas e barris. Todo o resto é
  visual. Nenhum colisor novo fica a menos de 1,5 m de Durn (os dois lugares), da folha, do Eco, da frente
  do painel, do quadro, das ferramentas, do início, da entrada ou do corredor forja × máquina (verificado
  por teste).
- **Nenhum objeto novo tem interação**, então nada captura o E.
- **Emissivos:** nenhum novo. A forja continua sendo o único quente forte, e o Eco o único ciano.
- **Desempenho:** 16,5 ms por quadro (60 fps), o mesmo de antes. O SSAO continua desligado.

### 9.6 Teste visual humano

F5 → jogue a sequência normalmente, olhando o espaço. Responda em poucas palavras:

A) O setor parece menos vazio? · B) A forja parece realmente utilizada? · C) Existem áreas de trabalho
reconhecíveis? · D) O cenário ganhou profundidade? · E) O espaço vertical está sendo utilizado? ·
F) Existem elementos demais? · G) O Eco continua visualmente especial? · H) O painel continua fácil de
encontrar? · I) Durn continua legível? · J) Você continua sabendo para onde ir? · K) Parece uma área
funcional ou uma coleção de objetos? · L) A entrada sul continua funcionando visualmente? · M) A
identidade industrial de Vardhelm ficou mais forte?

Onde olhar: a bigorna a leste da forja (com o trabalhador), a faixa entre a forja e a parede oeste (carvão,
barras, balde), a bancada perto da entrada, o nicho de manutenção atrás da máquina A (noroeste), o palete
sob a passarela (norte) e a carga pendurada na ponte rolante.

---

## 10. C17.2 — Identidade e acabamento

> **Status:** implementado, testes automatizados verdes. **Aguarda o teste visual humano** (10.5).

### 10.1 Auditoria (câmera do jogador)

| Tipo | Elemento | Tratamento |
|---|---|---|
| Temporário | rótulos flutuantes "SETOR INDUSTRIAL" e "FORJA 01" (canto noroeste) | **removidos** |
| Temporário | texto flutuante "FORJA 01 • VARDHELM" sobre o portão | virou **placa de ferro fixa** sob a verga, com "FORJA 01" pintado, voltada para fora |
| Placeholder | `MachineBlock_B` (bloco liso) | vestido como máquina (10.2) |
| Placeholder | `MachineBlock_A` (bloco liso) — **o quadro de manutenção estava enterrado dentro dele** | vestido; quadro visível com folhas na face sul (a observação não mudou) |
| Placeholder | trabalhadores e Durn em cápsula | silhueta humana simples e genérica (10.3) |
| Simplificado | suporte de ferramentas: placa cinza solta no piso | postes, travessa e ferramentas penduradas; placa em madeira |
| Simplificado | bases das estações: lajes cinzas elevadas | estrados de madeira baixos |
| Material | caixas, estantes e bancada em `#6B4A32` (liam laranja-marrom) | madeira velha `#4E3B2A` |
| Integração | colunas e postes nascendo do piso sem base | chapas de base |

### 10.2 Máquinas (grupos de dados, mesma ferramenta do C17.1)

- **Máquina B:** plinto, cintas, carcaça superior com chaminé curta, volante com cubo, correia de borracha até um motor, manômetros, portinhola de manutenção, cano de cobre até o coletor de tubos (leste: máquina → tubo → infraestrutura), óleo no chão. A colisão continua sendo o corpo de sempre, mais o motor (canto sudeste, longe dos caminhos).
- **Máquina A:** plinto, cinta, **quadro com folhas** (onde a observação sempre esteve), cano de cobre subindo até a parede norte, manômetro, portinhola, óleo. Sem colisão nova.
- **Ajuste:** a primeira versão da máquina B tinha uma chaminé alta que, na projeção isométrica, ficava **exatamente embaixo do Eco** na tela. Foi trocada por uma chaminé curta. Um teste novo garante que nada decorativo fique na frente do Eco ou do painel na câmera do jogador.

### 10.3 Pessoas

- `HumanoidSilhouette` (novo, genérico, só visual): pernas, tronco, braços, cabeça; avental e boné opcionais; braços à frente quando carrega algo. Sem rig, animação, colisão ou IA.
- **Trabalhadores:** usam a silhueta pelo AmbientLife (`accent` = camisa, `outfit` opcional no JSON), com camisas de cores apagadas da paleta; avental na forja, na bigorna e na manutenção; boné na bancada, no depósito e no transporte.
- **Durn:** a mesma silhueta, mas com **casaco longo** no tom de couro que já o identificava, um pouco mais alto, e a placa "DURN". A cápsula antiga ficou só oculta; colisão, interação, prioridade, posição, rota e C15/C16 inalterados.

### 10.4 Luz, desempenho, LevelBuilder

- Nenhuma luz nova, nenhum emissivo novo. A forja continua o único quente forte, e o Eco/painel o único ciano. O SSAO segue desligado.
- **16,5 ms por quadro** (60 fps), igual ao C17.1.
- Nenhum recurso novo no LevelBuilder: as máquinas e o suporte usam o tipo `group` do C17.1. O AmbientLife ganhou a cor opcional `color` nos adereços de história.

### 10.5 Teste visual humano

F5 → jogue normalmente. Onde olhar: a **máquina grande a sudeste** (volante, manômetros, cano até os tubos), a **máquina a noroeste** com o quadro de avisos, os **trabalhadores** (avental ou boné), **Durn** (casaco claro, mais alto, placa DURN), a **placa "FORJA 01"** no portão e o **suporte de ferramentas** perto da bancada.

A) O MachineBlock_B agora parece uma máquina? · B) Os trabalhadores parecem menos placeholders? ·
C) Durn continua claramente identificável? · D) O rótulo técnico desapareceu? · E) As máquinas parecem
integradas à infraestrutura? · F) Os materiais parecem do mesmo mundo? · G) A escala parece coerente? ·
H) O cenário parece mais "produzido"? · I) Menos "protótipo"? · J) O Eco continua especial? · K) O painel
continua claro? · L) A atmosfera industrial foi preservada? · M) Ficou mais interessante sem ficar carregado?

---

## 11. C17.3 — Colisão corporal dos trabalhadores

> **Status:** implementado, testes automatizados verdes. **Aguarda o teste humano** (11.4).
> Problema relatado: "O jogador está transpassando os trabalhadores."

### 11.1 Solução

- Cada trabalhador comum ganha um **`AnimatableBody3D`** filho (`BodyCollider`) com uma **`CapsuleShape3D`**
  de **raio 0,25 m e altura 1,7 m**. Ela cobre só pernas e tronco (sem cabeça, braços ou roupa); a
  silhueta tem cerca de 0,5 m de largura no corpo e 1,9 m de altura.
- O corpo é filho do trabalhador, então acompanha o tween da rota **sem processamento novo**. É o tipo de
  corpo feito para ser movido por animação/tween: se o trabalhador anda contra o jogador, o jogador é
  deslocado; **a rota nunca depende da física**, então o trabalhador não trava, não treme e sempre chega.
- **Camadas:** camada 1 (a do cenário, que o jogador já colide), máscara 0. Trabalhadores não detectam nada,
  não colidem entre si nem com o cenário, e ficam fora da camada 2 (interação): o detector do E não os
  enxerga. Nenhuma camada nova.
- **Configuração:** `"worker_body": {"radius": 0.25, "height": 1.7}` no `ambient_life.json` (sem essa
  chave, trabalhadores sem corpo, como antes).
- **Durn não mudou:** ele é montado pelo slice, não pelo AmbientLife; continua com um corpo e uma área de
  interação.
- **Nenhuma rota ou posição mudou.**

### 11.2 Passagens

Com raio 0,25 + jogador 0,4, é preciso 0,65 m entre os centros. Conferido nas passagens:

- trabalhador da manutenção na boca do corredor forja × máquina: sobra ~1,0 m;
- trabalhador da bancada depois do Eco, ao lado do anteparo: a bigorna não tem colisão, então a passagem
  fica aberta;
- bancada, bigorna, carregador (norte), depósito e distante: em área aberta.

O corredor forja × máquina continua estreito **por causa de Durn**, como antes do C17.

### 11.3 Testes

- **Runner:** um corpo leve por trabalhador (camada 1, máscara 0), sem área de interação. O teste do C17.1,
  que afirmava "sem colisão", foi atualizado para isso.
- **Playtest novo `c17_3_worker_collision_playtest.gd`** (física real, input real), 11/11, renderizado e
  headless:
  - A. andando direto contra o trabalhador, o jogador para no corpo (0,60 m entre os centros);
  - B. um passo para o lado e ele o contorna;
  - C/D. com o jogador no meio da rota, o trabalhador vai e volta; o carregador segue andando;
  - E. Durn com um corpo e uma área, no mesmo lugar;
  - F/G/H. Eco, painel (pela frente) e lugar da folha alcançáveis;
  - I. ao lado de cada trabalhador, o E não os escolhe;
  - J. Save → mover → Load: sucesso, sem duplicar corpos.

- **Playtest do C15 ajustado:** o andador ia do Eco ao painel em linha reta e agora esbarrava no trabalhador da bigorna (a linha passava a 0,32 m dele). Passou a ir pela rota aberta (leste da forja → frente do painel), como no C11. Nenhum trabalhador foi movido: o bloqueio não é intransponível; basta contornar, como mostra o item B.
- **Desempenho:** 16,35 ms por quadro (60 fps), igual a antes.

### 11.4 Teste humano

F5 →

1. Encontre pelo menos dois trabalhadores.
2. Caminhe direto contra eles.
3. Confirme que não atravessa o corpo.
4. Contorne os trabalhadores.
5. Veja se eles continuam andando normalmente.
6. Repita perto da forja (o trabalhador da bigorna, a leste dela).
7. Repita perto da bancada (entrada).
8. Repita perto da passarela (o carregador, ao norte).
9. Confirme que Durn continua normal.
10. Confirme que o Eco, o painel e a folha continuam acessíveis.
