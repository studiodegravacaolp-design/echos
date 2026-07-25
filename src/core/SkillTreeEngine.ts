/**
 * ====================================================================
 * SkillTreeEngine.ts
 * --------------------------------------------------------------------
 * Motor de árvore de perícias do Projeto Aetheris.
 * Gerencia nós de habilidade desbloqueáveis, verificação de
 * pré-requisitos, gasto de pontos de evolução e aplicação de
 * efeitos permanentes no personagem.
 *
 * Fonte: docs/04_arquitetura_software/ENG-PROGRESSAO-NIVEIS.md
 *
 * Versão: 1.0.0
 * Status: IMPLEMENTADO
 * ====================================================================
 */

import { CharacterState } from './CharacterState';
import { CANONICAL_ABILITIES, STARTER_ABILITY_IDS } from './CombatAbilities';

/**
 * Interface ISkillNode
 * --------------------------------------------------------------------
 * Define um nó na árvore de perícias.
 * Cada nó possui custo, pré-requisito opcional e um efeito
 * permanente que é aplicado ao personagem no desbloqueio.
 */
export interface ISkillNode {
    id: string;
    name: string;
    description: string;
    cost: number;
    requiredSkillId?: string; // Pré-requisito
    unlocked: boolean;
    effect: (character: CharacterState) => void;
}

/**
 * Classe SkillTreeEngine
 * --------------------------------------------------------------------
 * Gerencia múltiplas árvores de perícias indexadas por characterId.
 * Oferece métodos para:
 * - Inicializar árvores padrão para personagens
 * - Desbloquear nós com verificação de custo e pré-requisitos
 * - Consultar o estado atual da árvore
 *
 * NOTA: O campo evolutionPoints deve ser adicionado ao CharacterState
 * externamente para que o gerenciamento de pontos funcione.
 * Enquanto não presente, o fallback de 3 pontos é usado.
 */
export class SkillTreeEngine {
    private skills: Map<string, ISkillNode[]>; // Chave: characterId

    constructor() {
        this.skills = new Map<string, ISkillNode[]>();
    }

    /**
     * Inicializa uma árvore de exemplo para o herói (ex: foco em Engenharia Humana)
     * Define duas habilidades:
     *   - Blindagem Reforçada (custo 1, +5 defesa)
     *   - Engrenagem Sobrecarregada (custo 2, +8 ataque, requer Blindagem)
     */
    public initializeTreeForCharacter(characterId: string): void {
        const defaultSkills: ISkillNode[] = [
            {
                id: 'skill_reinforced_plating',
                name: 'Blindagem Reforçada',
                description: 'Aumenta permanentemente a defesa base em +5.',
                cost: 1,
                unlocked: false,
                effect: (char) => {
                    const current = char.equipmentBonusStats;
                    char.equipmentBonusStats = {
                        bonusMaxHp: current.bonusMaxHp ?? 0,
                        bonusAttack: current.bonusAttack ?? 0,
                        bonusDefense: (current.bonusDefense ?? 0) + 5,
                    };
                }
            },
            {
                id: 'skill_overcharged_gear',
                name: 'Engrenagem Sobrecarregada',
                description: 'Aumenta permanentemente o ataque base em +8. Requer Blindagem Reforçada.',
                cost: 2,
                requiredSkillId: 'skill_reinforced_plating',
                unlocked: false,
                effect: (char) => {
                    const current = char.equipmentBonusStats;
                    char.equipmentBonusStats = {
                        bonusMaxHp: current.bonusMaxHp ?? 0,
                        bonusAttack: (current.bonusAttack ?? 0) + 8,
                        bonusDefense: current.bonusDefense ?? 0,
                    };
                }
            }
        ];
        this.skills.set(characterId, defaultSkills);
    }

