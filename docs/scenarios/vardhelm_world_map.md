# Vardhelm — mapa de produção e fluxo (documento vivo)

> **Origem:** Bloco C22 ([`BLOCK_C22_VARDHELM_WORLD_MAP.md`](../architecture/BLOCK_C22_VARDHELM_WORLD_MAP.md)). Atualizar a cada bloco que mexer na região.
>
> **Classes:** **A** canônica/confirmada · **B** histórica · **C** proposta de produção · **D** contradição · **E** não definido no material canônico disponível.
> **Estados:** IMPLEMENTADO · PARCIAL · DOCUMENTADO · PROPOSTO · NÃO DEFINIDO.
> Só aparece aqui o que tem evidência. **Nada foi preenchido por suposição.**

## 1. Mapa conceitual

```
AETHERIS (universo)
└── Ato 1 — VARDHELM (cidade industrial; níveis 1–10)                [A · PARCIAL]
    │
    ├── Distrito das Fundições                                        [A · PARCIAL]
    │   ├── Forja 01 (baia elevada)                                   [A* · IMPLEMENTADO]
    │   │     └── patamar ↕ talha
    │   ├── Pátio da Forja 01 (sob a baia)                            [C · IMPLEMENTADO]
    │   │     ├── fundição vizinha (portões fechados, a oeste)        [C · PARCIAL: só fachada]
    │   │     └── portão sul + trilho (ABERTO no C23)                  [C · IMPLEMENTADO]
    │   └── Rua do Distrito das Fundições (C23)                        [A (arte) + DH · IMPLEMENTADO; teste humano pendente]
    │         ├── fundição oeste (porta, quadro de turnos)             [PROD · PARCIAL: fachada]
    │         ├── armazém leste (doca, talha de braço)                 [PROD · PARCIAL: fachada]
    │         ├── linha da rua + corredor ferroviário sul              [PROD · IMPLEMENTADO]
    │         └── rua continuando a oeste, além da cancela             [PROD · só fundo]
    │
    ├── Galpão de Manufatura (interior)                                [A (arte) · DOCUMENTADO; posição E]
    │
    ├── outros distritos / áreas                                       [E · NÃO DEFINIDO]
    │
    └── saída → Ato 2 (Ostrell)                                        [A: EVT no nível 10 · forma E]
          └── "rotas comerciais Vardhelm → Ostrell, longas e perigosas" [A (texto econômico) · espaço E]
```

\* A = cânone de produção do slice, validado por humano; não há documento de design anterior.

## 2. Locais

| Local | Fonte | Função | Relação com o Ato 1 | Relação espacial conhecida | Estado |
|---|---|---|---|---|---|
| Vardhelm | SYS-BALANCEAMENTO §2; ENG-PROGRESSAO; TIER1 §1.1 (A) | cidade industrial (fundições, chaminés, carvão) | é o Ato 1 | — | PARCIAL |
| Distrito das Fundições | TIER1 §1.4.1; TIER3 §2.3.3 (A) | produção e transporte de fundição | região do slice | contém a Forja 01 e o pátio (C) | PARCIAL |
| Forja 01 | slice C12–C19 (A*) | baia de forja; começo do arco (Durn, Primeiro Eco, painel) | começo do Ato 1 no jogo | elevada sobre o pátio; patamar com talha | IMPLEMENTADO (fechado) |
| Pátio da Forja 01 | C21 (C) | chegada de carvão, descarga, talha, doca | exploração opcional | sob a Forja 01; portão sul e fundição oeste fechados | IMPLEMENTADO (fechado) |
| Rua do Distrito das Fundições | TIER1 §1.4.1 (A, arte); C22.1 (DH) | rua de serviço: carvão, minério, doca, turnos, afiação | **Fase 4: abertura do mundo** | pelo portão sul do pátio (andando) | **IMPLEMENTADO (C23)**; teste humano pendente |
| Galpão de Manufatura | TIER1 §1.4.2 (A, arte) | manufatura (volantes, correias, ponte rolante) | E | E (proposta: portões da fundição oeste, C) | DOCUMENTADO |
| Estruturas de Artífice Anão | TIER1 §3 (A, arte) | arquitetura de engenharia pesada anã | E (TIER1 cobre os Atos 1 e 2) | E | DOCUMENTADO (sem local) |
| Saída de Vardhelm | ENG-PROGRESSAO §3.1 (A: `EVT_TRANSICAO_ATO1_ATO2`) | transição para o Ato 2 | fim do Ato 1 | E | NÃO DEFINIDO (forma) |
| Rotas Vardhelm → Ostrell | SYS-BALANCEAMENTO §3.5 (A, texto) | comércio | ligação entre os Atos 1 e 2 | E | NÃO DEFINIDO (espaço) |

