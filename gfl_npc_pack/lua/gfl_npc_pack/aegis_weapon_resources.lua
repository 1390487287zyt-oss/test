-- Source weapon particles and samples shared by the Aegis variants.
game.AddParticles("particles/advent_fx.pcf")
game.AddParticles("particles/advent_grenades_fx.pcf")

for _, system in ipairs({
    "flamethrower_long", "magnet_muzzleflash", "magnet_tracer_heavy", "vh_hit",
    "advent_frag_explosion", "advent_inc_grenade",
}) do
    PrecacheParticleSystem(system)
end

sound.Add({name="GFLPack.Aegis.ADV_GL_Drum1",channel=CHAN_WEAPON,volume=1.0,level=100,pitch={95,105},sound="weapon/adv_grenadelauncher_drum_r1.wav"})
sound.Add({name="GFLPack.Aegis.ADV_GL_Drum2",channel=CHAN_WEAPON,volume=1.0,level=100,pitch={95,105},sound="weapon/adv_grenadelauncher_drum_r2.wav"})
sound.Add({name="GFLPack.Aegis.ADV_GL_FireClose",channel=CHAN_WEAPON,volume=1.0,level=100,pitch={95,105},sound="weapon/adv_grenadelauncher_fire_close.wav"})
sound.Add({name="GFLPack.Aegis.ADV_GL_Reload",channel=CHAN_WEAPON,volume=1.0,level=100,pitch={95,105},sound="weapon/adv_grenadelauncher_reload.wav"})
sound.Add({name="GFLPack.Aegis.CMF1",channel=CHAN_STATIC,volume=1.0,level=110,pitch={95,105},sound="weapon/fire-01-cannon.wav"})
sound.Add({name="GFLPack.Aegis.CMF2",channel=CHAN_WEAPON,volume=1.0,level=110,pitch={95,105},sound="weapon/fire-02-cannon.wav"})
sound.Add({name="GFLPack.Aegis.CMF3",channel=CHAN_ITEM,volume=1.0,level=110,pitch={95,105},sound="weapon/fire-03-cannon.wav"})
sound.Add({name="GFLPack.Aegis.FLAMETHROWER.FlameLoop",channel=CHAN_WEAPON,volume=1,level=90,pitch=100,sound="weapon/flame_loop.wav"})
sound.Add({name="GFLPack.Aegis.FLAMETHROWER.FlameStop",channel=CHAN_WEAPON,volume=1,level=85,pitch=100,sound="weapon/flame_stop.wav"})
sound.Add({name="GFLPack.Aegis.MagnetCanReload",channel=CHAN_STATIC,volume=0.8,level=90,pitch=100,sound="weapon/mec_reload.wav"})

