shader_type canvas_item;

// Velocidade e tamanho do movimento horizontal (Ir e Vir)
uniform float wave_speed : hint_range(0.1, 5.0) = 1.5;
uniform float wave_amplitude : hint_range(0.0, 0.2) = 0.03;

// Configurações para deformação interna (Ondulação da água)
uniform float distortion_frequency : hint_range(1.0, 30.0) = 10.0;
uniform float distortion_amplitude : hint_range(0.0, 0.05) = 0.005;

void fragment() {
	// 1. Efeito de Vaivém (Ir e vir horizontalmente usando Seno)
	float back_and_forth = sin(TIME * wave_speed) * wave_amplitude;
	
	// 2. Efeito de Ondulação (faz com que diferentes partes da água deformem em tempos diferentes)
	float wave_distortion = sin(UV.y * distortion_frequency + TIME * wave_speed) * distortion_amplitude;
	
	// Junta os dois offsets na coordenada X
	vec2 distorted_uv = vec2(UV.x + back_and_forth + wave_distortion, UV.y);
	
	// Renderiza a textura com a nova coordenada deformada
	COLOR = texture(TEXTURE, distorted_uv);
}