    /**
     * [1] LÓGICA DE DESBLOQUEIO DE PERÍCIAS
     *
     * unlockSkill(character, skillId)
     * ------------------------------------------------------------------
     * Tenta desbloquear uma habilidade na árvore do personagem.
     *
     * Fluxo de validação:
     * 1. Árvore inicializada para o personagem
     * 2. Habilidade existe na árvore
     * 3. Habilidade ainda não foi desbloqueada
     * 4. Personagem tem pontos de evolução suficientes
     * 5. Pré-requisito (se existir) está desbloqueado
     *
     * Se todas as condições forem satisfeitas:
     * - Marca o nó como desbloqueado
     * - Deduz o custo dos pontos de evolução
     * - Aplica o efeito permanente no personagem
     *
     * @param character - Estado do personagem
     * @param skillId - ID da habilidade a desbloquear
     * @returns Objeto com status de sucesso e mensagem descritiva
     */
    public unlockSkill(character: CharacterState, skillId: string): { success: boolean; message: string } {
        const tree = this.skills.get(character.id);
        if (!tree) return { success: false, message: "Árvore de habilidades não inicializada." };

        const targetSkill = tree.find(s => s.id === skillId);
        if (!targetSkill) return { success: false, message: "Habilidade não encontrada." };
        if (targetSkill.unlocked) return { success: false, message: "Habilidade já adquirida!" };

        // Verifica pontos de evolução (simulando 3 pontos iniciais para testes)
        // O campo evolutionPoints deve ser adicionado ao CharacterState para
        // gerenciamento completo; enquanto não presente, usa fallback de 3.
        const evolutionPoints = (character as any).evolutionPoints ?? 3;
        if (evolutionPoints < targetSkill.cost) {
            return { success: false, message: "Pontos de evolução insuficientes." };
        }

        // Verifica pré-requisito
        if (targetSkill.requiredSkillId) {
            const preReq = tree.find(s => s.id === targetSkill.requiredSkillId);
            if (!preReq || !preReq.unlocked) {
                return { success: false, message: "Habilidade de pré-requisito necessária trancada!" };
            }
        }

        // Aplica o desbloqueio
        targetSkill.unlocked = true;
        (character as any).evolutionPoints = evolutionPoints - targetSkill.cost;
        targetSkill.effect(character);

        return { success: true, message: `Sucesso! '${targetSkill.name}' foi desbloqueada.` };
    }

    /**
     * getTree(characterId)
     * ------------------------------------------------------------------
     * Retorna a árvore de habilidades completa para um personagem.
     *
     * @param characterId - ID do personagem
     * @returns Array de ISkillNode com o estado atual da árvore
     */
    public getTree(characterId: string): ISkillNode[] {
        return this.skills.get(characterId) || [];
    }

    /**
     * getUnlockedNodeIds(characterId)
     * ------------------------------------------------------------------
     * Retorna os IDs dos nós de atributo passivo já desbloqueados —
     * usado pela persistência (SaveSlotEngine).
     */
    public getUnlockedNodeIds(characterId: string): string[] {
        return (this.skills.get(characterId) || []).filter((n) => n.unlocked).map((n) => n.id);
    }

    /**
     * restoreUnlockedNodes(character, nodeIds)
     * ------------------------------------------------------------------
     * Reidrata a árvore de um personagem no carregamento: reinicializa a
     * árvore (defaults) e re-desbloqueia os nós salvos NA ORDEM da árvore
     * (pré-requisitos primeiro), reaplicando cada efeito passivo. Ignora
     * o custo de pontos de evolução (o estado já foi pago originalmente).
     */
    public restoreUnlockedNodes(character: CharacterState, nodeIds: string[]): void {
        this.initializeTreeForCharacter(character.id);
        const tree = this.skills.get(character.id)!;
        const toRestore = new Set(nodeIds);
        for (const node of tree) {
            if (toRestore.has(node.id) && !node.unlocked) {
                node.unlocked = true;
                node.effect(character); // reaplica o bônus passivo permanente
            }
        }
    }

    /**
     * grantStarterAbilities(character)
     * ------------------------------------------------------------------
     * Concede ao personagem o kit inicial de HABILIDADES ATIVAS de
     * combate (CombatAbilities). Ponte entre a árvore de perícias e as
     * técnicas usáveis no combate interativo. Idempotente.
     *
     * @returns IDs das habilidades efetivamente concedidas.
     */
    public grantStarterAbilities(character: CharacterState): string[] {
        const granted: string[] = [];
        for (const id of STARTER_ABILITY_IDS) {
            const ability = CANONICAL_ABILITIES[id];
            if (ability && !character.hasCombatAbility(id)) {
                character.learnCombatAbility({ ...ability });
                granted.push(id);
            }
        }
        return granted;
    }
}