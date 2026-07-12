# ENG-PERSISTENCIA-CAMPANHA — Máquina de Estados da Campanha (Savegame do Veredito Final)

---

**ID do Documento:** ENG-PERSISTENCIA-CAMPANHA
**Versão:** 1.0.0
**Status:** APROVADO
**Classificação:** Técnico / Arquitetura de Software / Persistência
**Sistema de Origem:** EVT-ESCOLHA-FINAL-001
**Autor:** Núcleo de Arquitetura — Projeto Aetheris
**Última Revisão:** 2026-07-11

---

## 1. Objetivo

Este documento formaliza a **máquina de estados de persistência da campanha** responsável por salvar, validar e processar o estado final do jogo base na zona `LOC-VER-003` (Veredito da Balança). Define como o motor deve:

- Registrar a escolha binária de WorldState (`ERA_DO_ACO` | `ESTASE_RUNICA`).
- Avaliar o modificador de Maestria Neutra baseado no inventário do jogador.
- Persistir as variantes de desfecho narrativo no arquivo de savegame.
- Garantir a exclusão binária — impossibilidade de ambas as rotas coexistirem no mesmo bloco de memória de salvamento.

Este documento é o **Tópico 1** da trilha de engenharia de software do Projeto Aetheris, imediatamente posterior à integração do motor de combate (`ENG-MOTOR-COMBATE.md`).

---

## 2. Convenções de Pseudocódigo

Este documento segue as mesmas convenções estabelecidas em `ENG-MOTOR-COMBATE.md` (Seção 2). Adicionalmente:

| Notação                  | Significado                                              |
|--------------------------|----------------------------------------------------------|
| `CampaignSaveBlock`      | Estrutura de dados do bloco de salvamento de campanha    |
| `persist_to_save(block)` | Função que grava o bloco no arquivo de savegame do jogador |
| `verify_save_integrity`  | Função de auditoria que valida a consistência do save    |
| `throw SaveViolation`    | Exceção lançada quando uma regra de persistência é violada |

---

## 3. Estrutura da Máquina de Estados — `CampaignStateManager`

### 3.1 Definição

O `CampaignStateManager` é o singleton de sistema responsável por gerenciar o estado persistente de campanha. Ele é inicializado no momento do carregamento do savegame e finalizado na gravação do bloco de salvamento.

```
/* ============================================================
 * CampaignStateManager — Singleton de Persistência
 *
 * Gerencia as flags globais de sistema que definem o estado
 * do mundo pós-Veredito.
 *
 * NENHUMA outra entidade no motor pode escrever diretamente
 * nos campos WorldState ou campaign_variant.
 * ============================================================ */

class CampaignStateManager {
    // --- Campos Privados ---
    // Acesso exclusivo via getters públicos e método sealCampaignOutcome()

    private _worldState: WorldState | null;         // Estado do mundo — nulo até o Veredito
    private _isNeutroMaestriaActive: bool;           // Flag do Modificador Neutro
    private _campaignVariant: CampaignVariant | null; // Variante textual do desfecho
    private _saveSealed: bool;                        // Trava de segurança — true após o Veredito ser finalizado
    private _campaignTitle: string | null;            // Título honorífico do jogador

    // --- Construtor ---
    constructor() {
        this._worldState = null;
        this._isNeutroMaestriaActive = false;
        this._campaignVariant = null;
        this._saveSealed = false;
        this._campaignTitle = null;
    }

    // --- Getters Públicos (Somente Leitura) ---

    public get worldState(): WorldState | null {
        return this._worldState;
    }

    public get isNeutroMaestriaActive(): bool {
        return this._isNeutroMaestriaActive;
    }

    public get campaignVariant(): CampaignVariant | null {
        return this._campaignVariant;
    }

    public get saveSealed(): bool {
        return this._saveSealed;
    }

    public get campaignTitle(): string | null {
        return this._campaignTitle;
    }
}
```

### 3.2 Enum `WorldState`

O enum `WorldState` é a representação tipada e imutável do estado final do mundo. Seus valores são **exaustivos e mutuamente exclusivos** — não pode haver um terceiro valor, e nenhum dos dois pode ser válido simultaneamente.

```
/* ============================================================
 * WorldState — Enum do Estado Final do Mundo
 *
 * Valores permitidos (EXAUSTIVOS):
 *   ERA_DO_ACO      = Rota Kael (Industrialização, destruição da malha)
 *   ESTASE_RUNICA   = Rota Elyra (Preservação, cura da malha)
 *
 * RESTRIÇÃO:
 *   NENHUM outro valor pode ser adicionado a este enum.
 *   NENHUM código cliente pode setar um valor inválido.
 * ============================================================ */

enum WorldState: string {
    ERA_DO_ACO    = "ERA_DO_ACO",      // Rota Kael
    ESTASE_RUNICA = "ESTASE_RUNICA"     // Rota Elyra
}
```

