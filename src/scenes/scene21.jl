function make_scene21(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    path_header = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/"

    # materials
    println("LOADING MATERIALS")
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
    mat_ared_sanMiguel_qpatio = Matte(
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

    mat_dict["sanmiguel_00044_ascii.obj"] = mat_ared_sanMiguel_qpatio

    mat_dict["sanmiguel_00045_ascii.obj"] = mat_banqueta

    mat_dict["sanmiguel_00046_ascii.obj"] = mat_tierra
    mat_dict["sanmiguel_00047_ascii.obj"] = mat_tierra

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

    mat_dict["sanmiguel_00132_ascii.obj"] = mat_piso_patio_exterior2

    println("\t...DONE: we loaded $(length(keys(mat_dict))) materials")

    commented_in = keys(mat_dict)
    
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
        # if !(obj_file in commented_out)
        if obj_file in commented_in
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
                    push!(primitives, Primitive(mesh, tmp_mat, nothing))
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