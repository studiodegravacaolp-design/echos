extends RefCounted

## Save V2 (Bloco C1) — envelope, serialização canônica, checksum e validador.


func _sample_state() -> GameState:
	var state := GameState.new()
	state.player.position = Vector3(2.5, 0.25, -1.75)
	state.player.rotation = Vector3(0.0, 0.1, 0.0)
	state.world.set_flag("vardhelm_first_echo_complete")
	state.world.apply_consequence("consequence.vardhelm.first_echo_complete", "echo", "echo.vardhelm.first")
	state.memory.resolve_echo("echo.vardhelm.first")
	state.memory.register_memory("memory.vardhelm.first_echo", "echo", "echo.vardhelm.first")
	return state


func _envelope() -> Dictionary:
	return SaveV2Envelope.create(_sample_state().to_dict(), SaveV2Envelope.make_metadata("shadow", 100, 200))


func run(t) -> void:
	_test_envelope(t)
	_test_canonical_serialization(t)
	_test_checksum(t)
	_test_validator(t)
	_test_errors(t)


func _test_envelope(t) -> void:
	t.section("C1 — envelope")
	var envelope := _envelope()
	t.check(envelope.keys().size() == 6, "envelope tem format, schema_version, game_version, metadata, state, checksum")
	t.check(envelope["format"] == "echoes_of_the_soul_save", "format explícito")
	t.check(envelope["schema_version"] == 2, "schema_version (save) = 2")
	t.check(envelope["state"]["state_version"] == 1, "state.state_version (GameState) = 1 — independentes")
	t.check(envelope["game_version"] == SaveV2Envelope.GAME_VERSION and not String(envelope["game_version"]).is_empty(), "game_version = constante explícita")
	t.check(envelope["metadata"] == {"slot_id": "shadow", "created_at": 100, "updated_at": 200}, "metadata só com dados técnicos")
	for forbidden in ["position", "quests", "memories", "flags", "dialogue", "player"]:
		t.check(not envelope["metadata"].has(forbidden), "metadata sem '%s'" % forbidden)
	t.check(not envelope["state"].has("metadata") and not envelope["state"].has("checksum") and not envelope["state"].has("slot_id"), "GameState sem metadata/checksum/slot")
	t.check(not envelope["state"].has("progression"), "progression continua reservado (fora do state)")
	t.check(envelope["state"]["player"]["location"]["position"] == [2.5, 0.25, -1.75], "Vector3 -> [x, y, z] no state")
	var errors := PackedStringArray()
	SaveV2Serializer.canonical_json(envelope, errors)
	t.check(errors.is_empty(), "envelope inteiro é JSON puro")
	t.check(not JSON.stringify(envelope).contains("Vector3"), "nenhum objeto Godot no envelope")


func _test_canonical_serialization(t) -> void:
	t.section("C1 — serialização canônica")
	var a := {"b": 1, "a": {"y": [1, 2.5, "x"], "x": true}, "c": null}
	var b := {}
	b["c"] = null
	b["a"] = {"x": true, "y": [1, 2.5, "x"]}
	b["b"] = 1
	t.check(SaveV2Serializer.canonical_json(a) == SaveV2Serializer.canonical_json(b), "independente da ordem de inserção do Dictionary")
	t.check(SaveV2Serializer.canonical_json(a) == "{\"a\":{\"x\":true,\"y\":[1,2.5,\"x\"]},\"b\":1,\"c\":null}", "chaves ordenadas, sem espaços")
	t.check(SaveV2Serializer.canonical_json({"n": 3}) == SaveV2Serializer.canonical_json({"n": 3.0}), "int e float inteiro têm a mesma forma (3 == 3.0)")
	# Floats "patológicos": o parser JSON do Godot 4.7.1 não devolve o mesmo
	# double para alguns valores (ex.: 1e-3 vindo de float32).
	var f32 := Vector3(0.1, -3.14159, 1e-3)
	var as_array := GameStateSerde.vector3_to_array(f32)
	var parsed: Variant = JSON.parse_string(SaveV2Serializer.canonical_json(as_array))
	t.check(GameStateSerde.array_to_vector3(parsed) == f32, "Vector3 -> Array -> JSON -> Array -> Vector3 exato (float32 preservado)")
	var drifted := 0
	for index in 3:
		if float(parsed[index]) != float(as_array[index]):
			drifted += 1
	print("   info floats de Vector3 que mudam no parser JSON do Godot: %d de 3 (limitação conhecida; checksum não depende disso)" % drifted)
	var envelope := _envelope()
	var file_text := SaveV2Serializer.to_file_text(envelope)
	t.check(file_text.begins_with("{\"checksum\":\"sha256:") and not file_text.contains("\n"), "arquivo = forma canônica em uma linha, checksum como 1ª chave")
	t.check(file_text == SaveV2Serializer.to_file_text(envelope.duplicate(true)), "texto do arquivo determinístico (mesmo envelope)")
	t.check(file_text == SaveV2Serializer.to_file_text(_envelope()), "texto do arquivo determinístico (mesmo estado e metadata)")
	var without := envelope.duplicate(true)
	without.erase("checksum")
	var split := SaveV2Checksum.split_file_text(file_text)
	t.check(split["ok"] and split["covered"] == SaveV2Serializer.canonical_json(without), "arquivo sem o membro checksum == forma canônica do envelope sem checksum")
	var errors := PackedStringArray()
	SaveV2Serializer.canonical_json({"v": Vector3.ONE}, errors)
	t.check(errors.size() == 1, "Vector3 cru é recusado pela forma canônica")
	errors = PackedStringArray()
	SaveV2Serializer.canonical_json({"n": INF}, errors)
	t.check(errors.size() == 1, "número não finito recusado")
	errors = PackedStringArray()
	var node := Node.new()
	SaveV2Serializer.canonical_json({"o": node}, errors)
	node.free()
	t.check(errors.size() == 1, "objeto recusado")


