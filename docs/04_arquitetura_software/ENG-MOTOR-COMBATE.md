# ENG-MOTOR-COMBATE — Motor de Cálculo da Balança de Estafa

---

**ID do Documento:** ENG-MOTOR-COMBATE
**Versão:** 1.0.0
**Status:** APROVADO
**Classificação:** Técnico / Arquitetura de Software / Lógica de Programação
**Sistema de Origem:** SYS-RITMO-COMBATE-001
**Autor:** Núcleo de Arquitetura — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## 1. Objetivo

Este documento estabelece a lógica de programação detalhada e o pseudocódigo do motor de processamento de turnos e combate baseado na **Balança de Estafa** (SYS-RITMO-COMBATE-001). Define três rotinas principais que governam a aplicação de habilidades, o tratamento de estados de colapso (overload) e a lógica de IA inimiga para inimigos do tipo Elite/Chefe.

Todas as rotinas aqui descritas operam sobre as variáveis definidas em **ENG-ESTRUTURA-DADOS.md** e respeitam os contratos de dados, clamps de segurança e regras de encapsulamento lá estabelecidos.

---

## 2. Convenções de Pseudocódigo

| Notação                  | Significado                                              |
|--------------------------|----------------------------------------------------------|
| `//`                     | Comentário de linha — explicação lógica                  |
| `/* ... */`              | Comentário de bloco — documentação de seção              |
| `function nome(args)`    | Declaração de função/rotina                              |
| `TIPO`                   | Tipo de dado (int32, float, bool, string, enum)          |
| `player`                 | Instância do personagem jogador                          |
| `enemy`                  | Instância do inimigo (IA)                                |
| `ability`                | Instância da habilidade sendo utilizada                  |
| `=>`                     | Retorno de função / arrow operator                       |
| `===`                    | Comparação estrita de igualdade                          |
| `!==`                    | Comparação estrita de desigualdade                       |
| `&&` / `\|\|`            | Operadores lógicos E / OU                                |
| `if / else if / else`    | Estrutura condicional                                    |
| `switch / case / break`  | Estrutura de seleção múltipla                            |
| `for / foreach / while`  | Estruturas de repetição                                  |
| `try / catch`            | Tratamento de exceções                                   |
| `throw`                  | Lançamento de erro/exceção                               |
| `dispatch_event(id)`     | Disparo de evento no barramento global do motor          |
| `log_warning(msg)`       | Registro de aviso no log do motor                        |
| `log_error(code, msg)`   | Registro de erro no log do motor                         |
| `clamp(value, min, max)` | Função auxiliar que trunca value ao intervalo [min, max] |

---

## 3. Rotina: `process_ability_delta(player, ability)`

### 3.1 Propósito

Aplicar o deslocamento (delta) de uma habilidade no medidor `short_term_estafa` do jogador, respeitando o Eixo da habilidade (tag de `axis`) e o valor de `delta_m`, e disparando os gatilhos de borda quando os limites forem atingidos.

### 3.2 Contrato de Interface

```
function process_ability_delta(
    player: PlayerInstance,
    ability: AbilityInstance
) -> ProcessResult
```

### 3.3 Estrutura de Dados da Habilidade (Input Contract)

Cada habilidade DEVE expor os seguintes campos para o motor de combate:

```
interface AbilityInstance {
    id: string;                    // Identificador único da habilidade (ex: "HAB_FORJA_01")
    name: string;                  // Nome legível (ex: "Golpe de Forja")
    axis: AxisTag;                 // Tag de Eixo: "PATERNO" | "MATERNO" | "NEUTRO"
    delta_m: int32;                // Valor de deslocamento no medidor de estafa
                                   //   Positivo (+): desloca para o lado PATERNO (Ember)
                                   //   Negativo (-): desloca para o lado MATERNO (Dourado)
                                   //   Zero (0):     não desloca o medidor (NEUTRO)
    cooldown: float;               // Tempo de recarga em segundos
    stamina_cost: int32;           // Custo de estamina (recurso secundário)
}
```

### 3.4 Tag de Eixo — Definição Semântica

| Tag        | Delta_m (sinal) | Efeito no Medidor                          | Afinidade de Linhagem       |
|------------|-----------------|---------------------------------------------|-----------------------------|
| `PATERNO`  | Positivo (+)    | Desloca `short_term_estafa` para + (Ember)  | PATERNO_EMBER               |
| `MATERNO`  | Negativo (-)    | Desloca `short_term_estafa` para - (Dourado)| MATERNO_DOURADO             |
| `NEUTRO`   | Zero (0)        | Não altera `short_term_estafa`              | NEUTRO_ABSOLUTO             |

### 3.5 Pseudocódigo — `process_ability_delta`

