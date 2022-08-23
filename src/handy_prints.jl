function print_BVH_bounds(b::BVHNode)
    print("BVH Checking\n")
    print(b.bounds)
    print("\n")
    print(world_bounds(b.left))
    print("\n")
    print(world_bounds(b.right))
    print("\n")
end

function num2str(num::Number; delim=",")
    decimal_point = "."
    str = string(num)
    strs = split(str, decimal_point)
    left_str = strs[1]
    right_str = length(strs) > 1 ? strs[2] : ""
    left_str = replace(left_str, r"(?<=[0-9])(?=(?:[0-9]{3})+(?![0-9]))" => delim)
    decimal_point = occursin(decimal_point, str) ? decimal_point : ""
    return left_str * decimal_point * right_str
 end