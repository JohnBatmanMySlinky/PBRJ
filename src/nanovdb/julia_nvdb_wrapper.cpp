#include "IO.h"
#include "NanoVDB.h"

#include <random>
#include <string>
#include <iostream>
#include <fstream>

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

nanovdb::Vec3d operator*(nanovdb::Vec3d a, float b){
    return nanovdb::Vec3d(a[0] * b, a[1] * b, a[2] * b);
}

nanovdb::Coord at(nanovdb::Vec3d rayo, nanovdb::Vec3d rayd, float t){
    nanovdb::Vec3d tmp = rayo + (rayd * t);
    return nanovdb::Coord(tmp[0], tmp[1], tmp[2]);
}

    

class NanoVDBWrapper {
    public:
        NanoVDBWrapper(const std::string& fpath) : fpath(fpath) {}
        ~NanoVDBWrapper() {
            std::cout << "OOPS\n";
        }
        std::tuple<float, float, float, float, float, float> get_WorldBBox() {
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* densityFloatGrid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            const nanovdb::BBox<nanovdb::Vec3d> box = densityFloatGrid->worldBBox();
            nanovdb::Vec3 mi = box.min();
            nanovdb::Vec3 ma = box.max();
            return {mi[0], mi[1], mi[2], ma[0], ma[1], ma[2]};
        }
        std::tuple<float, float> get_extrema() {
            float minDensity, maxDensity;
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* densityFloatGrid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            densityFloatGrid->tree().extrema(minDensity, maxDensity);
            return {minDensity, maxDensity};
        }
        std::tuple<bool, double> sample_NanoVDBWrapper(
            double t,
            double tmax,
            double inv_max_density,
            double sigma_t,
            double rayox,
            double rayoy,
            double rayoz,
            double raydx,
            double raydy,
            double raydz) {
                auto handle = nanovdb::io::readGrid("/home/jmyslinski/random_stuff/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"); // reads first grid from file
                auto* densityFloatGrid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
                nanovdb::Vec3d rayo = nanovdb::Vec3d(rayox, rayoy, rayoz);
                nanovdb::Vec3d rayd = nanovdb::Vec3d(raydx, raydy, raydz);
                // random number stuff
                std::random_device rd;  // Will be used to obtain a seed for the random number engine
                std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
                std::uniform_real_distribution<> dis(0.0, 1.0); // Define the range [0, 1)
                std::cout << "Ray: " << rayo << " : " << rayd << std::endl;
                std::cout << "\tInverseDensity " << inv_max_density << ", sigma_t: " << sigma_t << std::endl;


                // accessor
                auto acc = densityFloatGrid->getAccessor();
                // double adj = tmax - t;
                // int CAP = 100000;
                // int i = 0;

                for (int i=0; i<5; i++) {
                    // i += 1;
                    // if (i > CAP){
                    //     return {true, t};
                    // }
                    // t =- std::log(1.0 - dis(gen)) * inv_max_density / sigma_t;
                    t -= std::log(1.0 - 0.5) * inv_max_density / sigma_t;
                    if (t > tmax) {
                        return {true, t};
                    }
                    nanovdb::Coord coord = at(rayo, rayd, t);
                    float density_value = acc.getValue(coord);
                    std::cout << "Density at " << coord << " at " << t << " is " << density_value << std::endl;
                    if (density_value * inv_max_density > dis(gen)) {
                        return {false, t};
                    }
                }
                return {true, t};
        }
        double transmittance_NanoVDBWrapper(
            double t,
            double tmax,
            double inv_max_density,
            double sigma_t,
            double rayox,
            double rayoy,
            double rayoz,
            double raydx,
            double raydy,
            double raydz) {
                auto handle = nanovdb::io::readGrid("/home/jmyslinski/random_stuff/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"); // reads first grid from file
                auto* densityFloatGrid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
                nanovdb::Vec3d rayo = nanovdb::Vec3d(rayox, rayoy, rayoz);
                nanovdb::Vec3d rayd = nanovdb::Vec3d(raydx, raydy, raydz);
                double Tr = 1.0;

                // random number stuff
                std::random_device rd;  // Will be used to obtain a seed for the random number engine
                std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
                std::uniform_real_distribution<> dis(0.0, 1.0); // Define the range [0, 1)


                // accessor
                auto acc = densityFloatGrid->getAccessor();
                // double adj = tmax - t;
                // int CAP = 100000;
                // int i = 0;

                while (true) {
                    // i += 1;
                    // if (i > CAP){
                    //     return Tr;
                    // }
                    t -= std::log(1.0 - dis(gen)) * inv_max_density / sigma_t;
                    if (t >= tmax) {
                        return Tr;
                    }
                    nanovdb::Coord coord = at(rayo, rayd, t);
                    double density_value = acc.getValue(coord);
                    Tr *= 1.0 - std::max(0.0, density_value * inv_max_density);
                    double rr_threshold = 0.1;
                    if (Tr < rr_threshold) {
                        double q = std::max(0.05, 1.0 - Tr);
                        if (dis(gen) < q) {
                            return 0.0;
                        }
                        Tr /= (1.0 - q);
                    }
                }
                return Tr;
            }
    private:
        const std::string& fpath;
};

int grid_to_unit(const std::string& in_path, const std::string& out_path, int steps){
	// open grid
	// auto handle = nanovdb::io::readGrid("/Users/jmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb");
    auto handle = nanovdb::io::readGrid(in_path);
	auto* grid = handle.grid<float>();
    auto acc = grid->getAccessor();

	// open out file
	std::ofstream outFile(out_path);
    outFile << std::fixed;

	// get world bounds
	const nanovdb::BBox<nanovdb::Vec3d> box = grid->worldBBox();

	// calc step size
	float ma, mi, stepsize;
	ma = std::max({box.max()[0], box.max()[1], box.max()[2]});
	mi = std::min({box.min()[0], box.min()[1], box.min()[2]});
	stepsize = (ma - mi) / (float)steps;

	// iterate over 'voxels'
	for (int z=0; z<steps; z++){
		for (int y=0; y<steps; y++){
			for (int x=0; x<steps; x++){
				nanovdb::Coord coord = nanovdb::Coord(
                    mi + (x * stepsize), 
                    mi + (y * stepsize), 
                    mi + (z * stepsize)
                );
                double density_value = acc.getValue(coord);
                outFile << density_value << " ";
			}
		}
	}

	// close file
	outFile.close();

	// boop
	std::cout << "boop\n";
	return 0;
}


NanoVDBWrapper make_NanoVDBWrapper(const std::string& fpath) {
    // auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
    // auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
    return NanoVDBWrapper(fpath); // return a John object
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.method("grid_to_unit", &grid_to_unit);

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
        .method("get_WorldBBox", &NanoVDBWrapper::get_WorldBBox)
        .method("get_extrema", &NanoVDBWrapper::get_extrema)
        .method("sample_NanoVDBWrapper", &NanoVDBWrapper::sample_NanoVDBWrapper)
        .method("transmittance_NanoVDBWrapper", &NanoVDBWrapper::transmittance_NanoVDBWrapper);

    mod.method("make_NanoVDBWrapper", &make_NanoVDBWrapper);
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