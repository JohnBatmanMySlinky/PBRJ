// Online C++ compiler to run C++ program online
#include <iostream>

static constexpr int PrimeTableSize = 17;
int Primes[PrimeTableSize] = {2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59};
float OneMinusEpsilon = float(0x1.fffffep-1);
float RadicalInverse(int baseIndex, uint64_t a) {
    unsigned int base = Primes[baseIndex];
    // We have to stop once reversedDigits is >= limit since otherwise the
    // next digit of |a| may cause reversedDigits to overflow.
    uint64_t limit = ~0ull / base - base;
    float invBase = (float)1 / (float)base, invBaseM = 1;
    uint64_t reversedDigits = 0;
    while (a && reversedDigits < limit) {
        // Extract least significant digit from _a_ and update _reversedDigits_
        uint64_t next = a / base;
        uint64_t digit = a - next * base;
        reversedDigits = reversedDigits * base + digit;
        invBaseM *= invBase;
        a = next;
    }
    return std::min(reversedDigits * invBaseM, OneMinusEpsilon);
}

int main() {
    // Write C++ code here
    std::cout <<  RadicalInverse(0,500);

    return 0;
}