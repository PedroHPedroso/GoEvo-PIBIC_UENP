extends Node

# Autoload: sobrevive às trocas de cena e às tentativas da mesma fase.
var tempos_fases_ms: Array[int] = [0, 0, 0, 0]
var fase_atual := 0
var menu_aberto := false
var fase_finalizada := false
var volume := 70.0
var _ultimo_tick := 0
var _desde_envio := 0
var _pausa_anterior := false
var _foco_anterior: Control
var _bridge: JavaScriptObject
var _antes_de_sair_callback: JavaScriptObject
var _overlay: Control
var _acoes: VBoxContainer
var _opcoes: VBoxContainer
var _titulo: Label
var _status: Label
var _continuar: Button
var _slider: HSlider
var _volume_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ultimo_tick = Time.get_ticks_msec()
	if OS.has_feature("web"):
		_bridge = JavaScriptBridge.get_interface("GoEvoSession")
	if _bridge:
		volume = float(_bridge.getVolume())
		_antes_de_sair_callback = JavaScriptBridge.create_callback(_antes_de_sair)
		_bridge.setBeforeLeave(_antes_de_sair_callback)
	else:
		var config := ConfigFile.new()
		if config.load("user://opcoes.cfg") == OK:
			volume = float(config.get_value("audio", "volume", 70.0))
	_aplicar_volume()
	_criar_menu()

func _process(_delta: float) -> void:
	_acumular_tempo()
	if _desde_envio >= 15000:
		salvar_tempo()
	if menu_aberto:
		_status.text = str(_bridge.getStatus()) if _bridge else "Tempo registrado nesta sessão local."

func _acumular_tempo() -> void:
	var agora := Time.get_ticks_msec()
	var intervalo := agora - _ultimo_tick
	_ultimo_tick = agora
	# Telas educativas e novas tentativas fazem parte da fase. Só o ESC suspende a medição.
	if fase_atual > 0 and not menu_aberto and not fase_finalizada:
		tempos_fases_ms[fase_atual - 1] += intervalo
		_desde_envio += intervalo

func iniciar_fase(fase: int) -> void:
	assert(fase >= 1 and fase <= 4)
	_acumular_tempo()
	if fase_atual != fase:
		salvar_tempo()
		fase_atual = fase
		fase_finalizada = false
		if _bridge:
			tempos_fases_ms[fase - 1] = maxi(tempos_fases_ms[fase - 1], int(_bridge.getTime(fase)))
	_ultimo_tick = Time.get_ticks_msec()

func salvar_tempo() -> void:
	_acumular_tempo()
	_desde_envio = 0
	if fase_atual > 0 and _bridge:
		_bridge.savePhase(fase_atual, tempos_fases_ms[fase_atual - 1])

func _antes_de_sair(_args: Array) -> void:
	salvar_tempo()

func concluir_fase() -> void:
	_acumular_tempo()
	fase_finalizada = true
	salvar_tempo()

func esperar_transicao(segundos: float) -> void:
	# A fase 2 pausa a árvore durante a mensagem de vitória. ESC também deve parar essa espera.
	var restante := segundos
	var anterior := Time.get_ticks_msec()
	while restante > 0.0:
		await get_tree().process_frame
		var agora := Time.get_ticks_msec()
		if not menu_aberto:
			restante -= float(agora - anterior) / 1000.0
		anterior = agora

func _input(event: InputEvent) -> void:
	if fase_atual > 0 and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if menu_aberto:
			if _opcoes.visible:
				_mostrar_acoes()
			else:
				continuar()
		else:
			abrir_pause()

func abrir_pause() -> void:
	if menu_aberto:
		return
	_acumular_tempo()
	menu_aberto = true
	_pausa_anterior = get_tree().paused
	_foco_anterior = get_viewport().gui_get_focus_owner()
	get_tree().paused = true
	_overlay.show()
	_mostrar_acoes()
	salvar_tempo()

func continuar() -> void:
	_overlay.hide()
	get_tree().paused = _pausa_anterior
	_ultimo_tick = Time.get_ticks_msec()
	menu_aberto = false
	if is_instance_valid(_foco_anterior):
		_foco_anterior.grab_focus()