### 3.3 Enum `CampaignVariant`

As variantes textuais do desfecho, determinadas pela combinação de `WorldState` e `is_neutro_maestria_active`.

```
/* ============================================================
 * CampaignVariant — Variantes de Desfecho
 *
 * Mapeamento 1:1 entre (WorldState, isNeutroMaestriaActive)
 * e a variante de save.
 * ============================================================ */

enum CampaignVariant: string {
    //--- Rota A (Kael) ---
    ACO_PURO              = "O Aço Puro",            // ERA_DO_ACO + neutro=false
    ACO_CONTROLADO        = "O Aço Controlado",      // ERA_DO_ACO + neutro=true

    //--- Rota B (Elyra) ---
    RUNAS_ESTASE          = "A Runastase Pura",      // ESTASE_RUNICA + neutro=false
    RUNAS_HARMONICA       = "A Runastase Harmônica"  // ESTASE_RUNICA + neutro=true
}
```

### 3.4 Estrutura `CampaignSaveBlock`

Bloco de dados serializável que é persistido no arquivo de savegame do jogador. Este bloco é a **única fonte da verdade** para o estado da campanha.

```
/* ============================================================
 * CampaignSaveBlock — Bloco de Salvamento da Campanha
 *
 * Estrutura plana para serialização JSON no savegame.
 * Todos os campos são obrigatórios quando o Veredito foi
 * processado (saveSealed === true).
 *
 * Se saveSealed === false, os campos worldState e
 * campaignVariant DEVEM ser null.
 * ============================================================ */

interface CampaignSaveBlock {
    // Metadados do save
    saveVersion:     string;            // Versão do schema de save (ex: "1.0.0")
    saveTimestamp:   string;            // ISO 8601 timestamp do momento da gravação
    sourceZone:      string;            // Zona de origem: "LOC-VER-003"
    saveSealed:      bool;              // Trava de segurança

    // Estado do mundo
    worldState:           WorldState | null;      // "ERA_DO_ACO" | "ESTASE_RUNICA" | null
    isNeutroMaestriaActive: bool;                 // true se a build Neutra Máxima foi detectada
    campaignVariant:      CampaignVariant | null; // Variante textual do desfecho
    campaignTitle:        string | null;          // Título do jogador

    // Hash de integridade
    integrityHash:  string;             // SHA-256 do bloco para detecção de adulteração
}
```

---

## 4. Injeção do Modificador de Maestria Neutra — `evaluateVeredictModifiers(player)`

### 4.1 Propósito

Esta função é invocada **imediatamente antes** do salvamento do Veredito (no Beat 5 de `EVT-ESCOLHA-FINAL-001`). Ela varre as variáveis de inventário do jogador para determinar se a condição de Maestria Neutra Máxima é satisfeita.

### 4.2 Contrato de Interface

```
function evaluateVeredictModifiers(
    player: PlayerInstance
) -> VeredictModifierResult
```

### 4.3 Condição de Ativação

A Maestria Neutra é ativada se, **e somente se**, ambas as condições forem verdadeiras no momento da chamada:

| Condição | ID do Item | Nome do Item | Tipo | Estado Exigido |
|----------|-----------|--------------|------|----------------|
| **A** | `SKL-NEU-050` | Ancoragem do Ponteiro Absoluto | Habilidade Ativa (Skill) | Desbloqueada **E** equipada no slot ativo |
| **B** | `REL-ONT-003` | Chassi Estático Primordial | Relíquia Ontológica | Equipada **E** ativa (não em cooldown ou inerte) |

### 4.4 Pseudocódigo — `evaluateVeredictModifiers`

