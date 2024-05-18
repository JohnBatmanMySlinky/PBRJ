#include "IO.h"

#include <string>
#include "jlcxx/jlcxx.hpp"

int magic()
{
    try {
        auto handle = nanovdb::io::readGrid("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"); // read first grid in file

        auto* grid = handle.grid<float>(); // get a (raw) pointer to the first NanoVDB grid of value type float

        if (grid == nullptr)
            throw std::runtime_error("File did not contain a grid with value type float");

        // Access and print out a single value in the NanoVDB grid
        printf("NanoVDB cpu: %4.2f\n", grid->tree().getValue(nanovdb::Coord(99, 0, 0)));
    }
    catch (const std::exception& e) {
        std::cerr << "An exception occurred: \"" << e.what() << "\"" << std::endl;
    }

    return 0;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("magic", &magic, "documentation for magic");
}