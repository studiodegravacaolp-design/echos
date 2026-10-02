# Vardhelm — Design da investigação (Fase 5 do Ato 1)

**Bloco:** C24 (2026-10-01). **Design narrativo; nada implementado.**
**Cânone de referência:** [`docs/lore/VARDHELM_ACT1_CANON.md`](../lore/VARDHELM_ACT1_CANON.md) e [`docs/lore/LORE_REVELATION_MATRIX.md`](../lore/LORE_REVELATION_MATRIX.md).
**Registro do bloco:** [`docs/architecture/BLOCK_C24_VARDHELM_INVESTIGATION.md`](../architecture/BLOCK_C24_VARDHELM_INVESTIGATION.md).

## Classificação

Toda decisão abaixo traz uma etiqueta:

| Etiqueta | Significado |
|---|---|
| **[A]** | já canônica |
| **[B]** | derivada diretamente do cânone ou do que já está no jogo |
| **[C]** | proposta de design (**não é cânone**) |
| **[D]** | decisão humana necessária |
| **[E]** | deliberadamente reservada |

Uma proposta **[C]** só vira cânone por decisão humana.

## Decisões humanas aprovadas depois do C24 (C24.1)

Estas decisões **substituem** as recomendações correspondentes do texto abaixo (marcadas com "→ **H#**"). O que elas deixam em aberto continua **[D]** ou **[E]**.

| # | Decisão | Classe agora | O que continua aberto |
|---|---|---|---|
| **H1** | O painel **permanece fechado durante a investigação**. A abertura ou ruptura fica reservada ao **clímax de Vardhelm**. O que ele revelar será **material e concreto**, sem explicar a cosmologia. | [A] decisão humana | o que exatamente o painel revela [D] |
| **H2** | Durn **permanece na Forja**. Pode reagir quando o protagonista volta. **Deixa aos poucos de ser o motor da investigação.** Não é companheiro nem expositor. | [A] decisão humana | participação no clímax: possível, **não definida** [D] |
| **H3** | O Galpão de Manufatura tem relação com o **histórico operacional do reforço/selamento do painel** e fornece **documentação ou rastro operacional** que faz a investigação avançar. | [A] decisão humana | posição, forma do registro e conteúdo [D] |
| **H4** | Elyra investiga **o que existia na área antes das fundições**. O protagonista pergunta "o que aconteceu aqui agora?"; Elyra pergunta "o que existia aqui antes?". As investigações **convergem sobre evidências ou registros relacionados**. | [A] decisão humana | local e momento do encontro; registro exato [D] |
| **H5** | O termo **"Véu" NÃO será introduzido ainda**: nem Durn, nem o protagonista, nem o primeiro encontro com Elyra o nomeiam. | [A] decisão humana | quando o termo entra: não definido [E] |
| **H6** | A **natureza exata do conflito permanece NÃO DEFINIDA.** A hipótese combinada (K-4) continua **candidata, não cânone**. | [D] | tudo [D] |
| **H7** | Verdade parcial aprovada **conceitualmente**: *"Isso já aconteceu antes. Alguém reconheceu o perigo, algo foi selado, e parte dos registros desapareceu."* | [A] (conceito) | **quem**, **por quê**, **o que** foi selado [D]; a natureza cosmológica do fenômeno [E] |
| **H8** | **Progressão narrativa, NÃO relógio**, dispara os eventos importantes do painel. Nenhum evento crítico da investigação depende de tempo real decorrido. | [A] decisão humana | — |
| **H9** | A ponte entre "arqueóloga élfica" e "Última Arconte Rúnica" fica **DELIBERADAMENTE RESERVADA**; não se resolve agora. | [E] | — |

---

## 0. Ponto de partida: o que o jogo já estabeleceu [A]