```
function process_ability_delta(player, ability) -> ProcessResult {
    /* ============================================================
     *  ETAPA 1: VALIDAÇÃO DE ENTRADA
     *  Verifica se a habilidade é válida e se o jogador pode usá-la
     * ============================================================ */

    // 1.1 Verifica se a habilidade existe e não é nula
    if (ability === null || ability === undefined) {
        log_error("MOTOR-ERR-001", "process_ability_delta recebeu ability nula");
        return {
            success: false,
            error_code: "MOTOR-ERR-001",
            final_estafa: player.short_term_estafa,
            trigger_event: null
        };
    }

    // 1.2 Verifica se o jogador está em estado de ESTAGNACAO_TATICA
    //     e se a habilidade é do eixo MATERNO (bloqueada neste estado)
    if (player.status_effects.contains("ESTAGNACAO_TATICA") && ability.axis === "MATERNO") {
        log_warning("Tentativa de usar habilidade MATERNO durante ESTAGNACAO_TATICA — bloqueada");
        return {
            success: false,
            error_code: "MOTOR-ERR-002",
            final_estafa: player.short_term_estafa,
            trigger_event: null
        };
    }

    /* ============================================================
     *  ETAPA 2: LEITURA DO EIXO E DELTA_M
     *  Extrai os parâmetros da habilidade
     * ============================================================ */

    // 2.1 Lê a tag de Eixo da habilidade
    let axis: AxisTag = ability.axis;   // "PATERNO" | "MATERNO" | "NEUTRO"

    // 2.2 Lê o valor de deslocamento
    let delta_m: int32 = ability.delta_m;

    // 2.3 Validação de consistência: o sinal de delta_m DEVE ser coerente com a tag
    if (!validateAxisDeltaConsistency(axis, delta_m)) {
        log_error("MOTOR-ERR-003",
            "Inconsistência entre axis tag e delta_m: axis=" + axis + ", delta_m=" + delta_m);
        return {
            success: false,
            error_code: "MOTOR-ERR-003",
            final_estafa: player.short_term_estafa,
            trigger_event: null
        };
    }

    /* ============================================================
     *  ETAPA 3: APLICAÇÃO DO DESLOCAMENTO
     *  Soma o delta_m ao medidor de estafa de curto prazo
     * ============================================================ */

    // 3.1 Armazena o valor anterior para logging/depuração
    let previous_estafa: int32 = player.short_term_estafa;

    // 3.2 Aplica o deslocamento
    player.short_term_estafa = player.short_term_estafa + delta_m;

    // 3.3 Log de depuração (apenas em build de desenvolvimento)
    log_debug("process_ability_delta: " + ability.id
        + " | axis=" + axis
        + " | delta_m=" + delta_m
        + " | previous=" + previous_estafa
        + " | new_raw=" + player.short_term_estafa);

    /* ============================================================
     *  ETAPA 4: CLAMP DE SEGURANÇA (BOUNDS SAFETY)
     *  Garante que o valor permaneça dentro de [-100, +100]
     *  Conforme especificado em ENG-ESTRUTURA-DADOS Seção 2.2
     * ============================================================ */

    // 4.1 Aplica clamp — o valor NUNCA pode exceder os limites
    let clamped: boolean = false;
    let trigger_event: string | null = null;

    if (player.short_term_estafa > 100) {
        player.short_term_estafa = 100;
        clamped = true;
        trigger_event = "EVT_FRATURA_FRENESI";
        log_warning("BOUNDS-001: short_term_estafa excedeu limite superior (+100). Truncado.");
    }

    if (player.short_term_estafa < -100) {
        player.short_term_estafa = -100;
        clamped = true;
        trigger_event = "EVT_ESTAGNACAO_TATICA";
        log_warning("BOUNDS-001: short_term_estafa excedeu limite inferior (-100). Truncado.");
    }

    /* ============================================================
     *  ETAPA 5: DISPARO DE EVENTO DE BORDA (TRIGGER)
     *  Se o clamp foi acionado, propaga o evento correspondente
     *  O clamp DEVE ser aplicado ANTES da propagação do evento
     * ============================================================ */

    if (clamped && trigger_event !== null) {
        // 5.1 Dispara o evento no barramento global do motor
        dispatch_event(trigger_event, {
            source: "process_ability_delta",
            ability_id: ability.id,
            previous_value: previous_estafa,
            final_value: player.short_term_estafa,
            timestamp: get_current_timestamp()
        });

        // 5.2 Aciona a rotina de tratamento de estado de colapso
        check_overload_states(player);
    }

    /* ============================================================
     *  ETAPA 6: RETORNO
     *  Retorna o resultado da operação para o chamador
     * ============================================================ */

    return {
        success: true,
        error_code: null,
        final_estafa: player.short_term_estafa,
        delta_applied: delta_m,
        previous_estafa: previous_estafa,
        clamped: clamped,
        trigger_event: trigger_event
    };
}
```

### 3.6 Função Auxiliar — `validateAxisDeltaConsistency`

