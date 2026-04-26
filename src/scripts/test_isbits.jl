# append!(ARGS, ["--scene-number", "4", "--samples-per-pixel", "1", "--image-dim", "10", "10"])
include("../RayTracing.jl")
using .RayTracing: MicrofacetDistributionImpl, FresnelDielectric, FresnelConductor, FresnelNoOp,
                   MicrofacetReflection, spectrum_from_float

distrib = MicrofacetDistributionImpl(0.1, 0.1)
fresnel_d = FresnelDielectric(1.0, 1.5)
fresnel_c = FresnelConductor(spectrum_from_float(1.0), spectrum_from_float(1.5), spectrum_from_float(0.0))
fresnel_n = FresnelNoOp()
r = spectrum_from_float(1.0)

mr_d = MicrofacetReflection(r, distrib, fresnel_d)
mr_c = MicrofacetReflection(r, distrib, fresnel_c)
mr_n = MicrofacetReflection(r, distrib, fresnel_n)

println("MicrofacetReflection{FresnelDielectric}  isbits: ", isbits(mr_d))
println("MicrofacetReflection{FresnelConductor}   isbits: ", isbits(mr_c))
println("MicrofacetReflection{FresnelNoOp}        isbits: ", isbits(mr_n))
println("MicrofacetDistributionImpl               isbits: ", isbits(distrib))
println("FresnelDielectric                        isbits: ", isbits(fresnel_d))
println("FresnelConductor                         isbits: ", isbits(fresnel_c))
println("FresnelNoOp                              isbits: ", isbits(fresnel_n))
println("Spectrum                                 isbits: ", isbits(r))
