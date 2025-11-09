# Subsurface scattering parameters
# From "A Practical Model for Subsurface Light Transport"
# Jensen, Marschner, Levoy, Hanrahan
# Proc SIGGRAPH 2001
#
# And "Acquiring Scattering Properties of Participating Media by Dilution"
# Narasimhan, Gupta, Donner, Ramamoorthi, Nayar, Jensen
# Proc SIGGRAPH 2006
#
# Each entry maps material name to (σ_prime_s, σ_a)
# where σ_prime_s is reduced scattering coefficient (RGB)
# and σ_a is absorption coefficient (RGB)

const SUBSURFACE_PARAMS = Dict{String, Tuple{Spectrum, Spectrum}}(
    # From Jensen et al. SIGGRAPH 2001
    "Apple" => (spectrum_from_float(2.29, 2.39, 1.97), spectrum_from_float(0.0030, 0.0034, 0.046)),
    "Chicken1" => (spectrum_from_float(0.15, 0.21, 0.38), spectrum_from_float(0.015, 0.077, 0.19)),
    "Chicken2" => (spectrum_from_float(0.19, 0.25, 0.32), spectrum_from_float(0.018, 0.088, 0.20)),
    "Cream" => (spectrum_from_float(7.38, 5.47, 3.15), spectrum_from_float(0.0002, 0.0028, 0.0163)),
    "Ketchup" => (spectrum_from_float(0.18, 0.07, 0.03), spectrum_from_float(0.061, 0.97, 1.45)),
    "Marble" => (spectrum_from_float(2.19, 2.62, 3.00), spectrum_from_float(0.0021, 0.0041, 0.0071)),
    "Potato" => (spectrum_from_float(0.68, 0.70, 0.55), spectrum_from_float(0.0024, 0.0090, 0.12)),
    "Skimmilk" => (spectrum_from_float(0.70, 1.22, 1.90), spectrum_from_float(0.0014, 0.0025, 0.0142)),
    "Skin1" => (spectrum_from_float(0.74, 0.88, 1.01), spectrum_from_float(0.032, 0.17, 0.48)),
    "Skin2" => (spectrum_from_float(1.09, 1.59, 1.79), spectrum_from_float(0.013, 0.070, 0.145)),
    "Spectralon" => (spectrum_from_float(11.6, 20.4, 14.9), spectrum_from_float(0.00, 0.00, 0.00)),
    "Wholemilk" => (spectrum_from_float(2.55, 3.21, 3.77), spectrum_from_float(0.0011, 0.0024, 0.014)),
    
    # From Narasimhan et al. SIGGRAPH 2006
    "Lowfat Milk" => (spectrum_from_float(0.89187, 1.5136, 2.532), spectrum_from_float(0.002875, 0.00575, 0.0115)),
    "Reduced Milk" => (spectrum_from_float(2.4858, 3.1669, 4.5214), spectrum_from_float(0.0025556, 0.0051111, 0.012778)),
    "Regular Milk" => (spectrum_from_float(4.5513, 5.8294, 7.136), spectrum_from_float(0.0015333, 0.0046, 0.019933)),
    "Espresso" => (spectrum_from_float(0.72378, 0.84557, 1.0247), spectrum_from_float(4.7984, 6.5751, 8.8493)),
    "Mint Mocha Coffee" => (spectrum_from_float(0.31602, 0.38538, 0.48131), spectrum_from_float(3.772, 5.8228, 7.82)),
    "Lowfat Soy Milk" => (spectrum_from_float(0.30576, 0.34233, 0.61664), spectrum_from_float(0.0014375, 0.0071875, 0.035937)),
    "Regular Soy Milk" => (spectrum_from_float(0.59223, 0.73866, 1.4693), spectrum_from_float(0.0019167, 0.0095833, 0.065167)),
    "Lowfat Chocolate Milk" => (spectrum_from_float(0.64925, 0.83916, 1.1057), spectrum_from_float(0.0115, 0.0368, 0.1564)),
    "Regular Chocolate Milk" => (spectrum_from_float(1.4585, 2.1289, 2.9527), spectrum_from_float(0.010063, 0.043125, 0.14375)),
    "Coke" => (spectrum_from_float(8.9053e-05, 8.372e-05, 0.0), spectrum_from_float(0.10014, 0.16503, 0.2468)),
    "Pepsi" => (spectrum_from_float(6.1697e-05, 4.2564e-05, 0.0), spectrum_from_float(0.091641, 0.14158, 0.20729)),
    "Sprite" => (spectrum_from_float(6.0306e-06, 6.4139e-06, 6.5504e-06), spectrum_from_float(0.001886, 0.0018308, 0.0020025)),
    "Gatorade" => (spectrum_from_float(0.0024574, 0.003007, 0.0037325), spectrum_from_float(0.024794, 0.019289, 0.008878)),
    "Chardonnay" => (spectrum_from_float(1.7982e-05, 1.3758e-05, 1.2023e-05), spectrum_from_float(0.010782, 0.011855, 0.023997)),
    "White Zinfandel" => (spectrum_from_float(1.7501e-05, 1.9069e-05, 1.288e-05), spectrum_from_float(0.012072, 0.016184, 0.019843)),
    "Merlot" => (spectrum_from_float(2.1129e-05, 0.0, 0.0), spectrum_from_float(0.11632, 0.25191, 0.29434)),
    "Budweiser Beer" => (spectrum_from_float(2.4356e-05, 2.4079e-05, 1.0564e-05), spectrum_from_float(0.011492, 0.024911, 0.057786)),
    "Coors Light Beer" => (spectrum_from_float(5.0922e-05, 4.301e-05, 0.0), spectrum_from_float(0.006164, 0.013984, 0.034983)),
    "Clorox" => (spectrum_from_float(0.0024035, 0.0031373, 0.003991), spectrum_from_float(0.0033542, 0.014892, 0.026297)),
    "Apple Juice" => (spectrum_from_float(0.00013612, 0.00015836, 0.000227), spectrum_from_float(0.012957, 0.023741, 0.052184)),
    "Cranberry Juice" => (spectrum_from_float(0.00010402, 0.00011646, 7.8139e-05), spectrum_from_float(0.039437, 0.094223, 0.12426)),
    "Grape Juice" => (spectrum_from_float(5.382e-05, 0.0, 0.0), spectrum_from_float(0.10404, 0.23958, 0.29325)),
    "Ruby Grapefruit Juice" => (spectrum_from_float(0.011002, 0.010927, 0.011036), spectrum_from_float(0.085867, 0.18314, 0.25262)),
    "White Grapefruit Juice" => (spectrum_from_float(0.22826, 0.23998, 0.32748), spectrum_from_float(0.0138, 0.018831, 0.056781)),
    "Shampoo" => (spectrum_from_float(0.0007176, 0.0008303, 0.0009016), spectrum_from_float(0.014107, 0.045693, 0.061717)),
    "Strawberry Shampoo" => (spectrum_from_float(0.00015671, 0.00015947, 1.518e-05), spectrum_from_float(0.01449, 0.05796, 0.075823)),
    "Head & Shoulders Shampoo" => (spectrum_from_float(0.023805, 0.028804, 0.034306), spectrum_from_float(0.084621, 0.15688, 0.20365)),
    "Lemon Tea Powder" => (spectrum_from_float(0.040224, 0.045264, 0.051081), spectrum_from_float(2.4288, 4.5757, 7.2127)),
    "Orange Powder" => (spectrum_from_float(0.00015617, 0.00017482, 0.0001762), spectrum_from_float(0.001449, 0.003441, 0.007863)),
    "Pink Lemonade Powder" => (spectrum_from_float(0.00012103, 0.00013073, 0.00012528), spectrum_from_float(0.001165, 0.002366, 0.003195)),
    "Cappuccino Powder" => (spectrum_from_float(1.8436, 2.5851, 2.1662), spectrum_from_float(35.844, 49.547, 61.084)),
    "Salt Powder" => (spectrum_from_float(0.027333, 0.032451, 0.031979), spectrum_from_float(0.28415, 0.3257, 0.34148)),
    "Sugar Powder" => (spectrum_from_float(0.00022272, 0.00025513, 0.000271), spectrum_from_float(0.012638, 0.031051, 0.050124)),
    "Suisse Mocha Powder" => (spectrum_from_float(2.7979, 3.5452, 4.3365), spectrum_from_float(17.502, 27.004, 35.433)),
    "Pacific Ocean Surface Water" => (spectrum_from_float(0.0001764, 0.00032095, 0.00019617), spectrum_from_float(0.031845, 0.031324, 0.030147))
)