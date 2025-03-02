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

uniform FerryLineUbo {
  vec2 color_stops;
  vec2 opacity_stops;
  vec2 width_stops;
  vec2 dasharray_size;
} ferry_line_ubo;

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

in highp vec2 position;
in highp vec2 normal;
in highp float line_length;

out highp float v_line_length;

in highp vec4 color_start_value;
in highp vec4 color_end_value;
out highp vec4 v_color;
in float opacity_start_value;
in float opacity_end_value;
out float v_opacity;
in float width_start_value;
in float width_end_value;
out float v_width;
uniform sampler2D dasharray;

void main() {
  highp vec4 color = data_interpolate(color_start_value, color_end_value, ferry_line_ubo.color_stops.x, ferry_line_ubo.color_stops.y);
  v_color = color;
  float opacity = data_interpolate(opacity_start_value, opacity_end_value, ferry_line_ubo.opacity_stops.x, ferry_line_ubo.opacity_stops.y);
  v_opacity = opacity;
  float width = data_interpolate(width_start_value, width_end_value, ferry_line_ubo.width_stops.x, ferry_line_ubo.width_stops.y);
  v_width = width;
  vec2 dasharray_size = ferry_line_ubo.dasharray_size;
  
  // Width is defined in terms of screen pixels, so we need to convert it.
  float local_width = width * (tile.extent / tile.size);
  vec2 offset = normal * local_width * 0.5;
  
  gl_Position = project_tile_position(position + offset);
  v_line_length = line_length;
}

