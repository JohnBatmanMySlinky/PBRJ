struct MaterialPool
    fourier::Vector{Fourier}             # 1
    glass::Vector{Glass}                 # 2
    hair::Vector{HairMaterial}                   # 3
    kdsubsurface::Vector{KdSubSurface}   # 4
    matte::Vector{Matte}                 # 5
    metal::Vector{Metal}                 # 6
    mirror::Vector{Mirror}               # 7
    plastic::Vector{Plastic}             # 8
    substrate::Vector{Substrate}         # 9
    uber::Vector{Uber}                   # 10
end

struct MaterialRef
    type::UInt8
    index::Int64
end

struct MaterialRegistry
    pool::MaterialPool
    id_to_ref::Dict{UInt32, MaterialRef}  
    
    function MaterialRegistry()
        new(
            MaterialPool(
                Fourier[],
                Glass[],
                HairMaterial[],
                KdSubSurface[],
                Matte[],
                Metal[],
                Mirror[],
                Plastic[],
                Substrate[],
                Uber[]
            ),
            Dict{UInt32, MaterialRef}(),
        )
    end
end

function register_material!(mat::Fourier)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.fourier, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(1), length(reg.pool.fourier))
end

function register_material!(mat::Glass)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.glass, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(2), length(reg.pool.glass))
end

function register_material!(mat::HairMaterial)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.hair, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(3), length(reg.pool.hair))
end

function register_material!(mat::KdSubSurface)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.kdsubsurface, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(4), length(reg.pool.kdsubsurface))
end

function register_material!(mat::Matte)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.matte, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(5), length(reg.pool.matte))
end

function register_material!(mat::Metal)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.metal, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(6), length(reg.pool.metal))
end

function register_material!(mat::Mirror)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.mirror, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(7), length(reg.pool.mirror))
end

function register_material!(mat::Plastic)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.plastic, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(8), length(reg.pool.plastic))
end

function register_material!(mat::Substrate)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.substrate, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(9), length(reg.pool.substrate))
end

function register_material!(mat::Uber)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.uber, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(10), length(reg.pool.uber))
end

function get_material(hash::UInt32)
    mat_ref = MATERIAL_REGISTRY[].id_to_ref[hash]
    if mat_ref.type == UInt8(1)
        return MATERIAL_REGISTRY[].pool.fourier[mat_ref.index]::Fourier
    elseif mat_ref.type == UInt8(2)
        return MATERIAL_REGISTRY[].pool.glass[mat_ref.index]::Glass
    elseif mat_ref.type == UInt8(3)
        return MATERIAL_REGISTRY[].pool.hair[mat_ref.index]::HairMaterial
    elseif mat_ref.type == UInt8(4)
        return MATERIAL_REGISTRY[].pool.kdsubsurface[mat_ref.index]::KdSubSurface
    elseif mat_ref.type == UInt8(5)
        return MATERIAL_REGISTRY[].pool.matte[mat_ref.index]::Matte
    elseif mat_ref.type == UInt8(6)
        return MATERIAL_REGISTRY[].pool.metal[mat_ref.index]::Metal
    elseif mat_ref.type == UInt8(7)
        return MATERIAL_REGISTRY[].pool.mirror[mat_ref.index]::Mirror
    elseif mat_ref.type == UInt8(8)
        return MATERIAL_REGISTRY[].pool.plastic[mat_ref.index]::Plastic
    elseif mat_ref.type == UInt8(9)
        return MATERIAL_REGISTRY[].pool.substrate[mat_ref.index]::Substrate
    elseif mat_ref.type == UInt8(10)
        return MATERIAL_REGISTRY[].pool.uber[mat_ref.index]::Uber
    else
        @assert false
    end
end