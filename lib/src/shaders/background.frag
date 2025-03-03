#version 460 core

#pragma prelude: interpolation
#pragma prelude: tile

#pragma prop: declare(highp vec4 color)
#pragma prop: declare(highp float opacity)

out highp vec4 f_color;

void main() {
  #pragma prop: resolve(...)
  f_color = color * (opacity * tile.opacity);
}
