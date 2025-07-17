function parse_transform(transform_string)
    # Match "Transform" followed by brackets containing numbers
    pattern = r"Transform\s*\[\s*((?:-?\d+\.?\d*\s*)+)\s*\]"
    match_result = match(pattern, transform_string)
    if match_result !== nothing
        # Extract the numbers from the captured group
        numbers_str = match_result.captures[1]
        # Find all individual numbers and join them
        numbers = eachmatch(r"-?\d+\.?\d*", numbers_str)
        return join([m.match for m in numbers], " ")
    else
        return nothing
    end
end

function parse_sanmiguel(fpath, START, END)
    transforms = String[]
    
    open(fpath, "r") do file
        line_number = 0
        for line in eachline(file)
            line_number += 1
            
            # Skip lines outside our range
            if (line_number < START) || (line_number > END)
                continue
            end
            
            transform = parse_transform(line)
            if transform !== nothing
                push!(transforms, transform)
            end
        end
    end
    
    return transforms
end

function init_materials!()
    path_header = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/"
    materials = Material[]

    mat_vidrio = Glass(
        "mat_vidrio",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_vidrio)

    mat_jardinera_1 = Matte(
        "mat_jardinera_1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/jardinera_1_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/jardinera_1_displacement_2.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_jardinera_1)

    mat_jardinera_2 = Matte(
        "mat_jardinera_2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/fuente_piedra_01.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_jardinera_2)
    
    mat_moldura_detalle_escalera = Matte(
        "mat_moldura_detalle_escalera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/cantera_naranja_liso.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_moldura_detalle_escalera)

    mat_moldura_techo_arcos = Matte(
        "mat_moldura_techo_arcos",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/moldura_volado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_moldura_techo_arcos)

    mat_moldura_techo = Matte(
        "mat_moldura_techo",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/moldura_techo.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/moldura_techo_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_moldura_techo)

    mat_escalera = Matte(
        "mat_escalera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/escalera_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/escalera_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_escalera)

    mat_muros = Matte(
        "mat_muros",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/pared_barro_afinado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_muros)

    mat_techos = Matte(
        "mat_techos",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/techo.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_techos)

    mat_vigas_concreto = Matte(
        "mat_vigas_concreto",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/concreto_02.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_vigas_concreto)
    
    mat_moldura_volado = Matte(
        "mat_moldura_volado",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/moldura_volado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_moldura_volado)
    
    mat_losa_volados = Matte(
        "mat_losa_volados",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/losa.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_losa_volados)
    
    mat_moldura_2_piso = Matte(
        "mat_moldura_2_piso",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/moldura2piso_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/moldura2piso_bump.png"), 
                true
            ),
            ConstantTexture(0.003)
        )
    )
    push!(materials, mat_moldura_2_piso)
    
    mat_piso_interior = Matte(
        "mat_piso_interior",
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_piso_interior)
    
    mat_azotea = Matte(
        "mat_azotea",
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_azotea)
    
    piso_pasillos_arriba = Plastic(
        "piso_pasillos_arriba",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/piso_rustico.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/piso_rustico_Spec.png"), 
                false
            ),
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0))
        ),
        ConstantTexture(0.005),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/piso_rustico_displace2.png"), 
                true
            ),
            ConstantTexture(0.012)
        ),
        true
    )
    push!(materials, piso_pasillos_arriba)
    
    mat_puerta_arco = Plastic(
        "mat_puerta_arco",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_triplay_01.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.113726, 0.113726, 0.113726)),
        ConstantTexture(0.01),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_puerta_arco)
    
    mat_barandal_postes = Plastic(
        "mat_barandal_postes",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/rust_a1.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_barandal_postes)
    
    mat_pared_sanMiguel_b = Matte(
        "mat_pared_sanMiguel_b",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_a.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_b)
    
    mat_pared_sanMiguel_b1 = Matte(
        "mat_pared_sanMiguel_b1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_b1.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/muros_b1.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_pared_sanMiguel_b1)
    
    mat_pared_sanMiguel_c2 = Matte(
        "mat_pared_sanMiguel_c2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_c2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_c2)
    
    mat_pared_sanMiguel_f = Matte(
        "mat_pared_sanMiguel_f",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_f.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_f)
    
    mat_pared_sanMiguel_e = Matte(
        "mat_pared_sanMiguel_e",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_e.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_e)
    
    mat_pared_sanMiguel_d = Matte(
        "mat_pared_sanMiguel_d",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_d.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_d)
    
    mat_pared_sanMiguel_g = Matte(
        "mat_pared_sanMiguel_g",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_g.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_g)
    
    mat_pared_sanMiguel_h = Matte(
        "mat_pared_sanMiguel_h",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_h.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_h)
    
    mat_pared_sanMiguel_i = Matte(
        "mat_pared_sanMiguel_i",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_l.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_i)
    
    mat_pared_sanMiguel_j = Matte(
        "mat_pared_sanMiguel_j",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_j.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_j)
    
    mat_muro_naranja_escalera = Matte(
        "mat_muro_naranja_escalera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_l.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_muro_naranja_escalera)
    
    mat_pared_sanMiguel_m = Matte(
        "mat_pared_sanMiguel_m",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_m.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_m)
    
    mat_pared_sanMiguel_n = Matte(
        "mat_pared_sanMiguel_n",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_n.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_n)
    
    mat_pared_sanMiguel_a = Matte(
        "mat_pared_sanMiguel_a",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_a)
    
    mat_pared_sanMiguel_p2 = Matte(
        "mat_pared_sanMiguel_p2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_p_.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_p2)
    
    mat_pared_sanMiguel_q = Matte(
        "mat_pared_sanMiguel_q",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_q3.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_q)
    
    mat_pared_sanMiguel_q2 = Matte(
        "mat_pared_sanMiguel_q2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_q.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_q2)
    
    mat_pared_sanMiguel_q4 = Matte(
        "mat_pared_sanMiguel_q4",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_q4.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_q4)
    
    mat_techo_vigas = Matte(
        "mat_techo_vigas",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/techo.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_techo_vigas)
    
    mat_pared_sanMiguel_qpatio = Matte(
        "mat_pared_sanMiguel_qpatio",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_q_patio2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_qpatio)
    
    mat_banqueta = Matte(
        "mat_banqueta",
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_banqueta)
    
    mat_tierra = Matte(
        "mat_tierra",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/052terresable.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_tierra)
    
    mat_arcos_lisos_2 = Matte(
        "mat_arcos_lisos_2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/arcos_lisos_2_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/arcos_lisos_2_bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    push!(materials, mat_arcos_lisos_2)
    
    mat_arcos_lisos_3 = Matte(
        "mat_arcos_lisos_3",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/arcos_lisos_3_color_1.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/arcos_lisos_3_bump_1.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    push!(materials, mat_arcos_lisos_3)
    
    mat_pared_sanMiguel_b2 = Matte(
        "mat_pared_sanMiguel_b2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_b2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_b2)
    
    mat_vigas_techo_b = Plastic(
        "mat_vigas_techo_b",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_rustica_2.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0431373, 0.0431373, 0.0431373)),
        ConstantTexture(0.01),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_vigas_techo_b)
    
    mat_vigas_techo_a = Matte(
        "mat_vigas_techo_a",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_rustica_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_vigas_techo_a)
    
    mat_pared_sanMiguel_k = Matte(
        "mat_pared_sanMiguel_k",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/muros_k.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_sanMiguel_k)
    
    mat_piso_patio_exterior_concreto = Matte(
        "mat_piso_patio_exterior_concreto",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/concreto_01.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_piso_patio_exterior_concreto)
    
    mat_vigas_volados = Matte(
        "mat_vigas_volados",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Vigas_A2.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/vigas_a2_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_vigas_volados)
    
    mat_techos_2 = Matte(
        "mat_techos_2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/techo_01.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_techos_2)
    
    mat_piso_patio_exterior = Matte(
        "mat_piso_patio_exterior",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/piso_patio_exterior.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/piso_patio_exterior_displace_inv.png"), 
                true
            ),
            ConstantTexture(0.02)
        )
    )
    push!(materials, mat_piso_patio_exterior)
    
    mat_calle = Matte(
        "mat_calle",
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_calle)
    
    mat_arco_frente = Matte(
        "mat_arco_frente",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/arco_frente.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/arco_frente_displace_inv.png"), 
                true
            ),
            ConstantTexture(0.002)
        )
    )
    push!(materials, mat_arco_frente)
    
    mat_puerta_agarradera01 = Plastic(
        "mat_puerta_agarradera01",
        ConstantTexture(spectrum_from_float(0.337255, 0.286275, 0.223529)),
        ConstantTexture(spectrum_from_float(0.501961, 0.443137, 0.372549)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_puerta_agarradera01)
    
    mat_pintura_15 = Matte(
        "mat_pintura_15",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7785.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_15)
    
    mat_pintura_1 = Matte(
        "mat_pintura_1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/0001_carros.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_1)
    
    mat_pintura_2 = Matte(
        "mat_pintura_2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7815.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_2)
    
    mat_pintura_3 = Matte(
        "mat_pintura_3",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7812.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_3)
    
    mat_pintura_12 = Matte(
        "mat_pintura_12",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/027_Cola Caballo 06-30-1997.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_12)
    
    mat_pintura_5 = Matte(
        "mat_pintura_5",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7812.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_5)
    
    mat_pintura_6 = Matte(
        "mat_pintura_6",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7843.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_6)
    
    mat_pintura_7 = Matte(
        "mat_pintura_7",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7785.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_7)
    
    mat_pintura_8 = Matte(
        "mat_pintura_8",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7758.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_8)
    
    mat_pintura_9 = Matte(
        "mat_pintura_9",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7843.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_9)
    
    mat_pintura_10 = Matte(
        "mat_pintura_10",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_10)
    
    mat_pintura_11 = Matte(
        "mat_pintura_11",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7768.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_11)
    
    mat_pintura_4 = Matte(
        "mat_pintura_4",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_4)
    
    mat_pintura_13 = Matte(
        "mat_pintura_13",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_13)
    
    mat_pintura_14 = Matte(
        "mat_pintura_14",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pintura_14)
    
    mat_pintura_marcos = Plastic(
        "mat_pintura_marcos",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_marcos.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.156863, 0.156863, 0.156863)),
        ConstantTexture(0.001),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_pintura_marcos)
    
    mat_postes_barandal = Matte(
        "mat_postes_barandal",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/postes_barandal_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/postes_barandal_bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    push!(materials, mat_postes_barandal)
    
    mat_piso_patio_exterior2 = Matte(
        "mat_piso_patio_exterior2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/piso_patio_exterior2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_piso_patio_exterior2)
    
    mat_sun_light = Matte(
        "mat_sun_light",
        ConstantTexture(spectrum_from_float(5.0, 4.1960802078, 2.4509799480)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_sun_light)
    
    mat_barandal_detalle_extremos = Plastic(
        "mat_barandal_detalle_extremos",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/rust_a1.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.01),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_barandal_detalle_extremos)
    
    mat_madera_barandal = Plastic(
        "mat_madera_barandal",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_barandal_esc_2.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_madera_barandal)
    
    mat_pared_calle = Matte(
        "mat_pared_calle",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/pared_calle.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pared_calle)
    
    mat_candil_2_foco = Glass(
        "mat_candil_2_foco",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_candil_2_foco)
    
    mat_detMoldura_06 = Matte(
        "mat_detMoldura_06",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/detmoldura_06_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/detmoldura_06_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_detMoldura_06)
    
    mat_detMoldura_05 = Matte(
        "mat_detMoldura_05",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/detmoldura_05_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/detmoldura_05_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_detMoldura_05)
    
    mat_detMoldura_04 = Matte(
        "mat_detMoldura_04",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/detmoldura_04_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/detmoldura_04_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_detMoldura_04)
    
    mat_detMoldura_03 = Matte(
        "mat_detMoldura_03",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/detmoldura_03_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/detmoldura_03_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_detMoldura_03)
    
    mat_detMoldura_02 = Matte(
        "mat_detMoldura_02",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/detmoldura_02_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/detmoldura_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_detMoldura_02)
    
    mat_detMoldura_01 = Matte(
        "mat_detMoldura_01",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/detmoldura_01_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/detmoldura_01_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_detMoldura_01)
    
    mat_detalle_escalera = Matte(
        "mat_detalle_escalera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/rust_a1.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_detalle_escalera)
    
    mat_marco_puerta_1 = Matte(
        "mat_marco_puerta_1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/marco_puerta_1.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/marco_puerta_1_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_marco_puerta_1)
    
    mat_marco_puerta = Plastic(
        "mat_marco_puerta",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_barandal_esc_2.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/madera_barandal_esc_2_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        ),
        true
    )
    push!(materials, mat_marco_puerta)
    
    mat_mold_arco_01 = Matte(
        "mat_mold_arco_01",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/mold_arco_01_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/mold_arco_01_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_mold_arco_01)
    
    mat_mold_terraza = Matte(
        "mat_mold_terraza",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/molduraterraza__color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/molduraterraza_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_mold_terraza)
    
    mat_puerta_agarradera = Matte(
        "mat_puerta_agarradera",
        ConstantTexture(spectrum_from_float(0.392157, 0.368627, 0.341176)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_puerta_agarradera)
    
    mat_puerta_arco = Plastic(
        "mat_puerta_arco",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/madera_triplay_01.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.113726, 0.113726, 0.113726)),
	    ConstantTexture(0.01),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_puerta_arco)
    
    mat_puerta_01 = Plastic(
        "mat_puerta_01",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/puerta.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0431373, 0.0431373, 0.0431373)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/puerta_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        ),
        true,
    )
    push!(materials, mat_puerta_01)
    
    mat_columna_a1 = Matte(
        "mat_columna_a1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/columna_a_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/columna_a_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_columna_a1)
    
    mat_columna_a2 = Matte(
        "mat_columna_a2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/columna_a_color_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/columna_a_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_columna_a2)
    
    mat_columna_a3 = Matte(
        "mat_columna_a3",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/columna_a_color_3.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/columna_a_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_columna_a3)
    
    mat_columna_b1 = Matte(
        "mat_columna_b1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/columna_b_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/columna_b_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    push!(materials, mat_columna_b1)
    
    mat_columna_b3 = Matte(
        "mat_columna_b3",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/columna_b_color_3.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/columna_b_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    push!(materials, mat_columna_b3)
    
    mat_columna_b2 = Matte(
        "mat_columna_b2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/columna_b_color_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/columna_b_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    push!(materials, mat_columna_b2)
    
    mat_light_patio06_mat01 = Matte(
        "mat_light_patio06_mat01",
        ConstantTexture(spectrum_from_float(4.4705901146, 4.9411802292, 5.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_light_patio06_mat01)
    
    mat_negro = Matte(
        "mat_negro",
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_negro)
    
    mat_candil_2_glass = Glass(
        "mat_candil_2_glass",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_candil_2_glass)
    
    mat_agua = Glass(
        "mat_agua",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.33),
        nothing,
        true
    )
    push!(materials, mat_agua)
    
    mat_fuente_centro = Matte(
        "mat_fuente_centro",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/fuente_piedra_02.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_fuente_centro)
    
    mat_fuente_fondo = Plastic(
        "mat_fuente_fondo",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/fuente_azulejo.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_fuente_fondo)
    
    mat_fuente = Matte(
        "mat_fuente",
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_fuente)
    
    mat_barandal_detalle_centro = Plastic(
        "mat_barandal_detalle_centro",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/rust_detalle.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/rust_detalle_bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        ),
        true
    )
    push!(materials, mat_barandal_detalle_centro)
    
    mat_candil_cadena = Plastic(
        "mat_candil_cadena",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/fierro_b.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.313726, 0.313726, 0.313726)),
        ConstantTexture(0.05),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_candil_cadena)
    
    mat_candil_metal = Plastic(
        "mat_candil_metal",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/fierro_b.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_candil_metal)
    
    mat_fake_foco = Glass(
        "mat_fake_foco",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_fake_foco)
    
    mat_candil_foco = Glass(
        "mat_candil_foco",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_candil_foco)
    
    mat_candil_madera = Plastic(
        "mat_candil_madera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/candil_madera.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.164706, 0.164706, 0.164706)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_candil_madera)
    
    mat_candil_2 = Plastic(
        "mat_candil_2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/metal_viejo_2.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.301961, 0.301961, 0.301961)),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/metal_viejo_2.png"), 
                true
            ),
            ConstantTexture(0.1)
        ),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/metal_viejo_2.png"), 
                true
            ),
            ConstantTexture(0.002)
        ),
        true
    )
    push!(materials, mat_candil_2)
    
    mat_candil_2_negro = Plastic(
        "mat_candil_2_negro",
        ConstantTexture(spectrum_from_float(0.0588235, 0.0588235, 0.0588235)),
        ConstantTexture(spectrum_from_float(0.301961, 0.301961, 0.301961)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_candil_2_negro)
    
    mat_escurridera = Matte(
        "mat_escurridera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/escurridera_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/escurridera_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_escurridera)
    
    mat_hoja_seca_2C = Matte(
        "mat_hoja_seca_2C",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_leaf_seca_03b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_hoja_seca_2C)
    
    mat_hoja_seca_2B = Matte(
        "mat_hoja_seca_2B",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_leaf_seca_02b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_hoja_seca_2B)
    
    mat_hoja_seca_2A = Matte(
        "mat_hoja_seca_2A",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_hoja_c_seca.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_hoja_seca_2A)
    
    mat_teja = Matte(
        "mat_teja",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Barro_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_teja)
    
    mat_tronco = Matte(
        "mat_tronco",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_tronco.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/sm_tronco_bump.png"), 
                true
            ),
            ConstantTexture(0.02)
        )
    )
    push!(materials, mat_tronco)
    
    mat_leave_A_a = Matte(
        "mat_leave_A_a",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_leaf_02a.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/sm_leaf_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_leave_A_a)
    
    mat_leave_A_b = Matte(
        "mat_leave_A_b",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_leaf_02b.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/sm_leaf_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_leave_A_b)
    
    mat_leave_A_c = Matte(
        "mat_leave_A_c",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/sm_leaf_03a.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/sm_leaf_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_leave_A_c)
    
    mat_hoja_verde_b = Matte(
        "mat_hoja_verde_b",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/l33-upper.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/l33-upper.png"), 
                true
            ),
            ConstantTexture(0.1)
        )
    )
    push!(materials, mat_hoja_verde_b)
    
    mat_hoja_verde_a = Matte(
        "mat_hoja_verde_a",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/l37-upper.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/l37-upper.png"), 
                true
            ),
            ConstantTexture(0.1)
        )
    )
    push!(materials, mat_hoja_verde_a)
    
    mat_hojas_rojas_top = Matte(
        "mat_hojas_rojas_top",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/l04-upper.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/l04-upper.png"), 
                true
            ),
            ConstantTexture(0.1)
        )
    )
    push!(materials, mat_hojas_rojas_top)

    mat_forja_macetas = Plastic(
        "mat_forja_macetas",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Forja_Macetas.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.164706, 0.164706, 0.164706)),
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Forja_Macetas_bump.png"), 
            true
        ),
        nothing,
        nothing,
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Forja_Macetas_bump.png"), 
            true
        ),
        true
    )
    push!(materials, mat_forja_macetas)

    mat_maceta_A = Matte(
        "mat_maceta_A",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_A_Color.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_A_Bump.png"), 
                true
            ),
            ConstantTexture(40.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_A_Bump.png"), 
                true
            ),
            ConstantTexture(0.005)
        )
    )
    push!(materials, mat_maceta_A)

    mat_maceta_A2 = Matte(
        "mat_maceta_A2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_A2_Color.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_A_Bump.png"), 
                true
            ),
            ConstantTexture(30.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_A_Bump.png"), 
                true
            ),
            ConstantTexture(0.005)
        )
    )
    push!(materials, mat_maceta_A2)

    mat_maceta_B = Matte(
        "mat_maceta_B",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_B_Color.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_B_Bump.png"), 
                true
            ),
            ConstantTexture(30.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_B_Bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    push!(materials, mat_maceta_B)

    mat_maceta_B2 = Matte(
        "mat_maceta_B2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_B2_Color.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_B_Bump.png"), 
                true
            ),
            ConstantTexture(35.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_B_Bump.png"), 
                true
            ),
            ConstantTexture(0.005)
        )
    )
    push!(materials, mat_maceta_B2)

    mat_maceta_C = Matte(
        "mat_maceta_C",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_C_Color.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_C_Bump.png"), 
                true
            ),
            ConstantTexture(30.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_C_Bump.png"), 
                true
            ),
            ConstantTexture(0.005)
        )
    )
    push!(materials, mat_maceta_C)

    mat_maceta_C2 = Matte(
        "mat_maceta_C2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_C2_Color.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_C_Bump.png"), 
                true
            ),
            ConstantTexture(40.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_C_Bump.png"), 
                true
            ),
            ConstantTexture(0.02)
        )
    )
    push!(materials, mat_maceta_C2)

    mat_maceta_D2 = Matte(
        "mat_maceta_D2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Maceta_D2_Color_0.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_D_Bump_0.png"), 
                true
            ),
            ConstantTexture(20.0)
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Maceta_D_Bump_0.png"), 
                true
            ),
            ConstantTexture(0.005)
        )
    )
    push!(materials, mat_maceta_D2)

    mat_plato_A = Plastic(
        "mat_plato_A",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/plato_a.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.129412, 0.129412, 0.129412)),
        ConstantTexture(0.005),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_plato_A)

    mat_individual_verde = Plastic(
        "mat_individual_verde",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/individual_b.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_individual_verde)

    mat_cenicero = Plastic(
        "mat_cenicero",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/cenicero.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.215686, 0.215686, 0.215686)),
        ConstantTexture(0.002),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_cenicero)

    mat_base_vera_color = Plastic(
        "mat_base_vera_color",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/ceramic_tile.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_base_vera_color)

    mat_vela = Plastic(
        "mat_vela",
        ConstantTexture(spectrum_from_float(0.776471, 0.756863, 0.721569)),
        ConstantTexture(spectrum_from_float(0.321569, 0.321569, 0.321569)),
        ConstantTexture(0.8),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_vela)

    mat_vela_mecha = Matte(
        "mat_vela_mecha",
        ConstantTexture(spectrum_from_float(0.121569, 0.113726, 0.101961)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_vela_mecha)

    mat_pimienta = Matte(
        "mat_pimienta",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/PITTED.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/PITTED.png"), 
                true
            ),
            ConstantTexture(0.8)
        )
    )
    push!(materials, mat_pimienta)

    mat_cromo = Plastic(
        "mat_cromo",
        ConstantTexture(spectrum_from_float(0.0862745, 0.0823529, 0.0745098)),
        ConstantTexture(spectrum_from_float(0.898039, 0.807843, 0.709804)),
        ConstantTexture(0.002),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_cromo)

    mat_sal = Matte(
        "mat_sal",
        ConstantTexture(spectrum_from_float(0.776471, 0.74902, 0.709804)),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/PITTED.png"), 
                true
            ),
            ConstantTexture(0.2)
        )
    )
    push!(materials, mat_sal)

    mat_plastico_cubiertos = Glass(
        "mat_plastico_cubiertos",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(0.694118, 0.850981, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_plastico_cubiertos)

    mat_copas = Glass(
        "mat_copas",
        ConstantTexture(spectrum_from_float(0.545098, 0.545098, 0.545098)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_copas)

    mat_vidriosalero = Glass(
        "mat_vidriosalero",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_vidriosalero)

    mat_vidriosalero = Glass(
        "mat_vidriosalero",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_vidriosalero)

    mat_silla_d_tachuelas  = Plastic(
        "mat_silla_d_tachuelas",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Fierro_A.png"), 
            false
        ),
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Fierro_A_Bump.png"), 
            false
        ),
        ConstantTexture(0.6),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Fierro_A_Bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        ),
        true
    )
    push!(materials, mat_silla_d_tachuelas)

    mat_silla_d_piel = Plastic(
        "mat_silla_d_piel",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/silla_d_piel.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0784314, 0.0784314, 0.0784314)),
        ConstantTexture(0.2),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/silla_d_piel_bump.png"), 
                true
            ),
            ConstantTexture(0.005)
        ),
        true
    )
    push!(materials, mat_silla_d_piel)

    mat_silla_d_madera = Plastic(
        "mat_silla_d_madera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/WOOD08.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.156863, 0.156863, 0.156863)),
        ConstantTexture(0.15),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/WOOD08_Bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        ),
        true
    )
    push!(materials, mat_silla_d_madera)

    mat_mesa_d_madera_patas = Plastic(
        "mat_mesa_d_madera_patas",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/WOOD08.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/WOOD08_Bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        ),
        true
    )
    push!(materials, mat_mesa_d_madera_patas)

    mat_mesa_d_talabera = Plastic(
        "mat_mesa_d_talabera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/tapa_talabera.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_mesa_d_talabera)

    mat_mesa_d_madera_orilla = Plastic(
        "mat_mesa_d_madera_orilla",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/WOOD08.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/WOOD08_Bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        ),
        true
    )
    push!(materials, mat_mesa_d_madera_orilla)

    mat_tela_mesa_d_2 = Matte(
        "mat_tela_mesa_d_2",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/tela_mesa_d.png"), 
            false
        ),
        ConstantTexture(20.0),
        nothing
    )
    push!(materials, mat_tela_mesa_d_2)

    mat_tela_mesa_d = Matte(
        "mat_tela_mesa_d",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/tela_mesa_b.png"), 
            false
        ),
        ConstantTexture(5.0),
        nothing
    )
    push!(materials, mat_tela_mesa_d)

    mat_madera_silla = Plastic(
        "mat_madera_silla",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/WOOD08.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.243137, 0.243137, 0.243137)),
        ConstantTexture(0.01),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/WOOD08_Bump.png"), 
                true
            ),
            ConstantTexture(0.002)
        ),
        true
    )
    push!(materials, mat_madera_silla)
    
    mat_silla_tela = Matte(
        "mat_silla_tela",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Finishes.Flooring.Carpet.Loop.5.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Finishes.Flooring.Carpet.Loop.5.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    push!(materials, mat_silla_tela)

    mat_madera_mesa_arriba = Plastic(
        "mat_madera_mesa_arriba",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/BWK_1024.png"), 
            false
        ),
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/bwk_1024_Spec2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/bwk_1024_Bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        ),
        true
    )
    push!(materials, mat_madera_mesa_arriba)

    mat_tela_mesa_1 = Matte(
        "mat_tela_mesa_1",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/tela_blanca.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/tela_blanca.png"), 
                true
            ),
            ConstantTexture(0.002)
        ),
    )
    push!(materials, mat_tela_mesa_1)

    mat_sila_forja_a_metal = Plastic(
        "mat_sila_forja_a_metal",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Fierro_A.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.2, 0.2, 0.2)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(1.0, -1.0, 0.0, 1.0),
                jmfp(path_header * "textures/Fierro_A_Bump.png"), 
                true
            ),
            ConstantTexture(0.005)
        ),
        true
    )
    push!(materials, mat_sila_forja_a_metal)

    mat_sila_forja_a_madera = Matte(
        "mat_sila_forja_a_madera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/wood.3.Bubinga.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_sila_forja_a_madera)

    mat_sila_forja_a_tela = Plastic(
        "mat_sila_forja_a_tela",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/tela_silla_b.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_sila_forja_a_tela)

    mat_standard_7 = Matte(
        "mat_standard_7",
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_standard_7)

    mat_mesa_madera = Matte(
        "mat_mesa_madera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/Vigas_B.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_mesa_madera)

    mat_silla_c_madera = Matte(
        "mat_silla_c_madera",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/BWK_1024.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_silla_c_madera)

    mat_silla_c_tela = Matte(
        "mat_silla_c_tela",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/tela_silla_b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_silla_c_tela)

    mat_base_vela_color = Plastic(
        "mat_base_vela_color",
        ImageTexture(
            UVMapping2D(1.0, -1.0, 0.0, 1.0),
            jmfp(path_header * "textures/ceramic_tile.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_base_vela_color)


    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)
end

function init_textures!()
    path_header = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/"
    textures = AbstractTexture[]
    tex_HojaSecaMask = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/sm_hoja_c_seca_Mask.png"), 
        true,
        "tex_HojaSecaMask"
    )
    push!(textures, tex_HojaSecaMask)

    tex_leave_A_a_alpha = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/sm_leaf_02_alpah.png"), 
        true,
        "tex_leave_A_a_alpha"
    )
    push!(textures, tex_leave_A_a_alpha)

    tex_leave_A_b_alpha = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/sm_leaf_02_alpah.png"), 
        true,
        "tex_leave_A_b_alpha"
    )
    push!(textures, tex_leave_A_b_alpha)

    tex_leave_A_c_alpha = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/sm_leaf_02_alpah.png"), 
        true,
        "tex_leave_A_c_alpha"
    )
    push!(textures, tex_leave_A_c_alpha)

    tex_26 = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/l33-clip.png"), 
        true,
        "tex_26"
    )
    push!(textures, tex_26)

    tex_28 = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/l37-clip.png"), 
        true,
        "tex_28"
    )
    push!(textures, tex_28)

    tex_30 = ImageTexture(
        UVMapping2D(1.0, -1.0, 0.0, 1.0),
        jmfp(path_header * "textures/l04-clip.png"), 
        true,
        "tex_30"
    )
    push!(textures, tex_30)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(textures))
    ALPHA_TEXTURE_REGISTRY[] = AlphaTextureRegistry(textures, name_index)
