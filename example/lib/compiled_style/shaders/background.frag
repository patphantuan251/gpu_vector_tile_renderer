#version 320 es

uniform BackgroundUbo {
  highp vec4 color;
  highp float opacity;
} background_ubo;


in vec4 v_color;
in float v_opacity;

out vec4 f_color;

void main() {
  f_color = v_color * v_opacity;
}

