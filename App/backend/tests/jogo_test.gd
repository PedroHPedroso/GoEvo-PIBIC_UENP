extends SceneTree

var falhas := 0

func _initialize() -> void:
	_run.call_deferred()

func verificar(condicao: bool, descricao: String) -> void:
	if not condicao:
		falhas += 1
		push_error(descricao)
	else:
		print("OK: ", descricao)

func carregar(caminho: String) -> void:
	paused = false
	change_scene_to_file(caminho)
	await process_frame
	await process_frame

func esc(gestao: Node) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	gestao._input(event)

func _run() -> void:
	var gestao := root.get_node("GestaoJogo")
	await carregar("res://Cenas/Fase1/Fase1.tscn")
	verificar(gestao.fase_atual == 1, "fase 1 inicia o cronômetro")
	gestao._ultimo_tick = Time.get_ticks_msec() - 1500
	gestao._acumular_tempo()
	verificar(gestao.tempos_fases_ms[0] >= 1500, "tempo acumulado em milissegundos")
	esc(gestao)
	verificar(paused and gestao.menu_aberto, "ESC abre a pausa")
	var antes: int = gestao.tempos_fases_ms[0]
	gestao._ultimo_tick = Time.get_ticks_msec() - 5000
	gestao._acumular_tempo()
	verificar(gestao.tempos_fases_ms[0] == antes, "tempo no ESC não é contado")
	gestao._mostrar_opcoes()
	gestao._slider.value = 25
	verificar(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.25), "slider altera o volume Master")
	gestao._slider.value = 0
	verificar(AudioServer.is_bus_mute(0), "volume zero silencia o som")
	gestao._slider.value = 70
	esc(gestao)
	verificar(gestao.menu_aberto and gestao._acoes.visible, "ESC nas opções volta aos botões")
	gestao._continuar.pressed.emit()
	verificar(not paused and not gestao.menu_aberto, "Continuar retoma a fase")
	current_scene.finalizar_fase()
	esc(gestao)
	await create_timer(3.2).timeout
	verificar(gestao.fase_atual == 1, "ESC suspende a transição da fase 1")
	gestao.continuar()
	await create_timer(3.2).timeout
	verificar(gestao.fase_atual == 2, "fase 1 avança após Continuar")
	current_scene.complete_phase()
	esc(gestao)
	await create_timer(3.2).timeout
	verificar(gestao.fase_atual == 2, "ESC suspende a transição da fase 2 mesmo na tela de vitória")
	gestao.continuar()
	await create_timer(3.2).timeout
	verificar(gestao.fase_atual == 3, "fase 2 avança após Continuar")
	await carregar("res://Cenas/Fase1/Fase1.tscn")
	gestao.concluir_fase()
	antes = gestao.tempos_fases_ms[0]
	gestao._ultimo_tick = Time.get_ticks_msec() - 5000
	gestao._acumular_tempo()
	verificar(gestao.tempos_fases_ms[0] == antes, "fase concluída não continua contando")
	await carregar("res://Cenas/Fase2/Fase2.tscn")
	verificar(gestao.fase_atual == 2 and gestao.tempos_fases_ms[0] == antes, "fase 2 preserva o tempo da fase 1")
	await carregar("res://Cenas/Fase3/Fase3.tscn")
	verificar(paused, "fase 3 começa na tela de instruções")
	esc(gestao)
	var ultimo_botao: Control = gestao._acoes.get_child(-1)
	ultimo_botao.grab_focus()
	verificar(ultimo_botao.find_next_valid_focus() == gestao._continuar, "Tab não alcança a introdução por trás do pause")
	gestao._continuar.pressed.emit()
	verificar(paused, "Continuar preserva a pausa da introdução")
	current_scene.start_level()
	current_scene.collect_pigment(current_scene.pigments[0])
	esc(gestao)
	verificar(current_scene.pattern_names.size() == 1, "ESC não desfaz pigmentos")
	gestao.continuar()
	gestao._ultimo_tick = Time.get_ticks_msec() - 2000
	gestao._acumular_tempo()
	antes = gestao.tempos_fases_ms[2]
	await carregar("res://Cenas/Fase3/Fase3.tscn")
	verificar(gestao.tempos_fases_ms[2] >= antes, "nova tentativa não zera o tempo da fase")
	await carregar("res://Cenas/Fase4/Fase4.tscn")
	verificar(gestao.fase_atual == 4, "fase 4 inicia seu próprio cronômetro")
	current_scene.island = 2
	current_scene.complete_island()
	verificar(gestao.fase_finalizada, "última ilha encerra a medição")
	current_scene.continue_from_summary()
	verificar(current_scene.summary_button.text == "Retornar ao menu", "síntese final oferece retorno ao menu")
	verificar(current_scene.summary_button.pressed.is_connected(gestao.voltar_ao_menu), "botão final usa o retorno ao portal")
	verificar(not ResourceLoader.exists("res://Cenas/menu_principal.tscn"), "não existe menu principal interno")
	print("Resultado: ", falhas, " falhas")
	quit(1 if falhas else 0)
