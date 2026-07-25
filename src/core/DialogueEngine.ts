import { CampaignManager } from './CampaignManager';
import {
    EstafaCalculator,
    EstafaQuadrant,
    EstafaActionType,
} from '../mechanics/EstafaCalculator';

export interface IDialogueChoice {
    text: string;
    targetNodeId?: string; // Muda o caminho do mapa se escolhido
    nextDialogueId: string | null; // Avança a conversa ou encerra (null)
    estafaModifier?: number; // Exito moral que inclina a balança
    consequence?: (campaign: CampaignManager) => { text: string; success: boolean };
}

/**
 * Categoria psicológica de uma resposta de diálogo, usada pela Balança de
 * Estafa para travar opções incompatíveis com a psique atual do líder:
 *   - MATERNAL_EMPATHY:      tom empático/compassivo (travado no extremo Paterno).
 *   - PATERNAL_CALCULATION:  tom frio/insensível/tático (travado no extremo Materno).
 *   - STANDARD:              tom neutro (nunca travado).
 */
export type DialogueActionCategory =
    | 'MATERNAL_EMPATHY'
    | 'PATERNAL_CALCULATION'
    | 'STANDARD';

/**
 * Opção de diálogo rica, integrada à Balança de Estafa.
 * Diferente de IDialogueChoice (legado, indexado), a opção é identificada por
 * `id` e carrega o deslocamento de estafa e a categoria para validação de bloqueio.
 */
export interface IDialogueOption {
    id: string;
    text: string;
    /** Deslocamento aplicado à estafa ao escolher (ex.: -10 Materno, +10 Paterno). */
    estafaShift?: number;
    /** Categoria psicológica para validação de bloqueio via EstafaCalculator. */
    actionCategory?: DialogueActionCategory;
    /** Gate opcional: a opção só é liberada neste quadrante. */
    requiredQuadrant?: EstafaQuadrant;
    /** Próximo nó de diálogo (string avança, null encerra, undefined mantém). */
    nextDialogueId?: string | null;
    /** Redireciona o nó do mapa de campanha, se definido. */
    targetNodeId?: string;
}

/** Opção de diálogo já avaliada contra a estafa atual (para renderização de UI). */
export interface IEvaluatedDialogueOption extends IDialogueOption {
    /** true se a psique atual do líder bloqueia esta resposta. */
    locked: boolean;
    /** Justificativa diegética do bloqueio, quando houver. */
    lockReason?: string;
}

/** Resultado da seleção de uma opção de diálogo integrada à estafa. */
export interface ISelectOptionResult {
    option: IDialogueOption | null;
    /** true se a opção estava travada — nesse caso o shift NÃO é aplicado. */
    locked: boolean;
    lockReason?: string;
    /** Estafa antes da seleção (clampada). */
    previousEstafa: number;
    /** Estafa após aplicar o shift (clampada em [-100, +100]). */
    newEstafa: number;
    /** Próximo nó ativo após a seleção. */
    nextNode: IDialogueNode | null;
}

export interface IDialogueNode {
    id: string;
    speaker: string;
    text: string;
    choices: IDialogueChoice[];
    /** Opções ricas integradas à Estafa (novo modelo; coexiste com `choices`). */
    options?: IDialogueOption[];
}

export class DialogueEngine {
    private dialogueNodes: Map<string, IDialogueNode>;
    private activeDialogue: IDialogueNode | null = null;

    constructor() {
        this.dialogueNodes = new Map<string, IDialogueNode>();
        this.initializeStoryNodes();
    }

