inline uint64_t SobolIntervalToIndex(uint32_t m, uint64_t frame, Point2i p) {
    if (m == 0)
        return frame;

    const uint32_t m2 = m << 1;
    uint64_t index = uint64_t(frame) << m2;

    uint64_t delta = 0;
    for (int c = 0; frame; frame >>= 1, ++c)
        if (frame & 1)  // Add flipped column m + c + 1.
            delta ^= VdCSobolMatrices[m - 1][c];

    // flipped b
    uint64_t b = (((uint64_t)((uint32_t)p.x) << m) | ((uint32_t)p.y)) ^ delta;

    for (int c = 0; b; b >>= 1, ++c)
        if (b & 1)  // Add column 2 * m - c.
            index ^= VdCSobolMatricesInv[m - 1][c];

    return index;
}