## 3. Fluxo do mundo

- 🟢 implementado
- 🟡 documentado, não implementado
- ⚪ não definido

```
🟢 Forja 01 — chegada
   ↓
🟢 Durn: "...Você também sentiu isso?" → escolha (Sentir o quê? / Não senti nada.)
   ↓
🟢 Primeiro Eco → memória, quest concluída
   ↓
🟢 Vardhelm reage (luz fria, trabalhador, máquinas mais baixas; no pátio, menos fumaça)
   ↓
🟢 consequência da escolha (Durn vai sozinho; folha no lugar dele)
   ↓
🟢 Durn: "...Você voltou." → painel selado
   ↓
🟢 painel → silêncio → gancho: "Então não fui só eu."
   ↓
🟢 Fase 4 — abertura do mundo: rua do Distrito das Fundições (C23; teste humano pendente)
   ↓
🟡 Fase 5 — investigação em Vardhelm (design C24; H1–H5, H7 conceito e H8 decididos no C24.1)
   │   🟢 C25 — os horários (5h58 · 13h58 · 17h41; trocas 6h/14h/22h — cânone): Durn conta (A) / a folha (B) → quadro de turnos da rua (comparação)
   │      → "Descubra o que acontece na Forja 01 nesses horários." (teste humano pendente)
   │   🟢 C26 — releituras: quadro de manutenção (linha raspada, "...58") + painel (reforço mais novo)
   │      → "Descubra quem reforçou o painel e onde ficam os registros da Forja." (teste humano pendente)
   │   ⏳ C27 — Galpão de Manufatura (histórico operacional do selo)
   ↓
🟡 Fase 6 — Elyra (arqueóloga élfica) cruza o caminho do protagonista: ela investiga o que existia antes das fundições; as investigações convergem sobre registros relacionados (H4) [C22.1]
   ↓
🟡 Fase 7 — conflito; combate com função narrativa (natureza NÃO DEFINIDA, H6; K-4 candidata) [C22.1]
   ↓
🟡 Fase 8 — descoberta parcial (conceito H7) → 🟡 Fase 9 — clímax de Vardhelm (o painel se abre ou rompe, H1; conteúdo ⚪)
   ↓
🟡 Fase 10 — consequência e saída (níveis 1–10 como referência, NÃO condição rígida; forma ⚪) [C22.1]
   ↓
🟡 Ato 2 — Ostrell (não iniciar)

🟢 Pátio do Distrito das Fundições: acessível pela talha a qualquer momento (lateral ao arco)
   ├── 🟢 rua do distrito (portão sul, C23; o quadro de turnos ganhou a leitura dos horários no C25)
   └── 🟡 Galpão de Manufatura (posição ⚪; função H3: histórico operacional do reforço/selamento do painel)
```

## 4. Decisões

**C24:** design da investigação em [`VARDHELM_INVESTIGATION_DESIGN.md`](../03_narrativa/VARDHELM_INVESTIGATION_DESIGN.md). Decisões H1–H9 (C24.1: H6 aberto, H9 reservado) e blocos C25–C30 propostos em [`BLOCK_C24_VARDHELM_INVESTIGATION.md`](../architecture/BLOCK_C24_VARDHELM_INVESTIGATION.md).

**C22.1:** D1–D7 foram decididos (total ou parcialmente) e consolidados em [`VARDHELM_ACT1_CANON.md`](../lore/VARDHELM_ACT1_CANON.md). O que continua aberto está no §14 desse documento.

Lista original do C22:

D1–D7 em [`BLOCK_C22_VARDHELM_WORLD_MAP.md`](../architecture/BLOCK_C22_VARDHELM_WORLD_MAP.md) §11:
- **D1:** o que vem depois do gancho;
- **D2:** Elyra no Ato 1;
- **D3:** combate e progressão no Ato 1;
- **D4:** a saída;
- **D5:** os distritos;
- **D6:** Brenhold;
- **D7:** o ritmo de revelação.
