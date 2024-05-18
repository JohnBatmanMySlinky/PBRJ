# Load the module and generate the functions
module CppHello
  using CxxWrap
  @wrapmodule("/Users/johnmyslinski/Documents/openvdb/nanovdb/nanovdb/j_nvdb_build/lib/libtestlib.dylib")

  function __init__()
    @initcxx
  end
end

# Call greet and show the result
print(CppHello.magic())