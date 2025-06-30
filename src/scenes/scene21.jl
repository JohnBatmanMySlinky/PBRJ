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
    data = readlines(fpath)
    transforms = String[]
    nlines = length(data)
    
    for i in 1:nlines
        if (i < START) || (i > END)
            continue
        end
        
        transform = parse_transform(data[i])
        if transform !== nothing
            push!(transforms, transform)
        end
    end
    
    return transforms
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
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(0.25, 0.25, 0.25)),
        ConstantTexture(0.0),
        nothing
    )
    mat_vidrio = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    mat_jardinera_1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/jardinera_1_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/jardinera_1_displacement_2.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_jardinera_2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/fuente_piedra_01.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_detalle_escalera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/cantera_naranja_liso.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_techo_arcos = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura_volado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_techo = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura_techo.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/moldura_techo_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_escalera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/escalera_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/escalera_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_muros = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/pared_barro_afinado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_techos = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/techo.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_vigas_concreto = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/concreto_02.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_volado = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura_volado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_losa_volados = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/losa.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_2_piso = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura2piso_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/moldura2piso_bump.png"), 
                true
            ),
            ConstantTexture(0.003)
        )
    )
    mat_piso_interior = Matte(
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        nothing
    )
    mat_azotea = Matte(
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    piso_pasillos_arriba = Plastic(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/piso_rustico.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
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
                UVMapping2D(),
                jmfp(path_header * "textures/piso_rustico_displace2.png"), 
                true
            ),
            ConstantTexture(0.012)
        ),
        true
    )
    mat_puerta_arco = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_barandal_postes = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_pared_sanMiguel_b = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_a.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_b1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_b1.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/muros_b1.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_pared_sanMiguel_c2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_c2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_f = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_f.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_e = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_e.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_d = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_d.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_g = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_g.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_h = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_h.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_i = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_l.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_j = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_j.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_muro_naranja_escalera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_l.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_m = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_m.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_n = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_n.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_a = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_p2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_p_.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_q = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_q3.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_q2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_q.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_q4 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_q4.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_techo_vigas = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/techo.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pared_sanMiguel_qpatio = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_q_patio2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_banqueta = Matte(
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    mat_tierra = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/052terresable.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_arcos_lisos_2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/arcos_lisos_2_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/arcos_lisos_2_bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    mat_arcos_lisos_3 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/arcos_lisos_3_color_1.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/arcos_lisos_3_bump_1.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    mat_pared_sanMiguel_b2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_b2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_vigas_techo_b = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_vigas_techo_a = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/madera_rustica_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    ) 
    mat_pared_sanMiguel_k = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/muros_k.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_piso_patio_exterior_concreto = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/concreto_01.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_vigas_volados = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/Vigas_A2.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/vigas_a2_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_techos_2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/techo_01.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_piso_patio_exterior = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/piso_patio_exterior.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/piso_patio_exterior_displace_inv.png"), 
                true
            ),
            ConstantTexture(0.02)
        )
    )
    mat_calle = Matte(
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    mat_arco_frente = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/arco_frente.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/arco_frente_displace_inv.png"), 
                true
            ),
            ConstantTexture(0.002)
        )
    )
    mat_puerta_agarradera01 = Plastic(
        ConstantTexture(spectrum_from_float(0.337255, 0.286275, 0.223529)),
        ConstantTexture(spectrum_from_float(0.501961, 0.443137, 0.372549)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    mat_pintura_15 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7785.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/0001_carros.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7815.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_3 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7812.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_12 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/027_Cola Caballo 06-30-1997.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_5 = Matte(
        
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7812.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_6 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7843.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_7 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7785.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_8 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7758.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_9 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7843.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_10 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_11 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7768.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_4 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_13 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_14 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/D30_Smiguel_2003_7833.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_pintura_marcos = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_postes_barandal = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/postes_barandal_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/postes_barandal_bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    mat_piso_patio_exterior2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/piso_patio_exterior2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_sun_light = Matte(
        ConstantTexture(spectrum_from_float(5.0, 4.1960802078, 2.4509799480)),
        ConstantTexture(0.0),
        nothing
    )
    mat_barandal_detalle_extremos = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_madera_barandal = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_pared_calle = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/pared_calle.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_candil_2_foco = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    mat_detMoldura_06 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/detmoldura_06_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/detmoldura_06_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_detMoldura_05 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/detmoldura_05_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/detmoldura_05_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_detMoldura_04 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/detmoldura_04_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/detmoldura_04_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_detMoldura_03 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/detmoldura_03_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/detmoldura_03_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_detMoldura_02 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/detmoldura_02_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/detmoldura_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_detMoldura_01 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/detmoldura_01_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/detmoldura_01_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_detalle_escalera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/rust_a1.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_marco_puerta_1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/marco_puerta_1.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/marco_puerta_1_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_marco_puerta = Plastic(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/madera_barandal_esc_2.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/madera_barandal_esc_2_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        ),
        true
    )
    mat_mold_arco_01 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/mold_arco_01_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/mold_arco_01_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_mold_terraza = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/molduraterraza__color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/molduraterraza_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_puerta_agarradera = Matte(
        ConstantTexture(spectrum_from_float(0.392157, 0.368627, 0.341176)),
        ConstantTexture(0.0),
        nothing
    )
    mat_puerta_arco = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_puerta_01 = Plastic(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/puerta.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0431373, 0.0431373, 0.0431373)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/puerta_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        ),
        true,
    )
    mat_columna_a1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/columna_a_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/columna_a_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_columna_a2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/columna_a_color_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/columna_a_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_columna_a3 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/columna_a_color_3.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/columna_a_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_columna_b1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/columna_b_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/columna_b_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    mat_columna_b3 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/columna_b_color_3.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/columna_b_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    mat_columna_b2 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/columna_b_color_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/columna_b_displacement_3_inv.png"), 
                true
            ),
            ConstantTexture(0.015)
        )
    )
    mat_light_patio06_mat01 = Matte(
        ConstantTexture(spectrum_from_float(4.4705901146, 4.9411802292, 5.0)),
        ConstantTexture(0.0),
        nothing
    )
    mat_negro = Matte(
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    mat_candil_2_glass = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    mat_agua = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.33),
        nothing,
        true
    )
    mat_fuente_centro = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/fuente_piedra_02.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_fuente_fondo = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_fuente = Matte(
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        nothing
    )
    mat_barandal_detalle_centro = Plastic(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/rust_detalle.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/rust_detalle_bump.png"), 
                true
            ),
            ConstantTexture(0.015)
        ),
        true
    )
    mat_candil_cadena = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_candil_metal = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_fake_foco = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    mat_candil_foco = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    mat_candil_madera = Plastic(
        ImageTexture(
            UVMapping2D(),
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
    mat_candil_2 = Plastic(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/metal_viejo_2.png"), 
            false
        ),
        ConstantTexture(spectrum_from_float(0.301961, 0.301961, 0.301961)),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/metal_viejo_2.png"), 
                true
            ),
            ConstantTexture(0.1)
        ),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/metal_viejo_2.png"), 
                true
            ),
            ConstantTexture(0.002)
        ),
        true
    )
    mat_candil_2_negro = Plastic(
        ConstantTexture(spectrum_from_float(0.0588235, 0.0588235, 0.0588235)),
        ConstantTexture(spectrum_from_float(0.301961, 0.301961, 0.301961)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true
    )
    mat_escurridera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/escurridera_color.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/escurridera_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_hoja_seca_2C = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_leaf_seca_03b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_hoja_seca_2B = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_leaf_seca_02b.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_hoja_seca_2A = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_hoja_c_seca.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_teja = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/Barro_2.png"), 
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_tronco = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_tronco.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/sm_tronco_bump.png"), 
                true
            ),
            ConstantTexture(0.02)
        )
    )
    mat_leave_A_a = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_leaf_02a.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/sm_leaf_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_leave_A_b = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_leaf_02b.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/sm_leaf_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )
    mat_leave_A_c = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/sm_leaf_03a.png"), 
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/sm_leaf_02_bump.png"), 
                true
            ),
            ConstantTexture(0.01)
        )
    )


    #######################################
    #######################################
    ############## (alpha) textures
    #######################################
    #######################################

    tex_HojaSecaMask = ImageTexture(
        UVMapping2D(),
        jmfp(path_header * "textures/sm_hoja_c_seca_Mask.png"), 
        true
    )
    tex_leave_A_a_alpha = ImageTexture(
        UVMapping2D(),
        jmfp(path_header * "textures/sm_leaf_02_alpah.png"), 
        true
    )
    tex_leave_A_b_alpha = ImageTexture(
        UVMapping2D(),
        jmfp(path_header * "textures/sm_leaf_02_alpah.png"), 
        true
    )
    tex_leave_A_c_alpha = ImageTexture(
        UVMapping2D(),
        jmfp(path_header * "textures/sm_leaf_02_alpah.png"), 
        true
    )
   

    #######################################
    #######################################
    ############## mat_dict
    #######################################
    #######################################

    mat_dict = Dict{String, Material}()

    mat_dict["sanmiguel_00001_ascii.obj"] = mat_vidrio
    mat_dict["sanmiguel_00073_ascii.obj"] = mat_vidrio

    mat_dict["sanmiguel_00002_ascii.obj"] = mat_jardinera_1
    mat_dict["sanmiguel_00003_ascii.obj"] = mat_jardinera_1

    mat_dict["sanmiguel_00004_ascii.obj"] = mat_moldura_detalle_escalera

    mat_dict["sanmiguel_00005_ascii.obj"] = mat_moldura_techo_arcos

    mat_dict["sanmiguel_00006_ascii.obj"] = mat_moldura_techo

    mat_dict["sanmiguel_00007_ascii.obj"] = mat_escalera

    mat_dict["sanmiguel_00008_ascii.obj"] = mat_muros
    mat_dict["sanmiguel_00037_ascii.obj"] = mat_muros
    mat_dict["sanmiguel_00041_ascii.obj"] = mat_muros

    mat_dict["sanmiguel_00009_ascii.obj"] = mat_techos

    mat_dict["sanmiguel_00010_ascii.obj"] = mat_vigas_concreto

    mat_dict["sanmiguel_00011_ascii.obj"] = mat_moldura_volado

    mat_dict["sanmiguel_00012_ascii.obj"] = mat_losa_volados

    mat_dict["sanmiguel_00013_ascii.obj"] = mat_moldura_2_piso

    mat_dict["sanmiguel_00014_ascii.obj"] = mat_piso_interior
    mat_dict["sanmiguel_00016_ascii.obj"] = mat_piso_interior
    mat_dict["sanmiguel_00018_ascii.obj"] = mat_piso_interior

    mat_dict["sanmiguel_00015_ascii.obj"] = mat_azotea

    mat_dict["sanmiguel_00017_ascii.obj"] = piso_pasillos_arriba
    mat_dict["sanmiguel_00055_ascii.obj"] = piso_pasillos_arriba

    mat_dict["sanmiguel_00019_ascii.obj"] = mat_puerta_arco
    mat_dict["sanmiguel_00020_ascii.obj"] = mat_puerta_arco
    mat_dict["sanmiguel_00201_ascii.obj"] = mat_puerta_arco
    mat_dict["sanmiguel_00202_ascii.obj"] = mat_puerta_arco

    mat_dict["sanmiguel_00021_ascii.obj"] = mat_barandal_postes

    mat_dict["sanmiguel_00022_ascii.obj"] = mat_pared_sanMiguel_b

    mat_dict["sanmiguel_00023_ascii.obj"] = mat_pared_sanMiguel_b1

    mat_dict["sanmiguel_00024_ascii.obj"] = mat_pared_sanMiguel_c2

    mat_dict["sanmiguel_00025_ascii.obj"] = mat_pared_sanMiguel_f

    mat_dict["sanmiguel_00026_ascii.obj"] = mat_pared_sanMiguel_e

    mat_dict["sanmiguel_00027_ascii.obj"] = mat_pared_sanMiguel_d

    mat_dict["sanmiguel_00028_ascii.obj"] = mat_pared_sanMiguel_g

    mat_dict["sanmiguel_00029_ascii.obj"] = mat_pared_sanMiguel_h

    mat_dict["sanmiguel_00030_ascii.obj"] = mat_pared_sanMiguel_i

    mat_dict["sanmiguel_00031_ascii.obj"] = mat_pared_sanMiguel_j

    mat_dict["sanmiguel_00032_ascii.obj"] = mat_muro_naranja_escalera

    mat_dict["sanmiguel_00033_ascii.obj"] = mat_pared_sanMiguel_m

    mat_dict["sanmiguel_00034_ascii.obj"] = mat_pared_sanMiguel_n

    mat_dict["sanmiguel_00035_ascii.obj"] = mat_pared_sanMiguel_a

    mat_dict["sanmiguel_00036_ascii.obj"] = mat_pared_sanMiguel_p2

    mat_dict["sanmiguel_00038_ascii.obj"] = mat_pared_sanMiguel_q

    mat_dict["sanmiguel_00039_ascii.obj"] = mat_pared_sanMiguel_q2

    mat_dict["sanmiguel_00040_ascii.obj"] = mat_pared_sanMiguel_q4

    mat_dict["sanmiguel_00042_ascii.obj"] = mat_techo_vigas

    mat_dict["sanmiguel_00043_ascii.obj"] = mat_tierra
    mat_dict["sanmiguel_00046_ascii.obj"] = mat_tierra
    mat_dict["sanmiguel_00047_ascii.obj"] = mat_tierra

    mat_dict["sanmiguel_00044_ascii.obj"] = mat_pared_sanMiguel_qpatio

    mat_dict["sanmiguel_00045_ascii.obj"] = mat_banqueta

    mat_dict["sanmiguel_00048_ascii.obj"] = mat_arcos_lisos_2
    mat_dict["sanmiguel_00049_ascii.obj"] = mat_arcos_lisos_2

    mat_dict["sanmiguel_00050_ascii.obj"] = mat_arcos_lisos_3

    mat_dict["sanmiguel_00051_ascii.obj"] = mat_pared_sanMiguel_b2

    mat_dict["sanmiguel_00052_ascii.obj"] = mat_vigas_techo_b

    mat_dict["sanmiguel_00053_ascii.obj"] = mat_vigas_techo_a

    mat_dict["sanmiguel_00054_ascii.obj"] = mat_pared_sanMiguel_k

    mat_dict["sanmiguel_00056_ascii.obj"] = mat_piso_patio_exterior_concreto

    mat_dict["sanmiguel_00057_ascii.obj"] = mat_vigas_volados

    mat_dict["sanmiguel_00058_ascii.obj"] = mat_techos_2

    mat_dict["sanmiguel_00059_ascii.obj"] = mat_piso_patio_exterior

    mat_dict["sanmiguel_00060_ascii.obj"] = mat_jardinera_2

    mat_dict["sanmiguel_00061_ascii.obj"] = mat_calle

    mat_dict["sanmiguel_00062_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00063_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00064_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00065_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00066_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00067_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00068_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00069_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00070_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00071_ascii.obj"] = mat_arco_frente
    mat_dict["sanmiguel_00072_ascii.obj"] = mat_arco_frente

    mat_dict["sanmiguel_00074_ascii.obj"] = mat_puerta_agarradera01

    mat_dict["sanmiguel_00075_ascii.obj"] = mat_pintura_15

    mat_dict["sanmiguel_00076_ascii.obj"] = mat_pintura_1

    mat_dict["sanmiguel_00077_ascii.obj"] = mat_pintura_2

    mat_dict["sanmiguel_00078_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00090_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00091_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00092_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00093_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00094_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00095_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00096_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00097_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00098_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00099_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00100_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00101_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00102_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00103_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00104_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00105_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00106_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00107_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00108_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00109_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00110_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00111_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00112_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00113_ascii.obj"] = mat_pintura_3
    mat_dict["sanmiguel_00114_ascii.obj"] = mat_pintura_3

    mat_dict["sanmiguel_00079_ascii.obj"] = mat_pintura_12

    mat_dict["sanmiguel_00080_ascii.obj"] = mat_pintura_5

    mat_dict["sanmiguel_00081_ascii.obj"] = mat_pintura_6

    mat_dict["sanmiguel_00082_ascii.obj"] = mat_pintura_7

    mat_dict["sanmiguel_00083_ascii.obj"] = mat_pintura_8

    mat_dict["sanmiguel_00084_ascii.obj"] = mat_pintura_9

    mat_dict["sanmiguel_00085_ascii.obj"] = mat_pintura_10

    mat_dict["sanmiguel_00086_ascii.obj"] = mat_pintura_11

    mat_dict["sanmiguel_00087_ascii.obj"] = mat_pintura_4

    mat_dict["sanmiguel_00088_ascii.obj"] = mat_pintura_13

    mat_dict["sanmiguel_00089_ascii.obj"] = mat_pintura_14

    mat_dict["sanmiguel_00115_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00116_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00117_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00118_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00119_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00120_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00121_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00122_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00123_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00124_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00125_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00126_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00127_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00128_ascii.obj"] = mat_pintura_marcos
    mat_dict["sanmiguel_00129_ascii.obj"] = mat_pintura_marcos

    mat_dict["sanmiguel_00130_ascii.obj"] = mat_postes_barandal
    mat_dict["sanmiguel_00131_ascii.obj"] = mat_postes_barandal

    mat_dict["sanmiguel_00132_ascii.obj"] = mat_piso_patio_exterior2

    mat_dict["sanmiguel_00133_ascii.obj"] = mat_sun_light

    mat_dict["sanmiguel_00134_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00135_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00136_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00137_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00139_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00141_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00146_ascii.obj"] = mat_barandal_detalle_extremos
    mat_dict["sanmiguel_00166_ascii.obj"] = mat_barandal_detalle_extremos

    mat_dict["sanmiguel_00138_ascii.obj"] = mat_barandal_detalle_centro

    mat_dict["sanmiguel_00140_ascii.obj"] = mat_madera_barandal

    mat_dict["sanmiguel_00142_ascii.obj"] = mat_pared_calle

    mat_dict["sanmiguel_00143_ascii.obj"] = mat_candil_cadena

    mat_dict["sanmiguel_00144_ascii.obj"] = mat_candil_metal
    mat_dict["sanmiguel_00145_ascii.obj"] = mat_candil_metal

    mat_dict["sanmiguel_00146_ascii.obj"] = mat_fake_foco

    mat_dict["sanmiguel_00147_ascii.obj"] = mat_candil_foco

    mat_dict["sanmiguel_00148_ascii.obj"] = mat_candil_madera
    mat_dict["sanmiguel_00149_ascii.obj"] = mat_candil_madera

    mat_dict["sanmiguel_00150_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00151_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00152_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00153_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00154_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00157_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00158_ascii.obj"] = mat_candil_2
    mat_dict["sanmiguel_00159_ascii.obj"] = mat_candil_2

    mat_dict["sanmiguel_00155_ascii.obj"] = mat_candil_2_negro

    mat_dict["sanmiguel_00156_ascii.obj"] = mat_candil_2_foco

    mat_dict["sanmiguel_00160_ascii.obj"] = mat_detMoldura_06

    mat_dict["sanmiguel_00161_ascii.obj"] = mat_detMoldura_05

    mat_dict["sanmiguel_00162_ascii.obj"] = mat_detMoldura_04

    mat_dict["sanmiguel_00163_ascii.obj"] = mat_detMoldura_03

    mat_dict["sanmiguel_00164_ascii.obj"] = mat_detMoldura_02

    mat_dict["sanmiguel_00165_ascii.obj"] = mat_detMoldura_01

    mat_dict["sanmiguel_00167_ascii.obj"] = mat_escurridera

    mat_dict["sanmiguel_00168_ascii.obj"] = mat_detalle_escalera
    mat_dict["sanmiguel_00169_ascii.obj"] = mat_detalle_escalera
    mat_dict["sanmiguel_00170_ascii.obj"] = mat_detalle_escalera

    mat_dict["sanmiguel_00171_ascii.obj"] = mat_hoja_seca_2C

    mat_dict["sanmiguel_00172_ascii.obj"] = mat_hoja_seca_2B

    mat_dict["sanmiguel_00173_ascii.obj"] = mat_hoja_seca_2A

    mat_dict["sanmiguel_00174_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00175_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00176_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00177_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00178_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00179_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00180_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00181_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00182_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00183_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00184_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00185_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00186_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00187_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00188_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00189_ascii.obj"] = mat_marco_puerta_1
    mat_dict["sanmiguel_00190_ascii.obj"] = mat_marco_puerta_1

    mat_dict["sanmiguel_00191_ascii.obj"] = mat_marco_puerta

    mat_dict["sanmiguel_00192_ascii.obj"] = mat_mold_arco_01
    mat_dict["sanmiguel_00193_ascii.obj"] = mat_mold_arco_01
    mat_dict["sanmiguel_00194_ascii.obj"] = mat_mold_arco_01
    mat_dict["sanmiguel_00195_ascii.obj"] = mat_mold_arco_01
    mat_dict["sanmiguel_00196_ascii.obj"] = mat_mold_arco_01
    mat_dict["sanmiguel_00197_ascii.obj"] = mat_mold_arco_01

    mat_dict["sanmiguel_00198_ascii.obj"] = mat_mold_terraza
    mat_dict["sanmiguel_00199_ascii.obj"] = mat_mold_terraza

    mat_dict["sanmiguel_00200_ascii.obj"] = mat_puerta_agarradera

    mat_dict["sanmiguel_00201_ascii.obj"] = mat_puerta_arco
    mat_dict["sanmiguel_00202_ascii.obj"] = mat_puerta_arco

    mat_dict["sanmiguel_00203_ascii.obj"] = mat_puerta_01

    mat_dict["sanmiguel_00204_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00205_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00206_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00207_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00208_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00209_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00210_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00211_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00212_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00213_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00214_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00215_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00216_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00217_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00218_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00219_ascii.obj"] = mat_teja
    mat_dict["sanmiguel_00220_ascii.obj"] = mat_teja

    mat_dict["sanmiguel_00221_ascii.obj"] = mat_columna_a1
    mat_dict["sanmiguel_00224_ascii.obj"] = mat_columna_a1
    mat_dict["sanmiguel_00225_ascii.obj"] = mat_columna_a1

    mat_dict["sanmiguel_00222_ascii.obj"] = mat_columna_a2
    mat_dict["sanmiguel_00231_ascii.obj"] = mat_columna_a2
    
    mat_dict["sanmiguel_00223_ascii.obj"] = mat_columna_a3

    mat_dict["sanmiguel_00226_ascii.obj"] = mat_columna_b1
    mat_dict["sanmiguel_00227_ascii.obj"] = mat_columna_b1
    mat_dict["sanmiguel_00229_ascii.obj"] = mat_columna_b1
    mat_dict["sanmiguel_00232_ascii.obj"] = mat_columna_b1

    mat_dict["sanmiguel_00227_ascii.obj"] = mat_columna_b3

    mat_dict["sanmiguel_00228_ascii.obj"] = mat_columna_b2
    mat_dict["sanmiguel_00230_ascii.obj"] = mat_columna_b2

    mat_dict["sanmiguel_00233_ascii.obj"] = mat_light_patio06_mat01

    mat_dict["sanmiguel_00234_ascii.obj"] = mat_negro

    mat_dict["sanmiguel_00235_ascii.obj"] = mat_candil_2_glass

    mat_dict["sanmiguel_00236_ascii.obj"] = mat_agua

    mat_dict["sanmiguel_00237_ascii.obj"] = mat_fuente_centro
    mat_dict["sanmiguel_00239_ascii.obj"] = mat_fuente_centro
    mat_dict["sanmiguel_00241_ascii.obj"] = mat_fuente_centro

    mat_dict["sanmiguel_00238_ascii.obj"] = mat_fuente_fondo

    mat_dict["sanmiguel_00240_ascii.obj"] = mat_fuente

    mat_dict["troncoA_00001_ascii.obj"] = mat_tronco
    mat_dict["troncoB_00001_ascii.obj"] = mat_tronco

    mat_dict["hojas_a1_00001_ascii.obj"] = mat_leave_A_a
    mat_dict["hojas_a4_00001_ascii.obj"] = mat_leave_A_a
    mat_dict["hojas_a6_00001_ascii.obj"] = mat_leave_A_a

    mat_dict["hojas_a2_00001_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_a2_00002_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_a5_00001_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_a7_00001_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_a7_00002_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_b2_00001_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_b2_00002_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_b4_00001_ascii.obj"] = mat_leave_A_b
    mat_dict["hojas_b4_00002_ascii.obj"] = mat_leave_A_b

    mat_dict["hojas_a3_00001_ascii.obj"] = mat_leave_A_c
    mat_dict["hojas_a3_00002_ascii.obj"] = mat_leave_A_c
    mat_dict["hojas_b3_00001_ascii.obj"] = mat_leave_A_c


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

    println("\t...DONE: we loaded $(length(keys(transform_dict))) transforms")


    #######################################
    #######################################
    ############## alpha dict
    #######################################
    #######################################

    alpha_dict = Dict{String, AbstractTexture}()

    alpha_dict["sanmiguel_00171_ascii.obj"] = tex_HojaSecaMask
    alpha_dict["sanmiguel_00172_ascii.obj"] = tex_HojaSecaMask
    alpha_dict["sanmiguel_00173_ascii.obj"] = tex_HojaSecaMask

    alpha_dict["hojas_a1_00001_ascii.obj"] = tex_leave_A_a_alpha
    alpha_dict["hojas_a4_00001_ascii.obj"] = tex_leave_A_a_alpha
    alpha_dict["hojas_a6_00001_ascii.obj"] = tex_leave_A_a_alpha

    alpha_dict["hojas_a2_00001_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_a2_00002_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_a5_00001_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_a7_00001_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_a7_00002_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_b2_00001_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_b2_00002_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_b4_00001_ascii.obj"] = tex_leave_A_b_alpha
    alpha_dict["hojas_b4_00002_ascii.obj"] = tex_leave_A_b_alpha

    alpha_dict["hojas_a3_00001_ascii.obj"] = tex_leave_A_c_alpha
    alpha_dict["hojas_a3_00002_ascii.obj"] = tex_leave_A_c_alpha
    alpha_dict["hojas_b3_00001_ascii.obj"] = tex_leave_A_c_alpha


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
                            # tmp_mat = mat_gray
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
                            # tmp_mat = mat_gray
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