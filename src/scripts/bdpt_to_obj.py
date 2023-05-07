def parse():
    with open("../../ref/caustic-glass/geometry.pbrt", "r") as f:
        lines = f.readlines()

    obj = []
        
    mapper = {
        '  "point P" [\n': "v",
        '  "normal N" [\n': "vn",
        '  "integer indices" [\n': "f",
    }

    key = ""
    start_exit_count_ID = 'Shape "trianglemesh"\n'
    do_exit_count = False
    exit_count = 0
    for line in lines:
        # print(line)
        # print(obj)
        # input()
        if do_exit_count:
            if line.strip() == ']':
                exit_count += 1
                continue

        if line in mapper.keys():
            key = mapper[line]
            mapper.pop(line)
            continue
        
        if line == start_exit_count_ID:
            do_exit_count = True

        if exit_count == 3:
            break

        if key != "":
            if key == "f":
                tmp = line.strip().split(" ")
                tmp2 = [str(int(x)+1) for x in tmp]
                obj.append(
                    key + " " + " ".join(tmp2) + "\n"
                )
            else:
                obj.append(
                    key + " " + line.strip() + "\n"
                )

    with open("../../ref/caustic-glass/caustic_glass.obj", "w") as f:
        f.write(''.join(obj))

if __name__ == "__main__":
    parse()
