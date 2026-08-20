extends Area2D

enum CorArvore { NENHUMA, BRANCA, MARROM, PRETA }
@export var cor_arvore: CorArvore = CorArvore.MARROM

@onready var sprite: Sprite2D = $Sprite2D

func definir_tonalidade(nova_cor: CorArvore) -> void:
	cor_arvore = nova_cor
	match cor_arvore:
		CorArvore.BRANCA:
			sprite.modulate = Color(0.9, 0.9, 0.9)
		CorArvore.MARROM:
			sprite.modulate = Color(0.312, 0.162, 0.004, 1.0)
		CorArvore.PRETA:
			sprite.modulate = Color(0.15, 0.15, 0.15)
