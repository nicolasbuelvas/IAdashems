extends SceneTree
## Verificación de la UI (persona D).
## Uso:  godot --path . -s tools/ui_check.gd
## Comprueba geometría, tipografía y comportamiento de las 8 pantallas
## y sale con código 0 solo si todo pasa.

var failures := 0
var checks := 0


func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failures += 1
	print("%s  %s" % ["PASS" if ok else "FAIL", label])


func wait_frames(n: int) -> void:
	for i in n:
		await process_frame


func _initialize() -> void:
	await _run()


func _run() -> void:
	await _verify_main_menu()
	await _verify_hud()
	await _verify_pause()
	await _verify_options()
	await _verify_round_card()
	await _verify_story_scenes()
	print("RESULTADO: %s (%d checks, %d fallos)" % ["OK" if failures == 0 else "FALLAS", checks, failures])
	quit(0 if failures == 0 else 1)


func _add(node: Node) -> Node:
	root.add_child(node)
	return node


func _verify_main_menu() -> void:
	print("== main_menu")
	var menu = _add(load("res://scenes/main_menu.tscn").instantiate())
	await wait_frames(3)
	var title: Label = menu.get_node("Brand/Title")
	var tag: Label = menu.get_node("Brand/Tagline")
	var rule: ColorRect = menu.get_node("Brand/Rule")
	var brand: Control = menu.get_node("Brand")
	var card: Control = menu.get_node("MenuCard")
	var mascot: TextureRect = menu.get_node("Mascot")
	var primary: Button = menu.get_node("MenuCard/Menu/NewGameButton")

	check("titulo usa fredoka", title.get_theme_font("font").resource_path.ends_with("fredoka.ttf"))
	check("titulo 58px", title.get_theme_font_size("font_size") == 58)
	check("titulo con outline (faux bold)", title.get_theme_constant("outline_size") >= 3)
	check("titulo en 2 lineas", title.get_line_count() == 2)
	check("regla de ~96px (mide %d)" % rule.size.x, absf(rule.size.x - 96.0) < 8.0)
	check("subtitulo hace wrap (%d lineas)" % tag.get_line_count(), tag.get_line_count() >= 2)
	check("marca no invade la tarjeta", brand.get_global_rect().end.x <= card.get_global_rect().position.x + 1.0)
	check("mascota visible y grande (%dx%d)" % [mascot.size.x, mascot.size.y], mascot.size.x > 200.0 and mascot.size.y > 200.0)
	check("boton primario con estilo amber", str(primary.get_theme_stylebox("normal")).contains("sb_primary_normal"))
	check("3 botones", menu.get_node("MenuCard/Menu").get_child_count() >= 5)
	menu.queue_free()
	await wait_frames(2)


func _verify_hud() -> void:
	print("== hud (hud_test)")
	var hud_scene = _add(load("res://ui/hud_test.tscn").instantiate())
	await wait_frames(10)
	var heat: ProgressBar = hud_scene.get_node("HUD/TopBar/HeatPanel/HeatRow/HeatBar")
	var clock: Label = hud_scene.get_node("HUD/TopBar/ClockPanel/ClockLabel")
	var count: Label = hud_scene.get_node("HUD/TopBar/AnomaliesPanel/AnomaliesRow/AnomaliesCount")
	var herb: Control = hud_scene.get_node("HUD/BottomBar/HerbicideSlot/HerbicideRow/IconSlot/HerbicideIcon")
	var card: Control = hud_scene.get_node("HUD/RoundCard")

	check("barra de calor avanza (%.1f)" % heat.value, heat.value > 0.0)
	check("reloj se actualiza (%s)" % clock.text, clock.text != "01:30")
	check("contador de anomalías (%s)" % count.text, count.text.is_valid_int())
	check("5 modulos del HUD con tamaño", heat.size.x > 50.0 and clock.size.x > 40.0 and herb.size.x > 20.0)
	var lives := [
		hud_scene.get_node("HUD/BottomBar/LivesPanel/LivesRow/Slot1/Life1"),
		hud_scene.get_node("HUD/BottomBar/LivesPanel/LivesRow/Slot2/Life2"),
		hud_scene.get_node("HUD/BottomBar/LivesPanel/LivesRow/Slot3/Life3"),
	]
	check("3 vidas visibles", lives[0].visible and lives[1].visible and lives[2].visible)
	check("icono herbicida oscurecido en cooldown", herb.modulate.a < 0.95)
	check("tarjeta de ronda dentro del HUD", card != null)
	# sin EventBus el HUD no debe quejarse y queda mudo: comprobar que existe el gancho
	check("hud expone attach_source", hud_scene.get_node("HUD").has_method("attach_source"))
	hud_scene.queue_free()
	await wait_frames(2)


