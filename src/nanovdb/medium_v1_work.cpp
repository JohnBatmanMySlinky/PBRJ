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