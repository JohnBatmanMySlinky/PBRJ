#include <iostream>
#include <vector> 

template <typename T>
class Point2 {
  public:
    // Point2 Public Methods
    // explicit Point2(const Point3<T> &p) : x(p.x), y(p.y) { DCHECK(!HasNaNs()); }
    Point2() { x = y = 0; }
    Point2(T xx, T yy) : x(xx), y(yy) { 
        // DCHECK(!HasNaNs()); 
    }

    template <typename U>
    explicit Point2(const Point2<U> &p) {
        x = (T)p.x;
        y = (T)p.y;
        // DCHECK(!HasNaNs());
    }

    // template <typename U>
    // explicit Point2(const Vector2<U> &p) {
    //     x = (T)p.x;
    //     y = (T)p.y;
    //     DCHECK(!HasNaNs());
    // }

    // template <typename U>
    // explicit operator Vector2<U>() const {
    //     return Vector2<U>(x, y);
    // }

#ifndef NDEBUG
    Point2(const Point2<T> &p) {
        // DCHECK(!p.HasNaNs());
        x = p.x;
        y = p.y;
    }

    Point2<T> &operator=(const Point2<T> &p) {
        // DCHECK(!p.HasNaNs());
        x = p.x;
        y = p.y;
        return *this;
    }
#endif  // !NDEBUG
    // Point2<T> operator+(const Vector2<T> &v) const {
    //     DCHECK(!v.HasNaNs());
    //     return Point2<T>(x + v.x, y + v.y);
    // }

    // Point2<T> &operator+=(const Vector2<T> &v) {
    //     DCHECK(!v.HasNaNs());
    //     x += v.x;
    //     y += v.y;
    //     return *this;
    // }
    // Vector2<T> operator-(const Point2<T> &p) const {
    //     DCHECK(!p.HasNaNs());
    //     return Vector2<T>(x - p.x, y - p.y);
    // }

    // Point2<T> operator-(const Vector2<T> &v) const {
    //     DCHECK(!v.HasNaNs());
    //     return Point2<T>(x - v.x, y - v.y);
    // }
    Point2<T> operator-() const { return Point2<T>(-x, -y); }
    // Point2<T> &operator-=(const Vector2<T> &v) {
    //     DCHECK(!v.HasNaNs());
    //     x -= v.x;
    //     y -= v.y;
    //     return *this;
    // }
    Point2<T> &operator+=(const Point2<T> &p) {
        // DCHECK(!p.HasNaNs());
        x += p.x;
        y += p.y;
        return *this;
    }
    Point2<T> operator+(const Point2<T> &p) const {
        // DCHECK(!p.HasNaNs());
        return Point2<T>(x + p.x, y + p.y);
    }
    template <typename U>
    Point2<T> operator*(U f) const {
        return Point2<T>(f * x, f * y);
    }
    template <typename U>
    Point2<T> &operator*=(U f) {
        x *= f;
        y *= f;
        return *this;
    }
    template <typename U>
    Point2<T> operator/(U f) const {
        // CHECK_NE(f, 0);
        float inv = (float)1 / f;
        return Point2<T>(inv * x, inv * y);
    }
    template <typename U>
    Point2<T> &operator/=(U f) {
        // CHECK_NE(f, 0);
        float inv = (float)1 / f;
        x *= inv;
        y *= inv;
        return *this;
    }
    T operator[](int i) const {
        // DCHECK(i >= 0 && i <= 1);
        if (i == 0) return x;
        return y;
    }

    T &operator[](int i) {
        // DCHECK(i >= 0 && i <= 1);
        if (i == 0) return x;
        return y;
    }
    bool operator==(const Point2<T> &p) const { return x == p.x && y == p.y; }
    bool operator!=(const Point2<T> &p) const { return x != p.x || y != p.y; }
    bool HasNaNs() const { return isNaN(x) || isNaN(y); }

    // Point2 Public Data
    T x, y;
};

typedef Point2<float> Point2f;

template <typename T, typename U, typename V>
inline T Clamp(T val, U low, V high) {
    if (val < low)
        return low;
    else if (val > high)
        return high;
    else
        return val;
}

template <typename Predicate>
int FindInterval(int size, const Predicate &pred) {
    int first = 0, len = size;
    while (len > 0) {
        int half = len >> 1, middle = first + half;
        // Bisect range based on value of _pred_ at _middle_
        if (pred(middle)) {
            first = middle + 1;
            len -= half + 1;
        } else
            len = half;
    }
    return Clamp(first - 1, 0, size - 2);
}

