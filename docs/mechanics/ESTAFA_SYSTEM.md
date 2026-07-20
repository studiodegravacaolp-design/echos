# ⚖️ SISTEMA DA BALANÇA DE ESTAFA — ESPECIFICAÇÃO DE MECÂNICA

> **Fonte canônica:** `AETHERIS_MASTER_INDEX.md` (§2 e §3).
> **Implementação de referência:** [`src/mechanics/EstafaCalculator.ts`](../../src/mechanics/EstafaCalculator.ts).
> **Cobertura de testes:** [`src/mechanics/__tests__/EstafaCalculator.test.ts`](../../src/mechanics/__tests__/EstafaCalculator.test.ts).

Este documento formaliza a mecânica core do Aetheris: a **Balança de Estafa**, um eixo
psicológico dinâmico que molda simultaneamente o combate (modificadores de atributos)
e a narrativa/UI diegética (Insubordinação Tática).

---

## 1. O EIXO

A Balança de Estafa é um valor numérico contínuo que oscila entre dois polos:

| Polo | Intervalo | Foco temático |
| --- | --- | --- |
| **Materno** | `-1` a `-100` | Preservação, empatia, regeneração de EP |
| **Neutro** | `0` | Equilíbrio — sem modificadores |
| **Paterno** | `+1` a `+100` | Rigidez, impacto, defesa física |

- **Clamp obrigatório:** o valor é sempre restringido ao intervalo fechado `[-100, +100]`.
- Valores `NaN` são tratados como `0` (neutro) por segurança.
- Constantes canônicas: `ESTAFA_MIN = -100`, `ESTAFA_MAX = +100`.

---

## 2. MODIFICADORES DE COMBATE (SYSTEM MATRIX)

Apenas o **lado ativo** recebe modificadores. Na posição neutra (`0`) todos os
modificadores são zerados.

### 2.1 Lado Materno (valor < 0)

Baseado na **magnitude absoluta** `|estafa|`.

| Modificador | Fórmula | Valor em `-100` |
| --- | --- | --- |
| Bônus de Regeneração de EP/turno | `+(|estafa| * 0.5)%` | **+50%** |
| Penalidade de Eficiência de Armadura Física | `-((|estafa| / 100) * 20)%` | **-20%** |

### 2.2 Lado Paterno (valor > 0)

| Modificador | Fórmula | Valor em `+100` |
| --- | --- | --- |
| Bônus de Resistência/Defesa Física | `+(estafa * 0.4)%` | **+40%** |
| Aumento de Custo de EP (habilidades mágicas/complexas) | `+((estafa / 100) * 30)%` | **+30%** |

### 2.3 Tabela de referência rápida

| Estafa | EP Regen | Armadura | Def. Física | Custo EP Mágico |
| ---: | ---: | ---: | ---: | ---: |
| `-100` | +50% | -20% | 0% | 0% |
| `-60` | +30% | -12% | 0% | 0% |
| `-20` | +10% | -4% | 0% | 0% |
| `0` | 0% | 0% | 0% | 0% |
| `+20` | 0% | 0% | +8% | +6% |
| `+60` | 0% | 0% | +24% | +18% |
| `+100` | 0% | 0% | +40% | +30% |

---

## 3. QUADRANTES PSICOLÓGICOS

O quadrante define o "humor tático" da unidade líder e quais ações a UI libera ou trava.

| Quadrante | Condição | Nome diegético |
| --- | --- | --- |
| `MATERNO_EXTREMO` | `estafa <= -60` | Empatia Ativa |
| `NEUTRAL` | `-59` a `+59` | — |
| `PATERNO_EXTREMO` | `estafa >= +60` | Cálculo Tático |

> **Nota sobre transição:** a faixa intermediária (`±21` a `±59`) mantém o
> comportamento neutro em termos de **bloqueio de UI**, embora os modificadores
> de combate já estejam ativos (ver §2). A zona de repouso "sem tensão" fica em
> `-20` a `+20`.

---

## 4. INSUBORDINAÇÃO TÁTICA (VALIDAÇÃO DE AÇÕES)

