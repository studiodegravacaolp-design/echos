class_name GameIdCatalog
extends RefCounted

## Catálogo canônico de IDs e aliases (A1 §4, decisão 7). SOMENTE DADO:
## nada aqui renomeia arquivos, conteúdo JSON, chaves de localização ou IDs
## usados pelo runtime atual. A migração por aliases é tratada separadamente.
##
## Regra: entidades usam `kind.scope.name` (snake_case por segmento).
## Sub-IDs (entry, choice, objective) continuam locais ao pai: start, memory,
## end, learn, leave, observe.

const KIND_SCENARIO := "scenario"
const KIND_NPC := "npc"
const KIND_DIALOGUE := "dialogue"
const KIND_QUEST := "quest"
const KIND_ECHO := "echo"
const KIND_MEMORY := "memory"
const KIND_CONSEQUENCE := "consequence"
const KIND_OBSERVATION := "observation"
const KIND_ENVSTATE := "envstate"

# --- IDs canônicos -----------------------------------------------------------

const SCENARIO_VARDHELM := "scenario.vardhelm"

const NPC_DURN := "npc.vardhelm.durn"
const NPC_DURN_NAME_KEY := "npc.vardhelm.durn.name"

const DIALOGUE_INTRO := "dialogue.vardhelm.intro"
## C12: conversa de Durn depois do Primeiro Eco.
const DIALOGUE_AFTER_ECHO := "dialogue.vardhelm.after_echo"
const DIALOGUE_AFTER_PANEL := "dialogue.vardhelm.after_panel"
## C25: os horários — Durn conta o que anotou (caminho "Sentir o quê?") ou aponta a folha ("Não senti nada.").
const DIALOGUE_THE_HOURS := "dialogue.vardhelm.the_hours"
const DIALOGUE_THE_NOTES := "dialogue.vardhelm.the_notes"
## C26: a reação curta de Durn à linha raspada (caminho "Sentir o quê?").
const DIALOGUE_THE_MARK := "dialogue.vardhelm.the_mark"

const QUEST_FIRST_ECHO := "quest.vardhelm.first_echo"
## C12: próxima investigação apontada por Durn (painel selado).
const QUEST_SEALED_PANEL := "quest.vardhelm.sealed_panel"
## C25: os horários (conhecer e comparar) e o que vem depois deles.
const QUEST_THE_HOURS := "quest.vardhelm.the_hours"
const QUEST_THOSE_HOURS := "quest.vardhelm.those_hours"
## C26: depois das releituras — quem reforçou o painel e onde ficam os registros.
const QUEST_THE_REINFORCEMENT := "quest.vardhelm.the_reinforcement"

const ECHO_FIRST := "echo.vardhelm.first"

const MEMORY_FIRST_ECHO := "memory.vardhelm.first_echo"
const MEMORY_MAINTENANCE_BOARD := "memory.vardhelm.maintenance_board"
const MEMORY_SEALED_PANEL := "memory.vardhelm.sealed_panel"
const MEMORY_TOOL_RACK := "memory.vardhelm.tool_rack"

const CONSEQUENCE_HEARD_ECHO := "consequence.vardhelm.heard_echo"
const CONSEQUENCE_FIRST_ECHO_COMPLETE := "consequence.vardhelm.first_echo_complete"
## C15: "Não senti nada." na primeira conversa — Durn fica sozinho com aquilo.
const CONSEQUENCE_FELT_NOTHING := "consequence.vardhelm.felt_nothing"

