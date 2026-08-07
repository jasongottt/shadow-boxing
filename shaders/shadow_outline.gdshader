shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.32, 0.53, 0.77, 0.9);
uniform float outline_width : hint_range(0.0, 6.0, 0.25) = 2.5;
uniform float flash_amount : hint_range(0.0, 1.0, 0.01) = 0.0;
// AnimatedSprite2D uses AtlasTexture frames, whose TEXTURE_PIXEL_SIZE describes
// the whole sheet rather than one 800x500 frame. Supplying the authored frame
// texel size keeps the rim equally thick in idle and directional atlases.
uniform vec2 frame_pixel_size = vec2(0.00125, 0.002);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	vec2 step_size = frame_pixel_size * outline_width;
	float nearby_alpha = 0.0;
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(step_size.x, 0.0)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - vec2(step_size.x, 0.0)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(0.0, step_size.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - vec2(0.0, step_size.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + step_size).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV - step_size).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(step_size.x, -step_size.y)).a);
	nearby_alpha = max(nearby_alpha, texture(TEXTURE, UV + vec2(-step_size.x, step_size.y)).a);

	float outline_mask = clamp(nearby_alpha - source.a, 0.0, 1.0);
	vec4 result = source * COLOR;
	result.rgb = mix(result.rgb, outline_color.rgb, flash_amount * source.a);

	if (outline_mask > 0.0) {
		result.rgb = mix(result.rgb, outline_color.rgb, outline_mask);
		result.a = max(result.a, outline_mask * outline_color.a * COLOR.a);
	}

	COLOR = result;
}
