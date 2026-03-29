extends Node
## Manages localization. Loads CSV translations and provides language switching.

const SUPPORTED_LOCALES := ["en", "zh_CN", "es", "ja", "ko"]
const LOCALE_NAMES := {
	"en": "English",
	"zh_CN": "中文",
	"es": "Español",
	"ja": "日本語",
	"ko": "한국어",
}

var current_locale: String = "en"

func _ready() -> void:
	_load_csv_translations()
	# Try to detect system language
	var sys_locale := OS.get_locale()
	if sys_locale.begins_with("zh"):
		set_locale("zh_CN")
	elif sys_locale.begins_with("es"):
		set_locale("es")
	elif sys_locale.begins_with("ja"):
		set_locale("ja")
	elif sys_locale.begins_with("ko"):
		set_locale("ko")
	else:
		set_locale("en")

func _load_csv_translations() -> void:
	var path := "res://data/translations.csv"
	if not FileAccess.file_exists(path):
		push_warning("LocaleManager: translations.csv not found")
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	# Parse header
	var header_line := file.get_csv_line()
	if header_line.size() < 2:
		return
	# header_line[0] = "keys", rest are locale codes
	var locales: Array[String] = []
	for i in range(1, header_line.size()):
		locales.append(header_line[i])
	# Create a Translation for each locale
	var translations: Array[Translation] = []
	for locale in locales:
		var t := Translation.new()
		t.locale = locale
		translations.append(t)
	# Parse rows
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2:
			continue
		var key: String = row[0]
		if key.is_empty():
			continue
		for i in range(1, mini(row.size(), locales.size() + 1)):
			translations[i - 1].add_message(key, row[i])
	# Register with TranslationServer
	for t in translations:
		TranslationServer.add_translation(t)

func set_locale(locale: String) -> void:
	if locale in SUPPORTED_LOCALES:
		current_locale = locale
		TranslationServer.set_locale(locale)

func get_locale_name(locale: String) -> String:
	return LOCALE_NAMES.get(locale, locale)

func cycle_locale() -> void:
	var idx := SUPPORTED_LOCALES.find(current_locale)
	idx = (idx + 1) % SUPPORTED_LOCALES.size()
	set_locale(SUPPORTED_LOCALES[idx])
