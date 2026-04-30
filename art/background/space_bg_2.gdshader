shader_type canvas_item;
render_mode blend_mix;

uniform vec2 camera_offset;
uniform float camera_zoom = 1.0;
uniform float camera_rotation = 0.0;

uniform float noise_frequency = 0.002;
uniform float noise_parallax : hint_range(0.0, 2.0) = 1.0;
uniform float star_parallax : hint_range(0.0, 2.0) = 0.2;
uniform float dust_brightness = 1.8;

uniform int OCTAVES : hint_range(0, 20, 1);

uniform sampler2D color_gradient : repeat_disable, filter_linear;
uniform float seed: hint_range(1, 10);

void vertex() {
	// Called for every vertex the material is visible on.
}

float rand(vec2 coord) {
	return fract(sin(dot(coord.xy ,vec2(12.9898,78.233))) * (15.5453 + seed));
}
float noise(vec2 coord){
	vec2 i = floor(coord*noise_frequency);
	vec2 f = fract(coord* noise_frequency);
		
	float a = rand(i);
	float b = rand(i + vec2(1.0, 0.0));
	float c = rand(i + vec2(0.0, 1.0));
	float d = rand(i + vec2(1.0, 1.0));

	vec2 cubic = f * f * (3.0 - 2.0 * f);

	return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES ; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}
	return value * dust_brightness;
}

float circleNoise(vec2 uv) {
    float uv_y = floor(uv.y);
    uv.x += uv_y*.31;
    vec2 f = fract(uv);
	float h = rand(vec2(floor(uv.x),floor(uv_y)));
    float m = (length(f-0.25-(h*0.5)));
    float r = h*0.25;
    return smoothstep(0.0, r, m*0.75);
}
float cloud_alpha(vec2 uv) {
	float c_noise = 0.0;
	
	// more iterations for more turbulence
	int iters = 2;
	for (int i = 0; i < iters; i++) {
		c_noise += circleNoise(uv * 0.5 + (float(i+1)) + vec2(-0.3, 0.0));
	}
	float fbm = fbm(uv+c_noise);
	
	return fbm;
}

vec2 get_position(vec2 uv, vec2 pixel_size) {
	vec2 screen_center_uv = uv - 0.5;
	vec2 pixel_pos = screen_center_uv / pixel_size;
	float c = cos(camera_rotation);
	float s = sin(camera_rotation);
	vec2 rotated_pos = vec2(pixel_pos.x * c - pixel_pos.y * s, pixel_pos.x * s + pixel_pos.y * c);
	
	vec2 base_screen_pos = rotated_pos / camera_zoom;
	return base_screen_pos;
}



void fragment() {
	
	vec2 base_screen_pos = get_position(UV, SCREEN_PIXEL_SIZE);
	vec2 noise_world_pos = base_screen_pos + (camera_offset * noise_parallax);
	
	float s=0.5;
	float n_alpha = fbm(base_screen_pos*s +vec2(2,2));
	float n_dust = cloud_alpha(base_screen_pos*s);
	float n_dust2 = fbm(base_screen_pos*s  -vec2(2,2));
	float n_dust_lerp = n_dust2 * n_dust;
	
	float noise_val = noise(noise_world_pos);
	float dust = fbm(noise_world_pos);
	
	vec4 gradient_color = texture(color_gradient, vec2(n_dust_lerp, 0));
	COLOR = gradient_color;//vec4(dust, 0,0,1);
}