```
function validateAxisDeltaConsistency(axis: AxisTag, delta_m: int32) -> bool {
    switch (axis) {
        case "PATERNO":
            // Habilidades PATERNO DEVEM ter delta_m > 0
            return delta_m > 0;
        case "MATERNO":
            // Habilidades MATERNO DEVEM ter delta_m < 0
            return delta_m < 0;
        case "NEUTRO":
            // Habilidades NEUTRO DEVEM ter delta_m === 0
            return delta_m === 0;
        default:
            // Tag de eixo desconhecida — erro de configuração
            return false;
    }
}
```

### 3.7 Diagrama de Fluxo (Texto)

```
[Início]
    |
    v
[Valida entrada: ability != null && player != null]
    |
    +--(inválido)--> [Retorna erro MOTOR-ERR-001]
    |
    +--(válido)
          |
          v
[Verifica ESTAGNACAO_TATICA + MATERNO?]
    |
    +--(sim)--> [Bloqueia: retorna erro MOTOR-ERR-002]
    |
    +--(não)
          |
          v
[Lê axis tag e delta_m da ability]
    |
    v
[Valida consistência axis <-> delta_m]
    |
    +--(inconsistente)--> [Retorna erro MOTOR-ERR-003]
    |
    +--(consistente)
          |
          v
[Aplica delta_m: short_term_estafa += delta_m]
    |
    v
[Aplica clamp de segurança [-100, +100]]
    |
    v
[Clamp foi acionado?]
    |
    +--(sim)--> [Dispara trigger event + check_overload_states()]
    |
    +--(não)
          |
          v
[Retorna ProcessResult com sucesso]
```

---

## 4. Rotina: `check_overload_states(player)`

### 4.1 Propósito

Avaliar o estado atual do medidor `short_term_estafa` do jogador e aplicar ou remover os estados de colapso (overload) conforme os limites forem atingidos ou abandonados.

### 4.2 Contrato de Interface

```
function check_overload_states(
    player: PlayerInstance
) -> OverloadResult
```

### 4.3 Estados de Colapso — Definição

#### 4.3.1 FRATURA_FRENESI (Colapso Ofensivo — PATERNO)

| Campo                        | Valor                                          |
|------------------------------|------------------------------------------------|
| **ID do Estado**             | `FRATURA_FRENESI`                              |
| **Condição de ativação**     | `short_term_estafa >= 100`                     |
| **Condição de desativação**  | `short_term_estafa < 100` (saiu do estado)     |
| **Duração mínima**           | 5.0 segundos (não pode ser removido antes)     |
| **Modificador — dano recebido** | `damage_received_multiplier = 1.30`         |
| **Efeito secundário**        | Personagem perde controle parcial: animação de frenesi, inputs de movimento direcional são substituídos por investida para frente |
| **Prioridade de execução**   | Crítica — DEVE ser processado no mesmo frame   |
| **Re-armamento**             | Só re-dispara após sair completamente do estado |

#### 4.3.2 ESTAGNACAO_TATICA (Colapso Defensivo — MATERNO)

| Campo                        | Valor                                          |
|------------------------------|------------------------------------------------|
| **ID do Estado**             | `ESTAGNACAO_TATICA`                            |
| **Condição de ativação**     | `short_term_estafa <= -100`                    |
| **Condição de desativação**  | `short_term_estafa > -100` (saiu do estado)    |
| **Duração mínima**           | 5.0 segundos (não pode ser removido antes)     |
| **Modificador — velocidade** | `movement_speed_multiplier = 0.50`             |
| **Bloqueio de habilidades**  | Habilidades com tag `MATERNO` são bloqueadas   |
| **Congelamento da barra**    | O medidor `short_term_estafa` não pode ser alterado enquanto o estado estiver ativo (nenhum delta_m é aplicado) |
| **Efeito secundário**        | Personagem entra em paralisia tática: animação de hesitação, câmera treme levemente |
| **Prioridade de execução**   | Crítica — DEVE ser processado no mesmo frame   |
| **Re-armamento**             | Só re-dispara após sair completamente do estado |

### 4.4 Pseudocódigo — `check_overload_states`

