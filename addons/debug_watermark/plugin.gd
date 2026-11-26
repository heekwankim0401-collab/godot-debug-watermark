@tool
extends EditorPlugin

# Debug Watermark editor plugin.
#
# - Enabling the plugin adds the "DebugWatermark" autoload; disabling removes it.
#   This happens in _enable_plugin() / _disable_plugin(), which run only when the
#   user toggles the plugin, so opening or closing the editor never rewrites
#   project.godot.
# - While the plugin is enabled, the "debug_watermark/..." settings are listed in
#   Project Settings. Values left at their default are not saved to
#   project.godot; the autoload falls back to the same defaults at run time.

const AUTOLOAD_NAME := "DebugWatermark"
const Watermark := preload("debug_watermark.gd")


func _enter_tree() -> void:
	_register_settings()


func _enable_plugin() -> void:
	add_autoload_singleton(AUTOLOAD_NAME, _autoload_path())


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)
	_unregister_default_settings()


func _autoload_path() -> String:
	# Works even if the add-on folder is renamed.
	return (get_script() as Script).resource_path.get_base_dir().path_join("debug_watermark.gd")


func _register_settings() -> void:
	for key in Watermark.SETTINGS:
		var spec: Array = Watermark.SETTINGS[key]
		var path: String = Watermark.PREFIX + str(key)
		if not ProjectSettings.has_setting(path):
			ProjectSettings.set_setting(path, spec[0])
		ProjectSettings.set_initial_value(path, spec[0])
		ProjectSettings.add_property_info({
			"name": path,
			"type": spec[1],
			"hint": spec[2],
			"hint_string": spec[3],
		})
		ProjectSettings.set_as_basic(path, true)


# Removes settings that are still at their default, so a disabled plugin does
# not leave empty entries in Project Settings. Changed values are kept, so they
# come back if the plugin is enabled again.
func _unregister_default_settings() -> void:
	for key in Watermark.SETTINGS:
		var path: String = Watermark.PREFIX + str(key)
		if ProjectSettings.has_setting(path) and ProjectSettings.get_setting(path) == Watermark.SETTINGS[key][0]:
			ProjectSettings.set_setting(path, null)