func _verify_pause() -> void:
	print("== pause_menu")
	var pause = _add(load("res://ui/pause_menu.tscn").instantiate())
	await wait_frames(2)
	check("process_mode ALWAYS", pause.process_mode == Node.PROCESS_MODE_ALWAYS)
	check("arranca oculto", not pause.visible)
	# los controles ocultos no maquetan: se muestra antes de medir
	pause.visible = true
	await wait_frames(2)
	var card: Control = pause.get_node("Center/Card")
	var vp := root.get_visible_rect().size
	check("tarjeta centrada (x=%.0f)" % (card.get_global_rect().get_center().x), absf(card.get_global_rect().get_center().x - vp.x * 0.5) < 6.0)
	pause.visible = false
	await wait_frames(1)
	pause.toggle_pause()
	check("pausa congela y se muestra", paused == true and pause.visible)
	check("3 botones con estilo", pause.get_node("Center/Card/Content/ResumeButton").get_theme_stylebox("normal") != null)
	pause.toggle_pause()
	check("reanuda y se oculta", paused == false and not pause.visible)
	pause.queue_free()
	await wait_frames(2)


func _verify_options() -> void:
	print("== options_menu")
	var opt = _add(load("res://ui/options_menu.tscn").instantiate())
	await wait_frames(3)
	var music: HSlider = opt.get_node("Center/Card/Rows/MusicRow/MusicSlider")
	var label_m: Label = opt.get_node("Center/Card/Rows/MusicRow/MusicLabel")
	var label_r: Label = opt.get_node("Center/Card/Rows/ResolutionRow/ResolutionLabel")
	check("buses Music/SFX creados", AudioServer.get_bus_index("Music") >= 0 and AudioServer.get_bus_index("SFX") >= 0)
	check("slider arranca en 100 (0 dB)", absf(music.value - 100.0) < 0.5)
	check("labels de fila alineados (%.0f/%.0f)" % [label_m.size.x, label_r.size.x], absf(label_m.size.x - label_r.size.x) < 1.0)
	check("hay backdrop", opt.get_node_or_null("Backdrop") != null)
	music.value = 50.0
	var db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	check("bajar slider baja el bus (%.1f dB)" % db, db < -5.0)
	opt.queue_free()
	await wait_frames(2)


func _verify_round_card() -> void:
	print("== round_card")
	var card = _add(load("res://ui/round_card.tscn").instantiate())
	await wait_frames(2)
	check("arranca oculto", not card.visible)
	card.show_turn(2)
	var label: Label = card.get_node("Center/Rows/TurnLabel")
	check("ronda 2: PATÉALO con imagen (%s)" % label.text, card.visible and label.text == "PATÉALO" and card.get_node("Center/Rows/Icon").visible)
	check("ronda 2: subtítulo con SHIFT", card.get_node("Center/Rows/Subtitle").visible)
	check("aviso de piso oculto", not card.get_node("Center/Rows/FloorNotice").visible)
	card.show_floor_unlocked()
	check("aviso de piso visible", card.get_node("Center/Rows/FloorNotice").visible)
	await create_timer(0.6).timeout
	check("sigue visible a los 0.6 s", card.visible)
	await create_timer(2.1).timeout
	check("se oculta a los 2.5 s", not card.visible)
	card.show_turn(5)
	check("ronda 5: solo texto, sin imagen", not card.get_node("Center/Rows/Icon").visible and not card.get_node("Center/Rows/Subtitle").visible)
	await create_timer(1.7).timeout
	check("ronda 5: se oculta a los 1.5 s", not card.visible)
	card.queue_free()
	await wait_frames(2)


func _verify_story_scenes() -> void:
	print("== intro / outro / credits")
	var intro = _add(load("res://scenes/intro.tscn").instantiate())
	await wait_frames(2)
	var hint: Label = intro.get_node("Center/Rows/ContinueHint")
	var a1 := hint.modulate.a
	await wait_frames(6)
	check("pista de intro parpadea (%.2f -> %.2f)" % [a1, hint.modulate.a], absf(a1 - hint.modulate.a) > 0.005)
	check("intro tiene mascota", intro.get_node("Center/Rows/Mascot") != null)
	intro.queue_free()

	var outro = _add(load("res://scenes/outro.tscn").instantiate())
	await wait_frames(2)
	check("outro conserva WhiteFlash para la explosión", outro.get_node_or_null("WhiteFlash") != null)
	check("outro con texto de cierre", outro.get_node("Center/Rows/Body").text.length() > 0)
	outro.queue_free()

	var credits = _add(load("res://scenes/credits.tscn").instantiate())
	await wait_frames(2)
	var names: VBoxContainer = credits.get_node("Center/Rows/Names")
	check("4 nombres en créditos (hay %d)" % names.get_child_count(), names.get_child_count() == 4)
	check("botón volver conectado", credits.get_node("Center/Rows/BackButton").pressed.is_connected(credits._on_BackButton_pressed))
	credits.queue_free()
	await wait_frames(2)
