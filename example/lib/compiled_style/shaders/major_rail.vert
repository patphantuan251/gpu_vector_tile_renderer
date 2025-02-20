#version 320 es
#define data_crossfade(a, b) mix(a, b, camera.zoom - floor(camera.zoom))

#define data_step(start_value, end_value, start_stop, end_stop) \
  mix(start_value, end_value, step(end_stop, camera.zoom))

#define data_interpolate(start_value, end_value, start_stop, end_stop) \
  mix(start_value, end_value, data_interpolate_factor(1.0, start_stop, end_stop, camera.zoom))

#define data_interpolate_exponential(base, start_value, end_value, start_stop, end_stop) \
  mix(start_value, end_value, data_interpolate_factor(base, start_stop, end_stop, camera.zoom))

float data_interpolate_factor(
  float base,
  float start_stop,
  float end_stop,
  float t
) {
  float difference = end_stop - start_stop;
  float progress = t - start_stop;

  if (difference == 0.0) return 0.0;
  else if (base == 1.0) return progress / difference;
  else return (pow(base, progress) - 1.0) / (pow(base, difference) - 1.0);
}

uniform MajorRailUbo {
  float color_start_stop;
  float color_end_stop;
  float width_start_stop;
  float width_end_stop;
} major_rail_ubo;


precision highp float;

uniform Tile {
  highp mat4 local_to_world;
  highp float size;
  highp float extent;
  highp float opacity;
} tile;


uniform Camera {
  highp mat4 world_to_gl;
  highp float zoom;
} camera;


vec4 project_tile_position(vec2 position) {
  return camera.world_to_gl * tile.local_to_world * (vec4(position * (tile.size / tile.extent), 0.0, 1.0));
}


in highp vec2 position;
in highp vec2 normal;

in highp vec4 color_start_value;
in highp vec4 color_end_value;
out highp vec4 v_color;
in float opacity;
out float v_opacity;
in float width_start_value;
in float width_end_value;
out float v_width;

void main() {
highp vec4 color = data_interpolate(color_start_value, color_end_value, major_rail_ubo.color_start_stop, major_rail_ubo.color_end_stop);
v_color = color;
v_opacity = opacity;
float width = data_interpolate(width_start_value, width_end_value, major_rail_ubo.width_start_stop, major_rail_ubo.width_end_stop);
v_width = width;

  vec2 offset = normal * width * 0.5 * 10;
  gl_Position = project_tile_position(position + offset);
}


