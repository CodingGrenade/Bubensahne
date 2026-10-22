shader_type canvas_item;

uniform float movement_strength : hint_range(0.0, 0.0) = 0.02;
uniform float movement_speed : hint_range(0.0, 2.0) = 1.5;

void fragment() {
    vec2 uv = UV;

    // Subtle horizontal movement
    uv.x += sin(TIME * movement_speed + uv.y * 5.0) * movement_strength;

    // Subtle vertical movement
    uv.y += sin(TIME * movement_speed * 1.3 + uv.x * 4.0) * movement_strength * 0.5;

    COLOR = texture(TEXTURE, uv);
}