from math import trunc
 
def lcg(seed, a, c, m):
    return (a * seed + c) % m
 
def main():
    seed = 15
    a = 75
    c = 74
    m = 2**16+1
 
    for i in range(10):
        seed = lcg(seed, a, c, m)
        print(f"Random Number {i+1}: {seed/m}")
    return None
 
if __name__ == "__main__":
    main()