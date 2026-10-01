shader_type canvas_item;
render_mode unshaded;

// Visual specimen only. The mask is a 32px material aperture, not a fluid grid.
uniform vec4 fluid_color : source_color = vec4(0.337, 0.784, 0.769, 1.0);
uniform bool has_content = true;
uniform float marker_opacity : hint_range(0.0, 1.0) = 1.0;
uniform float phase = 0.0;
uniform float path_offset = 0.0;
uniform float direction = 1.0;
uniform int segment_kind = 0; // 0: horizontal, 1: vertical, 2: left/down elbow
uniform bool layered_content = false;

const float PITCH = 48.0;
const float RADIUS = 8.0;
const vec2 BEND_CENTER = vec2(8.0, 24.0);

void fragment() {
	vec4 canvas_tint = COLOR;
	vec2 point = floor(UV * 32.0) + vec2(0.5);
	float along = point.x;
	float across = point.y - 16.0;
	if (segment_kind == 1) {
		along = point.y;
		across = point.x - 16.0;
	} else if (segment_kind == 2) {
		if (point.x <= 8.0) {
			along = point.x;
			across = point.y - 16.0;
		} else if (point.y >= 24.0) {
			along = 8.0 + RADIUS * 1.57079632679 + point.y - 24.0;
			across = point.x - 16.0;
		} else {
			float angle = atan(point.x - BEND_CENTER.x, BEND_CENTER.y - point.y);
			along = 8.0 + RADIUS * angle;
			across = length(point - BEND_CENTER) - RADIUS;
		}
	}
	float centered = mod(along + path_offset - phase + PITCH * 0.5, PITCH) - PITCH * 0.5;
	float forward = centered * direction;
	float v = abs(across);
	float stroke_distance = min(abs(forward - (3.0 - v)), abs(forward - (-3.0 - v)));
	float core = (v <= 2.5 && stroke_distance <= 0.65) ? 1.0 : 0.0;
	float outline = (v <= 3.5 && stroke_distance <= 1.35) ? 1.0 : 0.0;
	vec3 body = fluid_color.rgb * (across > 3.0 ? 0.88 : 1.0);
	body = mix(body, vec3(0.035, 0.06, 0.065), outline * marker_opacity * 0.6);
	body = mix(body, vec3(0.97, 0.985, 0.955), core * marker_opacity);
	float aperture = texture(TEXTURE, UV).a;
	float fill_alpha = layered_content ? (across > 0.0 ? 0.82 : 0.12) : 1.0;
	float mark_alpha = max(core, outline) * marker_opacity;
	COLOR = vec4(body, has_content ? aperture * fluid_color.a * max(fill_alpha, mark_alpha) : 0.0);
	if (layered_content) {
		COLOR *= canvas_tint;
	}
}
