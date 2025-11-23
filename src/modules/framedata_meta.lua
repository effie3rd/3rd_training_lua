local game_data = require("src.modules.game_data")

local frame_data_meta = {}

local frame_data_keys = copytable(game_data.characters)
frame_data_keys[#frame_data_keys + 1] = "projectiles"

for _, char in pairs(frame_data_keys) do
  frame_data_meta[char] = {}
end

--hit_type
--1 high or low (default)
--2 low
--3 high
--4 overhead

--alex
-- frame_data_meta["alex"]["a444"] = { hit_type = {3}}                              --LP
frame_data_meta["alex"]["a534"] = { hit_type = {3}}                              --MP
frame_data_meta["alex"]["a7dc"] = { hit_type = {4}}                              --HP
-- frame_data_meta["alex"]["ae64"] = { hit_type = {3}}                              --LK
frame_data_meta["alex"]["b094"] = { hit_type = {3}}                              --MK
frame_data_meta["alex"]["b224"] = { hit_type = {3}}                              --HK
-- frame_data_meta["alex"]["b4bc"] = { hit_type = {2}}                              --d_LP
-- frame_data_meta["alex"]["b634"] = { hit_type = {2}}                              --d_MP
-- frame_data_meta["alex"]["b714"] = { hit_type = {2, 2}}                           --d_HP
frame_data_meta["alex"]["b7fc"] = { hit_type = {2}}                              --d_LK
frame_data_meta["alex"]["b99c"] = { hit_type = {2, 2, 2}}                           --d_MK
frame_data_meta["alex"]["babc"] = { hit_type = {2, 2, 2}}                         --d_HK
-- frame_data_meta["alex"]["a394"] = { hit_type = {3}}                              --cl_LP
frame_data_meta["alex"]["af7c"] = { hit_type = {3}}                              --cl_MK
frame_data_meta["alex"]["a694"] = { hit_type = {3}}                              --f_MP
frame_data_meta["alex"]["a9fc"] = { hit_type = {3}}                              --f_HP
frame_data_meta["alex"]["ad04"] = { hit_type = {3}, hit_throw = true, unparryable = true}     --b_HP
frame_data_meta["alex"]["bc0c"] = { hit_type = {4}}                             --u_LP
frame_data_meta["alex"]["bd6c"] = { hit_type = {4}}                             --u_MP
frame_data_meta["alex"]["be7c"] = { hit_type = {4}}                             --u_HP
frame_data_meta["alex"]["bf94"] = { hit_type = {4}}                             --u_LK
frame_data_meta["alex"]["c0e4"] = { hit_type = {4}}                             --u_MK
frame_data_meta["alex"]["c1c4"] = { hit_type = {4}}                             --u_HK
frame_data_meta["alex"]["c9ec"] = { throw = true}                                --throw_neutral
frame_data_meta["alex"]["72d4"] = { hit_type = {4}}                              --uoh
frame_data_meta["alex"]["c324"] = { hit_type = {4}}                              --d_HP_air
frame_data_meta["alex"]["8bd4"] = { throw = true}                              --spiral_ddt
frame_data_meta["alex"]["5944"] = { hit_type = {3}}                              --flash_chop_LP
frame_data_meta["alex"]["5aec"] = { hit_type = {3}}                              --flash_chop_MP
frame_data_meta["alex"]["5cac"] = { hit_type = {3}}                              --flash_chop_HP
frame_data_meta["alex"]["5e54"] = { hit_type = {3, 3}}                           --flash_chop_EXP
frame_data_meta["alex"]["6014"] = { throw = true}                              --power_bomb_LP
frame_data_meta["alex"]["6144"] = { throw = true}                              --power_bomb_MP
frame_data_meta["alex"]["6274"] = { throw = true}                              --power_bomb_HP
frame_data_meta["alex"]["8294"] = { hit_type = {3}}                              --slash_elbow_LK
frame_data_meta["alex"]["849c"] = { hit_type = {3}}                              --slash_elbow_MK
frame_data_meta["alex"]["871c"] = { hit_type = {3}}                              --slash_elbow_HK
frame_data_meta["alex"]["899c"] = { hit_type = {3, 3}}                           --slash_elbow_EXK
frame_data_meta["alex"]["531c"] = { hit_type = {3}, hit_throw = true}                              --air_knee_smash_LK
frame_data_meta["alex"]["54ac"] = { hit_type = {3}, hit_throw = true}                              --air_knee_smash_MK
frame_data_meta["alex"]["5624"] = { hit_type = {3}, hit_throw = true}                              --air_knee_smash_HK
frame_data_meta["alex"]["579c"] = { hit_type = {3}, hit_throw = true}                              --air_knee_smash_EXK
frame_data_meta["alex"]["70e4"] = { hit_type = {4, 4}}                           --air_stampede_LK
frame_data_meta["alex"]["7044"] = { hit_type = {4}}                              --air_stampede_LK_ext
frame_data_meta["alex"]["7094"] = { hit_type = {4}}                              --air_stampede_MK_ext
frame_data_meta["alex"]["7284"] = { hit_type = {4}}                              --air_stampede_EXK_ext

frame_data_meta["alex"]["63a4"] = { throw = true}                              --hyper_bomb
frame_data_meta["alex"]["64ec"] = { hit_type = {3, 3, 3, 3}}                   --boomerang_raid
frame_data_meta["alex"]["688c"] = { throw = true}                              --boomerang_raid_ext
frame_data_meta["alex"]["69d4"] = { throw = true}                              --stungun_headbutt


--chunli
-- frame_data_meta["chunli"]["b6ec"] = { hit_type = {3}}                            --LP
frame_data_meta["chunli"]["b78c"] = { hit_type = {3}}                            --MP
frame_data_meta["chunli"]["baac"] = { hit_type = {3}}                            --HP
-- frame_data_meta["chunli"]["bdfc"] = { hit_type = {3}}                            --LK
frame_data_meta["chunli"]["c20c"] = { hit_type = {3}}                            --MK
frame_data_meta["chunli"]["c674"] = { hit_type = {3}}                            --HK
-- frame_data_meta["chunli"]["c744"] = { hit_type = {2}}                            --d_LP
frame_data_meta["chunli"]["c804"] = { hit_type = {2}}                            --d_MP
-- frame_data_meta["chunli"]["c94c"] = { hit_type = {2}}                            --d_HP
frame_data_meta["chunli"]["cac4"] = { hit_type = {2}}                            --d_LK
frame_data_meta["chunli"]["cbb4"] = { hit_type = {2}}                            --d_MK
-- frame_data_meta["chunli"]["cce4"] = { hit_type = {2}}                            --d_HK
-- frame_data_meta["chunli"]["b63c"] = { hit_type = {3}}                            --cl_LP
frame_data_meta["chunli"]["bf5c"] = { hit_type = {3, 3}}                         --cl_MK
frame_data_meta["chunli"]["e6c4"] = { hit_type = {3, 3, 3}}                      --cl_MK_ext
frame_data_meta["chunli"]["c52c"] = { hit_type = {3}}                            --cl_HK
frame_data_meta["chunli"]["c3b4"] = { hit_type = {3}}                            --f_MK
frame_data_meta["chunli"]["b8bc"] = { hit_type = {3, 3}}                         --b_MP
frame_data_meta["chunli"]["bc6c"] = { hit_type = {3}}                            --b_HP
frame_data_meta["chunli"]["cfdc"] = { hit_type = {4}}                             --u_LP
frame_data_meta["chunli"]["d0ec"] = { hit_type = {4}}                             --u_MP
frame_data_meta["chunli"]["d1fc"] = { hit_type = {4}}                             --u_HP
frame_data_meta["chunli"]["d38c"] = { hit_type = {4}}                             --u_LK
frame_data_meta["chunli"]["d49c"] = { hit_type = {4}}                             --u_MK
frame_data_meta["chunli"]["d5ac"] = { hit_type = {4}}                             --u_HK
frame_data_meta["chunli"]["d68c"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["chunli"]["d72c"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["chunli"]["d7dc"] = { hit_type = {4, 4}}                          --uf_HP
frame_data_meta["chunli"]["dbbc"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["chunli"]["dc5c"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["chunli"]["debc"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["chunli"]["e484"] = { throw = true}                             --throw_neutral
frame_data_meta["chunli"]["e59c"] = { throw = true}                             --throw_air
frame_data_meta["chunli"]["6a3c"] = { hit_type = {4}}                            --uoh
frame_data_meta["chunli"]["ce8c"] = { hit_type = {3}}                            --df_HK
frame_data_meta["chunli"]["da2c"] = { hit_type = {4}}                            --d_HP_air
frame_data_meta["chunli"]["dd4c"] = { hit_type = {4}}                            --d_MK_air
frame_data_meta["chunli"]["6aec"] = { hit_type = {4}}                            --hazanshuu_LK
frame_data_meta["chunli"]["6e5c"] = { hit_type = {4}}                            --hazanshuu_MK
frame_data_meta["chunli"]["71cc"] = { hit_type = {4}}                            --hazanshuu_HK
frame_data_meta["chunli"]["753c"] = { hit_type = {4}}                            --hazanshuu_EXK

frame_data_meta["chunli"]["458c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_LK_ext
frame_data_meta["chunli"]["42d4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_MK_ext
frame_data_meta["chunli"]["41ec"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_LK_ext
frame_data_meta["chunli"]["4644"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_MK_ext
frame_data_meta["chunli"]["46fc"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_HK_ext
frame_data_meta["chunli"]["43bc"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_HK_ext
frame_data_meta["chunli"]["44a4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_EXK_ext
frame_data_meta["chunli"]["47b4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}                         --hyakuretsukyaku_EXK_ext
frame_data_meta["chunli"]["802c"] = { hit_type = {3, 3, 3, 3}}                   --hyakuretsukyaku_HK_ext
frame_data_meta["chunli"]["7e5c"] = { hit_type = {3, 3, 3, 3}}                   --hyakuretsukyaku_LK_ext
frame_data_meta["chunli"]["7f44"] = { hit_type = {3, 3, 3, 3}}                   --hyakuretsukyaku_MK_ext

frame_data_meta["chunli"]["2c54"] = { hit_type = {3, 3, 3, 3}}                   --spinning_bird_kick_LK
frame_data_meta["chunli"]["2fac"] = { hit_type = {3, 3, 3, 3, 3, 3}}             --spinning_bird_kick_MK
frame_data_meta["chunli"]["3334"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}       --spinning_bird_kick_HK
frame_data_meta["chunli"]["36bc"] = { hit_type = {3, 3, 3, 3, 3}}                --spinning_bird_kick_EXK

-- frame_data_meta["chunli"]["5434"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --kikoushou
frame_data_meta["chunli"]["5f54"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --houyokusen
frame_data_meta["chunli"]["669c"] = { hit_type = {3, 3, 3, 3, 3, 3, 4, 4, 4}}    --tenseiranka

--dudley
-- frame_data_meta["dudley"]["36d4"] = { hit_type = {3}}                            --LP
frame_data_meta["dudley"]["3914"] = { hit_type = {3}}                            --MP
frame_data_meta["dudley"]["3b04"] = { hit_type = {3}}                            --HP
-- frame_data_meta["dudley"]["3eb4"] = { hit_type = {3}}                            --LK
frame_data_meta["dudley"]["3fd4"] = { hit_type = {3}}                            --MK
frame_data_meta["dudley"]["4254"] = { hit_type = {3}}                            --HK
-- frame_data_meta["dudley"]["44c4"] = { hit_type = {2}}                            --d_LP
-- frame_data_meta["dudley"]["4594"] = { hit_type = {2}}                            --d_MP
-- frame_data_meta["dudley"]["46f4"] = { hit_type = {2}}                            --d_HP
frame_data_meta["dudley"]["48fc"] = { hit_type = {2}}                            --d_LK
frame_data_meta["dudley"]["49ec"] = { hit_type = {2}}                            --d_MK
frame_data_meta["dudley"]["4bf4"] = { hit_type = {2}}                            --d_HK
-- frame_data_meta["dudley"]["37b4"] = { hit_type = {3}}                            --f_LP
frame_data_meta["dudley"]["39d4"] = { hit_type = {3}}                            --f_MP
frame_data_meta["dudley"]["3cdc"] = { hit_type = {3}}                            --f_HP
frame_data_meta["dudley"]["4124"] = { hit_type = {3}}                            --f_MK
frame_data_meta["dudley"]["4394"] = { hit_type = {4}}                            --f_HK
frame_data_meta["dudley"]["4ed4"] = { hit_type = {4}}                             --u_LP
frame_data_meta["dudley"]["4fb4"] = { hit_type = {4}}                             --u_MP
frame_data_meta["dudley"]["50b4"] = { hit_type = {4}}                             --u_HP
frame_data_meta["dudley"]["51d4"] = { hit_type = {4}}                             --u_LK
frame_data_meta["dudley"]["5314"] = { hit_type = {4}}                             --u_MK
frame_data_meta["dudley"]["5454"] = { hit_type = {4}}                             --u_HK
frame_data_meta["dudley"]["5584"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["dudley"]["5664"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["dudley"]["5764"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["dudley"]["5884"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["dudley"]["59c4"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["dudley"]["5b04"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["dudley"]["6cc4"] = { hit_type = {3}}                            --tc_2
frame_data_meta["dudley"]["7294"] = { hit_type = {3}}                            --tc_1_ext
frame_data_meta["dudley"]["6be4"] = { hit_type = {3, 3}}                         --tc_2_ext
frame_data_meta["dudley"]["6064"] = { hit_type = {3}}                            --tc_3_ext
-- frame_data_meta["dudley"]["7514"] = { hit_type = {3, 3}}                         --tc_4
frame_data_meta["dudley"]["675c"] = { hit_type = {3}}                            --tc_5
-- frame_data_meta["dudley"]["7414"] = { hit_type = {3}}                            --tc_4_ext
frame_data_meta["dudley"]["6394"] = { hit_type = {3}}                            --tc_6
frame_data_meta["dudley"]["656c"] = { hit_type = {3}}                            --tc_5_ext
frame_data_meta["dudley"]["70bc"] = { hit_type = {3, 3}}                         --tc_5_ext
frame_data_meta["dudley"]["61a4"] = { hit_type = {3}}                            --tc_6_ext
frame_data_meta["dudley"]["6eb4"] = { hit_type = {3, 3}}                         --tc_8_ext
frame_data_meta["dudley"]["5f34"] = { throw = true}                             --throw_neutral
frame_data_meta["dudley"]["0a50"] = { hit_type = {4}}                            --uoh
frame_data_meta["dudley"]["0080"] = { hit_type = {3}}                            --ducking_straight
frame_data_meta["dudley"]["0288"] = { hit_type = {3, 3}}                         --ducking_upper
-- frame_data_meta["dudley"]["a9a0"] = { hit_type = {3}}                            --jet_upper_LP
-- frame_data_meta["dudley"]["ace0"] = { hit_type = {3}}                            --jet_upper_MP
-- frame_data_meta["dudley"]["b020"] = { hit_type = {3, 3}}                         --jet_upper_HP
-- frame_data_meta["dudley"]["b4b0"] = { hit_type = {3, 3}}                         --jet_upper_EXP
-- frame_data_meta["dudley"]["0490"] = { hit_type = {3}}                            --punch_and_cross_LP
frame_data_meta["dudley"]["0550"] = { hit_type = {3}}                            --punch_and_cross_MP
frame_data_meta["dudley"]["0640"] = { hit_type = {3}}                            --punch_and_cross_HP
frame_data_meta["dudley"]["0878"] = { hit_type = {3}}                            --punch_and_cross_EXP
frame_data_meta["dudley"]["c410"] = { hit_type = {3, 3, 3}}                      --machinegun_blow_LP
frame_data_meta["dudley"]["c660"] = { hit_type = {3, 3, 3, 3}}                   --machinegun_blow_MP
frame_data_meta["dudley"]["c988"] = { hit_type = {3, 3, 3, 3, 3, 3}}             --machinegun_blow_HP
frame_data_meta["dudley"]["ccc8"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}          --machinegun_blow_EXP
frame_data_meta["dudley"]["d170"] = { hit_type = {3}}                            --short_swing_blow_LK
frame_data_meta["dudley"]["d300"] = { hit_type = {3}}                            --short_swing_blow_MK
frame_data_meta["dudley"]["d490"] = { hit_type = {3}}                            --short_swing_blow_HK
frame_data_meta["dudley"]["d620"] = { hit_type = {3, 3, 3}}                      --short_swing_blow_EXK
frame_data_meta["dudley"]["d910"] = { hit_type = {1, 1, 1, 1, 1, 1, 1, 3, 3, 3, 3, 3}} --rocket_upper
frame_data_meta["dudley"]["bc08"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}    --rolling_thunder
frame_data_meta["dudley"]["b958"] = { hit_type = {3, 3, 3, 3, 3}}                --corkscrew_blow

--elena
-- frame_data_meta["elena"]["a520"] = { hit_type = {3}}                             --LP
frame_data_meta["elena"]["a978"] = { hit_type = {3, 3}}                          --MP
frame_data_meta["elena"]["ae18"] = { hit_type = {3}}                             --HP
-- frame_data_meta["elena"]["b0f8"] = { hit_type = {3}}                             --LK
-- frame_data_meta["elena"]["b228"] = { hit_type = {3}}                             --MK
frame_data_meta["elena"]["b560"] = { hit_type = {3, 3}}                          --HK
-- frame_data_meta["elena"]["b940"] = { hit_type = {2}}                             --d_LP
-- frame_data_meta["elena"]["ba30"] = { hit_type = {2}}                             --d_MP
frame_data_meta["elena"]["bb60"] = { hit_type = {3}}                             --d_HP
frame_data_meta["elena"]["bde0"] = { hit_type = {2}}                             --d_LK
frame_data_meta["elena"]["bf88"] = { hit_type = {2}}                             --d_MK
frame_data_meta["elena"]["c1d8"] = { hit_type = {2}}                             --d_HK
frame_data_meta["elena"]["ab98"] = { hit_type = {3}}                             --f_MP
frame_data_meta["elena"]["b430"] = { hit_type = {4}}                             --f_MK
frame_data_meta["elena"]["b7e0"] = { hit_type = {3}}                             --b_HK
frame_data_meta["elena"]["c690"] = { hit_type = {4}}                             --u_LP
frame_data_meta["elena"]["c820"] = { hit_type = {4}}                             --u_MP
frame_data_meta["elena"]["c9e0"] = { hit_type = {4}}                             --u_HP
frame_data_meta["elena"]["cba0"] = { hit_type = {4}}                             --u_LK
frame_data_meta["elena"]["cd30"] = { hit_type = {4}}                             --u_MK
frame_data_meta["elena"]["cef0"] = { hit_type = {4, 4}}                          --u_HK
frame_data_meta["elena"]["d0f8"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["elena"]["d288"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["elena"]["d448"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["elena"]["d608"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["elena"]["d798"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["elena"]["d958"] = { hit_type = {4, 4}}                          --uf_HK
frame_data_meta["elena"]["e620"] = { hit_type = {3}}                             --tc_1_ext
frame_data_meta["elena"]["e370"] = { hit_type = {3, 3}}                          --tc_2_ext
frame_data_meta["elena"]["e068"] = { hit_type = {4}}                             --tc_3_ext
frame_data_meta["elena"]["e1f8"] = { hit_type = {4}}                             --tc_4_ext
frame_data_meta["elena"]["df50"] = { throw = true}                               --throw_neutral
frame_data_meta["elena"]["6354"] = { hit_type = {4}}                             --uoh
frame_data_meta["elena"]["63d4"] = { hit_type = {2, 1}}                          --pa
frame_data_meta["elena"]["c440"] = { hit_type = {2}}                             --df_HK
frame_data_meta["elena"]["83cc"] = { hit_type = {2, 2}}                          --lynx_tail_LK
frame_data_meta["elena"]["858c"] = { hit_type = {2, 2}}                          --lynx_tail_MK
frame_data_meta["elena"]["874c"] = { hit_type = {2, 2, 2, 2}}                    --lynx_tail_HK
frame_data_meta["elena"]["89fc"] = { hit_type = {2, 2, 2, 2, 1}}                 --lynx_tail_EXK
-- frame_data_meta["elena"]["36cc"] = { hit_type = {3, 3, 3}}                       --rhino_horn_LK
-- frame_data_meta["elena"]["3a54"] = { hit_type = {3, 3, 3}}                       --rhino_horn_MK
-- frame_data_meta["elena"]["3dc4"] = { hit_type = {3, 3, 3}}                       --rhino_horn_HK
-- frame_data_meta["elena"]["4134"] = { hit_type = {3, 3, 3, 3}}                    --rhino_horn_EXK
frame_data_meta["elena"]["681c"] = { hit_type = {3, 3, 3, 3}}                    --spin_sides_LK
frame_data_meta["elena"]["6e14"] = { hit_type = {3, 3, 3, 3}}                    --spin_sides_MK
frame_data_meta["elena"]["740c"] = { hit_type = {3, 3, 3, 3, 3, 3}}              --spin_sides_HK
frame_data_meta["elena"]["7a04"] = { hit_type = {3, 3, 3}}                       --spin_sides_EXK
-- frame_data_meta["elena"]["321c"] = { hit_type = {3}}                             --scratch_wheel_LK
-- frame_data_meta["elena"]["333c"] = { hit_type = {3, 3}}                          --scratch_wheel_MK
-- frame_data_meta["elena"]["345c"] = { hit_type = {3, 3, 3}}                       --scratch_wheel_HK
-- frame_data_meta["elena"]["358c"] = { hit_type = {3, 3, 3, 3}}                    --scratch_wheel_EXK
frame_data_meta["elena"]["0eac"] = { hit_type = {4, 4}}                          --mallet_smash_HP_ext
frame_data_meta["elena"]["094c"] = { hit_type = {4, 4}}                          --mallet_smash_LP_ext
frame_data_meta["elena"]["0cec"] = { hit_type = {4, 4}}                          --mallet_smash_MP_ext
frame_data_meta["elena"]["fde4"] = { hit_type = {4, 4}}                          --mallet_smash_EXP_ext
-- frame_data_meta["elena"]["485c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}           --spinning_beat
-- frame_data_meta["elena"]["4dc4"] = { hit_type = {3}}                             --brave_dance
-- frame_data_meta["elena"]["5074"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}           --brave_dance_ext

--gill
-- frame_data_meta["gill"]["48e4"] = { hit_type = {3}}                              --LP
frame_data_meta["gill"]["49b4"] = { hit_type = {3}}                              --MP
-- frame_data_meta["gill"]["4d7c"] = { hit_type = {3}}                              --HP
-- frame_data_meta["gill"]["4fcc"] = { hit_type = {3}}                              --LK
frame_data_meta["gill"]["507c"] = { hit_type = {3}}                              --MK
frame_data_meta["gill"]["533c"] = { hit_type = {3, 3}}                           --HK
-- frame_data_meta["gill"]["5764"] = { hit_type = {2}}                              --d_LP
-- frame_data_meta["gill"]["5874"] = { hit_type = {2}}                              --d_MP
-- frame_data_meta["gill"]["5964"] = { hit_type = {2, 2}}                           --d_HP
frame_data_meta["gill"]["5af4"] = { hit_type = {2}}                              --d_LK
frame_data_meta["gill"]["5bb4"] = { hit_type = {2}}                              --d_MK
frame_data_meta["gill"]["5c74"] = { hit_type = {2}}                              --d_HK
frame_data_meta["gill"]["51dc"] = { hit_type = {3}}                              --f_MK
frame_data_meta["gill"]["4b8c"] = { hit_type = {3}}                              --b_MP
frame_data_meta["gill"]["5dd4"] = { hit_type = {4}}                             --u_LP
frame_data_meta["gill"]["5e94"] = { hit_type = {4}}                             --u_MP
frame_data_meta["gill"]["5f64"] = { hit_type = {4}}                             --u_HP
frame_data_meta["gill"]["6044"] = { hit_type = {4}}                             --u_LK
frame_data_meta["gill"]["60e4"] = { hit_type = {4}}                             --u_MK
frame_data_meta["gill"]["61a4"] = { hit_type = {4}}                             --u_HK
frame_data_meta["gill"]["66f4"] = { throw = true}                                --throw_neutral
frame_data_meta["gill"]["cc64"] = { hit_type = {4}}                              --uoh
frame_data_meta["gill"]["c30c"] = { hit_type = {3, 3}}                           --cyber_lariat
frame_data_meta["gill"]["c96c"] = { hit_type = {3}}                              --psycho_headbutt
frame_data_meta["gill"]["c0fc"] = { hit_type = {4}}                              --moonsault_kneedrop

--gouki
-- frame_data_meta["gouki"]["1438"] = { hit_type = {3}}                             --LP
frame_data_meta["gouki"]["1598"] = { hit_type = {3}}                             --MP
frame_data_meta["gouki"]["1818"] = { hit_type = {3}}                             --HP
-- frame_data_meta["gouki"]["1908"] = { hit_type = {3}}                             --LK
frame_data_meta["gouki"]["1a38"] = { hit_type = {3}}                             --MK
frame_data_meta["gouki"]["1bf8"] = { hit_type = {3}}                             --HK
-- frame_data_meta["gouki"]["1d28"] = { hit_type = {2}}                             --d_LP
-- frame_data_meta["gouki"]["1dd8"] = { hit_type = {2}}                             --d_MP
-- frame_data_meta["gouki"]["1e88"] = { hit_type = {2}}                             --d_HP
frame_data_meta["gouki"]["1f68"] = { hit_type = {2}}                             --d_LK
frame_data_meta["gouki"]["2008"] = { hit_type = {2}}                             --d_MK
frame_data_meta["gouki"]["20d8"] = { hit_type = {2}}                             --d_HK
-- frame_data_meta["gouki"]["13a8"] = { hit_type = {3}}                             --cl_LP
frame_data_meta["gouki"]["14e8"] = { hit_type = {3}}                             --cl_MP
frame_data_meta["gouki"]["1728"] = { hit_type = {3}}                             --cl_HP
frame_data_meta["gouki"]["1988"] = { hit_type = {3}}                             --cl_MK
frame_data_meta["gouki"]["1b08"] = { hit_type = {4, 4}}                          --cl_HK
frame_data_meta["gouki"]["1638"] = { hit_type = {4, 4}}                          --f_MP
frame_data_meta["gouki"]["21c8"] = { hit_type = {4}}                             --u_LP
frame_data_meta["gouki"]["22a8"] = { hit_type = {4}}                             --u_MP
frame_data_meta["gouki"]["2388"] = { hit_type = {4}}                             --u_HP
frame_data_meta["gouki"]["2448"] = { hit_type = {4}}                             --u_LK
frame_data_meta["gouki"]["2558"] = { hit_type = {4}}                             --u_MK
frame_data_meta["gouki"]["2628"] = { hit_type = {4}}                             --u_HK
frame_data_meta["gouki"]["2708"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["gouki"]["2800"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["gouki"]["28e0"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["gouki"]["29c0"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["gouki"]["2b30"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["gouki"]["2aa0"] = { hit_type = {4}}                             --d_MK_air
frame_data_meta["gouki"]["3850"] = { hit_type = {3, 3}}                          --tc_1_ext
frame_data_meta["gouki"]["3768"] = { throw = true}                               --throw_neutral
frame_data_meta["gouki"]["98f8"] = { hit_type = {4}}                             --uoh
frame_data_meta["gouki"]["9c18"] = { throw = true}                               --sgs
frame_data_meta["gouki"]["9c98"] = { hit_type = {3}, unparryable = true}         --kkz
frame_data_meta["gouki"]["86e8"] = { hit_type = {3, 3}}                          --tatsumaki_LK
frame_data_meta["gouki"]["87f8"] = { hit_type = {3, 3, 3, 3, 3}}                 --tatsumaki_MK
frame_data_meta["gouki"]["8968"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}     --tatsumaki_HK
frame_data_meta["gouki"]["af08"] = { hit_type = {2}}                             --hyakki
frame_data_meta["gouki"]["b308"] = { throw = true}                               --hyakki_throw_ext
frame_data_meta["gouki"]["b218"] = { hit_type = {3}}                             --hyakki_kick_ext
frame_data_meta["gouki"]["b118"] = { hit_type = {4}}                             --hyakki_punch_ext
-- frame_data_meta["gouki"]["84f8"] = { hit_type = {3}}                             --goshoryuken_LP
-- frame_data_meta["gouki"]["85c8"] = { hit_type = {3, 3}}                          --goshoryuken_MP
-- frame_data_meta["gouki"]["8658"] = { hit_type = {3, 3, 3}}                       --goshoryuken_HP
frame_data_meta["gouki"]["9618"] = { hit_type = {3, 3}}                          --tatsumaki_air_LK
frame_data_meta["gouki"]["9738"] = { hit_type = {3, 3, 3, 3}}                    --tatsumaki_air_MK
frame_data_meta["gouki"]["9818"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}        --tatsumaki_air_HK
-- frame_data_meta["gouki"]["8c28"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}           --messatsu_goushoryu
-- frame_data_meta["gouki"]["8fe0"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --messatsu_gourasen

--hugo
-- frame_data_meta["hugo"]["3fe0"] = { hit_type = {3}}                              --LP
frame_data_meta["hugo"]["40b0"] = { hit_type = {3}}                              --MP
frame_data_meta["hugo"]["4200"] = { hit_type = {4}}                              --HP
-- frame_data_meta["hugo"]["4820"] = { hit_type = {3}}                              --LK
frame_data_meta["hugo"]["48d0"] = { hit_type = {3, 4}}                           --MK
frame_data_meta["hugo"]["4c10"] = { hit_type = {4}}                              --HK
-- frame_data_meta["hugo"]["4e00"] = { hit_type = {2}}                              --d_LP
-- frame_data_meta["hugo"]["4ec0"] = { hit_type = {2}}                              --d_MP
-- frame_data_meta["hugo"]["4f60"] = { hit_type = {2}}                              --d_HP
frame_data_meta["hugo"]["5060"] = { hit_type = {2}}                              --d_LK
frame_data_meta["hugo"]["5110"] = { hit_type = {2}}                              --d_MK
frame_data_meta["hugo"]["51d0"] = { hit_type = {4}}                              --d_HK
frame_data_meta["hugo"]["4420"] = { hit_type = {3}}                              --f_HP
frame_data_meta["hugo"]["52a0"] = { hit_type = {4}}                             --u_LP
frame_data_meta["hugo"]["5370"] = { hit_type = {4}}                             --u_MP
frame_data_meta["hugo"]["5440"] = { hit_type = {4}}                             --u_HP
frame_data_meta["hugo"]["55f0"] = { hit_type = {4}}                             --u_LK
frame_data_meta["hugo"]["56c0"] = { hit_type = {4}}                             --u_MK
frame_data_meta["hugo"]["5790"] = { hit_type = {4}}                             --u_HK
frame_data_meta["hugo"]["5540"] = { hit_type = {4}}                             --d_HP_air
frame_data_meta["hugo"]["5da8"] = { throw = true}                                --throw_neutral
frame_data_meta["hugo"]["1cd4"] = { hit_type = {4}}                              --uoh
frame_data_meta["hugo"]["efcc"] = { hit_type = {3}}                              --giant_palm_bomber_LP
frame_data_meta["hugo"]["f1bc"] = { hit_type = {3}}                              --giant_palm_bomber_MP
frame_data_meta["hugo"]["f3ac"] = { hit_type = {3}}                              --giant_palm_bomber_HP
frame_data_meta["hugo"]["f59c"] = { hit_type = {3, 3, 3}}                        --giant_palm_bomber_EXP
frame_data_meta["hugo"]["06b4"] = { throw = true}                                --ultra_throw
frame_data_meta["hugo"]["0900"] = { throw = true}                              --meat_squasher_LK
frame_data_meta["hugo"]["1d64"] = { throw = true}                              --meat_squasher_LK
frame_data_meta["hugo"]["0a00"] = { throw = true}                              --meat_squasher_MK
frame_data_meta["hugo"]["1f24"] = { throw = true}                              --meat_squasher_MK
frame_data_meta["hugo"]["0b00"] = { throw = true}                              --meat_squasher_HK
frame_data_meta["hugo"]["2184"] = { throw = true}                              --meat_squasher_HK
frame_data_meta["hugo"]["f7a4"] = { hit_type = {3}}                              --monster_lariat_LK
frame_data_meta["hugo"]["fa54"] = { hit_type = {3}}                              --monster_lariat_MK
frame_data_meta["hugo"]["fd1c"] = { hit_type = {3}}                              --monster_lariat_HK
frame_data_meta["hugo"]["0044"] = { hit_type = {3}}                              --monster_lariat_EXK
frame_data_meta["hugo"]["0444"] = { throw = true}                              --moonsault_press_LP
frame_data_meta["hugo"]["05a4"] = { throw = true}                              --moonsault_press_MP
frame_data_meta["hugo"]["062c"] = { throw = true}                              --moonsault_press_HP
frame_data_meta["hugo"]["096c"] = { throw = true}                              --shootdown_backbreaker_LK
frame_data_meta["hugo"]["0ab4"] = { throw = true}                              --shootdown_backbreaker_MK
frame_data_meta["hugo"]["0c14"] = { throw = true}                              --shootdown_backbreaker_HK
frame_data_meta["hugo"]["0d8c"] = { throw = true}                              --gigas_breaker
frame_data_meta["hugo"]["1164"] = { throw = true}                              --megaton_press
frame_data_meta["hugo"]["ffe0"] = { hit_type = {3}}                            --megaton_press_ext
-- frame_data_meta["hugo"]["1294"] = { hit_type = {1}}                            --hammer_mountain
frame_data_meta["hugo"]["15cc"] = { hit_type = {1, 3, 3, 3}}                   --hammer_mountain_ext

--ibuki
-- frame_data_meta["ibuki"]["f5b0"] = { hit_type = {3}}                             --LP
frame_data_meta["ibuki"]["f690"] = { hit_type = {3, 3}}                          --MP
frame_data_meta["ibuki"]["fc48"] = { hit_type = {3, 3}}                          --HP
-- frame_data_meta["ibuki"]["0018"] = { hit_type = {3}}                             --LK
frame_data_meta["ibuki"]["05d0"] = { hit_type = {3}}                             --MK
frame_data_meta["ibuki"]["0b10"] = { hit_type = {3}}                             --HK
-- frame_data_meta["ibuki"]["1058"] = { hit_type = {2}}                             --d_LP
-- frame_data_meta["ibuki"]["1118"] = { hit_type = {2}}                             --d_MP
-- frame_data_meta["ibuki"]["12a8"] = { hit_type = {2}}                             --d_HP
frame_data_meta["ibuki"]["14e0"] = { hit_type = {2}}                             --d_LK
frame_data_meta["ibuki"]["15f0"] = { hit_type = {2}}                             --d_MK
frame_data_meta["ibuki"]["19c0"] = { hit_type = {2}}                             --d_HK
-- frame_data_meta["ibuki"]["f468"] = { hit_type = {3}}                             --cl_LP
frame_data_meta["ibuki"]["fa10"] = { hit_type = {3, 3}}                          --cl_HP
frame_data_meta["ibuki"]["0920"] = { hit_type = {3, 3, 3}}                       --cl_HK
-- frame_data_meta["ibuki"]["01a8"] = { hit_type = {3}}                             --f_LK
frame_data_meta["ibuki"]["0748"] = { hit_type = {4}}                             --f_MK
frame_data_meta["ibuki"]["0d90"] = { hit_type = {3}}                             --f_HK
frame_data_meta["ibuki"]["f838"] = { hit_type = {3, 3}}                          --b_MP
frame_data_meta["ibuki"]["0398"] = { hit_type = {3}}                             --b_MK
frame_data_meta["ibuki"]["1c10"] = { hit_type = {4}}                             --u_LP
frame_data_meta["ibuki"]["1d10"] = { hit_type = {4}}                             --u_MP
frame_data_meta["ibuki"]["1ee8"] = { hit_type = {4}}                             --u_HP
frame_data_meta["ibuki"]["20f0"] = { hit_type = {4}}                             --u_LK
frame_data_meta["ibuki"]["2210"] = { hit_type = {4}}                             --u_MK
frame_data_meta["ibuki"]["2330"] = { hit_type = {4}}                             --u_HK
frame_data_meta["ibuki"]["2450"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["ibuki"]["25b0"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["ibuki"]["2748"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["ibuki"]["2878"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["ibuki"]["29a8"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["ibuki"]["3480"] = { hit_type = {4, 4}}                          --tc_12_ext jump hp fmk
frame_data_meta["ibuki"]["3580"] = { hit_type = {4}}                             --tc_13_ext jump lp fhp
frame_data_meta["ibuki"]["3f28"] = { hit_type = {3, 3}}                          --tc_2
frame_data_meta["ibuki"]["3828"] = { hit_type = {3}}                             --tc_3
frame_data_meta["ibuki"]["3a48"] = { hit_type = {3, 3, 3}}                       --tc_2_ext
frame_data_meta["ibuki"]["3290"] = { hit_type = {2}}                             --tc_4
frame_data_meta["ibuki"]["36c8"] = { hit_type = {3, 3}}                          --tc_3_ext
frame_data_meta["ibuki"]["4290"] = { hit_type = {3, 3}}                          --tc_4_ext
frame_data_meta["ibuki"]["30a0"] = { hit_type = {3}}                             --tc_9_ext
frame_data_meta["ibuki"]["2eb8"] = { throw = true}                              --throw_neutral
frame_data_meta["ibuki"]["dec0"] = { hit_type = {4}}                             --uoh
frame_data_meta["ibuki"]["e2f0"] = { hit_type = {1}, hit_throw = true}                             --pa
frame_data_meta["ibuki"]["1740"] = { hit_type = {2}}                             --df_MK
frame_data_meta["ibuki"]["7ca0"] = { hit_type = {4, 4}}                          --hien_LK
frame_data_meta["ibuki"]["8100"] = { hit_type = {4, 4}}                          --hien_MK
frame_data_meta["ibuki"]["8560"] = { hit_type = {4, 4}}                          --hien_HK
frame_data_meta["ibuki"]["89c0"] = { hit_type = {4, 4}}                          --hien_EXK
frame_data_meta["ibuki"]["8e20"] = { hit_type = {3}, unparryable = true, hit_throw = true}                             --raida_LP
frame_data_meta["ibuki"]["8f68"] = { hit_type = {3}, unparryable = true, hit_throw = true}                             --raida_MP
frame_data_meta["ibuki"]["90b0"] = { hit_type = {3}, unparryable = true, hit_throw = true}                             --raida_HP
frame_data_meta["ibuki"]["91f8"] = { hit_type = {2}, hit_throw = true}                             --kubiori_LP
frame_data_meta["ibuki"]["93b8"] = { hit_type = {2}, hit_throw = true}                             --kubiori_MP
frame_data_meta["ibuki"]["9578"] = { hit_type = {2}, hit_throw = true}                             --kubiori_HP
frame_data_meta["ibuki"]["9750"] = { hit_type = {2}, hit_throw = true}                             --kubiori_EXP
-- frame_data_meta["ibuki"]["7120"] = { hit_type = {3, 3, 3}}                       --kazekiri_LK
-- frame_data_meta["ibuki"]["7370"] = { hit_type = {3, 3, 3}}                       --kazekiri_MK
-- frame_data_meta["ibuki"]["75f0"] = { hit_type = {3, 3, 3, 3}}                    --kazekiri_HK
-- frame_data_meta["ibuki"]["7888"] = { hit_type = {3, 3, 3, 3}}                    --kazekiri_EXK
frame_data_meta["ibuki"]["9910"] = { hit_type = {3, 3}}                          --tsumuji_LK
frame_data_meta["ibuki"]["9de8"] = { hit_type = {3, 3, 3}}                       --tsumuji_MK
frame_data_meta["ibuki"]["a428"] = { hit_type = {3, 3}}                          --tsumuji_HK
frame_data_meta["ibuki"]["e490"] = { hit_type = {3}}                             --tsumuji_EXK
frame_data_meta["ibuki"]["e988"] = { hit_type = {3}}                             --tsumuji_EXK
frame_data_meta["ibuki"]["f980"] = { hit_type = {3}}                             --tsumuji_HK_ext
frame_data_meta["ibuki"]["e6f8"] = { hit_type = {3, 3}}                          --tsumuji_EXK_ext
frame_data_meta["ibuki"]["eb60"] = { hit_type = {2}}                             --tsumuji_low_EXK
frame_data_meta["ibuki"]["fc60"] = { hit_type = {2}}                             --tsumuji_low_HK_ext
frame_data_meta["ibuki"]["a768"] = { hit_type = {2}}                             --tsumuji_low_LK_ext
frame_data_meta["ibuki"]["e810"] = { hit_type = {2, 2}}                          --tsumuji_low_EXK_ext
-- frame_data_meta["ibuki"]["c800"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --yoroidooshi

--ken
-- frame_data_meta["ken"]["a270"] = { hit_type = {3}}                               --LP
frame_data_meta["ken"]["a3d0"] = { hit_type = {3}}                               --MP
frame_data_meta["ken"]["a560"] = { hit_type = {3}}                               --HP
-- frame_data_meta["ken"]["a630"] = { hit_type = {3}}                               --LK
frame_data_meta["ken"]["a6b0"] = { hit_type = {3}}                               --MK
frame_data_meta["ken"]["aa70"] = { hit_type = {3}}                               --HK
-- frame_data_meta["ken"]["ae08"] = { hit_type = {2}}                               --d_LP
-- frame_data_meta["ken"]["aeb8"] = { hit_type = {2}}                               --d_MP
-- frame_data_meta["ken"]["af68"] = { hit_type = {2}}                               --d_HP
frame_data_meta["ken"]["b048"] = { hit_type = {2}}                               --d_LK
frame_data_meta["ken"]["b0e8"] = { hit_type = {2}}                               --d_MK
frame_data_meta["ken"]["b1b8"] = { hit_type = {2}}                               --d_HK
-- frame_data_meta["ken"]["a1e0"] = { hit_type = {3}}                               --cl_LP
frame_data_meta["ken"]["a320"] = { hit_type = {3}}                               --cl_MP
frame_data_meta["ken"]["a470"] = { hit_type = {3}}                               --cl_HP
frame_data_meta["ken"]["a870"] = { hit_type = {3}}                               --f_MK
frame_data_meta["ken"]["abe8"] = { hit_type = {4}}                               --f_HK
frame_data_meta["ken"]["a980"] = { hit_type = {4, 4}}                            --b_MK
frame_data_meta["ken"]["b2a8"] = { hit_type = {4}}                             --u_LP
frame_data_meta["ken"]["b388"] = { hit_type = {4}}                             --u_MP
frame_data_meta["ken"]["b468"] = { hit_type = {4}}                             --u_HP
frame_data_meta["ken"]["b528"] = { hit_type = {4}}                             --u_LK
frame_data_meta["ken"]["b638"] = { hit_type = {4}}                             --u_MK
frame_data_meta["ken"]["b708"] = { hit_type = {4}}                             --u_HK
frame_data_meta["ken"]["b7e8"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["ken"]["b8c8"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["ken"]["b9a8"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["ken"]["ba88"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["ken"]["bb68"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["ken"]["bc48"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["ken"]["c188"] = { hit_type = {3}}                               --tc_1_ext
frame_data_meta["ken"]["bff8"] = { throw = true}                                 --throw_neutral
frame_data_meta["ken"]["23ec"] = { hit_type = {4}}                               --uoh
-- frame_data_meta["ken"]["24cc"] = { hit_type = {3, 3}}                            --pa
-- frame_data_meta["ken"]["0884"] = { hit_type = {3}}                               --shoryuken_LP
-- frame_data_meta["ken"]["0984"] = { hit_type = {3, 3}}                            --shoryuken_MP
-- frame_data_meta["ken"]["0a24"] = { hit_type = {3, 3, 3}}                         --shoryuken_HP
-- frame_data_meta["ken"]["0b64"] = { hit_type = {3, 3, 3, 3}}                      --shoryuken_EXP
frame_data_meta["ken"]["0c44"] = { hit_type = {3, 3, 3}}                         --tatsumaki_LK
frame_data_meta["ken"]["0d54"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}             --tatsumaki_MK
frame_data_meta["ken"]["0ee4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}       --tatsumaki_HK
frame_data_meta["ken"]["1074"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --tatsumaki_EXK
frame_data_meta["ken"]["1fd4"] = { hit_type = {3, 3, 3, 3}}                      --tatsumaki_air_LK
frame_data_meta["ken"]["2114"] = { hit_type = {3, 3, 3, 3, 3, 3}}                --tatsumaki_air_MK
frame_data_meta["ken"]["21f4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}          --tatsumaki_air_HK
frame_data_meta["ken"]["22d4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --tatsumaki_air_EXK
-- frame_data_meta["ken"]["1214"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --shoryu_reppa
-- frame_data_meta["ken"]["15b4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}       --shinryuuken
frame_data_meta["ken"]["1834"] = { hit_type = {3, 3, 3, 3, 3}}                   --shippu

--makoto
-- frame_data_meta["makoto"]["1d10"] = { hit_type = {3}}                            --LP
frame_data_meta["makoto"]["1ec0"] = { hit_type = {3}}                            --MP
frame_data_meta["makoto"]["2100"] = { hit_type = {3}}                            --HP
-- frame_data_meta["makoto"]["23d0"] = { hit_type = {3}}                            --LK
frame_data_meta["makoto"]["25f0"] = { hit_type = {3}}                            --MK
frame_data_meta["makoto"]["28c0"] = { hit_type = {3}}                            --HK
-- frame_data_meta["makoto"]["2be0"] = { hit_type = {2}}                            --d_LP
-- frame_data_meta["makoto"]["2cc0"] = { hit_type = {2}}                            --d_MP
frame_data_meta["makoto"]["2de0"] = { hit_type = {2}}                            --d_HP
frame_data_meta["makoto"]["2f10"] = { hit_type = {2}}                            --d_LK
-- frame_data_meta["makoto"]["2fe0"] = { hit_type = {2}}                            --d_MK
frame_data_meta["makoto"]["30c0"] = { hit_type = {3}}                            --d_HK
-- frame_data_meta["makoto"]["1de0"] = { hit_type = {3}}                            --f_LP
frame_data_meta["makoto"]["1fc0"] = { hit_type = {3}}                            --f_MP
-- frame_data_meta["makoto"]["24e0"] = { hit_type = {3}}                            --f_LK
frame_data_meta["makoto"]["2720"] = { hit_type = {3}}                            --f_MK
frame_data_meta["makoto"]["2a20"] = { hit_type = {2}}                            --f_HK
frame_data_meta["makoto"]["31e0"] = { hit_type = {4}}                             --u_LP
frame_data_meta["makoto"]["32c0"] = { hit_type = {4}}                             --u_MP
frame_data_meta["makoto"]["3380"] = { hit_type = {4}}                             --u_HP
frame_data_meta["makoto"]["3460"] = { hit_type = {4}}                             --u_LK
frame_data_meta["makoto"]["3520"] = { hit_type = {4}}                             --u_MK
frame_data_meta["makoto"]["3610"] = { hit_type = {4}}                             --u_HK
frame_data_meta["makoto"]["3720"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["makoto"]["37e0"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["makoto"]["38e0"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["makoto"]["3a50"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["makoto"]["3b10"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["makoto"]["3c00"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["makoto"]["3d10"] = { hit_type = {4}}                             --ub_LP
frame_data_meta["makoto"]["3dd0"] = { hit_type = {4}}                             --ub_MP
frame_data_meta["makoto"]["3ed0"] = { hit_type = {4}}                             --ub_HP
frame_data_meta["makoto"]["4040"] = { hit_type = {4}}                             --ub_LK
frame_data_meta["makoto"]["4100"] = { hit_type = {4}}                             --ub_MK
frame_data_meta["makoto"]["41f0"] = { hit_type = {4}}                             --ub_HK
frame_data_meta["makoto"]["2220"] = { hit_type = {3}}                            --tc_2
frame_data_meta["makoto"]["4a68"] = { hit_type = {3, 3}}                         --tc_1_ext
frame_data_meta["makoto"]["48a8"] = { hit_type = {3, 3, 3, 3}}                   --tc_2_ext
frame_data_meta["makoto"]["4ae8"] = { hit_type = {3, 3}}                         --tc_3_ext
frame_data_meta["makoto"]["4718"] = { throw = true}                              --throw_neutral
frame_data_meta["makoto"]["db10"] = { hit_type = {4}}                            --uoh
-- frame_data_meta["makoto"]["f7a8"] = { hit_type = {3}}                            --pa
frame_data_meta["makoto"]["e750"] = { hit_type = {3}}                            --hayate
frame_data_meta["makoto"]["e2d0"] = { hit_type = {3}}                            --hayate_1
frame_data_meta["makoto"]["e520"] = { hit_type = {3}}                            --hayate_2
frame_data_meta["makoto"]["e638"] = { hit_type = {3}}                            --hayate_3
frame_data_meta["makoto"]["e860"] = { hit_type = {3}}                            --hayate_ext
frame_data_meta["makoto"]["ebb8"] = { hit_type = {4}}                            --oroshi_LP
frame_data_meta["makoto"]["ed98"] = { hit_type = {4}}                            --oroshi_MP
frame_data_meta["makoto"]["ee98"] = { hit_type = {4}}                            --oroshi_HP
frame_data_meta["makoto"]["ef98"] = { hit_type = {4}}                            --oroshi_EXP
-- frame_data_meta["makoto"]["f0a8"] = { hit_type = {3}}                            --fukiage_LP
-- frame_data_meta["makoto"]["f3e8"] = { hit_type = {3}}                            --fukiage_MP
-- frame_data_meta["makoto"]["f518"] = { hit_type = {3}}                            --fukiage_HP
-- frame_data_meta["makoto"]["f648"] = { hit_type = {3}}                            --fukiage_EXP
frame_data_meta["makoto"]["2190"] = { hit_type = {4}}                            --tsurugi_LK
frame_data_meta["makoto"]["2310"] = { hit_type = {4}}                            --tsurugi_MK
frame_data_meta["makoto"]["2410"] = { hit_type = {4}}                            --tsurugi_HK
frame_data_meta["makoto"]["2510"] = { hit_type = {4, 4}}                         --tsurugi_EXK
frame_data_meta["makoto"]["0c10"] = { throw = true}                              --karakusa_LK
frame_data_meta["makoto"]["0d90"] = { throw = true}                              --karakusa_MK
frame_data_meta["makoto"]["0e60"] = { throw = true}                              --karakusa_HK
-- frame_data_meta["makoto"]["1438"] = { hit_type = {3}}                            --seichusengodanzuki
frame_data_meta["makoto"]["0290"] = { hit_type = {4, 3, 1}}                      --abaretosanami_LK                                                                                  
frame_data_meta["makoto"]["fde8"] = { hit_type = {3}}                            --abaretosanami_LK_ext                                                                              
frame_data_meta["makoto"]["fec8"] = { hit_type = {3}}                            --abaretosanami_MK_ext    
frame_data_meta["makoto"]["ffa8"] = { hit_type = {3}}                            --abaretosanami_HK_ext                                                                              

--necro
-- frame_data_meta["necro"]["c914"] = { hit_type = {3}}                             --LP
frame_data_meta["necro"]["cc1c"] = { hit_type = {3}}                             --MP
frame_data_meta["necro"]["cf84"] = { hit_type = {3}}                             --HP
-- frame_data_meta["necro"]["d40c"] = { hit_type = {3}}                             --LK
-- frame_data_meta["necro"]["d5cc"] = { hit_type = {3}}                             --MK
frame_data_meta["necro"]["d85c"] = { hit_type = {3}}                             --HK
-- frame_data_meta["necro"]["dccc"] = { hit_type = {2}}                             --d_LP
-- frame_data_meta["necro"]["dd9c"] = { hit_type = {2}}                             --d_MP
-- frame_data_meta["necro"]["defc"] = { hit_type = {2}}                             --d_HP
frame_data_meta["necro"]["e18c"] = { hit_type = {2}}                             --d_LK
frame_data_meta["necro"]["e29c"] = { hit_type = {2}}                             --d_MK
frame_data_meta["necro"]["e444"] = { hit_type = {2}}                             --d_HK
-- frame_data_meta["necro"]["ca74"] = { hit_type = {3}}                             --b_LP
frame_data_meta["necro"]["cdc4"] = { hit_type = {3}}                             --b_MP
-- frame_data_meta["necro"]["d1a4"] = { hit_type = {3}}                             --b_HP
-- frame_data_meta["necro"]["d4ec"] = { hit_type = {3}}                             --b_LK
frame_data_meta["necro"]["d6fc"] = { hit_type = {3}}                             --b_MK
frame_data_meta["necro"]["dadc"] = { hit_type = {3}}                             --b_HK
-- frame_data_meta["necro"]["e01c"] = { hit_type = {3}}                             --db_HP
frame_data_meta["necro"]["e5e4"] = { hit_type = {4}}                             --u_LP
frame_data_meta["necro"]["e6b4"] = { hit_type = {4}}                             --u_MP
frame_data_meta["necro"]["e7a4"] = { hit_type = {4}}                             --u_HP
frame_data_meta["necro"]["e954"] = { hit_type = {4}}                             --u_LK
frame_data_meta["necro"]["ec34"] = { hit_type = {4}}                             --u_MK
frame_data_meta["necro"]["ed74"] = { hit_type = {4}}                             --u_HK
frame_data_meta["necro"]["eef4"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["necro"]["efa4"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["necro"]["f084"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["necro"]["f224"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["necro"]["fd04"] = { hit_type = {3}}                             --tc_1_ext
frame_data_meta["necro"]["fbbc"] = { throw = true}                               --throw_neutral
frame_data_meta["necro"]["7cf4"] = { hit_type = {4}}                             --uoh
-- frame_data_meta["necro"]["8574"] = { hit_type = {3, 3, 3, 3, 3, 3}}              --pa
frame_data_meta["necro"]["e9e4"] = { hit_type = {1}, cooldown = 7}               --drill_LK
frame_data_meta["necro"]["f2cc"] = { hit_type = {1}, cooldown = 7}               --drill_MK
frame_data_meta["necro"]["f51c"] = { hit_type = {1}, cooldown = 7}               --drill_HK
frame_data_meta["necro"]["7274"] = { hit_type = {2}, hit_throw = true, unparryable = true}                             --snake_fang_LK
frame_data_meta["necro"]["7374"] = { hit_type = {2}, hit_throw = true, unparryable = true}                             --snake_fang_MK
frame_data_meta["necro"]["7474"] = { hit_type = {2}, hit_throw = true, unparryable = true}                             --snake_fang_HK
frame_data_meta["necro"]["651c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --denji_blast_LP
frame_data_meta["necro"]["680c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --denji_blast_MP
frame_data_meta["necro"]["6b1c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --denji_blast_HP
frame_data_meta["necro"]["7574"] = { hit_type = {4}}                             --flying_viper_LP
frame_data_meta["necro"]["7674"] = { hit_type = {4}}                             --flying_viper_MP
frame_data_meta["necro"]["7774"] = { hit_type = {4}}                             --flying_viper_HP
frame_data_meta["necro"]["7874"] = { hit_type = {4, 4}}                          --flying_viper_EXP
frame_data_meta["necro"]["7d94"] = { hit_type = {4}}                             --rising_cobra_LK
frame_data_meta["necro"]["7f24"] = { hit_type = {4}}                             --rising_cobra_MK
frame_data_meta["necro"]["80b4"] = { hit_type = {4}}                             --rising_cobra_HK
frame_data_meta["necro"]["8244"] = { hit_type = {4, 4}}                          --rising_cobra_EXK
frame_data_meta["necro"]["4fdc"] = { hit_type = {3, 3}}                          --tornado_hook_LP
frame_data_meta["necro"]["53dc"] = { hit_type = {3, 3}}                          --tornado_hook_MP
frame_data_meta["necro"]["5824"] = { hit_type = {3, 3, 3}}                       --tornado_hook_HP
frame_data_meta["necro"]["5e7c"] = { hit_type = {3, 3, 3, 3, 3}}                 --tornado_hook_EXP
-- frame_data_meta["necro"]["6e8c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --magnetic_storm
frame_data_meta["necro"]["7a14"] = { throw = true}                               --slam_dance

--oro
-- frame_data_meta["oro"]["49d0"] = { hit_type = {3}}                               --LP
frame_data_meta["oro"]["4c40"] = { hit_type = {3}}                               --MP
frame_data_meta["oro"]["4f08"] = { hit_type = {4, 4}}                            --HP
-- frame_data_meta["oro"]["5258"] = { hit_type = {3}}                               --LK
frame_data_meta["oro"]["54f0"] = { hit_type = {3}}                               --MK
frame_data_meta["oro"]["56b0"] = { hit_type = {3}}                               --HK
-- frame_data_meta["oro"]["58e8"] = { hit_type = {2}}                               --d_LP
-- frame_data_meta["oro"]["59a8"] = { hit_type = {2}}                               --d_MP
-- frame_data_meta["oro"]["5a68"] = { hit_type = {2}}                               --d_HP
frame_data_meta["oro"]["5c10"] = { hit_type = {2}}                               --d_LK
frame_data_meta["oro"]["5da0"] = { hit_type = {2}}                               --d_MK
frame_data_meta["oro"]["5ed0"] = { hit_type = {2}}                               --d_HK
-- frame_data_meta["oro"]["48f0"] = { hit_type = {3}}                               --cl_LP
frame_data_meta["oro"]["4a80"] = { hit_type = {3, 3}}                            --cl_MP
-- frame_data_meta["oro"]["5188"] = { hit_type = {3}}                               --cl_LK
frame_data_meta["oro"]["5378"] = { hit_type = {3}}                               --cl_MK
frame_data_meta["oro"]["4d30"] = { hit_type = {3}}                               --f_MP
frame_data_meta["oro"]["5fc0"] = { hit_type = {4}}                             --u_LP
frame_data_meta["oro"]["60d0"] = { hit_type = {4}}                             --u_MP
frame_data_meta["oro"]["6200"] = { hit_type = {4}}                             --u_HP
frame_data_meta["oro"]["6300"] = { hit_type = {4}}                             --u_LK
frame_data_meta["oro"]["6460"] = { hit_type = {4}}                             --u_MK
frame_data_meta["oro"]["6590"] = { hit_type = {4}}                             --u_HK
frame_data_meta["oro"]["6708"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["oro"]["6888"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["oro"]["6a08"] = { hit_type = {4, 4}}                          --uf_HP
frame_data_meta["oro"]["6bf8"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["oro"]["6d08"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["oro"]["6ef8"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["oro"]["7a18"] = { hit_type = {3}}                               --tc_1_ext
frame_data_meta["oro"]["72c8"] = { throw = true}                                 --throw_neutral
frame_data_meta["oro"]["73c8"] = { throw = true}                                 --throw_back
frame_data_meta["oro"]["0fbc"] = { hit_type = {4}}                               --uoh
frame_data_meta["oro"]["d71c"] = { hit_type = {3}, hit_throw = true, unparryable = true}                               --niouriki_LP
frame_data_meta["oro"]["d89c"] = { hit_type = {3}, hit_throw = true, unparryable = true}                               --niouriki_MP
frame_data_meta["oro"]["d96c"] = { hit_type = {3}, hit_throw = true, unparryable = true}                               --niouriki_HP
-- frame_data_meta["oro"]["dd6c"] = { hit_type = {3}}                               --oniyanma_LP
-- frame_data_meta["oro"]["dee4"] = { hit_type = {3}}                               --oniyanma_MP
-- frame_data_meta["oro"]["e02c"] = { hit_type = {3, 3, 3, 3}}                      --oniyanma_HP
-- frame_data_meta["oro"]["e1ec"] = { hit_type = {3, 3, 3, 3}}                      --oniyanma_EXP
frame_data_meta["oro"]["08bc"] = { hit_type = {4, 4}}                            --hitobashira_LK
frame_data_meta["oro"]["0b2c"] = { hit_type = {4, 4}}                            --hitobashira_MK
frame_data_meta["oro"]["0c9c"] = { hit_type = {4, 4}}                            --hitobashira_HK
frame_data_meta["oro"]["0e0c"] = { hit_type = {4, 4, 4}}                         --hitobashira_EXK
frame_data_meta["oro"]["012c"] = { hit_type = {4, 4}}                            --hitobashira_air
frame_data_meta["oro"]["041c"] = { hit_type = {4, 4}}                            --hitobashira_airEXK
frame_data_meta["oro"]["74f8"] = { throw = true}                                 --kishinriki
frame_data_meta["oro"]["fd04"] = { throw = true}                                 --kishinriki_EXP

--q
-- frame_data_meta["q"]["d18c"] = { hit_type = {3}}                                 --LP
frame_data_meta["q"]["d304"] = { hit_type = {3}}                                 --MP
frame_data_meta["q"]["d72c"] = { hit_type = {3}}                                 --HP
-- frame_data_meta["q"]["dd1c"] = { hit_type = {3}}                                 --LK
frame_data_meta["q"]["df1c"] = { hit_type = {3}}                                 --MK
frame_data_meta["q"]["e01c"] = { hit_type = {3}}                                 --HK
-- frame_data_meta["q"]["e3f4"] = { hit_type = {2}}                                 --d_LP
-- frame_data_meta["q"]["e4c4"] = { hit_type = {2}}                                 --d_MP
frame_data_meta["q"]["e684"] = { hit_type = {2}}                                 --d_HP
frame_data_meta["q"]["e7e4"] = { hit_type = {2}}                                 --d_LK
frame_data_meta["q"]["e8b4"] = { hit_type = {2}}                                 --d_MK
frame_data_meta["q"]["ea14"] = { hit_type = {2}}                                 --d_HK
-- frame_data_meta["q"]["d09c"] = { hit_type = {3}}                                 --cl_LP
-- frame_data_meta["q"]["ddfc"] = { hit_type = {3}}                                 --cl_MK
frame_data_meta["q"]["d524"] = { hit_type = {3}}                                 --b_MP
frame_data_meta["q"]["da24"] = { hit_type = {3}}                                 --b_HP
-- frame_data_meta["q"]["e1f4"] = { hit_type = {3}}                                 --b_HK
frame_data_meta["q"]["ec04"] = { hit_type = {4}}                             --u_LP
frame_data_meta["q"]["eca4"] = { hit_type = {4}}                             --u_MP
frame_data_meta["q"]["eda4"] = { hit_type = {4}}                             --u_HP
frame_data_meta["q"]["eea4"] = { hit_type = {4}}                             --u_LK
frame_data_meta["q"]["ef94"] = { hit_type = {4}}                             --u_MK
frame_data_meta["q"]["f074"] = { hit_type = {4}}                             --u_HK
frame_data_meta["q"]["f194"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["q"]["f234"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["q"]["f334"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["q"]["f494"] = { hit_type = {4}}                             --ub_MP
frame_data_meta["q"]["f594"] = { hit_type = {4}}                             --ub_HP
frame_data_meta["q"]["f9ac"] = { throw = true}                                   --throw_neutral
frame_data_meta["q"]["faf4"] = { throw = true}                                   --throw_forward
frame_data_meta["q"]["fc3c"] = { throw = true}                                   --throw_back
frame_data_meta["q"]["9074"] = { hit_type = {4}}                                 --uoh

frame_data_meta["q"]["518c"] = { hit_type = {2}}                                 --dashing_leg_attack_LK
frame_data_meta["q"]["5454"] = { hit_type = {2}}                                 --dashing_leg_attack_MK
frame_data_meta["q"]["5734"] = { hit_type = {2}}                                 --dashing_leg_attack_HK
frame_data_meta["q"]["5a2c"] = { hit_type = {2, 1}}                              --dashing_leg_attack_EXK
frame_data_meta["q"]["6414"] = { hit_type = {3, 3, 3}}                           --high_speed_barrage_LP
frame_data_meta["q"]["685c"] = { hit_type = {3, 3, 3}}                           --high_speed_barrage_MP
frame_data_meta["q"]["6c8c"] = { hit_type = {3, 3, 3}}                           --high_speed_barrage_HP
frame_data_meta["q"]["70a4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}               --high_speed_barrage_EXP
frame_data_meta["q"]["44d4"] = { hit_type = {3}}                                 --dashing_head_attack_LP
frame_data_meta["q"]["47b4"] = { hit_type = {3}}                                 --dashing_head_attack_MP
frame_data_meta["q"]["4ac4"] = { hit_type = {3}}                                 --dashing_head_attack_HP
frame_data_meta["q"]["4e04"] = { hit_type = {3}}                                 --dashing_head_attack_EXP
frame_data_meta["q"]["7714"] = { throw = true}                                   --capture_and_deadly_blow_LK
frame_data_meta["q"]["794c"] = { throw = true}                                   --capture_and_deadly_blow_MK
frame_data_meta["q"]["7b84"] = { throw = true}                                   --capture_and_deadly_blow_HK
frame_data_meta["q"]["61ac"] = { hit_type = {4}}                                 --dashing_head_attack_high_HP_ext
frame_data_meta["q"]["5cdc"] = { hit_type = {4}}                                 --dashing_head_attack_high_LP_ext
frame_data_meta["q"]["5f44"] = { hit_type = {4}}                                 --dashing_head_attack_high_MP_ext
frame_data_meta["q"]["7dbc"] = { hit_type = {3}}                                 --critical_combo_attack
frame_data_meta["q"]["8304"] = { hit_type = {2}}                                 --critical_combo_attack
frame_data_meta["q"]["81a4"] = { hit_type = {3, 3}}                              --critical_combo_attack_ext
frame_data_meta["q"]["8464"] = { hit_type = {1, 3}}                                 --deadly_double_combination
-- frame_data_meta["q"]["8c1c"] = { hit_type = {3}}                                 --total_destruction_attack
frame_data_meta["q"]["8df4"] = { throw = true}                                   --total_destruction_throw

--remy
-- frame_data_meta["remy"]["9d90"] = { hit_type = {3}}                              --LP
frame_data_meta["remy"]["9f20"] = { hit_type = {3}}                              --MP
frame_data_meta["remy"]["a100"] = { hit_type = {3}}                              --HP
-- frame_data_meta["remy"]["a2a0"] = { hit_type = {3}}                              --LK
frame_data_meta["remy"]["a400"] = { hit_type = {3}}                              --MK
frame_data_meta["remy"]["a6c0"] = { hit_type = {3}}                              --HK
-- frame_data_meta["remy"]["a7d0"] = { hit_type = {2}}                              --d_LP
-- frame_data_meta["remy"]["a900"] = { hit_type = {2}}                              --d_MP
-- frame_data_meta["remy"]["aa00"] = { hit_type = {2, 2}}                           --d_HP
frame_data_meta["remy"]["ab20"] = { hit_type = {2}}                              --d_LK
frame_data_meta["remy"]["abf0"] = { hit_type = {2}}                              --d_MK
frame_data_meta["remy"]["acc0"] = { hit_type = {2, 2}}                           --d_HK
-- frame_data_meta["remy"]["9d00"] = { hit_type = {3}}                              --cl_LP
frame_data_meta["remy"]["9e50"] = { hit_type = {3}}                              --cl_MP
frame_data_meta["remy"]["9ff0"] = { hit_type = {3}}                              --cl_HP
-- frame_data_meta["remy"]["a1f0"] = { hit_type = {3}}                              --cl_LK
frame_data_meta["remy"]["a330"] = { hit_type = {3}}                              --cl_MK
frame_data_meta["remy"]["a5b0"] = { hit_type = {3, 3}}                           --cl_HK
frame_data_meta["remy"]["a4b0"] = { hit_type = {4}}                              --f_MK
frame_data_meta["remy"]["af40"] = { hit_type = {4}}                             --u_LP
frame_data_meta["remy"]["b040"] = { hit_type = {4}}                             --u_MP
frame_data_meta["remy"]["b140"] = { hit_type = {4}}                             --u_HP
frame_data_meta["remy"]["b270"] = { hit_type = {4}}                             --u_LK
frame_data_meta["remy"]["b370"] = { hit_type = {4}}                             --u_MK
frame_data_meta["remy"]["b450"] = { hit_type = {4}}                             --u_HK
frame_data_meta["remy"]["bbf0"] = { hit_type = {3, 3}}                           --tc_1_ext
frame_data_meta["remy"]["b860"] = { throw = true}                                --throw_neutral
frame_data_meta["remy"]["b940"] = { throw = true}                                --throw_forward
frame_data_meta["remy"]["b9b0"] = { throw = true}                                --throw_back
-- frame_data_meta["remy"]["ba20"] = { throw = true}                                --throw_neutral
frame_data_meta["remy"]["ff48"] = { hit_type = {4}}                              --uoh

frame_data_meta["remy"]["09f8"] = { hit_type = {3}}                              --cold_blue_kick_LK
frame_data_meta["remy"]["0af8"] = { hit_type = {3}}                              --cold_blue_kick_MK
frame_data_meta["remy"]["0c08"] = { hit_type = {3}}                              --cold_blue_kick_HK
frame_data_meta["remy"]["0d18"] = { hit_type = {3}}                              --cold_blue_kick_EXK
-- frame_data_meta["remy"]["f908"] = { hit_type = {3}}                              --rising_rage_flash_LK
-- frame_data_meta["remy"]["faa8"] = { hit_type = {3, 3}}                           --rising_rage_flash_MK
-- frame_data_meta["remy"]["fc28"] = { hit_type = {3, 3}}                           --rising_rage_flash_HK
-- frame_data_meta["remy"]["fe08"] = { hit_type = {3, 3}}                           --rising_rage_flash_EXK
-- frame_data_meta["remy"]["25f0"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3}}   --supreme_rising_rage
frame_data_meta["remy"]["1150"] = { hit_type = {3, 3, 3}}                        --blue_nocturne
frame_data_meta["remy"]["16a0"] = { hit_type = {3}}                              --blue_nocturne_ext

--ryu
-- frame_data_meta["ryu"]["1794"] = { hit_type = {3}}                               --LP
frame_data_meta["ryu"]["18e4"] = { hit_type = {3}}                               --MP
frame_data_meta["ryu"]["1b44"] = { hit_type = {3}}                               --HP
-- frame_data_meta["ryu"]["1d84"] = { hit_type = {3}}                               --LK
frame_data_meta["ryu"]["1eb4"] = { hit_type = {3}}                               --MK
frame_data_meta["ryu"]["1f94"] = { hit_type = {3}}                               --HK
-- frame_data_meta["ryu"]["20c4"] = { hit_type = {2}}                               --d_LP
-- frame_data_meta["ryu"]["2174"] = { hit_type = {2}}                               --d_MP
-- frame_data_meta["ryu"]["2224"] = { hit_type = {2}}                               --d_HP
frame_data_meta["ryu"]["2304"] = { hit_type = {2}}                               --d_LK
frame_data_meta["ryu"]["23a4"] = { hit_type = {2}}                               --d_MK
frame_data_meta["ryu"]["2474"] = { hit_type = {2}}                               --d_HK
-- frame_data_meta["ryu"]["1704"] = { hit_type = {3}}                               --cl_LP
frame_data_meta["ryu"]["1844"] = { hit_type = {3}}                               --cl_MP
frame_data_meta["ryu"]["1a54"] = { hit_type = {3}}                               --cl_HP
frame_data_meta["ryu"]["1e04"] = { hit_type = {3}}                               --cl_MK
frame_data_meta["ryu"]["1984"] = { hit_type = {4, 4}}                            --f_MP
frame_data_meta["ryu"]["1c34"] = { hit_type = {3, 3}}                            --f_HP
frame_data_meta["ryu"]["2564"] = { hit_type = {4}}                             --u_LP
frame_data_meta["ryu"]["2644"] = { hit_type = {4}}                             --u_MP
frame_data_meta["ryu"]["2724"] = { hit_type = {4}}                             --u_HP
frame_data_meta["ryu"]["27e4"] = { hit_type = {4}}                             --u_LK
frame_data_meta["ryu"]["28f4"] = { hit_type = {4}}                             --u_MK
frame_data_meta["ryu"]["29c4"] = { hit_type = {4}}                             --u_HK
frame_data_meta["ryu"]["2aa4"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["ryu"]["2b84"] = { hit_type = {4, 4}}                            --uf_MP
frame_data_meta["ryu"]["2c84"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["ryu"]["2d64"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["ryu"]["2e44"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["ryu"]["2f24"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["ryu"]["33fc"] = { hit_type = {3, 3}}                            --tc_1_ext
frame_data_meta["ryu"]["3324"] = { throw = true}                                 --throw_neutral
frame_data_meta["ryu"]["80dc"] = { hit_type = {4}}                               --uoh
frame_data_meta["ryu"]["81dc"] = { hit_type = {3}}                               --joudan_LK
frame_data_meta["ryu"]["8354"] = { hit_type = {3}}                               --joudan_MK
frame_data_meta["ryu"]["84fc"] = { hit_type = {3}}                               --joudan_HK
frame_data_meta["ryu"]["86bc"] = { hit_type = {3}}                               --joudan_EXK
-- frame_data_meta["ryu"]["6d44"] = { hit_type = {3}}                               --shoryuken_LP
-- frame_data_meta["ryu"]["6e44"] = { hit_type = {3}}                               --shoryuken_MP
-- frame_data_meta["ryu"]["6ee4"] = { hit_type = {3}}                               --shoryuken_HP
-- frame_data_meta["ryu"]["6f84"] = { hit_type = {3, 3}}                            --shoryuken_EXP
frame_data_meta["ryu"]["7034"] = { hit_type = {3}}                               --tatsumaki_LK
frame_data_meta["ryu"]["7124"] = { hit_type = {3, 3, 3, 3, 3}}                   --tatsumaki_MK
frame_data_meta["ryu"]["72b4"] = { hit_type = {3, 3, 3, 3, 3}}                   --tatsumaki_HK
frame_data_meta["ryu"]["7444"] = { hit_type = {3, 3, 3, 3, 3, 3}}                --tatsumaki_EXK
frame_data_meta["ryu"]["7cbc"] = { hit_type = {3, 3, 3, 3}}                      --tatsumaki_air_LK
frame_data_meta["ryu"]["7dfc"] = { hit_type = {3, 3, 3, 3, 3, 3}}                --tatsumaki_air_MK
frame_data_meta["ryu"]["7edc"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}          --tatsumaki_air_HK
frame_data_meta["ryu"]["7fbc"] = { hit_type = {3, 3, 3, 3, 3, 3}}                --tatsumaki_air_EXK
-- frame_data_meta["ryu"]["894c"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}             --shin_shoryuken

--sean
-- frame_data_meta["sean"]["be7c"] = { hit_type = {3}}                              --LP
frame_data_meta["sean"]["bfcc"] = { hit_type = {3}}                              --MP
frame_data_meta["sean"]["c14c"] = { hit_type = {3}}                              --HP
-- frame_data_meta["sean"]["c3cc"] = { hit_type = {3}}                              --LK
-- frame_data_meta["sean"]["c44c"] = { hit_type = {3}}                              --MK
frame_data_meta["sean"]["c5dc"] = { hit_type = {3}}                              --HK
-- frame_data_meta["sean"]["c7ec"] = { hit_type = {2}}                              --d_LP
-- frame_data_meta["sean"]["c89c"] = { hit_type = {2}}                              --d_MP
-- frame_data_meta["sean"]["c94c"] = { hit_type = {2}}                              --d_HP
frame_data_meta["sean"]["ca3c"] = { hit_type = {2}}                              --d_LK
frame_data_meta["sean"]["cadc"] = { hit_type = {2}}                              --d_MK
frame_data_meta["sean"]["cbac"] = { hit_type = {2}}                              --d_HK
frame_data_meta["sean"]["bf1c"] = { hit_type = {3}}                              --cl_MP
frame_data_meta["sean"]["c06c"] = { hit_type = {3}}                              --cl_HP
frame_data_meta["sean"]["c50c"] = { hit_type = {3}}                              --cl_HK
frame_data_meta["sean"]["c25c"] = { hit_type = {4, 4}}                           --f_HP
frame_data_meta["sean"]["c6ec"] = { hit_type = {3}}                              --f_HK
frame_data_meta["sean"]["cc9c"] = { hit_type = {4}}                             --u_LP
frame_data_meta["sean"]["cd7c"] = { hit_type = {4}}                             --u_MP
frame_data_meta["sean"]["ce5c"] = { hit_type = {4}}                             --u_HP
frame_data_meta["sean"]["cf1c"] = { hit_type = {4}}                             --u_LK
frame_data_meta["sean"]["d02c"] = { hit_type = {4}}                             --u_MK
frame_data_meta["sean"]["d0fc"] = { hit_type = {4}}                             --u_HK
frame_data_meta["sean"]["d1dc"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["sean"]["d2bc"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["sean"]["d39c"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["sean"]["d47c"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["sean"]["d55c"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["sean"]["d63c"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["sean"]["dad4"] = { hit_type = {3}}                              --tc_1_ext
frame_data_meta["sean"]["dc7c"] = { hit_type = {4, 4}}                           --tc_2_ext
frame_data_meta["sean"]["d9ec"] = { throw = true}                               --throw_neutral
frame_data_meta["sean"]["3e50"] = { hit_type = {4}}                              --uoh
frame_data_meta["sean"]["28c0"] = { hit_type = {4}}                              --ryuubikyaku
frame_data_meta["sean"]["2a10"] = { hit_type = {4, 4, 4, 4}}                     --ryuubikyakuEXK
frame_data_meta["sean"]["2310"] = { hit_type = {3, 3}}                           --tornado_LK
frame_data_meta["sean"]["2470"] = { hit_type = {3, 3, 3}}                        --tornado_MK
frame_data_meta["sean"]["25b0"] = { hit_type = {3, 3, 3, 3}}                     --tornado_HK
frame_data_meta["sean"]["2740"] = { hit_type = {3, 3, 3, 3}}                     --tornado_EXK
frame_data_meta["sean"]["1ef0"] = { hit_type = {2}, hit_throw = true}                              --sean_tackle_LP
frame_data_meta["sean"]["2060"] = { hit_type = {2}, hit_throw = true}                              --sean_tackle_MP
frame_data_meta["sean"]["2130"] = { hit_type = {2}, hit_throw = true}                              --sean_tackle_HP
frame_data_meta["sean"]["2200"] = { hit_type = {2}, hit_throw = true}                              --sean_tackle_EXP
-- frame_data_meta["sean"]["3f30"] = { hit_type = {3}}                              --dragon_smash_LP
-- frame_data_meta["sean"]["4000"] = { hit_type = {3}}                              --dragon_smash_MP
-- frame_data_meta["sean"]["40e0"] = { hit_type = {3}}                              --dragon_smash_HP
-- frame_data_meta["sean"]["41e0"] = { hit_type = {3, 3}}                           --dragon_smash_EXP
-- frame_data_meta["sean"]["34e0"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --shoryu_cannon
frame_data_meta["sean"]["2dc8"] = { hit_type = {2, 2}}                           --hyper_tornado

--shingouki
-- frame_data_meta["shingouki"]["4684"] = { hit_type = {3}}                         --LP
frame_data_meta["shingouki"]["47b4"] = { hit_type = {3}}                         --MP
frame_data_meta["shingouki"]["4a24"] = { hit_type = {3}}                         --HP
-- frame_data_meta["shingouki"]["4b14"] = { hit_type = {3}}                         --LK
frame_data_meta["shingouki"]["4c54"] = { hit_type = {3}}                         --MK
frame_data_meta["shingouki"]["4d44"] = { hit_type = {3}}                         --HK
-- frame_data_meta["shingouki"]["4e74"] = { hit_type = {2}}                         --d_LP
-- frame_data_meta["shingouki"]["4ef4"] = { hit_type = {2}}                         --d_MP
-- frame_data_meta["shingouki"]["4f94"] = { hit_type = {2}}                         --d_HP
frame_data_meta["shingouki"]["5054"] = { hit_type = {2}}                         --d_LK
frame_data_meta["shingouki"]["5114"] = { hit_type = {2}}                         --d_MK
frame_data_meta["shingouki"]["52a4"] = { hit_type = {2}}                         --d_HK
-- frame_data_meta["shingouki"]["4614"] = { hit_type = {3}}                         --cl_LP
frame_data_meta["shingouki"]["4704"] = { hit_type = {3}}                         --cl_MP
frame_data_meta["shingouki"]["4954"] = { hit_type = {3}}                         --cl_HP
frame_data_meta["shingouki"]["4ba4"] = { hit_type = {3}}                         --cl_MK
frame_data_meta["shingouki"]["4864"] = { hit_type = {4, 4}}                      --f_MP
frame_data_meta["shingouki"]["541c"] = { hit_type = {4}}                             --u_LP
frame_data_meta["shingouki"]["5594"] = { hit_type = {4}}                             --u_MP
frame_data_meta["shingouki"]["573c"] = { hit_type = {4}}                             --u_HP
frame_data_meta["shingouki"]["58e4"] = { hit_type = {4}}                             --u_LK
frame_data_meta["shingouki"]["5a74"] = { hit_type = {4}}                             --u_MK
frame_data_meta["shingouki"]["5bec"] = { hit_type = {4}}                             --u_HK
frame_data_meta["shingouki"]["5d34"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["shingouki"]["5ec4"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["shingouki"]["600c"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["shingouki"]["6154"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["shingouki"]["6304"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["shingouki"]["6284"] = { hit_type = {4}}                         --d_MK_air
frame_data_meta["shingouki"]["7314"] = { hit_type = {3, 3}}                      --tc_1_ext
frame_data_meta["shingouki"]["6fa4"] = { throw = true}                           --throw_neutral
frame_data_meta["shingouki"]["d628"] = { hit_type = {4}}                         --uoh
frame_data_meta["shingouki"]["ca60"] = { hit_type = {3}}                         --parry_air
frame_data_meta["shingouki"]["d958"] = { throw = true}                           --sgs
frame_data_meta["shingouki"]["bcf0"] = { hit_type = {3, 3, 3}}                   --tatsumaki_LK
frame_data_meta["shingouki"]["be68"] = { hit_type = {3, 3, 3, 3, 3}}             --tatsumaki_MK
frame_data_meta["shingouki"]["c070"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}} --tatsumaki_HK
-- frame_data_meta["shingouki"]["b918"] = { hit_type = {3}}                         --goshoryuken_LP
-- frame_data_meta["shingouki"]["ba48"] = { hit_type = {3, 3}}                      --goshoryuken_MP
-- frame_data_meta["shingouki"]["bba8"] = { hit_type = {3, 3, 3}}                   --goshoryuken_HP
frame_data_meta["shingouki"]["d348"] = { hit_type = {3, 3}}                      --tatsumaki_air_LK
frame_data_meta["shingouki"]["d468"] = { hit_type = {3, 3, 3, 3}}                --tatsumaki_air_MK
frame_data_meta["shingouki"]["d548"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}    --tatsumaki_air_HK
-- frame_data_meta["shingouki"]["c6c8"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}    --messatsu_goushoryu
-- frame_data_meta["shingouki"]["ca80"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --messatsu_gourasen

--twelve
-- frame_data_meta["twelve"]["32c4"] = { hit_type = {3}}                            --LP
frame_data_meta["twelve"]["3484"] = { hit_type = {3}}                            --MP
frame_data_meta["twelve"]["3584"] = { hit_type = {3}}                            --HP
-- frame_data_meta["twelve"]["3714"] = { hit_type = {3}}                            --LK
frame_data_meta["twelve"]["37e4"] = { hit_type = {3}}                            --MK
frame_data_meta["twelve"]["3a64"] = { hit_type = {3}}                            --HK
-- frame_data_meta["twelve"]["3c84"] = { hit_type = {2}}                            --d_LP
-- frame_data_meta["twelve"]["3d14"] = { hit_type = {2}}                            --d_MP
-- frame_data_meta["twelve"]["3e84"] = { hit_type = {2, 2}}                         --d_HP
frame_data_meta["twelve"]["462c"] = { hit_type = {2}}                            --d_LK
frame_data_meta["twelve"]["46fc"] = { hit_type = {2}}                            --d_MK
frame_data_meta["twelve"]["480c"] = { hit_type = {2, 2, 2}}                      --d_HK
frame_data_meta["twelve"]["3394"] = { hit_type = {3}}                            --cl_MP
-- frame_data_meta["twelve"]["3934"] = { hit_type = {3, 3}}                         --b_MK
frame_data_meta["twelve"]["4a2c"] = { hit_type = {4}}                             --u_LP
frame_data_meta["twelve"]["4aec"] = { hit_type = {4}}                             --u_MP
frame_data_meta["twelve"]["4bac"] = { hit_type = {4}}                             --u_HP
frame_data_meta["twelve"]["4ccc"] = { hit_type = {4}}                             --u_LK
frame_data_meta["twelve"]["4d9c"] = { hit_type = {4}}                             --u_MK
frame_data_meta["twelve"]["4e9c"] = { hit_type = {4}}                             --u_HK
frame_data_meta["twelve"]["4f8c"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["twelve"]["504c"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["twelve"]["510c"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["twelve"]["522c"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["twelve"]["52fc"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["twelve"]["53fc"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["twelve"]["5a6c"] = { hit_type = {4}}                             --air_dash_LP
frame_data_meta["twelve"]["5b2c"] = { hit_type = {4}}                             --air_dash_MP
frame_data_meta["twelve"]["5bec"] = { hit_type = {4}}                             --air_dash_HP
frame_data_meta["twelve"]["5d0c"] = { hit_type = {4}}                             --air_dash_LK
frame_data_meta["twelve"]["5ddc"] = { hit_type = {4}}                             --air_dash_MK
frame_data_meta["twelve"]["5edc"] = { hit_type = {4}}                             --air_dash_HK
frame_data_meta["twelve"]["58dc"] = { throw = true}                              --throw_neutral
frame_data_meta["twelve"]["e1b4"] = { hit_type = {4}}                            --uoh
frame_data_meta["twelve"]["b574"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3}}       --axe_LP
frame_data_meta["twelve"]["b9c4"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}    --axe_MP
frame_data_meta["twelve"]["bd94"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}} --axe_HP
frame_data_meta["twelve"]["c174"] = { hit_type = {3, 3, 3, 3, 3, 3}}             --axe_EXP
frame_data_meta["twelve"]["a9dc"] = { hit_type = {4}}                            --dra_LK
frame_data_meta["twelve"]["b1f4"] = { hit_type = {4}}                            --dra_EXK
frame_data_meta["twelve"]["af94"] = { hit_type = {4}}                            --dra_HK_ext
frame_data_meta["twelve"]["ad34"] = { hit_type = {4}}                            --dra_MK_ext
frame_data_meta["twelve"]["cd94"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}    --axe_air_LP
frame_data_meta["twelve"]["d114"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}    --axe_air_MP
frame_data_meta["twelve"]["d494"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}    --axe_air_HP
frame_data_meta["twelve"]["d814"] = { hit_type = {3, 3, 3, 3, 3, 3, 3, 3, 3}}    --axe_air_EXP
frame_data_meta["twelve"]["ed84"] = { hit_type = {3}}                            --xflat

--urien
-- frame_data_meta["urien"]["d774"] = { hit_type = {3}}                             --LP
frame_data_meta["urien"]["d864"] = { hit_type = {3}}                             --MP
frame_data_meta["urien"]["daa4"] = { hit_type = {3}}                             --HP
-- frame_data_meta["urien"]["dcfc"] = { hit_type = {3}}                             --LK
frame_data_meta["urien"]["ddac"] = { hit_type = {3}}                             --MK
frame_data_meta["urien"]["e0b4"] = { hit_type = {4, 4}}                          --HK
-- frame_data_meta["urien"]["e4ac"] = { hit_type = {2}}                             --d_LP
-- frame_data_meta["urien"]["e65c"] = { hit_type = {2}}                             --d_MP
-- frame_data_meta["urien"]["e72c"] = { hit_type = {2, 2}}                          --d_HP
frame_data_meta["urien"]["eaf4"] = { hit_type = {2}}                             --d_LK
frame_data_meta["urien"]["ebc4"] = { hit_type = {2}}                             --d_MK
frame_data_meta["urien"]["ec84"] = { hit_type = {2}}                             --d_HK
frame_data_meta["urien"]["d994"] = { hit_type = {3}}                             --f_MP
frame_data_meta["urien"]["dc1c"] = { hit_type = {4}}                             --f_HP
frame_data_meta["urien"]["df0c"] = { hit_type = {3}}                             --f_MK
frame_data_meta["urien"]["ee14"] = { hit_type = {4}}                             --u_LP
frame_data_meta["urien"]["eeb4"] = { hit_type = {4}}                             --u_MP
frame_data_meta["urien"]["ef94"] = { hit_type = {4}}                             --u_HP
frame_data_meta["urien"]["f074"] = { hit_type = {4}}                             --u_LK
frame_data_meta["urien"]["f114"] = { hit_type = {4}}                             --u_MK
frame_data_meta["urien"]["f1f4"] = { hit_type = {4}}                             --u_HK
frame_data_meta["urien"]["fa84"] = { hit_type = {3}}                             --tc_1_ext
frame_data_meta["urien"]["fbb4"] = { hit_type = {4}}                             --tc_2_ext
frame_data_meta["urien"]["f764"] = { throw = true}                               --throw_neutral
frame_data_meta["urien"]["6784"] = { hit_type = {4}}                             --uoh
frame_data_meta["urien"]["6aac"] = { hit_type = {2}}                             --pa
frame_data_meta["urien"]["6c1c"] = { hit_type = {3}}                             --chariot_tackle_LK
frame_data_meta["urien"]["6dfc"] = { hit_type = {3}}                             --chariot_tackle_MK
frame_data_meta["urien"]["6fec"] = { hit_type = {3}}                             --chariot_tackle_HK
frame_data_meta["urien"]["720c"] = { hit_type = {3, 3}}                          --chariot_tackle_EXK
frame_data_meta["urien"]["4cbc"] = { hit_type = {4}}                             --violence_kneedrop_LK
frame_data_meta["urien"]["4e4c"] = { hit_type = {4}}                             --violence_kneedrop_MK
frame_data_meta["urien"]["4fdc"] = { hit_type = {4}}                             --violence_kneedrop_HK
frame_data_meta["urien"]["516c"] = { hit_type = {4, 4}}                          --violence_kneedrop_EXK
frame_data_meta["urien"]["6254"] = { hit_type = {3}}                             --dangerous_headbutt_LP
frame_data_meta["urien"]["6314"] = { hit_type = {3}}                             --dangerous_headbutt_MP
frame_data_meta["urien"]["63d4"] = { hit_type = {3}}                             --dangerous_headbutt_HP
frame_data_meta["urien"]["6494"] = { hit_type = {3, 3}}                          --dangerous_headbutt_EXP
frame_data_meta["urien"]["79dc"] = { hit_type = {3, 3, 3, 3, 3, 3}}              --tyrant_slaughter

--yang
-- frame_data_meta["yang"]["c114"] = { hit_type = {3}}                              --LP
frame_data_meta["yang"]["c2d4"] = { hit_type = {3}}                              --MP
frame_data_meta["yang"]["c4c4"] = { hit_type = {3}}                              --HP
-- frame_data_meta["yang"]["c66c"] = { hit_type = {3}}                              --LK
frame_data_meta["yang"]["c89c"] = { hit_type = {3}}                              --MK
frame_data_meta["yang"]["ce54"] = { hit_type = {3}}                              --HK
-- frame_data_meta["yang"]["d044"] = { hit_type = {2}}                              --d_LP
frame_data_meta["yang"]["d1c4"] = { hit_type = {2}}                              --d_MP
-- frame_data_meta["yang"]["d2b4"] = { hit_type = {2, 2}}                           --d_HP
frame_data_meta["yang"]["d45c"] = { hit_type = {2}}                              --d_LK
frame_data_meta["yang"]["d52c"] = { hit_type = {2}}                              --d_MK
frame_data_meta["yang"]["d6a4"] = { hit_type = {2}}                              --d_HK
frame_data_meta["yang"]["c224"] = { hit_type = {3}}                              --cl_MP
frame_data_meta["yang"]["c3a4"] = { hit_type = {3, 3}}                           --cl_HP
frame_data_meta["yang"]["c79c"] = { hit_type = {3, 3}}                           --cl_MK
frame_data_meta["yang"]["caa4"] = { hit_type = {4}}                              --f_MK
frame_data_meta["yang"]["d8ac"] = { hit_type = {4}}                             --u_LP
frame_data_meta["yang"]["d99c"] = { hit_type = {4}}                             --u_MP
frame_data_meta["yang"]["da8c"] = { hit_type = {4}}                             --u_HP
frame_data_meta["yang"]["dbfc"] = { hit_type = {4}}                             --u_LK
frame_data_meta["yang"]["dd3c"] = { hit_type = {4}}                             --u_MK
frame_data_meta["yang"]["de8c"] = { hit_type = {4}}                             --u_HK
frame_data_meta["yang"]["df8c"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["yang"]["e08c"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["yang"]["e17c"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["yang"]["e25c"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["yang"]["e44c"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["yang"]["e65c"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["yang"]["f0fc"] = { hit_type = {3, 3}}                           --tc_1
frame_data_meta["yang"]["ef0c"] = { hit_type = {3}}                              --tc_1_ext
frame_data_meta["yang"]["f50c"] = { hit_type = {3}}                              --tc_3
frame_data_meta["yang"]["f334"] = { hit_type = {3}}                              --tc_3_ext
frame_data_meta["yang"]["ed34"] = { hit_type = {4, 4}}                           --tc_4_ext
frame_data_meta["yang"]["1b34"] = { throw = true}                               --throw_neutral
frame_data_meta["yang"]["1c34"] = { throw = true}                               --throw_forward
frame_data_meta["yang"]["ecd4"] = { throw = true}                               --throw_back
frame_data_meta["yang"]["dd18"] = { hit_type = {4}}                              --uoh
-- frame_data_meta["yang"]["e288"] = { hit_type = {3}}                              --pa
frame_data_meta["yang"]["94d8"] = { hit_type = {3}}                              --byakko
frame_data_meta["yang"]["c830"] = { throw = true}                                --zenpou
frame_data_meta["yang"]["e39c"] = { hit_type = {4}}                              --raigeki_LK
frame_data_meta["yang"]["e5ac"] = { hit_type = {4}}                              --raigeki_MK
frame_data_meta["yang"]["e75c"] = { hit_type = {4}}                              --raigeki_HK
frame_data_meta["yang"]["a498"] = { hit_type = {3, 3, 3}}                        --tourouzan_LP
frame_data_meta["yang"]["aa18"] = { hit_type = {3, 3, 3}}                        --tourouzan_MP
frame_data_meta["yang"]["af98"] = { hit_type = {3, 3, 3}}                        --tourouzan_HP
frame_data_meta["yang"]["b518"] = { hit_type = {3, 3, 3, 3, 3}}                  --tourouzan_EXP
-- frame_data_meta["yang"]["9870"] = { hit_type = {3, 3}}                           --senkyuutai_LK
-- frame_data_meta["yang"]["9a30"] = { hit_type = {3, 3}}                           --senkyuutai_MK
-- frame_data_meta["yang"]["9cc8"] = { hit_type = {3, 3}}                           --senkyuutai_HK
-- frame_data_meta["yang"]["a0b0"] = { hit_type = {3, 3, 3}}                        --senkyuutai_EXK
frame_data_meta["yang"]["f0a0"] = { hit_type = {3}}                              --raishin
-- frame_data_meta["yang"]["c0d8"] = { hit_type = {3}}                              --tenshinsenkyuutai
-- frame_data_meta["yang"]["df28"] = { hit_type = {3, 3, 3, 3, 3, 3, 3}}            --tenshinsenkyuutai_ext

--yun
-- frame_data_meta["yun"]["a2dc"] = { hit_type = {3}}                               --LP
frame_data_meta["yun"]["415c"] = { hit_type = {3}}                               --MP
frame_data_meta["yun"]["447c"] = { hit_type = {3}}                               --HP
-- frame_data_meta["yun"]["48bc"] = { hit_type = {3}}                               --LK
frame_data_meta["yun"]["4b24"] = { hit_type = {3}}                               --MK
frame_data_meta["yun"]["4ed4"] = { hit_type = {3}}                               --HK
-- frame_data_meta["yun"]["510c"] = { hit_type = {2}}                               --d_LP
-- frame_data_meta["yun"]["51dc"] = { hit_type = {2}}                               --d_MP
-- frame_data_meta["yun"]["529c"] = { hit_type = {2, 2}}                            --d_HP
frame_data_meta["yun"]["53bc"] = { hit_type = {2}}                               --d_LK
frame_data_meta["yun"]["548c"] = { hit_type = {2}}                               --d_MK
frame_data_meta["yun"]["a014"] = { hit_type = {2}}                               --d_HK
-- frame_data_meta["yun"]["a1ec"] = { hit_type = {3}}                               --cl_LP
frame_data_meta["yun"]["402c"] = { hit_type = {3}}                               --cl_MP
frame_data_meta["yun"]["42a4"] = { hit_type = {3, 3}}                            --cl_HP
frame_data_meta["yun"]["4a04"] = { hit_type = {3}}                               --cl_MK
frame_data_meta["yun"]["4654"] = { hit_type = {3}}                               --f_HP
frame_data_meta["yun"]["4d2c"] = { hit_type = {4}}                               --f_MK
frame_data_meta["yun"]["580c"] = { hit_type = {4}}                             --u_LP
frame_data_meta["yun"]["590c"] = { hit_type = {4}}                             --u_MP
frame_data_meta["yun"]["59fc"] = { hit_type = {4}}                             --u_HP
frame_data_meta["yun"]["5b6c"] = { hit_type = {4}}                             --u_LK
frame_data_meta["yun"]["5cac"] = { hit_type = {4}}                             --u_MK
frame_data_meta["yun"]["5dfc"] = { hit_type = {4}}                             --u_HK
frame_data_meta["yun"]["5efc"] = { hit_type = {4}}                             --uf_LP
frame_data_meta["yun"]["5ffc"] = { hit_type = {4}}                             --uf_MP
frame_data_meta["yun"]["60ec"] = { hit_type = {4}}                             --uf_HP
frame_data_meta["yun"]["61cc"] = { hit_type = {4}}                             --uf_LK
frame_data_meta["yun"]["63bc"] = { hit_type = {4}}                             --uf_MK
frame_data_meta["yun"]["65bc"] = { hit_type = {4}}                             --uf_HK
frame_data_meta["yun"]["75a4"] = { hit_type = {3}}                               --tc_1
frame_data_meta["yun"]["6e14"] = { hit_type = {3, 3}}                            --tc_2
frame_data_meta["yun"]["748c"] = { hit_type = {1, 1}}                            --tc_1_ext
frame_data_meta["yun"]["6c24"] = { hit_type = {3}}                               --tc_2_ext
frame_data_meta["yun"]["76a4"] = { hit_type = {3, 3}}                            --tc_4_ext
frame_data_meta["yun"]["9d14"] = { hit_type = {3}}                               --tc_5_ext
frame_data_meta["yun"]["6b14"] = { hit_type = {3, 3}}                            --tc_6_ext
frame_data_meta["yun"]["9f04"] = { hit_type = {3, 3}}                            --tc_6_ext
frame_data_meta["yun"]["a50c"] = { throw = true}                                --throw_neutral
frame_data_meta["yun"]["a60c"] = { throw = true}                                --throw_forward
frame_data_meta["yun"]["a66c"] = { throw = true}                                --throw_back
frame_data_meta["yun"]["5e50"] = { hit_type = {4}}                               --uoh
frame_data_meta["yun"]["62f0"] = { hit_type = {4}}                               --uoh_geneijin
-- frame_data_meta["yun"]["63d0"] = { hit_type = {3, 3, 3, 3}}                      --pa
frame_data_meta["yun"]["8564"] = { hit_type = {3}}                               --HK_geneijin
frame_data_meta["yun"]["7bbc"] = { hit_type = {3}}                               --HP_geneijin
-- frame_data_meta["yun"]["7f9c"] = { hit_type = {3}}                               --LK_geneijin
-- frame_data_meta["yun"]["a45c"] = { hit_type = {3}}                               --LP_geneijin
frame_data_meta["yun"]["81fc"] = { hit_type = {3}}                               --MK_geneijin
frame_data_meta["yun"]["78b4"] = { hit_type = {3}}                               --MP_geneijin
frame_data_meta["yun"]["1e28"] = { hit_type = {3}}                               --kobokushi
frame_data_meta["yun"]["4f80"] = { throw = true}                                 --zenpou
frame_data_meta["yun"]["8ae4"] = { hit_type = {2}}                               --d_HK_geneijin
-- frame_data_meta["yun"]["8854"] = { hit_type = {2, 2}}                            --d_HP_geneijin
frame_data_meta["yun"]["8964"] = { hit_type = {2}}                               --d_LK_geneijin
-- frame_data_meta["yun"]["8724"] = { hit_type = {2}}                               --d_LP_geneijin
frame_data_meta["yun"]["8a04"] = { hit_type = {2}}                               --d_MK_geneijin
-- frame_data_meta["yun"]["87b4"] = { hit_type = {2}}                               --d_MP_geneijin
frame_data_meta["yun"]["7d64"] = { hit_type = {3}}                               --f_HP_geneijin
frame_data_meta["yun"]["83ec"] = { hit_type = {4}}                               --f_MK_geneijin
frame_data_meta["yun"]["920c"] = { hit_type = {4}}                             --u_HK_geneijin
frame_data_meta["yun"]["8e4c"] = { hit_type = {4}}                             --u_HP_geneijin
frame_data_meta["yun"]["8f9c"] = { hit_type = {4}}                             --u_LK_geneijin
frame_data_meta["yun"]["8c8c"] = { hit_type = {4}}                             --u_LP_geneijin
frame_data_meta["yun"]["976c"] = { hit_type = {4}}                             --u_MK_geneijin
frame_data_meta["yun"]["8d6c"] = { hit_type = {4}}                             --u_MP_geneijin
frame_data_meta["yun"]["7a2c"] = { hit_type = {3, 3}}                            --cl_HP_geneijin
-- frame_data_meta["yun"]["a3dc"] = { hit_type = {3}}                               --cl_LP_geneijin
frame_data_meta["yun"]["80b4"] = { hit_type = {3}}                               --cl_MK_geneijin
frame_data_meta["yun"]["77b4"] = { hit_type = {3}}                               --cl_MP_geneijin
frame_data_meta["yun"]["994c"] = { hit_type = {4}}                             --uf_HK_geneijin
frame_data_meta["yun"]["94cc"] = { hit_type = {4}}                             --uf_HP_geneijin
frame_data_meta["yun"]["959c"] = { hit_type = {4}}                             --uf_LK_geneijin
frame_data_meta["yun"]["92fc"] = { hit_type = {4}}                             --uf_LP_geneijin
frame_data_meta["yun"]["93ec"] = { hit_type = {4}}                             --uf_MP_geneijin
frame_data_meta["yun"]["5f40"] = { throw = true}                                 --zenpou_geneijin
frame_data_meta["yun"]["630c"] = { hit_type = {4}}                               --raigeki_LK
frame_data_meta["yun"]["650c"] = { hit_type = {4}}                               --raigeki_MK
frame_data_meta["yun"]["66bc"] = { hit_type = {4}}                               --raigeki_HK
frame_data_meta["yun"]["3620"] = { hit_type = {3}}                               --zesshou_LP
frame_data_meta["yun"]["3840"] = { hit_type = {3}}                               --zesshou_MP
frame_data_meta["yun"]["3a60"] = { hit_type = {3}}                               --zesshou_HP
frame_data_meta["yun"]["3c98"] = { hit_type = {3, 3}}                            --zesshou_EXP
frame_data_meta["yun"]["5c30"] = { hit_type = {3, 3, 3}}                         --zesshou_geneijin
-- frame_data_meta["yun"]["6810"] = { hit_type = {3}}                               --tetsuzan_LP
-- frame_data_meta["yun"]["6a78"] = { hit_type = {3}}                               --tetsuzan_MP
-- frame_data_meta["yun"]["6ce0"] = { hit_type = {3}}                               --tetsuzan_HP
-- frame_data_meta["yun"]["6f48"] = { hit_type = {3, 3}}                            --tetsuzan_EXP
frame_data_meta["yun"]["59f8"] = { hit_type = {3}}                               --kobokushi_geneijin
frame_data_meta["yun"]["9a3c"] = { hit_type = {4}}                               --raigeki_HK_geneijin
frame_data_meta["yun"]["96cc"] = { hit_type = {4}}                               --raigeki_LK_geneijin
frame_data_meta["yun"]["98ac"] = { hit_type = {4}}                               --raigeki_MK_geneijin
-- frame_data_meta["yun"]["7938"] = { hit_type = {3, 3}}                            --tetsuzan_HP_geneijin
-- frame_data_meta["yun"]["7468"] = { hit_type = {3, 3}}                            --tetsuzan_LP_geneijin
-- frame_data_meta["yun"]["76d0"] = { hit_type = {3, 3}}                            --tetsuzan_MP_geneijin
-- frame_data_meta["yun"]["8978"] = { hit_type = {3, 3}}                            --nishoukyaku_LK
-- frame_data_meta["yun"]["8bf8"] = { hit_type = {3, 3}}                            --nishoukyaku_MK
-- frame_data_meta["yun"]["8ea8"] = { hit_type = {3, 3}}                            --nishoukyaku_HK
-- frame_data_meta["yun"]["9158"] = { hit_type = {3, 3}}                            --nishoukyaku_EXK
-- frame_data_meta["yun"]["93d8"] = { hit_type = {3, 3}}                            --nishoukyaku_geneijin
frame_data_meta["yun"]["4390"] = { hit_type = {3}}                               --youhou
frame_data_meta["yun"]["7ba0"] = { hit_type = {3, 3, 3}}                         --youhou_ext
frame_data_meta["yun"]["48a0"] = { hit_type = {3, 3}}                            --sourairengeki
frame_data_meta["yun"]["4be0"] = { hit_type = {3, 3, 3}}                         --sourairengeki_ext

--projectiles
-- frame_data_meta["projectiles"]["00_pa_dudley"] = { hit_type = {3}}               --pa
-- frame_data_meta["projectiles"]["00_pa_sean"] = { hit_type = {3}}                 --pa
-- frame_data_meta["projectiles"]["00_kkz"] = { hit_type = {3}}                     --kkz
-- frame_data_meta["projectiles"]["00_seieienbu"] = { hit_type = {3}}               --seieienbu
-- frame_data_meta["projectiles"]["00_tenguishi"] = { hit_type = {3}}               --tenguishi
frame_data_meta["projectiles"]["24"] = { hit_type = {3}}                         --hadou_burst
frame_data_meta["projectiles"]["1C"] = { hit_type = {3}}                         --kunai_LP
frame_data_meta["projectiles"]["1D"] = { hit_type = {3}}                         --kunai_MP
frame_data_meta["projectiles"]["1E"] = { hit_type = {3}}                         --kunai_HP
frame_data_meta["projectiles"]["1F"] = { hit_type = {3}}                         --kunai_EXP
frame_data_meta["projectiles"]["3D"] = { hit_type = {3}}                         --kunai_EXP
frame_data_meta["projectiles"]["43"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["44"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["45"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["46"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["47"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["48"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["49"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["4A"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["4B"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["4C"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["4D"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["4E"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["4F"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["50"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["51"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["52"] = { hit_type = {3}}                         --meteor_strike
frame_data_meta["projectiles"]["07"] = { hit_type = {3}}                         --shinkuu_hadouken
frame_data_meta["projectiles"]["3B"] = { hit_type = {2}}                         --electric_snake
frame_data_meta["projectiles"]["00_hadouken"] = { hit_type = {3}}                --hadouken_LP
frame_data_meta["projectiles"]["18"] = { hit_type = {3}}                         --hadouken_LP
frame_data_meta["projectiles"]["01"] = { hit_type = {3}}                         --hadouken_MP
frame_data_meta["projectiles"]["19"] = { hit_type = {3}}                         --hadouken_MP
frame_data_meta["projectiles"]["02"] = { hit_type = {3}}                         --hadouken_HP
frame_data_meta["projectiles"]["1A"] = { hit_type = {3}}                         --hadouken_HP
frame_data_meta["projectiles"]["03"] = { hit_type = {3}}                         --hadouken_EXP ryu
frame_data_meta["projectiles"]["1B"] = { hit_type = {3}}                         --hadouken_EXP ken
frame_data_meta["projectiles"]["88"] = { hit_type = {3}}                         --kikouken_LP
frame_data_meta["projectiles"]["89"] = { hit_type = {3}}                         --kikouken_MP
frame_data_meta["projectiles"]["8A"] = { hit_type = {3}}                         --kikouken_HP
frame_data_meta["projectiles"]["8B"] = { hit_type = {3}}                         --kikouken_EXP
frame_data_meta["projectiles"]["0C"] = { hit_type = {3}}                         --nichirin_LP
frame_data_meta["projectiles"]["0D"] = { hit_type = {3}}                         --nichirin_MP
frame_data_meta["projectiles"]["0E"] = { hit_type = {3}}                         --nichirin_HP
frame_data_meta["projectiles"]["0F"] = { hit_type = {3}, cooldown = 1}           --nichirin_EXP
frame_data_meta["projectiles"]["00"] = { hit_type = {3}, unparryable = true}     --seraphic_wing
frame_data_meta["projectiles"]["53"] = { hit_type = {3}, cooldown = 3}           --temporal_thunder
frame_data_meta["projectiles"]["6A"] = { hit_type = {3}}                         --gohadouken_LP
frame_data_meta["projectiles"]["6B"] = { hit_type = {3}}                         --gohadouken_MP
frame_data_meta["projectiles"]["6C"] = { hit_type = {3}}                         --gohadouken_HP
frame_data_meta["projectiles"]["59"] = { hit_type = {3}}                         --shakunetsu_LP
frame_data_meta["projectiles"]["5A"] = { hit_type = {3}, cooldown = 1}           --shakunetsu_MP
frame_data_meta["projectiles"]["5B"] = { hit_type = {3}, cooldown = 1}           --shakunetsu_HP
frame_data_meta["projectiles"]["14"] = { hit_type = {1}, cooldown = 3}           --yagyoudama_LP
frame_data_meta["projectiles"]["15"] = { hit_type = {1}, cooldown = 3}           --yagyoudama_MP
frame_data_meta["projectiles"]["16"] = { hit_type = {1}, cooldown = 3}           --yagyoudama_HP
frame_data_meta["projectiles"]["72"] = { hit_type = {1}}                         --yagyoudama_EXP
frame_data_meta["projectiles"]["37"] = { hit_type = {3}}                         --pyrokinesis_LP
frame_data_meta["projectiles"]["38"] = { hit_type = {3}}                         --pyrokinesis_MP
frame_data_meta["projectiles"]["39"] = { hit_type = {3}}                         --pyrokinesis_HP
frame_data_meta["projectiles"]["25"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_LP
frame_data_meta["projectiles"]["26"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_LP
frame_data_meta["projectiles"]["27"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_LP
frame_data_meta["projectiles"]["28"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_LP
frame_data_meta["projectiles"]["29"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_LP
frame_data_meta["projectiles"]["2A"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_LP
frame_data_meta["projectiles"]["2B"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_MP
frame_data_meta["projectiles"]["2C"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_MP
frame_data_meta["projectiles"]["2D"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_MP
frame_data_meta["projectiles"]["2E"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_MP
frame_data_meta["projectiles"]["2F"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_MP
frame_data_meta["projectiles"]["30"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_MP
frame_data_meta["projectiles"]["31"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_HP
frame_data_meta["projectiles"]["32"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_HP
frame_data_meta["projectiles"]["33"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_HP
frame_data_meta["projectiles"]["34"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_HP
frame_data_meta["projectiles"]["35"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_HP
frame_data_meta["projectiles"]["36"] = { hit_type = {3}, hit_period = 4}         --kasumisuzaku_HP
frame_data_meta["projectiles"]["5D"] = { hit_type = {3}}                         --gohadouken_air_LP
frame_data_meta["projectiles"]["5E"] = { hit_type = {3}}                         --gohadouken_air_MP
frame_data_meta["projectiles"]["5F"] = { hit_type = {3}}                         --gohadouken_air_HP
frame_data_meta["projectiles"]["73"] = { hit_type = {3}}                         --light_of_justice
frame_data_meta["projectiles"]["74"] = { hit_type = {3}}                         --light_of_justice
frame_data_meta["projectiles"]["75"] = { hit_type = {3}}                         --light_of_justice
frame_data_meta["projectiles"]["76"] = { hit_type = {3}}                         --light_of_justice
frame_data_meta["projectiles"]["77"] = { hit_type = {3}}                         --light_of_justice
frame_data_meta["projectiles"]["78"] = { hit_type = {3}}                         --light_of_justice
frame_data_meta["projectiles"]["79"] = { hit_type = {3}}                         --light_of_justice
-- frame_data_meta["projectiles"]["7C"] = { hit_type = {3}}                         --light_of_virtue_LP
-- frame_data_meta["projectiles"]["7D"] = { hit_type = {3}}                         --light_of_virtue_MP
-- frame_data_meta["projectiles"]["7E"] = { hit_type = {3}}                         --light_of_virtue_HP
frame_data_meta["projectiles"]["82"] = { hit_type = {2}}                         --light_of_virtue_LK
frame_data_meta["projectiles"]["83"] = { hit_type = {2}}                         --light_of_virtue_MK
frame_data_meta["projectiles"]["84"] = { hit_type = {2}}                         --light_of_virtue_HK
frame_data_meta["projectiles"]["7F"] = { hit_type = {3}}                         --light_of_virtue_EXP
frame_data_meta["projectiles"]["80"] = { hit_type = {3}}                         --light_of_virtue_EXP
frame_data_meta["projectiles"]["87"] = { hit_type = {3}}                         --light_of_virtue_EXK_ext
frame_data_meta["projectiles"]["81"] = { hit_type = {3}}                         --light_of_virtue_EXP_ext
frame_data_meta["projectiles"]["85"] = { hit_type = {2}}                         --light_of_virtue_EXK
frame_data_meta["projectiles"]["86"] = { hit_type = {2}}                         --light_of_virtue_EXK
frame_data_meta["projectiles"]["00_ndl_lp"] = {hit_type = {3}}                         --ndl_LP
frame_data_meta["projectiles"]["00_ndl_mp"] = {hit_type = {3}}                         --ndl_MP
frame_data_meta["projectiles"]["00_ndl_hp"] = {hit_type = {3}}                         --ndl_HP
frame_data_meta["projectiles"]["01_ndl_exp"] = {hit_type = {3}}                         --ndl_EXP
frame_data_meta["projectiles"]["00_xndl"] = {hit_type = {3}}                         --xndl
-- frame_data_meta["projectiles"]["65"] = { hit_type = {3}}                         --aegis_reflector_LP
-- frame_data_meta["projectiles"]["66"] = { hit_type = {3}}                         --aegis_reflector_MP
-- frame_data_meta["projectiles"]["67"] = { hit_type = {3}}                         --aegis_reflector_HP
frame_data_meta["projectiles"]["68"] = { hit_type = {3}, cooldown = 2}           --aegis_reflector_EXP
frame_data_meta["projectiles"]["70"] = { hit_type = {1}, cooldown = 5}           --aegis_reflector
frame_data_meta["projectiles"]["08"] = { hit_type = {3}, unblockable = true}     --denjin_hadouken
frame_data_meta["projectiles"]["09"] = { hit_type = {3}, unblockable = true}     --denjin_hadouken_2
frame_data_meta["projectiles"]["0A"] = { hit_type = {3}, unblockable = true}     --denjin_hadouken_3
frame_data_meta["projectiles"]["0B"] = { hit_type = {3}, unblockable = true}     --denjin_hadouken_4
frame_data_meta["projectiles"]["20"] = { hit_type = {3}, unblockable = true}     --denjin_hadouken_5
frame_data_meta["projectiles"]["3E"] = { hit_type = {3}}                         --metallic_sphere_LP
frame_data_meta["projectiles"]["3F"] = { hit_type = {3}}                         --metallic_sphere_MP
frame_data_meta["projectiles"]["40"] = { hit_type = {3}}                         --metallic_sphere_HP
frame_data_meta["projectiles"]["6E"] = { hit_type = {3}, cooldown = 2}           --metallic_sphere_EXP
frame_data_meta["projectiles"]["55"] = { hit_type = {3}}                         --messatsu_gouhadou
frame_data_meta["projectiles"]["61"] = { hit_type = {3}}                         --messatsu_gouhadou_air

return {
  frame_data_meta = frame_data_meta
}