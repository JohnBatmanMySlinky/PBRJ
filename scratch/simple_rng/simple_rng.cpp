#include "iostream"
#include "iomanip"
#include "cmath"
 
long lcg(long start, long a, long c, long m) {
    // remembering LCG ranges returns a long in [0,m]
    return ((a * start) + c) % m;
}
 
int main(void) {
    long seed = 15;
    long a = 75;
    long c = 74;
    long m = pow(2,16)+1;
    for (int i = 0; i < 10; i++){
        seed = lcg(seed, a, c, m);
        std::cout << "Random Number " << i+1 << ": " << (double)seed/m << "\n";
    }
    return 0;
}