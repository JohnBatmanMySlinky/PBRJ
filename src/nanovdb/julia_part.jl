# Load the module and generate the functions
module NanoVDB
  using CxxWrap
  if Sys.isapple()
    @wrapmodule(() -> joinpath("/Users/johnmyslinski/Documents/PBRJ/src/nanovdb/lib", "libtestlib"))
  else
    @wrapmodule(() -> joinpath("/home/jmyslinski/random_stuff/PBRJ/src/nanovdb/lib", "libtestlib"))
  end
  

  function __init__()
    @initcxx
  end
end

# Call greet and show the result
# world = NanoVDB.World("a", "b")
# print("$(NanoVDB.greet_byvalue(world)) - by value\n")

# print("=======NanoVDBWrapper Test============\n")
# fpath = "/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"
# fpath = "/home/jmyslinski/random_stuff/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"
# coord = NanoVDB.Coord(99, 0, 0)
# nanovdb_wrapper = NanoVDB.make_NanoVDBWrapper(fpath)

# a, b, c, d, e, f = NanoVDB.get_WorldBBox(nanovdb_wrapper)
# print("BoundingBox: ($a, $b, $c), ($d, $e, $f)\n")

# extremas = NanoVDB.get_extrema(nanovdb_wrapper)
# print("Extremas: $extremas\n")


# print("=======NanoVDBWrapper Util Usage============\n")
# NanoVDB.grid_to_unit(
#   "/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb",
#   "output.txt",
#   20
# )