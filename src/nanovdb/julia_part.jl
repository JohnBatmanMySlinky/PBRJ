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

coord = CppHello.Coord(5)
print("woo hoo $(CppHello.x(coord)[])\n")
