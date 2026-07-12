# ENG-ESTRUTURA-DADOS — Estrutura de Dados do Motor de Combate

---

**ID do Documento:** ENG-ESTRUTURA-DADOS
**Versão:** 1.0.0
**Status:** APROVADO
**Classificação:** Técnico / Arquitetura de Software
**Sistema de Origem:** SYS-RITMO-COMBATE-001
**Autor:** Núcleo de Arquitetura — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## 1. Objetivo

Este documento formaliza as estruturas de dados, regras de encapsulamento e gatilhos de estado relativos ao sistema de ritmo de combate (SYS-RITMO-COMBATE-001). Define como o motor do jogo deve gerenciar as variáveis de curto prazo (Medidor de Estafa) e de longo prazo (Linhagem Oculta), incluindo clamps de segurança, eventos de borda e regras de visibilidade para UI e sistemas de IA inimiga.

---

## 2. Variável de Curto Prazo — Medidor de Estafa

### 2.1 Definição

| Campo                  | Valor                         |
|------------------------|-------------------------------|
| **Nome da variável**   | `short_term_estafa`           |
| **Tipo de dado**       | `int32` (Integer com sinal)   |
| **Valor padrão**       | `0`                           |
| **Clamp mínimo**       | `-100`                        |
| **Clamp máximo**       | `+100`                        |
| **Domínio semântico**  | Medidor de estafa do combatente em tempo real |
| **Sistema de origem**  | SYS-RITMO-COMBATE-001         |
| **Persistência**       | Sessão de combate apenas (não persiste entre salvas) |

### 2.2 Regras de Clamp (Bounds Safety)

Toda operação de leitura/escrita em `short_term_estafa` DEVE obedecer às seguintes regras no motor:

```
// Pseudocódigo — bloco de clamp obrigatório em todo setter
if (short_term_estafa < -100) {
    short_term_estafa = -100;
    dispatch_event("EVT_ESTAGNACAO_TATICA");
}
if (short_term_estafa > 100) {
    short_term_estafa = 100;
    dispatch_event("EVT_FRATURA_FRENESI");
}
```

- O clamp DEVE ser aplicado **antes** de qualquer propagação de evento.
- Nenhuma operação de aumento/diminuição pode exceder os limites — o valor é truncado aos bounds.
- A violação de clamp (ultrapassagem) NÃO DEVE causar overflow ou wrap-around em hipótese alguma.

### 2.3 Gatilhos de Estado Limite (Triggers)

#### 2.3.1 Fratura de Frenesi (Colapso Ofensivo)

| Campo                    | Valor                                          |
|--------------------------|------------------------------------------------|
| **Evento ID**            | `EVT_FRATURA_FRENESI`                          |
| **Condição de disparo**  | `short_term_estafa >= 100` (atingiu ou excedeu o clamp superior) |
| **Efeito no game state** | Personagem entra em estado de Frenesi: dano aumentado, perda de controle parcial |
| **Cooldown do trigger**  | Não re-dispara enquanto personagem estiver no estado. Re-armado ao sair do estado. |
| **Prioridade**           | Crítica — DEVE ser processado no mesmo frame |

#### 2.3.2 Estagnação Tática (Colapso Defensivo)

| Campo                    | Valor                                          |
|--------------------------|------------------------------------------------|
| **Evento ID**            | `EVT_ESTAGNACAO_TATICA`                        |
| **Condição de disparo**  | `short_term_estafa <= -100` (atingiu ou excedeu o clamp inferior) |
| **Efeito no game state** | Personagem entra em estado de Estagnação Tática: redução de ação, paralisia tática |
| **Cooldown do trigger**  | Não re-dispara enquanto personagem estiver no estado. Re-armado ao sair do estado. |
| **Prioridade**           | Crítica — DEVE ser processado no mesmo frame  |

### 2.4 Esquema de Implementação (JSON / Data Contract)

```json
{
  "combat_variables": {
    "short_term_estafa": {
      "type": "int32",
      "default": 0,
      "clamp": {
        "min": -100,
        "max": 100
      },
      "bounds_behavior": "TRUNCATE",
      "triggers": [
        {
          "id": "EVT_FRATURA_FRENESI",
          "condition": "value >= 100",
          "description": "Colapso ofensivo — personagem atinge estado de Frenesi"
        },
        {
          "id": "EVT_ESTAGNACAO_TATICA",
          "condition": "value <= -100",
          "description": "Colapso defensivo — personagem atinge estado de Estagnação Tática"
        }
      ]
    }
  }
}
```

---

## 3. Variável de Longo Prazo — Linhagem Oculta

### 3.1 Definição

| Campo                    | Valor                                |
|--------------------------|--------------------------------------|
| **Nome da variável**     | `latent_lineage_axis`                |
| **Tipo de dado**         | `enum` (String internado)            |
| **Valores possíveis**    | `PATERNO_EMBER`, `MATERNO_DOURADO`, `NEUTRO_ABSOLUTO` |
| **Valor padrão**         | `NEUTRO_ABSOLUTO`                    |
| **Persistência**         | Global — persiste entre sessões, vinculado ao perfil do personagem |
| **Visibilidade padrão**  | `PROTECTED` (encapsulado do escopo público) |
| **Nível mínimo para acesso** | `>= 36` (Ato 4) |

### 3.2 Regra de Encapsulamento e Segurança (MON-ERR-032)

