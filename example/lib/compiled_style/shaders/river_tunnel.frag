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

uniform RiverTunnelUbo {
  vec2 width_stops;
  vec2 dasharray_size;
} river_tunnel_ubo;

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

in highp float v_line_length;

const highp vec4 color = vec4(0.11339999999999997, 0.16446, 0.2466, 1.0);
const float opacity = 0.5;
in float v_width;
uniform sampler2D dasharray;

out highp vec4 f_color;

void main() {
  float width = v_width;
  vec2 dasharray_size = river_tunnel_ubo.dasharray_size;
  
  float line_position = project_pixel_length(v_line_length) / width;
  float dash_value = texture(dasharray, vec2(line_position / dasharray_size.x, 0.5)).r;
  if (dash_value < 0.5) discard;
  
  f_color = color * (opacity * tile.opacity);
}

