class_name SaveV2DiagnosticConfig
extends RefCounted

## Bloco C6 — configuração LOCAL do diagnóstico Save V2 (feature flag).
##
## Objeto comum passado explicitamente ao SaveV2DiagnosticCoordinator: não é
## Autoload, não lê ProjectSettings, variáveis de ambiente nem arquivos. Padrão:
## DESLIGADO — com a flag desligada o coordenador não lê, não grava e não
## restaura nada. Nenhum fluxo normal do jogo usa este objeto.

## SAVE_V2_DIAGNOSTIC_ENABLED — padrão OFF.
const DEFAULT_ENABLED := false
## Arquivo próprio do diagnóstico: nunca o do SaveService
## (user://echoes_of_the_soul_save.json) nem o da sombra do C2
## (SaveV2Service.DEFAULT_PATH).
const DEFAULT_PATH := "user://echoes_of_the_soul_save_v2_diagnostic.json"
const SLOT_ID := "diagnostic"

var enabled: bool = DEFAULT_ENABLED
var path: String = DEFAULT_PATH


static func create(is_enabled: bool = DEFAULT_ENABLED, file_path: String = DEFAULT_PATH) -> SaveV2DiagnosticConfig:
	var config := SaveV2DiagnosticConfig.new()
	config.enabled = is_enabled
	config.path = file_path
	return config