```
function check_overload_states(player) -> OverloadResult {
    /* ============================================================
     *  ETAPA 1: AVALIAÇÃO DO ESTADO ATUAL
     *  Lê o valor atual do medidor de estafa
     * ============================================================ */

    let current_estafa: int32 = player.short_term_estafa;
    let overload_activated: bool = false;
    let overload_deactivated: bool = false;
    let active_state: string | null = null;

    /* ============================================================
     *  ETAPA 2: CHECAGEM DE COLAPSO OFENSIVO — FRATURA_FRENESI
     *  Ativado quando short_term_estafa >= 100
     * ============================================================ */

    if (current_estafa >= 100) {
        // 2.1 Verifica se o jogador já está no estado FRATURA_FRENESI
        if (!player.status_effects.contains("FRATURA_FRENESI")) {
            // 2.2 Aplica o estado de colapso ofensivo
            apply_status_effect(player, {
                id: "FRATURA_FRENESI",
                duration: 5.0,                          // 5 segundos de duração mínima
                modifiers: {
                    damage_received_multiplier: 1.30     // Recebe 30% mais dano
                },
                flags: {
                    blocks_movement_input: false,        // Não bloqueia movimento
                    overrides_movement_direction: true,  // Substitui direção por investida
                    blocks_ability_axis: null,           // Não bloqueia eixos específicos
                    freezes_estafa_bar: false            // Não congela a barra
                },
                on_apply: function() {
                    // Dispara animação de frenesi
                    play_animation(player, "ANIM_FRENESI_ACTIVATE");
                    // Notifica a UI
                    dispatch_event("EVT_UI_STATUS_APPLIED", {
                        status_id: "FRATURA_FRENESI",
                        duration: 5.0
                    });
                },
                on_tick: function(delta_time: float) {
                    // A cada frame, aplica o modificador de dano recebido
                    // (implementado pelo sistema de dano ao calcular incoming damage)
                },
                on_expire: function() {
                    // Dispara animação de saída do estado
                    play_animation(player, "ANIM_FRENESI_EXPIRE");
                    dispatch_event("EVT_UI_STATUS_EXPIRED", {
                        status_id: "FRATURA_FRENESI"
                    });
                }
            });

            overload_activated = true;
            active_state = "FRATURA_FRENESI";

            log_debug("check_overload_states: FRATURA_FRENESI ativado para " + player.id);
        } else {
            // Já está no estado — apenas renova o timer se necessário
            // (comportamento opcional: renovar ou ignorar)
            active_state = "FRATURA_FRENESI (já ativo)";
        }
    }

    /* ============================================================
     *  ETAPA 3: CHECAGEM DE COLAPSO DEFENSIVO — ESTAGNACAO_TATICA
     *  Ativado quando short_term_estafa <= -100
     *  NOTA: ELSE IF — os dois estados são mutuamente exclusivos
     * ============================================================ */

    else if (current_estafa <= -100) {
        // 3.1 Verifica se o jogador já está no estado ESTAGNACAO_TATICA
        if (!player.status_effects.contains("ESTAGNACAO_TATICA")) {
            // 3.2 Aplica o estado de colapso defensivo
            apply_status_effect(player, {
                id: "ESTAGNACAO_TATICA",
                duration: 5.0,                          // 5 segundos de duração mínima
                modifiers: {
                    movement_speed_multiplier: 0.50      // Velocidade reduzida em 50%
                },
                flags: {
                    blocks_movement_input: false,        // Não bloqueia movimento
                    overrides_movement_direction: false, // Não substitui direção
                    blocks_ability_axis: "MATERNO",      // Bloqueia habilidades MATERNO
                    freezes_estafa_bar: true             // Congela a barra de estafa
                },
                on_apply: function() {
                    // Congela o medidor — nenhum delta_m pode ser aplicado
                    player.estafa_frozen = true;

                    // Dispara animação de estagnação
                    play_animation(player, "ANIM_ESTAGNACAO_ACTIVATE");

                    // Notifica a UI
                    dispatch_event("EVT_UI_STATUS_APPLIED", {
                        status_id: "ESTAGNACAO_TATICA",
                        duration: 5.0
                    });
                },
                on_tick: function(delta_time: float) {
                    // A cada frame, garante que a barra permanece congelada
                    // e que habilidades MATERNO são bloqueadas
                },
                on_expire: function() {
                    // Descongela o medidor
                    player.estafa_frozen = false;

                    // Dispara animação de saída do estado
                    play_animation(player, "ANIM_ESTAGNACAO_EXPIRE");

                    dispatch_event("EVT_UI_STATUS_EXPIRED", {
                        status_id: "ESTAGNACAO_TATICA"
                    });
                }
            });

            overload_activated = true;
            active_state = "ESTAGNACAO_TATICA";

            log_debug("check_overload_states: ESTAGNACAO_TATICA ativado para " + player.id);
        } else {
            active_state = "ESTAGNACAO_TATICA (já ativo)";
        }
    }

    /* ============================================================
     *  ETAPA 4: CHECAGEM DE SAÍDA DE ESTADO
     *  Se o jogador estava em um estado de colapso mas o medidor
     *  já não está mais no limite, inicia a desativação
     * ============================================================ */

    else {
        // 4.1 Verifica se o jogador está em FRATURA_FRENESI mas saiu do limite
        if (player.status_effects.contains("FRATURA_FRENESI")) {
            // Inicia a contagem regressiva para remoção do estado
            // (se a duração mínima de 5s já passou, remove imediatamente)
            if (get_status_remaining_duration(player, "FRATURA_FRENESI") <= 0) {
                remove_status_effect(player, "FRATURA_FRENESI");
                overload_deactivated = true;
                log_debug("check_overload_states: FRATURA_FRENESI desativado para " + player.id);
            }
        }

        // 4.2 Verifica se o jogador está em ESTAGNACAO_TATICA mas saiu do limite
        if (player.status_effects.contains("ESTAGNACAO_TATICA")) {
            if (get_status_remaining_duration(player, "ESTAGNACAO_TATICA") <= 0) {
                remove_status_effect(player, "ESTAGNACAO_TATICA");
                overload_deactivated = true;
                log_debug("check_overload_states: ESTAGNACAO_TATICA desativado para " + player.id);
            }
        }
    }

    /* ============================================================
     *  ETAPA 5: RETORNO
     * ============================================================ */

    return {
        checked: true,
        current_estafa: current_estafa,
        overload_activated: overload_activated,
        overload_deactivated: overload_deactivated,
        active_state: active_state
    };
}
```

