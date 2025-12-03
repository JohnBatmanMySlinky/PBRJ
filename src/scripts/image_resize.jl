using Images, FileIO

# Read the 4K image
img = load("/Users/johnmyslinski/Downloads/Aged Parchment.PNG")

# Scale down to 1K (1920x1080)
img_1k = imresize(img, (1080, 1920))  # Note: (height, width) order

img_1k_rot = rotr90(img_1k)

# Save the result
save("/Users/johnmyslinski/Documents/PBRJ/ref/aged_parchment_1k.png", img_1k_rot)