| Elemento | O que já existe (texto ou comportamento no jogo) |
|---|---|
| Primeiro Eco | evento incitante; memória registrada; consequência `first_echo_complete` |
| Painel selado | "Uma placa metálica foi **fechada e reforçada**. Não há instrução sobre o que existe atrás dela." Depois do Eco: "a impressão de ouvir uma **vibração** do outro lado". Memória: "algo mantido atrás de uma barreira **que ninguém explica**" |
| Durn | "...O painel selado, no fundo do setor. **Hoje ele fez um barulho que eu nunca tinha ouvido.**" / "Então não fui só eu." |
| Folha de Durn (só no caminho "Não senti nada.") | "**Horários anotados à mão, todos de hoje.** O último está **sublinhado duas vezes**." |
| Quadro de manutenção (Forja) | "Anotações de reparo, **horários** e marcas de uso." Depois do Eco: "uma **marca quase apagada** chama sua atenção. Você não consegue dizer se ela sempre esteve ali." |
| Suporte de ferramentas | depois do Eco: "Uma delas parece **familiar** por um motivo que você não consegue explicar." |
| Forja reage (C13) | luz fria e falhando sobre o painel; um trabalhador sai da rotina; **máquinas mais baixas** |
| Pátio (C21) | o respiro da Forja 01 solta menos fumaça; "o barulho da Forja 01 chega mais baixo do que antes" |
| Rua (C23) | "Daqui da rua, a Forja 01 soa **mais baixa que as outras fundições**." Quadro de turnos: "os nomes mudam; **os horários continuam os mesmos**" |
| Memórias | todas dizem "Você registrou a lembrança de…": o protagonista registra impressões de lugares |

**Princípio aplicado [B]:** reutilizar consequência existente antes de criar fenômeno novo. A investigação abaixo nasce desses elementos: **horários**, **registros**, **o painel reforçado** e **a Forja diferente das outras**.

## 1. Mistério local × mistério global

| | Pergunta | Vardhelm responde? |
|---|---|---|
| **Mistério local [B]** | "Por que a Forja 01, e só ela, mudou depois do que aconteceu? O que o painel guarda, e por que foi selado?" | **em parte**, no fim do Ato 1 |
| **Mistério global [E]** | o que são os Ecos, o Véu, Aethel, Asterion, o Homem Cinzento, o Último Experimento | **não** (camadas 2 e 3 da matriz) |

## 2. Por que o protagonista investiga

1. **Ele sentiu algo [A].** O Eco foi uma experiência pessoal, e a memória ficou registrada.
2. **Não foi só ele [A].** Durn também ouviu ("Então não fui só eu.").
3. **Há uma diferença que se mede [A/B].** Da rua, a Forja 01 soa mais baixa que as outras fundições. Algo mudou **num lugar só**, e qualquer trabalhador perceberia.
4. **Há registros que não fecham [A/B].** O painel foi reforçado sem explicação, e uma marca no quadro de manutenção parece apagada.

**Motivação formal [C]:** o protagonista quer entender **o que aconteceu com ele**, e a cidade mostra que **aconteceu com um lugar também**. A pergunta passa de "o que eu senti?" para **"o que este lugar está escondendo?"**. Não é uma lista de pistas; é a diferença entre a Forja 01 e as outras fundições, que se pode medir.

## 3. Gatilho e escalada

```
INCIDENTE LOCAL [A]   Primeiro Eco · painel vibra · a Forja baixa
      ↓
ANOMALIA [A/B]        só a Forja 01 mudou (pátio, rua) · Durn ouviu também
      ↓
REGISTRO [B/C]        horários: a folha de Durn (hoje) e o quadro de manutenção (marca apagada)
      ↓
PADRÃO [C]            os horários se repetem / batem com algo da operação da cidade
      ↓
ORIGEM DO SELO [C]    quem reforçou o painel, e quando → Galpão de Manufatura (ordens de serviço)
      ↓
CRUZAMENTO [C]        Elyra procura o mesmo registro por outro motivo
      ↓
IMPLICAÇÃO MAIOR [C]  isto já aconteceu antes, e houve uma decisão de selar e calar
      ↓
CONFLITO [D]          a investigação incomoda algo ou alguém (natureza a decidir)
```

Cada etapa muda o que o jogador entende:
1. eu senti;
2. o lugar sentiu;
3. alguém anotou;
4. há um ritmo;
5. alguém selou;
6. outra pessoa também procura;
7. não é a primeira vez;
8. há quem não queira que se saiba.

Isso evita "Eco → mais Eco → mais Eco".

## 4. Sequência de indícios (sem caça a colecionáveis)

