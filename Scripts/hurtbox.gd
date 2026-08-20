extends Area2D

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("hurtbox_mosca"):

		var mosca = area.get_parent()

		if mosca.has_method("receber_ataque"):

			var eliminou_mosca = mosca.receber_ataque()

			if eliminou_mosca:
				var player = get_parent()

				if player.has_method("adicionar_mosca"):
					player.adicionar_mosca()
