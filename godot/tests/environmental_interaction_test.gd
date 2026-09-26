extends SceneTree

func _init() -> void:
    var observation := EnvironmentalObservation.new()
    assert(observation is Interactable)
    assert(observation.observation_id == "")
    observation.queue_free()

    var file := FileAccess.open("res://data/vardhelm/ambient_life.json", FileAccess.READ)
    assert(file != null)
    var parsed = JSON.parse_string(file.get_as_text())
    assert(parsed is Dictionary)
    assert(parsed.get("observations", []).size() == 3)

    print("Environmental interaction test: PASS")
    quit()
