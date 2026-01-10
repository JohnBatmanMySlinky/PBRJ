struct MaterialPool
    matte::Vector{Matte}
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
                Matte[],
            ),
            Dict{UInt32, MaterialRef}(),
        )
    end
end

function register_material!(mat::Matte)
    reg = MATERIAL_REGISTRY[]
    push!(reg.pool.matte, mat)
    
    reg.id_to_ref[mat.hash] = MaterialRef(UInt8(1), length(reg.pool.matte))
end

function get_material(hash::UInt32)
    mat_ref = MATERIAL_REGISTRY[].id_to_ref[hash]
    if mat_ref.type == UInt8(1)
        return MATERIAL_REGISTRY[].pool.matte[mat_ref.index]::Matte
    else
        @assert false
    end
end