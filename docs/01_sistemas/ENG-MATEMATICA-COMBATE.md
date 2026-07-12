# ENG-MATEMATICA-COMBATE — Motor de Resolução de Dano (Protótipo Matemático)

---

**ID do Documento:** ENG-MATEMATICA-COMBATE
**Versão:** 1.0.0
**Status:** APROVADO
**Classificação:** Técnico / Arquitetura de Software / Matemática de Balanceamento
**Sistema de Origem:** ENG-PROGRESSAO-NIVEIS, ENG-MOTOR-COMBATE
**Autor:** Núcleo de Arquitetura — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## 1. Objetivo

Este documento formaliza as **equações matemáticas rígidas de resolução de combate** do jogo base 1.0 (Níveis 1–50), definindo:

1. A função de mitigação de dano por armadura (retornos decrescentes hiperbólicos).
2. A resolução de fricção e penetração para equipamentos específicos dos Atos 3 e 5.
3. O multiplicador de vulnerabilidade do estado `FRATURA_FRENESI`.
4. Casos de teste numéricos obrigatórios que provam a estabilidade das fórmulas sem vazamento de balanceamento.

Todas as funções operam sobre os atributos definidos em **ENG-PROGRESSAO-NIVEIS.md** (Seção 4) e respeitam os contratos de dados, clamps de segurança e regras de encapsulamento do sistema.

---

## 2. Convenções de Pseudocódigo

| Notação                    | Significado                                              |
|----------------------------|----------------------------------------------------------|
| `//`                       | Comentário de linha                                      |
| `/* ... */`                | Comentário de bloco                                      |
| `function nome(args)`      | Declaração de função/rotina                              |
| `TIPO`                     | Tipo de dado (int32, int64, float, bool, string)         |
| `=>`                       | Retorno de função / arrow operator                       |
| `===`                      | Comparação estrita de igualdade                          |
| `!==`                      | Comparação estrita de desigualdade                       |
| `clamp(value, min, max)`   | Trunca `value` ao intervalo `[min, max]`                 |
| `floor(value)`             | Arredondamento para baixo (truncatura)                  |
| `roundTo(value, decimals)` | Arredondamento para N casas decimais                     |
| `log_error(code, msg)`     | Registro de erro no log do motor                         |
| `log_warning(msg)`         | Registro de aviso no log do motor                        |
| `dispatch_event(id, data)` | Disparo de evento no barramento global do motor          |

---

## 3. Constantes Calibradas do Motor de Dano

Todas as constantes abaixo foram calibradas para a escala de dano do jogo base (Níveis 1–50), considerando os caps de atributo definidos em **ENG-PROGRESSAO-NIVEIS.md** (Seção 4.1 e 7).

```csharp
// ============================================================
// CONFIGURAÇÕES DO MOTOR DE RESOLUÇÃO DE DANO — enginesettings_combat_damage
// ============================================================

// --- Constante de Mitigação Hiperbólica (Armadura) ---
// A constante K define o ponto de inflexão da curva de mitigação.
// K é calibrado para que a redução de dano cresça suavemente
// do early game (~5% no nível 1) ao endgame (~57% no nível 50),
// sem nunca atingir 100%.
// Fórmula: damage_multiplier = K / (K + effective_defense)
const float   ARMOR_MITIGATION_CONSTANT_K   = 150.0;

// --- Constante de Retorno de Dano Base (Floor Damage) ---
// Garante que mesmo com defesa extremamente alta, o dano mínimo
// absoluto nunca seja inferior a 5% do dano bruto original.
const float   MIN_DAMAGE_FRACTION           = 0.05;   // 5% floor

// --- Modificador de Vulnerabilidade — FRATURA_FRENESI ---
// Multiplicador fixo aplicado ao dano final quando o alvo
// (jogador ou IA inimiga) está sob o estado FRATURA_FRENESI.
const float   FRATURA_FRENESI_MULTIPLIER    = 1.30;   // +30% dano recebido

// --- Modificador de Penetração — EQP-ARM-022 (Marreta de Fricção) ---
// A Marreta de Fricção ignora 40% da armadura nativa do alvo.
// Este valor é aplicado como um fator de redução na defesa efetiva.
const float   FRICTION_ARMOR_IGNORE_FRAC     = 0.40;   // Ignora 40% da defesa nativa

// --- Modificador de Penetração — EQP-ARM-051 (Fuso do Veredito) ---
// O Fuso do Veredito consome 40 de estafa Paterna para garantir
// 100% de penetração contra Abominações do tipo MON-ERR-047.
// Quando ativo, a defesa efetiva é zerada.
// Custo de ativação: 40 de short_term_estafa (lado PATERNO)
const int32   VEREDICT_ESTAFA_COST          = 40;      // Custo em estafa Paterna
// A penetração é absoluta (100%) — a defesa efetiva torna-se 0.
```

---

## 4. Função: `calculate_mitigated_damage`

### 4.1 Propósito

Calcular o dano final mitigado aplicado a um combatente (jogador ou IA inimiga), aplicando a redução por armadura baseada em **retornos decrescentes hiperbólicos**, o multiplicador de vulnerabilidade `FRATURA_FRENESI` quando ativo, e as regras de penetração de equipamentos específicos.

### 4.2 Modelo Matemático

A mitigação de dano por defesa segue o modelo hiperbólico:

$$damage\_multiplier = \frac{K}{K + defense\_effective}$$

Onde:
- $K = 150.0$ (constante de calibração — ver Seção 3)
- $defense\_effective$ é o valor de defesa após aplicar penetrações e fricções

**Propriedades da curva hiperbólica:**
- Quando $defense = 0$: $damage\_multiplier = 1.0$ (dano integral)
- Quando $defense \to \infty$: $damage\_multiplier \to 0$ (assíntota)
- $damage\_multiplier$ **nunca** atinge 0 — garantia de dano mínimo
- A taxa de redução por ponto de defesa decresce monotonicamente com o aumento da defesa

### 4.3 Contrato de Interface

