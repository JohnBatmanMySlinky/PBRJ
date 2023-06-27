function make_name(n::Int64)::Symbol
    @assert n ≤ 26^2
    second = n ÷ 26
    first = n - 26 * second
    ascii_offset = 96

    if second == 0
        return Symbol(Char(ascii_offset + first + 1))
    else
        return Symbol(Char(ascii_offset + first + 1)Char(ascii_offset + second))
    end
end
    
macro make_spectrum(N)
    fields=[:($(make_name(i))::Float64) for i in 0:(eval(N)-1)]
    esc(quote struct Spectrum <: FieldVector{$N, Float64}
        $(fields...)
        end
    end)
end

