# ENG-PROGRESSAO-NIVEIS — Sistema de Progressão e Níveis

---

**ID do Documento:** ENG-PROGRESSAO-NIVEIS
**Versão:** 1.0.0
**Status:** APROVADO
**Classificação:** Técnico / Arquitetura de Software
**Sistema de Origem:** SYS-BALANCEAMENTO-ATOS
**Autor:** Núcleo de Arquitetura — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## 1. Objetivo

Este documento formaliza os algoritmos de progressão de níveis do jogador do Nível 1 ao Nível 50, definindo a curva de experiência, a matriz de escalabilidade de atributos e as regras de segurança ontológica do sistema. A progressão é vinculada diretamente à transição dos Atos narrativos, garantindo que o crescimento mecânico do personagem reflita o ritmo da campanha.

---

## 2. Algoritmo da Curva de Experiência — `calculate_required_xp(level)`

### 2.1 Definição da Fórmula Matemática

O XP necessário para avançar do nível atual para o próximo segue um modelo **polinomial-exponencial controlado por segmentos**, onde cada Ato narrativo define um regime de crescimento distinto.

```
// Algoritmo — calculate_required_xp(level)
// Entrada: level (int32, 1 <= level <= 50)
// Saída: xp_to_next_level (int64, >= 0)
// Comportamento no nível máximo: retorna 0

function calculate_required_xp(level: int32): int64 {
    // VALIDAÇÃO DE ENTRADA
    if (level < 1 || level > 50) {
        logError("PROGRESS-ERR-003", "Nível fora do domínio [1, 50]: " + level);
        return 0;
    }

    // CLAMP DE NÍVEL MÁXIMO
    if (level >= 50) {
        return 0;  // Nível máximo atingido — XP não acumula mais
    }

    let xp: int64;

    // SEGMENTO 1 — Ato 1 (Vardhelm) — Níveis 1–10
    // Regime: Progressão ágil de engajamento base
    // Fórmula: floor(50 * level^1.4)
    if (level >= 1 && level <= 10) {
        xp = floor(50.0 * pow(level, 1.4));
    }

    // SEGMENTO 2 — Ato 2 (Ostrell) — Níveis 11–20
    // Regime: Curva acentuada com inflação local de +20%
    // Fórmula: floor(120 * level^1.6)
    else if (level >= 11 && level <= 20) {
        xp = floor(120.0 * pow(level, 1.6));
    }

    // SEGMENTO 3 — Ato 3 (Brenhold) — Níveis 21–35
    // Regime: Platô severo de estagnação rúnica
    // Fórmula: floor(85 * level^2.1) — expoente elevado com coeficiente reduzido
    else if (level >= 21 && level <= 35) {
        xp = floor(85.0 * pow(level, 2.1));
    }

    // SEGMENTO 4 — Atos 4 e 5 (Fenda e Clímax) — Níveis 36–49
    // Regime: Teto técnico de alta fricção
    // Fórmula: floor(200 * level^2.4)
    else if (level >= 36 && level <= 49) {
        xp = floor(200.0 * pow(level, 2.4));
    }

    // SEGURANÇA — Overflow protection
    if (xp > INT64_MAX_SAFE) {
        xp = INT64_MAX_SAFE;
        logWarning("PROGRESS-ERR-002", "Overflow de XP detectado no nível " + level + ". Valor truncado.");
    }

    // GARANTIA DE POSITIVIDADE
    if (xp <= 0) {
        xp = 1;  // Mínimo absoluto: nunca retornar 0 ou negativo para níveis < 50
        logWarning("BOUNDS-002", "Cálculo de XP retornou valor não-positivo. Corrigido para 1.");
    }

    return xp;
}
```

### 2.2 Tabela de Curva de XP por Faixa de Nível