### 4.5 Regras de Mutabilidade dos Estados

```
/* ============================================================
 * REGRA: MUTUALIDADE EXCLUSIVA
 * FRATURA_FRENESI e ESTAGNACAO_TATICA NUNCA podem estar
 * ativos simultaneamente no mesmo combatente.
 *
 * Implementação: a estrutura if/else if na Etapa 2/3 garante
 * que apenas UM dos blocos de ativação seja executado por frame.
 * ============================================================ */

/* ============================================================
 * REGRA: DURAÇÃO MÍNIMA INVULNERÁVEL
 * Ambos os estados têm duração mínima de 5.0 segundos.
 * Mesmo que o medidor saia da zona de colapso antes disso,
 * o estado NÃO pode ser removido até que os 5.0s expirem.
 *
 * Exceção: se o combatente morrer, os estados são removidos
 * imediatamente (ver rotina de morte).
 * ============================================================ */

/* ============================================================
 * REGRA: RE-ARMAMENTO
 * Após a remoção completa de um estado de colapso, o trigger
 * só pode re-disparar quando o medidor sair E retornar à zona
 * de colapso novamente.
 *
 * Isso evita "flickering" (entrar e sair do estado múltiplas
 * vezes em rápida sucessão).
 * ============================================================ */
```

---

## 5. Rotina: `apply_enemy_fracture(enemy)`

### 5.1 Propósito

Gerenciar a quebra do medidor de estafa de inimigos do tipo Elite ou Chefe ("Massa Abafadora"), aplicando a restrição de tempo útil do jogo base. Quando o medidor de estafa de um inimigo Elite/Chefe quebra, a janela de vulnerabilidade útil (`useful_vulnerability_window`) é reduzida de 5.0s nominais para 4.0s, e o primeiro 1.0s é consumido obrigatoriamente pela animação `ANIM_EJECTION_CHUMBO`.

### 5.2 Contrato de Interface

```
function apply_enemy_fracture(
    enemy: EnemyInstance
) -> FractureResult
```

### 5.3 Classificação de Inimigos

| Tipo        | Tag `enemy_type` | Comportamento na Fratura                          |
|-------------|------------------|----------------------------------------------------|
| Normal      | `NORMAL`         | Fratura padrão — janela de 5.0s, sem animação de ejeção |
| Elite       | `ELITE`          | Fratura com restrição — animação `ANIM_EJECTION_CHUMBO` obrigatória, janela reduzida para 4.0s |
| Chefe       | `BOSS`           | Fratura com restrição — animação `ANIM_EJECTION_CHUMBO` obrigatória, janela reduzida para 4.0s |
| Lendário    | `LEGENDARY`      | Fratura com restrição — animação `ANIM_EJECTION_CHUMBO` obrigatória, janela reduzida para 4.0s |

### 5.4 Pseudocódigo — `apply_enemy_fracture`

