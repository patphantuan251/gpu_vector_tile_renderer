#version 320 es

uniform BackgroundUbo {
  highp vec4 color;
  highp float opacity;
} background_ubo;

in vec2 position;

void main() {
  gl_Position = vec4(position, 0.0, 1.0);
}