```
/*
 * Função: calculate_mitigated_damage
 * 
 * Calcula o dano final mitigado após aplicar redução por armadura,
 * modificadores de penetração/fricção de equipamentos, e o
 * multiplicador de vulnerabilidade FRATURA_FRENESI.
 *
 * Entrada:
 *   raw_damage   (float)  — Dano bruto calculado pela fonte (não mitigado)
 *   defense      (float)  — Valor de defesa nativa do alvo (base_defense)
 *   is_fractured (bool)   — Se o alvo está sob o estado FRATURA_FRENESI
 *   penetration_sources  (PenetrationSource[]) — Lista de modificadores
 *                            de penetração ativos (equipamentos, habilidades)
 *
 * Saída:
 *   MitigatedDamageResult — Estrutura contendo dano final e metadados
 *
 * Garantias:
 *   - O dano final NUNCA é negativo (clamp mínimo de 0)
 *   - O dano final NUNCA excede raw_damage (sem amplificação por defesa)
 *   - A mitigação NUNCA atinge 100% (mínimo MIN_DAMAGE_FRACTION = 5%)
 *   - Overflow de float: protegido por clamp preventivo
 */
function calculate_mitigated_damage(
    raw_damage: float,
    defense: float,
    is_fractured: bool,
    penetration_sources: PenetrationSource[]
) -> MitigatedDamageResult
```

### 4.4 Estruturas de Dados Auxiliares

```
// Fonte de penetração ativa
interface PenetrationSource {
    source_id: string;          // Identificador (ex: "EQP-ARM-022", "EQP-ARM-051")
    source_name: string;        // Nome legível (ex: "Marreta de Fricção")
    penetration_type: string;   // "FRICTION" | "ABSOLUTE" | "FLAT"
    penetration_value: float;   // Valor do modificador (ex: 0.40 para fricção)
    is_active: bool;            // Se a fonte está ativa no momento
    requires_estafa_cost: bool; // Se requer consumo de estafa (ex: Fuso do Veredito)
}

// Resultado do cálculo de mitigação
interface MitigatedDamageResult {
    success: bool;                  // Se o cálculo foi bem-sucedido
    error_code: string | null;      // Código de erro, se houver

    // Valores intermediários (para depuração e logging)
    raw_damage: float;              // Dano bruto original (input)
    defense_native: float;          // Defesa nativa do alvo (input)
    defense_effective: float;       // Defesa efetiva após penetrações

    damage_multiplier_base: float;  // K / (K + defense_effective)
    damage_after_mitigation: float; // raw_damage * damage_multiplier_base

    fracture_applied: bool;         // Se o multiplicador FRATURA_FRENESI foi aplicado
    fracture_multiplier: float;     // 1.30 se fracture_applied, senão 1.0

    // Valores finais
    damage_final: float;            // Dano final após todos os modificadores
    damage_reduction_pct: float;    // Percentual de redução total (0.0 a 100.0)

    // Metadados de penetração
    penetrations_applied: string[]; // Lista de source_id das penetrações aplicadas
}
```

### 4.5 Pseudocódigo — `calculate_mitigated_damage`

