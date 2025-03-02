#version 320 es
#pragma prelude: interpolation
#pragma prelude: tile

in highp vec2 position;

#pragma prop: declare(highp vec4 color)
#pragma prop: declare(highp float opacity)

void main() {
  #pragma prop: resolve(...)
  gl_Position = tile.local_to_gl * vec4(position.x, position.y, 0.0, 1.0);
}