```
function evaluateVeredictModifiers(player: PlayerInstance) -> VeredictModifierResult {
    /* ============================================================
     *  ETAPA 1: VALIDAÇÃO DE ENTRADA
     * ============================================================ */

    if (player === null || player === undefined) {
        log_error("PERSIST-ERR-001", "evaluateVeredictModifiers recebeu player nulo");
        return {
            success: false,
            error_code: "PERSIST-ERR-001",
            isNeutroMaestriaActive: false,
            checkedItems: []
        };
    }

    /* ============================================================
     *  ETAPA 2: LEITURA DO INVENTÁRIO DO JOGADOR
     *
     *  Verifica a presença e o estado de:
     *    a) SKL-NEU-050 (Ancoragem do Ponteiro Absoluto)
     *    b) REL-ONT-003 (Chassi Estático Primordial)
     * ============================================================ */

    // 2.1 Busca a habilidade SKL-NEU-050 no grimório/lista de habilidades do jogador
    let skillNEU050: SkillInstance | null = player.skills.find(
        skill => skill.id === "SKL-NEU-050"
    );

    // 2.2 Busca a relíquia REL-ONT-003 no inventário de relíquias do jogador
    let relicONT003: RelicInstance | null = player.relics.find(
        relic => relic.id === "REL-ONT-003"
    );

    /* ============================================================
     *  ETAPA 3: AVALIAÇÃO DAS CONDIÇÕES
     *
     *  Ambas as condições DEVEM ser verdadeiras simultaneamente.
     *  Se uma delas falhar, o modificador neutro NÃO é ativado.
     * ============================================================ */

    // 3.1 Verifica condição A: SKL-NEU-050 equipada e desbloqueada
    let conditionA: bool = (
        skillNEU050 !== null &&
        skillNEU050.isUnlocked === true &&
        skillNEU050.isEquipped === true
    );

    // 3.2 Verifica condição B: REL-ONT-003 equipada e ativa
    let conditionB: bool = (
        relicONT003 !== null &&
        relicONT003.isEquipped === true &&
        relicONT003.isActive === true
    );

    // 3.3 Ambas as condições DEVEM ser verdadeiras
    let isNeutroMaestriaActive: bool = (conditionA === true && conditionB === true);

    /* ============================================================
     *  ETAPA 4: LOG DE DEPURAÇÃO
     * ============================================================ */

    log_info("evaluateVeredictModifiers: " +
        "SKL-NEU-050-present=" + (skillNEU050 !== null) +
        " | SKL-NEU-050-equipped=" + (skillNEU050 !== null ? skillNEU050.isEquipped : false) +
        " | REL-ONT-003-present=" + (relicONT003 !== null) +
        " | REL-ONT-003-active=" + (relicONT003 !== null ? relicONT003.isActive : false) +
        " | isNeutroMaestriaActive=" + isNeutroMaestriaActive
    );

    /* ============================================================
     *  ETAPA 5: NOTIFICAÇÃO AO SISTEMA NARRATIVO
     *
     *  Se a Maestria Neutra foi detectada, dispara um evento
     *  para o módulo narrativo ajustar os diálogos e cenas
     *  do Modificador de Tom Neutro.
     * ============================================================ */

    if (isNeutroMaestriaActive === true) {
        dispatch_event("EVT_NEUTRO_MAESTRIA_ACTIVATED", {
            player_id: player.id,
            source: "evaluateVeredictModifiers",
            timestamp: get_current_timestamp()
        });
    }

    /* ============================================================
     *  ETAPA 6: RETORNO
     * ============================================================ */

    return {
        success: true,
        error_code: null,
        isNeutroMaestriaActive: isNeutroMaestriaActive,
        checkedItems: [
            { id: "SKL-NEU-050", present: skillNEU050 !== null, conditionMet: conditionA },
            { id: "REL-ONT-003", present: relicONT003 !== null, conditionMet: conditionB }
        ]
    };
}
```

### 4.5 Função Auxiliar — `validateModifierResultConsistency`

```
/* ============================================================
 * validateModifierResultConsistency
 *
 * Garante que o resultado do modificador seja consistente
 * com o inventário real do jogador.
 *
 * PREVENÇÃO DE FRAUDE:
 * Impede que um save editado manualmente ative o modificador
 * sem que os itens reais estejam presentes no inventário.
 * ============================================================ */

function validateModifierResultConsistency(
    player: PlayerInstance,
    result: VeredictModifierResult
) -> bool {
    // Re-executa a verificação de forma independente
    let skillNEU050 = player.skills.some(s => s.id === "SKL-NEU-050" && s.isEquipped);
    let relicONT003 = player.relics.some(r => r.id === "REL-ONT-003" && r.isActive);

    let expectedNeutro: bool = (skillNEU050 && relicONT003);

    if (result.isNeutroMaestriaActive !== expectedNeutro) {
        log_error("PERSIST-ERR-005",
            "Inconsistência no resultado do modificador neutro. " +
            "Esperado=" + expectedNeutro + ", Obtido=" + result.isNeutroMaestriaActive
        );
        return false;
    }

    return true;
}
```

---

## 5. Processamento do Salvamento — `sealCampaignOutcome()`

### 5.1 Propósito

Método principal do `CampaignStateManager` que orquestra todo o fluxo de salvamento do Veredito. Este método:

1. Recebe a escolha do jogador (`WorldState`).
2. Executa `evaluateVeredictModifiers(player)`.
3. Determina a variante de desfecho.
4. Constrói o `CampaignSaveBlock`.
5. Aplica as travas de segurança de exclusão binária.
6. Persiste o bloco no arquivo de savegame.

