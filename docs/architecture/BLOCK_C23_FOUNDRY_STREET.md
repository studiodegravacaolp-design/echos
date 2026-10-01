# Bloco C23 — Rua do Distrito das Fundições: Vardhelm como cidade

**Status:**
- implementado; validação automatizada completa;
- **teste humano pendente** (o fechamento artístico depende dele);
- sem commit e sem push.

**Documento do cenário:** [`docs/scenarios/vardhelm_foundry_street.md`](../scenarios/vardhelm_foundry_street.md).
**Lido antes de implementar:** `VARDHELM_ACT1_CANON.md`, `LORE_REVELATION_MATRIX.md`, `BLOCK_C22_VARDHELM_WORLD_MAP.md`, `vardhelm_world_map.md`, `SCENARIO_PRODUCTION_STANDARD.md`.

## 1. Função e conceito

- **Fase 4 do Ato 1 (abertura do mundo).** A rua é a transição entre o microcosmo da Forja e **Vardhelm como cidade**: o jogador sai pelo portão sul do pátio e encontra uma rua de serviço industrial que já funcionava antes dele.
- **Normalidade primeiro.** A rua funciona sem o mistério. Ela prepara a investigação, mas **não a resolve**: não há segundo Eco, Elyra, combate nem revelação.

**Definido antes de construir** (CONCEITO → ARQUITETURA → FUNÇÃO → VIDA → ATMOSFERA → NARRATIVA AMBIENTAL → ACABAMENTO):
- **por que existe:** entrada e saída de material das fundições e circulação de trabalhadores;
- **o que circula:**
  - carvão pelo ramal do pátio;
  - minério pela linha da rua;
  - caixas pela doca e pela talha;
  - um trem de carga no corredor sul;
- **edifícios visíveis:** fundição oeste (porta, turnos), complexo da Forja 01 (muro e portão), armazém leste (doca, talha);
- **como os trilhos continuam:** o ramal do pátio passa pelo portão e encontra a linha da rua;
- **onde se anda:** a faixa de 56 × 15 m;
- **onde não se anda:** fachadas, doca, muros baixos, cancela, vagões;
- **o que é só fundo:** a rua além da cancela, o corredor sul e as massas ao norte.

## 2. Arquitetura e continuidade

- **Ligação:** **Forja 01 → talha → pátio → portão sul → rua**. A passagem é **andando, pelo portão existente**: não há transição, teleporte nem saída nova.
- **Portão sul aberto:**
  - a grade fechada do C21 virou duas folhas abertas para **dentro** do pátio, perpendiculares ao muro, que emolduram a passagem;
  - vão livre de **5,85 m** entre os postes;
  - as folhas abriam primeiro **para fora**, mas o playtest mostrou que avançavam 2,85 m sobre a calçada e travavam quem andava junto ao muro. Foi corrigido.
- **Rua:**
  - `level_data/vardhelm_foundry_street_01.json` → `vp_03_vardhelm_foundry_street.tscn`, em (0, −11,9, 39,5): o mesmo chão do pátio;
  - lado norte alto (fachadas de 10 m e 8 m); lados sul, oeste e leste em corte (muros de 1,1 m), como a baia do C17 e o pátio do C21;
  - profundidade: a rua continua a oeste além da cancela (esquinas, janelas acesas, poste) e o corredor ferroviário ao sul.
  - Detalhes no documento do cenário.

## 3. Implementação e sistemas reutilizados

| Sistema | Uso |
|---|---|
| LevelBuilder / LevelValidator | rua: 111 props, 2 regras de geração (dormentes), 17 corpos com colisão; **nenhuma mudança no builder** |
| `VardhelmAmbientLife` | a mesma classe, uma segunda instância (`StreetLife`) com `foundry_street_life.json`: 12 trabalhadores, 4 observações |
| `VardhelmFoundryDistrict` | integra a rua ao distrito: segunda vida, nível extra no desenho derivado, área ampliada, lampiões, placa, fumaça e **animações de cenário** |
| `EnvironmentalObservation`, `ContextualWindowLifecycle` | 4 observações, dica pelo ciclo do C18 |
| GameState / EventBus / Save V2 | sem mudança de arquitetura; 4 IDs de observação |

### 3.1 Generalização do AmbientLife (só o que a rua precisou)

| | |
|---|---|
| **Antes (problema concreto)** | Na rua, pedestres e o carrinho fazem rotas longas e **andavam de lado**: o trabalhador nunca virava para onde ia (pendência B do C21). Grupos parados olhavam todos para o mesmo lado. O carrinho de mão precisava de carga **baixa e à frente**, não na altura do peito |
| **Depois (abstração)** | três chaves **opcionais** por trabalhador: `face_movement` (vira para o próximo ponto antes de cada perna), `facing_degrees` (direção de quem está parado) e `carry_offset` (posição da carga) |
| **Custo** | `vardhelm_ambient_life.gd` (+17 linhas) e os dados da rua. A Forja e o pátio **não** usam as chaves e ficam idênticos (testado: rotação 0, sem as opções) |
| **Regressão** | runner (C11–C23), C11, C15, C16, C17.3, C18, C21, C21.1 |
| **Não generalizado (registrado)** | a primeira perna de toda rota vai até o próprio ponto inicial, o que deixa o trabalhador parado uma perna inteira. Na rua isso foi resolvido **por dados** (quem anda nasce no último ponto da rota), sem mexer no código compartilhado |

