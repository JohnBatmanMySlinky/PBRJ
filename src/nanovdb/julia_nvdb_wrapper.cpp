#include "IO.h"
#include "NanoVDB.h"
#include "SampleFromVoxels.h"

#include <random>
#include <string>
#include <iostream>
#include <fstream>
#include <regex>

#include "jlcxx/jlcxx.hpp"

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

nanovdb::Vec3d lerp(nanovdb::BBox<nanovdb::Vec3d> bbox, nanovdb::Vec3d t) {
    return nanovdb::Vec3d(
        lerp(t[0], bbox.min()[0], bbox.max()[0]),
        lerp(t[1], bbox.min()[1], bbox.max()[1]),
        lerp(t[2], bbox.min()[2], bbox.max()[2])
    );
}

class NanoVDBWrapper {
    public:
        NanoVDBWrapper(const std::string& fpath) : fpath(fpath) {}
        ~NanoVDBWrapper() {
            std::cout << "NanoVDBWrapper - Destructed\n";
        }
        // std::tuple<double, double, double> get_worldToIndexF(double x, double y, double z
        // ){
        //     nanovdb::Vec3 xyz = nanovdb::Vec3(x, y, z);

        //     auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
        //     auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
        //     nanovdb::Vec3 i0 = grid->worldToIndexF(xyz);
        //     return {i0[0], i0[1], i0[2]};
        // }
        std::vector<double> build_majorant_grid(
            int resx, int resy, int resz
        ) {
            // instantiate majorantGrid array
            std::vector<double> majorantGrid(resx * resy * resz);

            // instantiate grid from fpath as we haven't init'd from julia yet
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            auto accessor = grid->getAccessor();
            const nanovdb::BBox<nanovdb::Vec3d> bounds = grid->worldBBox();
            auto bbox = grid->indexBBox();
            
            for (int index=0; index < resx * resy * resz; ++index) {
                int x = index % resx;
                int y = (index / resx) % resy;
                int z = index / (resx * resy);

                // std::cout << "NOW IN C++ LAND " << index << " " << x << " " << y << " " << z << std::endl;
                
                // World (aka medium) space bounds of this max grid cell
                nanovdb::BBox<nanovdb::Vec3d> wb = nanovdb::BBox<nanovdb::Vec3d>(
                    lerp(
                        bounds, 
                        nanovdb::Vec3d(
                            double(x) / double(resx),
                            double(y) / double(resy),
                            double(z) / double(resz)
                        )
                    ),
                    lerp(
                        bounds, 
                        nanovdb::Vec3d(
                            double(x+1) / double(resx),
                            double(y+1) / double(resy),
                            double(z+1) / double(resz)
                        )
                    )
                );
                // std::cout << "\twb: [ [" << wb.min()[0] << ", " << wb.min()[1] << ", " << wb.min()[2] << "], - ["  << wb.max()[0] << ", " << wb.max()[1] << ", " << wb.max()[2] << "] ]" << std::endl;
                
                // Compute corresponding NanoVDB index-space bounds in floating-point.
                nanovdb::Vec3d i0 = grid->worldToIndexF(
                    nanovdb::Vec3d(wb.min()[0], wb.min()[1], wb.min()[2]));
                nanovdb::Vec3d i1 = grid->worldToIndexF(
                    nanovdb::Vec3d(wb.max()[0], wb.max()[1], wb.max()[2]));
                    
                // Now find integer index-space bounds, accounting for both filtering and the overall index bounding box.
                double delta = 1.0;  // Filter slop
                int nx0 = std::max(int(i0[0] - delta), bbox.min()[0]);
                int nx1 = std::min(int(i1[0] + delta), bbox.max()[0]);
                int ny0 = std::max(int(i0[1] - delta), bbox.min()[1]);
                int ny1 = std::min(int(i1[1] + delta), bbox.max()[1]);
                int nz0 = std::max(int(i0[2] - delta), bbox.min()[2]);
                int nz1 = std::min(int(i1[2] + delta), bbox.max()[2]);
                // std::cout << "\tindices: " << nx0 << " " << nx1 << " " << ny0 << " " << ny1 << " " << nz0 << " " << nz1 << std::endl;

                
                float maxValue = 0;
                for (int nz = nz0; nz <= nz1; ++nz)
                    for (int ny = ny0; ny <= ny1; ++ny)
                        for (int nx = nx0; nx <= nx1; ++nx)
                            maxValue = std::max(maxValue, accessor.getValue({nx, ny, nz}));

                // std::cout << "\t density = " << maxValue << std::endl;

                majorantGrid[index] = maxValue;
            }
            return majorantGrid;
        }
        // float get_max_voxel_value(
        //     int nx0,
        //     int nx1,
        //     int ny0,
        //     int ny1,
        //     int nz0,
        //     int nz1
        // ) {
        //     float maxValue = 0;