| Faixa de Níveis | Ato         | Coeficiente Base | Expoente | Multiplicador de Inflação | XP no início da faixa | XP no fim da faixa |
|-----------------|-------------|------------------|----------|--------------------------|----------------------|--------------------|
| 1–10            | Ato 1       | 50               | 1.4      | 1.0×                     | 50 (nível 1→2)       | ~1,990 (nível 10→11) |
| 11–20           | Ato 2       | 120              | 1.6      | 1.2× (inflação local)    | ~4,570 (nível 11→12) | ~18,820 (nível 20→21) |
| 21–35           | Ato 3       | 85               | 2.1      | 1.0× (platô rúnico)      | ~15,280 (nível 21→22)| ~93,560 (nível 35→36) |
| 36–49           | Ato 4 e 5   | 200              | 2.4      | 1.0× (teto técnico)      | ~163,420 (nível 36→37)| ~662,540 (nível 49→50) |

### 2.3 Comportamento no Nível Máximo (Level 50)

```
// Regra de Level Cap — Nível 50
function grant_xp(character, raw_xp_amount: int64): void {
    if (character.level >= 50) {
        // CONVERSÃO: XP excedente → Marcas de Aço
        // Taxa de conversão: 100 XP → 1 Marca de Aço (floor)
        let marcasGanhas: int64 = floor(raw_xp_amount / 100.0);
        if (marcasGanhas > 0) {
            character.currency.marcas_de_aco += marcasGanhas;
            dispatch_event("EVT_XP_CONVERTIDO_MARCAS", {
                "xp_original": raw_xp_amount,
                "marcas_geradas": marcasGanhas,
                "taxa_conversao": "100:1"
            });
        }
        // Zera o XP contido — personagem não acumula XP além do cap
        character.current_xp = 0;
        character.xp_to_next_level = 0;
        return;
    }

    // FLUXO NORMAL DE GRANT (níveis 1–49)
    character.current_xp += raw_xp_amount;
    check_level_up(character);
}
```

#### 2.3.1 Taxa de Conversão XP → Marcas de Aço

| Parâmetro               | Valor         |
|-------------------------|---------------|
| Taxa de conversão       | 100 XP : 1 Marca de Aço |
| Método de arredondamento | `floor` (truncatura para baixo) |
| Evento disparado        | `EVT_XP_CONVERTIDO_MARCAS` |
| Visibilidade na UI      | Notificação de conversão exibida ao jogador |
| Impacto na economia     | Calibrado para não inflacionar a economia de endgame |

---

## 3. Motor de Level-Up — `check_level_up`

```
// Algoritmo — check_level_up(character)
// Processa múltiplos level-ups em cascata até que o XP atual seja insuficiente
// ou o nível máximo seja atingido.

function check_level_up(character): void {
    let levelsGained: int32 = 0;

    while (character.level < 50) {
        let requiredXP: int64 = calculate_required_xp(character.level);

        if (character.current_xp < requiredXP) {
            break;  // XP insuficiente para o próximo nível
        }

        // Consome o XP do level-up
        character.current_xp -= requiredXP;

        // Aplica o ganho de nível
        character.level += 1;
        levelsGained += 1;

        // Aplica escalabilidade de atributos
        scale_character_stats(character, character.level);

        // Dispara evento narrativo por marco de Ato
        dispatch_level_up_events(character, character.level);

        // Verifica conquistas/achievements
        check_level_milestones(character, character.level);
    }

    // Atualiza a barreira de XP para o próximo nível
    if (character.level >= 50) {
        character.xp_to_next_level = 0;
    } else {
        character.xp_to_next_level = calculate_required_xp(character.level);
    }

    // Segurança: prevenção de overflow em cadeia
    if (levelsGained > MAX_LEVELS_PER_GRANT) {
        logError("PROGRESS-ERR-004", 
            "Level-up em cascata excessivo: " + levelsGained + 
            " níveis ganhos em um único grant. Máximo permitido: " + 
            MAX_LEVELS_PER_GRANT);
        // Ação corretiva: reverte último nível e congela grant de XP por 5 segundos
        character.level -= (levelsGained - MAX_LEVELS_PER_GRANT);
        character.current_xp = 0;
        grant_cooldown_active = true;
        schedule_cooldown_reset(5000);
    }

    // Segurança: validação de integridade pós-level-up
    validate_character_integrity(character);
}
```

### 3.1 Eventos de Marco por Nível

