std::vector<double> build_majorant_grid(
	int resx, int resy, int resz, wb Bounds3
) {
	
	std::vector<double> majorantGrid[resx * resy * resz];
	
	for (int index=0, index < resx * resy * resz, index ++) {
		int x = index % resx;
        int y = (index / resx) % resy;
        int z = index / (resx * resy);
		
		// World (aka medium) space bounds of this max grid cell
		Bounds3f wb(
			lerp(
				wb, 
				Pnt3(
					float(x) / resx,
					float(y) / resy,
					float(z) / resz,
				)
			),
						lerp(
				wb, 
				Pnt3(
					float(x+1) / resx,
					float(y+1) / resy,
					float(z+1) / resz,
				)
			)
		);
		
		// Compute corresponding NanoVDB index-space bounds in floating-point.
        nanovdb::Vec3R i0 = grid->worldToIndexF(
            nanovdb::Vec3R(wb.pMin.x, wb.pMin.y, wb.pMin.z));
        nanovdb::Vec3R i1 = grid->worldToIndexF(
            nanovdb::Vec3R(wb.pMax.x, wb.pMax.y, wb.pMax.z));
			
		// Now find integer index-space bounds, accounting for both filtering and the overall index bounding box.
        auto bbox = grid->indexBBox();
        Float delta = 1.f;  // Filter slop
        int nx0 = std::max(int(i0[0] - delta), bbox.min()[0]);
        int nx1 = std::min(int(i1[0] + delta), bbox.max()[0]);
        int ny0 = std::max(int(i0[1] - delta), bbox.min()[1]);
        int ny1 = std::min(int(i1[1] + delta), bbox.max()[1]);
        int nz0 = std::max(int(i0[2] - delta), bbox.min()[2]);
        int nz1 = std::min(int(i1[2] + delta), bbox.max()[2]);
		
		double maxValue = 0;
		auto accessor = grid->getAccessor();
		
		for (int nz = nz0; nz <= nz1; nz++) {
			for (int ny = ny0; ny <= ny1; ny++) {
				for (int nx = nx0; ny <= nx1; nx++) {
					maxValue = std::max(maxValue, acessor.getValue({nx, ny, nz);
				}
			}
		}
		
		majorantGrid[] = maxValue;
	}
	return majorantGrid;
}

# Then regular function return...