### 3.2 Animações de cenário (componente do distrito, dados)

`foundry_district.json` → `animations`: a carga da talha do armazém sobe e desce, o pedal da pedra de afiar trabalha e o trem de carga anda devagar no corredor.
- São tweens em laço, sem `_process`, sem colisão e nunca salvos.
- Tentei girar a pedra de afiar, mas um cilindro liso girando no próprio eixo não se vê. Ficou o pedal.

## 4. Alterações compartilhadas

| Arquivo | Mudança |
|---|---|
| `godot/level_data/vardhelm_foundry_district_01.json` + `vp_02_…tscn` (re-assada, `unique_id` preservados) | portão sul aberto (folhas para dentro); trilho do pátio termina no portão; 19 dormentes; fundo sul (galpões e "rua" falsa) removido; a massa da fundição oeste para no alinhamento da rua |
| `scripts/vardhelm/vardhelm_ambient_life.gd` | 3 opções opcionais (§3.1) |
| `scripts/vardhelm/vardhelm_foundry_district.gd` | `extra_levels`, `extra_lives`, `lives`, `observation_roots()`, `life_named()`, `animations` |
| `scripts/vardhelm/vardhelm_vertical_slice.gd` | `observation_roots()` passa a incluir todas as raízes do distrito |
| `scenes/prototypes/vardhelm_vertical_slice.tscn` | instância `VP03_FoundryStreet` |
| `scripts/state/id_catalog.gd` | 4 IDs + aliases |
| `data/vardhelm/foundry_district.json` | rua (nível e vida extras), área de névoa e luz ampliada (z 6–48), +3 lampiões, placa "FORJA 01" do lado da rua, +2 fumaças, 3 animações |
| `data/localization/pt-BR.json` | 9 chaves (4 títulos, 4 textos, 1 pós-Eco) |
| `tests/save_v2/test_c21_foundry_district.gd` | 3 checks de **contagem total** (raízes, lampiões, emissores) passaram a verificar os itens do pátio e a contagem da config: a rua soma itens no mesmo controlador. O que o C21 protege continua coberto |

**Não mudou:**
- Forja 01 (nível, cena, set dressing, vida), Durn, Eco, painel, folha (C16), talha e passagem do C21.1;
- quests, diálogos, Save V2, GameState, EventBus e LevelBuilder.

## 5. IDs, estados e eventos

- **IDs:** `observation.vardhelm.foundry_street_gate`, `…_shift_board`, `…_ore_wagons`, `…_sharpening`. Nenhum cenário, NPC, quest, consequência ou evento novo.
- **Persistente:** observações vistas, posição e rotação.
- **Derivado:** área, névoa, luz, desenho, texto pós-Eco do portão, rotinas.
- **Transitório:** animações, partículas, dica, painel.
- **No save, verificado:** não aparecem trabalhadores, trem, talha, névoa ou área.
- **EventBus:** só `observation_discovered` (ID canônico, sem memória e sem duplicar). No Load, só `game_loaded`.

## 6. Testes

**Runner `test_c23_foundry_street.gd` (38 checks):**
- dados: validador, 12 trabalhadores e 4 observações, IDs, textos curtos e sem lore proibido, pátio intacto;
- cena: rua no lugar, portão aberto (8 corpos por folha), colisão = geometria, fundo sem colisão, câmera, um só ambiente e uma só luz, 2 vidas, 3 raízes de observação, 6 lampiões, 5 emissores, 3 animações;
- vida: 12 corpos, `facing_degrees`, `carry_offset`, `face_movement` (leste −90°, sul 180°), Forja e pátio inalterados;
- integração: 4 observações (texto, flag, evento canônico, sem duplicar), GameState, texto pós-Eco do portão, resto da rua igual;
- Save/Load na rua: posição e rotação, observações restauradas, só `game_loaded`, nada duplicado, nada transitório no save.

**Playtest `c23_foundry_street_playtest.gd` (16 checks)**, frames, física e input reais, sem teleporte:

| # | Cobertura |
|---|---|
| 1 | Forja → talha → pátio → portão → rua, sem travar |
| 2–3 | larguras reais: portão **5,85 m**; entre as folhas **6,15 m**; rua **9,15 / 14,55 / 14,8 / 14,55 / 10,35 m** |
| 4 | vida: 7 de 12 andando, o carrinho virado para onde vai |
| 5 | as 4 observações examinadas andando |
| 6 | portão nos dois sentidos, 2 vezes |
| 7 | Save na rua; nada transitório no arquivo |
| 8 | Load na rua: posição, rotação, fora de colisão, só `game_loaded` |
| 9 | observações mantidas depois do Load |
| 10 | depois do Load: rua → pátio → rua |
| 11 | depois do Primeiro Eco: Forja → talha → pátio → portão → rua |
| 12 | texto pós-Eco do portão |
| 13 | eventos sem duplicação |
| 14 | 0 travamentos nas caminhadas sem desvio |

