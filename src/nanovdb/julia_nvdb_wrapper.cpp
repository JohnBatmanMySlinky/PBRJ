#include "IO.h"
#include "NanoVDB.h"
#include "SampleFromVoxels.h"

#include <random>
#include <string>
#include <iostream>
#include <fstream>
#include <regex>

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

std::string getOS(){
#if defined(__MACH__) || defined(__APPLE__)
	return "macOS";
#elif defined(__unix__)
	return "Unix";
#else
	return "Windows";
#endif
}
std::string jmfp(const std::string& fp) {
	bool sys_apple = getOS() == "macOS";
	bool sys_linux = getOS() == "Unix";

	if (!(sys_apple || sys_linux)) {
		std::cerr << "get off windows" << std::endl;
		throw std::runtime_error("Unsupported OS");
	}

	bool fp_apple = fp.find("Users") != std::string::npos;
	bool fp_linux = fp.find("home") != std::string::npos;

	if (!(fp_apple || fp_linux)) {
		std::cerr << "bad input string in cpp" << std::endl;
		throw std::runtime_error("Bad input string");
	}
	
	std::string result_fp = fp;
	if (fp_apple && sys_linux) {
		result_fp = std::regex_replace(result_fp, std::regex("Users"), "home");
		result_fp = std::regex_replace(result_fp, std::regex("johnmyslinski"), "jmyslinski");
		result_fp = std::regex_replace(result_fp, std::regex("Documents"), "random_stuff"); 
	} else if (fp_linux && sys_apple) {
		result_fp = std::regex_replace(result_fp, std::regex("home"), "Users");
		result_fp = std::regex_replace(result_fp, std::regex("jmyslinski"), "johnmyslinski");
		result_fp = std::regex_replace(result_fp, std::regex("random_stuff"), "Documents");
	}
	return result_fp;
}

nanovdb::Vec3d operator*(nanovdb::Vec3d a, float b){
    return nanovdb::Vec3d(a[0] * b, a[1] * b, a[2] * b);
}

nanovdb::Vec3d at(nanovdb::Vec3d rayo, nanovdb::Vec3d rayd, float t){
    return rayo + (rayd * t);
}

float lerp(float t, float a, float b){
    return a + t * (b - a);
}

