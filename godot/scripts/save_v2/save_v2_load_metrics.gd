class_name SaveV2LoadMetrics
extends RefCounted

## Bloco C9 — estatística das medições de Save/Load V2 e identificação do modo de
## execução (headless × renderizado), para nunca misturar as duas séries.


## {count, min, max, mean, median} de uma lista de ms. Vazia -> count 0.
static func summarize(values: Array) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	var sorted := values.duplicate()
	sorted.sort()
	var total := 0.0
	for value in sorted:
		total += float(value)
	var count := sorted.size()
	var median: float = float(sorted[count / 2]) if count % 2 == 1 else (float(sorted[count / 2 - 1]) + float(sorted[count / 2])) / 2.0
	return {
		"count": count,
		"min": snappedf(float(sorted[0]), 0.001),
		"max": snappedf(float(sorted[count - 1]), 0.001),
		"mean": snappedf(total / count, 0.001),
		"median": snappedf(median, 0.001),
	}


## "headless" (servidor de exibição/renderização fictício) ou "rendered".
static func render_mode() -> String:
	return "headless" if DisplayServer.get_name() == "headless" else "rendered"


static func rendering_info() -> Dictionary:
	return {
		"mode": render_mode(),
		"display_server": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(),
	}
