# EVT-ESCOLHA-FINAL-001 — O Veredito da Balança
**Evento de Fechamento de Campanha — Ato 5 / Beat 6**
**Status:** Script Técnico de Encerramento — Versão 1.0

---

## ESTRUTURA DO EVENTO

O evento de escolha final é processado em **duas zonas sequenciais**, dividindo os 6 Beats do Bloco 31 original:

| Zona | Beats | Descrição |
|------|-------|-----------|
| ENT-NUCLEO-001 | Beats 2–4 | Revelação: A verdade sobre a Balança e o preço do equilíbrio |
| LOC-VER-003 | Beat 6 | Veredito: A escolha binária de convicção ética |

**Beat 1 (Prólogo do Confronto)** e **Beat 5 (Processamento da Escolha)** são transições técnicas entre as zonas.

---

## BEAT 1 — PRÓLOGO DO CONFRONTO (Transição)

**Contexto:** Imediatamente após a derrota do Juízo da Balança (MON-ERR-BOSS-01). O campo de batalha se desfaz em partículas de luz e cinza. O jogador está no **Núcleo do Vértice**, o ponto zero da malha de Estafa.

**Estado do Sistema:**
- Barra de Estafa: Zerada (reset pós-batalha).
- Todas as habilidades disponíveis.
- Relíquias ontológicas: Ativas.
- WorldState: "VEREDICTO_IMINENTE".

**Narrativa:**
> A Balança range uma última vez. O silêncio não é paz — é o peso de tudo que foi sacrificado para chegar até aqui. Diante de você, duas silhuetas emergem das cinzas do Juízo: Kael, o Ferreiro de Aço, e Elyra, a Última Arconte Rúnica. Ambos estendem a mão. Ambos oferecem um caminho. A malha aguarda sua decisão.

---

## ZONA ENT-NUCLEO-001 — REVELAÇÃO (Beats 2–4)

### Beat 2 — A Exposição de Kael (Tese Paterna)

**Kael avança.** Sua armadura de aço reflete a luz fria do núcleo.

> "Você viu o que a estagnação fez com este mundo. A malha apodrece porque ninguém ousa forjá-la novamente. O equilíbrio é uma mentira que os fracos contam para si mesmos. O que este mundo precisa é de progresso — custe o que custar. Eu posso forjar uma nova era. Uma era de aço, de movimento, de evolução. Mas preciso de você para puxar o gatilho."

**Parâmetros da Oferta (ROTA A):**
- **WorldState resultante:** "ERA_DO_ACO"
- **Tom:** Progresso a qualquer custo. Sacrifício dos resquícios da malha antiga.
- **Custo Ético:** A destruição completa da malha de Estafa como conhecida. Milhares de vidas ligadas à malha serão perdidas.
- **Recompensa:** Um mundo forjado do zero, sem as amarras do equilíbrio forçado.

---

### Beat 3 — A Exposição de Elyra (Tese Materna)

**Elyra flutua** em direção ao jogador. Runas de luz dançam ao redor de seus braços.

> "Kael oferece progresso, mas o progresso sem memória é apenas destruição. A malha não é uma prisão — é um testamento. Cada fio carrega a história de alguém que veio antes de nós. Preservar a Estase Rúnica não é estagnação; é honrar o que foi construído. Podemos curar a malha, restaurar o que foi corrompido. Mas isso exige que você recuse o martelo de Kael. A escolha é sua."

**Parâmetros da Oferta (ROTA B):**
- **WorldState resultante:** "ESTASE_RUNICA"
- **Tom:** Preservação e cura. Restauração da malha original.
- **Custo Ético:** A manutenção das estruturas de poder existentes. Aqueles que prosperam na desigualdade da malha permanecem.
- **Recompensa:** Um mundo curado, com a memória e a história intactas.

---

### Beat 4 — O Peso da Escolha (Processamento de Convicção)

O jogo apresenta ao jogador as duas opções de forma explícita. Nenhuma terceira via é oferecida.

**Opção A — "Forjar uma nova era" (ROTA A — Kael)**
- WorldState → "ERA_DO_ACO"
- A malha é desfeita. O mundo renasce do aço e do fogo.

**Opção B — "Preservar o que resta" (ROTA B — Elyra)**
- WorldState → "ESTASE_RUNICA"
- A malha é curada. O mundo permanece, mas inalterado em suas fundações.

---

## BEAT 5 — PROCESSAMENTO DA ESCOLHA (Transição Técnica)

**Regras de Processamento:**

1. O jogo registra a escolha do jogador.
2. O WorldState é atualizado para "ERA_DO_ACO" ou "ESTASE_RUNICA".
3. O sistema verifica a **Maestria da Build Neutra Máxima**:
   - **Condição:** REL-ONT-003 (Chassi Estático Primordial) equipada **E** SKL-NEU-050 (Ancoragem do Ponteiro Absoluto) desbloqueada.
   - **Se verdadeiro:** Ativa o **Modificador de Tom Neutro** (ver seção abaixo).
   - **Se falso:** Prossegue sem modificador.

---

### Modificador de Tom Neutro (Maestria da Build Neutra Máxima)

A build Neutra Máxima não cria um terceiro final. Em vez disso, ela atua como um **modificador de tom e mitigação de danos** para o lado rejeitado.

**Efeito Mecânico-Narrativo:**

