[GFL] NPC PACK · Garry’s Mod / VJ Base

安装
1. 退出 GMod。把旧的 gfl_npc_pack、gfl_hydra_vj_snpc 和 gfl_manticore_vj_snpc 和 gfl_aegis_yellow（如存在）移出 garrysmod/addons/ 备份，以免菜单出现多个同名单位。
2. 安装并启用 VJ Base。将本包的 gfl_npc_pack 文件夹解压到 garrysmod/addons/。
3. 启动游戏，在 Q 菜单的 NPC → [GFL] NPC PACK 中选择单位。
   多人游戏请在服务端与客户端使用同一个合包。

NPC
KCCO - Hydra，生成时生命和最大生命均为 11000，新实体类名 npc_vj_gfl_pack_hydra。
使用旧类名 npc_vj_gfl_hydra 的存档、复制品或脚本需要改用新实体。
Sangvis Ferri - Manticore，基础生命 6000，实体类名 npc_vj_gfl_manticore。
AA-02 "Sinner"，生命 18000，实体类名 npc_vj_gfl_aa02_sinner。
Ares，生命 50000，实体类名 npc_vj_gfl_aa02_ares。
Hydra 在 VJ Base 初始化之后设置生命值。Manticore 的生成生命值由 VJ Base 难度倍率和全局生命值设置照常调整。

Aegis
KCCO 和 Sangvis Ferri 各有 Aegis、Aegis SWAP、Firefighters 与 Myrmidon 的对应变体，各六个，共十二个。
Sangvis Ferri 圣盾普通版 800 HP、SWAP 版 1000 HP。KCCO 圣盾普通版 1800 HP、SWAP 版 2000 HP。各组的武器变体使用相同的生成生命值和最大生命值。
Firefighters 使用原版火焰喷射器，Myrmidon 使用原版 M32，Aegis 使用原版 Bolter。KCCO 组与 HECU 结盟。
这些单位直接出现在 [GFL] NPC PACK 分类，均含独立缩略图。已收录 SF NPC Constant 的 Aegis 行为、武器脚本、模型、材质及开火资源。
Aegis 原始模型及依赖：https://github.com/1390487287zyt-oss/test/tree/855cd5c0f8ccd4f4660f7de8e24a5b36726d2d51/sf_npc_constant_3686739205

光照与阴影
Manticore 的装甲按所在位置和机体部位采样环境光，在暗处降低亮度，发光灯带保留。
四台机体按当前动画的实际网格生成定向地面轮廓投影，包含机身、腿部和武器。Ares 的投影还包含主炮。
本版直接在可接收投影的地面上绘制轮廓。投影随动画更新，并受场景遮挡。

装甲单位作战
机体物理重量为 Hydra 6000 kg、Manticore 4500 kg、AA-02「负罪者」5000 kg、Ares 6500 kg。
机体免疫伤害推力。受击时也会消除伤害脚本额外施加的向上速度，火炮仍可造成伤害。
四台机甲受伤后继续迎敌。找不到伤害来源时继续索敌，看到敌人后继续追击或开火。
已开始的攻击按原时序执行。当前锁定目标仍可攻击时继续打该目标，目标失效后转向 AI 选中的有效敌人。
没有有效目标时跳过当次发射，墙体和友军仍能拦截射击。

友军
KCCO - Hydra 与 vj_gfl_enemies_snpcs 的 KSSO，以及使用 CLASS_UNITED_STATES 的 HECU 单位结盟。
Sangvis Ferri - Manticore 与 vj_gfl_enemies_snpcs 的 SF 结盟。
AA-02 "Sinner" 与 Ares 沿用 Hydra 的 KCCO、KSSO 和 HECU 友军标签。
每台机体分别记录友军攻击者。来自同一友军的第二次正伤害命中会触发反击，其他友军照常受到友军保护。
计数以进入机体受伤处理时的伤害值为准。零伤害、治疗与自伤不计，正伤害被护盾或 VJ 的友军过滤挡住仍计。

单位细节见 README_Hydra_zh-CN.txt、README_Manticore_zh-CN.txt 和 README_AA02_zh-CN.txt。
蝎甲兽原模型作者的日文说明见 readme.txt。