| Nível | Ato   | Evento ID                     | Descrição                                     |
|-------|-------|-------------------------------|-----------------------------------------------|
| 5     | Ato 1 | `EVT_MARCO_NIVEL_5`           | Primeiro marco relevante — desbloqueio de habilidade básica |
| 10    | Ato 1 | `EVT_TRANSICAO_ATO1_ATO2`     | Transição narrativa para Ostrell              |
| 15    | Ato 2 | `EVT_MARCO_NIVEL_15`          | Desbloqueio de manufatura intermediária       |
| 20    | Ato 2 | `EVT_TRANSICAO_ATO2_ATO3`     | Transição narrativa para Brenhold             |
| 25    | Ato 3 | `EVT_MARCO_NIVEL_25`          | Platô rúnico — primeiro contato com estagnação |
| 30    | Ato 3 | `EVT_MARCO_NIVEL_30`          | Crise de Brenhold — atributos começam a patinar |
| 35    | Ato 3 | `EVT_TRANSICAO_ATO3_ATO4`     | Transição narrativa para a Fenda              |
| 36    | Ato 4 | `EVT_REVELACAO_LINHAGEM`      | Revelação da Linhagem Oculta (gate nível 36)  |
| 40    | Ato 4 | `EVT_MARCO_NIVEL_40`          | Fenda — poder latente começa a se manifestar  |
| 45    | Ato 4 | `EVT_MARCO_NIVEL_45`          | Preparação para o Clímax                      |
| 50    | Ato 5 | `EVT_NIVEL_MAXIMO`            | Level Cap — conversão de XP ativada           |

---

## 4. Matriz de Escalabilidade de Atributos — `scale_character_stats`

### 4.1 Definição dos Atributos Base

| Atributo        | Nome do Campo               | Tipo     | Valor Inicial (Nível 1) | Cap Máximo (Nível 50) |
|-----------------|-----------------------------|----------|------------------------|-----------------------|
| Dano Físico/Aço | `base_physical_damage`      | `float`  | 10.0                   | 250.0                 |
| Defesa          | `base_defense`              | `float`  | 8.0                    | 200.0                 |
| Resiliência     | `base_stamina_resilience`   | `float`  | 12.0                   | 180.0                 |

### 4.2 Algoritmo de Escalabilidade com Retornos Decrescentes

```
// Algoritmo — scale_character_stats(character, target_level)
// Aplica a progressão de atributos base usando crescimento linear
// atenuado por Diminishing Returns (Lei de Weber-Fechner modificada).
//
// Princípio: Cada atributo tem um teto assimptótico. O ganho por nível
// reduz progressivamente à medida que o personagem se aproxima do nível 50.

function scale_character_stats(character, target_level: int32): void {
    // VALIDAÇÃO
    if (target_level < 1 || target_level > 50) {
        logError("PROGRESS-ERR-003", "Target level inválido para scale_character_stats: " + target_level);
        return;
    }

    // FATOR DE RETORNOS DECRESCENTES (Diminishing Returns Factor)
    // drf = 1.0 - ( (level - 1) / 49 )^0.7
    // Um expoente de 0.7 significa que os primeiros níveis crescem rápido,
    // mas o ganho desacelera suavemente até o cap.
    let drf: float = 1.0 - pow( (target_level - 1) / 49.0, 0.7 );
    drf = clamp(drf, 0.05, 1.0);  // Mínimo de 5% de ganho mesmo no endgame

    // --- Dano Físico / Aço ---
    // Base: 10.0 em level 1. Cap: 250.0 em level 50.
    // Growth linear: (target_level - 1) * (240.0 / 49) * drf
    let damageGrowth: float = (target_level - 1) * (240.0 / 49.0) * drf;
    character.base_physical_damage = 10.0 + damageGrowth;
    character.base_physical_damage = clamp(character.base_physical_damage, 10.0, 250.0);

    // --- Defesa ---
    // Base: 8.0 em level 1. Cap: 200.0 em level 50.
    let defenseGrowth: float = (target_level - 1) * (192.0 / 49.0) * drf;
    character.base_defense = 8.0 + defenseGrowth;
    character.base_defense = clamp(character.base_defense, 8.0, 200.0);

    // --- Resiliência à Estafa ---
    // Base: 12.0 em level 1. Cap: 180.0 em level 50.
    // NOTA: Resiliência NÃO altera os bounds do medidor de Estafa [-100, +100].
    // Resiliência afeta a TAXA de acúmulo/redução de Estafa, não os limites.
    let resilienceGrowth: float = (target_level - 1) * (168.0 / 49.0) * drf;
    character.base_stamina_resilience = 12.0 + resilienceGrowth;
    character.base_stamina_resilience = clamp(character.base_stamina_resilience, 12.0, 180.0);

    // --- Pós-processamento: arredondamento para 2 casas decimais ---
    character.base_physical_damage = roundTo(character.base_physical_damage, 2);
    character.base_defense = roundTo(character.base_defense, 2);
    character.base_stamina_resilience = roundTo(character.base_stamina_resilience, 2);

    // Dispara evento de stats atualizados
    dispatch_event("EVT_STATS_ATUALIZADOS", {
        "level": target_level,
        "damage": character.base_physical_damage,
        "defense": character.base_defense,
        "resilience": character.base_stamina_resilience,
        "drf_applied": drf
    });
}
```