const OBSERVATION_MAINTENANCE_BOARD := "observation.vardhelm.maintenance_board"
const OBSERVATION_SEALED_PANEL := "observation.vardhelm.sealed_panel"
const OBSERVATION_TOOL_RACK := "observation.vardhelm.tool_rack"
## C16: o que Durn deixou no lugar de sempre quando saiu sozinho (caminho "Não senti nada.").
const OBSERVATION_DURN_NOTES := "observation.vardhelm.durn_notes"
## C21: Distrito das Fundições (pátio sob a Forja 01) — observações ambientais, sem memória.
const OBSERVATION_FOUNDRY_COAL_CARTS := "observation.vardhelm.foundry_coal_carts"
const OBSERVATION_FOUNDRY_CHAIN_PULLEY := "observation.vardhelm.foundry_chain_pulley"
const OBSERVATION_FOUNDRY_FORGE_DOOR := "observation.vardhelm.foundry_forge_door"
## C23: rua do Distrito das Fundições — observações ambientais, sem memória.
const OBSERVATION_FOUNDRY_STREET_GATE := "observation.vardhelm.foundry_street_gate"
const OBSERVATION_FOUNDRY_STREET_SHIFT_BOARD := "observation.vardhelm.foundry_street_shift_board"
const OBSERVATION_FOUNDRY_STREET_ORE_WAGONS := "observation.vardhelm.foundry_street_ore_wagons"
const OBSERVATION_FOUNDRY_STREET_SHARPENING := "observation.vardhelm.foundry_street_sharpening"

## Estados de ambiente (derivados, nunca persistidos — A1 §3.3). Usados só como
## IDs de eventos world_state_changed (Bloco B1).
const ENVSTATE_ECHO_AWAKENED := "envstate.vardhelm.echo_awakened"
const ENVSTATE_MAINTENANCE_REMEMBERED := "envstate.vardhelm.maintenance_remembered"
const ENVSTATE_SEALED_PANEL_REMEMBERED := "envstate.vardhelm.sealed_panel_remembered"
const ENVSTATE_TOOLS_REMEMBERED := "envstate.vardhelm.tools_remembered"
## C15: depois do Eco, Durn não espera o jogador (vai sozinho até onde o Eco aconteceu).
const ENVSTATE_DURN_ALONE := "envstate.vardhelm.durn_alone"

## IDs canônicos conhecidos, por tipo.
const KNOWN_IDS := {
	KIND_SCENARIO: [SCENARIO_VARDHELM],
	KIND_NPC: [NPC_DURN],
	KIND_DIALOGUE: [DIALOGUE_INTRO, DIALOGUE_AFTER_ECHO, DIALOGUE_AFTER_PANEL, DIALOGUE_THE_HOURS, DIALOGUE_THE_NOTES, DIALOGUE_THE_MARK],
	KIND_QUEST: [QUEST_FIRST_ECHO, QUEST_SEALED_PANEL, QUEST_THE_HOURS, QUEST_THOSE_HOURS, QUEST_THE_REINFORCEMENT],
	KIND_ECHO: [ECHO_FIRST],
	KIND_MEMORY: [MEMORY_FIRST_ECHO, MEMORY_MAINTENANCE_BOARD, MEMORY_SEALED_PANEL, MEMORY_TOOL_RACK],
	KIND_CONSEQUENCE: [CONSEQUENCE_HEARD_ECHO, CONSEQUENCE_FIRST_ECHO_COMPLETE, CONSEQUENCE_FELT_NOTHING],
	KIND_OBSERVATION: [OBSERVATION_MAINTENANCE_BOARD, OBSERVATION_SEALED_PANEL, OBSERVATION_TOOL_RACK, OBSERVATION_DURN_NOTES, OBSERVATION_FOUNDRY_COAL_CARTS, OBSERVATION_FOUNDRY_CHAIN_PULLEY, OBSERVATION_FOUNDRY_FORGE_DOOR, OBSERVATION_FOUNDRY_STREET_GATE, OBSERVATION_FOUNDRY_STREET_SHIFT_BOARD, OBSERVATION_FOUNDRY_STREET_ORE_WAGONS, OBSERVATION_FOUNDRY_STREET_SHARPENING],
	KIND_ENVSTATE: [ENVSTATE_ECHO_AWAKENED, ENVSTATE_MAINTENANCE_REMEMBERED, ENVSTATE_SEALED_PANEL_REMEMBERED, ENVSTATE_TOOLS_REMEMBERED, ENVSTATE_DURN_ALONE],
}