→ **H8 (decidido):** o "evento do painel" abaixo é disparado por **progressão narrativa**, não por horário nem relógio. Os "horários" são conteúdo dos registros, não um mecanismo de tempo.

| Indício | Onde | Como chega ao jogador | Ordem | Classe |
|---|---|---|---|---|
| A Forja 01 está diferente das outras | pátio / rua | observação (já existe) | livre | [A] |
| **Horários de hoje** | folha de Durn (caminho B) **ou** conversa com Durn (caminho A) | observação **ou** diálogo | depois do gancho | [B]/[C] |
| A marca apagada no quadro de manutenção | Forja | observação pós-Eco (já existe); depois da investigação ganha leitura nova (um horário antigo?) | livre | [A]/[C] |
| Os horários dos turnos não mudam | rua | observação (já existe); com os horários de Durn, vira comparação | livre | [A]/[C] |
| Quem reforçou o painel | Galpão de Manufatura | registro de serviço (ambiente ou documento) | depois do padrão | [C] |
| O mesmo tipo de registro, antigo | Galpão / arquivo | encontrado **junto com Elyra** ou por ela | encontro | [C] |

**Formas de chegar à informação [B]:** exploração, observação, conversa (Durn), consequência (caminho A/B) e evento (o painel vibra de novo num horário que o jogador pode testemunhar, [C]). As três primeiras linhas podem ser vistas em ordens diferentes.

## 5. Papel de cada lugar

→ **H3 (decidido):** o Galpão guarda o histórico operacional do reforço/selamento do painel e fornece o rastro que faz a investigação avançar.

| Lugar | Papel na investigação | Classe |
|---|---|---|
| **Forja 01** | origem: painel, quadro de manutenção, Durn | [A] |
| **Pátio** | primeira prova de que a mudança se vê de fora | [A] |
| **Rua (C23)** | a cidade como **instrumento de medida**: a Forja 01 comparada às outras; turnos com horários fixos; o fluxo do minério e da carga como "relógio" da cidade | [B]/[C]; **integração futura** na rua (registrada, não feita) |
| **Galpão de Manufatura** | **onde o selo foi feito.** O painel é uma "placa metálica fechada e **reforçada**", trabalho de manufatura. O protagonista entra para descobrir **quem reforçou, quando e a pedido de quem** | [C]: razão narrativa proposta; o Galpão só se constrói se a decisão D3 for aceita |
| **Rotas comerciais** | sem papel na investigação; ficam para a saída (Fase 10) | [A]/[E] |

## 6. O painel selado

**Leitura atual [A]:**
- é uma promessa: reforçado, sem instrução, vibrou no dia do Eco, e Durn nunca tinha ouvido aquilo;
- é o lugar onde a Forja reage (luz fria).

**Opções [D]:**

| | O painel… | A favor | Contra |
|---|---|---|---|
| A | fica fechado durante boa parte do ato | mantém a promessa; a investigação é **sobre** ele, sem abri-lo | precisa render algo antes do fim |
| B | abre durante a investigação | revelação no meio do ato | gasta cedo o principal mistério local |
| C | abre no clímax | clímax com objeto concreto; a verdade parcial vem dele | precisa de construção cuidadosa até lá |
| D | não abre: o que importa é **por que foi selado** (registros), não o que há atrás | mantém o mistério global intacto; Vardhelm responde "quem e por quê", não "o quê" | pode frustrar se nada for mostrado |

**Recomendação [C]: A + C, com D como conteúdo.**

→ **H1 (decidido):** fechado durante a investigação; abertura ou ruptura reservada ao clímax; revelação material e concreta, sem cosmologia. O conteúdo exato continua [D].
- O painel fica fechado durante a investigação.
- O que se investiga é **o selo**: quem, quando, por quê.
- No clímax ele se abre ou se rompe, e mostra algo **concreto e parcial**, sem nomear a causa global.

## 7. Continuidade da escolha "Não senti nada." / "Sentir o quê?"

**Proposta [C]: a mesma informação por caminhos diferentes, e uma relação diferente com Durn.** Sem grande bifurcação.