    private initializeStoryNodes(): void {
        // Exemplo de encontro narrativo inicial na Fábrica de Brenhold
        this.dialogueNodes.set('brenhold_scavenger_encounter', {
            id: 'brenhold_scavenger_encounter',
            speaker: 'Catador Sombrio',
            text: 'Estes corredores de ferro pertencem à nossa colônia de sucata. Se quiserem passar sem lutar, mostrem que valorizam nosso trabalho... ou paguem o pedágio.',
            choices: [
                {
                    text: '🔧 [Engenharia] Reparar o gerador quebrado deles (Ganha passagem livre)',
                    nextDialogueId: 'scavenger_thankful',
                    estafaModifier: -15, // Inclina para o Materno
                    consequence: (_campaign) => {
                        // Não gasta recurso, usa perícia técnica fictícia
                        return { text: "Você conserta o gerador usando ferramentas básicas. Eles abrem o portão.", success: true };
                    }
                },
                {
                    text: '🪙 Entregar 25 unidades de sucata como suborno',
                    nextDialogueId: 'scavenger_bribed',
                    estafaModifier: 10, // Inclina para o Paterno
                    consequence: (campaign) => {
                        const party = campaign.getPartyState();
                        const paymaster = party[0]; // Primeiro membro paga
                        if (paymaster && paymaster.scrapCount !== undefined && paymaster.scrapCount >= 25) {
                            paymaster.scrapCount -= 25;
                            return { text: "Você entrega a sucata reluzente. O Catador sorri com dentes podres.", success: true };
                        }
                        return { text: "Você não tem sucata suficiente! Eles se irritam.", success: false };
                    }
                }
            ],
            // Novo modelo de opções ricas integradas à Balança de Estafa.
            options: [
                {
                    id: 'opt_repair',
                    text: '🔧 Reparar o gerador quebrado deles (empatia técnica)',
                    estafaShift: -15,
                    actionCategory: 'MATERNAL_EMPATHY',
                    nextDialogueId: 'scavenger_thankful',
                    targetNodeId: 'sector_01_combat',
                },
                {
                    id: 'opt_bribe',
                    text: '🪙 Entregar 25 de sucata como suborno (pragmático)',
                    estafaShift: 10,
                    actionCategory: 'STANDARD',
                    nextDialogueId: 'scavenger_bribed',
                    targetNodeId: 'sector_01_combat',
                },
                {
                    id: 'opt_mercy',
                    text: '💧 Poupar e acolher o catador ferido (compaixão)',
                    estafaShift: -10,
                    actionCategory: 'MATERNAL_EMPATHY',
                    nextDialogueId: 'scavenger_thankful',
                },
                {
                    id: 'opt_threaten',
                    text: '🔩 Ameaçar de morte para forçar passagem (frieza tática)',
                    estafaShift: 15,
                    actionCategory: 'PATERNAL_CALCULATION',
                    nextDialogueId: 'scavenger_bribed',
                },
            ],
        });

        this.dialogueNodes.set('scavenger_thankful', {
            id: 'scavenger_thankful',
            speaker: 'Catador Sombrio',
            text: 'Sua perícia com as engrenagens é impressionante, Humano. Siga em frente. O Pátio de Fundição aguarda.',
            choices: [{ text: 'Continuar jornada...', nextDialogueId: null, targetNodeId: 'sector_01_combat' }]
        });

        this.dialogueNodes.set('scavenger_bribed', {
            id: 'scavenger_bribed',
            speaker: 'Catador Sombrio',
            text: 'Um bom negócio. O ferro vai continuar girando. Pode passar.',
            choices: [{ text: 'Continuar jornada...', nextDialogueId: null, targetNodeId: 'sector_01_combat' }]
        });

        // ── Encontro ramificado: Autômato Preso ──
        this.dialogueNodes.set('trapped_automaton', {
            id: 'trapped_automaton',
            speaker: 'Autômato Preso',
            text: 'Circuitos... presos sob os escombros. Unidade requisita assistência — ou desativação misericordiosa.',
            choices: [],
            options: [
                {
                    id: 'auto_free',
                    text: '🔧 Libertar o autômato dos escombros (compaixão)',
                    estafaShift: -12,
                    actionCategory: 'MATERNAL_EMPATHY',
                    nextDialogueId: 'automaton_freed',
                },
                {
                    id: 'auto_salvage',
                    text: '🔩 Desmontá-lo por peças enquanto está imóvel (frieza)',
                    estafaShift: 12,
                    actionCategory: 'PATERNAL_CALCULATION',
                    nextDialogueId: 'automaton_salvaged',
                },
                {
                    id: 'auto_ignore',
                    text: '🚶 Seguir em frente sem interferir',
                    estafaShift: 0,
                    actionCategory: 'STANDARD',
                    nextDialogueId: null,
                },
            ],
        });
        this.dialogueNodes.set('automaton_freed', {
            id: 'automaton_freed',
            speaker: 'Autômato Liberto',
            text: 'Gratidão registrada nos bancos de memória. A unidade se afasta, mancando de volta aos dutos.',
            choices: [{ text: 'Continuar jornada...', nextDialogueId: null }],
        });
        this.dialogueNodes.set('automaton_salvaged', {
            id: 'automaton_salvaged',
            speaker: 'Narrador',
            text: 'Você arranca as placas úteis antes que as luzes do núcleo se apaguem. Peças valiosas, silêncio incômodo.',
            choices: [{ text: 'Continuar jornada...', nextDialogueId: null }],
        });

        // ── Encontro ramificado: Engenheira Ferida ──
        this.dialogueNodes.set('wounded_engineer', {
            id: 'wounded_engineer',
            speaker: 'Engenheira Ferida',
            text: 'Por favor... uma ferida feia. Ajuda? Ou você só quer o que resta da minha bolsa?',
            choices: [],
            options: [
                {
                    id: 'eng_heal',
                    text: '💧 Estabilizar seus ferimentos (compaixão)',
                    estafaShift: -10,
                    actionCategory: 'MATERNAL_EMPATHY',
                    nextDialogueId: null,
                },
                {
                    id: 'eng_interrogate',
                    text: '🔩 Interrogá-la friamente por rotas e recursos (cálculo)',
                    estafaShift: 10,
                    actionCategory: 'PATERNAL_CALCULATION',
                    nextDialogueId: null,
                },
            ],
        });
    }

