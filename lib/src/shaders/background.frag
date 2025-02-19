#version 320 es

uniform BackgroundUbo {
  highp vec4 color;
  highp float opacity;
} background_ubo;

out vec4 f_color;

void main() {
  f_color = background_ubo.color * background_ubo.opacity;
}