func _test_checksum(t) -> void:
	t.section("C1 — checksum")
	var envelope := _envelope()
	var checksum := String(envelope["checksum"])
	t.check(checksum.begins_with("sha256:") and checksum.length() == 71, "formato 'sha256:' + 64 hex")
	t.check(SaveV2Checksum.is_well_formed(checksum), "checksum bem formado")
	t.check(SaveV2Checksum.compute(envelope) == checksum, "calculado SEM o próprio campo checksum")
	var without := envelope.duplicate(true)
	without.erase("checksum")
	t.check(SaveV2Checksum.compute(without) == checksum, "mesmo resultado com ou sem o campo checksum presente")
	t.check(_envelope()["checksum"] == checksum, "determinístico (mesmo estado -> mesmo checksum)")
	var expected := SaveV2Serializer.canonical_json(without).sha256_text()
	t.check(checksum == "sha256:" + expected, "algoritmo = SHA-256 da forma canônica do envelope sem checksum")
	var changed := envelope.duplicate(true)
	changed["state"]["world"]["flags"]["extra"] = true
	t.check(SaveV2Checksum.compute(changed) != checksum, "qualquer mudança no state muda o checksum")
	changed = envelope.duplicate(true)
	changed["metadata"]["updated_at"] = 201
	t.check(SaveV2Checksum.compute(changed) != checksum, "metadata é coberta pelo checksum")
	t.check(SaveV2Checksum.matches(envelope), "matches() confere o envelope íntegro")
	t.check(not SaveV2Checksum.matches(changed), "matches() recusa o envelope alterado")
	t.check(not SaveV2Checksum.is_well_formed("sha256:XYZ") and not SaveV2Checksum.is_well_formed(123), "checksum malformado reconhecido")
	var text := SaveV2Serializer.to_file_text(envelope)
	var split := SaveV2Checksum.split_file_text(text)
	t.check(split["ok"] and SaveV2Checksum.compute_from_text(split["covered"]) == checksum, "mesmo checksum calculado a partir do texto do arquivo (sem reler números)")
	t.check(not SaveV2Checksum.split_file_text(JSON.stringify(envelope, "\t", true, true))["ok"], "arquivo reformatado não tem texto canônico verificável")


func _expect_code(t, envelope: Variant, code: String, label: String) -> void:
	var result := SaveV2Validator.validate(envelope)
	t.check(not result.ok and result.code == code, "%s -> %s (obtido: %s)" % [label, code, result.describe() if not result.ok else "OK"])


func _resealed(envelope: Dictionary) -> Dictionary:
	var copy := envelope.duplicate(true)
	copy["checksum"] = SaveV2Checksum.compute(copy)
	return copy