```
function calculate_mitigated_damage(
    raw_damage: float,
    defense: float,
    is_fractured: bool,
    penetration_sources: PenetrationSource[]
) -> MitigatedDamageResult {

    /* ============================================================
     *  ETAPA 1: VALIDAÇÃO DE ENTRADA
     * ============================================================ */

    // 1.1 Valida raw_damage
    if (raw_damage < 0.0 || isNaN(raw_damage) || !isFinite(raw_damage)) {
        log_error("DMG-ERR-001",
            "calculate_mitigated_damage: raw_damage inválido — " + raw_damage);
        return {
            success: false,
            error_code: "DMG-ERR-001",
            damage_final: 0.0,
            damage_reduction_pct: 0.0
        };
    }

    // 1.2 Valida defense
    if (defense < 0.0 || isNaN(defense) || !isFinite(defense)) {
        log_error("DMG-ERR-002",
            "calculate_mitigated_damage: defense inválida — " + defense);
        return {
            success: false,
            error_code: "DMG-ERR-002",
            damage_final: raw_damage,  // Fallback seguro: dano integral
            damage_reduction_pct: 0.0
        };
    }

    // 1.3 Valida overflow de raw_damage (proteção contra float gigante)
    if (raw_damage > 1e12) {
        log_warning("DMG-OVERFLOW: raw_damage excessivo (" + raw_damage + "). Truncando.");
        raw_damage = 1e12;
    }

    /* ============================================================
     *  ETAPA 2: CÁLCULO DA DEFESA EFETIVA
     *  Aplica os modificadores de penetração ativos na ordem:
     *    1. Fricção (percentual) — reduz a defesa nativa em X%
     *    2. Absoluta (100%)      — zera a defesa nativa
     *    3. Plana (flat)         — subtrai valor fixo da defesa nativa
     * ============================================================ */

    let defense_effective: float = defense;          // Começa com a defesa nativa
    let penetrations_applied: string[] = [];          // Lista de IDs aplicados
    let veredict_estafa_consumed: bool = false;      // Flag de consumo de estafa

    // 2.1 Ordena penetrações: FRICTION primeiro, depois FLAT, depois ABSOLUTE
    //     ABSOLUTE deve ser o último porque zera a defesa
    let sorted_sources: PenetrationSource[] = sort_penetration_sources(penetration_sources);

    for each (source in sorted_sources) {
        if (!source.is_active) {
            continue;  // Pula fontes inativas
        }

        // 2.2 Verifica se a penetração requer consumo de estafa Paterna
        if (source.requires_estafa_cost) {
            // O consumo de estafa é verificado externamente (antes da chamada)
            // Aqui apenas confirmamos que o custo foi pago
            // Se o custo não foi pago, a fonte NÃO deve estar marcada como is_active
            veredict_estafa_consumed = true;
        }

        switch (source.penetration_type) {

            case "FRICTION":
                // Ex: Marreta de Fricção — ignora 40% da defesa nativa
                // Aplica-se sobre a defesa nativa ORIGINAL, não sobre defense_effective atual
                let friction_reduction: float = defense * source.penetration_value;
                defense_effective -= friction_reduction;
                penetrations_applied.push(source.source_id);

                log_debug("Penetração FRICTION aplicada: " + source.source_id
                    + " — redução de " + friction_reduction
                    + " pontos de defesa (" + (source.penetration_value * 100) + "%)");
                break;

            case "ABSOLUTE":
                // Ex: Fuso do Veredito — 100% de penetração
                // Zera completamente a defesa efetiva
                defense_effective = 0.0;
                penetrations_applied.push(source.source_id);

                log_debug("Penetração ABSOLUTE aplicada: " + source.source_id
                    + " — defesa zerada (100% de penetração)");
                break;

            case "FLAT":
                // Penetração plana — subtrai valor fixo
                let flat_reduction: float = source.penetration_value;
                defense_effective -= flat_reduction;
                penetrations_applied.push(source.source_id);

                log_debug("Penetração FLAT aplicada: " + source.source_id
                    + " — redução plana de " + flat_reduction + " pontos");
                break;

            default:
                log_warning("Tipo de penetração desconhecido: " + source.penetration_type
                    + " para fonte " + source.source_id + ". Ignorando.");
                break;
        }
    }

    // 2.3 Clamp de segurança: defesa efetiva NUNCA negativa
    if (defense_effective < 0.0) {
        defense_effective = 0.0;
        log_warning("BOUNDS-010: defense_effective truncada para 0.0 (era negativa).");
    }

    /* ============================================================
     *  ETAPA 3: CÁLCULO DO MULTIPLICADOR BASE DE MITIGAÇÃO
     *  Fórmula hiperbólica: damage_multiplier = K / (K + defense_effective)
     * ============================================================ */

    let K: float = ARMOR_MITIGATION_CONSTANT_K;

    // 3.1 Cálculo do multiplicador base
    let damage_multiplier_base: float = K / (K + defense_effective);

    // 3.2 Clamp de segurança do multiplicador
    //     Garante: 0.0 < damage_multiplier_base <= 1.0
    if (damage_multiplier_base < 0.0) {
        damage_multiplier_base = 0.0;
        log_error("DMG-ERR-003",
            "damage_multiplier_base negativo. Corrigido para 0.0. defense_effective="
            + defense_effective);
    }
    if (damage_multiplier_base > 1.0) {
        damage_multiplier_base = 1.0;
        log_warning("BOUNDS-011: damage_multiplier_base truncado para 1.0 (máximo).");
    }

    // 3.3 Aplica o dano mínimo (floor) — garantia de 5% de dano mínimo
    //     Mesmo com defesa infinita, o dano nunca é inferior a MIN_DAMAGE_FRACTION
    if (damage_multiplier_base < MIN_DAMAGE_FRACTION) {
        damage_multiplier_base = MIN_DAMAGE_FRACTION;
        log_debug("Floor de dano mínimo aplicado: " + MIN_DAMAGE_FRACTION);
    }

    // 3.4 Cálculo do dano pós-mitigação base
    let damage_after_mitigation: float = raw_damage * damage_multiplier_base;

    /* ============================================================
     *  ETAPA 4: APLICAÇÃO DO MULTIPLICADOR DE VULNERABILIDADE
     *  FRATURA_FRENESI — amplifica o dano recebido em 30%
     * ============================================================ */

    let fracture_applied: bool = false;
    let fracture_multiplier: float = 1.0;   // Neutro — sem amplificação

    if (is_fractured) {
        fracture_multiplier = FRATURA_FRENESI_MULTIPLIER;  // 1.30
        fracture_applied = true;

        log_debug("FRATURA_FRENESI ativo no alvo. Multiplicador de dano: "
            + fracture_multiplier);
    }

    // 4.1 Aplica o multiplicador de vulnerabilidade
    let damage_final: float = damage_after_mitigation * fracture_multiplier;

    /* ============================================================
     *  ETAPA 5: CLAMPS FINAIS DE SEGURANÇA
     * ============================================================ */

    // 5.1 Dano final NUNCA negativo
    if (damage_final < 0.0) {
        damage_final = 0.0;
        log_error("DMG-ERR-004",
            "damage_final negativo. Corrigido para 0.0.");
    }

    // 5.2 Dano final NUNCA excede raw_damage (a menos que fracture esteja ativo)
    //     Com fracture, o dano pode exceder raw_damage (é intencional — +30%)
    //     Sem fracture, o dano NUNCA pode exceder raw_damage
    if (!fracture_applied && damage_final > raw_damage) {
        damage_final = raw_damage;
        log_warning("BOUNDS-012: damage_final truncado para raw_damage (sem fracture).");
    }

    // 5.3 Proteção contra NaN e Infinity
    if (isNaN(damage_final) || !isFinite(damage_final)) {
        damage_final = 0.0;
        log_error("DMG-ERR-005",
            "damage_final é NaN ou Infinity. Corrigido para 0.0.");
    }

    /* ============================================================
     *  ETAPA 6: CÁLCULO DO PERCENTUAL DE REDUÇÃO
     * ============================================================ */

    // 6.1 Percentual de redução total (considerando todos os modificadores)
    //     Fórmula: (1 - (damage_final / raw_damage)) * 100
    let damage_reduction_pct: float;
    if (raw_damage > 0.0) {
        damage_reduction_pct = (1.0 - (damage_final / raw_damage)) * 100.0;
    } else {
        damage_reduction_pct = 0.0;  // raw_damage == 0 → sem redução
    }

    // 6.2 Clamp do percentual
    damage_reduction_pct = clamp(damage_reduction_pct, 0.0, 100.0);

    /* ============================================================
     *  ETAPA 7: RETORNO
     * ============================================================ */

    return {
        success: true,
        error_code: null,

        raw_damage: raw_damage,
        defense_native: defense,
        defense_effective: defense_effective,

        damage_multiplier_base: damage_multiplier_base,
        damage_after_mitigation: damage_after_mitigation,

        fracture_applied: fracture_applied,
        fracture_multiplier: fracture_applied ? FRATURA_FRENESI_MULTIPLIER : 1.0,

        damage_final: damage_final,
        damage_reduction_pct: damage_reduction_pct,

        penetrations_applied: penetrations_applied
    };
}
```