## Aliases: ID atual do conteúdo/runtime -> ID canônico, por tipo.
## Fontes: data/dialogue/vardhelm_intro.json, vardhelm_after_echo.json, vardhelm_after_panel.json, vardhelm_the_hours.json, vardhelm_the_notes.json (C25), vardhelm_the_mark.json (C26), data/quests/vardhelm_first_echo.json, vardhelm_sealed_panel.json, vardhelm_the_hours.json, vardhelm_those_hours.json (C25), vardhelm_the_reinforcement.json (C26),
## data/vardhelm/ambient_life.json, data/vardhelm/foundry_district_life.json (C21), data/vardhelm/foundry_street_life.json (C23) e scripts/vardhelm/vardhelm_vertical_slice.gd.
const ALIASES := {
	KIND_NPC: {
		"vardhelm.durn": NPC_DURN,
	},
	KIND_DIALOGUE: {
		"vardhelm_intro": DIALOGUE_INTRO,
		"vardhelm_after_echo": DIALOGUE_AFTER_ECHO,
		"vardhelm_after_panel": DIALOGUE_AFTER_PANEL,
		"vardhelm_the_hours": DIALOGUE_THE_HOURS,
		"vardhelm_the_notes": DIALOGUE_THE_NOTES,
		"vardhelm_the_mark": DIALOGUE_THE_MARK,
	},
	KIND_QUEST: {
		"vardhelm_first_echo": QUEST_FIRST_ECHO,
		"vardhelm_sealed_panel": QUEST_SEALED_PANEL,
		"vardhelm_the_hours": QUEST_THE_HOURS,
		"vardhelm_those_hours": QUEST_THOSE_HOURS,
		"vardhelm_the_reinforcement": QUEST_THE_REINFORCEMENT,
	},
	KIND_MEMORY: {
		"vardhelm_first_echo_memory": MEMORY_FIRST_ECHO,
		"vardhelm_memory_maintenance_board": MEMORY_MAINTENANCE_BOARD,
		"vardhelm_memory_sealed_panel": MEMORY_SEALED_PANEL,
		"vardhelm_memory_tool_rack": MEMORY_TOOL_RACK,
	},
	KIND_CONSEQUENCE: {
		"vardhelm_heard_echo": CONSEQUENCE_HEARD_ECHO,
		"vardhelm_first_echo_complete": CONSEQUENCE_FIRST_ECHO_COMPLETE,
		"vardhelm_felt_nothing": CONSEQUENCE_FELT_NOTHING,
	},
	KIND_OBSERVATION: {
		"maintenance_board": OBSERVATION_MAINTENANCE_BOARD,
		"sealed_panel": OBSERVATION_SEALED_PANEL,
		"tool_rack": OBSERVATION_TOOL_RACK,
		"durn_notes": OBSERVATION_DURN_NOTES,
		"foundry_coal_carts": OBSERVATION_FOUNDRY_COAL_CARTS,
		"foundry_chain_pulley": OBSERVATION_FOUNDRY_CHAIN_PULLEY,
		"foundry_forge_door": OBSERVATION_FOUNDRY_FORGE_DOOR,
		"foundry_street_gate": OBSERVATION_FOUNDRY_STREET_GATE,
		"foundry_street_shift_board": OBSERVATION_FOUNDRY_STREET_SHIFT_BOARD,
		"foundry_street_ore_wagons": OBSERVATION_FOUNDRY_STREET_ORE_WAGONS,
		"foundry_street_sharpening": OBSERVATION_FOUNDRY_STREET_SHARPENING,
	},
	# Fonte: narrative_consequences[].environment_state em data/vardhelm/ambient_life.json.
	KIND_ENVSTATE: {
		"echo_awakened": ENVSTATE_ECHO_AWAKENED,
		"maintenance_remembered": ENVSTATE_MAINTENANCE_REMEMBERED,
		"sealed_panel_remembered": ENVSTATE_SEALED_PANEL_REMEMBERED,
		"tools_remembered": ENVSTATE_TOOLS_REMEMBERED,
		"durn_alone": ENVSTATE_DURN_ALONE,
	},
}

## Chaves de localização: canônica -> chave existente hoje (não renomeada).
## A identidade de Durn é NPC_DURN; a chave legada não é identidade.
const LOCALIZATION_KEY_ALIASES := {
	NPC_DURN_NAME_KEY: "npc.vardhelm.elder.name",
}