    public startDialogue(nodeId: string): IDialogueNode | undefined {
        this.activeDialogue = this.dialogueNodes.get(nodeId) || null;
        return this.activeDialogue || undefined;
    }

    public selectChoice(campaign: CampaignManager, choiceIndex: number): { nextNode: IDialogueNode | null; message?: string } {
        if (!this.activeDialogue || choiceIndex < 0 || choiceIndex >= this.activeDialogue.choices.length) {
            return { nextNode: null };
        }

        const choice = this.activeDialogue.choices[choiceIndex];
        let consequenceMessage = "";

        // Aplica consequências se houver
        if (choice.consequence) {
            const res = choice.consequence(campaign);
            consequenceMessage = res.text;
            if (!res.success && choice.text.includes('suborno')) {
                // Se falhar o suborno por falta de dinheiro, força o encerramento ou muda a rota
                return { nextNode: this.activeDialogue, message: "Falha: Recursos insuficientes para esta escolha!" };
            }
        }

        // Aplica impacto na Balança de Estafa antes de processar o próximo nó
        if (choice.estafaModifier !== undefined) {
            campaign.modifyEstafaBalance(choice.estafaModifier);
        }

        // Se a escolha redirecionar o mapa de campanha
        if (choice.targetNodeId) {
            campaign.setCurrentNode(choice.targetNodeId);
        }

        // Avança o nó do diálogo
        if (choice.nextDialogueId) {
            this.activeDialogue = this.dialogueNodes.get(choice.nextDialogueId) || null;
        } else {
            this.activeDialogue = null; // Fim do diálogo
        }

        return {
            nextNode: this.activeDialogue,
            message: consequenceMessage
        };
    }

    // ==============================================================
    // MODELO DE OPÇÕES RICAS — INTEGRAÇÃO COM A BALANÇA DE ESTAFA
    // ==============================================================

    /**
     * registerDialogueNode(node)
     * ------------------------------------------------------------------
     * Registra (ou substitui) um nó de diálogo no repositório. Útil para
     * conteúdo carregado dinamicamente e para testes que injetam nós
     * customizados com opções ricas.
     */
    public registerDialogueNode(node: IDialogueNode): void {
        this.dialogueNodes.set(node.id, node);
    }

    /**
     * mapCategoryToActionType(category)
     * ------------------------------------------------------------------
     * Mapeia a categoria psicológica da resposta para o tipo de ação
     * canônico avaliado pelo EstafaCalculator.validateAction:
     *   - MATERNAL_EMPATHY     → COMPASSIONATE_HEAL (travada no extremo Paterno)
     *   - PATERNAL_CALCULATION → COLD_EXECUTION     (travada no extremo Materno)
     *   - STANDARD/undefined   → STANDARD           (nunca travada)
     */
    private mapCategoryToActionType(category?: DialogueActionCategory): EstafaActionType {
        switch (category) {
            case 'MATERNAL_EMPATHY':
                return 'COMPASSIONATE_HEAL';
            case 'PATERNAL_CALCULATION':
                return 'COLD_EXECUTION';
            default:
                return 'STANDARD';
        }
    }