### 4.6 Função Auxiliar — `sort_penetration_sources`

```
/*
 * Ordena as fontes de penetração para aplicação na ordem correta:
 * 1. FRICTION (primeiro — reduz a defesa percentualmente)
 * 2. FLAT     (segundo  — subtrai valor fixo)
 * 3. ABSOLUTE (último  — zera a defesa, deve ser o último)
 */
function sort_penetration_sources(sources: PenetrationSource[]): PenetrationSource[] {
    let priority_map: map = {
        "FRICTION": 0,
        "FLAT": 1,
        "ABSOLUTE": 2
    };

    return sources.sort((a, b) => {
        let priority_a: int32 = priority_map[a.penetration_type] ?? 999;
        let priority_b: int32 = priority_map[b.penetration_type] ?? 999;
        return priority_a - priority_b;
    });
}
```

---

## 5. Resolução de Fricção e Penetração — Equipamentos Específicos

### 5.1 EQP-ARM-022 — Marreta de Fricção (Ato 3)

**Descrição:** Marreta pesada de combate corpo a corpo cujo impacto gera fricção térmica suficiente para corroer armaduras nativas. Ignora 40% da armadura nativa do alvo.

**Regras de Ativação:**
- Fonte de penetração ativa permanentemente enquanto a arma está equipada.
- NÃO requer consumo de estafa para ativar a penetração.
- O modificador é aplicado sobre a **defesa nativa original** do alvo, não sobre o valor já modificado por outras penetrações.
- A redução é recalculada a cada golpe (não é cumulativa com múltiplos acertos).

**Configuração da Fonte de Penetração:**

```csharp
PenetrationSource marretaFriccao = {
    source_id: "EQP-ARM-022",
    source_name: "Marreta de Fricção",
    penetration_type: "FRICTION",
    penetration_value: 0.40,   // Ignora 40% da defesa nativa
    is_active: true,           // Sempre ativa enquanto equipada
    requires_estafa_cost: false
};
```

**Cálculo do Efeito:**

```
// Exemplo: alvo com 100.0 de defesa nativa
// Marreta de Fricção aplica:
//   reducao = 100.0 * 0.40 = 40.0
//   defesa_efetiva = 100.0 - 40.0 = 60.0
//
// Sem Marreta: damage_multiplier = 150 / (150 + 100) = 0.600
// Com Marreta:  damage_multiplier = 150 / (150 + 60)  = 0.714
// Aumento efetivo de dano: 0.714 / 0.600 = 1.19x (+19%)
```

### 5.2 EQP-ARM-051 — Fuso do Veredito (Ato 5)

**Descrição:** Fusível rúnico de julgamento que consome 40 de estafa Paterna (`short_term_estafa`) para garantir 100% de penetração contra Abominações do tipo `MON-ERR-047`. O custo de estafa é pago no momento da ativação, antes do cálculo de dano.

**Regras de Ativação:**
- A ativação é **voluntária** — o jogador decide quando consumir os 40 de estafa Paterna.
- O custo de 40 de estafa é subtraído de `short_term_estafa` **antes** do cálculo de dano.
- Se o jogador não tiver pelo menos 40 de estafa Paterna disponível (posição atual no medidor), a ativação é **bloqueada**.
- O efeito de penetração dura apenas para o **próximo golpe** contra uma Abominação `MON-ERR-047`.
- Se o golpe não acertar um inimigo do tipo `MON-ERR-047`, a estafa é consumida mas o efeito é perdido (penalidade).
- A penetração é **absoluta** (100%) — a defesa efetiva do alvo torna-se 0.

**Configuração da Fonte de Penetração:**

```csharp
PenetrationSource fusoVeredito = {
    source_id: "EQP-ARM-051",
    source_name: "Fuso do Veredito",
    penetration_type: "ABSOLUTE",
    penetration_value: 1.00,   // 100% de penetração
    is_active: false,          // Ativado manualmente pelo jogador
    requires_estafa_cost: true  // Requer 40 de estafa Paterna
};
```

**Pseudocódigo de Ativação:**

```
/*
 * Função: activate_veredict_fuse(player, enemy)
 *
 * Tenta ativar o Fuso do Veredito contra um inimigo alvo.
 * Se o alvo for do tipo MON-ERR-047 e o jogador tiver
 * estafa Paterna >= 40, ativa a penetração absoluta.
 *
 * Retorno: ActivationResult
 */
function activate_veredict_fuse(player, enemy) -> ActivationResult {

    // 1. Verifica se o inimigo é do tipo MON-ERR-047
    if (enemy.enemy_type !== "MON-ERR-047") {
        log_warning("Fuso do Veredito: alvo NÃO é MON-ERR-047. "
            + "Estafa será consumida sem efeito.");

        // Consome a estafa mesmo assim (penalidade)
        player.short_term_estafa -= VEREDICT_ESTAFA_COST;

        // Aplica clamp de segurança
        if (player.short_term_estafa < -100) {
            player.short_term_estafa = -100;
        }

        // Dispara evento de penalidade
        dispatch_event("EVT_VEREDICT_MISUSE", {
            player_id: player.id,
            estafa_consumed: VEREDICT_ESTAFA_COST,
            target_type: enemy.enemy_type,
            expected_type: "MON-ERR-047"
        });

        return {
            success: false,
            activated: false,
            error: "Alvo não é MON-ERR-047",
            estafa_consumed: VEREDICT_ESTAFA_COST
        };
    }

    // 2. Verifica se o jogador tem estafa Paterna suficiente (>= 40)
    if (player.short_term_estafa < VEREDICT_ESTAFA_COST) {
        log_warning("Fuso do Veredito: estafa insuficiente. "
            + "Estafa atual: " + player.short_term_estafa
            + ", necessário: " + VEREDICT_ESTAFA_COST);

        return {
            success: false,
            activated: false,
            error: "Estafa insuficiente",
            estafa_consumed: 0
        };
    }

    // 3. Consome a estafa Paterna
    player.short_term_estafa -= VEREDICT_ESTAFA_COST;

    // 4. Aplica clamp de segurança
    if (player.short_term_estafa < -100) {
        player.short_term_estafa = -100;
    }

    // 5. Ativa a penetração absoluta no próximo golpe
    player.veredict_fuse_active = true;

    // 6. Dispara evento de ativação
    dispatch_event("EVT_VEREDICT_ACTIVATE", {
        player_id: player.id,
        estafa_consumed: VEREDICT_ESTAFA_COST,
        estafa_remaining: player.short_term_estafa,
        target_enemy_id: enemy.id
    });

    log_debug("Fuso do Veredito ativado. Estafa consumida: "
        + VEREDICT_ESTAFA_COST
        + ". Estafa restante: " + player.short_term_estafa);

    return {
        success: true,
        activated: true,
        error: null,
        estafa_consumed: VEREDICT_ESTAFA_COST,
        estafa_remaining: player.short_term_estafa
    };
}
```