## Ecos conhecidos. Um Eco resolvido registra sua memória (decisão A1 #2) e é a
## fonte narrativa da consequência que o resolve (decisão A1 #4).
const ECHOES := {
	ECHO_FIRST: {
		"memory_id": MEMORY_FIRST_ECHO,
		"resolving_consequence": CONSEQUENCE_FIRST_ECHO_COMPLETE,
		"quest_id": QUEST_FIRST_ECHO,
	},
}

## Observação -> fragmento de memória que ela produz (decisão A1 #1).
## Fonte: campo memory_id de data/vardhelm/ambient_life.json.
const OBSERVATION_FRAGMENTS := {
	OBSERVATION_MAINTENANCE_BOARD: MEMORY_MAINTENANCE_BOARD,
	OBSERVATION_SEALED_PANEL: MEMORY_SEALED_PANEL,
	OBSERVATION_TOOL_RACK: MEMORY_TOOL_RACK,
}

## Fonte narrativa conhecida de cada consequência no conteúdo atual.
const CONSEQUENCE_SOURCES := {
	CONSEQUENCE_HEARD_ECHO: {"source_type": "dialogue", "source_id": DIALOGUE_INTRO},
	CONSEQUENCE_FIRST_ECHO_COMPLETE: {"source_type": "echo", "source_id": ECHO_FIRST},
	CONSEQUENCE_FELT_NOTHING: {"source_type": "dialogue", "source_id": DIALOGUE_INTRO},
}

## Padrões legados usados pelo slice para "observação vista".
const LEGACY_OBSERVATION_FLAG_PREFIX := "observation_"
const LEGACY_OBSERVATION_FLAG_SUFFIX := "_seen"
const LEGACY_OBSERVATION_VALUE_PREFIX := "observation."
const LEGACY_OBSERVATION_VALUE_SUFFIX := ".seen"


## Retorna o ID canônico de `id` para o tipo `kind` (aceita ID canônico ou
## alias legado). Retorna "" se o ID for desconhecido.
static func canonical_id(kind: String, id: String) -> String:
	var known: Array = KNOWN_IDS.get(kind, [])
	if known.has(id):
		return id
	var aliases: Dictionary = ALIASES.get(kind, {})
	if aliases.has(id):
		return String(aliases[id])
	return ""


## Busca reversa: ID atual do runtime para um ID canônico, ou "" se não houver
## alias. Usado só para espelhar flags legadas no modo sombra.
static func legacy_id(kind: String, canonical: String) -> String:
	var aliases: Dictionary = ALIASES.get(kind, {})
	for legacy in aliases:
		if aliases[legacy] == canonical:
			return String(legacy)
	return ""


static func is_known(kind: String, id: String) -> bool:
	return not canonical_id(kind, id).is_empty()


## Tipo de um ID canônico (segmento antes do primeiro ponto).
static func kind_of(id: String) -> String:
	var dot := id.find(".")
	if dot <= 0:
		return ""
	return id.substr(0, dot)


## Origem de uma memória conhecida: {"source_type", "source_id"} ou {}.
static func memory_source(memory_id: String) -> Dictionary:
	for echo_id in ECHOES:
		if ECHOES[echo_id]["memory_id"] == memory_id:
			return {"source_type": "echo", "source_id": echo_id}
	for observation_id in OBSERVATION_FRAGMENTS:
		if OBSERVATION_FRAGMENTS[observation_id] == memory_id:
			return {"source_type": "observation", "source_id": observation_id}
	return {}


## Extrai o ID legado de observação de uma flag "observation_<id>_seen", ou "".
static func legacy_observation_from_flag(flag_id: String) -> String:
	return _strip_affixes(flag_id, LEGACY_OBSERVATION_FLAG_PREFIX, LEGACY_OBSERVATION_FLAG_SUFFIX)


## Extrai o ID legado de observação de um value "observation.<id>.seen", ou "".
static func legacy_observation_from_value_key(key: String) -> String:
	return _strip_affixes(key, LEGACY_OBSERVATION_VALUE_PREFIX, LEGACY_OBSERVATION_VALUE_SUFFIX)


static func _strip_affixes(text: String, prefix: String, suffix: String) -> String:
	if not text.begins_with(prefix) or not text.ends_with(suffix):
		return ""
	var inner_length := text.length() - prefix.length() - suffix.length()
	if inner_length <= 0:
		return ""
	return text.substr(prefix.length(), inner_length)
