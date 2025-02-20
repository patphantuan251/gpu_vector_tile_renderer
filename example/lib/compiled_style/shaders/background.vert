#version 320 es

uniform BackgroundUbo {
  highp vec4 color;
  highp float opacity;
} background_ubo;


in vec2 position;

out vec4 v_color;
out float v_opacity;

void main() {
  v_color = background_ubo.color;
  v_opacity = background_ubo.opacity;

  gl_Position = vec4(position, 0.0, 1.0);
}