---

## 6. Multiplicador de Vulnerabilidade — FRATURA_FRENESI

### 6.1 Definição

O estado `FRATURA_FRENESI` é um estado de colapso ofensivo (lado PATERNO do medidor de Estafa) que impõe um **multiplicador fixo de 1.30x** sobre todo dano recebido pelo combatente afetado.

### 6.2 Especificação do Modificador

| Campo                          | Valor                          |
|--------------------------------|--------------------------------|
| **ID do Estado**               | `FRATURA_FRENESI`              |
| **Condição de ativação**       | `short_term_estafa >= 100`     |
| **Duração mínima**             | 5.0 segundos                   |
| **Multiplicador de dano**      | 1.30x (fixo, imutável)         |
| **Tipo de modificador**        | Multiplicativo (aplicado ao dano pós-mitigação) |
| **Escopo**                     | Aplica-se a jogador e IA inimiga igualmente |
| **Empilhamento**               | NÃO acumula com outros modificadores de dano recebido. O maior valor prevalece. |

### 6.3 Pseudocódigo de Aplicação

A aplicação é feita dentro de `calculate_mitigated_damage` (Etapa 4). O modificador é aplicado **após** a mitigação por armadura:

```csharp
// Aplicação do multiplicador FRATURA_FRENESI
// (dentro de calculate_mitigated_damage — Etapa 4)
if (is_fractured) {
    damage_final = damage_after_mitigation * FRATURA_FRENESI_MULTIPLIER;  // 1.30
} else {
    damage_final = damage_after_mitigation;
}
```

### 6.4 Regras de Interação

```
/* ============================================================
 * REGRA: FRATURA_FRENESI + PENETRAÇÃO ABSOLUTA
 * Se o alvo está com FRATURA_FRENESI ativo E sofre um golpe
 * com penetração absoluta (ex: Fuso do Veredito), o dano é:
 *
 *   damage_final = raw_damage * 1.0 (sem mitigação) * 1.30
 *                = raw_damage * 1.30
 *
 * Ou seja, a vulnerabilidade é aplicada APÓS a mitigação,
 * mesmo que a mitigação seja zero.
 * ============================================================ */

/* ============================================================
 * REGRA: FRATURA_FRENESI NÃO SE AUTO-AMPLIFICA
 * O estado FRATURA_FRENESI não amplifica o dano que causou
 * a ativação do estado. A amplificação só se aplica a danos
 * recebidos ENQUANTO o estado está ativo.
 * ============================================================ */

/* ============================================================
 * REGRA: NÃO ACUMULAÇÃO
 * FRATURA_FRENESI (1.30x) não acumula com outros modificadores
 * de dano recebido. Se múltiplas fontes de amplificação de dano
 * recebido estiverem ativas, o MAIOR multiplicador prevalece.
 * ============================================================ */
```

---

## 7. Casos de Teste Numéricos

### 7.1 Caso de Teste 1 — Ato 1 (Early Game): Atacante Nível 10 vs Monstro do Ato 1

**Cenário:** Jogador nível 10 executando um ataque básico contra um monstro padrão de Vardhelm (Ato 1).

**Parâmetros de Entrada:**

| Parâmetro                 | Valor         | Fonte                                          |
|---------------------------|---------------|------------------------------------------------|
| `raw_damage`              | 55.46         | Dano base nível 10 (ENG-PROGRESSAO-NIVEIS 4.4)|
| `defense` (alvo)          | 8.0           | Defesa base de monstro nível apropriado        |
| `is_fractured`            | false         | Sem FRATURA_FRENESI ativo                      |
| `penetration_sources`     | []            | Sem penetrações ativas                         |
| K (constante)             | 150.0         | ARMOR_MITIGATION_CONSTANT_K                    |

**Cálculo Passo a Passo:**

```
1. defense_effective = 8.0 (sem penetrações)

2. damage_multiplier_base = 150.0 / (150.0 + 8.0)
                          = 150.0 / 158.0
                          = 0.949367

3. damage_after_mitigation = 55.46 * 0.949367
                           = 52.65

4. fracture_multiplier = 1.0 (is_fractured = false)

5. damage_final = 52.65 * 1.0 = 52.65

6. damage_reduction_pct = (1.0 - 52.65 / 55.46) * 100
                        = (1.0 - 0.9494) * 100
                        = 5.06%
```

**Resultado Esperado:**

| Variável                    | Valor     |
|-----------------------------|-----------|
| `damage_multiplier_base`    | 0.9494    |
| `defense_effective`         | 8.0       |
| `damage_after_mitigation`   | 52.65     |
| `fracture_applied`          | false     |
| `damage_final`              | **52.65** |
| `damage_reduction_pct`      | 5.06%     |

**Interpretação:** No early game, a defesa do monstro reduz apenas ~5% do dano bruto. O combate é rápido e letal, incentivando agressividade.

---

### 7.2 Caso de Teste 2 — Ato 1 (Early Game): Jogador Nível 10 SOB FRATURA_FRENESI

**Cenário:** O jogador nível 10 atingiu o limite PATERNO do medidor de Estafa e está sob o estado `FRATURA_FRENESI`. O mesmo monstro do Ato 1 contra-ataca.