end

function make_scene21(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    path_header = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/"

    #######################################
    #######################################
    ############## materials
    #######################################
    #######################################
    println("LOADING MATERIALS")
    init_materials!()
    


    #######################################
    #######################################
    ############## (alpha) textures
    #######################################
    #######################################

    init_textures!()
   

    #######################################
    #######################################
    ############## mat_dict
    #######################################
    #######################################

    mat_dict = Dict{String, String}()

    mat_dict["sanmiguel_00001_ascii.obj"] = "mat_vidrio"
    mat_dict["sanmiguel_00073_ascii.obj"] = "mat_vidrio"

    mat_dict["sanmiguel_00002_ascii.obj"] = "mat_jardinera_1"
    mat_dict["sanmiguel_00003_ascii.obj"] = "mat_jardinera_1"

    mat_dict["sanmiguel_00004_ascii.obj"] = "mat_moldura_detalle_escalera"

    mat_dict["sanmiguel_00005_ascii.obj"] = "mat_moldura_techo_arcos"

    mat_dict["sanmiguel_00006_ascii.obj"] = "mat_moldura_techo"

    mat_dict["sanmiguel_00007_ascii.obj"] = "mat_escalera"

    mat_dict["sanmiguel_00008_ascii.obj"] = "mat_muros"
    mat_dict["sanmiguel_00037_ascii.obj"] = "mat_muros"
    mat_dict["sanmiguel_00041_ascii.obj"] = "mat_muros"

    mat_dict["sanmiguel_00009_ascii.obj"] = "mat_techos"

    mat_dict["sanmiguel_00010_ascii.obj"] = "mat_vigas_concreto"

    mat_dict["sanmiguel_00011_ascii.obj"] = "mat_moldura_volado"

    mat_dict["sanmiguel_00012_ascii.obj"] = "mat_losa_volados"

    mat_dict["sanmiguel_00013_ascii.obj"] = "mat_moldura_2_piso"

    mat_dict["sanmiguel_00014_ascii.obj"] = "mat_piso_interior"
    mat_dict["sanmiguel_00016_ascii.obj"] = "mat_piso_interior"
    mat_dict["sanmiguel_00018_ascii.obj"] = "mat_piso_interior"

    mat_dict["sanmiguel_00015_ascii.obj"] = "mat_azotea"

    mat_dict["sanmiguel_00017_ascii.obj"] = "piso_pasillos_arriba"
    mat_dict["sanmiguel_00055_ascii.obj"] = "piso_pasillos_arriba"

    mat_dict["sanmiguel_00019_ascii.obj"] = "mat_puerta_arco"
    mat_dict["sanmiguel_00020_ascii.obj"] = "mat_puerta_arco"
    mat_dict["sanmiguel_00201_ascii.obj"] = "mat_puerta_arco"
    mat_dict["sanmiguel_00202_ascii.obj"] = "mat_puerta_arco"

    mat_dict["sanmiguel_00021_ascii.obj"] = "mat_barandal_postes"

    mat_dict["sanmiguel_00022_ascii.obj"] = "mat_pared_sanMiguel_b"

    mat_dict["sanmiguel_00023_ascii.obj"] = "mat_pared_sanMiguel_b1"

    mat_dict["sanmiguel_00024_ascii.obj"] = "mat_pared_sanMiguel_c2"

    mat_dict["sanmiguel_00025_ascii.obj"] = "mat_pared_sanMiguel_f"

    mat_dict["sanmiguel_00026_ascii.obj"] = "mat_pared_sanMiguel_e"

    mat_dict["sanmiguel_00027_ascii.obj"] = "mat_pared_sanMiguel_d"

    mat_dict["sanmiguel_00028_ascii.obj"] = "mat_pared_sanMiguel_g"

    mat_dict["sanmiguel_00029_ascii.obj"] = "mat_pared_sanMiguel_h"

    mat_dict["sanmiguel_00030_ascii.obj"] = "mat_pared_sanMiguel_i"

    mat_dict["sanmiguel_00031_ascii.obj"] = "mat_pared_sanMiguel_j"

    mat_dict["sanmiguel_00032_ascii.obj"] = "mat_muro_naranja_escalera"

    mat_dict["sanmiguel_00033_ascii.obj"] = "mat_pared_sanMiguel_m"

    mat_dict["sanmiguel_00034_ascii.obj"] = "mat_pared_sanMiguel_n"

    mat_dict["sanmiguel_00035_ascii.obj"] = "mat_pared_sanMiguel_a"

    mat_dict["sanmiguel_00036_ascii.obj"] = "mat_pared_sanMiguel_p2"

    mat_dict["sanmiguel_00038_ascii.obj"] = "mat_pared_sanMiguel_q"

    mat_dict["sanmiguel_00039_ascii.obj"] = "mat_pared_sanMiguel_q2"

    mat_dict["sanmiguel_00040_ascii.obj"] = "mat_pared_sanMiguel_q4"

    mat_dict["sanmiguel_00042_ascii.obj"] = "mat_techo_vigas"

    mat_dict["sanmiguel_00043_ascii.obj"] = "mat_tierra"
    mat_dict["sanmiguel_00046_ascii.obj"] = "mat_tierra"
    mat_dict["sanmiguel_00047_ascii.obj"] = "mat_tierra"

    mat_dict["sanmiguel_00044_ascii.obj"] = "mat_pared_sanMiguel_qpatio"

    mat_dict["sanmiguel_00045_ascii.obj"] = "mat_banqueta"

    mat_dict["sanmiguel_00048_ascii.obj"] = "mat_arcos_lisos_2"
    mat_dict["sanmiguel_00049_ascii.obj"] = "mat_arcos_lisos_2"

    mat_dict["sanmiguel_00050_ascii.obj"] = "mat_arcos_lisos_3"

    mat_dict["sanmiguel_00051_ascii.obj"] = "mat_pared_sanMiguel_b2"

    mat_dict["sanmiguel_00052_ascii.obj"] = "mat_vigas_techo_b"

    mat_dict["sanmiguel_00053_ascii.obj"] = "mat_vigas_techo_a"

    mat_dict["sanmiguel_00054_ascii.obj"] = "mat_pared_sanMiguel_k"

    mat_dict["sanmiguel_00056_ascii.obj"] = "mat_piso_patio_exterior_concreto"

    mat_dict["sanmiguel_00057_ascii.obj"] = "mat_vigas_volados"

    mat_dict["sanmiguel_00058_ascii.obj"] = "mat_techos_2"

    mat_dict["sanmiguel_00059_ascii.obj"] = "mat_piso_patio_exterior"

    mat_dict["sanmiguel_00060_ascii.obj"] = "mat_jardinera_2"

    mat_dict["sanmiguel_00061_ascii.obj"] = "mat_calle"

    mat_dict["sanmiguel_00062_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00063_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00064_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00065_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00066_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00067_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00068_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00069_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00070_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00071_ascii.obj"] = "mat_arco_frente"
    mat_dict["sanmiguel_00072_ascii.obj"] = "mat_arco_frente"

    mat_dict["sanmiguel_00074_ascii.obj"] = "mat_puerta_agarradera01"

    mat_dict["sanmiguel_00075_ascii.obj"] = "mat_pintura_15"

    mat_dict["sanmiguel_00076_ascii.obj"] = "mat_pintura_1"

    mat_dict["sanmiguel_00077_ascii.obj"] = "mat_pintura_2"

    mat_dict["sanmiguel_00078_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00090_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00091_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00092_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00093_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00094_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00095_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00096_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00097_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00098_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00099_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00100_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00101_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00102_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00103_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00104_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00105_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00106_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00107_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00108_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00109_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00110_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00111_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00112_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00113_ascii.obj"] = "mat_pintura_3"
    mat_dict["sanmiguel_00114_ascii.obj"] = "mat_pintura_3"

    mat_dict["sanmiguel_00079_ascii.obj"] = "mat_pintura_12"

    mat_dict["sanmiguel_00080_ascii.obj"] = "mat_pintura_5"

    mat_dict["sanmiguel_00081_ascii.obj"] = "mat_pintura_6"

    mat_dict["sanmiguel_00082_ascii.obj"] = "mat_pintura_7"

    mat_dict["sanmiguel_00083_ascii.obj"] = "mat_pintura_8"

    mat_dict["sanmiguel_00084_ascii.obj"] = "mat_pintura_9"

    mat_dict["sanmiguel_00085_ascii.obj"] = "mat_pintura_10"

    mat_dict["sanmiguel_00086_ascii.obj"] = "mat_pintura_11"

    mat_dict["sanmiguel_00087_ascii.obj"] = "mat_pintura_4"

    mat_dict["sanmiguel_00088_ascii.obj"] = "mat_pintura_13"

    mat_dict["sanmiguel_00089_ascii.obj"] = "mat_pintura_14"

    mat_dict["sanmiguel_00115_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00116_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00117_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00118_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00119_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00120_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00121_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00122_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00123_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00124_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00125_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00126_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00127_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00128_ascii.obj"] = "mat_pintura_marcos"
    mat_dict["sanmiguel_00129_ascii.obj"] = "mat_pintura_marcos"

    mat_dict["sanmiguel_00130_ascii.obj"] = "mat_postes_barandal"
    mat_dict["sanmiguel_00131_ascii.obj"] = "mat_postes_barandal"

    mat_dict["sanmiguel_00132_ascii.obj"] = "mat_piso_patio_exterior2"

    mat_dict["sanmiguel_00133_ascii.obj"] = "mat_sun_light"

    mat_dict["sanmiguel_00134_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00135_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00136_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00137_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00139_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00141_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00146_ascii.obj"] = "mat_barandal_detalle_extremos"
    mat_dict["sanmiguel_00166_ascii.obj"] = "mat_barandal_detalle_extremos"

    mat_dict["sanmiguel_00138_ascii.obj"] = "mat_barandal_detalle_centro"

    mat_dict["sanmiguel_00140_ascii.obj"] = "mat_madera_barandal"

    mat_dict["sanmiguel_00142_ascii.obj"] = "mat_pared_calle"

    mat_dict["sanmiguel_00143_ascii.obj"] = "mat_candil_cadena"

    mat_dict["sanmiguel_00144_ascii.obj"] = "mat_candil_metal"
    mat_dict["sanmiguel_00145_ascii.obj"] = "mat_candil_metal"

    mat_dict["sanmiguel_00146_ascii.obj"] = "mat_fake_foco"

    mat_dict["sanmiguel_00147_ascii.obj"] = "mat_candil_foco"

    mat_dict["sanmiguel_00148_ascii.obj"] = "mat_candil_madera"
    mat_dict["sanmiguel_00149_ascii.obj"] = "mat_candil_madera"

    mat_dict["sanmiguel_00150_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00151_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00152_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00153_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00154_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00157_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00158_ascii.obj"] = "mat_candil_2"
    mat_dict["sanmiguel_00159_ascii.obj"] = "mat_candil_2"

    mat_dict["sanmiguel_00155_ascii.obj"] = "mat_candil_2_negro"

    mat_dict["sanmiguel_00156_ascii.obj"] = "mat_candil_2_foco"

    mat_dict["sanmiguel_00160_ascii.obj"] = "mat_detMoldura_06"

    mat_dict["sanmiguel_00161_ascii.obj"] = "mat_detMoldura_05"

    mat_dict["sanmiguel_00162_ascii.obj"] = "mat_detMoldura_04"

    mat_dict["sanmiguel_00163_ascii.obj"] = "mat_detMoldura_03"

    mat_dict["sanmiguel_00164_ascii.obj"] = "mat_detMoldura_02"

    mat_dict["sanmiguel_00165_ascii.obj"] = "mat_detMoldura_01"

    mat_dict["sanmiguel_00167_ascii.obj"] = "mat_escurridera"

    mat_dict["sanmiguel_00168_ascii.obj"] = "mat_detalle_escalera"
    mat_dict["sanmiguel_00169_ascii.obj"] = "mat_detalle_escalera"
    mat_dict["sanmiguel_00170_ascii.obj"] = "mat_detalle_escalera"

    mat_dict["sanmiguel_00171_ascii.obj"] = "mat_hoja_seca_2C"

    mat_dict["sanmiguel_00172_ascii.obj"] = "mat_hoja_seca_2B"

    mat_dict["sanmiguel_00173_ascii.obj"] = "mat_hoja_seca_2A"

    mat_dict["sanmiguel_00174_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00175_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00176_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00177_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00178_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00179_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00180_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00181_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00182_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00183_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00184_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00185_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00186_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00187_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00188_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00189_ascii.obj"] = "mat_marco_puerta_1"
    mat_dict["sanmiguel_00190_ascii.obj"] = "mat_marco_puerta_1"

    mat_dict["sanmiguel_00191_ascii.obj"] = "mat_marco_puerta"

    mat_dict["sanmiguel_00192_ascii.obj"] = "mat_mold_arco_01"
    mat_dict["sanmiguel_00193_ascii.obj"] = "mat_mold_arco_01"
    mat_dict["sanmiguel_00194_ascii.obj"] = "mat_mold_arco_01"
    mat_dict["sanmiguel_00195_ascii.obj"] = "mat_mold_arco_01"
    mat_dict["sanmiguel_00196_ascii.obj"] = "mat_mold_arco_01"
    mat_dict["sanmiguel_00197_ascii.obj"] = "mat_mold_arco_01"

    mat_dict["sanmiguel_00198_ascii.obj"] = "mat_mold_terraza"
    mat_dict["sanmiguel_00199_ascii.obj"] = "mat_mold_terraza"

    mat_dict["sanmiguel_00200_ascii.obj"] = "mat_puerta_agarradera"

    mat_dict["sanmiguel_00201_ascii.obj"] = "mat_puerta_arco"
    mat_dict["sanmiguel_00202_ascii.obj"] = "mat_puerta_arco"

    mat_dict["sanmiguel_00203_ascii.obj"] = "mat_puerta_01"

    mat_dict["sanmiguel_00204_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00205_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00206_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00207_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00208_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00209_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00210_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00211_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00212_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00213_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00214_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00215_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00216_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00217_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00218_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00219_ascii.obj"] = "mat_teja"
    mat_dict["sanmiguel_00220_ascii.obj"] = "mat_teja"

    mat_dict["sanmiguel_00221_ascii.obj"] = "mat_columna_a1"
    mat_dict["sanmiguel_00224_ascii.obj"] = "mat_columna_a1"
    mat_dict["sanmiguel_00225_ascii.obj"] = "mat_columna_a1"

    mat_dict["sanmiguel_00222_ascii.obj"] = "mat_columna_a2"
    mat_dict["sanmiguel_00231_ascii.obj"] = "mat_columna_a2"
    
    mat_dict["sanmiguel_00223_ascii.obj"] = "mat_columna_a3"

    mat_dict["sanmiguel_00226_ascii.obj"] = "mat_columna_b1"
    mat_dict["sanmiguel_00227_ascii.obj"] = "mat_columna_b1"
    mat_dict["sanmiguel_00229_ascii.obj"] = "mat_columna_b1"
    mat_dict["sanmiguel_00232_ascii.obj"] = "mat_columna_b1"

    mat_dict["sanmiguel_00227_ascii.obj"] = "mat_columna_b3"

    mat_dict["sanmiguel_00228_ascii.obj"] = "mat_columna_b2"
    mat_dict["sanmiguel_00230_ascii.obj"] = "mat_columna_b2"

    mat_dict["sanmiguel_00233_ascii.obj"] = "mat_light_patio06_mat01"

    mat_dict["sanmiguel_00234_ascii.obj"] = "mat_negro"

    mat_dict["sanmiguel_00235_ascii.obj"] = "mat_candil_2_glass"

    mat_dict["sanmiguel_00236_ascii.obj"] = "mat_agua"

    mat_dict["sanmiguel_00237_ascii.obj"] = "mat_fuente_centro"
    mat_dict["sanmiguel_00239_ascii.obj"] = "mat_fuente_centro"
    mat_dict["sanmiguel_00241_ascii.obj"] = "mat_fuente_centro"

    mat_dict["sanmiguel_00238_ascii.obj"] = "mat_fuente_fondo"

    mat_dict["sanmiguel_00240_ascii.obj"] = "mat_fuente"

    mat_dict["troncoA_00001_ascii.obj"] = "mat_tronco"
    mat_dict["troncoB_00001_ascii.obj"] = "mat_tronco"

    mat_dict["hojas_a1_00001_ascii.obj"] = "mat_leave_A_a"
    mat_dict["hojas_a4_00001_ascii.obj"] = "mat_leave_A_a"
    mat_dict["hojas_a6_00001_ascii.obj"] = "mat_leave_A_a"

    mat_dict["hojas_a2_00001_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_a2_00002_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_a5_00001_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_a7_00001_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_a7_00002_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_b2_00001_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_b2_00002_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_b4_00001_ascii.obj"] = "mat_leave_A_b"
    mat_dict["hojas_b4_00002_ascii.obj"] = "mat_leave_A_b"

    mat_dict["hojas_a3_00001_ascii.obj"] = "mat_leave_A_c"
    mat_dict["hojas_a3_00002_ascii.obj"] = "mat_leave_A_c"
    mat_dict["hojas_b3_00001_ascii.obj"] = "mat_leave_A_c"

    mat_dict["enredadera_00001_ascii.obj"] = "mat_tronco"

    mat_dict["enredadera_00002_ascii.obj"] = "mat_hoja_verde_b"

    mat_dict["enredadera_00003_ascii.obj"] = "mat_hoja_verde_a"
    
    mat_dict["enredadera_00004_ascii.obj"] = "mat_hojas_rojas_top"

    mat_dict["macetas_00001_ascii.obj"] = "mat_forja_macetas"
    mat_dict["macetas_00002_ascii.obj"] = "mat_forja_macetas"
    mat_dict["macetas_00010_ascii.obj"] = "mat_forja_macetas"
    mat_dict["macetas_00011_ascii.obj"] = "mat_forja_macetas"
    mat_dict["macetas_00012_ascii.obj"] = "mat_forja_macetas"
    mat_dict["macetas_00013_ascii.obj"] = "mat_forja_macetas"

    mat_dict["macetas_00003_ascii.obj"] = "mat_maceta_A"

    mat_dict["macetas_00004_ascii.obj"] = "mat_maceta_A2"

    mat_dict["macetas_00005_ascii.obj"] = "mat_maceta_B"

    mat_dict["macetas_00006_ascii.obj"] = "mat_maceta_B2"

    mat_dict["macetas_00007_ascii.obj"] = "mat_maceta_C"

    mat_dict["macetas_00008_ascii.obj"] = "mat_maceta_C2"

    mat_dict["macetas_00009_ascii.obj"] = "mat_maceta_D2"

    mat_dict["platos_00001_ascii.obj"] = "mat_plato_A"

    mat_dict["platos_00002_ascii.obj"] = "mat_individual_verde"

    mat_dict["platos_00003_ascii.obj"] = "mat_cenicero"

    mat_dict["platos_00004_ascii.obj"] = "mat_base_vera_color"

    mat_dict["platos_00005_ascii.obj"] = "mat_vela"

    mat_dict["platos_00006_ascii.obj"] = "mat_vela_mecha"

    mat_dict["platos_00007_ascii.obj"] = "mat_pimienta"

    mat_dict["platos_00008_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00010_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00012_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00013_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00015_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00017_ascii.obj"] = "mat_cromo"

    mat_dict["platos_00009_ascii.obj"] = "mat_sal"

    mat_dict["platos_00011_ascii.obj"] = "mat_plastico_cubiertos"
    mat_dict["platos_00014_ascii.obj"] = "mat_plastico_cubiertos"
    mat_dict["platos_00016_ascii.obj"] = "mat_plastico_cubiertos"
    mat_dict["platos_00018_ascii.obj"] = "mat_plastico_cubiertos"

    mat_dict["platos_00019_ascii.obj"] = "mat_copas"
    mat_dict["platos_00020_ascii.obj"] = "mat_copas"
    mat_dict["platos_00023_ascii.obj"] = "mat_copas"

    mat_dict["platos_00021_ascii.obj"] = "mat_vidriosalero"
    mat_dict["platos_00022_ascii.obj"] = "mat_vidriosalero"

    mat_dict["mesas_abajo_00001_ascii.obj"] = "mat_silla_d_tachuelas"
    
    mat_dict["mesas_abajo_00002_ascii.obj"] = "mat_silla_d_piel"

    mat_dict["mesas_abajo_00003_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00004_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00005_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00006_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00007_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00008_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00009_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00010_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00011_ascii.obj"] = "mat_silla_d_madera"
    mat_dict["mesas_abajo_00012_ascii.obj"] = "mat_silla_d_madera"

    mat_dict["mesas_abajo_00013_ascii.obj"] = "mat_mesa_d_madera_patas"

    mat_dict["mesas_abajo_00014_ascii.obj"] = "mat_mesa_d_talabera"

    mat_dict["mesas_abajo_00015_ascii.obj"] = "mat_mesa_d_madera_orilla"

    mat_dict["mesas_abajo_00016_ascii.obj"] = "mat_tela_mesa_d_2"

    mat_dict["mesas_abajo_00017_ascii.obj"] = "mat_tela_mesa_d"

    mat_dict["mesas_arriba_00001_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00002_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00003_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00004_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00006_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00007_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00008_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00009_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00010_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00011_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00012_ascii.obj"] = "mat_madera_silla"
    mat_dict["mesas_arriba_00013_ascii.obj"] = "mat_madera_silla"

    mat_dict["mesas_arriba_00005_ascii.obj"] = "mat_silla_tela"
    mat_dict["mesas_arriba_00014_ascii.obj"] = "mat_silla_tela"
    mat_dict["mesas_arriba_00015_ascii.obj"] = "mat_silla_tela"
    mat_dict["mesas_arriba_00016_ascii.obj"] = "mat_silla_tela"
    mat_dict["mesas_arriba_00017_ascii.obj"] = "mat_silla_tela"
    mat_dict["mesas_arriba_00018_ascii.obj"] = "mat_silla_tela"    

    mat_dict["mesas_arriba_00019_ascii.obj"] = "mat_madera_mesa_arriba"
    mat_dict["mesas_arriba_00020_ascii.obj"] = "mat_madera_mesa_arriba"

    mat_dict["mesas_patio_00001_ascii.obj"] = "mat_tela_mesa_1"
    mat_dict["mesas_patio_00002_ascii.obj"] = "mat_tela_mesa_1"
    mat_dict["mesas_patio_00003_ascii.obj"] = "mat_tela_mesa_1"
    mat_dict["mesas_patio_00004_ascii.obj"] = "mat_tela_mesa_1"
    mat_dict["mesas_patio_00005_ascii.obj"] = "mat_tela_mesa_1"

    mat_dict["mesas_patio_00006_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00007_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00008_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00009_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00010_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00011_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00012_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00013_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00014_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00015_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00016_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00017_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00018_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00019_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00020_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00021_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00022_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00023_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00024_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00025_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00026_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00027_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00035_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00036_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00037_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00038_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00039_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00040_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00041_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00042_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00043_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00044_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00045_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00046_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00047_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00048_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00049_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00050_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00051_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00052_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00053_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00056_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00057_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00060_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00061_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00062_ascii.obj"] = "mat_sila_forja_a_metal"
    mat_dict["mesas_patio_00063_ascii.obj"] = "mat_sila_forja_a_metal"

    mat_dict["mesas_patio_00028_ascii.obj"] = "mat_sila_forja_a_madera"

    mat_dict["mesas_patio_00029_ascii.obj"] = "mat_sila_forja_a_tela"
    mat_dict["mesas_patio_00030_ascii.obj"] = "mat_sila_forja_a_tela"
    mat_dict["mesas_patio_00031_ascii.obj"] = "mat_sila_forja_a_tela"

    mat_dict["mesas_patio_00032_ascii.obj"] = "mat_standard_7"
    mat_dict["mesas_patio_00033_ascii.obj"] = "mat_standard_7"

    mat_dict["mesas_patio_00034_ascii.obj"] = "mat_mesa_madera"

    mat_dict["mesas_patio_00054_ascii.obj"] = "mat_silla_c_madera"

    mat_dict["mesas_patio_00055_ascii.obj"] = "mat_silla_c_tela"
    mat_dict["mesas_patio_00058_ascii.obj"] = "mat_silla_c_tela"
    mat_dict["mesas_patio_00059_ascii.obj"] = "mat_silla_c_tela"

    mat_dict["platos_00001_ascii.obj"] = "mat_plato_A"

    mat_dict["platos_00002_ascii.obj"] = "mat_individual_verde"

    mat_dict["platos_00003_ascii.obj"] = "mat_cenicero"

    mat_dict["platos_00004_ascii.obj"] = "mat_base_vela_color"

    mat_dict["platos_00005_ascii.obj"] = "mat_vela"

    mat_dict["platos_00006_ascii.obj"] = "mat_vela_mecha"

    mat_dict["platos_00007_ascii.obj"] = "mat_pimienta"

    mat_dict["platos_00008_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00010_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00012_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00013_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00015_ascii.obj"] = "mat_cromo"
    mat_dict["platos_00017_ascii.obj"] = "mat_cromo"

    mat_dict["platos_00009_ascii.obj"] = "mat_sal"

    mat_dict["platos_00011_ascii"] = "mat_plastico_cubiertos"
    mat_dict["platos_00014_ascii"] = "mat_plastico_cubiertos"
    mat_dict["platos_00016_ascii"] = "mat_plastico_cubiertos"
    mat_dict["platos_00018_ascii"] = "mat_plastico_cubiertos"

    mat_dict["platos_00019_ascii"] = "mat_copas"
    mat_dict["platos_00020_ascii"] = "mat_copas"
    mat_dict["platos_00023_ascii"] = "mat_copas"

    mat_dict["platos_00021_ascii"] = "mat_vidriosalero"

    mat_dict["platos_00022_ascii"] = "mat_vidriosalero"


    println("\t...DONE: we loaded $(length(keys(mat_dict))) materials")

    commented_in = keys(mat_dict)

    #######################################
    #######################################
    ############## area_lights
    #######################################
    #######################################

    area_lights = Dict{String, Tuple{Spectrum, Float64}}()
    area_lights["sanmiguel_00133_ascii.obj"] = (
        spectrum_from_float(1.0, 0.8392159939, 0.4901959896), 4_000
    )
    area_lights["sanmiguel_00233_ascii.obj"] = (
        spectrum_from_float(0.8941180110, 0.9882349968, 1.0), 2
    )


    #######################################
    #######################################
    ############## instancing
    #######################################
    #######################################

    println("LOADING TRANSFORMATIONS")
    transform_dict = Dict{String, Vector{String}}()
    transform_dict["sanmiguel_00043_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        215,
        234
    )
    @assert length(transform_dict["sanmiguel_00043_ascii.obj"]) == 3

    transform_dict["sanmiguel_00060_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        316,
        335
    )
    @assert length(transform_dict["sanmiguel_00060_ascii.obj"]) == 3

    transform_dict["sanmiguel_00131_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        687,
        711
    )
    @assert length(transform_dict["sanmiguel_00131_ascii.obj"]) == 3

    transform_dict["sanmiguel_00134_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        724,
        743
    )
    @assert length(transform_dict["sanmiguel_00134_ascii.obj"]) == 3

    transform_dict["sanmiguel_00135_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        745,
        774
    )
    @assert length(transform_dict["sanmiguel_00135_ascii.obj"]) == 5

    transform_dict["sanmiguel_00136_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        776,
        795
    )
    @assert length(transform_dict["sanmiguel_00136_ascii.obj"]) == 3

    transform_dict["sanmiguel_00137_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        797,
        3466
    )
    @assert length(transform_dict["sanmiguel_00137_ascii.obj"]) == 533

    transform_dict["sanmiguel_00138_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        3468,
        4807
    )
    @assert length(transform_dict["sanmiguel_00138_ascii.obj"]) == 267

    transform_dict["sanmiguel_00139_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        4809,
        4828
    )
    @assert length(transform_dict["sanmiguel_00139_ascii.obj"]) == 3

    transform_dict["sanmiguel_00141_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        4835,
        6174
    )
    @assert length(transform_dict["sanmiguel_00141_ascii.obj"]) == 267

    transform_dict["sanmiguel_00143_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        6181,
        6865
    )
    @assert length(transform_dict["sanmiguel_00143_ascii.obj"]) == 136

    transform_dict["sanmiguel_00144_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        6867,
        6976
    )
    @assert length(transform_dict["sanmiguel_00144_ascii.obj"]) == 21

    transform_dict["sanmiguel_00145_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        6978,
        7087
    )
    @assert length(transform_dict["sanmiguel_00145_ascii.obj"]) == 21

    transform_dict["sanmiguel_00146_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        7089,
        7198
    )
    @assert length(transform_dict["sanmiguel_00146_ascii.obj"]) == 21

    transform_dict["sanmiguel_00147_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        7200,
        7309
    )
    @assert length(transform_dict["sanmiguel_00147_ascii.obj"]) == 21

    transform_dict["sanmiguel_00148_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        7311,
        7340
    )
    @assert length(transform_dict["sanmiguel_00148_ascii.obj"]) == 5

    transform_dict["sanmiguel_00149_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        7342,
        7451
    )
    @assert length(transform_dict["sanmiguel_00149_ascii.obj"]) == 21

    transform_dict["sanmiguel_00150_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        7453,
        7497
    )
    @assert length(transform_dict["sanmiguel_00150_ascii.obj"]) == 8

    transform_dict["sanmiguel_00151_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        7499,
        9308
    )
    @assert length(transform_dict["sanmiguel_00151_ascii.obj"]) == 361

    transform_dict["sanmiguel_00152_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        9310,
        9459
    )
    @assert length(transform_dict["sanmiguel_00152_ascii.obj"]) == 29

    transform_dict["sanmiguel_00153_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        9461,
        9680
    )
    @assert length(transform_dict["sanmiguel_00153_ascii.obj"]) == 43

    transform_dict["sanmiguel_00154_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        9682,
        9901
    )
    @assert length(transform_dict["sanmiguel_00154_ascii.obj"]) == 43

    transform_dict["sanmiguel_00155_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        9903,
        9947
    )
    @assert length(transform_dict["sanmiguel_00155_ascii.obj"]) == 8

    transform_dict["sanmiguel_00157_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        9954,
        9998
    )
    @assert length(transform_dict["sanmiguel_00157_ascii.obj"]) == 8

    transform_dict["sanmiguel_00158_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        10_000,
        10_044
    )
    @assert length(transform_dict["sanmiguel_00158_ascii.obj"]) == 8

    transform_dict["sanmiguel_00159_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        10_046,
        10_090
    )
    @assert length(transform_dict["sanmiguel_00159_ascii.obj"]) == 8

    transform_dict["sanmiguel_00166_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        10_122,
        10_256
    )
    @assert length(transform_dict["sanmiguel_00166_ascii.obj"]) == 26

    transform_dict["sanmiguel_00167_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        10_258,
        10_307
    )
    @assert length(transform_dict["sanmiguel_00167_ascii.obj"]) == 9

    transform_dict["sanmiguel_00169_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        10_314,
        10_383
    )
    @assert length(transform_dict["sanmiguel_00169_ascii.obj"]) == 13

    transform_dict["sanmiguel_00171_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        10_390,
        12_185
    )
    @assert length(transform_dict["sanmiguel_00171_ascii.obj"]) == 358

    transform_dict["sanmiguel_00172_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        12_187,
        14_092
    )
    @assert length(transform_dict["sanmiguel_00172_ascii.obj"]) == 380

    transform_dict["sanmiguel_00172_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        12_187,
        14_092
    )
    @assert length(transform_dict["sanmiguel_00172_ascii.obj"]) == 380

    transform_dict["sanmiguel_00173_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        14_094,
        15_894
    )
    @assert length(transform_dict["sanmiguel_00173_ascii.obj"]) == 359

    transform_dict["sanmiguel_00204_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_046,
        16_095
    )
    @assert length(transform_dict["sanmiguel_00204_ascii.obj"]) == 9

    transform_dict["sanmiguel_00205_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_097,
        16_146
    )
    @assert length(transform_dict["sanmiguel_00205_ascii.obj"]) == 9

    transform_dict["sanmiguel_00206_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_148,
        16_197
    )
    @assert length(transform_dict["sanmiguel_00206_ascii.obj"]) == 9

    transform_dict["sanmiguel_00207_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_199,
        16_248
    )
    @assert length(transform_dict["sanmiguel_00207_ascii.obj"]) == 9

    transform_dict["sanmiguel_00208_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_250,
        16_299
    )
    @assert length(transform_dict["sanmiguel_00208_ascii.obj"]) == 9

    transform_dict["sanmiguel_00209_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_301,
        16_350
    )
    @assert length(transform_dict["sanmiguel_00209_ascii.obj"]) == 9

    transform_dict["sanmiguel_00210_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_352,
        16_401
    )
    @assert length(transform_dict["sanmiguel_00210_ascii.obj"]) == 9

    transform_dict["sanmiguel_00211_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_403,
        16_472
    )
    @assert length(transform_dict["sanmiguel_00211_ascii.obj"]) == 13

    transform_dict["sanmiguel_00212_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_474,
        16_523
    )
    @assert length(transform_dict["sanmiguel_00212_ascii.obj"]) == 9

    transform_dict["sanmiguel_00213_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_525,
        16_574
    )
    @assert length(transform_dict["sanmiguel_00213_ascii.obj"]) == 9

    transform_dict["sanmiguel_00214_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_576,
        16_625
    )
    @assert length(transform_dict["sanmiguel_00214_ascii.obj"]) == 9

    transform_dict["sanmiguel_00215_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_627,
        16_676
    )
    @assert length(transform_dict["sanmiguel_00215_ascii.obj"]) == 9

    transform_dict["sanmiguel_00216_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_678,
        16_727
    )
    @assert length(transform_dict["sanmiguel_00216_ascii.obj"]) == 9

    transform_dict["sanmiguel_00217_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_729,
        16_818
    )
    @assert length(transform_dict["sanmiguel_00217_ascii.obj"]) == 17

    transform_dict["sanmiguel_00218_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_820,
        16_869
    )
    @assert length(transform_dict["sanmiguel_00218_ascii.obj"]) == 9

    transform_dict["sanmiguel_00219_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_871,
        16_920
    )
    @assert length(transform_dict["sanmiguel_00219_ascii.obj"]) == 9

    transform_dict["sanmiguel_00220_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/sanmiguel-geom.pbrt"),
        16_922,
        16_971
    )
    @assert length(transform_dict["sanmiguel_00220_ascii.obj"]) == 9

    transform_dict["hojas_a1_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a1-geom.pbrt"),
        5,
        81_930
    )
    @assert length(transform_dict["hojas_a1_00001_ascii.obj"]) == 16_384

    transform_dict["hojas_a2_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a2-geom.pbrt"),
        11,
        24_926
    )
    @assert length(transform_dict["hojas_a2_00002_ascii.obj"]) == 4_982

    transform_dict["hojas_a3_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a3-geom.pbrt"),
        11,
        81_946
    )
    @assert length(transform_dict["hojas_a3_00002_ascii.obj"]) == 16_386

    transform_dict["hojas_a4_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a4-geom.pbrt"),
        5,
        81_935
    )
    @assert length(transform_dict["hojas_a4_00001_ascii.obj"]) == 16_385

    transform_dict["hojas_a5_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a5-geom.pbrt"),
        5,
        48_040
    )
    @assert length(transform_dict["hojas_a5_00001_ascii.obj"]) == 9_606

    transform_dict["hojas_a6_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a6-geom.pbrt"),
        5,
        38_100
    )
    @assert length(transform_dict["hojas_a6_00001_ascii.obj"]) == 7_618

    transform_dict["hojas_a7_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_a7-geom.pbrt"),
        11,
        23_186
    )
    @assert length(transform_dict["hojas_a7_00002_ascii.obj"]) == 4_634

    transform_dict["hojas_b2_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_b2-geom.pbrt"),
        11,
        81_946
    )
    @assert length(transform_dict["hojas_b2_00002_ascii.obj"]) == 16_386

    transform_dict["hojas_b3_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_b3-geom.pbrt"),
        5,
        67_670
    )
    @assert length(transform_dict["hojas_b3_00001_ascii.obj"]) == 13_532

    transform_dict["hojas_b4_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/hojas_b4-geom.pbrt"),
        11,
        74_501
    )
    @assert length(transform_dict["hojas_b4_00002_ascii.obj"]) == 14_897

    transform_dict["enredadera_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/enredadera-geom.pbrt"),
        11,
        106_934
    )
    @assert length(transform_dict["enredadera_00002_ascii.obj"]) == 21_384

    transform_dict["enredadera_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/enredadera-geom.pbrt"),
        106_937,
        125_042
    )
    @assert length(transform_dict["enredadera_00003_ascii.obj"]) == 3_620

    transform_dict["enredadera_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/enredadera-geom.pbrt"),
        125_044,
        150_059
    )
    @assert length(transform_dict["enredadera_00004_ascii.obj"]) == 5_002

    transform_dict["macetas_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        6,
        224
    )
    @assert length(transform_dict["macetas_00001_ascii.obj"]) == 43

    transform_dict["macetas_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        227,
        340
    )
    @assert length(transform_dict["macetas_00002_ascii.obj"]) == 22

    transform_dict["macetas_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        342,
        436
    )
    @assert length(transform_dict["macetas_00003_ascii.obj"]) == 18

    transform_dict["macetas_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        438,
        457
    )
    @assert length(transform_dict["macetas_00004_ascii.obj"]) == 3

    transform_dict["macetas_00005_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        460,
        558
    )
    @assert length(transform_dict["macetas_00005_ascii.obj"]) == 19

    transform_dict["macetas_00006_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        561,
        579
    )
    @assert length(transform_dict["macetas_00006_ascii.obj"]) == 3

    transform_dict["macetas_00007_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        581,
        600
    )
    @assert length(transform_dict["macetas_00007_ascii.obj"]) == 3

    transform_dict["macetas_00008_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        603,
        631
    )
    @assert length(transform_dict["macetas_00008_ascii.obj"]) == 5

    transform_dict["macetas_00009_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        634,
        732
    )
    @assert length(transform_dict["macetas_00009_ascii.obj"]) == 19

    transform_dict["macetas_00010_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        734,
        1_063
    )
    @assert length(transform_dict["macetas_00010_ascii.obj"]) == 65

    transform_dict["macetas_00011_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        1_066,
        1_394
    )
    @assert length(transform_dict["macetas_00011_ascii.obj"]) == 65

    transform_dict["macetas_00012_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        1_397,
        1_725
    )
    @assert length(transform_dict["macetas_00012_ascii.obj"]) == 65

    transform_dict["macetas_00013_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        1_728,
        1_816
    )
    @assert length(transform_dict["macetas_00013_ascii.obj"]) == 17

    transform_dict["macetas_00014_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/macetas-geom.pbrt"),
        1_819,
        1_907
    )
    @assert length(transform_dict["macetas_00014_ascii.obj"]) == 17

    transform_dict["platos_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        6,
        454
    )
    @assert length(transform_dict["platos_00001_ascii.obj"]) == 89

    transform_dict["platos_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        457,
        785
    )
    @assert length(transform_dict["platos_00002_ascii.obj"]) == 65

    transform_dict["platos_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        788,
        906
    )
    @assert length(transform_dict["platos_00003_ascii.obj"]) == 23

    transform_dict["platos_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        909,
        1_027
    )
    @assert length(transform_dict["platos_00004_ascii.obj"]) == 23

    transform_dict["platos_00005_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_030,
        1_148
    )
    @assert length(transform_dict["platos_00005_ascii.obj"]) == 23

    transform_dict["platos_00006_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_151,
        1_269
    )
    @assert length(transform_dict["platos_00006_ascii.obj"]) == 23

    transform_dict["platos_00007_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_272,
        1_390
    )
    @assert length(transform_dict["platos_00007_ascii.obj"]) == 23

    transform_dict["platos_00008_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_393,
        1_511
    )
    @assert length(transform_dict["platos_00008_ascii.obj"]) == 23

    transform_dict["platos_00009_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_514,
        1_632
    )
    @assert length(transform_dict["platos_00009_ascii.obj"]) == 23

    transform_dict["platos_00010_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_635,
        1_753
    )
    @assert length(transform_dict["platos_00010_ascii.obj"]) == 23

    transform_dict["platos_00011_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_756,
        2_204
    )
    @assert length(transform_dict["platos_00011_ascii.obj"]) == 89

    transform_dict["platos_00012_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        2_207,
        2_655
    )
    @assert length(transform_dict["platos_00012_ascii.obj"]) == 89

    transform_dict["platos_00013_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        2_658,
        3_106
    )
    @assert length(transform_dict["platos_00013_ascii.obj"]) == 89

    transform_dict["platos_00014_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        3_109,
        3_557
    )
    @assert length(transform_dict["platos_00014_ascii.obj"]) == 89

    transform_dict["platos_00015_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        3_560,
        4_008
    )
    @assert length(transform_dict["platos_00015_ascii.obj"]) == 89

    transform_dict["platos_00016_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        4_011,
        4_459
    )
    @assert length(transform_dict["platos_00016_ascii.obj"]) == 89

    transform_dict["platos_00017_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        4_462,
        4_910
    )
    @assert length(transform_dict["platos_00017_ascii.obj"]) == 89

    transform_dict["platos_00018_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        4_913,
        5_361
    )
    @assert length(transform_dict["platos_00018_ascii.obj"]) == 89

    transform_dict["platos_00019_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        5_364,
        5_812
    )
    @assert length(transform_dict["platos_00019_ascii.obj"]) == 89

    transform_dict["platos_00020_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        5_815,
        5_933
    )
    @assert length(transform_dict["platos_00020_ascii.obj"]) == 23

    transform_dict["platos_00021_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        5_933,
        6_054
    )
    @assert length(transform_dict["platos_00021_ascii.obj"]) == 23

    transform_dict["platos_00022_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        6_057,
        6_175
    )
    @assert length(transform_dict["platos_00022_ascii.obj"]) == 23

    transform_dict["platos_00023_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        6_178,
        6_626
    )
    @assert length(transform_dict["platos_00023_ascii.obj"]) == 89

    transform_dict["mesas_abajo_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        6,
        1_934
    )
    @assert length(transform_dict["mesas_abajo_00001_ascii.obj"]) == 385

    transform_dict["mesas_abajo_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        1_937,
        2_065
    )
    @assert length(transform_dict["mesas_abajo_00002_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        2_068,
        2_316
    )
    @assert length(transform_dict["mesas_abajo_00003_ascii.obj"]) == 49

    transform_dict["mesas_abajo_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        2_319,
        2_447
    )
    @assert length(transform_dict["mesas_abajo_00004_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00005_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        2_450,
        2_578
    )
    @assert length(transform_dict["mesas_abajo_00005_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00006_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        2_581,
        2_709
    )
    @assert length(transform_dict["mesas_abajo_00006_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00007_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        2_711,
        3_200
    )
    @assert length(transform_dict["mesas_abajo_00007_ascii.obj"]) == 97

    transform_dict["mesas_abajo_00008_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        3_203,
        3_451
    )
    @assert length(transform_dict["mesas_abajo_00008_ascii.obj"]) == 49

    transform_dict["mesas_abajo_00009_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        3_454,
        3_582
    )
    @assert length(transform_dict["mesas_abajo_00009_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00010_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        3_585,
        3_713
    )
    @assert length(transform_dict["mesas_abajo_00010_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00011_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        3_716,
        3_964
    )
    @assert length(transform_dict["mesas_abajo_00011_ascii.obj"]) == 49

    transform_dict["mesas_abajo_00012_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        3_967,
        4_215
    )
    @assert length(transform_dict["mesas_abajo_00012_ascii.obj"]) == 49

    transform_dict["mesas_abajo_00013_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        4_218,
        4_346
    )
    @assert length(transform_dict["mesas_abajo_00013_ascii.obj"]) == 25

    transform_dict["mesas_abajo_00014_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        4_349,
        4_387
    )
    @assert length(transform_dict["mesas_abajo_00014_ascii.obj"]) == 7

    transform_dict["mesas_abajo_00015_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        4_390,
        4_428
    )
    @assert length(transform_dict["mesas_abajo_00015_ascii.obj"]) == 7

    transform_dict["mesas_abajo_00016_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        4_431,
        4_470
    )
    @assert length(transform_dict["mesas_abajo_00016_ascii.obj"]) == 7

    transform_dict["mesas_abajo_00017_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_abajo-geom.pbrt"),
        4_473,
        4_511
    )
    @assert length(transform_dict["mesas_abajo_00017_ascii.obj"]) == 7

    transform_dict["mesas_arriba_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        5,
        54
    )
    @assert length(transform_dict["mesas_arriba_00001_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        57,
        75
    )
    @assert length(transform_dict["mesas_arriba_00002_ascii.obj"]) == 3

    transform_dict["mesas_arriba_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        78,
        126
    )
    @assert length(transform_dict["mesas_arriba_00003_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        129,
        217
    )
    @assert length(transform_dict["mesas_arriba_00004_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00005_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        220,
        308
    )
    @assert length(transform_dict["mesas_arriba_00005_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00006_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        311,
        359
    )
    @assert length(transform_dict["mesas_arriba_00006_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00007_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        362,
        450
    )
    @assert length(transform_dict["mesas_arriba_00007_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00008_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        453,
        541
    )
    @assert length(transform_dict["mesas_arriba_00008_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00009_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        544,
        632
    )
    @assert length(transform_dict["mesas_arriba_00009_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00010_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        635,
        723
    )
    @assert length(transform_dict["mesas_arriba_00010_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00011_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        725,
        774
    )
    @assert length(transform_dict["mesas_arriba_00011_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00012_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        777,
        825
    )
    @assert length(transform_dict["mesas_arriba_00012_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00013_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        828,
        916
    )
    @assert length(transform_dict["mesas_arriba_00013_ascii.obj"]) == 17

    transform_dict["mesas_arriba_00014_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        919,
        967
    )
    @assert length(transform_dict["mesas_arriba_00014_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00015_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        970,
        1_018
    )
    @assert length(transform_dict["mesas_arriba_00015_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00016_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        1_021,
        1_069
    )
    @assert length(transform_dict["mesas_arriba_00016_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00017_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        1_072,
        1_120
    )
    @assert length(transform_dict["mesas_arriba_00017_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00018_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        1_123,
        1_171
    )
    @assert length(transform_dict["mesas_arriba_00018_ascii.obj"]) == 9

    transform_dict["mesas_arriba_00019_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        1_174,
        1_192
    )
    @assert length(transform_dict["mesas_arriba_00019_ascii.obj"]) == 3

    transform_dict["mesas_arriba_00020_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_arriba-geom.pbrt"),
        1_195,
        1_213
    )
    @assert length(transform_dict["mesas_arriba_00020_ascii.obj"]) == 3

    transform_dict["mesas_patio_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        5,
        29
    )
    @assert length(transform_dict["mesas_patio_00001_ascii.obj"]) == 4

    transform_dict["mesas_patio_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        32,
        50
    )
    @assert length(transform_dict["mesas_patio_00002_ascii.obj"]) == 3

    transform_dict["mesas_patio_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        53,
        86
    )
    @assert length(transform_dict["mesas_patio_00003_ascii.obj"]) == 6

    transform_dict["mesas_patio_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        89,
        132
    )
    @assert length(transform_dict["mesas_patio_00004_ascii.obj"]) == 8

    transform_dict["mesas_patio_00005_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        135,
        158
    )
    @assert length(transform_dict["mesas_patio_00005_ascii.obj"]) == 4

    transform_dict["mesas_patio_00006_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        161,
        369
    )
    @assert length(transform_dict["mesas_patio_00006_ascii.obj"]) == 41

    transform_dict["mesas_patio_00007_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        372,
        580
    )
    @assert length(transform_dict["mesas_patio_00007_ascii.obj"]) == 41

    transform_dict["mesas_patio_00008_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        583,
        791
    )
    @assert length(transform_dict["mesas_patio_00008_ascii.obj"]) == 41

    transform_dict["mesas_patio_00009_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        794,
        1_002
    )
    @assert length(transform_dict["mesas_patio_00009_ascii.obj"]) == 41

    transform_dict["mesas_patio_00010_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        1_005,
        1_213
    )
    @assert length(transform_dict["mesas_patio_00010_ascii.obj"]) == 41

    transform_dict["mesas_patio_00011_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        1_216,
        1_424
    )
    @assert length(transform_dict["mesas_patio_00011_ascii.obj"]) == 41

    transform_dict["mesas_patio_00012_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        1_427,
        1_635
    )
    @assert length(transform_dict["mesas_patio_00012_ascii.obj"]) == 41

    transform_dict["mesas_patio_00013_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        1_638,
        1_846
    )
    @assert length(transform_dict["mesas_patio_00013_ascii.obj"]) == 41

    transform_dict["mesas_patio_00014_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        1_849,
        2_057
    )
    @assert length(transform_dict["mesas_patio_00014_ascii.obj"]) == 41

    transform_dict["mesas_patio_00015_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        2_060,
        2_268
    )
    @assert length(transform_dict["mesas_patio_00015_ascii.obj"]) == 41

    transform_dict["mesas_patio_00016_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        2_271,
        2_479
    )
    @assert length(transform_dict["mesas_patio_00016_ascii.obj"]) == 41

    transform_dict["mesas_patio_00017_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        2_482,
        2_690
    )
    @assert length(transform_dict["mesas_patio_00017_ascii.obj"]) == 41

    transform_dict["mesas_patio_00018_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        2_693,
        2_901
    )
    @assert length(transform_dict["mesas_patio_00018_ascii.obj"]) == 41

    transform_dict["mesas_patio_00019_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        2_904,
        3_112
    )
    @assert length(transform_dict["mesas_patio_00019_ascii.obj"]) == 41

    transform_dict["mesas_patio_00020_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        3_115,
        3_322
    )
    @assert length(transform_dict["mesas_patio_00020_ascii.obj"]) == 41

    transform_dict["mesas_patio_00021_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        3_325,
        3_533
    )
    @assert length(transform_dict["mesas_patio_00021_ascii.obj"]) == 41

    transform_dict["mesas_patio_00022_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        3_536,
        3_745
    )
    @assert length(transform_dict["mesas_patio_00022_ascii.obj"]) == 41

    transform_dict["mesas_patio_00023_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        3_748,
        3_956
    )
    @assert length(transform_dict["mesas_patio_00023_ascii.obj"]) == 41

    transform_dict["mesas_patio_00024_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        3_959,
        4_167
    )
    @assert length(transform_dict["mesas_patio_00024_ascii.obj"]) == 41

    transform_dict["mesas_patio_00025_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        4_170,
        4_378
    )
    @assert length(transform_dict["mesas_patio_00025_ascii.obj"]) == 41

    transform_dict["mesas_patio_00026_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        4_381,
        4_589
    )
    @assert length(transform_dict["mesas_patio_00026_ascii.obj"]) == 41

    transform_dict["mesas_patio_00027_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        4_592,
        4_800
    )
    @assert length(transform_dict["mesas_patio_00027_ascii.obj"]) == 41

    transform_dict["mesas_patio_00028_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        4_803,
        5_011
    )
    @assert length(transform_dict["mesas_patio_00028_ascii.obj"]) == 41

    transform_dict["mesas_patio_00029_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        5_014,
        5_222
    )
    @assert length(transform_dict["mesas_patio_00029_ascii.obj"]) == 41

    transform_dict["mesas_patio_00030_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        5_225,
        5_433
    )
    @assert length(transform_dict["mesas_patio_00030_ascii.obj"]) == 41

    transform_dict["mesas_patio_00031_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        5_436,
        5_644
    )
    @assert length(transform_dict["mesas_patio_00031_ascii.obj"]) == 41

    transform_dict["mesas_patio_00032_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        5_647,
        5_855
    )
    @assert length(transform_dict["mesas_patio_00032_ascii.obj"]) == 41

    transform_dict["mesas_patio_00033_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        5_858,
        6_066
    )
    @assert length(transform_dict["mesas_patio_00033_ascii.obj"]) == 41

    transform_dict["mesas_patio_00034_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        6_069,
        6_177
    )
    @assert length(transform_dict["mesas_patio_00034_ascii.obj"]) == 21

    transform_dict["mesas_patio_00035_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        6_180,
        6_388
    )
    @assert length(transform_dict["mesas_patio_00035_ascii.obj"]) == 41

    transform_dict["mesas_patio_00036_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        6_391,
        6_599
    )
    @assert length(transform_dict["mesas_patio_00036_ascii.obj"]) == 41

    transform_dict["mesas_patio_00037_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        6_602,
        6_810
    )
    @assert length(transform_dict["mesas_patio_00037_ascii.obj"]) == 41

    transform_dict["mesas_patio_00038_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        6_813,
        7_021
    )
    @assert length(transform_dict["mesas_patio_00038_ascii.obj"]) == 41

    transform_dict["mesas_patio_00039_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        7_024,
        7_232
    )
    @assert length(transform_dict["mesas_patio_00039_ascii.obj"]) == 41

    transform_dict["mesas_patio_00040_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        7_235,
        7_443
    )
    @assert length(transform_dict["mesas_patio_00040_ascii.obj"]) == 41

    transform_dict["mesas_patio_00041_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        7_446,
        7_654
    )
    @assert length(transform_dict["mesas_patio_00041_ascii.obj"]) == 41

    transform_dict["mesas_patio_00042_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        7_657,
        7_865
    )
    @assert length(transform_dict["mesas_patio_00042_ascii.obj"]) == 41

    transform_dict["mesas_patio_00043_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        7_868,
        8_076
    )
    @assert length(transform_dict["mesas_patio_00043_ascii.obj"]) == 41

    transform_dict["mesas_patio_00044_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        8_079,
        8_287
    )
    @assert length(transform_dict["mesas_patio_00044_ascii.obj"]) == 41

    transform_dict["mesas_patio_00045_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        8_290,
        8_498
    )
    @assert length(transform_dict["mesas_patio_00045_ascii.obj"]) == 41

    transform_dict["mesas_patio_00046_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        8_501,
        8_709
    )
    @assert length(transform_dict["mesas_patio_00046_ascii.obj"]) == 41

    transform_dict["mesas_patio_00047_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        8_712,
        8_920
    )
    @assert length(transform_dict["mesas_patio_00047_ascii.obj"]) == 41

    transform_dict["mesas_patio_00048_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        8_923,
        9_131
    )
    @assert length(transform_dict["mesas_patio_00048_ascii.obj"]) == 41

    transform_dict["mesas_patio_00049_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        9_134,
        9_342
    )
    @assert length(transform_dict["mesas_patio_00049_ascii.obj"]) == 41

    transform_dict["mesas_patio_00050_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        9_345,
        9_553
    )
    @assert length(transform_dict["mesas_patio_00050_ascii.obj"]) == 41

    transform_dict["mesas_patio_00051_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        9_556,
        9_764
    )
    @assert length(transform_dict["mesas_patio_00051_ascii.obj"]) == 41

    transform_dict["mesas_patio_00052_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        9_767,
        9_975
    )
    @assert length(transform_dict["mesas_patio_00052_ascii.obj"]) == 41

    transform_dict["mesas_patio_00053_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        9_978,
        10_186
    )
    @assert length(transform_dict["mesas_patio_00053_ascii.obj"]) == 41

    transform_dict["mesas_patio_00054_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        10_189,
        10_397
    )
    @assert length(transform_dict["mesas_patio_00054_ascii.obj"]) == 41

    transform_dict["mesas_patio_00055_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        10_400,
        10_608
    )
    @assert length(transform_dict["mesas_patio_00055_ascii.obj"]) == 41

    transform_dict["mesas_patio_00056_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        10_611,
        10_819
    )
    @assert length(transform_dict["mesas_patio_00056_ascii.obj"]) == 41

    transform_dict["mesas_patio_00057_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        10_822,
        11_030
    )
    @assert length(transform_dict["mesas_patio_00057_ascii.obj"]) == 41

    transform_dict["mesas_patio_00058_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        11_033,
        11_241
    )
    @assert length(transform_dict["mesas_patio_00058_ascii.obj"]) == 41

    transform_dict["mesas_patio_00059_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        11_244,
        11_452
    )
    @assert length(transform_dict["mesas_patio_00059_ascii.obj"]) == 41

    transform_dict["mesas_patio_00060_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        11_455,
        11_663
    )
    @assert length(transform_dict["mesas_patio_00060_ascii.obj"]) == 41

    transform_dict["mesas_patio_00061_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        11_666,
        11_874
    )
    @assert length(transform_dict["mesas_patio_00061_ascii.obj"]) == 41

    transform_dict["mesas_patio_00062_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        11_877,
        12_085
    )
    @assert length(transform_dict["mesas_patio_00062_ascii.obj"]) == 41

    transform_dict["mesas_patio_00063_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/mesas_patio-geom.pbrt"),
        12_088,
        12_296
    )
    @assert length(transform_dict["mesas_patio_00063_ascii.obj"]) == 41

    transform_dict["platos_00001_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        6,
        454
    )
    @assert length(transform_dict["platos_00001_ascii.obj"]) == 89

    transform_dict["platos_00002_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        457,
        785
    )
    @assert length(transform_dict["platos_00002_ascii.obj"]) == 65

    transform_dict["platos_00003_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        788,
        906
    )
    @assert length(transform_dict["platos_00003_ascii.obj"]) == 23

    transform_dict["platos_00004_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        909,
        1_027
    )
    @assert length(transform_dict["platos_00004_ascii.obj"]) == 23

    transform_dict["platos_00005_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_030,
        1_148
    )
    @assert length(transform_dict["platos_00005_ascii.obj"]) == 23

    transform_dict["platos_00006_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_151,
        1_269
    )
    @assert length(transform_dict["platos_00006_ascii.obj"]) == 23

    transform_dict["platos_00007_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_272,
        1_390
    )
    @assert length(transform_dict["platos_00007_ascii.obj"]) == 23

    transform_dict["platos_00008_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_393,
        1_511
    )
    @assert length(transform_dict["platos_00008_ascii.obj"]) == 23

    transform_dict["platos_00009_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_514,
        1_632
    )
    @assert length(transform_dict["platos_00009_ascii.obj"]) == 23

    transform_dict["platos_00010_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_635,
        1_753
    )
    @assert length(transform_dict["platos_00010_ascii.obj"]) == 23

    transform_dict["platos_00011_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        1_756,
        2_204
    )
    @assert length(transform_dict["platos_00011_ascii.obj"]) == 89

    transform_dict["platos_00012_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        2_207,
        2_655
    )
    @assert length(transform_dict["platos_00012_ascii.obj"]) == 89

    transform_dict["platos_00013_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        2_658,
        3_106
    )
    @assert length(transform_dict["platos_00013_ascii.obj"]) == 89

    transform_dict["platos_00014_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        3_109,
        3_557
    )
    @assert length(transform_dict["platos_00014_ascii.obj"]) == 89

    transform_dict["platos_00015_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        3_560,
        4_008
    )
    @assert length(transform_dict["platos_00015_ascii.obj"]) == 89

    transform_dict["platos_00016_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        4_011,
        4_459
    )
    @assert length(transform_dict["platos_00016_ascii.obj"]) == 89

    transform_dict["platos_00017_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        4_462,
        4_910
    )
    @assert length(transform_dict["platos_00017_ascii.obj"]) == 89

    transform_dict["platos_00018_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        4_913,
        5_361
    )
    @assert length(transform_dict["platos_00018_ascii.obj"]) == 89

    transform_dict["platos_00019_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        5_364,
        5_812
    )
    @assert length(transform_dict["platos_00019_ascii.obj"]) == 89

    transform_dict["platos_00020_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        5_815,
        5_933
    )
    @assert length(transform_dict["platos_00020_ascii.obj"]) == 23

    transform_dict["platos_00021_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        5_936,
        6_054
    )
    @assert length(transform_dict["platos_00021_ascii.obj"]) == 23

    transform_dict["platos_00022_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        6_057,
        6_175
    )
    @assert length(transform_dict["platos_00022_ascii.obj"]) == 23

    transform_dict["platos_00022_ascii.obj"] = parse_sanmiguel(
        jmfp(path_header * "geometry/platos-geom.pbrt"),
        6_178,
        6_626
    )
    @assert length(transform_dict["platos_00022_ascii.obj"]) == 89

    println("\t...DONE: we loaded $(length(keys(transform_dict))) transforms")


    #######################################
    #######################################
    ############## alpha dict
    #######################################
    #######################################

    alpha_dict = Dict{String, String}()

    alpha_dict["sanmiguel_00171_ascii.obj"] = "tex_HojaSecaMask"
    alpha_dict["sanmiguel_00172_ascii.obj"] = "tex_HojaSecaMask"
    alpha_dict["sanmiguel_00173_ascii.obj"] = "tex_HojaSecaMask"

    alpha_dict["hojas_a1_00001_ascii.obj"] = "tex_leave_A_a_alpha"
    alpha_dict["hojas_a4_00001_ascii.obj"] = "tex_leave_A_a_alpha"
    alpha_dict["hojas_a6_00001_ascii.obj"] = "tex_leave_A_a_alpha"

    alpha_dict["hojas_a2_00001_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_a2_00002_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_a5_00001_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_a7_00001_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_a7_00002_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_b2_00001_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_b2_00002_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_b4_00001_ascii.obj"] = "tex_leave_A_b_alpha"
    alpha_dict["hojas_b4_00002_ascii.obj"] = "tex_leave_A_b_alpha"

    alpha_dict["hojas_a3_00001_ascii.obj"] = "tex_leave_A_c_alpha"
    alpha_dict["hojas_a3_00002_ascii.obj"] = "tex_leave_A_c_alpha"
    alpha_dict["hojas_b3_00001_ascii.obj"] = "tex_leave_A_c_alpha"

    alpha_dict["enredadera_00002_ascii.obj"] = "tex_26"

    alpha_dict["enredadera_00003_ascii.obj"] = "tex_28"

    alpha_dict["enredadera_00004_ascii.obj"] = "tex_30"


    #######################################
    #######################################
    ############## ply reading
    #######################################
    #######################################
    
    dirpath = jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/geometry/")
    objs = String[]
    for (_, _, files) in walkdir(dirpath)
        # LAZILY ignoring nested folders
        for file in files
            if endswith(file, "_ascii.obj")
                push!(objs, file)
            end
        end
    end
    for obj_file in objs
        # COMMENTED IN & NOT AN AREA LIGHT
        if (obj_file in commented_in) && !(obj_file in keys(area_lights))
            obj_path = joinpath(dirpath, obj_file)

            if obj_file in keys(alpha_dict)
                alpha = alpha_dict[obj_file]
            else
                alpha = nothing
            end

            # if we have transforms, then we need to loop over them
            if obj_file in keys(transform_dict)
                for tstring in transform_dict[obj_file]
                    objects = parse_obj(
                        obj_path,
                        Transformation(Mat4(parse.(Float64, split(tstring)))),
                        false,
                        false,
                        alpha
                    )
                    for object in objects
                        for mesh in object
                            tmp_mat = mat_dict[obj_file]
                            push!(primitives, Primitive(mesh, tmp_mat, nothing))
                        end
                    end
                end
            else
                # if no transforms, then no loop.
                objects = parse_obj(
                        obj_path,
                        Translate(Pnt3(0,0,0)),
                        false,
                        false,
                        alpha
                    )
                    for object in objects
                        for mesh in object
                            tmp_mat = mat_dict[obj_file]
                            push!(primitives, Primitive(mesh, tmp_mat, nothing))
                        end
                    end
            end
        # area lights go here. 
        elseif (obj_file in commented_in) && (obj_file in keys(area_lights))
            obj_path = joinpath(dirpath, obj_file)
            objects = parse_obj(
                obj_path,
                Translate(Pnt3(0,0,0)),
                false,
                false,
                nothing
            )
            for object in objects
                for mesh in object
                    tmp_mat = mat_dict[obj_file]
                    brightness, mult = area_lights[obj_file]
                    alight = DiffuseAreaLight(
                        brightness * mult,
                        mesh,
                        false
                    )
                    push!(lights, alight)
                    push!(primitives, Primitive(mesh, tmp_mat, alight))
                end
            end
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = RotateZ(198.0)
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(13.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/textures/RenoSuburb01_sm.exr"),
        false
    )
    push!(lights, light)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera
    look_from = Pnt3(27.6255, -2.42353, 1.49616)
    look_at = Pnt3(26.6582, -2.17012, 1.48803)
    up = Vec3(-0.00786446, 0.00206023, 0.999967)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), screen, 0.0, 1.0, 0.0, 1e6, 57.2209, film)

    # Instantiate a Sampler
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]), 
        Int8(2),
        parsed_args["seed"]
    )
    # S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end