### 5.2 Contrato de Interface

```
function sealCampaignOutcome(
    player: PlayerInstance,
    chosenWorldState: WorldState,
    stateManager: CampaignStateManager
) -> SealResult
```

### 5.3 Pseudocódigo — `sealCampaignOutcome`

```
function sealCampaignOutcome(
    player: PlayerInstance,
    chosenWorldState: WorldState,
    stateManager: CampaignStateManager
) -> SealResult {
    /* ============================================================
     *  ETAPA 1: PRÉ-VALIDAÇÕES DE SEGURANÇA
     * ============================================================ */

    // 1.1 Validação de entrada
    if (player === null || player === undefined) {
        log_error("PERSIST-ERR-001", "sealCampaignOutcome recebeu player nulo");
        return { success: false, error_code: "PERSIST-ERR-001" };
    }

    // 1.2 Validação do WorldState — apenas valores permitidos
    if (chosenWorldState !== WorldState.ERA_DO_ACO &&
        chosenWorldState !== WorldState.ESTASE_RUNICA) {
        log_error("PERSIST-ERR-002",
            "WorldState inválido: " + chosenWorldState +
            " — apenas ERA_DO_ACO e ESTASE_RUNICA são permitidos");
        return { success: false, error_code: "PERSIST-ERR-002" };
    }

    // 1.3 TRAVA DE EXCLUSÃO BINÁRIA (Verificação Primária)
    // Se o save já está selado, NÃO permite re-selar
    if (stateManager._saveSealed === true) {
        log_error("PERSIST-ERR-003",
            "Tentativa de re-selar um save já finalizado. " +
            "O CampaignStateManager já possui um WorldState registrado.");
        return { success: false, error_code: "PERSIST-ERR-003" };
    }

    /* ============================================================
     *  ETAPA 2: AVALIAÇÃO DO MODIFICADOR DE MAESTRIA NEUTRA
     * ============================================================ */

    // 2.1 Executa a verificação de inventário
    let modifierResult: VeredictModifierResult = evaluateVeredictModifiers(player);

    if (modifierResult.success === false) {
        log_error("PERSIST-ERR-004",
            "Falha na avaliação do modificador neutro: " + modifierResult.error_code);
        return { success: false, error_code: "PERSIST-ERR-004" };
    }

    // 2.2 Valida a consistência do resultado (prevenção de fraude)
    if (validateModifierResultConsistency(player, modifierResult) === false) {
        log_error("PERSIST-ERR-005",
            "Inconsistência detectada no resultado do modificador neutro");
        return { success: false, error_code: "PERSIST-ERR-005" };
    }

    let isNeutro: bool = modifierResult.isNeutroMaestriaActive;

    /* ============================================================
     *  ETAPA 3: DETERMINAÇÃO DA VARIANTE DE DESFECHO
     *
     *  Mapeamento determinístico baseado em:
     *    (WorldState, isNeutroMaestriaActive) -> CampaignVariant
     * ============================================================ */

    let variant: CampaignVariant;
    let title: string;

    if (chosenWorldState === WorldState.ERA_DO_ACO) {
        // --- ROTA A (Kael) ---
        if (isNeutro === true) {
            variant = CampaignVariant.ACO_CONTROLADO;    // "O Aço Controlado"
            title = "Ponteiro Absoluto";
        } else {
            variant = CampaignVariant.ACO_PURO;          // "O Aço Puro"
            title = "Ferreiro do Veredito";
        }
    } else {
        // --- ROTA B (Elyra) ---
        if (isNeutro === true) {
            variant = CampaignVariant.RUNAS_HARMONICA;   // "A Runastase Harmônica"
            title = "Ponteiro Absoluto";
        } else {
            variant = CampaignVariant.RUNAS_ESTASE;      // "A Runastase Pura"
            title = "Guardião do Equilíbrio";
        }
    }

    log_info("sealCampaignOutcome: " +
        "WorldState=" + chosenWorldState +
        " | isNeutro=" + isNeutro +
        " | variant=" + variant +
        " | title=" + title
    );

    /* ============================================================
     *  ETAPA 4: CONSTRUÇÃO DO BLOCO DE SALVAMENTO
     * ============================================================ */

    let saveBlock: CampaignSaveBlock = {
        saveVersion:         "1.0.0",
        saveTimestamp:       get_current_iso_timestamp(),
        sourceZone:          "LOC-VER-003",
        saveSealed:          true,
        worldState:          chosenWorldState,
        isNeutroMaestriaActive: isNeutro,
        campaignVariant:     variant,
        campaignTitle:       title,
        integrityHash:       ""  // Será preenchido na Etapa 6
    };

    // 4.1 Calcula o hash de integridade (exclui o próprio campo integrityHash)
    saveBlock.integrityHash = calculateIntegrityHash(saveBlock);

    /* ============================================================
     *  ETAPA 5: TRAVAS DE SEGURANÇA — GARANTIA DE EXCLUSÃO BINÁRIA
     *
     *  NESTE PONTO, ANTES DE GRAVAR:
     *
     *  1. VERIFICA se já existe um save anterior com WorldState
     *     diferente do escolhido (save corrompido).
     *
     *  2. TRAVA o stateManager para impedir qualquer gravação
     *     subsequente (saveSealed = true).
     *
     *  3. Verifica a integridade do hash.
     * ============================================================ */

    // 5.1 Verificação de save pré-existente com conflito de rota
    let existingSave: CampaignSaveBlock | null = loadExistingCampaignSave();

    if (existingSave !== null && existingSave.saveSealed === true) {
        if (existingSave.worldState !== chosenWorldState) {
            // Conflito detectado: save existente tem WorldState DIFERENTE
            log_error("PERSIST-ERR-006",
                "CONFLITO DE ROTA DETECTADO: Save existente contém WorldState=" +
                existingSave.worldState + ", mas a nova escolha é " + chosenWorldState +
                ". A campanha não pode ter dois WorldStates distintos no mesmo bloco."
            );

            // NÃO grava o novo save — retorna erro
            return {
                success: false,
                error_code: "PERSIST-ERR-006",
                existingWorldState: existingSave.worldState,
                attemptedWorldState: chosenWorldState
            };
        }

        // Save já selado com o MESMO WorldState — rejeita duplicação
        log_error("PERSIST-ERR-003",
            "Save já selado com WorldState=" + existingSave.worldState +
            ". Tentativa de re-selar ignorada."
        );
        return { success: false, error_code: "PERSIST-ERR-003" };
    }

    // 5.2 TRAVA FINAL — marca o stateManager como selado
    //     NENHUMA outra chamada a sealCampaignOutcome será aceita
    //     após esta linha (verifica na Etapa 1.3)
    stateManager._saveSealed = true;
    stateManager._worldState = chosenWorldState;
    stateManager._isNeutroMaestriaActive = isNeutro;
    stateManager._campaignVariant = variant;
    stateManager._campaignTitle = title;

    /* ============================================================
     *  ETAPA 6: PERSISTÊNCIA NO ARQUIVO DE SAVEGAME
     * ============================================================ */

    // 6.1 Serializa o bloco para o formato de save
    let serializedBlock: string = serializeToJson(saveBlock);

    // 6.2 Grava no arquivo de savegame do jogador
    let writeResult: WriteResult = persistToSaveFile(
        player.saveSlot,
        "campaign_state",
        serializedBlock
    );

    if (writeResult.success === false) {
        log_error("PERSIST-ERR-007",
            "Falha na gravação do save: " + writeResult.error_message
        );

        // Reverte a trava interna (rollback)
        stateManager._saveSealed = false;
        stateManager._worldState = null;
        stateManager._isNeutroMaestriaActive = false;
        stateManager._campaignVariant = null;
        stateManager._campaignTitle = null;

        return { success: false, error_code: "PERSIST-ERR-007" };
    }

    /* ============================================================
     *  ETAPA 7: PÓS-PERSISTÊNCIA — LOG E NOTIFICAÇÃO
     * ============================================================ */

    // 7.1 Registra o salvamento bem-sucedido
    log_info("Campanha finalizada com sucesso. " +
        "WorldState=" + chosenWorldState +
        " | Variant=" + variant +
        " | Title=" + title +
        " | Hash=" + saveBlock.integrityHash
    );

    // 7.2 Dispara evento global de campanha finalizada
    dispatch_event("EVT_CAMPAIGN_SEALED", {
        worldState: chosenWorldState,
        campaignVariant: variant,
        campaignTitle: title,
        isNeutroMaestria: isNeutro,
        saveTimestamp: saveBlock.saveTimestamp
    });

    /* ============================================================
     *  ETAPA 8: RETORNO
     * ============================================================ */

    return {
        success: true,
        error_code: null,
        worldState: chosenWorldState,
        isNeutroMaestriaActive: isNeutro,
        campaignVariant: variant,
        campaignTitle: title,
        saveTimestamp: saveBlock.saveTimestamp,
        integrityHash: saveBlock.integrityHash
    };
}
```

