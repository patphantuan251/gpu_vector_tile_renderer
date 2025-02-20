#include <gpu_vector_tile_renderer.h>
#include <mapbox/earcut.hpp>

extern "C" struct tessellation_result* tessellate_polygon(struct polygon* poly)
{
    using IndexType = uint32_t;
    using CoordType = double;

    std::vector<std::vector<std::array<CoordType, 2>>> polygonData;
    polygonData.reserve(poly->interior_count + 1);

    {
        std::vector<std::array<CoordType, 2>> ringCoords;
        ringCoords.reserve(poly->exterior.count);

        for (uint32_t i = 0; i < poly->exterior.count; i++) {
            ringCoords.push_back({ poly->exterior.points[i].x, poly->exterior.points[i].y });
        }

        polygonData.push_back(std::move(ringCoords));
    }

    for (uint32_t r = 0; r < poly->interior_count; r++) {
        std::vector<std::array<CoordType, 2>> ringCoords;
        ringCoords.reserve(poly->interiors[r].count);

        for (uint32_t i = 0; i < poly->interiors[r].count; i++) {
            ringCoords.push_back({ poly->interiors[r].points[i].x, poly->interiors[r].points[i].y });
        }

        polygonData.push_back(std::move(ringCoords));
    }

    auto indices = mapbox::earcut<IndexType>(polygonData);

    auto* resultPtr = new tessellation_result();

    resultPtr->count = indices.size();
    resultPtr->indices = new uint32_t[resultPtr->count];
    memcpy(resultPtr->indices, indices.data(), resultPtr->count * sizeof(uint32_t));

    return resultPtr;
}

extern "C" void free_tessellation_result(struct tessellation_result* result)
{
    if (result) {
        delete[] result->indices;
        delete result;
    }
}