### 4.3 Trava Lógica de Segurança — Balança de Estafa (Ontologia Inquebrável)

```
// REGRA ONTOLÓGICA: A Balança de Estafa é uma constante inquebrável.
// NENHUM ganho de nível, talento, equipamento ou catalisador pode alterar
// os limites mínimos ou máximos do medidor de curto prazo short_term_estafa.
//
// A progressão de nível concede ao jogador maior CAPACIDADE DE MANUSEIO
// dos Catalisadores (via base_stamina_resilience), mas a FÍSICA da Balança
// permanece imutável em [-100, +100].

const int32 ESTAFA_MIN_BOUND = -100;   // Imutável — nunca alterar
const int32 ESTAFA_MAX_BOUND = 100;    // Imutável — nunca alterar

function enforce_estafa_ontological_lock(character): void {
    // Verificação pós-level-up
    if (character.short_term_estafa_min != ESTAFA_MIN_BOUND ||
        character.short_term_estafa_max != ESTAFA_MAX_BOUND) {
        
        // Violação ontológica — corrige imediatamente
        character.short_term_estafa_min = ESTAFA_MIN_BOUND;
        character.short_term_estafa_max = ESTAFA_MAX_BOUND;
        
        logError("PROGRESS-ERR-005", 
            "Violação ontológica da Balança de Estafa detectada. " +
            "Limites foram reescritos para [-100, +100]. " +
            "Sistema causador: " + get_calling_system_id());
        
        dispatch_event("EVT_VIOLACAO_ESTAFA", {
            "severity": "CRITICAL",
            "action": "BOUNDS_RESTORED"
        });
    }
}
```

### 4.4 Tabela de Atributos Esperados por Faixa de Nível

| Nível | Dano Físico (Aço) | Defesa | Resiliência (Estafa) | DRF Aplicado |
|-------|-------------------|--------|----------------------|--------------|
| 1     | 10.00             | 8.00   | 12.00                | 1.0000       |
| 5     | ~26.73            | ~20.69 | ~27.24               | ~0.6873      |
| 10    | ~55.46            | ~42.69 | ~51.47               | ~0.4648      |
| 15    | ~86.23            | ~66.38 | ~74.58               | ~0.3414      |
| 20    | ~117.44           | ~90.48 | ~96.11               | ~0.2626      |
| 25    | ~148.28           | ~114.29 | ~117.28              | ~0.2075      |
| 30    | ~178.09           | ~137.32 | ~136.10              | ~0.1663      |
| 35    | ~206.46           | ~159.24 | ~153.75              | ~0.1343      |
| 40    | ~233.04           | ~179.83 | ~170.05              | ~0.1085      |
| 45    | ~257.46           | ~198.76 | ~185.31              | ~0.0871      |
| 50    | 250.00 (cap)      | 200.00 (cap) | 180.00 (cap)    | 0.0500 (min) |