**Parâmetros de Entrada:**

| Parâmetro                 | Valor         | Fonte                                          |
|---------------------------|---------------|------------------------------------------------|
| `raw_damage` (ataque inimigo) | 25.0     | Dano típico de monstro Ato 1                   |
| `defense` (jogador)       | 42.69         | Defesa do jogador nível 10 (ENG-PROGRESSAO)    |
| `is_fractured`            | true          | Jogador sob FRATURA_FRENESI                    |
| `penetration_sources`     | []            | Monstro sem penetrações                        |
| K (constante)             | 150.0         | ARMOR_MITIGATION_CONSTANT_K                    |

**Cálculo Passo a Passo:**

```
1. defense_effective = 42.69 (sem penetrações)

2. damage_multiplier_base = 150.0 / (150.0 + 42.69)
                          = 150.0 / 192.69
                          = 0.7785

3. damage_after_mitigation = 25.0 * 0.7785
                           = 19.46

4. fracture_multiplier = 1.30 (FRATURA_FRENESI ativo)

5. damage_final = 19.46 * 1.30 = 25.30

6. damage_reduction_pct = (1.0 - 25.30 / 25.0) * 100
                        (nota: dano final > raw_damage é intencional — amplificação)
                        = -1.20% (negativo = amplificação)
```

**Resultado Esperado:**

| Variável                    | Valor     |
|-----------------------------|-----------|
| `damage_multiplier_base`    | 0.7785    |
| `defense_effective`         | 42.69     |
| `damage_after_mitigation`   | 19.46     |
| `fracture_applied`          | true      |
| `damage_final`              | **25.30** |
| `amplification_vs_raw`      | +1.2%     |

**Interpretação:** A defesa do jogador nível 10 mitiga ~22% do dano bruto, mas a vulnerabilidade FRATURA_FRENESI anula essa mitigação e ainda amplifica ligeiramente o dano final. O jogador em frenesi recebe mais dano do que o ataque bruto original.

---

### 7.3 Caso de Teste 3 — Ato 3 (Mid Game): Marreta de Fricção em Ação

**Cenário:** Jogador nível 30 usando a **EQP-ARM-022 (Marreta de Fricção)** contra um Elite de Brenhold (Ato 3). A marreta ignora 40% da armadura nativa.

**Parâmetros de Entrada:**

| Parâmetro                 | Valor         | Fonte                                          |
|---------------------------|---------------|------------------------------------------------|
| `raw_damage`              | 178.09        | Dano base nível 30 (ENG-PROGRESSAO-NIVEIS 4.4)|
| `defense` (alvo Elite)    | 120.0         | Defesa típica de Elite Ato 3                   |
| `is_fractured`            | false         | Sem FRATURA_FRENESI ativo                      |
| `penetration_sources`     | [EQP-ARM-022] | Marreta de Fricção ativa                       |

**Cálculo Passo a Passo:**

```
1. Penetração FRICTION aplicada:
   reducao_friccao = 120.0 * 0.40 = 48.0
   defense_effective = 120.0 - 48.0 = 72.0

2. damage_multiplier_base = 150.0 / (150.0 + 72.0)
                          = 150.0 / 222.0
                          = 0.6757

3. damage_after_mitigation = 178.09 * 0.6757
                           = 120.33

4. fracture_multiplier = 1.0 (is_fractured = false)

5. damage_final = 120.33 * 1.0 = 120.33

6. damage_reduction_pct = (1.0 - 120.33 / 178.09) * 100
                        = (1.0 - 0.6757) * 100
                        = 32.43%
```

**Comparação Sem Marreta:**

| Variável               | Sem Marreta       | Com Marreta       | Ganho        |
|------------------------|-------------------|-------------------|--------------|
| `defense_effective`    | 120.0             | 72.0              | -40% defesa  |
| `damage_multiplier`    | 0.5556            | 0.6757            | +21.6%       |
| `damage_final`         | 98.93             | 120.33            | **+21.6%**   |

**Resultado Esperado:**

| Variável                    | Valor     |
|-----------------------------|-----------|
| `damage_multiplier_base`    | 0.6757    |
| `defense_effective`         | 72.0      |
| `damage_after_mitigation`   | 120.33    |
| `fracture_applied`          | false     |
| `damage_final`              | **120.33**|
| `damage_reduction_pct`      | 32.43%    |
| `ganho_relativo`            | +21.6%    |

**Interpretação:** A Marreta de Fricção proporciona um ganho de ~21.6% de dano contra alvos com defesa moderada (120). O ganho é significativo sem ser quebrado.

---

### 7.4 Caso de Teste 4 — Ato 4 (Late Game): Defesa Alta, Sem Penetração

**Cenário:** Jogador nível 40 contra um inimigo com defesa muito alta (próximo ao cap) sem penetrações ativas.

**Parâmetros de Entrada:**

| Parâmetro                 | Valor         | Fonte                                          |
|---------------------------|---------------|------------------------------------------------|
| `raw_damage`              | 233.04        | Dano base nível 40 (ENG-PROGRESSAO-NIVEIS 4.4)|
| `defense` (alvo)          | 200.0         | Defesa no cap máximo                           |
| `is_fractured`            | false         | Sem FRATURA_FRENESI ativo                      |
| `penetration_sources`     | []            | Sem penetrações ativas                         |

**Cálculo Passo a Passo:**

```
1. defense_effective = 200.0 (sem penetrações)

2. damage_multiplier_base = 150.0 / (150.0 + 200.0)
                          = 150.0 / 350.0
                          = 0.4286

3. damage_after_mitigation = 233.04 * 0.4286
                           = 99.88

4. fracture_multiplier = 1.0

5. damage_final = 99.88

6. damage_reduction_pct = (1.0 - 99.88 / 233.04) * 100
                        = (1.0 - 0.4286) * 100
                        = 57.14%
```

**Resultado Esperado:**

