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

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
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