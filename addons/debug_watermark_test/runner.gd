@tool
extends EditorPlugin

# Editor-side test runner for Debug Watermark. NOT part of the add-on; do not
# ship it. It only runs when the WM_EDITOR_OUT environment variable is set (path
# of the results file); otherwise it does nothing. test/run_tests.ps1 enables it
# in a temporary copy of the project.
#
# It turns the add-on off and on again with EditorInterface.set_plugin_enabled()
# (the same code path as the Plugins tab) and checks the autoload, the project
# settings and what ends up in project.godot. It re-saves project.godot.
#
# Godot 4.4+ may store the autoload as "*uid://..." instead of "*res://...", and
# the editor writes project.godot a moment after a change, so the checks resolve
# UIDs and wait until the file stops changing.

const PLUGIN := "debug_watermark"
const PROJECT_FILE := "res://project.godot"
const AUTOLOAD_KEY := "autoload/DebugWatermark"
const SCRIPT_PATH := "res://addons/debug_watermark/debug_watermark.gd"
const TEXT_KEY := "debug_watermark/general/text"
## The file counts as saved once it has not changed for this long.
const SAVE_SETTLE_SECONDS := 2.5
const SAVE_TIMEOUT_SECONDS := 10.0
## How long to watch project.godot right after the editor opens.
const OPEN_WATCH_SECONDS := 6.0
const Watermark := preload("res://addons/debug_watermark/debug_watermark.gd")

var _lines := PackedStringArray()
var _fails := 0


func _enter_tree() -> void:
	if OS.get_environment("WM_EDITOR_OUT").is_empty():
		return
	_run.call_deferred()


func _run() -> void:
	await _frames(30)
	_log("Godot %s" % Engine.get_version_info().string)
	var expected_md5 := OS.get_environment("WM_EDITOR_START_MD5").to_lower()
	if not expected_md5.is_empty():
		# The editor saves project.godot a moment after a change, so watch the
		# file for a while instead of looking once.
		var changed_at := -1
		var t0 := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t0 < OPEN_WATCH_SECONDS * 1000.0:
			if changed_at < 0 and FileAccess.get_md5(PROJECT_FILE) != expected_md5:
				changed_at = Time.get_ticks_msec() - t0
			await get_tree().create_timer(0.1).timeout
		_check("opening the editor did not rewrite project.godot (watched for %d s)" % int(OPEN_WATCH_SECONDS), changed_at < 0, "" if changed_at < 0 else "changed after %d ms" % changed_at)

	_check("add-on enabled at start", EditorInterface.is_plugin_enabled(PLUGIN))
	_check("autoload registered at start", _points_to_addon(ProjectSettings.get_setting(AUTOLOAD_KEY, "")), str(ProjectSettings.get_setting(AUTOLOAD_KEY, "")))
	_check_settings_registered("at start")

	ProjectSettings.set_setting(TEXT_KEY, "TEST")

	var before := FileAccess.get_md5(PROJECT_FILE)
	EditorInterface.set_plugin_enabled(PLUGIN, false)
	var file := await _file_after_save(before)
	_check("disable: add-on reported disabled", not EditorInterface.is_plugin_enabled(PLUGIN))
	_check("disable: autoload removed from ProjectSettings", not ProjectSettings.has_setting(AUTOLOAD_KEY))
	_check("disable: autoload removed from project.godot", _autoload_in_file(file).is_empty(), _autoload_in_file(file))
	var leftover := PackedStringArray()
	for key in Watermark.SETTINGS:
		if key != "general/text" and ProjectSettings.has_setting(Watermark.PREFIX + str(key)):
			leftover.append(str(key))
	_check("disable: settings left at default are removed", leftover.is_empty(), ", ".join(leftover))
	_check("disable: changed setting is kept", ProjectSettings.get_setting(TEXT_KEY, "") == "TEST", str(ProjectSettings.get_setting(TEXT_KEY, "")))

	before = FileAccess.get_md5(PROJECT_FILE)
	EditorInterface.set_plugin_enabled(PLUGIN, true)
	file = await _file_after_save(before)
	_check("enable: add-on reported enabled", EditorInterface.is_plugin_enabled(PLUGIN))
	_check("enable: autoload back in ProjectSettings", _points_to_addon(ProjectSettings.get_setting(AUTOLOAD_KEY, "")), str(ProjectSettings.get_setting(AUTOLOAD_KEY, "")))
	_check("enable: autoload back in project.godot", _points_to_addon(_autoload_in_file(file)), _autoload_in_file(file))
	_check_settings_registered("after enable")
	_check("enable: changed setting still there", ProjectSettings.get_setting(TEXT_KEY, "") == "TEST")
	_check("enable: changed setting saved to project.godot", file.contains("general/text=\"TEST\""), _section(file, "[debug_watermark]"))
	_check("enable: settings at default not saved to project.godot", not file.contains("layout/corner") and not file.contains("style/opacity"), _section(file, "[debug_watermark]"))

	ProjectSettings.set_setting(TEXT_KEY, "DEBUG")
	ProjectSettings.save()
	file = FileAccess.get_file_as_string(PROJECT_FILE)
	_check("text back at default: nothing of the add-on's settings left in project.godot", not file.contains("[debug_watermark]"), _section(file, "[debug_watermark]"))
	_finish()


