# Ray-Triangle Intersection Testing

Inspired by the work [here](https://github.com/johnnovak/raytriangle-test)

Initially I was getting like 2.5M intersections / second on 10M test cases. The one (three) weird trick(s) for a ~5x speed up were

1) When I permute the triangle vertices, use an `SVector` as the permutation index, not a plain `Vector`. Aka
```{julia}
permute = [kx, ky, kz]
d = ray.direction[permute]
p0t = p0t[permute]
```
to 
```{julia}
permute = SVector(kx, ky, kz)
d = ray.direction[permute]
p0t = p0t[permute]
```
2) and having `get_vertices` (and the sister normal and uv functions) NOT use list comprehension and instead return a tuple of the `Pnt3`. Again seems that avoid `Vector` is a winning strategy

3) `@inline`'ing the `get_vertices` (and friends) gave a very slight increase. 

## Current results are as follows. 

idx | function | number of tests | total run time | M intersections / s | % hits
--- | --- | --- | --- | -- | ---
1 | `intersect_p()` | 100,000 | 4ms | 25.0 | 8.7%
2 | `intersect_p()` | 1,000,000 | 43ms | 23.3 | 8.6%
3 | `intersect_p()` | 10,000,000 | 854ms | 11.7 | 9.5%
4 | `intersect_p()` | 100,000,000 | 9,555ms | 10.5 | 8.9%
5 | `intersect()` | 100,000 | 5ms | 20.0 | 8.7%
6 | `intersect()` | 1,000,000 | 64ms | 15.6 | 8.6%
7 | `intersect()` | 10,000,000 | 1,220ms | 8.2 | 9.5%
8 | `intersect()` | 100,000,000 | 13,726ms | 7.3 | 8.9%

If we benchmarking with the Cornell Box scene, results are as follows
```
julia -t 4 RayTracing.jl --scene-number 4
```
- 256 tiles
- 4 spp
- uniform light sampling strategy
- cornell box

```
24.966179 seconds (224.37 M allocations: 14.531 GiB, 22.86% gc time, 43.12% compilation time)
21.841606 seconds (168.57 M allocations: 9.761 GiB, 18.69% gc time, 49.95% compilation time)
```

Yielding a 13% decrease in run time, 25% decrease in peak allocations, and 33% reduction in cumulative allocations.

## Current thoughts
- My implementation isn't M-T, so that's not apples to apples.
- I have some slight additional overhead in my Triangle implementation. (I could be wrong.) More not apples to apples.
- I think I have some performance to squeeze out of `intersect()`
- Why does my rate of intersection slow down so much betwen 10M and 100M? Also the hit % changes, that is suspicious.
- Comparing to the benchmark linked at the top, I can get almost 50% the performance of C++. That's not bad! I should be able to get closer though? Happy to be 2x Java.