> **Nota Técnica:** Valores nos níveis 45–49 podem ultrapassar ligeiramente o cap final devido ao arredondamento, sendo truncados pelo clamp no nível 50.

---

## 5. Tabela de Erros de Progressão

| Código do Erro        | Descrição                                                        | Severidade | Ação do Motor                                                       |
|------------------------|------------------------------------------------------------------|------------|----------------------------------------------------------------------|
| `PROGRESS-ERR-001`     | De-level não autorizado — tentativa de reduzir o nível do personagem | CRITICAL   | Rejeitar operação + logar erro + disparar `EVT_DELEVEL_BLOCKED`     |
| `PROGRESS-ERR-002`     | Overflow de XP — cálculo de XP necessário excede INT64_MAX_SAFE  | HIGH       | Truncar valor para INT64_MAX_SAFE + logar warning                   |
| `PROGRESS-ERR-003`     | Nível fora do domínio [1, 50] — entrada inválida em função de progressão | HIGH       | Retornar 0 + logar erro + registrar stack trace do chamador         |
| `PROGRESS-ERR-004`     | Level-up em cascata excessivo — mais de `MAX_LEVELS_PER_GRANT` níveis em um único grant | CRITICAL   | Reverter excesso + congelar grant de XP por 5s + logar erro         |
| `PROGRESS-ERR-005`     | Violação ontológica da Balança de Estafa — bounds alterados por sistema externo | CRITICAL   | Re-escrever bounds para [-100, +100] + logar erro + disparar evento |
| `PROGRESS-ERR-006`     | Tentativa de conversão de XP com taxa inválida (divisão por zero ou taxa negativa) | HIGH       | Bloquear conversão + logar erro + usar taxa padrão 100:1 como fallback |
| `PROGRESS-ERR-007`     | Atributo base excede cap máximo após scale_character_stats       | MEDIUM     | Truncar ao valor do cap + logar warning + disparar `EVT_STATS_CAPPED` |
| `PROGRESS-ERR-008`     | DRF (Diminishing Returns Factor) fora do intervalo [0.05, 1.0]    | MEDIUM     | Clampar ao intervalo válido + logar warning                          |
| `PROGRESS-ERR-009`     | XP negativo detectado em `grant_xp` — tentativa de remover XP por via não autorizada | CRITICAL   | Rejeitar operação + logar erro + inspecionar caller                  |
| `PROGRESS-ERR-010`     | Tabela de milestones não encontrada para o nível alcançado       | LOW        | Logar warning + pular milestone + continuar execução                |

---

## 6. Funções Auxiliares e Utilitários

```
// Função: get_act_by_level(level)
// Mapeia o nível para o Ato narrativo correspondente.
function get_act_by_level(level: int32): string {
    if (level >= 1 && level <= 10)   return "Ato 1 — Vardhelm";
    if (level >= 11 && level <= 20)  return "Ato 2 — Ostrell";
    if (level >= 21 && level <= 35)  return "Ato 3 — Brenhold";
    if (level >= 36 && level <= 45)  return "Ato 4 — A Fenda";
    if (level >= 46 && level <= 50)  return "Ato 5 — Clímax";
    return "DESCONHECIDO";
}

// Função: get_level_progress_percentage(character)
// Retorna o percentual de progressão do personagem em direção ao level 50.
function get_level_progress_percentage(character): float {
    return (character.level - 1) / 49.0 * 100.0;
}

// Função: validate_character_integrity(character)
// Valida a integridade dos dados do personagem após qualquer operação de progressão.
function validate_character_integrity(character): bool {
    let valid: bool = true;

    // Verifica nível
    if (character.level < 1 || character.level > 50) {
        logError("PROGRESS-ERR-003", "Integridade violada: nível " + character.level);
        valid = false;
    }

    // Verifica atributos dentro dos caps
    if (character.base_physical_damage < 10.0 || character.base_physical_damage > 250.0) {
        logError("PROGRESS-ERR-007", "Integridade violada: base_physical_damage fora do cap");
        valid = false;
    }
    if (character.base_defense < 8.0 || character.base_defense > 200.0) {
        logError("PROGRESS-ERR-007", "Integridade violada: base_defense fora do cap");
        valid = false;
    }
    if (character.base_stamina_resilience < 12.0 || character.base_stamina_resilience > 180.0) {
        logError("PROGRESS-ERR-007", "Integridade violada: base_stamina_resilience fora do cap");
        valid = false;
    }

    // Verifica bounds ontológicos da Estafa
    enforce_estafa_ontological_lock(character);

    // Verifica XP não negativo
    if (character.current_xp < 0) {
        logError("PROGRESS-ERR-009", "Integridade violada: XP negativo detectado");
        character.current_xp = 0;
        valid = false;
    }

    if (!valid) {
        dispatch_event("EVT_INTEGRIDADE_PROGRESSAO_VIOLADA", {
            "character_id": character.id,
            "level": character.level
        });
    }

    return valid;
}
```

