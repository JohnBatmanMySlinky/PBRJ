# Load the module and generate the functions
module NanoVDB
  using CxxWrap
  @wrapmodule("/Users/johnmyslinski/Documents/PBRJ/src/nanovdb/lib/libtestlib.dylib")
  # @wrapmodule("/home/jmyslinski/random_stuff/PBRJ/src/nanovdb/lib/libtestlib.dylib")

  function __init__()
    @initcxx
  end
end

# Call greet and show the result
# world = NanoVDB.World("a", "b")
# print("$(NanoVDB.greet_byvalue(world)) - by value\n")

# print("=======NanoVDBWrapper Test============\n")
# fpath = "/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"
# coord = NanoVDB.Coord(99, 0, 0)
# nanovdb_wrapper = NanoVDB.make_NanoVDBWrapper(fpath)

# a, b, c, d, e, f = NanoVDB.get_WorldBBox(nanovdb_wrapper)
# print("BoundingBox: ($a, $b, $c), ($d, $e, $f)\n")

# extremas = NanoVDB.get_extrema(nanovdb_wrapper)
# print("Extremas: $extremas\n")

# NanoVDB.grid_to_unit(
#   "/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb",
#   "output.txt",
#   20
# )