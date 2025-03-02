precision highp float;

uniform Tile {
  highp mat4 local_to_gl;
  highp float size;
  highp float extent;
  highp float opacity;
} tile;

uniform Camera {
  highp mat4 world_to_gl;
  highp float zoom;
  float pixel_ratio;
} camera;

vec4 project_tile_position(vec2 position) {
  return tile.local_to_gl * vec4(position, 0.0, 1.0);
}

float project_pixel_length(float len) {
  return len * tile.size / tile.extent;
}