func _mostrar_acoes() -> void:
	_titulo.text = "PAUSA • FASE %d" % fase_atual
	_acoes.show()
	_opcoes.hide()
	_continuar.grab_focus()

func _mostrar_opcoes() -> void:
	_titulo.text = "OPÇÕES"
	_acoes.hide()
	_opcoes.show()
	_slider.set_value_no_signal(volume)
	_volume_label.text = "SOM: %d%%" % int(volume)
	_slider.grab_focus()

func definir_volume(valor: float) -> void:
	volume = clampf(valor, 0.0, 100.0)
	_aplicar_volume()
	if is_instance_valid(_volume_label):
		_volume_label.text = "SOM: %d%%" % int(volume)
	if _bridge:
		_bridge.setVolume(volume)
	else:
		var config := ConfigFile.new()
		config.set_value("audio", "volume", volume)
		config.save("user://opcoes.cfg")

func _aplicar_volume() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master, volume <= 0.0)
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(volume / 100.0, 0.0001)))

func voltar_ao_menu() -> void:
	salvar_tempo()
	if OS.has_feature("web"):
		if _bridge:
			_bridge.returnToMenu()
		else:
			JavaScriptBridge.eval("window.location.assign('../index.html')")
		return
	# Pelo editor/desktop, abre o mesmo portal no navegador e encerra o jogo.
	var url := str(ProjectSettings.get_setting("goevo/portal/menu_url", "http://localhost:5286/index.html"))
	if OS.shell_open(url) == OK:
		get_tree().quit()
	else:
		push_error("Não foi possível abrir o menu do App em %s." % url)

func criar_botao(texto: String, acao: Callable) -> Button:
	var button := Button.new()
	button.text = texto
	button.custom_minimum_size = Vector2(240, 34)
	button.pressed.connect(acao)
	return button

func _criar_menu() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.04, 0.025, 0.85)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 240)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("163328")
	style.border_color = Color("b2d86c")
	style.set_border_width_all(3)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	panel.add_theme_font_override("font", preload("res://Fonts/determination.ttf"))
	panel.add_theme_font_size_override("font_size", 18)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	_titulo = Label.new()
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_titulo)
	_acoes = VBoxContainer.new()
	_acoes.add_theme_constant_override("separation", 8)
	box.add_child(_acoes)
	_continuar = criar_botao("Continuar", continuar)
	_acoes.add_child(_continuar)
	_acoes.add_child(criar_botao("Opções", _mostrar_opcoes))
	_acoes.add_child(criar_botao("Sair", voltar_ao_menu))
	_limitar_foco(_acoes.get_children())
	_opcoes = VBoxContainer.new()
	_opcoes.add_theme_constant_override("separation", 14)
	box.add_child(_opcoes)
	_volume_label = Label.new()
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_opcoes.add_child(_volume_label)
	_slider = HSlider.new()
	_slider.min_value = 0
	_slider.max_value = 100
	_slider.step = 1
	_slider.custom_minimum_size = Vector2(240, 28)
	_slider.value_changed.connect(definir_volume)
	_opcoes.add_child(_slider)
	_opcoes.add_child(criar_botao("Voltar", _mostrar_acoes))
	_limitar_foco([_slider, _opcoes.get_child(-1)])
	_status = Label.new()
	_status.custom_minimum_size = Vector2(240, 28)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 12)
	box.add_child(_status)
	_overlay.hide()

func _limitar_foco(controles: Array) -> void:
	# Tab e as setas permanecem no pause, inclusive sobre instruções pausadas.
	for index in range(controles.size()):
		var controle: Control = controles[index]
		var anterior := controle.get_path_to(controles[(index - 1 + controles.size()) % controles.size()])
		var proximo := controle.get_path_to(controles[(index + 1) % controles.size()])
		controle.focus_previous = anterior
		controle.focus_next = proximo
		controle.focus_neighbor_top = anterior
		controle.focus_neighbor_bottom = proximo
		controle.focus_neighbor_left = NodePath(".")
		controle.focus_neighbor_right = NodePath(".")
