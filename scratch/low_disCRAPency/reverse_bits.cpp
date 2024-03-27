// Online C++ compiler to run C++ program online
#include <iostream>

inline uint32_t ReverseBits32(uint32_t n) {
    n = (n << 16) | (n >> 16);
    n = ((n & 0x00ff00ff) << 8) | ((n & 0xff00ff00) >> 8);
    n = ((n & 0x0f0f0f0f) << 4) | ((n & 0xf0f0f0f0) >> 4);
    n = ((n & 0x33333333) << 2) | ((n & 0xcccccccc) >> 2);
    n = ((n & 0x55555555) << 1) | ((n & 0xaaaaaaaa) >> 1);
    return n;
}

int main() {
    // Write C++ code here
    uint32_t john = 8;
    std::cout << ReverseBits32(john) << "\n"; // 268435456
    uint32_t lana = 1944;
    std::cout << ReverseBits32(lana) << "\n"; // 434110464
    return 0;
}