        //     auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
        //     auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
        //     auto accessor = grid->getAccessor();

        //     for (int nz = nz0; nz <= nz1; ++nz) {
        //         for (int ny = ny0; ny <= ny1; ++ny) {
        //             for (int nx = nx0; nx <= nx1; ++nx) {
        //                 maxValue = std::max(maxValue, accessor.getValue({nx, ny, nz}));
        //             }
        //         }
        //     }
        //     return maxValue;
        // }
        std::tuple<float, float, float, float, float, float> get_WorldBBox() {
            auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
            auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            const nanovdb::BBox<nanovdb::Vec3d> box = grid->worldBBox();
            nanovdb::Vec3 mi = box.min();
            nanovdb::Vec3 ma = box.max();
            return {mi[0], mi[1], mi[2], ma[0], ma[1], ma[2]};
        }
        // std::tuple<float, float> get_extrema() {
        //     float minDensity, maxDensity;
        //     auto handle = nanovdb::io::readGrid(fpath); // reads first grid from file
        //     auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
        //     grid->tree().extrema(minDensity, maxDensity);
        //     return {minDensity, maxDensity};
        // }
        float get_sampled_point(double x, double y, double z
        ) {
            // auto handle = nanovdb::io::readGrid(jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb")); // reads first grid from file
            // auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float
            nanovdb::Vec3<float> pIndex = densityFloatGrid->worldToIndexF(nanovdb::Vec3<float>(x, y, z));
            // std::cout << "SAMPLE POINT: pIndex " << pIndex[0] << ", " << pIndex[1] << ", " << pIndex[2] << std::endl;
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
    
    private:
        const std::string& fpath;
        nanovdb::FloatGrid* densityFloatGrid = nullptr;
};


NanoVDBWrapper make_NanoVDBWrapper(const std::string& fpath) {
    return NanoVDBWrapper(fpath); // return a John object
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    // mod.method("grid_to_unit", &grid_to_unit);

    // mod.add_type<nanovdb::BBox<nanovdb::Vec3d>>("BBox");


    mod.add_type<nanovdb::Coord>("Coord")
        .constructor<int32_t>()
        .constructor<int32_t, int32_t, int32_t>()
        .method("x", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::x)
        .method("y", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::y)
        .method("z", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::z);

    mod.add_type<NanoVDBWrapper>("NanoVDBWrapper")
        .method("get_WorldBBox", &NanoVDBWrapper::get_WorldBBox)
        // .method("get_extrema", &NanoVDBWrapper::get_extrema)
        // .method("get_worldToIndexF", &NanoVDBWrapper::get_worldToIndexF)
        // .method("get_indexBBox", &NanoVDBWrapper::get_indexBBox)
        // .method("get_max_voxel_value", &NanoVDBWrapper::get_max_voxel_value)
        .method("get_sampled_point", &NanoVDBWrapper::get_sampled_point)
        .method("build_majorant_grid", &NanoVDBWrapper::build_majorant_grid)
        // .method("sample_NanoVDBWrapper", &NanoVDBWrapper::sample_NanoVDBWrapper)
        // .method("transmittance_NanoVDBWrapper", &NanoVDBWrapper::transmittance_NanoVDBWrapper)
        .method("init", &NanoVDBWrapper::init);

    mod.method("make_NanoVDBWrapper", &make_NanoVDBWrapper);
}