```
function apply_enemy_fracture(enemy) -> FractureResult {
    /* ============================================================
     *  ETAPA 1: VALIDAÇÃO DE ENTRADA
     * ============================================================ */

    if (enemy === null || enemy === undefined) {
        log_error("MOTOR-ERR-010", "apply_enemy_fracture recebeu enemy nulo");
        return {
            success: false,
            error_code: "MOTOR-ERR-010",
            fracture_applied: false,
            vulnerability_window: 0.0
        };
    }

    /* ============================================================
     *  ETAPA 2: VERIFICAÇÃO DO TIPO DE INIMIGO
     *  Apenas Elite, Boss e Legendary têm a restrição de tempo
     * ============================================================ */

    let is_restricted_type: bool = (
        enemy.enemy_type === "ELITE" ||
        enemy.enemy_type === "BOSS" ||
        enemy.enemy_type === "LEGENDARY"
    );

    /* ============================================================
     *  ETAPA 3: DEFINIÇÃO DA JANELA DE VULNERABILIDADE
     * ============================================================ */

    let nominal_window: float = 5.0;       // Janela nominal padrão (segundos)
    let useful_window: float;              // Janela útil efetiva (segundos)
    let ejection_animation_duration: float = 0.0;  // Duração da animação de ejeção

    if (is_restricted_type) {
        /* --------------------------------------------------------
         * 3.1 INIMIGO RESTRITO (ELITE / BOSS / LEGENDARY)
         *
         *  - O primeiro 1.0 segundo é consumido pela animação
         *    ANIM_EJECTION_CHUMBO (o jogador não pode agir)
         *  - A janela de vulnerabilidade útil é de 4.0 segundos
         *  - A janela nominal total é de 5.0 segundos
         *    (1.0s animação + 4.0s útil)
         * -------------------------------------------------------- */

        useful_window = 4.0;                          // Janela útil reduzida
        ejection_animation_duration = 1.0;             // Animação obrigatória de 1.0s

        log_debug("apply_enemy_fracture: inimigo restrito (" + enemy.enemy_type
            + ") — useful_window=" + useful_window
            + "s, ejection_animation=" + ejection_animation_duration + "s");

    } else {
        /* --------------------------------------------------------
         * 3.2 INIMIGO NORMAL
         *
         *  - Sem animação de ejeção
         *  - Janela de vulnerabilidade útil = janela nominal = 5.0s
         * -------------------------------------------------------- */

        useful_window = nominal_window;                // 5.0s — sem redução
        ejection_animation_duration = 0.0;             // Sem animação de ejeção

        log_debug("apply_enemy_fracture: inimigo normal — useful_window="
            + useful_window + "s");
    }

    /* ============================================================
     *  ETAPA 4: EXECUÇÃO DA FRATURA
     * ============================================================ */

    // 4.1 Marca o inimigo como fraturado
    enemy.is_fractured = true;
    enemy.fracture_timestamp = get_current_timestamp();

    // 4.2 Define a janela de vulnerabilidade no inimigo
    enemy.vulnerability_window = useful_window;
    enemy.vulnerability_window_elapsed = 0.0;

    // 4.3 Se for restrito, dispara a animação de ejeção
    if (is_restricted_type && ejection_animation_duration > 0.0) {
        // 4.3.1 Bloqueia a entrada do jogador durante a animação de ejeção
        lock_player_input(true, ejection_animation_duration);

        // 4.3.2 Dispara a animação ANIM_EJECTION_CHUMBO no inimigo
        play_animation(enemy, "ANIM_EJECTION_CHUMBO", {
            duration: ejection_animation_duration,     // 1.0 segundo
            on_start: function() {
                // Notifica a UI sobre a ejeção
                dispatch_event("EVT_UI_EJECTION_CHUMBO_START", {
                    enemy_id: enemy.id,
                    enemy_name: enemy.name,
                    duration: ejection_animation_duration
                });

                // Aplica um pequeno "screen shake" para impacto visual
                apply_screen_shake(0.3, 0.5);  // intensidade 0.3, duração 0.5s
            },
            on_complete: function() {
                // Libera a entrada do jogador
                lock_player_input(false, 0.0);

                // Notifica a UI que a janela de vulnerabilidade começou
                dispatch_event("EVT_UI_VULNERABILITY_WINDOW_OPEN", {
                    enemy_id: enemy.id,
                    window_duration: useful_window
                });

                // Dispara som de abertura de janela de vulnerabilidade
                play_sound("SFX_VULNERABILITY_OPEN");
            }
        });

        // 4.3.3 Registra o consumo do tempo de animação
        enemy.vulnerability_window_elapsed = ejection_animation_duration;

        log_debug("apply_enemy_fracture: ANIM_EJECTION_CHUMBO disparada para "
            + enemy.id + " — duração=" + ejection_animation_duration + "s");
    }

    // 4.4 Dispara o evento global de fratura
    dispatch_event("EVT_ENEMY_FRACTURE", {
        enemy_id: enemy.id,
        enemy_type: enemy.enemy_type,
        useful_vulnerability_window: useful_window,
        ejection_animation_played: is_restricted_type
    });

    /* ============================================================
     *  ETAPA 5: TIMER DA JANELA DE VULNERABILIDADE
     *  Inicia a contagem regressiva da janela útil
     * ============================================================ */

    start_timer({
        id: "VULNERABILITY_WINDOW_" + enemy.id,
        duration: useful_window,
        on_tick: function(delta_time: float) {
            enemy.vulnerability_window_elapsed += delta_time;
        },
        on_complete: function() {
            // Final da janela de vulnerabilidade
            enemy.is_fractured = false;
            enemy.vulnerability_window = 0.0;
            enemy.vulnerability_window_elapsed = 0.0;

            // Notifica a UI
            dispatch_event("EVT_UI_VULNERABILITY_WINDOW_CLOSE", {
                enemy_id: enemy.id
            });

            // Dispara som de fechamento
            play_sound("SFX_VULNERABILITY_CLOSE");

            log_debug("apply_enemy_fracture: janela de vulnerabilidade encerrada para "
                + enemy.id);
        }
    });

    /* ============================================================
     *  ETAPA 6: RETORNO
     * ============================================================ */

    return {
        success: true,
        error_code: null,
        fracture_applied: true,
        enemy_type: enemy.enemy_type,
        is_restricted: is_restricted_type,
        nominal_window: nominal_window,
        useful_vulnerability_window: useful_window,
        ejection_animation_duration: ejection_animation_duration,
        vulnerability_remaining: useful_window
    };
}
```