# Waits until project.godot has changed and then stayed the same for
# SAVE_SETTLE_SECONDS, and returns its text.
func _file_after_save(before_md5: String) -> String:
	var start := Time.get_ticks_msec()
	var last := before_md5
	var last_change := -1
	var changes := 0
	while Time.get_ticks_msec() - start < SAVE_TIMEOUT_SECONDS * 1000.0:
		await get_tree().create_timer(0.1).timeout
		var md5 := FileAccess.get_md5(PROJECT_FILE)
		if md5 != last:
			last = md5
			last_change = Time.get_ticks_msec()
			changes += 1
		elif last_change >= 0 and Time.get_ticks_msec() - last_change >= SAVE_SETTLE_SECONDS * 1000.0:
			break
	_log("      project.godot written %d time(s), %d ms" % [changes, Time.get_ticks_msec() - start])
	return FileAccess.get_file_as_string(PROJECT_FILE)


# The value of DebugWatermark= in the [autoload] section, or "".
func _autoload_in_file(file: String) -> String:
	var in_autoload := false
	for line in file.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("["):
			in_autoload = l == "[autoload]"
		elif in_autoload and l.begins_with("DebugWatermark="):
			return l.trim_prefix("DebugWatermark=").trim_prefix("\"").trim_suffix("\"")
	return ""


# True for "*res://.../debug_watermark.gd" or a "*uid://..." that resolves to it.
func _points_to_addon(value: Variant) -> bool:
	var s := str(value)
	if not s.begins_with("*"):
		return false
	s = s.substr(1)
	if s.begins_with("uid://"):
		var id := ResourceUID.text_to_id(s)
		if not ResourceUID.has_id(id):
			return false
		s = ResourceUID.get_id_path(id)
	return s == SCRIPT_PATH


func _check_settings_registered(tag: String) -> void:
	var infos := {}
	for p in ProjectSettings.get_property_list():
		infos[p["name"]] = p
	var missing := PackedStringArray()
	for key in Watermark.SETTINGS:
		var path: String = Watermark.PREFIX + str(key)
		var spec: Array = Watermark.SETTINGS[key]
		if not ProjectSettings.has_setting(path) or not infos.has(path) or infos[path]["type"] != spec[1] or infos[path]["hint"] != spec[2]:
			missing.append(str(key))
	_check("%s: all %d settings listed with type and hint" % [tag, Watermark.SETTINGS.size()], missing.is_empty(), ", ".join(missing))


func _section(file: String, header: String) -> String:
	var i := file.find(header)
	if i < 0:
		return "no " + header
	return file.substr(i, 200).replace("\n", " | ")


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _log(s: String) -> void:
	print("[WM-EDITOR] ", s)
	_lines.append(s)


func _check(label: String, cond: bool, detail := "") -> void:
	if not cond:
		_fails += 1
	_log(("PASS  " if cond else "FAIL  ") + label + ("" if detail.is_empty() else "   [" + detail + "]"))


func _finish() -> void:
	_log("RESULT: %d failure(s)" % _fails)
	var f := FileAccess.open(OS.get_environment("WM_EDITOR_OUT"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines) + "\n")
		f.close()
	get_tree().quit()
