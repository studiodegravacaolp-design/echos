extends SceneTree

## Runner isolado dos testes do GameState (Blocos A2 e A3).
##
##   godot --headless --path godot --script res://tests/state/state_test_runner.gd
##
## Não usa assert(): uma falha é registrada e contada, o runner sempre termina
## e o código de saída é 0 (tudo passou) ou 1 (houve falha). Não toca nos
## testes existentes em res://tests/. A suíte de integração do A3 instancia a
## cena de Vardhelm dentro deste SceneTree, sem Save/Load.

const SUITES := [
	preload("res://tests/state/test_state_contracts.gd"),
	preload("res://tests/state/test_state_migrator.gd"),
	preload("res://tests/state/test_state_projector.gd"),
	preload("res://tests/state/test_shadow_recorder.gd"),
	preload("res://tests/state/test_shadow_vardhelm.gd"),
	preload("res://tests/events/test_events_core.gd"),
	preload("res://tests/events/test_events_vardhelm.gd"),
	preload("res://tests/save_v2/test_save_v2_core.gd"),
	preload("res://tests/save_v2/test_save_v2_service.gd"),
	preload("res://tests/save_v2/test_save_v2_vardhelm.gd"),
	preload("res://tests/save_v2/test_save_v2_dual.gd"),
	preload("res://tests/save_v2/test_runtime_restorer.gd"),
	preload("res://tests/save_v2/test_runtime_restorer_vardhelm.gd"),
	preload("res://tests/save_v2/test_restore_adapters.gd"),
	preload("res://tests/save_v2/test_restore_adapters_vardhelm.gd"),
	preload("res://tests/save_v2/test_runtime_contracts.gd"),
	preload("res://tests/save_v2/test_runtime_contracts_vardhelm.gd"),
	preload("res://tests/save_v2/test_save_v2_diagnostic.gd"),
	preload("res://tests/save_v2/test_save_v2_diagnostic_vardhelm.gd"),
	preload("res://tests/save_v2/test_save_v2_operational_load.gd"),
	preload("res://tests/save_v2/test_save_v2_operational_load_vardhelm.gd"),
	preload("res://tests/echo/test_echo_visual_state.gd"),
	preload("res://tests/save_v2/test_save_v2_operational_save.gd"),
	preload("res://tests/save_v2/test_save_v2_operational_save_vardhelm.gd"),
	preload("res://tests/save_v2/test_c9_adoption_readiness.gd"),
	preload("res://tests/save_v2/test_c9_adoption_readiness_vardhelm.gd"),
	preload("res://tests/save_v2/test_c10_adoption_hardening.gd"),
	preload("res://tests/save_v2/test_c10_adoption_hardening_vardhelm.gd"),
	preload("res://tests/save_v2/test_c10_5_playtest_fixes.gd"),
	preload("res://tests/save_v2/test_c11_continuity.gd"),
	preload("res://tests/save_v2/test_c12_post_echo_bridge.gd"),
	preload("res://tests/save_v2/test_c13_living_vardhelm.gd"),
	preload("res://tests/save_v2/test_c14_first_sequence.gd"),
	preload("res://tests/save_v2/test_c15_choice_consequence.gd"),
	preload("res://tests/save_v2/test_c16_future_possibility.gd"),
	preload("res://tests/save_v2/test_c17_forge_bay.gd"),
	preload("res://tests/save_v2/test_c18_contextual_windows.gd"),
	preload("res://tests/save_v2/test_c21_foundry_district.gd"),
]

var _checks := 0
var _failures: Array[String] = []
var _section := ""


func _initialize() -> void:
	# Adiado um frame: a suíte de integração precisa da árvore pronta.
	_run_all.call_deferred()


func _run_all() -> void:
	for suite_script in SUITES:
		if suite_script == null or not suite_script.can_instantiate():
			section("carregamento de suíte")
			check(false, "suíte não compilou: %s" % (suite_script.resource_path if suite_script != null else "null"))
			continue
		var suite: RefCounted = suite_script.new()
		suite.call("run", self)
		# Um frame entre suítes: libera as cenas de integração (queue_free),
		# para que nenhuma experiência de uma suíte receba input de outra.
		await process_frame
	print("")
	print("==== GameState contract tests: %d checks, %d falha(s) ====" % [_checks, _failures.size()])
	for failure in _failures:
		print("  FAIL ", failure)
	if _failures.is_empty():
		print("RESULTADO: PASS")
	else:
		print("RESULTADO: FAIL")
	quit(0 if _failures.is_empty() else 1)


func section(name: String) -> void:
	_section = name
	print("-- ", name)


func check(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("   ok   ", label)
	else:
		print("   FAIL ", label)
		_failures.append("[%s] %s" % [_section, label])


## Compara dois Dictionaries pela serialização JSON com chaves ordenadas.
func same_json(a: Variant, b: Variant) -> bool:
	return JSON.stringify(a, "", true) == JSON.stringify(b, "", true)


## Simula o caminho real de um save: Dictionary -> texto JSON -> Dictionary.
func json_roundtrip(data: Dictionary) -> Dictionary:
	var parsed: Variant = JSON.parse_string(JSON.stringify(data))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed
