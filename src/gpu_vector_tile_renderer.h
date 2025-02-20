#include <stdint.h>

#define FLUTTER_EXPORT __attribute__((__visibility__("default"))) __attribute__((__used__))

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

struct point {
  double x;
  double y;
};

struct ring {
  struct point* points;
  uint32_t count;
};

struct polygon {
  struct ring exterior;
  struct ring* interiors;
  uint32_t interior_count;
};

struct tessellation_result {
  uint32_t* indices;
  uint32_t count;
};


EXTERNC struct tessellation_result* FLUTTER_EXPORT tessellate_polygon(struct polygon* poly);
EXTERNC void FLUTTER_EXPORT free_tessellation_result(struct tessellation_result* result);

#undef EXTERNC