| Variável                    | Valor     |
|-----------------------------|-----------|
| `damage_multiplier_base`    | 0.4286    |
| `defense_effective`         | 200.0     |
| `damage_after_mitigation`   | 99.88     |
| `fracture_applied`          | false     |
| `damage_final`              | **99.88** |
| `damage_reduction_pct`      | 57.14%    |

**Interpretação:** Mesmo com a defesa no cap máximo (200), a redução é de ~57%. O dano mínimo de 5% garante que o combate nunca se torne impossível.

---

### 7.5 Caso de Teste 5 — Ato 5 (Endgame): Fuso do Veredito + FRATURA_FRENESI vs Chefe Final

**Cenário:** Jogador nível 50, com a **EQP-ARM-051 (Fuso do Veredito)** ativado contra o Chefe Final (tipo `MON-ERR-047`), que está sob o estado `FRATURA_FRENESI`. Cenário de pico de dano.

**Parâmetros de Entrada:**

| Parâmetro                 | Valor         | Fonte                                          |
|---------------------------|---------------|------------------------------------------------|
| `raw_damage`              | 250.0         | Dano base cap nível 50 (ENG-PROGRESSAO 4.4)   |
| `defense` (Chefe Final)   | 200.0         | Defesa no cap máximo                           |
| `is_fractured`            | true          | Chefe sob FRATURA_FRENESI                      |
| `penetration_sources`     | [EQP-ARM-051] | Fuso do Veredito ativo (penetração absoluta)   |
| Estafa consumida          | 40            | Custo de ativação do Fuso                      |

**Cálculo Passo a Passo:**

```
1. Penetração ABSOLUTE aplicada:
   defense_effective = 0.0 (100% de penetração)

2. damage_multiplier_base = 150.0 / (150.0 + 0.0)
                          = 150.0 / 150.0
                          = 1.0 (dano integral sem mitigação)

3. damage_after_mitigation = 250.0 * 1.0 = 250.0

4. fracture_multiplier = 1.30 (FRATURA_FRENESI ativo no chefe)

5. damage_final = 250.0 * 1.30 = 325.0

6. damage_reduction_pct = (1.0 - 325.0 / 250.0) * 100
                        = -30.0% (amplificação de 30%)
```

**Resultado Esperado:**

| Variável                    | Valor     |
|-----------------------------|-----------|
| `damage_multiplier_base`    | 1.0       |
| `defense_effective`         | 0.0       |
| `damage_after_mitigation`   | 250.0     |
| `fracture_applied`          | true      |
| `damage_final`              | **325.0** |
| `amplification_vs_raw`      | +30%      |

**Interpretação:** A combinação de penetração absoluta (Fuso do Veredito) + FRATURA_FRENESI no alvo produz **325.0 de dano** — um pico de +30% sobre o dano bruto máximo do jogador. Este é o teto de dano teórico do jogo base.

---

### 7.6 Caso de Teste 6 — Prova da Assíntota: Defesa Extremamente Alta

**Cenário:** Teste de borda para provar que a mitigação NUNCA atinge 100%, mesmo com defesa arbitrariamente alta.

**Parâmetros de Entrada:**

| Parâmetro                 | Valor                | Fonte                              |
|---------------------------|----------------------|------------------------------------|
| `raw_damage`              | 1000.0               | Valor arbitrário alto              |
| `defense` (teórica)       | 1_000_000.0          | Defesa absurdamente alta (1 milhão)|
| `is_fractured`            | false                | Sem FRATURA_FRENESI                |
| `penetration_sources`     | []                   | Sem penetrações                    |

**Cálculo:**

```
1. defense_effective = 1_000_000.0

2. damage_multiplier_base = 150.0 / (150.0 + 1_000_000.0)
                          = 150.0 / 1_000_150.0
                          = 0.00014998

3. Aplica floor de dano mínimo (5%):
   damage_multiplier_base = max(0.00014998, 0.05) = 0.05

4. damage_final = 1000.0 * 0.05 = 50.0
```

**Resultado Esperado:**

| Variável                    | Valor        |
|-----------------------------|--------------|
| `damage_multiplier_base`    | 0.05 (floor) |
| `defense_effective`         | 1_000_000.0  |
| `damage_final`              | **50.0**     |
| `damage_reduction_pct`      | 95.0%        |
| `mitigacao_atingiu_100%`    | **NÃO**      |

**Interpretação:** Mesmo com 1 milhão de defesa, o dano mínimo de 5% (floor) garante que o alvo sempre tome pelo menos 50 de dano. A mitigação NUNCA atinge 100%.

---

### 7.7 Tabela Resumo dos Casos de Teste

| Caso | Cenário                        | raw_damage | defense | Penetração | Fracture | damage_final | Redução  |
|------|--------------------------------|-----------|---------|------------|----------|-------------|----------|
| 1    | Early Game (Ato 1)             | 55.46     | 8.0     | Nenhuma    | Não      | 52.65       | 5.06%    |
| 2    | Jogador Fractured (Ato 1)      | 25.00     | 42.69   | Nenhuma    | Sim      | 25.30       | -1.2%*   |
| 3    | Marreta de Fricção (Ato 3)     | 178.09    | 120.0   | FRICTION   | Não      | 120.33      | 32.43%   |
| 4    | Defesa Cap (Ato 4)             | 233.04    | 200.0   | Nenhuma    | Não      | 99.88       | 57.14%   |
| 5    | Fuso + Fracture (Ato 5)        | 250.00    | 200.0   | ABSOLUTE   | Sim      | 325.00      | -30.0%*  |
| 6    | Prova da Assíntota (borda)     | 1000.0    | 1e6     | Nenhuma    | Não      | 50.00       | 95.0%    |

(*Valores negativos indicam amplificação, não redução.)

---

## 8. Tabela de Códigos de Erro do Motor de Dano

