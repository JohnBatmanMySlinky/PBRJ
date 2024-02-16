# PBRT_CPU_GPU inline Float RadicalInverse(int baseIndex, uint64_t a) {
#     unsigned int base = Primes[baseIndex];
#     // We have to stop once reversedDigits is >= limit since otherwise the
#     // next digit of |a| may cause reversedDigits to overflow.
#     uint64_t limit = ~0ull / base - base;
#     Float invBase = (Float)1 / (Float)base, invBaseM = 1;
#     uint64_t reversedDigits = 0;
#     while (a && reversedDigits < limit) {
#         // Extract least significant digit from _a_ and update _reversedDigits_
#         uint64_t next = a / base;
#         uint64_t digit = a - next * base;
#         reversedDigits = reversedDigits * base + digit;
#         invBaseM *= invBase;
#         a = next;
#     }
#     return std::min(reversedDigits * invBaseM, OneMinusEpsilon);
# }