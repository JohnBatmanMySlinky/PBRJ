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
nanovdb::DefaultReadAccessor<float> get_accessor_pls()
{
    auto handle = nanovdb::io::readGrid("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"); // reads first grid from file
    auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
    if (!grid)
        throw std::runtime_error("File did not contain a grid with value type float");
    auto acc = grid->getAccessor(); // create an accessor for fast access to multiple values
    return acc;
}

float get_value_pls(nanovdb::DefaultReadAccessor<float> acc)
{
    return acc.getValue(nanovdb::Coord(99, 0, 0));
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<nanovdb::DefaultReadAccessor<float>>("DefaultReadAccessor")
        .method("get_accessor_pls", &get_accessor_pls)
        .method("get_value_pls", &get_value_pls);

    mod.add_type<nanovdb::Coord>("Coord")
        .constructor<int32_t>()
        .constructor<int32_t, int32_t, int32_t>()
        .method("x", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::x)
        .method("y", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::y)
        .method("z", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::z);



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