class NanoVDBWrapper {
    public:
        NanoVDBWrapper(const std::string& fpath) : fpath(fpath) {}
        ~NanoVDBWrapper() {
            std::cout << "NanoVDBWrapper - Destructed\n";
        }
        std::tuple<double, double, double> get_worldToIndexF(
            double x,
            double y,
            double z
        ){
            nanovdb::Vec3 xyz = nanovdb::Vec3(x, y, z);

            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            nanovdb::Vec3 i0 = grid->worldToIndexF(xyz);
            return {i0[0], i0[1], i0[2]};
        }
        std::tuple<float, float, float, float, float, float> get_indexBBox() {
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            const nanovdb::BBox<nanovdb::Vec3d> box = grid->indexBBox();
            nanovdb::Vec3 mi = box.min();
            nanovdb::Vec3 ma = box.max();
            return {mi[0], mi[1], mi[2], ma[0], ma[1], ma[2]};
        }
        float get_max_voxel_value(
            int nx0,
            int nx1,
            int ny0,
            int ny1,
            int nz0,
            int nz1
        ) {
            float maxValue = 0;

            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            auto accessor = grid->getAccessor();

            for (int nz = nz0; nz <= nz1; ++nz) {
                for (int ny = ny0; ny <= ny1; ++ny) {
                    for (int nx = nx0; nx <= nx1; ++nx) {
                        maxValue = std::max(maxValue, accessor.getValue({nx, ny, nz}));
                    }
                }
            }
            return maxValue;
        }
        std::tuple<float, float, float, float, float, float> get_WorldBBox() {
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            const nanovdb::BBox<nanovdb::Vec3d> box = grid->worldBBox();
            nanovdb::Vec3 mi = box.min();
            nanovdb::Vec3 ma = box.max();
            return {mi[0], mi[1], mi[2], ma[0], ma[1], ma[2]};
        }
        std::tuple<float, float> get_extrema() {
            float minDensity, maxDensity;
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            grid->tree().extrema(minDensity, maxDensity);
            return {minDensity, maxDensity};
        }
        float get_sampled_point(
            double x,
            double y,
            double z
        ) {
            // auto handle = nanovdb::io::readGrid(jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb")); // reads first grid from file
            // auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            nanovdb::Vec3<float> pIndex = densityFloatGrid->worldToIndexF(nanovdb::Vec3<float>(x, y, z));
            using Sampler = nanovdb::SampleFromVoxels<nanovdb::FloatGrid::TreeType, 1, false>;
            float d = Sampler(densityFloatGrid->tree())(pIndex);
            return d;
        }
        void init(){
            // auto handle = nanovdb::io::readGrid("/home/jmyslinski/random_stuff/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"); // reads first grid from file
            auto handle = nanovdb::io::readGrid(jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb")); // reads first grid from file                
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            densityFloatGrid = grid;
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
                nanovdb::Vec3d rayo = nanovdb::Vec3d(rayox, rayoy, rayoz);
                nanovdb::Vec3d rayd = nanovdb::Vec3d(raydx, raydy, raydz);
                // random number stuff
                std::random_device rd;  // Will be used to obtain a seed for the random number engine
                std::mt19937 gen(rd()); // Standard mersenne_twister_engine seeded with rd()
                std::uniform_real_distribution<> dis(0.0, 1.0); // Define the range [0, 1)
                // std::cout << "Ray: " << rayo << " : " << rayd << std::endl;
                // std::cout << "\tInverseDensity " << inv_max_density << ", sigma_t: " << sigma_t << std::endl;

                // accessor
                auto acc = densityFloatGrid->getAccessor();
                // double adj = tmax - t;
                int CAP = 1000000;
                int i = 0;

                while (true) {
                    i += 1;
                    if (i > CAP){
                        // std::cout << "   oopsie" << std::endl;
                        break;
                    }
                    t -= std::log(1.0 - dis(gen)) * inv_max_density / sigma_t;
                    // t -= std::log(1.0 - 0.5) * inv_max_density / sigma_t;
                    // std::cout << "medium sample: " << t << std::endl;
                    if (t > tmax) {
                        break;
                    }
                    // nanovdb::Vec3d p = at(rayo, rayd, t);
                    // nanovdb::Coord pfloor = nanovdb::Coord(p[0], p[1], p[2]);
                    // nanovdb::Vec3d delta = nanovdb::Vec3d(p[0] - pfloor[0], p[1] - pfloor[1], p[2] - pfloor[2]);
                    // float d00 = lerp(delta[0], acc.getValue(pfloor),                         acc.getValue(pfloor + nanovdb::Coord(1,0,0)));
                    // float d10 = lerp(delta[0], acc.getValue(pfloor + nanovdb::Coord(0,1,0)), acc.getValue(pfloor + nanovdb::Coord(1,1,0)));
                    // float d01 = lerp(delta[0], acc.getValue(pfloor + nanovdb::Coord(0,0,1)), acc.getValue(pfloor + nanovdb::Coord(1,0,1)));
                    // float d11 = lerp(delta[0], acc.getValue(pfloor + nanovdb::Coord(0,1,1)), acc.getValue(pfloor + nanovdb::Coord(1,1,1)));
                    // float d0 = lerp(delta[1], d00, d10);
                    // float d1 = lerp(delta[1], d01, d11);
                    // float density_value = lerp(delta[2], d0, d1);

                    nanovdb::Vec3d p = at(rayo, rayd, t);
                    nanovdb::Coord pfloor = nanovdb::Coord(p[0], p[1], p[2]);
                    double density_value = acc.getValue(pfloor);

                    // std::cout << "Density at " << coord << " at " << t << " is " << density_value << std::endl;
                    if (density_value * inv_max_density > dis(gen)) {
                        // std::cout << "Sampled Medium # times: " << i << std::endl;
                        return {false, t};
                    }
                }
                // std::cout << "Sampled Medium # times: " << i << std::endl;
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
                int CAP = 1000000;
                int i = 0;

                while (true) {
                    i += 1;
                    if (i > CAP){
                        // std::cout << "   oopsie" << std::endl;
                        break;
                    }
                    t -= std::log(1.0 - dis(gen)) * inv_max_density / sigma_t;
                    // t -= std::log(1.0 - 0.5) * inv_max_density / sigma_t;
                    if (t >= tmax) {
                        break;
                    }
                    // nanovdb::Vec3d p = at(rayo, rayd, t);
                    // nanovdb::Coord pfloor = nanovdb::Coord(p[0], p[1], p[2]);
                    // nanovdb::Vec3d delta = nanovdb::Vec3d(p[0] - pfloor[0], p[1] - pfloor[1], p[2] - pfloor[2]);
                    // float d00 = lerp(delta[0], acc.getValue(pfloor),                         acc.getValue(pfloor + nanovdb::Coord(1,0,0)));
                    // float d10 = lerp(delta[0], acc.getValue(pfloor + nanovdb::Coord(0,1,0)), acc.getValue(pfloor + nanovdb::Coord(1,1,0)));
                    // float d01 = lerp(delta[0], acc.getValue(pfloor + nanovdb::Coord(0,0,1)), acc.getValue(pfloor + nanovdb::Coord(1,0,1)));
                    // float d11 = lerp(delta[0], acc.getValue(pfloor + nanovdb::Coord(0,1,1)), acc.getValue(pfloor + nanovdb::Coord(1,1,1)));
                    // float d0 = lerp(delta[1], d00, d10);
                    // float d1 = lerp(delta[1], d01, d11);
                    // float density_value = lerp(delta[2], d0, d1);

                    nanovdb::Vec3d p = at(rayo, rayd, t);
                    nanovdb::Coord pfloor = nanovdb::Coord(p[0], p[1], p[2]);
                    double density_value = acc.getValue(pfloor);

                    Tr *= 1.0 - std::max(0.0, density_value * inv_max_density);
                    double rr_threshold = 0.1;
                    if (Tr < rr_threshold) {
                        double q = std::max(0.05, 1.0 - Tr);
                        if (dis(gen) < q) {
                            // std::cout << "Transmittance Medium # times: " << i << std::endl;
                            return 0.0;
                        }
                        Tr /= (1.0 - q);
                    }
                }
                // std::cout << "Transmittance Medium # times: " << i << std::endl;
                return Tr;
            }
    private:
        const std::string& fpath;
        nanovdb::FloatGrid* densityFloatGrid = nullptr;
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
	// std::cout << "boop\n";
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
        .method("get_worldToIndexF", &NanoVDBWrapper::get_worldToIndexF)
        .method("get_indexBBox", &NanoVDBWrapper::get_indexBBox)
        .method("get_max_voxel_value", &NanoVDBWrapper::get_max_voxel_value)
        .method("get_sampled_point", &NanoVDBWrapper::get_sampled_point)
        .method("sample_NanoVDBWrapper", &NanoVDBWrapper::sample_NanoVDBWrapper)
        .method("transmittance_NanoVDBWrapper", &NanoVDBWrapper::transmittance_NanoVDBWrapper)
        .method("init", &NanoVDBWrapper::init);

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