---

## 6. Travas de Segurança de Persistência — Garantia de Escolha Excludente Binária

### 6.1 Regra Fundamental

**O bloco de memória de save `campaign_state` NUNCA pode conter dois WorldStates distintos.** A campanha é uma linha do tempo única e irreversível.

### 6.2 Mecanismos de Proteção

O sistema implementa **três camadas** de proteção:

#### Camada 1 — Trava de Selamento (Save Seal)

```
/* ============================================================
 * REGRA: SAVE SEAL (Trava de Selamento)
 *
 * Após a primeira chamada bem-sucedida a sealCampaignOutcome(),
 * o campo _saveSealed do CampaignStateManager é setado para true.
 *
 * QUALQUER tentativa subsequente de chamar sealCampaignOutcome()
 * é rejeitada na Etapa 1.3 com erro PERSIST-ERR-003.
 *
 * Efeito: Apenas UM Veredito pode ser processado por campanha.
 * ============================================================ */

if (stateManager._saveSealed === true) {
    throw SaveViolation("PERSIST-ERR-003: Save já selado");
}
```

#### Camada 2 — Verificação de Conflito de Rota

```
/* ============================================================
 * REGRA: CONFLICT CHECK (Verificação de Conflito)
 *
 * Antes de gravar, o motor carrega o bloco de save existente
 * (se houver) e compara o WorldState.
 *
 * Se o WorldState existente for DIFERENTE do novo, o motor
 * RECUSA gravar e retorna PERSIST-ERR-006.
 *
 * Isto impede que um save corrompido ou editado manualmente
 * contenha dois finais diferentes no mesmo bloco.
 * ============================================================ */

if (existingSave.worldState !== chosenWorldState) {
    throw SaveViolation("PERSIST-ERR-006: Conflito de rota detectado");
}
```

