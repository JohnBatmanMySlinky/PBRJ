function print_BVH_bounds(b::BVHNode)
    print("BVH Checking\n")
    print(b.bounds)
    print("\n")
    print(world_bounds(b.left))
    print("\n")
    print(world_bounds(b.right))
    print("\n")
end