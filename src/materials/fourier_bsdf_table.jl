"""
    FourierBSDFTable

Represents a tabulated BSDF using Fourier series coefficients.
"""
mutable struct FourierBSDFTable
    # Public Data
    eta::Float64
    mMax::Int
    nChannels::Int
    nMu::Int
    mu::Vector{Float64}
    m::Vector{Int}
    aOffset::Vector{Int}
    a::Vector{Float64}
    a0::Vector{Float64}
    cdf::Vector{Float64}
    recip::Vector{Float64}
    
    # Constructor with default initialization
    function FourierBSDFTable()
        return new(0.0, 0, 0, 0, Float64[], Int[], Int[], Float64[], Float64[], Float64[], Float64[])
    end
end

function get_ak(table::FourierBSDFTable, offsetI::Int, offsetO::Int, c::Int64)
    idx = offsetO * table.nMu + offsetI
    m_val = table.m[idx + 1]
    len = c * m_val + (m_val - 1)
    # @info "GetAk: $m_val $(table.aOffset[idx + 1])"
    return table.a[(table.aOffset[idx + 1] + 1):(table.aOffset[idx + 1] + len + 1)], m_val
end

function get_weights_and_offset(table::FourierBSDFTable, cos_theta::Float64)::Tuple{Bool, Int64, Vector{Float64}}
    return catmull_rom_weights(table.nMu, table.mu, cos_theta)
end

"""
    Read(filename::String)

Read a tabulated BSDF from a binary file.
"""
function read_fourier_bsdf_table(filename::String)::FourierBSDFTable
    table = FourierBSDFTable()
    
    # Open file in binary mode
    open(filename, "r") do f
        # Helper functions for reading binary data
        function read32(count::Integer)
            data = Vector{Int32}(undef, count)
            read!(f, data)
            if ENDIAN_BOM == 0x01020304  # Big endian check
                # Julia's ntoh function handles byte swapping
                data .= ntoh.(data)
            end
            return data
        end
        
        function readfloat(count::Integer)
            data = Vector{Float32}(undef, count)
            read!(f, data)
            if ENDIAN_BOM == 0x01020304  # Big endian check
                data .= ntoh.(data)
            end
            return Float64.(data)  # Convert to Float64
        end
        
        # Read and verify header
        header_exp = UInt8['S', 'C', 'A', 'T', 'F', 'U', 'N', 0x01]
        header = read(f, 8)
        
        if header != header_exp
            @error "Tabulated BSDF file \"$filename\" has an incompatible file format or version."
            return nothing
        end
        
        # Read metadata
        flags = read32(1)[1]
        table.nMu = read32(1)[1]
        nCoeffs = read32(1)[1]
        table.mMax = read32(1)[1]
        table.nChannels = read32(1)[1]
        nBases = read32(1)[1]
        unused = read32(3)  # Skip unused fields
        table.eta = readfloat(1)[1]
        unused = read32(4)  # Skip more unused fields
        
        # Verify supported format
        if flags != 1 || (table.nChannels != 1 && table.nChannels != 3) || nBases != 1
            @error "Unsupported BSDF format in file \"$filename\"."
            return nothing
        end
        
        # Allocate and read data arrays
        table.mu = readfloat(table.nMu)
        table.cdf = readfloat(table.nMu * table.nMu)
        
        offsetAndLength = read32(table.nMu * table.nMu * 2)
        table.a = readfloat(nCoeffs)
        
        # Process offset and length data
        table.aOffset = Vector{Int}(undef, table.nMu * table.nMu)
        table.m = Vector{Int}(undef, table.nMu * table.nMu)
        table.a0 = Vector{Float64}(undef, table.nMu * table.nMu)
        
        for i in 0:(table.nMu * table.nMu - 1)
            offset = offsetAndLength[2*i + 1]
            length = offsetAndLength[2*i + 2]
            table.aOffset[i+1] = offset
            table.m[i+1] = length
            table.a0[i+1] = length > 0 ? table.a[offset+1] : 0.0
        end
        
        # Compute reciprocals
        table.recip = Vector{Float64}(undef, table.mMax)
        for i in 1:table.mMax
            table.recip[i] = 1.0 / (i-1)
        end
        
        return table
    end
    return table
end