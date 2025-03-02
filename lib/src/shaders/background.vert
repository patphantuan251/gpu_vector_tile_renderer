#version 320 es
#pragma prelude: interpolation
#pragma prelude: tile

in highp vec2 position;

#pragma prop: declare(highp vec4 color)
#pragma prop: declare(highp float opacity)

void main() {
  #pragma prop: resolve(...)
  gl_Position = camera.world_to_gl * tile.local_to_world * vec4(position.x * tile.size, position.y * tile.size, 0.0, 1.0);
}
