#include <iostream>
#include <cmath>

template <typename T>
inline bool isNaN(const T x) {
    return std::isnan(x);
}

template <typename T>
class Vector3 {
  public:
    // Vector3 Public Methods
    T operator[](int i) const {
        if (i == 0) return x;
        if (i == 1) return y;
        return z;
    }
    T &operator[](int i) {
        if (i == 0) return x;
        if (i == 1) return y;
        return z;
    }
    Vector3() { x = y = z = 0; }
    Vector3(T x, T y, T z) : x(x), y(y), z(z) { !HasNaNs(); }
    bool HasNaNs() const { return isNaN(x) || isNaN(y) || isNaN(z); }
#ifndef NDEBUG
    // The default versions of these are fine for release builds; for debug
    // we define them so that we can add the Assert checks.
    Vector3(const Vector3<T> &v) {
        x = v.x;
        y = v.y;
        z = v.z;
    }

    Vector3<T> &operator=(const Vector3<T> &v) {
        x = v.x;
        y = v.y;
        z = v.z;
        return *this;
    }
#endif  // !NDEBUG
    Vector3<T> operator+(const Vector3<T> &v) const {
        return Vector3(x + v.x, y + v.y, z + v.z);
    }
    Vector3<T> &operator+=(const Vector3<T> &v) {
        x += v.x;
        y += v.y;
        z += v.z;
        return *this;
    }
    Vector3<T> operator-(const Vector3<T> &v) const {
        return Vector3(x - v.x, y - v.y, z - v.z);
    }
    Vector3<T> &operator-=(const Vector3<T> &v) {
        x -= v.x;
        y -= v.y;
        z -= v.z;
        return *this;
    }
    bool operator==(const Vector3<T> &v) const {
        return x == v.x && y == v.y && z == v.z;
    }
    bool operator!=(const Vector3<T> &v) const {
        return x != v.x || y != v.y || z != v.z;
    }
    template <typename U>
    Vector3<T> operator*(U s) const {
        return Vector3<T>(s * x, s * y, s * z);
    }
    template <typename U>
    Vector3<T> &operator*=(U s) {
        x *= s;
        y *= s;
        z *= s;
        return *this;
    }
    template <typename U>
    Vector3<T> operator/(U f) const {
        float inv = (float)1 / f;
        return Vector3<T>(x * inv, y * inv, z * inv);
    }

    template <typename U>
    Vector3<T> &operator/=(U f) {
        float inv = (float)1 / f;
        x *= inv;
        y *= inv;
        z *= inv;
        return *this;
    }
    Vector3<T> operator-() const { return Vector3<T>(-x, -y, -z); }
    float LengthSquared() const { return x * x + y * y + z * z; }
    float Length() const { return std::sqrt(LengthSquared()); }

    // Vector3 Public Data
    T x, y, z;
};

template <typename T>
inline Vector3<T> Normalize(const Vector3<T> &v) {
    return v / v.Length();
}

typedef Vector3<float> Vector3f;

template <typename T, typename U, typename V>
constexpr T Clamp(T val, U low, V high) {
    if (val < low)       return T(low);
    else if (val > high) return T(high);
    else                 return val;
};

class OctahedralVector {
  public:
    // OctahedralVector Public Methods
    // OctahedralVector() = default;
    OctahedralVector(Vector3f v) {
        v /= std::abs(v.x) + std::abs(v.y) + std::abs(v.z);
        if (v.z >= 0) {
            x = Encode(v.x);
            y = Encode(v.y);
        } else {
            // Encode octahedral vector with $z < 0$
            x = Encode((1 - std::abs(v.y)) * Sign(v.x));
            y = Encode((1 - std::abs(v.x)) * Sign(v.y));
        }
    };

    Vector3f makevec3() const {
        Vector3f v;
        v.x = -1 + 2 * (x / 65535.f);
        v.y = -1 + 2 * (y / 65535.f);
        v.z = 1 - (std::abs(v.x) + std::abs(v.y));
        // Reparameterize directions in the $z<0$ portion of the octahedron
        if (v.z < 0) {
            float xo = v.x;
            v.x = (1 - std::abs(v.y)) * Sign(xo);
            v.y = (1 - std::abs(xo)) * Sign(v.y);
        }

        return Normalize(v);
    };

  private:
    // OctahedralVector Private Methods
    static float Sign(float v) { return std::copysign(1.f, v); }

    static uint16_t Encode(float f) {
        return std::round(Clamp((f + 1) / 2, 0, 1) * 65535.f);
    }

    // OctahedralVector Private Members
    uint16_t x, y;
};

int main() {
    // Write C++ code here
    Vector3f v;
    v = Vector3f(0.5, 0.6, 0.7);

    std::cout << "boop";

    return 0;
};