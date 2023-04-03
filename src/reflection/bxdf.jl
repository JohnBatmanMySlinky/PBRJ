#14.1 sampling reflection functions
function sample_f(bxdf::AbstractBxDF, wo::Vec3, u::Pnt2)
    wi = cosine_sample_hemisphere(u)
    if wo.z < 0 
        wi = Vec3(wi.x, wi.y, wi.z * -1)
    end
    pdf_val = compute_pdf(bxdf, wo, wi)
    f_val = f(bxdf, wo, wi)
    return wi, pdf_val, f_val, nothing
end

function compute_pdf(bxdf::AbstractBxDF, wo::Vec3, wi::Vec3)::Float64
    return same_hemisphere(wo, wi) ? abs_cos_theta(wi) / pi : 0 
end