    /**
     * evaluateLock(option, currentEstafa)
     * ------------------------------------------------------------------
     * Decide, consultando o EstafaCalculator, se uma opção é bloqueada
     * pela psique atual do líder e produz a justificativa diegética.
     * Aplica primeiro o gate opcional `requiredQuadrant` e depois a
     * validação por categoria (validateAction).
     */
    private evaluateLock(
        option: IDialogueOption,
        currentEstafa: number,
    ): { locked: boolean; lockReason?: string } {
        // Gate opcional por quadrante exigido.
        if (option.requiredQuadrant !== undefined) {
            const quadrant = EstafaCalculator.getQuadrant(currentEstafa);
            if (quadrant !== option.requiredQuadrant) {
                return {
                    locked: true,
                    lockReason: `Esta resposta exige o quadrante ${option.requiredQuadrant}; o líder está em ${quadrant}.`,
                };
            }
        }

        // Validação psicológica canônica por categoria de ação.
        const actionType = this.mapCategoryToActionType(option.actionCategory);
        const validation = EstafaCalculator.validateAction(currentEstafa, actionType);

        if (!validation.allowed) {
            const quadrant = EstafaCalculator.getQuadrant(currentEstafa);
            const lockReason =
                quadrant === EstafaQuadrant.PATERNO_EXTREMO
                    ? 'Cálculo Tático: no extremo Paterno, o líder não adota um tom empático ou compassivo nesta resposta.'
                    : 'Empatia Ativa: no extremo Materno, o líder se recusa a responder de forma fria ou insensível.';
            return { locked: true, lockReason };
        }

        return { locked: false };
    }

    /**
     * getAvailableOptions(currentEstafa)
     * ------------------------------------------------------------------
     * Avalia todas as opções ricas do diálogo ativo contra o valor atual
     * da Estafa, marcando as incompatíveis como `locked: true` e
     * preenchendo `lockReason`. Retorna a lista completa (não filtra) para
     * que a UI possa exibir opções travadas em estado desabilitado.
     *
     * @param currentEstafa - Valor atual da Balança de Estafa do grupo/líder
     */
    public getAvailableOptions(currentEstafa: number): IEvaluatedDialogueOption[] {
        const options = this.activeDialogue?.options ?? [];
        return options.map((opt) => {
            const { locked, lockReason } = this.evaluateLock(opt, currentEstafa);
            return { ...opt, locked, lockReason };
        });
    }

    /**
     * selectOption(optionId, currentEstafa, campaign?)
     * ------------------------------------------------------------------
     * Seleciona uma opção rica pelo `id`:
     *   1. Se a opção estiver travada pela psique atual, NÃO aplica o
     *      shift nem avança — devolve o motivo do bloqueio.
     *   2. Caso contrário, aplica `estafaShift` (persistindo no grupo via
     *      campaign.modifyEstafaBalance, se fornecido), redireciona o nó
     *      do mapa (se houver) e avança o diálogo.
     *
     * Retorna sempre o novo valor de Estafa clampado em [-100, +100].
     *
     * @param optionId      - Identificador da opção
     * @param currentEstafa - Estafa atual (grupo/líder)
     * @param campaign      - Campanha opcional para persistir o shift no grupo
     */
    public selectOption(
        optionId: string,
        currentEstafa: number,
        campaign?: CampaignManager,
    ): ISelectOptionResult {
        const previousEstafa = EstafaCalculator.clamp(currentEstafa);
        const option = this.activeDialogue?.options?.find((o) => o.id === optionId) ?? null;

        // Opção inexistente — no-op seguro.
        if (!option) {
            return {
                option: null,
                locked: false,
                previousEstafa,
                newEstafa: previousEstafa,
                nextNode: this.activeDialogue,
            };
        }

        // Bloqueio pela psique atual — não aplica shift nem avança.
        const { locked, lockReason } = this.evaluateLock(option, currentEstafa);
        if (locked) {
            return {
                option,
                locked: true,
                lockReason,
                previousEstafa,
                newEstafa: previousEstafa,
                nextNode: this.activeDialogue,
            };
        }

        // Aplica o deslocamento de estafa (clampado) e persiste no grupo.
        const shift = option.estafaShift ?? 0;
        const newEstafa = EstafaCalculator.clamp(previousEstafa + shift);
        if (campaign && shift !== 0) {
            campaign.modifyEstafaBalance(shift);
        }
        if (campaign && option.targetNodeId) {
            campaign.setCurrentNode(option.targetNodeId);
        }

        // Avança o diálogo: string → próximo nó; null → encerra; undefined → mantém.
        if (option.nextDialogueId === null) {
            this.activeDialogue = null;
        } else if (typeof option.nextDialogueId === 'string') {
            this.activeDialogue = this.dialogueNodes.get(option.nextDialogueId) || null;
        }

        return {
            option,
            locked: false,
            previousEstafa,
            newEstafa,
            nextNode: this.activeDialogue,
        };
    }

    public getActiveDialogue(): IDialogueNode | null {
        return this.activeDialogue;
    }
}