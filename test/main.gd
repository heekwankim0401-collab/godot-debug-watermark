extends Control

# Test scene for the Debug Watermark add-on.
#
# Normal run: shows a button under the watermark corner (with another
# CanvasLayer on top of it) and counts clicks, so you can check by hand that the
# watermark is drawn on top and lets clicks through.
#
# Automated run: only when the WM_OUT environment variable is set (path of the
# results file). WM_CASE picks the expectations, WM_SHOTS (optional) is a folder
# for screenshots and WM_RUN (optional) prefixes their names. test/run_tests.ps1
# sets these; see the README.
#
#   WM_CASE=default         watermark shown with default settings
#   WM_CASE=custom          override.cfg sets text, corner, margin, hide_after
#   WM_CASE=hidden          no watermark expected (release build, or editor run
#                           with show_when_run_from_editor = false)
#
# Checks do not use assert(), which is removed from release builds.

const Watermark := preload("res://addons/debug_watermark/debug_watermark.gd")

const WATCHDOG_SECONDS := 60.0
## A pixel counts as changed when a channel differs by more than this.
const PIXEL_TOLERANCE := 0.05

var _button: Button
var _clicks := 0
var _lines := PackedStringArray()
var _fails := 0
var _finished := false
var _case := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	if OS.get_environment("WM_OUT").is_empty():
		return
	_case = OS.get_environment("WM_CASE")
	get_tree().create_timer(WATCHDOG_SECONDS).timeout.connect(_on_watchdog)
	_run.call_deferred()


func _build_ui() -> void:
	var info := Label.new()
	info.position = Vector2(24, 80)
	info.text = "Debug Watermark test project\n\n" \
		+ "Debug build: %s\n" % OS.is_debug_build() \
		+ "Run from the editor: %s\n\n" % OS.has_feature("editor") \
		+ "In a debug build the watermark is in the bottom-right corner, above\n" \
		+ "the blue box (another CanvasLayer, layer 100) and the button.\n" \
		+ "Click the watermark: the click should reach the button."
	add_child(info)

	_button = Button.new()
	_button.name = "UnderWatermark"
	_button.text = "Button under the watermark\nClicks: 0"
	_button.anchor_left = 1.0
	_button.anchor_top = 1.0
	_button.anchor_right = 1.0
	_button.anchor_bottom = 1.0
	_button.offset_left = -440
	_button.offset_top = -180
	_button.pressed.connect(_on_button_pressed)
	add_child(_button)

	var other_layer := CanvasLayer.new()
	other_layer.name = "OtherLayer100"
	other_layer.layer = 100
	add_child(other_layer)
	var box := ColorRect.new()
	box.name = "BlueBox"
	box.color = Color(0.1, 0.2, 0.55)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.anchor_left = 1.0
	box.anchor_top = 1.0
	box.anchor_right = 1.0
	box.anchor_bottom = 1.0
	box.offset_left = -200
	box.offset_top = -70
	other_layer.add_child(box)


func _on_button_pressed() -> void:
	_clicks += 1
	_button.text = "Button under the watermark\nClicks: %d" % _clicks


# --- automated checks -------------------------------------------------------

