# MODELO DE CENÁRIO — copiar para `docs/scenarios/<scenario_id>.md`

> Regras do [Padrão de Produção de Cenários](SCENARIO_PRODUCTION_STANDARD.md):
> - Tudo que vem do cânone **cita a fonte** (documento e seção).
> - Onde o cânone não diz, escrever **"não definido no material canônico"** e abrir pergunta. **Não inventar lore.**
> - Este documento é de produção: não redefine cosmologia, raças nem personagens canônicos.
> - Preencher **antes** da primeira implementação. O checklist de entrada (fim do arquivo) decide se o cenário pode começar.

---

# IDENTIDADE

- **Nome:**
- **ID do cenário** (catálogo Godot, `scenario.<nome>`):
- **ID documental** (`LOC-…`, [`MASTER_ID_REGISTRY.md`](../../DOCUMENTACAO/MASTER_ID_REGISTRY.md)):
- **Localização** (região / Ato, com fonte):
- **Função narrativa** (o que este lugar faz na história):
- **Função no mundo** (o que este lugar faz para quem vive nele):
- **Fontes canônicas:**

# CONCEITO

- **O que é este lugar?**
- **Por que ele existe?**
- **O que acontece nele diariamente?**
- **Quem utiliza o espaço?**

# ARQUITETURA

- **Estrutura** (raça/cultura construtora → [`BLUEPRINT_VISUAL_MESTRE.md`](../../doc/art_bible/BLUEPRINT_VISUAL_MESTRE.md) cap. 4 §3):
- **Materiais** (dentre os canônicos, cap. 4 §2):
- **Escala** (altura de pé-direito, largura de circulação, em metros):
- **Entradas:**
- **Saídas:**
- **Áreas** (nome → função):
- **Elementos verticais** (passarelas, pontes rolantes, mezaninos…):
- **Profundidade** (primeiro plano / meio / fundo; o que se vê além do limite jogável):
- **Planta funcional** (esboço em texto ou imagem: áreas, postos, rotas, bloqueios naturais):

# VIDA

- **Quem está presente?**
- **O que essas pessoas fazem?** (posto → atividade)
- **Quais rotinas existem?** (rota, ritmo, pausas)
- **Quais elementos demonstram atividade?** (máquinas, cargas, fumaça, desgaste)

# ATMOSFERA

- **Luz** (fontes, motivo, temperatura):
- **Som** (camadas e loops):
- **Clima:**
- **Partículas:**
- **Temperatura visual** (quente / frio, onde fica o foco):
- **Paleta** (70/20/10, hex):

# NARRATIVA AMBIENTAL

- **O que o jogador percebe sem diálogo?**
- **Quais histórias o ambiente conta?**
- **Quais elementos sugerem acontecimentos passados?**

# INTERAÇÃO

- **O que pode ser observado?** (observações ambientais)
- **O que pode ser examinado?**
- **Quais elementos têm interação?** (NPC, Eco, objetos) + prioridade quando dois se sobrepõem
- **Janelas contextuais** (dica "E • …" com `ContextualWindowLifecycle`; atraso e fades em dados):

# CIRCULAÇÃO

- **Por onde o jogador entra?** (spawn)
- **Para onde pode ir?**
- **Áreas abertas:**
- **Áreas naturalmente bloqueadas** (e por quê: parede, máquina, parapeito; nunca parede invisível):
- **Rotas dos NPCs** (sem cruzar interações nem entradas; colisores ≥ 1,5 m delas):

# NARRATIVA

- **Quais acontecimentos podem ocorrer aqui?**
- **Quais NPCs participam?** (ID `npc.<cenário>.<nome>`)
- **Quais escolhas existem, e qual consequência perceptível cada uma deixa no espaço?**
- **Quais consequências podem alterar o espaço?** (antes / depois)
- **Ordem esperada de eventos** (tipos do [`event_catalog.gd`](../../godot/scripts/events/event_catalog.gd)):

# ESTADO

| Elemento | PERSISTENTE / DERIVADO / TRANSITÓRIO | Fonte de verdade | Como o Load o restaura |
|---|---|---|---|
| | | | |

> Estado de apresentação transitória **não** entra no GameState nem no Save V2. Estado derivado não é salvo: salva-se a causa.

# IDs E DADOS

| Tipo | ID | Arquivo de dados |
|---|---|---|
| cenário | `scenario.<nome>` | — |
| nível | — | `godot/level_data/<nome>_<área>.json` |
| vida | — | `godot/data/<nome>/ambient_life.json` |
| diálogo | `dialogue.<nome>.<id>` | `godot/data/dialogue/<nome>_<id>.json` |
| quest | `quest.<nome>.<id>` | `godot/data/quests/<nome>_<id>.json` |
| observação | `observation.<nome>.<id>` | `ambient_life.json` + `localization/pt-BR.json` |
| consequência | `consequence.<nome>.<id>` | diálogo/quest |
| estado de ambiente | `envstate.<nome>.<id>` | `ambient_life.json` |
| textos | chaves de localização | `godot/data/localization/pt-BR.json` |

# PRIMEIRO BLOCO

- **Escopo** (FORMA + FUNÇÃO + VIDA + IDENTIDADE; nunca uma caixa vazia):
- **O que já estará jogável:**
- **Sistemas reutilizados:**
- **Generalizações pré-requisito** (ex.: AmbientLife para outro cenário), com regressão de Vardhelm:
- **Testes do bloco** (runner + playtest com input real):
- **Como será avaliado** (câmera do jogador + teste humano):

---

## Checklist de entrada

- [ ] conceito definido
- [ ] função definida
- [ ] arquitetura definida
- [ ] circulação definida
- [ ] ocupação definida
- [ ] rotina definida
- [ ] atmosfera definida
- [ ] narrativa ambiental definida
- [ ] pontos de interesse definidos
- [ ] interações definidas
- [ ] estados persistentes definidos
- [ ] estados derivados definidos
- [ ] estados transitórios definidos
- [ ] IDs definidos
- [ ] dados definidos
- [ ] primeiro bloco de implementação preparado