### 5.5 Diagrama de Fluxo — Fratura de Elite/Chefe

```
[Início — short_term_estafa do inimigo atinge +100 ou -100]
    |
    v
[Verifica tipo do inimigo]
    |
    +--(NORMAL)--> [Janela útil = 5.0s | Sem animação de ejeção]
    |                   |
    |                   v
    |              [Inicia timer de vulnerabilidade: 5.0s]
    |
    +--(ELITE / BOSS / LEGENDARY)
          |
          v
    [CONSOME 1.0s — ANIM_EJECTION_CHUMBO]
          |
          |-- Bloqueia input do jogador
          |-- Tela treme (screen shake 0.3/0.5s)
          |-- UI notifica ejeção
          |
          v
    [LIBERA 4.0s — useful_vulnerability_window]
          |
          |-- Libera input do jogador
          |-- UI notifica janela de vulnerabilidade
          |-- Som de abertura
          |
          v
    [Inicia timer de vulnerabilidade: 4.0s]
          |
          v
    [Timer expira → inimigo sai do estado de fratura]
```

### 5.6 Regras de Negócio — Fratura de Elite/Chefe

```
/* ============================================================
 * REGRA: TEMPO ÚTIL MÍNIMO
 * A janela de vulnerabilidade útil (useful_vulnerability_window)
 * para inimigos restritos é de EXATAMENTE 4.0 segundos.
 *
 * NENHUM modificador, perk, item ou habilidade do jogador pode
 * aumentar esta janela além de 4.0s para inimigos Elite/Boss.
 * ============================================================ */

/* ============================================================
 * REGRA: ANIMAÇÃO OBRIGATÓRIA
 * A animação ANIM_EJECTION_CHUMBO é OBRIGATÓRIA para inimigos
 * dos tipos ELITE, BOSS e LEGENDARY.
 *
 * O motor DEVE garantir que:
 *   1. A animação seja reproduzida até o fim (1.0s)
 *   2. O input do jogador seja bloqueado durante a animação
 *   3. A janela de vulnerabilidade só comece APÓS a animação
 * ============================================================ */

/* ============================================================
 * REGRA: NÃO ACUMULAÇÃO
 * Se o medidor de estafa do inimigo quebrar novamente enquanto
 * ele já está em estado de fratura, a nova fratura é IGNORADA.
 *
 * O inimigo só pode ser fraturado novamente após sair
 * completamente do estado de fratura anterior.
 * ============================================================ */

/* ============================================================
 * REGRA: INVULNERABILIDADE DURANTE EJEÇÃO
 * Durante a animação ANIM_EJECTION_CHUMBO, o inimigo é
 * invulnerável a dano. O dano só pode ser aplicado durante
 * a janela de vulnerabilidade útil (após a animação).
 * ============================================================ */
```

---

## 6. Integração entre as Rotinas

### 6.1 Ciclo de Combate Completo (Sequência Lógica)

O fluxo abaixo demonstra como as três rotinas se integram em um ciclo de combate típico:

```
1. Jogador seleciona e usa uma habilidade
        |
        v
2. process_ability_delta(player, ability)
   ├── Valida habilidade
   ├── Verifica ESTAGNACAO_TATICA (bloqueia MATERNO se ativo)
   ├── Aplica delta_m no short_term_estafa do jogador
   ├── Aplica clamp de segurança
   └── Se clamp acionado → dispara trigger event
        |
        v
3. check_overload_states(player)
   ├── Se short_term_estafa >= 100 → FRATURA_FRENESI (5s, dano +30%)
   ├── Se short_term_estafa <= -100 → ESTAGNACAO_TATICA (5s, velocidade -50%, bloqueia MATERNO)
   └── Se saiu do limite → inicia desativação do estado
        |
        v
4. IA do inimigo processa sua ação
        |
        v
5. Se habilidade inimiga causar estafa no inimigo:
   process_ability_delta(enemy, enemy_ability)
        |
        v
6. Se short_term_estafa do inimigo atingir limite:
   apply_enemy_fracture(enemy)
   ├── Se NORMAL → janela de 5.0s
   └── Se ELITE/BOSS/LEGENDARY → ANIM_EJECTION_CHUMBO (1.0s) + janela de 4.0s
        |
        v
7. Jogador ataca durante a janela de vulnerabilidade
        |
        v
8. Ciclo se repete até o fim do combate
```