if SERVER then
    for _, path in ipairs({
        "materials/advent_particles/effects/arcs_b_adv.vmt",
        "materials/advent_particles/effects/arcs_b_adv.vtf",
        "materials/advent_particles/effects/energy_flare_01_nocolor.vmt",
        "materials/advent_particles/effects/energy_flare_05_nocolor.vmt",
        "materials/advent_particles/effects/fas_dust_c.vmt",
        "materials/advent_particles/effects/fas_dust_c.vtf",
        "materials/advent_particles/effects/fas_glow_debris.vmt",
        "materials/advent_particles/effects/fas_glow_debris.vtf",
        "materials/advent_particles/effects/fas_glow_debris_noz.vmt",
        "materials/advent_particles/effects/fas_heavy_smoke_spike.vmt",
        "materials/advent_particles/effects/fas_heavy_smoke_spike.vtf",
        "materials/advent_particles/effects/fire_flame1.vmt",
        "materials/advent_particles/effects/hoovy_explosion_large.vmt",
        "materials/advent_particles/effects/hoovy_explosion_large.vtf",
        "materials/advent_particles/effects/ins_firenew_trail.vmt",
        "materials/advent_particles/effects/mex_anomaly_01.vmt",
        "materials/advent_particles/effects/mex_anomaly_01.vtf",
        "materials/advent_particles/effects/neuro_debris.vmt",
        "materials/advent_particles/effects/neuro_debris.vtf",
        "materials/advent_particles/effects/neuro_smoke_soft_b.vmt",
        "materials/advent_particles/effects/neuro_smoke_soft_b.vtf",
        "materials/advent_particles/effects/neuro_smokes_anim.vmt",
        "materials/advent_particles/effects/neuro_smokes_anim.vtf",
        "materials/advent_particles/effects/ori_orb_anim.vmt",
        "materials/advent_particles/effects/ori_orb_anim.vtf",
        "materials/advent_particles/effects/particle_smokegrenade1.vmt",
        "materials/advent_particles/effects/smoke_dust_rd.vmt",
        "materials/advent_particles/effects/spark.vmt",
        "materials/advent_particles/effects/spark.vtf",
        "materials/advent_particles/effects/spark_advent.vmt",
        "materials/advent_particles/effects/vistasmokev1.vtf",
        "materials/advent_particles/particle/fluidexplosion.vmt",
        "materials/advent_particles/particle/fluidexplosion.vtf",
        "materials/models/advent_snpc/flamethrower.vmt",
        "materials/models/advent_snpc/flamethrower_c.vtf",
        "materials/models/advent_snpc/flamethrower_e.vtf",
        "materials/models/advent_snpc/flamethrower_m.vtf",
        "materials/models/advent_snpc/flamethrower_n.vtf",
        "materials/models/advent_snpc/phongwarp_steel.vtf",
        "materials/models/gfl2_surtr/surtr_weapon.vmt",
        "materials/models/gfl2_surtr/surtr_weapon_d.vtf",
        "materials/models/gfl2_surtr/surtr_weapon_e.vtf",
        "materials/models/gfl2_surtr/surtr_weapon_n.vtf",
        "materials/models/weapons/arcticvr/m32mgl/m32mglblack.vmt",
        "materials/models/weapons/arcticvr/m32mgl/m32mglblack.vtf",
        "models/advent_flamethrower.dx80.vtx",
        "models/advent_flamethrower.dx90.vtx",
        "models/advent_flamethrower.mdl",
        "models/advent_flamethrower.phy",
        "models/advent_flamethrower.vvd",
        "models/gfl2_surtr_weapon1.dx90.vtx",
        "models/gfl2_surtr_weapon1.mdl",
        "models/gfl2_surtr_weapon1.phy",
        "models/gfl2_surtr_weapon1.vvd",
        "models/weapons/w_m32.dx80.vtx",
        "models/weapons/w_m32.dx90.vtx",
        "models/weapons/w_m32.mdl",
        "models/weapons/w_m32.phy",
        "models/weapons/w_m32.sw.vtx",
        "models/weapons/w_m32.vvd",
        "particles/advent_fx.pcf",
        "particles/advent_grenades_fx.pcf",
        "sound/grenade/gren_expl1_close.wav",
        "sound/grenade/gren_expl1_distant.wav",
        "sound/grenade/gren_expl3_close.wav",
        "sound/grenade/gren_expl3_dist2.wav",
        "sound/weapon/adv_grenadelauncher_drum_r1.wav",
        "sound/weapon/adv_grenadelauncher_drum_r2.wav",
        "sound/weapon/adv_grenadelauncher_fire_close.wav",
        "sound/weapon/adv_grenadelauncher_reload.wav",
        "sound/weapon/fire-01-cannon.wav",
        "sound/weapon/fire-02-cannon.wav",
        "sound/weapon/fire-03-cannon.wav",
        "sound/weapon/flame_loop.wav",
        "sound/weapon/flame_stop.wav",
        "sound/weapon/mec_reload.wav",
    }) do
        resource.AddSingleFile(path)
    end
end