| | Caminho A ("Sentir o quê?") | Caminho B ("Não senti nada.") |
|---|---|---|
| Os horários | Durn **conta** os horários quando o jogador volta a ele ("anotei quando ouvi") | o jogador **já tem** a folha. Pode mostrá-la a Durn, que reage ao ver que ela foi lida |
| Relação | Durn confia no jogador (ele admitiu sentir) | Durn foi sozinho. Ao saber que o jogador mentiu ou negou, fica mais reservado, mas a informação chega |
| Impacto | o caminho é o mesmo daí em diante; muda o **tom** de Durn e **quando** a pista aparece | idem |

**Por que isso basta [B]:** a escolha deixa de ser "30 segundos de consequência" e passa a definir **como** o jogador obtém a primeira pista concreta e **como** Durn o trata, sem multiplicar o conteúdo.

## 8. Durn

**Pode [A]:** lembrar, observar, desconfiar, reconhecer a Forja estranha, dar contexto local (turnos, quem trabalha onde, quem fez manutenção).
**Não pode [A]:** explicar o fenômeno, virar enciclopédia, conhecer o Véu.

**Opções para o futuro de Durn [D]:**

| | Função | Observação |
|---|---|---|
| D-1 | **termina aos poucos**: dá os horários e o nome de quem reforçou o painel (contexto local) e fica na Forja | coerente com "sabe pouco" |
| D-2 | **testemunha recorrente**: reage a cada avanço quando o jogador volta à Forja | mantém o vínculo humano |
| D-3 | **reaparece no clímax** (a Forja é o lugar dele) | dá peso ao fim do arco |

**Recomendação [C]:** D-1 com um toque de D-2 (reage quando o jogador volta) e D-3 só se o clímax for na Forja.

→ **H2 (decidido):** Durn fica na Forja, reage quando o protagonista volta e deixa aos poucos de ser o motor da investigação. Não é companheiro nem expositor. O clímax continua possível, mas **não definido**.

## 9. Elyra

**Cânone [A]:** participa do Ato 1; arqueóloga élfica; memória e verdade; conhecimento incompleto; linhagem só no Ato 4.

**Motivo independente [C] (opções [D]):**

→ **H4 (decidido):** Elyra investiga **o que existia na área antes das fundições** (corresponde à opção E-3). As tabelas abaixo ficam como registro das alternativas.

| | Elyra está em Vardhelm porque… | Liga-se à investigação por… |
|---|---|---|
| E-1 | estuda **vestígios antigos sob ou dentro das fundições** (as instalações mais velhas do distrito) | o painel ou a área dele está entre esses vestígios |
| E-2 | rastreia **registros de ocorrências parecidas em vários lugares**, como arquivo e memória | o selo da Forja 01 é um desses registros |
| E-3 | pesquisa **a história das fundições** (o que havia antes delas) | a Forja 01 fica num ponto que interessa à pesquisa |

**Ponto de encontro [C]:** **as duas investigações chegam ao mesmo registro.** O protagonista procura quem reforçou o painel (ordens de serviço no Galpão). Elyra procura o mesmo documento, ou registros antigos do mesmo lugar, pelo motivo dela. Ninguém estava esperando o outro.

**Diferença de conhecimento [C]:**

| Protagonista tem | Elyra tem |
|---|---|
| a **experiência**: sentiu o Eco, guarda os fragmentos de memória, tem o testemunho de Durn e os horários | **conhecimento histórico**: sabe ler registros antigos, reconhece que o padrão tem profundidade histórica e conhece ocorrências parecidas (sem a causa) |
| não sabe ler o passado | **não viveu** o fenômeno: só tem relatos e documentos |

Um precisa do outro. **[E]** Elyra **não** explica Aethel, AETHERIS, Asterion, o Homem Cinzento, o Último Experimento nem a própria linhagem.

## 10. O Véu

**Recomendação [C] (decisão [D]):**

→ **H5 (decidido):** o termo "Véu" **não será introduzido ainda**, nem pelo primeiro encontro com Elyra. A recomendação abaixo (Elyra usar o termo sem definir) foi **descartada** para Vardhelm por enquanto.

