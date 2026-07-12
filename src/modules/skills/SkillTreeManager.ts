/**
 * ====================================================================
 * SkillTreeManager.ts
 * --------------------------------------------------------------------
 * Gerenciador da árvore de habilidades do Projeto Aetheris.
 * Responsável por:
 *   - Carregar e manter o estado de desbloqueio (isUnlocked) dos nós
 *     de habilidade (ISkillNode)
 *   - Validar se um nó pode ser desbloqueado (nível mínimo + todos os
 *     pré-requisitos já desbloqueados)
 *   - Efetivar o desbloqueio de forma atômica (só muta o estado se
 *     toda a validação passar)
 *
 * Fonte: src/types/aetheris.types.ts (ISkillNode, ISkillOrSpell)
 *        src/core/CharacterState.ts (currentLevel)
 * ====================================================================
 */

import { CharacterState } from '../../core/CharacterState';
import { ISkillNode, ISkillOrSpell } from '../../types/aetheris.types';

/**
 * Classe SkillTreeManager
 * --------------------------------------------------------------------
 * Gerencia o conjunto de ISkillNode de um personagem através de um
 * mapeamento de skillId para o nó correspondente.
 */
export class SkillTreeManager {
  // ==================================================================
  // PROPRIEDADES PRIVADAS
  // ==================================================================

  /** Mapeamento de skillId para o nó de habilidade correspondente */
  private _nodes: Map<string, ISkillNode>;

  // ==================================================================
  // CONSTRUTOR
  // ==================================================================

  /**
   * Cria uma nova instância de SkillTreeManager.
   *
   * @param nodes - Conjunto inicial de nós de habilidade (opcional)
   */
  constructor(nodes: ISkillNode[] = []) {
    this._nodes = new Map<string, ISkillNode>();
    this.loadNodes(nodes);
  }

  // ==================================================================
  // GETTERS
  // ==================================================================

  /**
   * Obtém uma cópia do mapeamento de nós atual.
   * Retorna um novo Map (com nós clonados) para evitar mutação
   * externa direta do estado interno.
   */
  get nodes(): Map<string, ISkillNode> {
    const copy = new Map<string, ISkillNode>();
    for (const [skillId, node] of this._nodes) {
      copy.set(skillId, { ...node, prerequisites: [...node.prerequisites] });
    }
    return copy;
  }

  // ==================================================================
  // MÉTODO: loadNodes
  // ==================================================================

  /**
   * loadNodes(nodes)
   * ------------------------------------------------------------------
   * Carrega um conjunto de nós de habilidade no gerenciador. Nós com
   * o mesmo skillId de um nó já carregado são sobrescritos.
   *
   * @param nodes - Nós de habilidade a carregar
   */
  public loadNodes(nodes: ISkillNode[]): void {
    for (const node of nodes) {
      this._nodes.set(node.skillId, {
        ...node,
        prerequisites: [...node.prerequisites],
      });
    }
  }

  // ==================================================================
  // MÉTODO: getNode
  // ==================================================================

  /**
   * getNode(skillId)
   * ------------------------------------------------------------------
   * Obtém uma cópia defensiva do nó de habilidade, ou null se o
   * skillId não estiver carregado.
   *
   * @param skillId - ID da habilidade
   * @returns O nó de habilidade, ou null se não encontrado
   */
  public getNode(skillId: string): ISkillNode | null {
    const node = this._nodes.get(skillId);
    return node ? { ...node, prerequisites: [...node.prerequisites] } : null;
  }

  // ==================================================================
  // MÉTODO: isSkillUnlocked
  // ==================================================================

  /**
   * isSkillUnlocked(skillId)
   * ------------------------------------------------------------------
   * Verifica se um nó de habilidade está desbloqueado.
   * Retorna false se o skillId não estiver carregado.
   *
   * @param skillId - ID da habilidade
   * @returns true se o nó existe e está desbloqueado
   */
  public isSkillUnlocked(skillId: string): boolean {
    return this._nodes.get(skillId)?.isUnlocked ?? false;
  }

  // ==================================================================
  // MÉTODO: canUnlock
  // ==================================================================

  /**
   * canUnlock(skillId, character, skillData)
   * ------------------------------------------------------------------
   * Valida se um nó de habilidade PODE ser desbloqueado, sem alterar
   * nenhum estado. Duas condições precisam ser satisfeitas:
   *
   *   1. character.currentLevel >= skillData.get(skillId).minRequiredLevel
   *   2. Todos os IDs em node.prerequisites correspondem a nós já
   *      carregados com isUnlocked === true
   *
   * Retorna false se o nó ou os dados da skill não estiverem
   * carregados (validação impossível de resolver).
   *
   * @param skillId   - ID da habilidade a validar
   * @param character - Personagem cujo nível será checado
   * @param skillData - Catálogo de definições de skill (ISkillOrSpell),
   *                    usado para obter minRequiredLevel
   * @returns true se todas as condições de desbloqueio são satisfeitas
   */
  public canUnlock(
    skillId: string,
    character: CharacterState,
    skillData: Map<string, ISkillOrSpell>,
  ): boolean {
    const node = this._nodes.get(skillId);

    if (!node) {
      return false; // Nó não carregado — validação impossível
    }

    const skill = skillData.get(skillId);

    if (!skill) {
      return false; // Definição da skill não encontrada no catálogo
    }

    // ================================================================
    // Condição 1: Nível mínimo requerido
    // ================================================================

    if (character.currentLevel < skill.minRequiredLevel) {
      return false;
    }

    // ================================================================
    // Condição 2: Todos os pré-requisitos já desbloqueados
    // ================================================================

    for (const prerequisiteId of node.prerequisites) {
      const prerequisiteNode = this._nodes.get(prerequisiteId);

      if (!prerequisiteNode || !prerequisiteNode.isUnlocked) {
        return false;
      }
    }

    return true;
  }

  // ==================================================================
  // MÉTODO: unlockSkill
  // ==================================================================

  /**
   * unlockSkill(skillId, character, skillData)
   * ------------------------------------------------------------------
   * Efetiva o desbloqueio de um nó de habilidade.
   *
   * Comportamento:
   *   - Se o nó já estiver desbloqueado, retorna true de forma
   *     idempotente (nenhuma mutação adicional é necessária).
   *   - Caso contrário, roda canUnlock() e só muta node.isUnlocked
   *     para true se TODA a validação passar — mutação atômica:
   *     nenhum estado intermediário/parcial é exposto entre a
   *     validação e a escrita.
   *
   * @param skillId   - ID da habilidade a desbloquear
   * @param character - Personagem que está desbloqueando a habilidade
   * @param skillData - Catálogo de definições de skill (ISkillOrSpell)
   * @returns true se o nó está (ou passou a estar) desbloqueado
   */
  public unlockSkill(
    skillId: string,
    character: CharacterState,
    skillData: Map<string, ISkillOrSpell>,
  ): boolean {
    const node = this._nodes.get(skillId);

    if (!node) {
      return false;
    }

    if (node.isUnlocked) {
      return true; // Já desbloqueado — idempotente
    }

    if (!this.canUnlock(skillId, character, skillData)) {
      return false;
    }

    // Mutação atômica: só ocorre após toda a validação ter passado
    node.isUnlocked = true;

    return true;
  }
}
