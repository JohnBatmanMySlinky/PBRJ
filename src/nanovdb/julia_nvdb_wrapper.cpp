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

// on linux i get a namespace violation and what ever function is actually called 
// must have a different order of params; so not only do i need to define my own lerp
// i gotta call it something stupid
float lerp_why(float t, float a, float b){
    return a + t * (b - a);
}

class NanoVDBWrapper {
    public:
        NanoVDBWrapper(const std::string& fpath) : fpath(fpath) {}
        void init(){
            handle = nanovdb::io::readGrid(jmfp(fpath));
            densityFloatGrid = handle.grid<float>();
            if (!densityFloatGrid) {
                throw std::runtime_error("Failed to load grid");
            }
        }
        // Delete copy constructor and copy assignment
        NanoVDBWrapper(const NanoVDBWrapper&) = delete;
        NanoVDBWrapper& operator=(const NanoVDBWrapper&) = delete;
        
        // Default move constructor and move assignment (compiler-generated)
        NanoVDBWrapper(NanoVDBWrapper&&) = default;
        NanoVDBWrapper& operator=(NanoVDBWrapper&&) = default;
        ~NanoVDBWrapper() {
            std::cout << "NanoVDBWrapper - Destructed\n";
        }
        std::vector<double> build_majorant_grid(
            int resx, int resy, int resz
        ) {
            auto temphandle = nanovdb::io::readGrid(jmfp(fpath)); // Temporary handle
            auto* grid = temphandle.grid<float>();
            auto accessor = grid->getAccessor();
            const nanovdb::BBox<nanovdb::Vec3d> bounds = grid->worldBBox();
            // std::cout << "WORLD BOUNDS " << bounds << std::endl;
            auto bbox = grid->indexBBox();

            // instantiate majorantGrid array
            std::vector<double> majorantGrid(resx * resy * resz);

            // std::cout << "NOW IN C++ LAND " << resx << ", " << resy << ", " << resx << std::endl;
            
            for (int index=0; index < resx * resy * resz; ++index) {
                int x = index % resx;
                int y = (index / resx) % resy;
                int z = index / (resx * resy);

                // std::cout << "NOW IN C++ LAND " << index << " " << x << " " << y << " " << z << std::endl;
                
                // World (aka medium) space bounds of this max grid cell
                nanovdb::BBox<nanovdb::Vec3d> wb = nanovdb::BBox<nanovdb::Vec3d>(
                    nanovdb::Vec3d(
                        lerp_why(double(x) / double(resx), bounds.min()[0], bounds.max()[0]),
                        lerp_why(double(y) / double(resy), bounds.min()[1], bounds.max()[1]),
                        lerp_why(double(z) / double(resz), bounds.min()[2], bounds.max()[2])
                    ),
                    nanovdb::Vec3d(
                        lerp_why(double(x + 1) / double(resx), bounds.min()[0], bounds.max()[0]),
                        lerp_why(double(y + 1) / double(resy), bounds.min()[1], bounds.max()[1]),
                        lerp_why(double(z + 1) / double(resz), bounds.min()[2], bounds.max()[2])
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
        std::tuple<float, float, float, float, float, float> get_WorldBBox() {
            auto temphandle = nanovdb::io::readGrid(jmfp(fpath)); // Temporary handle
            auto* grid = temphandle.grid<float>();
            const nanovdb::BBox<nanovdb::Vec3d> box = grid->worldBBox();
            nanovdb::Vec3 mi = box.min();
            nanovdb::Vec3 ma = box.max();
            return {mi[0], mi[1], mi[2], ma[0], ma[1], ma[2]};
        }
        float get_sampled_point(double x, double y, double z
        ) {
            if (!densityFloatGrid) {
                throw std::runtime_error("Grid not initialized - call init() first");
            }
            // Check for NaN/infinity
            if (!std::isfinite(x) || !std::isfinite(y) || !std::isfinite(z)) {
                throw std::runtime_error("Invalid coordinates");
            }
            nanovdb::Vec3<float> pIndex = densityFloatGrid->worldToIndexF(nanovdb::Vec3<float>(x, y, z));
            // std::cout << "SAMPLE POINT: pIndex " << pIndex[0] << ", " << pIndex[1] << ", " << pIndex[2] << std::endl;
            using Sampler = nanovdb::SampleFromVoxels<nanovdb::FloatGrid::TreeType, 1, false>;
            float d = Sampler(densityFloatGrid->tree())(pIndex);
            return d;
        }
    private:
        std::string fpath; // Copy, not reference
        nanovdb::GridHandle<> handle; // Store the handle
        nanovdb::FloatGrid* densityFloatGrid = nullptr;
};


NanoVDBWrapper make_NanoVDBWrapper(const std::string& fpath) {
    return NanoVDBWrapper(fpath); // return a John object
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
    mod.add_type<nanovdb::Coord>("Coord")
        .constructor<int32_t>()
        .constructor<int32_t, int32_t, int32_t>()
        .method("x", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::x)
        .method("y", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::y)
        .method("z", (int32_t (nanovdb::Coord::*)() const) &nanovdb::Coord::z);

    mod.add_type<NanoVDBWrapper>("NanoVDBWrapper")
        .method("get_WorldBBox", &NanoVDBWrapper::get_WorldBBox)
        .method("get_sampled_point", &NanoVDBWrapper::get_sampled_point)
        .method("build_majorant_grid", &NanoVDBWrapper::build_majorant_grid)
        .method("init", &NanoVDBWrapper::init);

    mod.method("make_NanoVDBWrapper", &make_NanoVDBWrapper);
}
