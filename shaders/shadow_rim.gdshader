shader_type canvas_item;

uniform vec4 rim_color : source_color = vec4(0.32, 0.53, 0.77, 0.9);

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(rim_color.rgb, source.a * rim_color.a * COLOR.a);
}
