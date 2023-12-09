shader_type canvas_item;

uniform sampler2D mask;

void fragment() {
	COLOR.a *= texture(mask, vec2(UV.y, 0.0)).a;
}