Quando o líder está em um quadrante extremo, a UI **bloqueia** ações incompatíveis
com sua psique. Se o jogador **forçar** o comando, a unidade executa uma **ação
autônoma modificada** (`autonomousAlternative`).

### 4.1 Empatia Ativa — Extremo Materno (`<= -60`)

Bloqueia frieza e sacrifício:

| Ação bloqueada | Motivo | Ação autônoma |
| --- | --- | --- |
| `SACRIFICE` | A unidade se recusa a sacrificar aliados. | Prioriza preservação/proteção do alvo. |
| `COLD_EXECUTION` | A execução a sangue-frio é bloqueada. | Neutraliza o alvo de forma não-letal. |

### 4.2 Cálculo Tático — Extremo Paterno (`>= +60`)

Bloqueia compaixão e partilha:

| Ação bloqueada | Motivo | Ação autônoma |
| --- | --- | --- |
| `COMPASSIONATE_HEAL` | A cura compassiva é bloqueada. | Redireciona recursos para um golpe ofensivo. |
| `SHARE_ITEM` | A partilha de itens é bloqueada. | Retém o item como recurso estratégico. |

### 4.3 Ações sempre permitidas

- `STANDARD` nunca é travada pela psique.
- Ações compassivas no lado Materno e ações frias no lado Paterno são **compatíveis**
  e, portanto, permitidas.

---

## 5. RAÇAS FUNDADORAS E REAÇÕES TÁTICAS

Cada raça possui uma expressão distinta para os polos Materno e Paterno da Estafa
(ver `AETHERIS_MASTER_INDEX.md` §3):

| Raça | Materno | Paterno |
| --- | --- | --- |
| **Humanos** (Engenheiros de Sucata) | Solda de Sobrevivência (reparo de chassi aliado) | Sobrecarga de Pistão (dano massivo com coice) |
| **Anões** (Metalurgia Pesada) | Vapor de Arrefecimento (evasão/nuvem de vapor) | Prensa Hidráulica (postura defensiva +60%) |
| **Elfos** (Engenheiros de Reator) | Ressonância de Núcleo (regeneração de EP coletivo) | Corte de Centelha (elétrico, ignora 50% de armadura) |
| **Fadas** (Mecânicas de Duto) | Névoa Química (cura de veneno/estresse em área) | Injeção Pneumática (jato de ar que repele) |
| **Draconianos** (Alta Temperatura) | Dissipador Térmico (absorção/conversão de dano) | Sobrecarga Vulcânica (explosão de fogo 360°) |
| **Lurídeos** (Adaptação Subaquática) | Cápsula de Pressão (bolha de proteção hidráulica) | Siphon Químico (dreno de vida + terreno tóxico) |

---

## 6. CONTRATO DA API (`EstafaCalculator`)

Todos os métodos são **estáticos e puros** (sem estado, sem efeitos colaterais).

| Método | Assinatura | Descrição |
| --- | --- | --- |
| `clamp` | `(value: number) => number` | Restringe ao intervalo `[-100, +100]`; `NaN → 0`. |
| `calculateModifiers` | `(value: number) => EstafaModifiers` | Calcula os modificadores de combate dinâmicos. |
| `getQuadrant` | `(value: number) => EstafaQuadrant` | Retorna `NEUTRAL`, `MATERNO_EXTREMO` ou `PATERNO_EXTREMO`. |
| `validateAction` | `(value: number, actionType: EstafaActionType) => ActionValidationResult` | Valida a compatibilidade psicológica da ação. |

### Tipos

```ts
enum EstafaQuadrant { NEUTRAL, MATERNO_EXTREMO, PATERNO_EXTREMO }

interface EstafaModifiers {
  epRegenBonus: number;    // %
  armorPenalty: number;    // %
  physicalDefBonus: number; // %
  epCostIncrease: number;  // %
}

interface ActionValidationResult {
  allowed: boolean;
  reason?: string;
  autonomousAlternative?: string;
}

type EstafaActionType =
  | 'SACRIFICE'
  | 'COLD_EXECUTION'
  | 'COMPASSIONATE_HEAL'
  | 'SHARE_ITEM'
  | 'STANDARD';
```
