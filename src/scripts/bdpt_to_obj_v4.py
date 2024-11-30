def parse():
    with open("/Users/johnmyslinski/Documents/pbrt-v4-scenes/bunny-fur/geometry/bunnymesh_for_parsing.pbrt", "r") as f:
        lines = f.readlines()
        
    mapper = {
        '"point3 P" [': "v",
        '"normal N" [': "vn",
        '"integer indices" [': "f",
    }

    key = ""
    start_exit_count_ID = 'Shape "trianglemesh"'
    do_exit_count = False
    exit_count = 0
    v = []
    vn = []
    f = []
    for line in lines:
        # print(line)
        # print(v)
        # print(f)
        # print(vn)
        # print(mapper)
        # input()
        if do_exit_count:
            if line.strip() == ']':
                exit_count += 1
                continue

        if line.strip() in mapper.keys():
            key = mapper[line.strip()]
            mapper.pop(line.strip())
            continue
        
        if line.strip() == start_exit_count_ID:
            do_exit_count = True

        if exit_count == 2:
            break

        if key != "":
            tmp = line.strip().split(" ")
            if key == "f":
                tmp2 = [int(x)+1 for x in tmp]
                f += tmp2
            elif key == "v":
                tmp2 = [float(x) for x in tmp]
                v += tmp2
            else:
                assert False


    assert len(v) % 3 == 0
    obj = ""
    i = 0
    while i < len(f):
        line = "f"
        for _ in range(3):
            line += " " + str(f[i])
            i += 1
        line += "\n"
        obj += line

    i = 0
    while i < len(v):
        line = "v"
        for _ in range(3):
            line += " " + str(v[i])
            i += 1
        line += "\n"
        obj += line


    with open("/Users/johnmyslinski/Documents/pbrt-v4-scenes/bunny-fur/geometry/bunnymesh.obj", "w") as f:
        f.write(''.join(obj))

if __name__ == "__main__":
    parse()
