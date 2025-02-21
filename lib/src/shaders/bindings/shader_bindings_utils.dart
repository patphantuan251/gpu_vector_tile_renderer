// ignore_for_file: non_constant_identifier_names, unused_element

import 'dart:typed_data';

import 'package:flutter_gpu/gpu.dart' as gpu;
import 'package:vector_math/vector_math_64.dart';

void clearMemberOffsetCache() {
  _memberOffsetCache.clear();
}

final _memberOffsetCache = <(gpu.UniformSlot, String), int>{};

int get_member_offset(gpu.UniformSlot slot, String member) {
  final key = (slot, member);
  return _memberOffsetCache[key] ??= slot.getMemberOffsetInBytes(member)!;
}

int set_int(int offset, ByteData data, int value) {
  data.setInt32(offset, value, Endian.host);
  return offset + 4;
}

int set_float(int offset, ByteData data, double value) {
  data.setFloat32(offset, value, Endian.host);
  return offset + 4;
}

int set_vec2(int offset, ByteData data, Vector2 vector) {
  data.setFloat32(offset, vector.storage[0], Endian.host);
  data.setFloat32(offset + 4, vector.storage[1], Endian.host);

  return offset + 8;
}

int set_vec3(int offset, ByteData data, Vector3 vector) {
  data.setFloat32(offset, vector.storage[0], Endian.host);
  data.setFloat32(offset + 4, vector.storage[1], Endian.host);
  data.setFloat32(offset + 8, vector.storage[2], Endian.host);

  return offset + 12;
}

int set_vec4(int offset, ByteData data, Vector4 vector) {
  data.setFloat32(offset, vector.storage[0], Endian.host);
  data.setFloat32(offset + 4, vector.storage[1], Endian.host);
  data.setFloat32(offset + 8, vector.storage[2], Endian.host);
  data.setFloat32(offset + 12, vector.storage[3], Endian.host);

  return offset + 16;
}

int set_mat2(int offset, ByteData data, Matrix2 matrix) {
  data.setFloat32(offset, matrix.storage[0], Endian.host);
  data.setFloat32(offset + 4, matrix.storage[1], Endian.host);
  data.setFloat32(offset + 8, matrix.storage[2], Endian.host);
  data.setFloat32(offset + 12, matrix.storage[3], Endian.host);

  return offset + 16;
}

int set_mat3(int offset, ByteData data, Matrix3 matrix) {
  data.setFloat32(offset, matrix.storage[0], Endian.host);
  data.setFloat32(offset + 4, matrix.storage[1], Endian.host);
  data.setFloat32(offset + 8, matrix.storage[2], Endian.host);
  data.setFloat32(offset + 12, matrix.storage[3], Endian.host);
  data.setFloat32(offset + 16, matrix.storage[4], Endian.host);
  data.setFloat32(offset + 20, matrix.storage[5], Endian.host);
  data.setFloat32(offset + 24, matrix.storage[6], Endian.host);
  data.setFloat32(offset + 28, matrix.storage[7], Endian.host);
  data.setFloat32(offset + 32, matrix.storage[8], Endian.host);

  return offset + 36;
}

int set_mat4(int offset, ByteData data, Matrix4 matrix) {
  data.setFloat32(offset, matrix.storage[0], Endian.host);
  data.setFloat32(offset + 4, matrix.storage[1], Endian.host);
  data.setFloat32(offset + 8, matrix.storage[2], Endian.host);
  data.setFloat32(offset + 12, matrix.storage[3], Endian.host);
  data.setFloat32(offset + 16, matrix.storage[4], Endian.host);
  data.setFloat32(offset + 20, matrix.storage[5], Endian.host);
  data.setFloat32(offset + 24, matrix.storage[6], Endian.host);
  data.setFloat32(offset + 28, matrix.storage[7], Endian.host);
  data.setFloat32(offset + 32, matrix.storage[8], Endian.host);
  data.setFloat32(offset + 36, matrix.storage[9], Endian.host);
  data.setFloat32(offset + 40, matrix.storage[10], Endian.host);
  data.setFloat32(offset + 44, matrix.storage[11], Endian.host);
  data.setFloat32(offset + 48, matrix.storage[12], Endian.host);
  data.setFloat32(offset + 52, matrix.storage[13], Endian.host);
  data.setFloat32(offset + 56, matrix.storage[14], Endian.host);
  data.setFloat32(offset + 60, matrix.storage[15], Endian.host);

  return offset + 64;
}