1. **Cena de Mitigação:** Imediatamente após a escolha, o personagem não-escolhido (Kael se ROTA B, Elyra se ROTA A) sofre um colapso de Estafa. A Ancoragem do Ponteiro Absoluto (SKL-NEU-050) é usada **narrativamente** para estabilizar o lado rejeitado, evitando sua destruição total.
   - **ROTA A (Kael escolhido):** Elyra começa a se desfazer em runas. O jogador usa a Ancoragem para cravar seu espírito na malha, preservando sua essência como uma memória viva no novo mundo de aço.
   - **ROTA B (Elyra escolhido):** Kael é consumido pelo fogo de sua própria forja. O jogador usa a Ancoragem para extrair seu martelo e sua chama, que se tornam relíquias na Estase Rúnica — um lembrete do caminho não trilhado.

2. **Modificador de Tom:** A cena de encerramento ganha um tom **bittersweet** (agridoce) em vez de trágico. O lado rejeitado não é aniquilado, mas transformado em algo que perdura.

3. **Bônus de Finalização:** O jogador recebe o título **"Ponteiro Absoluto"** e um item cosmético memorial (Âncora do Equilíbrio) que referencia o caminho não escolhido.

**Importante:** Este modificador **não altera o WorldState**. A ROTA A ainda resulta em "ERA_DO_ACO" e a ROTA B em "ESTASE_RUNICA". A diferença é exclusivamente tonal e de mitigação de danos narrativos.

---

## ZONA LOC-VER-003 — VEREDITO (Beat 6)

### Beat 6 — A Balança se Aquieta

A cena final é processada de acordo com a escolha do jogador e o modificador de Maestria.

---

### ROTA A — WorldState: "ERA_DO_ACO"

**Sem Modificador Neutro (Build não-Neutra):**

> Kael golpeia o núcleo da malha com seu martelo. O mundo estilhaça como vidro. A luz se apaga. Quando ela retorna, tudo é diferente. O aço cobre o horizonte. A malha de Estafa não existe mais — apenas o progresso, implacável e belo. Elyra não está em lugar nenhum. Você nunca mais ouvirá a voz dela. O preço foi pago.

**Com Modificador Neutro (Build Neutra Máxima):**

> Kael golpeia o núcleo. O mundo estilhaça. Mas antes que Elyra se desfaça completamente, você crava o Ponteiro Absoluto. Ela não sobrevive — mas sua essência se cristaliza em uma runa que flutua sobre o novo mundo de aço. Kael olha para você, e pela primeira vez, há algo parecido com gratidão em seus olhos. O progresso tem um preço, mas nem tudo foi perdido. A âncora em seu peito pulsa com a memória do que poderia ter sido.

**Consequências Globais:**
- A malha de Estafa é desfeita.
- O mundo entra em uma era de reconstrução industrial e tecnológica.
- Personagens ligados à malha (incluindo Elyra, sem modificador) são perdidos.
- O jogador é lembrado como "O Ferreiro do Veredito".

---

### ROTA B — WorldState: "ESTASE_RUNICA"

**Sem Modificador Neutro (Build não-Neutra):**

> Elyra entrelaça suas runas na malha ferida. A luz se espalha como água curando uma ferida. Aos poucos, o mundo se estabiliza. A malha está intacta — mas Kael caiu, consumido pelo fogo de sua própria forja. Você nunca mais ouvirá o som de seu martelo. A preservação tem um preço. A estase rúnica é bela, mas silenciosa.

**Com Modificador Neutro (Build Neutra Máxima):**

> Elyra entrelaça suas runas na malha. A luz se espalha. Kael começa a cair, mas você crava o Ponteiro Absoluto em seu martelo, extraindo sua chama antes que ela se apague. O martelo repousa agora no centro da Estase Rúnica — um monumento ao caminho não trilhado. Elyra toca seu ombro. "Você fez a escolha certa", ela diz. Mas ambas sabem que "certa" é uma palavra pesada demais para carregar sozinha.

**Consequências Globais:**
- A malha de Estafa é curada e preservada.
- O mundo permanece em sua estrutura atual, com suas desigualdades e belezas.
- Personagens ligados ao progresso (incluindo Kael, sem modificador) são perdidos.
- O jogador é lembrado como "O Guardião do Equilíbrio".

---

## TABELA DE ESTADOS FINAIS

| Rota | WorldState | Modificador Neutro | Tom | Personagem Rejeitado | Título do Jogador |
|------|------------|-------------------|-----|---------------------|-------------------|
| A | ERA_DO_ACO | Não | Triunfo trágico | Elyra (perdida) | Ferreiro do Veredito |
| A | ERA_DO_ACO | Sim | Bittersweet | Elyra (preservada como memória) | Ponteiro Absoluto |
| B | ESTASE_RUNICA | Não | Sacrifício silencioso | Kael (perdido) | Guardião do Equilíbrio |
| B | ESTASE_RUNICA | Sim | Bittersweet | Kael (preservado como relíquia) | Ponteiro Absoluto |

---

## NOTAS TÉCNICAS

- O evento **não** oferece uma terceira opção de rota. A escolha é estritamente binária entre Kael e Elyra.
- O Modificador Neutro **não** altera o WorldState — apenas o tom e a mitigação de danos narrativos.
- O título "Ponteiro Absoluto" é concedido **apenas** na build Neutra Máxima, independentemente da rota escolhida.
- A cena final (Beat 6) é a última cena jogável da campanha base 1.0. Créditos sobem após a conclusão.

---

**Fim do Documento — EVT-ESCOLHA-FINAL-001.md**
**Versão 1.0 — Projeto Aetheris**