#include "IO.h"
#include "NanoVDB.h"

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

#include "IO.h" // this is required to read (and write) NanoVDB files on the host
/// @note Note This example does NOT depend on OpenVDB (nor CUDA), only NanoVDB.
nanovdb::GridHandle<nanovdb::HostBuffer> get_gridhandle_pls(const std::string& fpath)
{
    auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
    // auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
    // if (!grid)
    //     throw std::runtime_error("File did not contain a grid with value type float");
    // auto acc = grid->getAccessor(); // create an accessor for fast access to multiple values
    // return acc;
    return handle;
}

const nanovdb::BBox<nanovdb::Vec3d> get_bbox(const std::string& fpath)
{
    auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
    auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
    return grid->worldBBox();
}

float get_value_pls(nanovdb::DefaultReadAccessor<float> accessor, nanovdb::Coord coord)
{
    return accessor.getValue(coord);
}

std::tuple<double, double, double> get_bbox_min(nanovdb::BBox<nanovdb::Vec3d> box)
{
    nanovdb::Vec3 m = box.min();
    return {m[0], m[1], m[2]};
}
std::tuple<double, double, double> get_bbox_max(nanovdb::BBox<nanovdb::Vec3d> box)
{
    nanovdb::Vec3 m = box.max(); 
    return {m[0], m[1], m[2]};
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<nanovdb::GridHandle<nanovdb::HostBuffer>>("GridHandle");

    mod.add_type<nanovdb::BBox<nanovdb::Vec3d>>("BBox")
        .method("get_bbox", &get_bbox)
        .method("get_bbox_max", &get_bbox_max)
        .method("get_bbox_min", &get_bbox_min);

    mod.add_type<nanovdb::Coord>("Coord")
        .constructor<int32_t>()
        .constructor<int32_t, int32_t, int32_t>()
        .method("x", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::x)
        .method("y", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::y)
        .method("z", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::z);

    mod.add_type<nanovdb::DefaultReadAccessor<float>>("DefaultReadAccessor")
        .method("get_gridhandle_pls", &get_gridhandle_pls)
        .method("get_value_pls", &get_value_pls);


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