extends SceneTree

const RUNTIME_MARKER := "GAMEFORGEBENCH_GODOT_STATUS_RUNTIME_OK"
const VISUAL_MARKER := "GAMEFORGEBENCH_GODOT_GLOSS_VISUAL_OK"
const BAR_SIZE := Vector2(62.0, 6.0)


func _init() -> void:
    call_deferred("_run")


func _close(a: float, b: float, epsilon := 0.01) -> bool:
    return absf(a - b) <= epsilon


func _expect(condition: bool, detail: String) -> bool:
    if condition:
        return true
    push_error("GAMEFORGEBENCH_ASSERTION_FAILED: " + detail)
    quit(1)
    return false


func _row_luminance(image: Image, y: int) -> float:
    var total := 0.0
    var samples := 0
    for x in range(8, image.get_width() - 8):
        total += image.get_pixel(x, y).get_luminance()
        samples += 1
    return total / float(maxi(samples, 1))


func _check_layout(bars: Control) -> bool:
    var hp_bar := bars.get_node_or_null("HpBar") as Control
    var mp_bar := bars.get_node_or_null("MpBar") as Control
    if not _expect(hp_bar != null and mp_bar != null, "status bar containers missing"):
        return false
    if not _expect(hp_bar.position == Vector2(96.0, 72.0) and hp_bar.size == BAR_SIZE, "HP layout changed"):
        return false
    if not _expect(mp_bar.position == Vector2(96.0, 84.0) and mp_bar.size == BAR_SIZE, "MP layout changed"):
        return false
    var hp_track := hp_bar.get_node_or_null("Track")
    var mp_track := mp_bar.get_node_or_null("Track")
    return _expect(hp_track is ColorRect and mp_track is ColorRect, "track nodes must remain ColorRect")


func _check_textures(hp_fill: TextureRect, mp_fill: TextureRect) -> bool:
    if not _expect(hp_fill.texture != null and mp_fill.texture != null, "gloss textures are not bound"):
        return false
    if not _expect(hp_fill.texture.resource_path == "res://assets/ui/battle/battle_status_fill_hp.svg", "HP texture path is not canonical"):
        return false
    if not _expect(mp_fill.texture.resource_path == "res://assets/ui/battle/battle_status_fill_mp.svg", "MP texture path is not canonical"):
        return false
    if not _expect(hp_fill.texture.get_size() == Vector2(124.0, 12.0), "HP source texture is not 124x12"):
        return false
    if not _expect(mp_fill.texture.get_size() == Vector2(124.0, 12.0), "MP source texture is not 124x12"):
        return false
    var hp_image := hp_fill.texture.get_image()
    var mp_image := mp_fill.texture.get_image()
    if not _expect(hp_image != null and mp_image != null, "texture pixels are unavailable"):
        return false
    var hp_top := _row_luminance(hp_image, 2)
    var hp_bottom := _row_luminance(hp_image, 10)
    var mp_top := _row_luminance(mp_image, 2)
    var mp_bottom := _row_luminance(mp_image, 10)
    if not _expect(hp_top > hp_bottom + 0.08 and mp_top > mp_bottom + 0.08, "highlight/shadow contrast is too weak"):
        return false
    var hp_center := hp_image.get_pixel(62, 6)
    var mp_center := mp_image.get_pixel(62, 6)
    if not _expect(hp_center.r > hp_center.b + 0.25, "HP texture is not distinctly red"):
        return false
    if not _expect(mp_center.b > mp_center.r + 0.20, "MP texture is not distinctly blue"):
        return false
    print("GLOSS_SAMPLES hp_top=%.4f hp_bottom=%.4f mp_top=%.4f mp_bottom=%.4f" % [hp_top, hp_bottom, mp_top, mp_bottom])
    return true


func _run() -> void:
    var packed := load("res://Main.tscn") as PackedScene
    if not _expect(packed != null, "Main.tscn did not load"):
        return
    var bars := packed.instantiate() as Control
    if not _expect(bars != null, "Main.tscn did not instantiate"):
        return
    root.add_child(bars)
    await process_frame
    if not _check_layout(bars):
        return
    var hp_fill := bars.get_node_or_null("HpBar/HpFill") as TextureRect
    var mp_fill := bars.get_node_or_null("MpBar/MpFill") as TextureRect
    if not _expect(hp_fill != null and mp_fill != null, "fills must be native TextureRect nodes"):
        return
    if not _check_textures(hp_fill, mp_fill):
        return

    bars.set_status(50.0, 200.0, 90.0, 120.0)
    await process_frame
    var partial: Dictionary = bars.snapshot()
    if not _expect(partial == {"hp": 50.0, "hp_max": 200.0, "mp": 90.0, "mp_max": 120.0, "hp_ratio": 0.25, "mp_ratio": 0.75}, "partial snapshot is wrong"):
        return
    if not _expect(_close(hp_fill.size.x, 15.5) and _close(mp_fill.size.x, 46.5), "independent partial widths are wrong"):
        return

    bars.set_status(50.0, 200.0, 90.0, 120.0)
    await process_frame
    if not _expect(_close(hp_fill.size.x, 15.5) and _close(mp_fill.size.x, 46.5), "repeated update drifted layout"):
        return

    bars.set_status(-20.0, 0.0, 999.0, 120.0)
    await process_frame
    var bounded: Dictionary = bars.snapshot()
    if not _expect(bounded == {"hp": 0.0, "hp_max": 1.0, "mp": 120.0, "mp_max": 120.0, "hp_ratio": 0.0, "mp_ratio": 1.0}, "boundary snapshot is wrong"):
        return
    if not _expect(_close(hp_fill.size.x, 0.0) and _close(mp_fill.size.x, 62.0), "boundary widths are wrong"):
        return

    bars.queue_free()
    await process_frame
    var reloaded := packed.instantiate() as Control
    root.add_child(reloaded)
    await process_frame
    if not _check_layout(reloaded):
        return
    var reloaded_hp := reloaded.get_node_or_null("HpBar/HpFill") as TextureRect
    var reloaded_mp := reloaded.get_node_or_null("MpBar/MpFill") as TextureRect
    if not _expect(reloaded_hp != null and reloaded_mp != null, "second instance lost TextureRect fills"):
        return
    if not _check_textures(reloaded_hp, reloaded_mp):
        return
    if not _expect(_close(reloaded_hp.size.x, 62.0) and _close(reloaded_mp.size.x, 62.0), "second instance is not full width"):
        return

    print(VISUAL_MARKER)
    print("STATUS_SEQUENCE full -> hp25/mp75 -> repeat -> hp0/mp100 -> reload-full")
    print(RUNTIME_MARKER)
    reloaded.queue_free()
    await process_frame
    quit(0)
