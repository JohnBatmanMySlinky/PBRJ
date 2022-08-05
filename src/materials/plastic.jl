# PBR 9.2.2 Plastic Material
struct PlasticMaterial <: Material
    Kd::Texture
    Ks::Texture
    roughness::Maybe{Texture}
    bump_map::Maybe{Texture}
    remap_roughness::Bool
end