O andador de teste agora **alterna o lado do desvio** (contorna quem cruza a frente), como uma pessoa faria.

## 7. Resultados

Bateria completa guardada, com os saves reais intactos:

| Suite | Renderizado | Headless |
|---|---|---|
| Runner | — | **1732/1732** (C23 38/38) |
| **C23** | **16/16** | **16/16** |
| C21.1 | 24/24 | 24/24 |
| C21 | 25/25 | 25/25 |
| C11 | 52/52 | 52/52 |
| C15 | 17/17 | 17/17 |
| C16 | 16/16 | 16/16 |
| C17.3 | 11/11 | 11/11 |
| C18 | 17/17 | 17/17 |
| C9 | 66/66 | — |
| Cena principal / legados / `tsc` | 0 erros / iguais à linha de base / limpo | |

**Desempenho:**
- **Condições:** na tomada (BatteryStatus 2), Intel UHD, Forward+, 1152×648, vsync.

| Medição | Resultado |
|---|---|
| Rua (centro / oeste / leste) | **16,61 / 16,73 / 17,00 ms** |
| Pátio | 16,65 ms |
| Forja (sonda do pátio) | 17,01–17,94 ms |
| **Forja (sonda do C19, 1500 quadros)** | **17,52 e 17,37 ms** (C21.1: 17,26 ms; dentro do ruído) |

**Contagens:**
- rua: 217 malhas, 17 corpos com colisão;
- distrito: 6 lampiões (3 na rua), 5 emissores de partículas (2 na rua; 10–12 partículas cada), 3 animações, 12 trabalhadores novos.

**Cuidados de custo:**
- a rua entra no **desenho derivado** do C21: não é desenhada da Forja (só do pátio, da rua ou do patamar);
- o fundo não tem colisão;
- nenhuma luz com sombra;
- nada de simulação distante.

**Capturas** (evidência técnica, não aprovação artística): [`c23_street/`](c23_street/), com portão dos dois lados, centro, oeste, vagões, fim oeste, afiação, doca, retorno ao pátio, corredor sul e o portão depois do Eco.

## 8. Limitações e pendências

| # | Item | Classe |
|---|---|---|
| 1 | A profundidade a oeste é sutil: a câmera ortográfica de 10 m só mostra uns 8 m ao redor do jogador, e o resto cai na névoa. A "cidade maior" vem mais das fachadas e do fluxo do que de silhuetas distantes | **C**, depende do teste humano |
| 2 | Pedestres em faixas diferentes ainda podem se cruzar por instantes (sem colisão entre trabalhadores, por desenho do C17.3) | B |
| 3 | A primeira perna das rotas no AmbientLife (§3.1) foi resolvida por dados na rua; Forja e pátio continuam como antes | B, refinamento |
| 4 | O papel da rua na investigação (Fase 5) não está definido. A rua só prepara o palco; os próximos blocos decidem | lacuna (C24/C25) |
| 5 | A janela de observação de 660 × 300 continua grande; os textos novos foram mantidos curtos para não agravar | refinamento UX (registrado no C22) |

**Oportunidade documentada para C24/C25:** a rua é o primeiro lugar onde a pergunta "aquilo afetou só a Forja?" pode ser feita pelo jogador, pelo texto pós-Eco do portão. Qualquer sinal novo **fora** da Forja precisa de decisão humana antes.

## 9. Classificação

| Área | Classe |
|---|---|
| Conexão pátio ↔ rua, circulação, Save V2, integração, regressão, performance | **A — pronto** |
| Vida (cruzamentos) e AmbientLife (primeira perna) | **B — ajuste recomendado** (pequeno, depois do teste humano) |
| Sensação de cidade maior, ocupação, poluição visual, leitura do portão | **C — depende do teste humano** |

## 10. Checklist do teste humano

- **A.** O portão parece realmente levar para uma cidade?
- **B.** A passagem pátio → rua parece natural (andando pelo portão aberto)?
- **C.** A rua parece ocupada?
- **D.** Há sensação de atividade industrial (carrinho, carregadores, talha, trem, vapor)?
- **E.** A cidade parece maior que a área jogável (fachadas, rua continuando a oeste)?
- **F.** O caminho é confortável (portão, calçada junto ao muro, entre os trabalhadores)?
- **G.** Dá para voltar naturalmente ao pátio?
- **H.** Save/Load funciona na rua (e o jogador volta ao lugar certo)?
- **I.** Alguma parte parece vazia demais?
- **J.** Alguma parte parece poluída ou confusa demais?

**Também conferir:** examinar o portão antes e depois do Primeiro Eco, e que a Forja, o pátio e a talha continuam iguais.
