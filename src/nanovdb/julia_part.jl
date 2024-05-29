# Load the module and generate the functions
module NanoVDB
  using CxxWrap
  # @wrapmodule("/Users/johnmyslinski/Documents/PBRJ/src/nanovdb/lib/libtestlib.dylib")
  @wrapmodule("/home/jmyslinski/random_stuff/PBRJ/src/nanovdb/lib/libtestlib.dylib")

  function __init__()
    @initcxx
  end
end

# Call greet and show the result
# world = NanoVDB.World("a", "b")
# print("$(NanoVDB.greet_byvalue(world)) - by value\n")


# using BenchmarkTools
# print("=======Coord Test======\n")
# coord = NanoVDB.Coord(5)
# print("woo hoo $(NanoVDB.x(coord)[])\n")
# coord = NanoVDB.Coord(5, 6, 7)
# print("woo hoo $(NanoVDB.y(coord)[])\n")


# print("=======Access Test======\n")

# acc = NanoVDB.get_accessor_pls(fpath)
# print("$(NanoVDB.get_value_pls(acc, coord))\n")


# print("=======BBox Test======\n")
# bbox = NanoVDB.get_bbox(fpath)
# print("$(NanoVDB.get_bbox_min(bbox))\n")
# print("$(NanoVDB.get_bbox_max(bbox))\n")

# print("=======MaxDensity Test======\n")
# min_density, max_density = NanoVDB.get_extrema(fpath)
# print("$(max_density)\n")

print("=======NanoVDBWrapper Test============\n")
fpath = "/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"
coord = NanoVDB.Coord(99, 0, 0)
nanovdb_wrapper = NanoVDB.make_NanoVDBWrapper(fpath)

a, b, c, d, e, f = NanoVDB.get_WorldBBox(nanovdb_wrapper)
print("BoundingBox: ($a, $b, $c), ($d, $e, $f)\n")

extremas = NanoVDB.get_extrema(nanovdb_wrapper)
print("Extremas: $extremas\n")

