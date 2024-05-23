# Load the module and generate the functions
module CppHello
  using CxxWrap
  @wrapmodule("/Users/johnmyslinski/Documents/PBRJ/src/nanovdb/lib/libtestlib.dylib")

  function __init__()
    @initcxx
  end
end

# Call greet and show the result
# world = CppHello.World("a", "b")
# print("$(CppHello.greet_byvalue(world)) - by value\n")
print("=======Coord Test======\n")
coord = CppHello.Coord(5)
print("woo hoo $(CppHello.x(coord)[])\n")
coord = CppHello.Coord(5, 6, 7)
print("woo hoo $(CppHello.y(coord)[])\n")


print("=======Access Test======\n")
coord = CppHello.Coord(99, 0, 0)
acc = CppHello.get_accessor_pls()
print("$(typeof(acc))\n")
print("is it time to cry? $(CppHello.get_value_pls(acc, coord))\n")


print("=======BBox Test======\n")
bbox = CppHello.get_bbox()
print("$(bbox)\n")
print("$(CppHello.get_bbox_min(bbox))\n")
print("$(CppHello.get_bbox_max(bbox))\n")