| Código          | Descrição                                                       | Etapa de Origem            | Ação do Motor                                      |
|-----------------|-----------------------------------------------------------------|----------------------------|----------------------------------------------------|
| `DMG-ERR-001`   | `raw_damage` inválido (negativo, NaN, ou infinito)              | Etapa 1 — Validação input  | Retorna `success: false`, dano final = 0           |
| `DMG-ERR-002`   | `defense` inválida (negativa, NaN, ou infinito)                 | Etapa 1 — Validação input  | Retorna `success: false`, dano final = raw_damage (fallback) |
| `DMG-ERR-003`   | `damage_multiplier_base` negativo (erro matemático)             | Etapa 3 — Cálculo          | Corrige para 0.0 + log de erro                     |
| `DMG-ERR-004`   | `damage_final` negativo (erro no cálculo de amplificação)       | Etapa 5 — Clamp final      | Corrige para 0.0 + log de erro                     |
| `DMG-ERR-005`   | `damage_final` é NaN ou Infinity (overflow/underflow)           | Etapa 5 — Clamp final      | Corrige para 0.0 + log de erro                     |
| `BOUNDS-010`    | `defense_effective` truncada para 0.0 (era negativa)            | Etapa 2 — Clamp defesa     | Trunca + log warning                                |
| `BOUNDS-011`    | `damage_multiplier_base` truncado para 1.0 (máximo)             | Etapa 3 — Clamp mult       | Trunca + log warning                                |
| `BOUNDS-012`    | `damage_final` truncado para `raw_damage` (sem fracture)        | Etapa 5 — Clamp final      | Trunca + log warning                                |

---

## 9. Matriz de Dependências

| Componente                    | Função / Constante                        | Tipo de Dependência | Observação                                      |
|-------------------------------|-------------------------------------------|---------------------|-------------------------------------------------|
| ENG-PROGRESSAO-NIVEIS         | `base_physical_damage` (10.0–250.0)       | Leitura             | Fornece `raw_damage` para cálculos             |
| ENG-PROGRESSAO-NIVEIS         | `base_defense` (8.0–200.0)                | Leitura             | Fornece `defense` para mitigação               |
| ENG-PROGRESSAO-NIVEIS         | Caps de atributo (Seção 4.1)              | Leitura             | Validação de input                              |
| ENG-MOTOR-COMBATE             | `FRATURA_FRENESI` (1.30x)                 | Leitura             | Multiplicador de vulnerabilidade                |
| ENG-MOTOR-COMBATE             | `check_overload_states`                   | Gatilho             | Ativa/desativa FRATURA_FRENESI no combatente    |
| ENG-MOTOR-COMBATE             | `process_ability_delta`                   | Gatilho             | Consome estafa para Fuso do Veredito            |
| ENG-ESTRUTURA-DADOS            | `short_term_estafa` (-100 a +100)         | Leitura/Escrita     | Verificação e consumo de estafa para penetrações |
| Sistema de Itens              | `EQP-ARM-022` (Marreta de Fricção)        | Leitura             | Fornece PenetrationSource com tipo FRICTION     |
| Sistema de Itens              | `EQP-ARM-051` (Fuso do Veredito)          | Leitura             | Fornece PenetrationSource com tipo ABSOLUTE     |
| Sistema de Inimigos           | `MON-ERR-047` (Abominação do Veredito)    | Leitura             | Alvo específico para penetração absoluta        |
| HUD / UI                      | `damage_final`                            | Leitura             | Exibição de números de dano flutuantes          |
| HUD / UI                      | `damage_reduction_pct`                    | Leitura             | Exibição de resistência na tela de status       |

---

## 10. Checklist de Implementação

- [x] Documento ENG-MATEMATICA-COMBATE.md criado no diretório de sistemas
- [x] Constante `ARMOR_MITIGATION_CONSTANT_K = 150.0` calibrada para Níveis 1–50
- [x] Constante `MIN_DAMAGE_FRACTION = 0.05` (floor de 5%) definida
- [x] Constante `FRATURA_FRENESI_MULTIPLIER = 1.30` documentada
- [x] Constante `FRICTION_ARMOR_IGNORE_FRAC = 0.40` para EQP-ARM-022
- [x] Constante `VEREDICT_ESTAFA_COST = 40` para EQP-ARM-051
- [ ] Implementar `calculate_mitigated_damage` com Etapas 1–7
- [ ] Implementar validação de entrada (DMG-ERR-001, DMG-ERR-002)
- [ ] Implementar cálculo de defesa efetiva com ordenação de penetrações (FRICTION → FLAT → ABSOLUTE)
- [ ] Implementar fórmula hiperbólica `K / (K + defense_effective)`
- [ ] Implementar floor de dano mínimo (5%)
- [ ] Implementar aplicação do multiplicador FRATURA_FRENESI (1.30x)
- [ ] Implementar clamps de segurança (BOUNDS-010 a BOUNDS-012, DMG-ERR-003 a DMG-ERR-005)
- [ ] Implementar `activate_veredict_fuse` com consumo de estafa e verificação MON-ERR-047
- [ ] Implementar `sort_penetration_sources` para ordenação correta das penetrações
- [ ] Escrever testes unitários para todos os 6 casos de teste numéricos (Seção 7)
- [ ] Escrever teste de borda: raw_damage = 0
- [ ] Escrever teste de borda: defense = 0 (deve retornar damage_multiplier = 1.0)
- [ ] Escrever teste de borda: raw_damage negativo (DMG-ERR-001)
- [ ] Escrever teste de borda: defense negativa (DMG-ERR-002)
- [ ] Escrever teste de borda: múltiplas penetrações FRICTION simultâneas
- [ ] Escrever teste de segurança: overflow de raw_damage > 1e12
- [ ] Escrever teste de regra: FRATURA_FRENESI não acumula com outros modificadores

---

## 11. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                                      |
|--------|------------|------------------------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arquitetura  | Criação do documento — motor matemático de dano (Tópico 3) |

---

## 12. Aprovação

| Papel                    | Nome / Equipe           | Data       | Assinatura |
|--------------------------|-------------------------|------------|------------|
| Arquiteto de Software    | Cline (Lead Engineer)   | 2026-07-11 | —          |
| Revisor Técnico          | —                       | —          | —          |
| Product Owner            | —                       | —          | —          |

---

*Fim do Documento ENG-MATEMATICA-COMBATE*
*Próximo: Tópico 4 — [a definir]*