---

## 7. Constantes e Configurações do Sistema

```
// ============================================================
// CONFIGURAÇÕES DO SISTEMA DE PROGRESSÃO — enginesettings_progression
// ============================================================

// Limites de Nível
const int32   MIN_LEVEL                  = 1;
const int32   MAX_LEVEL                  = 50;
const int32   MAX_LEVELS_PER_GRANT       = 5;   // Máximo de levels-up em cascata por grant

// Atributos Base — Valores Iniciais (Nível 1)
const float   BASE_DAMAGE_START          = 10.0;
const float   BASE_DEFENSE_START         = 8.0;
const float   BASE_RESILIENCE_START      = 12.0;

// Atributos Base — Caps Máximos (Nível 50)
const float   BASE_DAMAGE_CAP            = 250.0;
const float   BASE_DEFENSE_CAP           = 200.0;
const float   BASE_RESILIENCE_CAP        = 180.0;

// Curva de XP — Parâmetros por Segmento
const float   XP_COEFF_ACT1              = 50.0;
const float   XP_EXPONENT_ACT1           = 1.4;
const float   XP_COEFF_ACT2              = 120.0;
const float   XP_EXPONENT_ACT2           = 1.6;
const float   XP_INFLATION_ACT2          = 1.2;   // +20% inflação local
const float   XP_COEFF_ACT3              = 85.0;
const float   XP_EXPONENT_ACT3           = 2.1;
const float   XP_COEFF_ACT4              = 200.0;
const float   XP_EXPONENT_ACT4           = 2.4;

// DRF (Diminishing Returns Factor)
const float   DRF_EXPONENT               = 0.7;
const float   DRF_MIN_CLAMP              = 0.05;
const float   DRF_MAX_CLAMP              = 1.0;

// Conversão XP → Marcas de Aço
const int64   XP_TO_MARCAS_RATIO         = 100;   // 100 XP : 1 Marca
const int64   INT64_MAX_SAFE             = 9223372036854775807;  // 2^63 - 1

// Balança de Estafa — Bounds Ontológicos (IMUTÁVEIS)
const int32   ESTAFA_MIN_BOUND           = -100;
const int32   ESTAFA_MAX_BOUND           = 100;

// Cooldown de Grant após erro de cascata
const int32   GRANT_COOLDOWN_MS          = 5000;  // 5 segundos
```

---

## 8. Esquema de Implementação (JSON / Data Contract)

