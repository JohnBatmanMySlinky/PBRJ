using OpenEXR
using ColorTypes
 
 
function just_do_it(two_to_the_Nth_power::Int=3)
    WIDTH, HEIGHT = 2^two_to_the_Nth_power-1, 2^two_to_the_Nth_power+1
    SIZE = WIDTH * HEIGHT
    img = zeros(RGBA, HEIGHT, WIDTH)
 
    for x in 1:WIDTH
        for y in 1:HEIGHT
            z = round(x*y/SIZE; base=20, digits=1)
            img[y,x] = RGBA(z, z, z, 1.0)
        end
    end
    return img
end
 
img = just_do_it(3)
print(img)
OpenEXR.save("hello.exr", img)