### 6.2 Matriz de Dependências entre Rotinas

| Rotina                          | Depende de                          | Fornece para                        |
|---------------------------------|-------------------------------------|--------------------------------------|
| `process_ability_delta`         | ENG-ESTRUTURA-DADOS (variáveis)     | `check_overload_states` (trigger)    |
| `check_overload_states`         | `process_ability_delta` (evento)    | Sistema de Estados (status effects)  |
| `apply_enemy_fracture`          | ENG-ESTRUTURA-DADOS (variáveis)     | Sistema de IA / Sistema de Dano      |
| Sistema de Dano                 | `apply_enemy_fracture` (janela)     | —                                    |
| Sistema de Animação             | `apply_enemy_fracture` (ejeção)     | —                                    |
| UI / HUD                        | Todas as rotinas (eventos)          | —                                    |

---

## 7. Tabela de Códigos de Erro do Motor

| Código          | Descrição                                                       | Rotina de Origem            | Ação do Motor                                      |
|-----------------|-----------------------------------------------------------------|-----------------------------|----------------------------------------------------|
| `MOTOR-ERR-001` | `process_ability_delta` recebeu ability nula                    | `process_ability_delta`     | Retorna `success: false`, não altera estado         |
| `MOTOR-ERR-002` | Tentativa de usar habilidade MATERNO durante ESTAGNACAO_TATICA  | `process_ability_delta`     | Bloqueia a ação, retorna erro ao chamador           |
| `MOTOR-ERR-003` | Inconsistência entre axis tag e delta_m na habilidade           | `process_ability_delta`     | Loga erro de configuração, não aplica delta         |
| `MOTOR-ERR-010` | `apply_enemy_fracture` recebeu enemy nulo                       | `apply_enemy_fracture`      | Retorna `success: false`, não aplica fratura        |
| `BOUNDS-001`    | Tentativa de setar `short_term_estafa` fora dos limites [-100, +100] | `process_ability_delta` | Trunca ao valor limite + loga warning + dispara trigger |

---

## 8. Checklist de Implementação

- [ ] Rotina `process_ability_delta` implementada com validação de entrada (MOTOR-ERR-001)
- [ ] Bloqueio de habilidades MATERNO durante ESTAGNACAO_TATICA (MOTOR-ERR-002)
- [ ] Validação de consistência axis <-> delta_m (MOTOR-ERR-003)
- [ ] Aplicação de delta_m no `short_term_estafa`
- [ ] Clamp de segurança [-100, +100] com truncamento (BOUNDS-001)
- [ ] Disparo de trigger event no clamp (`EVT_FRATURA_FRENESI` / `EVT_ESTAGNACAO_TATICA`)
- [ ] Rotina `check_overload_states` implementada
- [ ] Estado FRATURA_FRENESI: duração 5s, `damage_received_multiplier = 1.30`
- [ ] Estado ESTAGNACAO_TATICA: duração 5s, `movement_speed_multiplier = 0.50`, bloqueio MATERNO, congelamento da barra
- [ ] Mutabilidade exclusiva entre FRATURA_FRENESI e ESTAGNACAO_TATICA
- [ ] Duração mínima invulnerável de 5.0s para ambos os estados
- [ ] Re-armamento seguro (sem flickering)
- [ ] Rotina `apply_enemy_fracture` implementada
- [ ] Diferenciação entre inimigo NORMAL e restrito (ELITE/BOSS/LEGENDARY)
- [ ] Animação `ANIM_EJECTION_CHUMBO` obrigatória de 1.0s para inimigos restritos
- [ ] Bloqueio de input do jogador durante a animação de ejeção
- [ ] Janela de vulnerabilidade útil de 4.0s para inimigos restritos
- [ ] Janela de vulnerabilidade de 5.0s para inimigos normais
- [ ] Invulnerabilidade do inimigo durante a animação de ejeção
- [ ] Não acumulação de fraturas (enquanto já fraturado)
- [ ] Todos os códigos de erro documentados (MOTOR-ERR-001 a MOTOR-ERR-010, BOUNDS-001)

---

## 9. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                                      |
|--------|------------|------------------------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arquitetura  | Criação do documento — lógica do motor de combate (Tópico 1) |

---

## 10. Aprovação

| Papel                    | Nome / Equipe           | Data       | Assinatura |
|--------------------------|-------------------------|------------|------------|
| Arquiteto de Software    | Cline (Lead Engineer)   | 2026-07-11 | —          |
| Revisor Técnico          | —                       | —          | —          |
| Product Owner            | —                       | —          | —          |

---

*Fim do Documento ENG-MOTOR-COMBATE*
*Próximo: Tópico 2 — Sistema de Progressão e Níveis*