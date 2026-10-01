class_name SaveV2OperationalConfig
extends RefCounted

## Blocos C7/C8/C10.5 — flags do Save/Load V2 OPERACIONAL.
##
## Desde o C10.5 (decisão do usuário após o playtest humano) o V2 é o CAMINHO
## PADRÃO: Ctrl+S e Ctrl+L usam somente o Save V2 / Load V2 — o SaveService
## legado não é chamado nem usado como fallback. Com as flags desligadas
## explicitamente, o Ctrl+S/Ctrl+L voltam ao LEGACY COMPATIBILITY PATH (ex.: para
## ler um save antigo enquanto a migração opt-in não existe).
## Objeto local (não Autoload, sem ProjectSettings/ambiente); o dono é a
## experiência (VardhelmVerticalSlice).
##
## Arquivo: user://echoes_of_the_soul_save_v2_shadow.json (SaveV2Service.DEFAULT_PATH),
## slot único. O save antigo nunca é lido, gravado ou alterado pelo V2.

## SAVE_V2_OPERATIONAL_LOAD_ENABLED — padrão ON desde o C10.5.
const DEFAULT_ENABLED := true
## SAVE_V2_OPERATIONAL_SAVE_ENABLED — padrão ON desde o C10.5.
const DEFAULT_SAVE_ENABLED := true
## Único slot (C8): o mesmo arquivo do Save V2 desde o C2.
const SLOT_ID := "current"
const DEFAULT_PATH := SaveV2Service.DEFAULT_PATH

## SAVE_V2_OPERATIONAL_LOAD_ENABLED (Ctrl+L). Ligada: somente Load V2, sem fallback.
var enabled: bool = DEFAULT_ENABLED
## SAVE_V2_OPERATIONAL_SAVE_ENABLED (Ctrl+S). Ligada: somente Save V2 (o save
## antigo não é gravado nem sobrescrito).
var save_enabled: bool = DEFAULT_SAVE_ENABLED
var path: String = DEFAULT_PATH


## Configuração EXPLÍCITA (testes/ferramentas): nada ligado a menos que pedido.
static func create(is_enabled: bool = false, file_path: String = DEFAULT_PATH, is_save_enabled: bool = false) -> SaveV2OperationalConfig:
	var config := SaveV2OperationalConfig.new()
	config.enabled = is_enabled
	config.path = file_path
	config.save_enabled = is_save_enabled
	return config