- O protagonista e Durn **não usam** a palavra. Os fenômenos ficam **sem nome** ("aquilo", "o barulho", "o que aconteceu").
- **Se** a palavra aparecer no Ato 1, quem a usa é **Elyra**, como **termo de tradição ou de texto antigo élfico** que ela conhece academicamente, com cautela e **sem definir**. O protagonista não entende.
- Pela matriz, o Véu como conceito compreendido é da camada 2 (Atos posteriores).

## 11. Conflito

→ **H6:** a natureza exata do conflito continua **NÃO DEFINIDA**. K-4 é candidata, não cânone.

**O que existe [A]:** o Ato 1 terá combate; os documentos falam de um "**monstro padrão de Vardhelm**", sem dizer qual. Não há bestiário de Vardhelm no repositório; o bestiário do CLI é de Brenhold [histórico].

**Como a investigação pode levar ao conflito (opções [D]):**

| | Natureza | Ligação com o que existe |
|---|---|---|
| K-1 | **humano**: alguém (quem mandou selar? a administração da fundição?) reage a quem mexe no assunto | "barreira que ninguém explica"; marca apagada (alguém apagou?) |
| K-2 | **criatura**: algo atraído ou desperto onde o fenômeno acontece | "monstro padrão de Vardhelm" [A]; natureza [E] |
| K-3 | **ambiental/industrial**: a instalação reage (máquinas, vibração, falha), e o perigo é o próprio lugar | C13 (máquinas e luz reagem); painel vibra |
| K-4 | **combinação**: o perigo físico (K-3/K-2) aparece porque alguém escondeu o que sabia (K-1) | une o mistério local ao conflito |

**Recomendação [C]:**
- **K-4**, com o primeiro combate em **K-2 ou K-3**, ligado a um lugar da investigação (nunca "inimigos na rua por acaso").
- O conflito humano (K-1) dá o **porquê**; o combate dá o **perigo**.

## 12. Descoberta parcial (o tipo de verdade)

**Proposta [C] (decisão [D]):** *"O que aconteceu na Forja 01 **já aconteceu antes**. Na vez anterior, o lugar foi **selado e reforçado**, e o registro **apagado**. Não se sabe o que causa, mas alguém decidiu esconder."*
- Usa só o que já existe: o reforço, a marca apagada, "ninguém explica", os horários.
- Responde parte do mistério local (**houve antes, e houve silêncio**).
- Não toca o mistério global (**o que** é o fenômeno fica [E]).

**Alternativas [D]:**

→ **H7 (aprovado conceitualmente):** *"Isso já aconteceu antes. Alguém reconheceu o perigo, algo foi selado, e parte dos registros desapareceu."* Quem, por quê e o que foi selado continuam [D]; a natureza cosmológica, [E]. As alternativas abaixo ficam só como registro.

- "certos materiais ou máquinas respondem ao fenômeno" (liga com C13 e o reforço metálico);
- "os horários seguem um ritmo que não é da cidade".

## 13. Agência

| Onde | Tipo |
|---|---|
| Caminho A ou B (C15) | consequência: como a pista dos horários chega e o tom de Durn |
| Forja, pátio e rua | ordem livre das observações; leitura nova de observações antigas depois da pista |
| Conversas com Durn | escolha de perguntar ou mostrar a folha; o quanto contar |
| Encontro com Elyra | **o que o protagonista conta** (a experiência inteira ou só os registros), mudando o que ela sabe e o tom da parceria [C] |
| Evento do painel | testemunhar ou não a vibração num horário (opcional) [C] |

Sem árvore grande: **ordem livre + 2 pontos de escolha com consequência + informação opcional**.

## 14. Memória

**O que existe [A]:**
- o Eco gera memória;
- as observações podem gerar **fragmentos** ("Você registrou a lembrança de…");
- consequência, memória e observação são separadas;
- a composição de fragmentos fica para o futuro, sem implementação.

**Proposta para Vardhelm [C]:**
- **Nem toda memória vem de Eco.** O Primeiro Eco gera a memória principal; observações importantes da investigação geram **fragmentos**.
- **Ambiguidade deliberada [E]:** os fragmentos parecem registro do protagonista, mas há sinais de que não são só dele ("uma delas parece **familiar** por um motivo que você não consegue explicar"). **O jogador não consegue distinguir** neste estágio, e não deve.
- Nada de composição de fragmentos agora.

