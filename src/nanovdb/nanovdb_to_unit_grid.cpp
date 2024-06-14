#include "IO.h"
#include "NanoVDB.h"
#include <iostream>
#include <fstream>

int main(){
	// open grid
	auto handle = nanovdb::io::readGrid("/home/jmyslinski/random_stuff/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb");
	auto* grid = handle.grid<float>();

	// open out file
	std::ofstream outFile("output.txt");

	// get world bounds
	const nanovdb::BBox<nanovdb::Vec3d> box = grid->worldBBox();

	// define resolution
	int steps;
	steps = 10;

	// calc step size
	float ma, mi, stepsize;
	ma = std::max({box.max()[0], box.max()[1], box.max()[2]});
	mi = std::max({box.min()[0], box.min()[1], box.min()[2]});
	stepsize = (ma - mi) / steps;

	// iterate over 'voxels'
	for (int x=0; x<steps; x++){
		for (int y=0; y<steps; y++){
			for (int z=0; z<steps; z++){
				// nanovdb::Coord coord = nanovdb::Coord(x * stepsize, y * stepsize, z * stepsize);
				outFile << x*stepsize << " " << y*stepsize << " " << z*stepsize << "\n";
			}
		}
	}


	// close file
	outFile.close();

	// boop
	std::cout << "boop\n";
	return 0;
}