A variável `latent_lineage_axis` DEVE obedecer estritamente às seguintes regras de proteção no código:

#### 3.2.1 Ocultação da UI

- `latent_lineage_axis` NÃO DEVE ser exposta no pool de dados da UI (HUD, menus de status, inventário, tooltips).
- Nenhum componente de front-end pode referenciar esta variável diretamente.
- Qualquer tentativa de serialização para a camada de apresentação DEVE filtrar (remover) este campo.

#### 3.2.2 Ocultação da IA Inimiga (Referência: MON-ERR-032)

- As rotinas de leitura de IA inimiga NÃO PODEM acessar `latent_lineage_axis`.
- O sistema de estado global acessível pelos módulos de IA (`AI_BLACKBOARD`, `AI_SENSOR_POOL`, `AI_TARGET_EVALUATOR`) DEVE excluir esta variável do feed de dados.
- Se uma rotina de IA tentar acessar o campo, o motor DEVE retornar `null` / `NONE` e registrar o erro `MON-ERR-032` no log de segurança.

```
// Pseudocódigo — regra de acesso protegido
function getLatentLineage(character, requestingSystem) {
    if (requestingSystem.type == "AI" || requestingSystem.type == "UI") {
        logSecurityError("MON-ERR-032", 
            "Tentativa de acesso a latent_lineage_axis por sistema não autorizado: " 
            + requestingSystem.id);
        return null;  // NÃO expõe o valor real
    }
    if (character.level < 36) {
        return null;  // Ainda não revelado
    }
    return character.latent_lineage_axis;
}
```

#### 3.2.3 Liberação por Nível (Gate: Level >= 36 — Ato 4)

- O acesso a `latent_lineage_axis` é liberado **exclusivamente** quando o personagem atinge o nível `>= 36` (início do Ato 4).
- Antes deste patamar, qualquer consulta ao campo retorna `null` / `NEUTRO_ABSOLUTO` para sistemas autorizados (ex: módulo narrativo).
- O sistema de checkpoint DEVE verificar o nível do personagem **a cada frame** enquanto em áreas narrativamente relevantes, para disparar a revelação assim que o nível `36` for cruzado.
- A revelação da linhagem DEVE acionar um evento narrativo (`EVT_REVELACAO_LINHAGEM`) ao ser desbloqueada.

### 3.3 Esquema de Implementação (JSON / Data Contract)

```json
{
  "character_variables": {
    "latent_lineage_axis": {
      "type": "enum<string>",
      "values": ["PATERNO_EMBER", "MATERNO_DOURADO", "NEUTRO_ABSOLUTO"],
      "default": "NEUTRO_ABSOLUTO",
      "visibility": "PROTECTED",
      "security": {
        "blacklist_consumers": ["UI_DATA_POOL", "AI_BLACKBOARD", "AI_SENSOR_POOL"],
        "unlock_level": 36,
        "unlock_act": "Ato 4",
        "error_code_on_violation": "MON-ERR-032",
        "error_message": "Tentativa de acesso a linhagem oculta por sistema não autorizado antes do desbloqueio narrativo"
      },
      "metadata": {
        "persistence": "global_profile",
        "narrative_weight": "critical",
        "hidden_from_player_until_unlock": true
      }
    }
  }
}
```

---

## 4. Matriz de Dependências

| Componente                   | Variável                | Tipo de Dependência | Observação                           |
|------------------------------|-------------------------|---------------------|--------------------------------------|
| Motor de Combate             | `short_term_estafa`     | Leitura/Escrita     | Atualizado a cada ação/turno         |
| HUD / UI                     | `short_term_estafa`     | Leitura             | Apenas leitura para barra de estafa  |
| Sistema de Estados           | `short_term_estafa`     | Leitura             | Gatilho de eventos de borda          |
| Sistema Narrativo            | `latent_lineage_axis`   | Leitura             | Bloqueado até nível 36               |
| Motor de IA (inimigos)       | `latent_lineage_axis`   | **BLOQUEADO**       | MON-ERR-032 se tentar acessar        |
| Pool de Dados da UI          | `latent_lineage_axis`   | **BLOQUEADO**       | Campo oculto até nível 36            |
| Sistema de Salvamento        | `latent_lineage_axis`   | Escrita             | Persiste na save game do personagem  |

---

## 5. Tratamento de Erros e Logs de Segurança

| Código do Erro  | Descrição                                               | Ação do Motor                              |
|-----------------|---------------------------------------------------------|--------------------------------------------|
| `MON-ERR-032`   | Tentativa de acesso à `latent_lineage_axis` por sistema não autorizado (IA ou UI antes do nível 36) | Logar o erro + retornar `null` ao requisitante |
| `BOUNDS-001`    | Tentativa de setar `short_term_estafa` fora dos limites [-100, 100] via bypass | Truncar ao valor limite + logar warning + disparar trigger |

---

## 6. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                          |
|--------|------------|------------------------|------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arquitetura  | Criação do documento (Tópico 1)    |

---

## 7. Aprovação

| Papel                    | Nome / Equipe           | Data       | Assinatura |
|--------------------------|-------------------------|------------|------------|
| Arquiteto de Software    | Cline (Lead Engineer)   | 2026-07-11 | —          |
| Revisor Técnico          | —                       | —          | —          |
| Product Owner            | —                       | —          | —          |