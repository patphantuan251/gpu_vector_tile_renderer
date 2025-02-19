#version 320 es
#pragma prelude: interpolation
#pragma prelude: tile

in highp vec2 position;

#pragma prop: declare(bool antialias)
#pragma prop: declare(highp float opacity)
#pragma prop: declare(highp vec4 color)
#pragma prop: declare(highp vec2 translate)

void main() {
  #pragma prop: resolve(...)
  gl_Position = project_tile_position(position + translate);
}
