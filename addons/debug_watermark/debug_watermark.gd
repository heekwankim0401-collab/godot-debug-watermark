extends CanvasLayer

## Debug Watermark: shows a small label (by default "DEBUG") in a corner of the
## game window when the game runs from a debug build, so debug builds are easy
## to tell apart from release builds.
##
## The Debug Watermark editor plugin registers this script as the
## "DebugWatermark" autoload. In a release build the node stays in the tree
## (so game code that refers to it keeps working) but creates no label.
##
## Settings live under "debug_watermark/" in Project Settings. Values left at
## their default are not written to project.godot, so every read below falls
## back to the defaults in SETTINGS.

enum Corner { TOP_LEFT, TOP_RIGHT, BOTTOM_LEFT, BOTTOM_RIGHT }

const PREFIX := "debug_watermark/"

## Setting name -> [default, type, hint, hint_string]. Shared with plugin.gd.
const SETTINGS := {
	"general/text": ["DEBUG", TYPE_STRING, PROPERTY_HINT_MULTILINE_TEXT, ""],
	"general/show_when_run_from_editor": [true, TYPE_BOOL, PROPERTY_HINT_NONE, ""],
	"general/hide_after_seconds": [0.0, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,600,0.1,or_greater,suffix:s"],
	"layout/corner": [Corner.BOTTOM_RIGHT, TYPE_INT, PROPERTY_HINT_ENUM, "Top Left,Top Right,Bottom Left,Bottom Right"],
	"layout/margin": [16, TYPE_INT, PROPERTY_HINT_RANGE, "0,256,1,or_greater,suffix:px"],
	"layout/layer": [2048, TYPE_INT, PROPERTY_HINT_RANGE, "-4096,4096,1,or_less,or_greater"],
	"style/font_size": [24, TYPE_INT, PROPERTY_HINT_RANGE, "1,256,1,or_greater,suffix:px"],
	"style/color": [Color(1.0, 0.25, 0.25), TYPE_COLOR, PROPERTY_HINT_COLOR_NO_ALPHA, ""],
	"style/opacity": [0.6, TYPE_FLOAT, PROPERTY_HINT_RANGE, "0,1,0.01"],
	"style/outline_size": [4, TYPE_INT, PROPERTY_HINT_RANGE, "0,64,1,or_greater,suffix:px"],
}

const _FADE_SECONDS := 0.5

## The watermark label, or null when the watermark is not shown (release build,
## or a run from the editor with "show_when_run_from_editor" off).
var label: Label


func _ready() -> void:
	# Keep fading out while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not should_show(OS.is_debug_build(), OS.has_feature("editor"), get_setting("general/show_when_run_from_editor")):
		return

	layer = get_setting("layout/layer")

	label = Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.text = format_text(get_setting("general/text"))
	label.add_theme_font_size_override("font_size", get_setting("style/font_size"))
	label.add_theme_color_override("font_color", get_setting("style/color"))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", get_setting("style/outline_size"))
	label.modulate.a = clampf(get_setting("style/opacity"), 0.0, 1.0)
	add_child(label)
	_place(get_setting("layout/corner"), get_setting("layout/margin"))

	var hide_after: float = get_setting("general/hide_after_seconds")
	if hide_after > 0.0:
		var tween := create_tween()
		tween.tween_interval(hide_after)
		tween.tween_property(label, "modulate:a", 0.0, _FADE_SECONDS)
		tween.tween_callback(label.hide)


## True when the watermark should appear: in debug builds only, and in runs
## from the editor only if [param show_in_editor_runs] is on.
static func should_show(debug_build: bool, run_from_editor: bool, show_in_editor_runs: bool) -> bool:
	if not debug_build:
		return false
	return show_in_editor_runs or not run_from_editor


## Replaces {project_name}, {project_version} and {godot_version} in [param template].
static func format_text(template: String) -> String:
	return template.format({
		"project_name": str(ProjectSettings.get_setting("application/config/name", "")),
		"project_version": str(ProjectSettings.get_setting("application/config/version", "")),
		"godot_version": str(Engine.get_version_info().get("string", "")),
	})


## Reads a "debug_watermark/<name>" project setting, or its default.
static func get_setting(name: String) -> Variant:
	var default_value: Variant = SETTINGS[name][0]
	var value: Variant = ProjectSettings.get_setting(PREFIX + name, default_value)
	if typeof(value) != typeof(default_value):
		# Wrong type (for example hand-edited project.godot): use the default,
		# except that ints and floats are interchangeable.
		if typeof(default_value) == TYPE_FLOAT and typeof(value) == TYPE_INT:
			return float(value)
		if typeof(default_value) == TYPE_INT and typeof(value) == TYPE_FLOAT:
			return int(value)
		return default_value
	return value


func _place(corner: int, margin: int) -> void:
	var right := corner == Corner.TOP_RIGHT or corner == Corner.BOTTOM_RIGHT
	var bottom := corner == Corner.BOTTOM_LEFT or corner == Corner.BOTTOM_RIGHT
	var preset := Control.PRESET_TOP_LEFT
	if right and bottom:
		preset = Control.PRESET_BOTTOM_RIGHT
	elif right:
		preset = Control.PRESET_TOP_RIGHT
	elif bottom:
		preset = Control.PRESET_BOTTOM_LEFT
	# Grow away from the corner, so a longer text stays inside the window.
	label.grow_horizontal = Control.GROW_DIRECTION_BEGIN if right else Control.GROW_DIRECTION_END
	label.grow_vertical = Control.GROW_DIRECTION_BEGIN if bottom else Control.GROW_DIRECTION_END
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	label.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, margin)