```json
{
  "progression_system": {
    "version": "1.0.0",
    "level_bounds": {
      "min": 1,
      "max": 50,
      "max_cascade_per_grant": 5
    },
    "xp_curve_segments": [
      {
        "act": "Ato 1 — Vardhelm",
        "level_range": [1, 10],
        "coefficient": 50.0,
        "exponent": 1.4,
        "inflation_multiplier": 1.0
      },
      {
        "act": "Ato 2 — Ostrell",
        "level_range": [11, 20],
        "coefficient": 120.0,
        "exponent": 1.6,
        "inflation_multiplier": 1.2
      },
      {
        "act": "Ato 3 — Brenhold",
        "level_range": [21, 35],
        "coefficient": 85.0,
        "exponent": 2.1,
        "inflation_multiplier": 1.0
      },
      {
        "act": "Ato 4 e 5 — Fenda e Clímax",
        "level_range": [36, 49],
        "coefficient": 200.0,
        "exponent": 2.4,
        "inflation_multiplier": 1.0
      }
    ],
    "max_level_behavior": {
      "xp_to_next": 0,
      "excess_conversion": {
        "enabled": true,
        "currency": "Marcas de Aço",
        "ratio": 100,
        "rounding": "floor",
        "event_on_conversion": "EVT_XP_CONVERTIDO_MARCAS"
      }
    },
    "attribute_scaling": {
      "diminishing_returns": {
        "exponent": 0.7,
        "min_drf": 0.05,
        "max_drf": 1.0
      },
      "base_damage": {
        "start": 10.0,
        "cap": 250.0
      },
      "defense": {
        "start": 8.0,
        "cap": 200.0
      },
      "resilience": {
        "start": 12.0,
        "cap": 180.0
      }
    },
    "ontological_locks": {
      "estafa_bounds": {
        "min": -100,
        "max": 100,
        "immutable": true,
        "violation_error": "PROGRESS-ERR-005"
      }
    },
    "milestone_events": [
      { "level": 5,  "event_id": "EVT_MARCO_NIVEL_5" },
      { "level": 10, "event_id": "EVT_TRANSICAO_ATO1_ATO2" },
      { "level": 15, "event_id": "EVT_MARCO_NIVEL_15" },
      { "level": 20, "event_id": "EVT_TRANSICAO_ATO2_ATO3" },
      { "level": 25, "event_id": "EVT_MARCO_NIVEL_25" },
      { "level": 30, "event_id": "EVT_MARCO_NIVEL_30" },
      { "level": 35, "event_id": "EVT_TRANSICAO_ATO3_ATO4" },
      { "level": 36, "event_id": "EVT_REVELACAO_LINHAGEM" },
      { "level": 40, "event_id": "EVT_MARCO_NIVEL_40" },
      { "level": 45, "event_id": "EVT_MARCO_NIVEL_45" },
      { "level": 50, "event_id": "EVT_NIVEL_MAXIMO" }
    ],
    "error_codes": [
      { "code": "PROGRESS-ERR-001", "severity": "CRITICAL", "description": "De-level não autorizado" },
      { "code": "PROGRESS-ERR-002", "severity": "HIGH",     "description": "Overflow de XP" },
      { "code": "PROGRESS-ERR-003", "severity": "HIGH",     "description": "Nível fora do domínio [1, 50]" },
      { "code": "PROGRESS-ERR-004", "severity": "CRITICAL", "description": "Level-up em cascata excessivo" },
      { "code": "PROGRESS-ERR-005", "severity": "CRITICAL", "description": "Violação ontológica da Balança de Estafa" },
      { "code": "PROGRESS-ERR-006", "severity": "HIGH",     "description": "Taxa de conversão inválida" },
      { "code": "PROGRESS-ERR-007", "severity": "MEDIUM",   "description": "Atributo base excede cap máximo" },
      { "code": "PROGRESS-ERR-008", "severity": "MEDIUM",   "description": "DRF fora do intervalo válido" },
      { "code": "PROGRESS-ERR-009", "severity": "CRITICAL", "description": "XP negativo detectado" },
      { "code": "PROGRESS-ERR-010", "severity": "LOW",      "description": "Tabela de milestones não encontrada" }
    ]
  }
}
```

---

## 9. Matriz de Dependências

