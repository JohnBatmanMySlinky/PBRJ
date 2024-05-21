# Load the module and generate the functions
module CppHello
  using CxxWrap
  @wrapmodule("/Users/johnmyslinski/Documents/PBRJ/src/nanovdb/lib/libtestlib.dylib")

  function __init__()
    @initcxx
  end
end

# Call greet and show the result
print("THIS SHOULD BE 5: $(CppHello.greet())\n")
acc = CppHello.get_accessor()
print(CppHello.get_value(acc, 99, 0, 0))