func _run() -> void:
	await _frames(10)
	_log("case=%s godot=%s debug_build=%s feature(editor)=%s feature(template)=%s feature(debug)=%s feature(release)=%s" % [
		_case, Engine.get_version_info().string, OS.is_debug_build(), OS.has_feature("editor"),
		OS.has_feature("template"), OS.has_feature("debug"), OS.has_feature("release")])
	_log("autoload entry: %s" % ProjectSettings.get_setting("autoload/DebugWatermark", "(none)"))
	var wm := get_node_or_null("/root/DebugWatermark") as CanvasLayer
	_check("autoload /root/DebugWatermark exists and is a CanvasLayer", wm != null)
	if wm == null:
		_finish()
		return
	var label: Label = wm.get("label")

	if _case == "hidden":
		_check("no label created", label == null and wm.get_child_count() == 0, "children=%d" % wm.get_child_count())
		# Game code that touches the autoload must keep working.
		wm.visible = false
		wm.visible = true
		_check("autoload still usable from game code", is_instance_valid(wm) and wm.is_inside_tree())
		await _shot("hidden")
		_finish()
		return

	_check("label created and visible", label != null and label.is_visible_in_tree())
	if label == null:
		_finish()
		return

	var exp_text := "DEBUG"
	var exp_corner := Watermark.Corner.BOTTOM_RIGHT
	var exp_margin := 16
	var exp_layer := 2048
	if _case == "custom":
		exp_text = "DBG %s %s %s" % [ProjectSettings.get_setting("application/config/name"),
			ProjectSettings.get_setting("application/config/version"), Engine.get_version_info().string]
		exp_corner = Watermark.Corner.TOP_LEFT
		exp_margin = 40
	_check("text", label.text == exp_text, "'%s'" % label.text)
	_check("layer", wm.layer == exp_layer, str(wm.layer))
	var controls := wm.find_children("*", "Control", true, false)
	var all_ignore := not controls.is_empty()
	for c: Control in controls:
		all_ignore = all_ignore and c.mouse_filter == Control.MOUSE_FILTER_IGNORE
	_check("every Control under the autoload has mouse_filter IGNORE", all_ignore, "%d control(s)" % controls.size())
	_check("label takes no focus", label.focus_mode == Control.FOCUS_NONE)
	await _frames(2)
	_check_corner(label, exp_corner, exp_margin, "")

	if _case == "custom":
		_check("font size from settings", label.get_theme_font_size("font_size") == 32, str(label.get_theme_font_size("font_size")))
		_check("opacity from settings", is_equal_approx(label.modulate.a, 1.0), str(label.modulate.a))
		await _shot("custom")
		# hide_after_seconds = 1: it must fade out even while the tree is paused.
		get_tree().paused = true
		await get_tree().create_timer(2.0).timeout
		_check("hidden after hide_after_seconds, with the tree paused", not label.visible and is_zero_approx(label.modulate.a), "visible=%s alpha=%s" % [label.visible, label.modulate.a])
		get_tree().paused = false
		_finish()
		return

	_check("opacity default", is_equal_approx(label.modulate.a, 0.6), str(label.modulate.a))
	await _shot("default")
	var rect := Rect2i(label.get_global_rect())

	var diff := await _diff_with_and_without(wm, rect)
	_check("drawn above another CanvasLayer (layer 100)", diff > 20, "%d px change when hidden" % diff)

	_clicks = 0
	await _click(Vector2(rect.get_center()))
	_check("a click on the watermark reaches the Button underneath", _clicks == 1, "clicks=%d" % _clicks)

	var dialog := AcceptDialog.new()
	dialog.title = "Embedded dialog"
	dialog.dialog_text = "This dialog covers the corner."
	add_child(dialog)
	var vp := Vector2i(get_viewport_rect().size)
	dialog.popup(Rect2i(vp - Vector2i(400, 170), Vector2i(390, 160)))
	await _frames(6)
	var covered := Rect2i(dialog.position, dialog.size).encloses(rect)
	_check("dialog is embedded and covers the watermark", dialog.is_embedded() and covered, "dialog=%s label=%s" % [Rect2i(dialog.position, dialog.size), rect])
	diff = await _diff_with_and_without(wm, rect)
	_check("drawn above an embedded dialog (layer 2048 > 1024)", diff > 20, "%d px" % diff)
	await _shot("dialog")
	wm.layer = 512
	diff = await _diff_with_and_without(wm, rect)
	_check("control: with layer 512 the embedded dialog hides it", diff == 0, "%d px" % diff)
	wm.layer = exp_layer
	dialog.hide()
	dialog.queue_free()

	get_window().size = Vector2i(800, 600)
	await _frames(10)
	_check_corner(label, exp_corner, exp_margin, " after resizing the window to 800x600")
	await _shot("resized")
	_finish()


func _check_corner(label: Label, corner: int, margin: int, tag: String) -> void:
	var vp := get_viewport_rect().size
	var r := label.get_global_rect()
	var ok := false
	match corner:
		Watermark.Corner.TOP_LEFT:
			ok = r.position.distance_to(Vector2(margin, margin)) <= 1.0
		Watermark.Corner.TOP_RIGHT:
			ok = absf(r.end.x - (vp.x - margin)) <= 1.0 and absf(r.position.y - margin) <= 1.0
		Watermark.Corner.BOTTOM_LEFT:
			ok = absf(r.position.x - margin) <= 1.0 and absf(r.end.y - (vp.y - margin)) <= 1.0
		Watermark.Corner.BOTTOM_RIGHT:
			ok = r.end.distance_to(vp - Vector2(margin, margin)) <= 1.0
	ok = ok and Rect2(Vector2.ZERO, vp).encloses(r) and r.size.x > 0 and r.size.y > 0
	_check("placed in corner %d with margin %d%s" % [corner, margin, tag], ok, "label=%s viewport=%s" % [r, vp])


func _diff_with_and_without(wm: CanvasLayer, rect: Rect2i) -> int:
	wm.visible = true
	var a := await _capture()
	wm.visible = false
	var b := await _capture()
	wm.visible = true
	await _frames(2)
	var area := rect.intersection(Rect2i(Vector2i.ZERO, a.get_size()))
	var n := 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			if absf(ca.r - cb.r) > PIXEL_TOLERANCE or absf(ca.g - cb.g) > PIXEL_TOLERANCE or absf(ca.b - cb.b) > PIXEL_TOLERANCE:
				n += 1
	return n


func _capture() -> Image:
	await _frames(3)
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _click(pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	Input.parse_input_event(motion)
	await _frames(3)
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		ev.pressed = pressed
		ev.position = pos
		ev.global_position = pos
		Input.parse_input_event(ev)
		await _frames(3)


func _shot(name: String) -> void:
	var dir := OS.get_environment("WM_SHOTS")
	if dir.is_empty():
		return
	var run := OS.get_environment("WM_RUN")
	var img := await _capture()
	img.save_png(dir.path_join("%s_%s.png" % [_case if run.is_empty() else run, name]))


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _log(s: String) -> void:
	print("[WM] ", s)
	_lines.append(s)


func _check(label: String, cond: bool, detail := "") -> void:
	if not cond:
		_fails += 1
	_log(("PASS  " if cond else "FAIL  ") + label + ("" if detail.is_empty() else "   [" + detail + "]"))


func _on_watchdog() -> void:
	if _finished:
		return
	_fails += 1
	_log("FAIL  watchdog: the run did not finish")
	_finish()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	_log("RESULT: %d failure(s)" % _fails)
	var f := FileAccess.open(OS.get_environment("WM_OUT"), FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_lines) + "\n")
		f.close()
	get_tree().quit()
