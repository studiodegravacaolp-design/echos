class_name LocalizationService
extends Node

var language: String = "pt-BR"
var catalogs: Dictionary = {}

func set_language(locale: String) -> void:
    language = locale

func register_catalog(locale: String, catalog: Dictionary) -> void:
    catalogs[locale] = catalog

func tr_key(key: String) -> String:
    var catalog: Dictionary = catalogs.get(language, {})
    return str(catalog.get(key, key))
