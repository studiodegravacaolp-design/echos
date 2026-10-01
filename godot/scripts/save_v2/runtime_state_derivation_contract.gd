class_name RuntimeStateDerivationContract
extends RefCounted

## Bloco C5 — contrato formal das DERIVAÇÕES de runtime usadas pelos adapters.
##
##   RestoreAdapter -> RuntimeStateDerivationContract -> runtime atual
##
## Cada experiência fornece uma implementação (Vardhelm:
## VardhelmRuntimeStateProvider). Os adapters só conhecem este contrato: nada de
## métodos privados, nomes/caminhos de nós, UI ou AmbientLife.
##
## Regras: não é um GameState, não guarda estado persistente, não guarda cópias
## e não tem cache. Identidade sempre por ID canônico (nunca NodePath/Node).
## A implementação padrão (esta) não sabe derivar nada: toda derivação devolve
## false / vazio e o adapter reporta requires_adapter.
##
## Memória e consequência NÃO têm métodos aqui: derivam de WorldState/QuestState
## pelo GameStateProjector + GameIdCatalog, contratos que já existem.


# --- observações ---------------------------------------------------------------

## IDs canônicos das observações que este runtime possui.
func observation_ids() -> Array[String]:
	return []


## Aplica ao runtime o estado derivado de "descoberta" de uma observação (o mesmo
## que a interação original deixa). false = observação desconhecida/indisponível.
func derive_observation_state(_observation_id: String, _discovered: bool) -> bool:
	return false


## {"revealed": bool, "fragment_registered": bool}; {} = desconhecida.
func describe_observation(_observation_id: String) -> Dictionary:
	return {}


# --- Eco -----------------------------------------------------------------------

## IDs canônicos dos Ecos que este runtime possui.
func echo_ids() -> Array[String]:
	return []


## Deriva o estado funcional dos Ecos a partir de WorldState/QuestState já
## restaurados. false = derivação indisponível.
func derive_echo_state() -> bool:
	return false


## {"revealed": bool, "interaction_enabled": bool}; {} = desconhecido.
func describe_echo(_echo_id: String) -> Dictionary:
	return {}


# --- apresentação da quest -----------------------------------------------------

## Deriva a apresentação das quests a partir do QuestState restaurado.
func derive_quest_presentation() -> bool:
	return false


## {"completion_presented": bool}; {} = quest sem apresentação neste runtime.
func describe_quest_presentation(_quest_id: String) -> Dictionary:
	return {}


# --- ambiente ------------------------------------------------------------------

## Deriva os estados de ambiente a partir de flags/consequências restauradas.
## Efeitos temporários não fazem parte da derivação.
func derive_environment_state() -> bool:
	return false


## IDs canônicos dos estados de ambiente ativos (IDs sem alias ficam como estão).
func environment_state_ids() -> Array[String]:
	return []


# --- sessão transitória (C8) ---------------------------------------------------

## true se há uma sessão de diálogo aberta (estado TRANSIENTE, sem contrato de
## restauração). O Load V2 operacional é recusado nesse caso. Padrão: false.
func is_dialogue_session_open() -> bool:
	return false
