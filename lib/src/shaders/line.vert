#version 460 core

#pragma prelude: interpolation
#pragma prelude: tile

in highp vec2 position;
in highp vec2 normal;

#pragma prop: declare(highp vec4 color)
#pragma prop: declare(float opacity)
#pragma prop: declare(float width)

void main() {
  #pragma prop: resolve(...)

  // Width is defined in terms of screen pixels, so we need to convert it.
  float local_width = width * (tile.extent / tile.size);
  vec2 offset = normal * local_width * 0.5;
  gl_Position = project_tile_position(position + offset);
}
