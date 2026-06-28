#version 330
uniform sampler2D tex;
in vec2 uv;
out vec4 fragColor;
void main() {
    vec4 color = texture(tex, uv);
    fragColor = mix(color, vec4(0.82, 0.14, 0.14, 1.0), 0.35); // Rio red tint
}
