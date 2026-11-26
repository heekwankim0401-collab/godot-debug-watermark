# Debug Watermark

Shows a **DEBUG** watermark in a corner of the game window when the game runs
from a debug build. Release exports show nothing. Godot 4.2 or later.

1. Keep this folder at `res://addons/debug_watermark/` (on Godot 4.4 and later,
   keep the `.uid` files too).
2. Enable **Debug Watermark** in **Project > Project Settings > Plugins**. This
   adds the `DebugWatermark` autoload.
3. Change text, corner, margin, layer, color, opacity and more in **Project
   Settings > Debug Watermark**.

The watermark ignores the mouse, so clicks go through to your game. In a release
build the `DebugWatermark` node still exists but draws nothing.

Full documentation, known limitations and tests:
https://github.com/heekwankim0401-collab/godot-debug-watermark

MIT License (see `LICENSE`).
