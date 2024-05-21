#include "IO.h"
#include "NanoVDB.h"

#include <string>
#include "jlcxx/jlcxx.hpp"

nanovdb::FloatGrid* get_accessor()
{
    auto handle = nanovdb::io::readGrid("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"); // read first grid in file

    auto* grid = handle.grid<float>(); // get a (raw) pointer to a NanoVDB grid of value type float

    if (!grid)
        throw std::runtime_error("File did not contain a grid with value type float");

    // auto acc = grid->getAccessor(); // create an accessor for fast access to multiple values
    // for (int i = 97; i < 104; ++i) {
    //     printf("(%3i,0,0) NanoVDB cpu: % -4.2f\n", i, acc.getValue(nanovdb::Coord(i, 0, 0)));
    // }

    return grid;
}

float get_value(nanovdb::DefaultReadAccessor<float> acc, int x, int y, int z) {
    return acc.getValue(nanovdb::Coord(x, y, z));
}

int greet(){
    return 5;
}

JLCXX_MODULE define_julia_module(jlcxx::Module& mod)
{
  mod.method("get_accessor", &get_accessor, "get accessor");
  mod.method("get_value", &get_value, "get value");
  mod.method("greet", &greet, "returns 5");
}