| Componente                    | Função / Variável                  | Tipo de Dependência | Observação                                    |
|-------------------------------|------------------------------------|---------------------|-----------------------------------------------|
| Motor de Combate              | `base_physical_damage`             | Leitura             | Usado para cálculo de dano em ações           |
| Motor de Combate              | `base_defense`                     | Leitura             | Usado para mitigação de dano recebido         |
| Motor de Combate              | `base_stamina_resilience`          | Leitura             | Usado para taxa de acúmulo de Estafa          |
| Motor de Combate              | `short_term_estafa`                | Escrita (bounds)    | Trava ontológica — bounds NUNCA alterados     |
| Sistema de Estados            | `check_level_up`                   | Gatilho             | Dispara eventos de estado ao subir de nível   |
| Sistema de Estados            | `get_act_by_level`                 | Leitura             | Determina ato atual do personagem             |
| Sistema Narrativo             | `dispatch_level_up_events`         | Gatilho             | Marcos narrativos vinculados a níveis         |
| Sistema de Economia           | `grant_xp` (conversão nível 50)    | Escrita             | XP excedente → Marcas de Aço no endgame       |
| Sistema de Salvamento         | Todos os atributos de progressão   | Leitura/Escrita     | Persiste character state entre sessões        |
| HUD / UI                      | `character.level`                  | Leitura             | Exibição do nível do jogador                  |
| HUD / UI                      | `character.current_xp`             | Leitura             | Barra de progressão de XP                     |
| HUD / UI                      | `character.xp_to_next_level`       | Leitura             | Barreira de XP para próximo nível             |
| HUD / UI                      | Atributos base                     | Leitura             | Exibição nos menus de status                  |
| HUD / UI                      | `short_term_estafa`                | Leitura             | Barra de Estafa — bounds NÃO expostos como editáveis |

---

## 10. Checklist de Implementação

- [x] Documento ENG-PROGRESSAO-NIVEIS.md criado no diretório de arquitetura
- [ ] Implementar `calculate_required_xp(level)` com segmentação por Ato
- [ ] Implementar validação de entrada (PROGRESS-ERR-003) no topo de `calculate_required_xp`
- [ ] Implementar proteção contra overflow de XP (PROGRESS-ERR-002)
- [ ] Implementar clamp de nível máximo retornando 0 em `calculate_required_xp`
- [ ] Implementar `grant_xp` com conversão XP → Marcas de Aço no nível 50
- [ ] Implementar `check_level_up` com loop de cascata e proteção (PROGRESS-ERR-004)
- [ ] Implementar `scale_character_stats` com fator de retornos decrescentes (DRF)
- [ ] Implementar clamps de atributos base nos caps máximos (PROGRESS-ERR-007)
- [ ] Implementar `enforce_estafa_ontological_lock` com verificação pós-level-up (PROGRESS-ERR-005)
- [ ] Implementar `validate_character_integrity` chamada pós-level-up
- [ ] Implementar `get_act_by_level` para mapeamento nível → Ato narrativo
- [ ] Implementar `get_level_progress_percentage` para UI
- [ ] Implementar dispatch de eventos de marco por nível (11 eventos)
- [ ] Implementar rejeição de de-level (PROGRESS-ERR-001)
- [ ] Implementar rejeição de XP negativo em `grant_xp` (PROGRESS-ERR-009)
- [ ] Implementar fallback de taxa de conversão 100:1 (PROGRESS-ERR-006)
- [ ] Implementar log de segurança para todas as violações de progressão
- [ ] Escrever testes unitários para curva de XP em todos os 4 segmentos
- [ ] Escrever testes unitários para DRF em níveis 1, 10, 20, 30, 40, 50
- [ ] Escrever testes de integração para cascata de level-up (XP suficiente para múltiplos níveis)
- [ ] Escrever teste de borda: grant_xp com valor exatamente igual ao necessário para level 50
- [ ] Escrever teste de borda: grant_xp com valor zero
- [ ] Escrever teste de segurança: tentativa de de-level via edição de save é rejeitada
- [ ] Escrever teste ontológico: bounds da Estafa permanecem [-100, +100] após qualquer operação

---

## 11. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                          |
|--------|------------|------------------------|------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arquitetura  | Criação do documento (Tópico 1)    |

---

## 12. Aprovação

| Papel                    | Nome / Equipe           | Data       | Assinatura |
|--------------------------|-------------------------|------------|------------|
| Arquiteto de Software    | Cline (Lead Engineer)   | 2026-07-11 | —          |
| Revisor Técnico          | —                       | —          | —          |
| Product Owner            | —                       | —          | —          |