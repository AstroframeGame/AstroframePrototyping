shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float intensity : hint_range(0.0, 10.0) = 2.0;
uniform float amount : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float dist = distance(UV, vec3(0.5).xy);
	float fresnel = pow(dist / 0.5, intensity) * amount;
	
	COLOR = col;
	COLOR.rgb *= glow_color.rgb;
	COLOR.a *= col.a * fresnel;
}