struct Distribution1D {
    // Distribution1D Public Methods
    Distribution1D(const float *f, int n) : func(f, f + n), cdf(n + 1) {
        // Compute integral of step function at $x_i$
        cdf[0] = 0;
        for (int i = 1; i < n + 1; ++i) {
            cdf[i] = cdf[i - 1] + func[i - 1] / n;
            std::cout << func[i - 1] << " ";
        }
        std::cout << "\n\n";

        // Transform step function integral into CDF
        funcInt = cdf[n];
        if (funcInt == 0) {
            for (int i = 1; i < n + 1; ++i) cdf[i] = float(i) / float(n);
        } else {
            for (int i = 1; i < n + 1; ++i) cdf[i] /= funcInt;
        }
    }
    int Count() const { return (int)func.size(); }
    float SampleContinuous(float u, float *pdf, int *off = nullptr) const {
        // Find surrounding CDF segments and _offset_
        int offset = FindInterval((int)cdf.size(), [&](int index) { return cdf[index] <= u; });
        if (off) *off = offset;
        // Compute offset along CDF segment
        float du = u - cdf[offset];
        if ((cdf[offset + 1] - cdf[offset]) > 0) {
            du /= (cdf[offset + 1] - cdf[offset]);
        }

        // Compute PDF for sampled offset
        if (pdf) *pdf = (funcInt > 0) ? func[offset] / funcInt : 0;

        // Return $x\in{}[0,1)$ corresponding to sample
        return (offset + du) / Count();
    }
    int SampleDiscrete(float u, float *pdf = nullptr,
                       float *uRemapped = nullptr) const {
        // Find surrounding CDF segments and _offset_
        int offset = FindInterval((int)cdf.size(), [&](int index) { return cdf[index] <= u; });
        if (pdf) *pdf = (funcInt > 0) ? func[offset] / (funcInt * Count()) : 0;
        if (uRemapped)
            *uRemapped = (u - cdf[offset]) / (cdf[offset + 1] - cdf[offset]);
        // if (uRemapped) CHECK(*uRemapped >= 0.f && *uRemapped <= 1.f);
        return offset;
    }
    float DiscretePDF(int index) const {
        return func[index] / (funcInt * Count());
    }

    // Distribution1D Public Data
    std::vector<float> func, cdf;
    float funcInt;
};

class Distribution2D {
  public:
    // Distribution2D Public Methods
    Distribution2D(const float *data, int nu, int nv);
    Point2f SampleContinuous(const Point2f &u, float *pdf) const {
        float pdfs[2];
        int v;
        float d1 = pMarginal->SampleContinuous(u[1], &pdfs[1], &v);
        std::cout << "\tpMarginal " << d1 << "\n";
        float d0 = pConditionalV[v]->SampleContinuous(u[0], &pdfs[0]);
        std::cout << "\tpConditionalV " << d0 << "\n";
        *pdf = pdfs[0] * pdfs[1];
        return Point2f(d0, d1);
    }
    float Pdf(const Point2f &p) const {
        int iu = Clamp(int(p[0] * pConditionalV[0]->Count()), 0,
                       pConditionalV[0]->Count() - 1);
        int iv =
            Clamp(int(p[1] * pMarginal->Count()), 0, pMarginal->Count() - 1);
        return pConditionalV[iv]->func[iu] / pMarginal->funcInt;
    }

  private:
    // Distribution2D Private Data
    std::vector<std::unique_ptr<Distribution1D>> pConditionalV;
    std::unique_ptr<Distribution1D> pMarginal;
};

Distribution2D::Distribution2D(const float *func, int nu, int nv) {
    pConditionalV.reserve(nv);
    for (int v = 0; v < nv; ++v) {
        // Compute conditional sampling distribution for $\tilde{v}$
        // std::cout << "\t\tBUILD CONDITIONAL: " << v << ": " << &func[v * nu] << "\n";
        pConditionalV.emplace_back(new Distribution1D(&func[v * nu], nu));
    }
    // Compute marginal sampling distribution $p[\tilde{v}]$
    std::vector<float> marginalFunc;
    marginalFunc.reserve(nv);
    for (int v = 0; v < nv; ++v)
        marginalFunc.push_back(pConditionalV[v]->funcInt);
    pMarginal.reset(new Distribution1D(&marginalFunc[0], nv));
}

int main()
{
    // from tests/sampling.cpp
    // float func[4] = {0, 1., 0., 3.};
    // Distribution1D dist(func, sizeof(func) / sizeof(func[0]));
    // float pdf_val;
    // int offset;
    // float val = dist.SampleContinuous(0.75, &pdf_val, &offset);
    // std::cout << val << " " << pdf_val << " " << offset << "\n";



    float ugh[77] = {4.0, 5.0, 4.0, 3.0, 3.0, 4.0, 1.0,
        3.0, 1.0, 7.0, 6.0, 3.0, 5.0, 2.0,
        1.0, 7.0, 7.0, 7.0, 4.0, 7.0, 1.0,
        0.0, 8.0, 9.0, 13.0, 9.0, 7.0, 1.0,
        5.0, 7.0, 10.0, 13.0, 9.0, 5.0, 0.0,
        0.0, 5.0, 12.0, 15.0, 15.0, 9.0, 1.0,
        1.0, 7.0, 12.0, 15.0, 11.0, 4.0, 2.0,
        1.0, 4.0, 7.0, 9.0, 6.0, 7.0, 4.0,
        0.0, 5.0, 5.0, 11.0, 8.0, 5.0, 1.0,
        4.0, 2.0, 6.0, 4.0, 2.0, 5.0, 4.0,
        4.0, 3.0, 5.0, 3.0, 3.0, 0.0, 5.0
    };
    Distribution2D dist2(ugh, 11, 7);
    float pdf_val2;
    Point2f val2 = dist2.SampleContinuous(Point2f(0.4f, 0.6f), &pdf_val2);
    std::cout << "(" << val2.x << ", " << val2.y << ") - " << pdf_val2 << "\n";

    return 0;
}