## 15. O que fica desconhecido no fim de Vardhelm [E]

- O que o fenômeno (o Eco) **é**.
- Por que o protagonista o percebe.
- O que existe por trás do painel, em sentido global. O conteúdo concreto do clímax [D] pode mostrar algo, sem explicar.
- O Véu como conceito.
- Aethel e "AETHERIS é Aethel"; Asterion; o Homem Cinzento; o Último Experimento.
- A linhagem de Elyra.
- Kael, Lurídeos, Édor, Árvore-Biblioteca (fora do Ato 1).

## 16. Fluxo macro

```
GANCHO DE DURN ("Então não fui só eu.")                                   [A]
   ↓
VOLTA A DURN — os horários (caminho A: ele conta / caminho B: a folha)    [C]
   ├── (opcional) Forja: o quadro de manutenção ganha leitura nova        [C]
   └── (opcional) pátio/rua: a Forja 01 diferente das outras; turnos      [A/C]
   ↓
PADRÃO — os horários se repetem (+ evento opcional: o painel vibra)       [C]
   ↓
QUEM SELOU? — contexto local de Durn → Galpão de Manufatura               [C]
   ↓
GALPÃO — ordens de serviço do reforço                                     [C]
   ↓
ELYRA — as duas investigações chegam ao mesmo registro                    [C]
   ↓
INVESTIGAÇÃO CONJUNTA — experiência + conhecimento histórico              [C]
   ↓
IMPLICAÇÃO MAIOR — já aconteceu antes; houve silêncio                     [C]
   ↓
CONFLITO — natureza a decidir (K-1…K-4)                                   [D]
   ↓
(Fase 8–9: descoberta parcial e clímax — fora do escopo do C24)
```

## 17. As 14 perguntas (resultado do C24)

| # | Pergunta | Resposta | Classe |
|---|---|---|---|
| 1 | Por que o protagonista investiga? | Sentiu o Eco, e Durn também ouviu. Depois percebe que **só a Forja 01** mudou. A pergunta passa de "o que eu senti?" para "o que este lugar esconde?" | [A]+[C] |
| 2 | O que ele procura inicialmente? | **Quando** aquilo aconteceu: os horários de Durn (a folha ou o relato) | [B]/[C] |
| 3 | O que ele encontra? | Os horários de hoje; a marca apagada do quadro, que ganha leitura nova; os horários fixos dos turnos; o registro do **reforço do painel** no Galpão | [A]+[C] |
| 4 | Como percebe um padrão? | Comparando registros que já existem no jogo (folha, quadro de manutenção, quadro de turnos) e, se quiser, presenciando o painel vibrar de novo no horário | [C] |
| 5 | Qual o papel da cidade? | **Instrumento de comparação e arquivo:** a Forja 01 contra as outras fundições; turnos e fluxo como relógio; manufatura (Galpão) como origem do selo | [B]/[C] |
| 6 | Qual o papel de Durn? | Testemunha e contexto local na Forja; reage quando o jogador volta e deixa aos poucos de ser o motor (H2). Não explica. Clímax: não definido | [A] H2 + [D] |
| 7 | Qual o papel do painel? | Objeto central do mistério local; fechado durante a investigação, aberto ou rompido no clímax, com revelação material sem cosmologia (H1) | [A] H1 + [D] conteúdo |
| 8 | Qual o papel da escolha anterior? | Define **como** chega a pista dos horários (relato × folha) e o **tom** de Durn. A informação é a mesma | [C] |
| 9 | Por que Elyra está investigando? | Investiga **o que existia na área antes das fundições** (H4) | [A] H4 |
| 10 | Por que eles se encontram? | "O que aconteceu aqui agora?" e "o que existia aqui antes?" convergem sobre evidências ou registros relacionados (H4); o rastro operacional do Galpão é o candidato (H3) | [A] H3/H4 + [C] |
| 11 | O que cada um sabe que o outro não sabe? | Ele: a **experiência** (Eco, memória, Durn, horários). Ela: a **leitura histórica** (registros antigos, profundidade do padrão, casos parecidos sem causa) | [C] |
| 12 | Como a investigação leva ao conflito? | Mexer no que foi selado provoca reação; a natureza exata continua **NÃO DEFINIDA** (H6); K-4 é candidata | [D] |
| 13 | Que verdade parcial Vardhelm pode entregar? | "Isso já aconteceu antes. Alguém reconheceu o perigo, algo foi selado, e parte dos registros desapareceu." (H7). Quem, por quê e o quê: abertos | [A] conceito H7 + [D]/[E] |
| 14 | O que permanece desconhecido? | Ver §15 | [E] |