#### Camada 3 — Hash de Integridade (Anti-Adulteração)

```
/* ============================================================
 * REGRA: INTEGRITY HASH (Hash de Integridade)
 *
 * O bloco CampaignSaveBlock contém um campo integrityHash
 * calculado como SHA-256 de todos os outros campos concatenados.
 *
 * Ao carregar um save, o motor DEVE recalcular o hash e
 * compará-lo com o valor armazenado.
 *
 * Se os hashes não coincidirem, o save é considerado
 * CORROMPIDO ou ADULTERADO, e o motor DEVE:
 *   1. Rejeitar o carregamento.
 *   2. Logar o erro PERSIST-ERR-008.
 *   3. Notificar o jogador sobre a corrupção do save.
 * ============================================================ */

function verifySaveIntegrity(block: CampaignSaveBlock) -> bool {
    let storedHash: string = block.integrityHash;

    // Cria uma cópia do bloco sem o hash para recalcular
    let blockForHash: CampaignSaveBlock = { ...block };
    blockForHash.integrityHash = "";

    let recalculatedHash: string = calculateIntegrityHash(blockForHash);

    if (storedHash !== recalculatedHash) {
        log_error("PERSIST-ERR-008",
            "Hash de integridade não corresponde. " +
            "Armazenado=" + storedHash + ", Recalculado=" + recalculatedHash +
            " — Save pode estar corrompido ou adulterado."
        );
        return false;
    }

    return true;
}
```

### 6.3 Diagrama de Fluxo — Exclusão Binária

```
[Início — Jogador escolhe Rota A ou B no Beat 5]
    |
    v
[sealCampaignOutcome(player, chosenWorldState, stateManager)]
    |
    v
[ETAPA 1: PRÉ-VALIDAÇÕES]
    |
    +--(player nulo)-->     [PERSIST-ERR-001: Abortar]
    +--(WorldState inválido)--> [PERSIST-ERR-002: Abortar]
    +--(_saveSealed == true)--> [PERSIST-ERR-003: Abortar — Save já selado]
    |
    v
[ETAPA 2: evaluateVeredictModifiers(player)]
    |
    +--(falha)-->   [PERSIST-ERR-004/005: Abortar]
    |
    v
[ETAPA 3: Determinar CampaignVariant]
    |
    v
[ETAPA 5.1: Carregar save existente]
    |
    +--(save existe && selado && worldState DIFERENTE)
    |       |
    |       v
    |   [PERSIST-ERR-006: CONFLITO DE ROTA — Abortar]
    |
    +--(save existe && selado && worldState IGUAL)
    |       |
    |       v
    |   [PERSIST-ERR-003: Save já selado — Abortar]
    |
    +--(save inexistente || não selado)
            |
            v
    [ETAPA 5.2: TRAVAR stateManager]
            |
            v
    [ETAPA 6: Persistir no savegame]
            |
            +--(falha na escrita)--> [Rollback + PERSIST-ERR-007]
            |
            v
    [SUCESSO: Save selado com WorldState único]
            |
            v
    [NENHUMA outra chamada a sealCampaignOutcome será aceita]
```

---

## 7. Matriz de Estados — Mapeamento Completo

