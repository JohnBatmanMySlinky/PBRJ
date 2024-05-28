#include "IO.h"
#include "NanoVDB.h"

#include <random>
#include <string>

#include "jlcxx/jlcxx.hpp"

// struct World
// {
//   World(const std::string& message = "default hello") : msg(message){}
//   World(jlcxx::cxxint_t) : msg("NumberedWorld") {}
//   void set(const std::string& msg) { this->msg = msg; }
//   const std::string& greet() const { return msg; }
//   std::string msg;
//   ~World() { std::cout << "Destroying World with message " << msg << std::endl; }
// };

// nanovdb::DefaultReadAccessor<float> get_accessor_pls(const std::string& fpath)
// {
//     auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
//     auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
//     if (!grid)
//         throw std::runtime_error("File did not contain a grid with value type float");
//     auto acc = grid->getAccessor(); // create an accessor for fast access to multiple values
//     return acc;
// }

// std::tuple<float, float> get_extrema(const std::string& fpath)
// std::tuple<float, float> get_extrema(const std::string& fpath)
// {
//     auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
//     auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
//     float minDensity, maxDensity;
//     grid->tree().extrema(minDensity, maxDensity);
//     return {minDensity, maxDensity};
// }

// const nanovdb::BBox<nanovdb::Vec3d> get_bbox(const std::string& fpath)
// {
//     auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
//     auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
//     return grid->worldBBox();
// }

// float get_value_pls(nanovdb::DefaultReadAccessor<float> accessor, nanovdb::Coord coord)
// {
//     return accessor.getValue(coord);
// }

// std::tuple<double, double, double> get_bbox_min(nanovdb::BBox<nanovdb::Vec3d> box)
// {
//     nanovdb::Vec3 m = box.min();
//     return {m[0], m[1], m[2]};
// }
// std::tuple<double, double, double> get_bbox_max(nanovdb::BBox<nanovdb::Vec3d> box)
// {
//     nanovdb::Vec3 m = box.max(); 
//     return {m[0], m[1], m[2]};
// }

// aight what if i create a dumy class

float at(nanovdb::Vec3d rayo, nanovdb::Vec3d rayd, float t){
    return rayo + (rayd * t);
}

class NanoVDBWrapper {
    public:
        NanoVDBWrapper(nanovdb::FloatGrid* densityFloatGrid) : densityFloatGrid(densityFloatGrid) {}
        ~NanoVDBWrapper() {
            std::cout << "OOPS\n";
        }
        std::tuple<float, float, float, float, float, float> get_WorldBBox() {
            const nanovdb::BBox<nanovdb::Vec3d> box = densityFloatGrid->worldBBox();
            nanovdb::Vec3 mi = box.min();
            nanovdb::Vec3 ma = box.max();
            return {mi[0], mi[1], mi[2], ma[0], ma[1], ma[2]};
        }
        std::tuple<float, float> get_extrema() {
            float minDensity, maxDensity;
            densityFloatGrid->tree().extrema(minDensity, maxDensity);
            return {minDensity, maxDensity};
        }
        std::tuple<bool, float> sample_NanoVDBWrapper(
            float t, 
            float tmax, 
            float inv_max_density, 
            float sigma_t, 
            nanovdb::Vec3d rayo, 
            nanovdb::Vec3d rayd) {
                // random number stuff
                std::random_device rd;  // Will be used to obtain a seed for the random number engine
                std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
                std::uniform_real_distribution<> dis(0.0, 1.0); // Define the range [0, 1)

                // accessor
                auto acc = densityFloatGrid->getAccessor();

                while true {
                    t =- std::log(1.0 - dis(gen)) * inv_max_density / sigma_t;
                    if t > tmax {
                        return {true, t};
                    }
                    nanovdb::Coord coord = at(rayo, rayd, t);
                    float density_value = acc.getValue(coord);
                    if densit_value * inv_max_density > dis(gen) {
                        return {false, t}
                    }
                }
        }
        float transmittance_NanoVDBWrapper(
            float t,
            float tmax,
            float inv_max_density,
            float sigma_t,
            nanovdb::Vec3d rayo,
            nanovdb::Vec3d rayd) {
                float Tr = 1.0;

                // random number stuff
                std::random_device rd;  // Will be used to obtain a seed for the random number engine
                std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
                std::uniform_real_distribution<> dis(0.0, 1.0); // Define the range [0, 1)


                // accessor
                auto acc = densityFloatGrid->getAccessor();

                while true {
                    t -= std::log(1.0 - dis(gen)) * inv_max_density / sigma_t;
                    if t >= tmax {
                        return {true, Tr}
                    }
                    nanovdb::Coord coord = at(rayo, rayd, t);
                    float density_value = acc.getValue(coord);
                    Tr *= 1.0 - max(0.0, density_value * inv_max_density);
                    float rr_threshold = 0.1;
                    if Tr < rr_threshold {
                        q = std::max(0.05, 1.0 - Tr)
                        if dis(gen) < q {
                            return {false, 0.0}
                        }
                        Tr /= (1.0 - q)
                    }
                }
            }
    private:
        const nanovdb::FloatGrid* densityFloatGrid = nullptr;
};