## 18. Integração futura na rua (C23 não é alterado)

C23 continua **tecnicamente aprovado e aguardando o fechamento humano/artístico**. As propostas abaixo ficam registradas para quando a investigação for implementada:

| Elemento da rua | Integração futura [C] |
|---|---|
| Quadro de turnos | leitura nova depois da pista dos horários (compara os horários de Durn com os dos turnos) |
| Portão do pátio (após o Eco) | já cumpre o papel ("a Forja 01 soa mais baixa"); nenhuma mudança necessária |
| Pedra de afiar | marca de dono riscada: possível ligação com a "ferramenta familiar" da Forja (opcional) |
| Caminho ao Galpão | a rua é o acesso natural; a saída (porta, cancela, direção) fica a definir no bloco de construção |

## 18.1 Implementado no C25 — os horários

O primeiro passo (§16: "volta a Durn — os horários" e o início do "padrão") está jogável. Detalhes em [`BLOCK_C25_THE_HOURS.md`](../architecture/BLOCK_C25_THE_HOURS.md).

| Item | Como ficou | Classe |
|---|---|---|
| Os horários | 5h58 · 13h58 · 17h41 (o último sublinhado; o momento do Primeiro Eco) | **[A] cânone** (decisão humana depois do C25) |
| Rotina da cidade | troca de turno às 6h, 14h e 22h (quadro de turnos da rua) | **[A] cânone** (idem) |
| Caminho "Sentir o quê?" | Durn conta ("Eu comecei a anotar." … "Não sei. Só sei que repetiu.") | [C] implementado |
| Caminho "Não senti nada." | Durn aponta a folha; a folha mostra os horários | [C] implementado |
| Padrão percebido | dois horários minutos antes da troca de turno; o sublinhado fora da rotina | [C] implementado; **não explica nada** |
| Próximo objetivo | "Descubra o que acontece na Forja 01 nesses horários." (sem apontar o Galpão) | [C] implementado |
| Memória | nenhuma nova (os horários são conhecimento, não impressão) | [C] |
| Painel, Elyra, Véu | intocados (H1, H4, H5) | [A] |

## 18.2 Implementado no C26 — releituras e padrão

Detalhes em [`BLOCK_C26_REREADS_PATTERN.md`](../architecture/BLOCK_C26_REREADS_PATTERN.md). Cobre o "padrão" e o início de "quem selou?" do §16.

| Item | Como ficou | Classe |
|---|---|---|
| Gatilho | a comparação no quadro de turnos (C25) | [C] implementado |
| Quadro de manutenção relido | linha raspada; resta "...58" (continua a "marca quase apagada" do C13) | [C] implementado; **evidência, não fato** |
| Painel relido | parafusos do reforço mais novos que a placa; continua fechado (H1) | [C] implementado |
| 17h41 | sem correspondência; nenhum texto o explica | [A] (decisão humana) |
| Objetivo seguinte | "Descubra quem reforçou o painel e onde ficam os registros da Forja." | [C] implementado; prepara o Galpão (H3) sem nomeá-lo |
| Durn | "...Raspado? Não fui eu." (caminho da confiança); silêncio no outro | [C] implementado (H2) |
| Memória | nenhuma nova | [C] |

## 19. Local deste documento

O pedido indicava `docs/narrative/`, pasta que **não existe**. O repositório já tem [`docs/03_narrativa/`](.) para documentos de narrativa, ao lado de `docs/lore/` (cânone) e `docs/scenarios/` (cenários). Criar `docs/narrative/` duplicaria uma pasta com a mesma função. Por isso o documento fica em `docs/03_narrativa/`.