### 7.1 Tabela de Desfechos

| WorldState | `isNeutroMaestriaActive` | `CampaignVariant` | Título do Jogador | Tom Narrativo |
|------------|-------------------------|-------------------|-------------------|---------------|
| `ERA_DO_ACO` | `false` | "O Aço Puro" | Ferreiro do Veredito | Triunfo trágico (Elyra perdida) |
| `ERA_DO_ACO` | `true` | "O Aço Controlado" | Ponteiro Absoluto | Bittersweet (Elyra preservada como memória) |
| `ESTASE_RUNICA` | `false` | "A Runastase Pura" | Guardião do Equilíbrio | Sacrifício silencioso (Kael perdido) |
| `ESTASE_RUNICA` | `true` | "A Runastase Harmônica" | Ponteiro Absoluto | Bittersweet (Kael preservado como relíquia) |

### 7.2 Correspondência com EVT-ESCOLHA-FINAL-001

A tabela acima mapeia diretamente para a **Tabela de Estados Finais** definida em `EVT-ESCOLHA-FINAL-001.md` (Seção: Tabela de Estados Finais). As variantes "O Aço Controlado" e "A Runastase Harmônica" são os nomes técnicos de persistência para os desfechos com Modificador Neutro ativo.

---

## 8. Tabela de Códigos de Erro de Persistência

| Código | Descrição | Rotina de Origem | Ação do Motor |
|--------|-----------|-------------------|---------------|
| `PERSIST-ERR-001` | `evaluateVeredictModifiers` ou `sealCampaignOutcome` recebeu player nulo | `evaluateVeredictModifiers` / `sealCampaignOutcome` | Retorna `success: false`, não altera estado |
| `PERSIST-ERR-002` | WorldState inválido (diferente de ERA_DO_ACO ou ESTASE_RUNICA) | `sealCampaignOutcome` | Rejeita o valor, retorna erro |
| `PERSIST-ERR-003` | Tentativa de re-selar um save já finalizado | `sealCampaignOutcome` | Rejeita a operação, preserva o save existente |
| `PERSIST-ERR-004` | Falha na avaliação do modificador neutro | `sealCampaignOutcome` | Não prossegue com o selamento |
| `PERSIST-ERR-005` | Inconsistência no resultado do modificador neutro (possível fraude/edição) | `sealCampaignOutcome` | Rejeita o salvamento, loga alerta de segurança |
| `PERSIST-ERR-006` | Conflito de rota: save existente com WorldState diferente do novo | `sealCampaignOutcome` | Rejeita gravação, preserva integridade do save |
| `PERSIST-ERR-007` | Falha na gravação física do arquivo de save | `sealCampaignOutcome` | Rollback do stateManager, retorna erro |
| `PERSIST-ERR-008` | Hash de integridade não corresponde ao carregar save | `verifySaveIntegrity` | Rejeita carregamento do save, notifica jogador |

---

## 9. Integração com o Motor de Combate e Estrutura de Dados

### 9.1 Dependências de Documentos

| Documento | Relação | Observação |
|-----------|---------|------------|
| `ENG-ESTRUTURA-DADOS.md` | Base de dados | As variáveis `short_term_estafa` e `latent_lineage_axis` são lidas pelo sistema narrativo, mas não interferem diretamente no selamento da campanha |
| `ENG-MOTOR-COMBATE.md` | Motor de combate | A rotina `process_ability_delta` e `check_overload_states` operam antes do Veredito; o `CampaignStateManager` só é acionado após o combate final |
| `EVT-ESCOLHA-FINAL-001.md` | Script narrativo | Fonte dos valores de WorldState e das condições do Modificador Neutro |
| `MASTER_ID_REGISTRY.md` | Registro de IDs | `SKL-NEU-050` e `REL-ONT-003` devem estar registrados como ATIVOS |

### 9.2 Ciclo de Vida do Salvamento de Campanha

```
[Ato 5 — Combate Final contra Juízo da Balança]
    |
    v
[Motor de Combate: process_ability_delta, check_overload_states, apply_enemy_fracture]
    |
    v (Juízo derrotado)
    |
[EVT-ESCOLHA-FINAL-001: Beat 1 — Prólogo do Confronto]
    |
    v
[ENT-NUCLEO-001: Beats 2-4 — Revelação e Escolha]
    |
    v
[Beat 5 — Processamento da Escolha]
    |
    |-- sealCampaignOutcome(player, chosenWorldState, stateManager)
    |       |
    |       |-- evaluateVeredictModifiers(player)
    |       |-- Determina CampaignVariant
    |       |-- Aplica travas de segurança
    |       |-- Persiste CampaignSaveBlock
    |
    v
[Beat 6 / LOC-VER-003 — Cena Final (Veredito)]
    |
    v
[Créditos]
```

