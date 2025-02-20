#version 320 es
#pragma prelude: interpolation
#pragma prelude: tile

in highp vec2 position;
in highp vec2 normal;

#pragma prop: declare(highp vec4 color)
#pragma prop: declare(float opacity)
#pragma prop: declare(float width)

void main() {
  #pragma prop: resolve(...)

  vec2 offset = normal * width * 0.5 * 10;
  gl_Position = project_tile_position(position + offset);
}