func _test_validator(t) -> void:
	t.section("C1 — validador")
	var good := _envelope()
	t.check(SaveV2Validator.validate(good).ok, "envelope íntegro é aceito")
	var good_text := SaveV2Serializer.to_file_text(good)
	var reparsed: Variant = JSON.parse_string(good_text)
	t.check(SaveV2Validator.validate(reparsed, good_text).ok, "envelope vindo de texto JSON é aceito (checksum pelo texto)")
	var pathological := GameState.new()
	pathological.player.position = Vector3(1e-3, -3.14159, 0.1)
	pathological.world.set_value("ratio", 0.0010000000474974513)
	var odd_envelope := SaveV2Envelope.create(pathological.to_dict(), SaveV2Envelope.make_metadata("shadow", 1, 2))
	var odd_text := SaveV2Serializer.to_file_text(odd_envelope)
	t.check(SaveV2Validator.validate(JSON.parse_string(odd_text), odd_text).ok, "floats que o parser altera não quebram o checksum do arquivo")
	_expect_code(t, [], SaveV2Errors.INVALID_ENVELOPE, "envelope não Dictionary")
	_expect_code(t, {}, SaveV2Errors.INVALID_ENVELOPE, "envelope vazio")
	var e := good.duplicate(true)
	e.erase("format")
	_expect_code(t, e, SaveV2Errors.INVALID_FORMAT, "format ausente")
	e = good.duplicate(true)
	e["format"] = "echoes_save_v1"
	_expect_code(t, e, SaveV2Errors.INVALID_FORMAT, "format errado")
	_expect_code(t, {"version": 2, "language": "pt-BR", "world": {}, "quests": {}}, SaveV2Errors.INVALID_FORMAT, "save antigo do SaveService")
	e = good.duplicate(true)
	e.erase("schema_version")
	_expect_code(t, e, SaveV2Errors.INVALID_ENVELOPE, "schema_version ausente")
	e = good.duplicate(true)
	e["schema_version"] = "2"
	_expect_code(t, e, SaveV2Errors.INVALID_ENVELOPE, "schema_version não inteiro")
	e = good.duplicate(true)
	e["schema_version"] = 3
	_expect_code(t, _resealed(e), SaveV2Errors.UNSUPPORTED_SCHEMA, "schema futuro (3)")
	e = good.duplicate(true)
	e["schema_version"] = 1
	_expect_code(t, _resealed(e), SaveV2Errors.UNSUPPORTED_SCHEMA, "schema antigo (1)")
	e = good.duplicate(true)
	e["extra"] = 1
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_ENVELOPE, "campo desconhecido no envelope")
	e = good.duplicate(true)
	e["game_version"] = ""
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_ENVELOPE, "game_version vazio")
	e = good.duplicate(true)
	e["metadata"] = "x"
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_METADATA, "metadata não Dictionary")
	e = good.duplicate(true)
	e["metadata"]["player_position"] = [0, 0, 0]
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_METADATA, "dado de jogo em metadata")
	e = good.duplicate(true)
	e["metadata"]["created_at"] = "ontem"
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_METADATA, "created_at não inteiro")
	e = good.duplicate(true)
	e["metadata"]["created_at"] = 999
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_METADATA, "created_at depois de updated_at")
	e = good.duplicate(true)
	e.erase("state")
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "state ausente")
	e = good.duplicate(true)
	e["state"] = [1, 2]
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "state não Dictionary")
	e = good.duplicate(true)
	e.erase("checksum")
	_expect_code(t, e, SaveV2Errors.INVALID_CHECKSUM, "checksum ausente")
	e = good.duplicate(true)
	e["checksum"] = 12345
	_expect_code(t, e, SaveV2Errors.INVALID_CHECKSUM, "checksum não String")
	e = good.duplicate(true)
	e["checksum"] = "sha256:" + "0".repeat(64)
	_expect_code(t, e, SaveV2Errors.INVALID_CHECKSUM, "checksum incorreto")
	e = good.duplicate(true)
	e["state"]["world"]["flags"]["vardhelm_first_echo_complete"] = false
	_expect_code(t, e, SaveV2Errors.INVALID_CHECKSUM, "payload alterado depois do checksum")
	e = good.duplicate(true)
	e["state"]["player"]["location"]["position"] = [1, "a", 3]
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "Vector3 inválido (tipo)")
	e = good.duplicate(true)
	e["state"]["player"]["location"]["rotation"] = [1, 2]
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "Vector3 inválido (tamanho)")
	e = good.duplicate(true)
	e["state"]["world"]["flags"]["vardhelm_first_echo_complete"] = "sim"
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "tipo inválido em campo conhecido (flag)")
	e = good.duplicate(true)
	e["state"]["state_version"] = 2
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "state_version do GameState não suportada")
	e = good.duplicate(true)
	e["state"]["progression"] = {}
	_expect_code(t, _resealed(e), SaveV2Errors.INVALID_STATE, "progression (reservado) recusado no state")


func _test_errors(t) -> void:
	t.section("C1 — códigos de erro")
	for code in ["INVALID_FORMAT", "UNSUPPORTED_SCHEMA", "INVALID_ENVELOPE", "INVALID_STATE", "INVALID_CHECKSUM", "INVALID_METADATA", "CORRUPTED_DATA", "FILE_NOT_FOUND"]:
		t.check(SaveV2Errors.ALL.has(code), "código %s definido" % code)
	var failure := SaveV2Result.failure(SaveV2Errors.INVALID_STATE, "x", ["a"])
	t.check(not failure.ok and failure.state == null and failure.describe().begins_with("INVALID_STATE"), "falha explícita, sem estado")