---

## 10. Casos de Borda e Tratamento de Exceções

### 10.1 Jogador morre durante o Beat 5 (antes do salvamento)

Se o jogador morrer ou o jogo for fechado forçadamente entre a escolha e a chamada de `sealCampaignOutcome`, o estado `_saveSealed` permanece `false` e nenhum WorldState é registrado. Ao recarregar, o jogador retorna ao checkpoint anterior ao Beat 5 e pode refazer a escolha.

### 10.2 Falha de escrita do savegame (disco cheio, permissão negada)

O `sealCampaignOutcome` implementa **rollback automático** na Etapa 6: se `persistToSaveFile` falhar, o `CampaignStateManager` reverte `_saveSealed` para `false` e limpa todos os campos de estado. O jogador pode tentar novamente.

### 10.3 Save corrompido com hash inválido (PERSIST-ERR-008)

Ao carregar um save com hash inválido, o motor:
1. Rejeita o carregamento.
2. Exibe mensagem: "O arquivo de salvamento parece estar corrompido ou foi adulterado."
3. Oferece ao jogador: carregar um backup automático (se disponível) ou iniciar uma nova campanha.

### 10.4 Dois saves distintos com WorldState diferentes (contas múltiplas)

A regra de exclusão binária **aplica-se por slot de save**, não por perfil de jogador. Um jogador pode ter:
- Slot 1: `ERA_DO_ACO` (Rota Kael)
- Slot 2: `ESTASE_RUNICA` (Rota Elyra)

Isto é permitido e não viola a regra, desde que cada slot individualmente contenha apenas um WorldState.

---

## 11. Checklist de Implementação

- [ ] Estrutura `CampaignStateManager` implementada com campos privados e getters
- [ ] Enum `WorldState` com valores estritos `ERA_DO_ACO` | `ESTASE_RUNICA`
- [ ] Enum `CampaignVariant` com as 4 variantes de desfecho
- [ ] Interface `CampaignSaveBlock` com todos os campos de persistência
- [ ] `evaluateVeredictModifiers(player)` implementada
- [ ] Verificação de `SKL-NEU-050` (equipada e desbloqueada)
- [ ] Verificação de `REL-ONT-003` (equipada e ativa)
- [ ] Sinalização `is_neutro_maestria_active` injetada corretamente
- [ ] `validateModifierResultConsistency` (prevenção de fraude)
- [ ] `sealCampaignOutcome(player, chosenWorldState, stateManager)` implementada
- [ ] Mapeamento determinístico: (WorldState, isNeutro) -> CampaignVariant
- [ ] Trava de Save Seal (PERSIST-ERR-003 — impedir re-selamento)
- [ ] Verificação de Conflito de Rota (PERSIST-ERR-006 — exclusão binária)
- [ ] Hash de Integridade SHA-256 (PERSIST-ERR-008 — anti-adulteração)
- [ ] Rollback automático em falha de escrita (PERSIST-ERR-007)
- [ ] Evento `EVT_NEUTRO_MAESTRIA_ACTIVATED` disparado no modificador
- [ ] Evento `EVT_CAMPAIGN_SEALED` disparado no selamento
- [ ] Variante "O Aço Controlado" salva quando `ERA_DO_ACO` + `is_neutro_maestria_active == true`
- [ ] Variante "A Runastase Harmônica" salva quando `ESTASE_RUNICA` + `is_neutro_maestria_active == true`
- [ ] Exclusão binária: impossibilidade de ambos WorldStates no mesmo bloco de save
- [ ] Tratamento de caso de borda: morte do jogador antes do salvamento
- [ ] Tratamento de caso de borda: falha de disco/escrita
- [ ] Tratamento de caso de borda: save corrompido (hash inválido)
- [ ] Permissão de rotas diferentes em slots de save distintos

---

## 12. Histórico de Revisão

| Versão | Data       | Autor                  | Descrição                                      |
|--------|------------|------------------------|------------------------------------------------|
| 1.0.0  | 2026-07-11 | Núcleo de Arquitetura  | Criação do documento — persistência da campanha (Tópico 1) |

---

## 13. Aprovação

| Papel                    | Nome / Equipe           | Data       | Assinatura |
|--------------------------|-------------------------|------------|------------|
| Arquiteto de Software    | Cline (Lead Engineer)   | 2026-07-11 | —          |
| Revisor Técnico          | —                       | —          | —          |
| Product Owner            | —                       | —          | —          |

---

*Fim do Documento ENG-PERSISTENCIA-CAMPANHA*
*Próximo: Tópico 2 — Sistema de Progressão e Níveis*