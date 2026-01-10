struct MaterialPool
    fourier::Vector{Fourier}             # 1
    glass::Vector{Glass}                 # 2
    hair::Vector{Hair}                   # 3
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
                Hair[],
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

function register_material!(mat::Hair)
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

function get_material(hash::UInt32)
    mat_ref = MATERIAL_REGISTRY[].id_to_ref[hash]
    if mat_ref.type == UInt8(1)
        return MATERIAL_REGISTRY[].pool.matte[mat_ref.index]::Matte
    else
        @assert false
    end
end