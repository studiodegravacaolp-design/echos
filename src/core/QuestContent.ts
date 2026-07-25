/**
 * ====================================================================
 * QuestContent.ts
 * --------------------------------------------------------------------
 * Catálogo canônico de missões do Aetheris. Fornece as definições
 * (fábricas) registradas no QuestManager ao iniciar/carregar um jogo.
 *
 * Fábricas retornam instâncias novas (metas com progresso zerado) para
 * que cada sessão tenha seu próprio estado mutável.
 * ====================================================================
 */

import { IQuest, QuestStatus } from './QuestManager';

/** Missão Principal — o arco central do Ato 1→2. */
export function makeMainQuest(): IQuest {
    return {
        id: 'quest_heart_of_brenhold',
        name: 'O Coração de Brenhold',
        description: 'Atravesse os dutos, sobreviva às máquinas e silencie o Colosso no reator central.',
        status: QuestStatus.NOT_STARTED,
        type: 'MAIN',
        goals: [
            { id: 'g_reach_foundry', description: 'Alcançar o Pátio de Fundição', current: 0, required: 1, type: 'REACH_NODE', target: 'sector_01_combat' },
            { id: 'g_defeat_enemies', description: 'Derrotar 3 hostis dos dutos', current: 0, required: 3, type: 'DEFEAT_ENEMIES' },
            { id: 'g_kill_colossus', description: 'Destruir o Colosso de Ferrugem', current: 0, required: 1, type: 'KILL_BOSS', target: 'colosso_ferrugem' },
        ],
        reward: { scrap: 100, items: [], xp: 200, supplies: 50 },
    };
}

/** Missão Secundária — o dilema do autômato preso. */
export function makeSideQuestAutomaton(): IQuest {
    return {
        id: 'quest_echoes_in_ducts',
        name: 'Ecos nos Dutos',
        description: 'Atenda (ou ignore) o chamado do autômato preso nos Condutos de Vapor.',
        status: QuestStatus.NOT_STARTED,
        type: 'SIDE',
        goals: [
            { id: 'g_talk_automaton', description: 'Responder ao Autômato Preso', current: 0, required: 1, type: 'TALK_NPC', target: 'trapped_automaton' },
        ],
        reward: { scrap: 30, items: [], xp: 50, supplies: 0 },
    };
}

/** Todas as fábricas de missão canônica. */
export const CANONICAL_QUEST_FACTORIES: Array<() => IQuest> = [
    makeMainQuest,
    makeSideQuestAutomaton,
];