NanoVDBWrapper make_NanoVDBWrapper(const std::string& fpath) {
    auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
    auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
    return NanoVDBWrapper(grid); // return a John object
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{

    mod.add_type<nanovdb::BBox<nanovdb::Vec3d>>("BBox");
        // .method("get_bbox", &get_bbox)
        // .method("get_bbox_max", &get_bbox_max)
        // .method("get_bbox_min", &get_bbox_min);

    mod.add_type<nanovdb::Coord>("Coord")
        .constructor<int32_t>()
        .constructor<int32_t, int32_t, int32_t>()
        .method("x", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::x)
        .method("y", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::y)
        .method("z", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::z);

    // mod.add_type<nanovdb::DefaultReadAccessor<float>>("DefaultReadAccessor")
    //     .method("get_accessor_pls", &get_accessor_pls)
    //     .method("get_value_pls", &get_value_pls)
    //     .method("get_extrema", &get_extrema);


    mod.add_type<NanoVDBWrapper>("NanoVDBWrapper")
        .method("make_NanoVDBWrapper", &make_NanoVDBWrapper)
        .method("get_WorldBBox", &NanoVDBWrapper::get_WorldBBox)
        .method("get_extrema", &NanoVDBWrapper::get_extrema);


//   mod.add_type<World>("World")
//     .constructor<const std::string&>()
//     // .constructor<jlcxx::cxxint_t>(jlcxx::finalize_policy::no) // no finalizer
//     .constructor([] (const std::string& a, const std::string& b) { return new World(a + " " + b); })
//     .method("set", &World::set)
//     .method("greet_cref", &World::greet)
//     .method("greet_lambda", [] (const World& w) { return w.greet(); } )
//     .method("greet_byvalue", [] (World w) { return w.greet(); } );


// std::string greet_overload(World& w) { return w.msg + "_byref"; }
// std::string greet_overload(const World& w) { return w.msg + "_byconstref"; }
// std::string greet_overload(World* w) { return w->msg + "_bypointer"; }
// std::string greet_overload(const World* w) { return w->msg + "_byconstpointer"; }
// std::string greet_overload(const std::shared_ptr<World> w) { return w->msg + "_bysharedptr"; }

//   types.method("greet_overload", static_cast<std::string (*) (World&)>(greet_overload));
//   types.method("greet_overload", static_cast<std::string (*) (const World&)>(greet_overload));
//   types.method("greet_overload", static_cast<std::string (*) (World*)>(greet_overload));
//   types.method("greet_overload", static_cast<std::string (*) (const World*)>(greet_overload));
//   types.method("greet_overload", static_cast<std::string (*) (std::shared_ptr<World>)>(greet_overload));

}